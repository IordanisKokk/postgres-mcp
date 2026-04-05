export type TableKind = "BASE TABLE" | "VIEW";

export interface TestConnectionOutput {
  ok: true;
  latency_ms: number;
  database: string;
  current_user: string;
  server_version: string;
  server_time: string;
}

export interface ListTablesInput {
  schema?: string;
  include_views?: boolean;
}

export interface ListTablesOutput {
  tables: Array<{
    schema: string;
    name: string;
    type: TableKind;
  }>;
}

export interface ListSchemasInput { }

export interface ListSchemasOutput {
  schemas: Array<{
    name: string;
  }>
}

export interface DescribeTableInput {
  table: string;
  schema?: string;
}

export interface DescribeTableOutput {
  schema: string;
  table: string;
  columns: Array<{
    name: string;
    data_type: string;
    udt_name: string;
    is_nullable: boolean;
    default_value: string | null;
    ordinal_position: number;
    is_primary_key: boolean;
  }>;
  primary_key: string[];
  foreign_keys: Array<{
    constraint_name: string;
    column_name: string;
    foreign_table_schema: string;
    foreign_table_name: string;
    foreign_column_name: string;
  }>;
}
