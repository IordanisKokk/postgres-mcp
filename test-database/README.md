# Test Database Stack

This directory runs a **seeded PostgreSQL database** plus your **MCP server** in the same Docker Compose stack.

## Why same stack?

Using the same compose stack is the most reliable setup for testing:

- Postgres and MCP share the same Docker network.
- `DATABASE_URL` uses the service name (`test-postgres`) directly.
- No host networking issues (`host.docker.internal`, port forwarding edge cases).

## Start

```bash
cd test-database
docker compose up -d --build
```

## Endpoints / URLs

- Postgres (from host tools):
  - `postgresql://postgres:postgres@localhost:55432/test_database`
- MCP endpoint:
  - `http://localhost:3001/mcp`
- MCP health:
  - `http://localhost:3001/health`

## Seeded Data

The DB initializes from:

- `init/001_schema.sql`
- `init/002_seed.sql`

It creates ~20 related tables with realistic commerce/support data (customers, addresses, products, inventory, orders, order_items, payments, shipments, reviews, support tickets, etc.).

It also seeds a few extra non-system schemas for introspection demos:

- `public`: core commerce/support tables
- `analytics`: reporting snapshots
- `operations`: job run and integration monitoring tables
- `crm`: customer segmentation and outreach tables

## Quick MCP checks with curl

Initialize:

```bash
curl -si -X POST 'http://localhost:3001/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"manual-curl","version":"1.0.0"}}}'
```

List tools (one-shot):

```bash
curl -si -X POST 'http://localhost:3001/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
```

Call `list_tables`:

```bash
curl -si -X POST 'http://localhost:3001/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_tables","arguments":{"schema":"public","include_views":false}}}'
```

Call `list_schemas`:

```bash
curl -si -X POST 'http://localhost:3001/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"list_schemas","arguments":{}}}'
```

Call `describe_table`:

```bash
curl -si -X POST 'http://localhost:3001/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"describe_table","arguments":{"schema":"analytics","table":"daily_sales_summary"}}}'
```

## Reset (re-seed from scratch)

```bash
cd test-database
docker compose down -v
docker compose up -d --build
```
