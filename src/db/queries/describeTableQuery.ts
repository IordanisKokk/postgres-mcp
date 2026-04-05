import { DbClient } from "../client.js";
import { ensureNotSystemSchema, ensureSchemaAllowed } from "../schemaPolicy.js";
import { resolveTable } from "../resolveTable.js";

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

  ensureNotSystemSchema(target.schema);
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
