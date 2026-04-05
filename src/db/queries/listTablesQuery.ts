import { env } from "../../config/env.js";
import { DbClient } from "../client.js";
import { validateIdentifier, ensureSchemaAllowed } from "../schemaPolicy.js";

export async function listTablesQuery(
  db: DbClient,
  input: { schema?: string; include_views?: boolean }
): Promise<Array<{ schema: string; name: string; type: "BASE TABLE" | "VIEW" }>> {
  if (input.schema) {
    validateIdentifier(input.schema, "schema");
    ensureSchemaAllowed(input.schema);
  }

  const includeViews = input.include_views ?? false;
  const params: unknown[] = [input.schema ?? null, includeViews];

  let sql = `
    SELECT
      table_schema AS schema,
      table_name AS name,
      table_type AS type
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND ($1::text IS NULL OR table_schema = $1)
      AND ($2::boolean OR table_type = 'BASE TABLE')
  `;

  if (env.ALLOWED_SCHEMAS.length > 0) {
    sql += " AND table_schema = ANY($3::text[])";
    params.push(env.ALLOWED_SCHEMAS);
  }

  sql += " ORDER BY table_schema, table_name";

  const { rows } = await db.query<{ schema: string; name: string; type: "BASE TABLE" | "VIEW" }>(
    sql,
    params
  );

  return rows;
}
