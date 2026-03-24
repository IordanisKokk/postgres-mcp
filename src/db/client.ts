import { Pool, type QueryResult, type QueryResultRow } from "pg";
import { env } from "../config/env.js";

export class DbClient {
  private readonly pool: Pool;

  constructor() {
    this.pool = new Pool({
      connectionString: env.DATABASE_URL,
      statement_timeout: env.QUERY_TIMEOUT_MS,
      query_timeout: env.QUERY_TIMEOUT_MS,
      application_name: "postgres-mcp-server"
    });
  }

  async query<T extends QueryResultRow>(
    sql: string,
    params: unknown[] = []
  ): Promise<QueryResult<T>> {
    return this.pool.query<T>(sql, params);
  }

  async close(): Promise<void> {
    await this.pool.end();
  }
}

export const db = new DbClient();
