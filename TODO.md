# TODO

## MCP server/runtime

- [ ] Migrate from deprecated low-level `Server` API to `McpServer` (`registerTool`) to reduce wiring risk and align with SDK direction.
- [ ] Validate and harden streamable HTTP initialize/session flow so tool discovery is reliable in Codex clients (initialize -> session reuse -> tools/list behavior).

## DB/query architecture

- [x] Refactor `src/db/introspection.ts` into smaller modules by responsibility (no behavior change in first pass).
- [x] Extract shared validation/policy helpers (identifier validation + `ALLOWED_SCHEMAS` enforcement) into a reusable guard module.
- [x] Move `list_tables` SQL into a dedicated query module owned by that tool.
- [x] Move `describe_table` SQL into a dedicated query module owned by that tool.
- [x] Move `resolveTable` lookup/ambiguity logic into a shared table-resolution module.
- [x] Keep tool wrappers thin and route each wrapper to its dedicated query module.
- [x] Add/keep clear error codes compatibility (`VALIDATION_ERROR`, `SCHEMA_NOT_ALLOWED`, `NOT_FOUND`, `AMBIGUOUS_TABLE`).
- [ ] Add regression checks for all three current tools after refactor (`test_connection`, `list_tables`, `describe_table`).
- [x] Update README structure notes to reflect new module layout.

## Short-term tool roadmap

- [ ] Add `list_schemas` to expose non-system schemas after `ALLOWED_SCHEMAS` filtering.
- [ ] Add `list_indexes` to show per-table indexes, uniqueness, and indexed columns.
- [ ] Add `list_constraints` to expose primary key, foreign key, unique, and check constraints in a dedicated tool.
- [ ] Add `preview_rows` for safe read-only data inspection with enforced row limits and explicit ordering rules.
- [ ] Add `explain_query` for read-only plan inspection without executing arbitrary mutations.

## v0.5 tool roadmap

- [ ] Add `get_table_stats` to expose estimated row counts, last analyze/vacuum timestamps, and sequential/index scan counters from `pg_stat_*`.
- [ ] Add `get_table_size` to show table, index, and total relation size in human-readable and raw-byte form.
- [ ] Add `list_active_queries` to inspect currently running sessions with duration, state, wait event, and query text.
- [ ] Add `list_locks` to inspect blocked/blocking sessions and relation-level lock details.
- [ ] Add `get_index_usage` to show index scan counts and help spot unused or underused indexes.
- [ ] Add `get_relation_bloat_signals` to surface coarse bloat/debugging signals from catalog/stat views without claiming exact bloat math.
- [ ] Add `list_extensions` to show installed extensions and versions for environment/debugging parity.
- [ ] Add `get_db_settings` to expose a safe allowlisted subset of important Postgres settings (`search_path`, timeouts, memory/work settings, autovacuum-related knobs).

## v1.0 tool roadmap

- [ ] Add `explain_query` with structured options for `ANALYZE`, `BUFFERS`, `VERBOSE`, and JSON plan output.
- [ ] Add `explain_statement` with read-only statement validation and mutation blocking for safer plan debugging from raw SQL input.
- [ ] Add `get_blocking_tree` to trace blocker -> blocked chains with session metadata and lock context.
- [ ] Add `get_query_stats` using `pg_stat_statements` when available to surface high-latency / high-call-count queries.
- [ ] Add `compare_table_definitions` to diff tables across schemas or environments for debugging drift.
- [ ] Add `get_replication_status` for environments using replicas, including lag and replay status where available.
- [ ] Add `get_vacuum_health` to inspect dead tuples, autovacuum activity, and freeze-age related warning signals.
- [ ] Add `get_index_definition` to return full index definitions plus indexed expressions, predicates, and backing table context.

## Future roadmap

### Permissions and access debugging

- [ ] Add `list_roles` to inspect available roles/users in the current database.
- [ ] Add `get_role_memberships` to debug inherited privileges and role chains.
- [ ] Add `get_schema_privileges` to inspect `USAGE`/`CREATE` grants on schemas.
- [ ] Add `get_table_privileges` to inspect per-table grants and debug access-denied errors.

### Views, functions, and trigger debugging

- [ ] Add `list_views` to enumerate views separately from tables for easier discovery.
- [ ] Add `get_view_definition` to inspect the SQL behind a view.
- [ ] Add `list_materialized_views` to inspect analytics/reporting objects separately.
- [ ] Add `list_triggers` to show table triggers and their firing behavior.
- [ ] Add `get_trigger_definition` to inspect trigger functions and trigger configuration.
- [ ] Add `get_function_definition` to inspect stored procedures/functions for debugging server-side behavior.

### Relationship and dependency debugging

- [ ] Add `get_fk_graph` to inspect foreign-key relationships around a table.
- [ ] Add `find_referencing_tables` to identify tables that point to a target table.
- [ ] Add `find_dependent_objects` to inspect dependent views, functions, triggers, and indexes.
- [ ] Add `compare_table_definitions` across schemas or environments to debug drift.

### Storage and table-layout debugging

- [ ] Add `get_database_size` to inspect overall database footprint.
- [ ] Add `get_schema_size` to inspect which schemas consume the most space.
- [ ] Add `list_sequences` to inspect serial/identity backing sequences.
- [ ] Add `get_sequence_state` to debug sequence drift and next-value issues.
- [ ] Add `get_partition_info` to inspect partitioned-table configuration.
- [ ] Add `list_partitions` to inspect child partitions and routing layout.

### Runtime and performance diagnostics

- [ ] Add `get_long_running_transactions` to surface transactions that may cause lock or vacuum issues.
- [ ] Add `get_idle_in_transaction_sessions` to inspect sessions that hold resources without active work.
- [ ] Add `get_wait_events` to inspect what active sessions are waiting on.
- [ ] Add `get_cache_hit_ratios` to provide coarse cache-efficiency signals.
- [ ] Add `get_io_stats` to expose relation or backend I/O counters where supported.
- [ ] Add `get_checkpoint_health` to inspect checkpoint pressure and write behavior.
- [ ] Add `get_bgwriter_stats` to expose background writer activity.

### Replication and environment diagnostics

- [ ] Add `get_replication_slots` to inspect slot state and lag risks.
- [ ] Add `list_publications` to inspect logical replication publications.
- [ ] Add `list_subscriptions` to inspect logical replication subscriptions.
- [ ] Add `get_wal_activity` to inspect WAL generation and replay-related signals.
- [ ] Add `get_server_identity` to return environment-level facts such as version, timezone, current DB, current user, and recovery mode.
- [ ] Add `get_database_uptime` to inspect restart/debugging history at a glance.

## Refactor definition of done

- [x] `src/db/introspection.ts` no longer contains all tool logic and is either removed or reduced to a thin compatibility layer.
- [x] Tool outputs and error payload shapes remain unchanged for existing clients.
- [x] Build passes (`npm run build`) and test-database compose flow still works end-to-end.
