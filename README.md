# postgres-mcp-server

Self-hosted PostgreSQL MCP server (TypeScript) with a streamable HTTP endpoint and read-only schema/introspection tools.

## Current v1 scope

- `test_connection`
- `list_tables`
- `describe_table`

## Prerequisites

- Docker + Docker Compose
- A reachable PostgreSQL database

## Configuration

1. Copy `.env.example` to `.env`.
2. Set a valid `DATABASE_URL`.

Example:

```env
DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/postgres
PORT=3000
MCP_PATH=/mcp
QUERY_TIMEOUT_MS=10000
MAX_ROWS=200
ALLOWED_SCHEMAS=public
```

Notes:

- Use `host.docker.internal` when the DB runs on your host machine (macOS/Windows).
- For Linux, use a reachable host/IP for your environment.

## Run with Docker Compose

```bash
docker-compose up --build
```

Server endpoint:

- MCP: `http://localhost:3000/mcp`
- Health: `http://localhost:3000/health`

## Add to Codex MCP config

Use streamable HTTP MCP transport pointing to:

`http://localhost:3000/mcp`

Example TOML-style entry:

```toml
[mcp_servers.postgres]
url = "http://localhost:3000/mcp"
```

If your Codex version expects additional fields (for transport type), keep the same URL and choose streamable HTTP.

## Tool contracts

### `test_connection`

Input:

```json
{}
```

Output:

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

Input:

```json
{
  "schema": "public",
  "include_views": false
}
```

Output:

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

Input:

```json
{
  "schema": "public",
  "table": "users"
}
```

Output includes:

- `columns` with nullability/default/type/order
- `primary_key` column list
- `foreign_keys` relationship metadata

## Safety decisions in this step

- Read-only introspection SQL only
- No mutation tools exposed
- Identifier validation for `schema` and `table`
- Optional schema restriction via `ALLOWED_SCHEMAS`
- DB statement/query timeout via env config
