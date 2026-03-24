import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  PORT: z.coerce.number().int().positive().default(3000),
  MCP_PATH: z.string().min(1).default("/mcp"),
  QUERY_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  MAX_ROWS: z.coerce.number().int().positive().default(200),
  ALLOWED_SCHEMAS: z.string().optional()
});

const parsed = envSchema.parse(process.env);

const allowedSchemas = parsed.ALLOWED_SCHEMAS
  ? parsed.ALLOWED_SCHEMAS.split(",")
      .map((value) => value.trim())
      .filter(Boolean)
  : [];

if (!parsed.MCP_PATH.startsWith("/")) {
  throw new Error("MCP_PATH must start with '/'.");
}

export const env = {
  ...parsed,
  ALLOWED_SCHEMAS: allowedSchemas
};

export type Env = typeof env;
