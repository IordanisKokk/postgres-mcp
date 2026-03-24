import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema
} from "@modelcontextprotocol/sdk/types.js";
import { db } from "./db/client.js";
import { normalizeError } from "./utils/errors.js";
import { describeTableInputSchema, runDescribeTable } from "./tools/describeTable.js";
import { listTablesInputSchema, runListTables } from "./tools/listTables.js";
import { testConnectionInputSchema, runTestConnection } from "./tools/testConnection.js";

const tools = [
  {
    name: "test_connection",
    description: "Test DATABASE_URL connectivity and return basic Postgres metadata.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {}
    }
  },
  {
    name: "list_tables",
    description: "List tables in non-system schemas.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {
        schema: {
          type: "string",
          description: "Optional schema name to filter tables."
        },
        include_views: {
          type: "boolean",
          description: "When true, include views in results."
        }
      }
    }
  },
  {
    name: "describe_table",
    description: "Describe columns, primary key, and foreign keys for a table.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["table"],
      properties: {
        table: {
          type: "string",
          description: "Table name without schema prefix."
        },
        schema: {
          type: "string",
          description: "Optional schema. Required when table exists in multiple schemas."
        }
      }
    }
  }
];

function makeToolResponse(payload: unknown) {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(payload, null, 2)
      }
    ]
  };
}

function makeToolError(error: unknown) {
  const normalized = normalizeError(error);
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(normalized, null, 2)
      }
    ]
  };
}

export function createMcpServer(): Server {
  const server = new Server(
    {
      name: "postgres-mcp-server",
      version: "0.1.0"
    },
    {
      capabilities: {
        tools: {}
      }
    }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
      if (name === "test_connection") {
        testConnectionInputSchema.parse(args ?? {});
        const result = await runTestConnection(db);
        return makeToolResponse(result);
      }

      if (name === "list_tables") {
        const input = listTablesInputSchema.parse(args ?? {});
        const result = await runListTables(db, input);
        return makeToolResponse(result);
      }

      if (name === "describe_table") {
        const input = describeTableInputSchema.parse(args ?? {});
        const result = await runDescribeTable(db, input);
        return makeToolResponse(result);
      }

      return makeToolError({
        code: "UNKNOWN_TOOL",
        message: `Tool '${name}' is not registered.`
      });
    } catch (error) {
      return makeToolError(error);
    }
  });

  return server;
}
