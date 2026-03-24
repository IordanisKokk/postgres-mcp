import express from "express";
import { randomUUID } from "node:crypto";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import {
  LATEST_PROTOCOL_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS
} from "@modelcontextprotocol/sdk/types.js";
import { env } from "./config/env.js";
import { db } from "./db/client.js";
import { createMcpServer } from "./server.js";

const app = express();
app.use(express.json({ limit: "1mb" }));

type SessionState = {
  server: ReturnType<typeof createMcpServer>;
  transport: StreamableHTTPServerTransport;
  protocolVersion: string;
};

const sessions = new Map<string, SessionState>();

function parseRequestedProtocolVersion(body: unknown): string {
  const method = (body as { method?: unknown } | null)?.method;
  const requestedProtocolVersion = (body as { params?: { protocolVersion?: unknown } } | null)?.params
    ?.protocolVersion;

  if (method !== "initialize" || typeof requestedProtocolVersion !== "string") {
    return LATEST_PROTOCOL_VERSION;
  }

  return SUPPORTED_PROTOCOL_VERSIONS.includes(requestedProtocolVersion)
    ? requestedProtocolVersion
    : LATEST_PROTOCOL_VERSION;
}

function isInitializeRequest(body: unknown): boolean {
  return (
    typeof body === "object" &&
    body !== null &&
    "method" in body &&
    (body as { method?: unknown }).method === "initialize"
  );
}

function setIncomingHeader(req: express.Request, name: string, value: string): void {
  const lowerName = name.toLowerCase();
  req.headers[lowerName] = value;

  const rawHeaders = (req as unknown as { rawHeaders?: string[] }).rawHeaders;
  if (!Array.isArray(rawHeaders)) {
    return;
  }

  const nextRawHeaders: string[] = [];
  let replaced = false;

  for (let i = 0; i < rawHeaders.length; i += 2) {
    const key = rawHeaders[i];
    const headerValue = rawHeaders[i + 1];

    if (key?.toLowerCase() === lowerName) {
      if (!replaced) {
        nextRawHeaders.push(key, value);
        replaced = true;
      }
      continue;
    }

    if (typeof key === "string" && typeof headerValue === "string") {
      nextRawHeaders.push(key, headerValue);
    }
  }

  if (!replaced) {
    nextRawHeaders.push(name, value);
  }

  (req as unknown as { rawHeaders: string[] }).rawHeaders = nextRawHeaders;
}

function normalizeAcceptHeader(req: express.Request): void {
  const original = req.header("accept");

  if (!original) {
    setIncomingHeader(req, "accept", "application/json, text/event-stream");
    return;
  }

  const acceptsJson = original.includes("application/json");
  const acceptsSse = original.includes("text/event-stream");

  if (!acceptsJson && !acceptsSse) {
    setIncomingHeader(req, "accept", `${original}, application/json, text/event-stream`);
    return;
  }

  if (acceptsJson && !acceptsSse) {
    setIncomingHeader(req, "accept", `${original}, text/event-stream`);
    return;
  }

  if (!acceptsJson && acceptsSse) {
    setIncomingHeader(req, "accept", `${original}, application/json`);
  }
}

async function createStatelessState() {
  const server = createMcpServer();
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true
  });
  await server.connect(transport);
  return { server, transport };
}

async function getOrCreateSession(
  sessionIdHeader: string | undefined,
  allowCreate: boolean,
  protocolVersion: string
): Promise<SessionState | null> {
  if (sessionIdHeader) {
    return sessions.get(sessionIdHeader) ?? null;
  }

  if (!allowCreate) {
    return null;
  }

  const server = createMcpServer();

  let transport: StreamableHTTPServerTransport;
  transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: () => randomUUID(),
    enableJsonResponse: true,
    onsessioninitialized: (sessionId) => {
      sessions.set(sessionId, { server, transport, protocolVersion });
    }
  });

  transport.onclose = () => {
    if (transport.sessionId) {
      sessions.delete(transport.sessionId);
    }
  };

  await server.connect(transport);

  return { server, transport, protocolVersion };
}

app.all(env.MCP_PATH, async (req, res) => {
  try {
    if (req.method === "POST") {
      normalizeAcceptHeader(req);
    }

    const initializeRequest = req.method === "POST" && isInitializeRequest(req.body);
    const inferredProtocolVersion = parseRequestedProtocolVersion(req.body);
    const sessionHeader = req.header("mcp-session-id") ?? undefined;
    const allowCreate = !sessionHeader && initializeRequest;
    const state = await getOrCreateSession(sessionHeader, allowCreate, inferredProtocolVersion);

    if (req.method === "POST" && !sessionHeader && !initializeRequest) {
      if (!req.header("mcp-protocol-version")) {
        setIncomingHeader(req, "mcp-protocol-version", inferredProtocolVersion);
      }

      const oneShot = await createStatelessState();
      try {
        await oneShot.transport.handleRequest(req, res, req.body);
      } finally {
        await oneShot.server.close();
      }
      return;
    }

    if (!state) {
      res.status(400).json({
        error:
          "Missing or invalid mcp-session-id. Start a session with POST without an mcp-session-id header."
      });
      return;
    }

    if (req.method === "POST") {
      if (!req.header("mcp-protocol-version") && !initializeRequest) {
        setIncomingHeader(req, "mcp-protocol-version", state.protocolVersion);
      }
      await state.transport.handleRequest(req, res, req.body);
      return;
    }

    if (req.method === "GET" || req.method === "DELETE") {
      await state.transport.handleRequest(req, res);
      return;
    }

    res.setHeader("Allow", "GET, POST, DELETE");
    res.status(405).send("Method Not Allowed");
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown transport error";
    res.status(500).json({ error: message });
  }
});

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "postgres-mcp-server" });
});

const httpServer = app.listen(env.PORT, () => {
  process.stdout.write(
    `postgres-mcp-server listening on http://0.0.0.0:${env.PORT}${env.MCP_PATH}\n`
  );
});

async function shutdown() {
  httpServer.close(async () => {
    await db.close();
    process.exit(0);
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
