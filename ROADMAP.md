# Roadmap

This roadmap captures the planned evolution of `postgres-mcp-server` as a read-only PostgreSQL debugging and introspection server for MCP clients.

The focus is:

- safe database introspection
- debugging-oriented tools
- operational visibility
- clear, stable tool contracts

Current scope already includes connectivity and schema/table introspection. The next phases expand that into deeper database debugging and runtime diagnostics.

## Platform and quality

These are cross-cutting items that improve reliability regardless of which tools are added next.

- Migrate from the deprecated low-level `Server` API to `McpServer` and `registerTool`
- Harden streamable HTTP initialize/session behavior so tool discovery is reliable in Codex clients
- Add regression checks for the existing tool surface after refactors
- Keep tool outputs and error payloads stable for existing clients

## Near term

These are the next practical additions to the current introspection surface.

- `list_schemas`
  List non-system schemas after `ALLOWED_SCHEMAS` filtering
- `list_indexes`
  Show per-table indexes, uniqueness, and indexed columns
- `list_constraints`
  Show primary key, foreign key, unique, and check constraints
- `preview_rows`
  Provide safe read-only data inspection with row limits and predictable ordering

## v0.5

This phase is focused on debugging and operational inspection without introducing broad raw-SQL execution.

- `get_table_stats`
  Estimated row counts, last analyze/vacuum timestamps, and scan counters from `pg_stat_*`
- `get_table_size`
  Table, index, and total relation size in raw bytes and human-readable form
- `list_active_queries`
  Running sessions with duration, state, wait event, and query text
- `list_locks`
  Blocked/blocking sessions and relation-level lock details
- `get_index_usage`
  Index scan counts to help identify unused or underused indexes
- `get_relation_bloat_signals`
  Coarse bloat/debugging signals from catalog and stats views
- `list_extensions`
  Installed extensions and versions for environment/debugging parity
- `get_db_settings`
  Safe allowlisted database settings such as `search_path`, timeouts, memory/work settings, and autovacuum-related knobs

## v1.0

This phase adds stronger query-planning, lock-debugging, and drift-analysis capabilities.

- `explain_query`
  Structured query-plan inspection with options such as `ANALYZE`, `BUFFERS`, `VERBOSE`, and JSON output
- `explain_statement`
  Safer plan debugging from raw SQL input with read-only validation and mutation blocking
- `get_blocking_tree`
  Blocker-to-blocked chains with session metadata and lock context
- `get_query_stats`
  Query-level performance statistics via `pg_stat_statements` when available
- `compare_table_definitions`
  Diff table definitions across schemas or environments to debug drift
- `get_replication_status`
  Replica/standby lag and replay status where applicable
- `get_vacuum_health`
  Dead tuples, autovacuum activity, and freeze-age warning signals
- `get_index_definition`
  Full index definitions including indexed expressions, predicates, and table context

## Future roadmap

### Permissions and access debugging

- `list_roles`
  Inspect available roles and users in the current database
- `get_role_memberships`
  Debug inherited privileges and role chains
- `get_schema_privileges`
  Inspect `USAGE` and `CREATE` grants on schemas
- `get_table_privileges`
  Inspect per-table grants and debug access-denied errors

### Views, functions, and trigger debugging

- `list_views`
  Enumerate views separately from tables
- `get_view_definition`
  Inspect the SQL behind a view
- `list_materialized_views`
  Inspect analytics/reporting objects separately
- `list_triggers`
  Show table triggers and their firing behavior
- `get_trigger_definition`
  Inspect trigger functions and trigger configuration
- `get_function_definition`
  Inspect stored procedures and functions for debugging server-side behavior

### Relationship and dependency debugging

- `get_fk_graph`
  Inspect foreign-key relationships around a table
- `find_referencing_tables`
  Identify tables that point to a target table
- `find_dependent_objects`
  Inspect dependent views, functions, triggers, and indexes

### Storage and table-layout debugging

- `get_database_size`
  Inspect overall database footprint
- `get_schema_size`
  Inspect which schemas consume the most space
- `list_sequences`
  Inspect serial and identity backing sequences
- `get_sequence_state`
  Debug sequence drift and next-value issues
- `get_partition_info`
  Inspect partitioned-table configuration
- `list_partitions`
  Inspect child partitions and routing layout

### Runtime and performance diagnostics

- `get_long_running_transactions`
  Surface transactions that may cause lock or vacuum issues
- `get_idle_in_transaction_sessions`
  Inspect sessions that hold resources without active work
- `get_wait_events`
  Inspect what active sessions are waiting on
- `get_cache_hit_ratios`
  Provide coarse cache-efficiency signals
- `get_io_stats`
  Expose relation or backend I/O counters where supported
- `get_checkpoint_health`
  Inspect checkpoint pressure and write behavior
- `get_bgwriter_stats`
  Expose background writer activity

### Replication and environment diagnostics

- `get_replication_slots`
  Inspect slot state and lag risks
- `list_publications`
  Inspect logical replication publications
- `list_subscriptions`
  Inspect logical replication subscriptions
- `get_wal_activity`
  Inspect WAL generation and replay-related signals
- `get_server_identity`
  Return environment-level facts such as version, timezone, current database, current user, and recovery mode
- `get_database_uptime`
  Inspect restart/debugging history at a glance

## Principles

The roadmap is guided by a few constraints:

- stay read-only by default
- prefer structured, explicit tool contracts over arbitrary SQL execution
- make debugging signals clear and actionable
- keep behavior predictable across clients
- add stronger safety and testing as the tool surface grows
