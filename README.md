# postgres-mcp-server

Inspect PostgreSQL schemas, tables, columns, and keys from an MCP client. This self-hosted TypeScript server exposes four read-only tools over Streamable HTTP.

## Try the seeded database

From the repository root, start the demo with Docker Compose:

```bash
docker compose -f test-database/docker-compose.yml up -d --build
```

Connect your MCP client to `http://localhost:3001/mcp` and ask: **“Describe the daily sales summary table in the analytics schema. Which column is its primary key?”**

The client can call `describe_table` with `{"schema":"analytics","table":"daily_sales_summary"}`. In the [seed schema](./test-database/init/001_schema.sql), `summary_date` is the primary key and `gross_revenue` is a numeric column with precision 12 and scale 2.

The demo publishes the MCP server on port **3001** by default. The standalone server uses **3000**. See the [demo guide](./test-database/README.md) for curl examples. To stop the demo and keep its data:

```bash
docker compose -f test-database/docker-compose.yml down
```

## Current scope

- `test_connection`
- `list_tables`
- `describe_table`
- `list_schemas`

## Roadmap

See [ROADMAP.md](./ROADMAP.md) for the planned tool and platform roadmap.

## Project structure

- `src/http.ts`: Express server, streamable HTTP transport, session handling, and health route
- `src/server.ts`: MCP server creation, tool registration, and tool dispatch
- `src/tools/`: thin tool wrappers plus Zod input schemas
- `src/db/schemaPolicy.ts`: identifier validation and schema access policy helpers
- `src/db/resolveTable.ts`: shared table lookup and ambiguity handling
- `src/db/queries/`: tool-owned SQL modules
- `src/config/env.ts`: environment parsing and normalization
- `src/utils/errors.ts`: app error shape and error normalization

## Requirements

- Node.js 20+
- npm
- A reachable PostgreSQL database
- Docker and Docker Compose if you want to use the local test stack

## Configuration

Copy `.env.example` to `.env` and adjust values as needed.

```bash
cp .env.example .env
```

Example:

```env
DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/postgres
PORT=3000
MCP_PATH=/mcp
QUERY_TIMEOUT_MS=10000
MAX_ROWS=200
ALLOWED_SCHEMAS=public
```

Environment variables:

- `DATABASE_URL`: Postgres connection string
- `PORT`: HTTP port for the MCP server
- `MCP_PATH`: path where the MCP endpoint is exposed
- `QUERY_TIMEOUT_MS`: statement and query timeout in milliseconds
- `MAX_ROWS`: reserved for row-limited tools such as future data preview tools
- `ALLOWED_SCHEMAS`: optional comma-separated schema allowlist; empty means no allowlist

Notes:

- Use `host.docker.internal` when the database runs on your host machine on macOS or Windows.
- On Linux, use a host/IP reachable from your environment.

## Run locally

Install dependencies:

```bash
npm install
```

Start the server in development mode:

```bash
npm run dev
```

Build production output:

```bash
npm run build
```

Start the compiled server:

```bash
npm run start
```

Default endpoints:

- MCP: `http://localhost:3000/mcp`
- Health: `http://localhost:3000/health`

## Run with Docker Compose

```bash
docker-compose up --build
```

## Add to Codex MCP config

Use streamable HTTP MCP transport pointing to:

`http://localhost:3000/mcp`

Example:

```toml
[mcp_servers.postgres]
url = "http://localhost:3000/mcp"
```

If your Codex version asks for transport details, keep the same URL and choose streamable HTTP.

## Tool reference

### `test_connection`

Purpose:

- verifies the configured `DATABASE_URL`
- returns basic server metadata

Input:

```json
{}
```

Output shape:

```json
{
  "ok": true,
  "latency_ms": 7,
  "database": "app_db",
  "current_user": "readonly_user",
  "server_version": "PostgreSQL 16...",
  "server_time": "2026-03-20T12:00:00.000Z"
}
```

### `list_schemas`

Call with `{}` to list visible non-system schemas in alphabetical order, filtered by `ALLOWED_SCHEMAS` when configured. Example output for a server restricted to the public schema:

```json
{ "schemas": [{ "name": "public" }] }
```

### `list_tables`

Purpose:

- lists non-system tables
- optionally filters to one schema
- optionally includes views

Input fields:

- `schema`: optional string
- `include_views`: optional boolean, default `false`

Example input:

```json
{
  "schema": "public",
  "include_views": false
}
```

Output shape:

```json
{
  "tables": [
    {
      "schema": "public",
      "name": "users",
      "type": "BASE TABLE"
    }
  ]
}
```

### `describe_table`

Purpose:

- returns column metadata
- returns primary key metadata
- returns foreign key metadata

Input fields:

- `table`: required string
- `schema`: optional string; needed when the table exists in multiple schemas

Example input:

```json
{
  "schema": "public",
  "table": "users"
}
```

Output includes:

- `schema`
- `table`
- `columns`
- `primary_key`
- `foreign_keys`

## Validation and errors

Tool input schemas are strict. Unknown fields are rejected by Zod before the tool logic runs.

Current application-level error codes:

- `VALIDATION_ERROR`
- `SCHEMA_NOT_ALLOWED`
- `NOT_FOUND`
- `AMBIGUOUS_TABLE`
- `INTERNAL_ERROR`

## Safety and behavior

- read-only introspection SQL only
- no mutation tools exposed
- identifier validation for `schema` and `table`
- optional schema restriction via `ALLOWED_SCHEMAS`
- system schemas are excluded from introspection paths
- DB statement/query timeout is configured through env
