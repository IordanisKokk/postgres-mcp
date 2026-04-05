# postgres-mcp-server

Self-hosted PostgreSQL MCP server in TypeScript with a streamable HTTP endpoint and read-only database introspection tools.

## Current scope

- `test_connection`
- `list_tables`
- `describe_table`

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

## Test database stack

For repeatable local checks, use the seeded stack in [`test-database/README.md`](/Users/iordaniskokk/CSD/postgres-mcp-server/test-database/README.md).

That stack runs:

- a seeded PostgreSQL instance
- this MCP server in the same Docker network

It is the easiest way to manually verify the current tools end-to-end.

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

## Status

The DB/query architecture refactor has been split into smaller modules and `src/db/introspection.ts` has been removed. The next major work items are MCP server/runtime cleanup, regression checks, and additional read-only tools.
