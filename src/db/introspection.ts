import { env } from "../config/env.js";
import { AppError } from "../utils/errors.js";
import type { DbClient } from "./client.js";

const SYSTEM_SCHEMAS = new Set(["pg_catalog", "information_schema"]);
const IDENTIFIER_PATTERN = /^[A-Za-z_][A-Za-z0-9_$]*$/;

function validateIdentifier(name: string, field: string): void {
  if (!IDENTIFIER_PATTERN.test(name)) {
    throw new AppError("VALIDATION_ERROR", `Invalid ${field}: ${name}`);
  }
}

function ensureSchemaAllowed(schema: string): void {
  if (env.ALLOWED_SCHEMAS.length === 0) {
    return;
  }

  if (!env.ALLOWED_SCHEMAS.includes(schema)) {
    throw new AppError(
      "SCHEMA_NOT_ALLOWED",
      `Schema '${schema}' is not in ALLOWED_SCHEMAS.`
    );
  }
}

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

type ColumnRow = {
  name: string;
  data_type: string;
  udt_name: string;
  is_nullable: boolean;
  default_value: string | null;
  ordinal_position: number;
};

type ForeignKeyRow = {
  constraint_name: string;
  column_name: string;
  foreign_table_schema: string;
  foreign_table_name: string;
  foreign_column_name: string;
};

export async function describeTableQuery(
  db: DbClient,
  input: { schema?: string; table: string }
): Promise<{
  schema: string;
  table: string;
  columns: Array<ColumnRow & { is_primary_key: boolean }>;
  primary_key: string[];
  foreign_keys: ForeignKeyRow[];
}> {
  const target = await resolveTable(db, input);

  if (SYSTEM_SCHEMAS.has(target.schema)) {
    throw new AppError("SCHEMA_NOT_ALLOWED", `Schema '${target.schema}' is not allowed.`);
  }

  ensureSchemaAllowed(target.schema);

  const [columnsResult, pkResult, fkResult] = await Promise.all([
    db.query<ColumnRow>(
      `
        SELECT
          c.column_name AS name,
          c.data_type,
          c.udt_name,
          (c.is_nullable = 'YES') AS is_nullable,
          c.column_default AS default_value,
          c.ordinal_position
        FROM information_schema.columns c
        WHERE c.table_schema = $1
          AND c.table_name = $2
        ORDER BY c.ordinal_position
      `,
      [target.schema, target.table]
    ),
    db.query<{ column_name: string }>(
      `
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = $1
          AND tc.table_name = $2
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
      `,
      [target.schema, target.table]
    ),
    db.query<ForeignKeyRow>(
      `
        SELECT
          kcu.constraint_name,
          kcu.column_name,
          ccu.table_schema AS foreign_table_schema,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
         AND ccu.table_schema = tc.table_schema
        WHERE tc.table_schema = $1
          AND tc.table_name = $2
          AND tc.constraint_type = 'FOREIGN KEY'
        ORDER BY kcu.constraint_name, kcu.ordinal_position
      `,
      [target.schema, target.table]
    )
  ]);

  const primaryKey = pkResult.rows.map((row) => row.column_name);
  const primaryKeySet = new Set(primaryKey);

  return {
    schema: target.schema,
    table: target.table,
    columns: columnsResult.rows.map((column) => ({
      ...column,
      is_primary_key: primaryKeySet.has(column.name)
    })),
    primary_key: primaryKey,
    foreign_keys: fkResult.rows
  };
}
