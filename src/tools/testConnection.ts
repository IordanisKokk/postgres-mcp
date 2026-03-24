import { z } from "zod";
import type { DbClient } from "../db/client.js";
import type { TestConnectionOutput } from "../types/index.js";

export const testConnectionInputSchema = z.object({}).strict();

export async function runTestConnection(db: DbClient): Promise<TestConnectionOutput> {
  const startedAt = Date.now();

  const { rows } = await db.query<{
    database: string;
    current_user: string;
    server_version: string;
    server_time: Date;
  }>(
    `
      SELECT
        current_database() AS database,
        current_user AS current_user,
        version() AS server_version,
        now() AS server_time
    `
  );

  const row = rows[0];

  return {
    ok: true,
    latency_ms: Date.now() - startedAt,
    database: row.database,
    current_user: row.current_user,
    server_version: row.server_version,
    server_time: row.server_time.toISOString()
  };
}
