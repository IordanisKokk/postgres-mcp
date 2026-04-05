import { env } from "../config/env.js";
import { AppError } from "../utils/errors.js";
import { DbClient } from "./client.js";
import { validateIdentifier, ensureSchemaAllowed } from "./schemaPolicy.js";

export async function resolveTable(
  db: DbClient,
  input: { schema?: string; table: string }
): Promise<{ schema: string; table: string }> {
  validateIdentifier(input.table, "table");

  if (input.schema) {
    validateIdentifier(input.schema, "schema");
    ensureSchemaAllowed(input.schema);
  }

  const params: unknown[] = [input.table, input.schema ?? null];

  let sql = `
    SELECT table_schema AS schema, table_name AS table
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND table_name = $1
      AND ($2::text IS NULL OR table_schema = $2)
  `;

  if (env.ALLOWED_SCHEMAS.length > 0) {
    sql += " AND table_schema = ANY($3::text[])";
    params.push(env.ALLOWED_SCHEMAS);
  }

  sql += " ORDER BY table_schema";

  const { rows } = await db.query<{ schema: string; table: string }>(sql, params);

  if (rows.length === 0) {
    throw new AppError("NOT_FOUND", `Table '${input.table}' was not found.`);
  }

  if (!input.schema && rows.length > 1) {
    throw new AppError(
      "AMBIGUOUS_TABLE",
      `Table '${input.table}' exists in multiple schemas. Provide schema explicitly.`,
      {
        candidates: rows.map((row) => `${row.schema}.${row.table}`)
      }
    );
  }

  return rows[0];
}
