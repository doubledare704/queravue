# Queravue — Roadmap (first 20 iterations)

Each iteration ≈ 1–2 weeks part-time and ends with a runnable app plus green tests.
"Done when" is the exit criterion: don't start the next iteration until it holds.

## Phase A — Foundations (it. 0–3)

### It. 0 — Skeleton & plumbing
- Monorepo: `app/` (Flutter), `core/` (Go), `proto/` (buf), `dev/docker-compose.yml` (Postgres, MySQL, MongoDB replica set, Redis, SQL Server, ClickHouse).
- Core sidecar lifecycle: UI spawns core, handshake (socket path + token), health ping, auto-restart, clean shutdown.
- CI (GitHub Actions): `go test`, `golangci-lint`, `flutter analyze`, `flutter test`, `buf lint`.
- **Done when:** the app launches, shows "Core connected vX.Y", and survives `kill -9` of the core.

### It. 1 — Connection manager + first two engines
- `Engine` interface + registry; Postgres (pgx) and SQLite drivers.
- Connection CRUD, groups, colors; secrets in the OS keychain; "Test connection".
- **Done when:** you can save, test and reconnect a Postgres and a SQLite connection across restarts; no plaintext passwords on disk.

### It. 2 — SQL editor + streaming result grid (spike: grid & editor choice)
- Spike 2–3 days: grid candidates on a 1M-row result (FPS, memory). Write the decision as an ADR.
- Editor with highlighting, run statement/selection, cancel.
- Server-streamed row batches, virtualized grid, column resize/sort, copy as CSV/JSON.
- **Done when:** `SELECT * FROM generate_series(1,1000000)` scrolls smoothly, memory stays within budget, and cancel works.

### It. 3 — Schema browser & table data view
- Tree: databases → schemas → tables/views → columns/indexes/FKs.
- Table view: pagination, filter builder, sort, inline edit with pending-changes + commit/rollback.
- Query history and multiple editor tabs.
- **Done when:** you can browse, filter and edit a table without writing SQL.

## Phase B — Engine breadth & Mongo (it. 4–7)

### It. 4 — More SQL engines
- MySQL/MariaDB (+TiDB), CockroachDB (via pgx), SQL Server.
- Shared SQL-dialect layer (quoting, pagination, introspection queries).
- **Done when:** It. 1–3 features pass integration tests on all of them.

### It. 5 — MongoDB core
- Connections (SRV, replica set, TLS); databases/collections tree.
- Document views: JSON, tree, table; filter/sort/projection bar; insert/edit/delete documents.
- Cosmos DB and DocumentDB smoke-tested.
- **Done when:** day-to-day Mongo browsing works without a shell.

### It. 6 — Mongo shell + saved queries ✅ done
- ✅ goja-based shell with a mongosh-like API subset (`db.coll.find/aggregate/updateMany...`, cursors, `printjson`).
- ✅ Saved queries & scripts as files in a workspace folder (Git-friendly), with folders and search.
- ✅ **Done when:** common mongosh snippets run unchanged.

**Status:** merged in PRs #14–#18 (ADRs 0010 and 0011), CI green on each. Perf results in `docs/perf/iteration-6.md`.
- Core: `internal/shell` (goja runtime, cancellable, no gRPC dependency), `ShellService`, `WorkspaceService`.
- UI: shell tabs with an output pane, workspace file tree with saved queries and scripts.

### It. 7 — Indexes, stats, validation, table management ✅ done
- ✅ Index manager (SQL + Mongo): list, create, drop, usage stats. Usage and size show "n/a" where a server keeps none.
- ✅ Collection/table statistics.
- ✅ Mongo `$jsonSchema` validation editor.
- ✅ SQL table designer: create/alter tables, columns and constraints (foreign keys, unique, check) → preview DDL → apply.
- ✅ **Done when:** schema changes can be made visually with a DDL preview.

**Status:** merged in PRs #19–#24 (ADRs 0012 and 0013, protocol version 7), CI green on each.
- Core: `IndexService`, `StatsService`, `ValidationService`, `SchemaDesignService`; DDL builders per dialect with golden tests.
- Live-server tests pass on PostgreSQL, CockroachDB, MySQL, MariaDB, TiDB, SQL Server, MongoDB and DocumentDB Local (shared `IndexLifecycle`, `TableStats`, `DDLRoundTrip` suites, Mongo validation tests).
- UI: Indexes, Stats and Validation sections on table and collection tabs, gated by capability; designer tab. Widget tests plus the macOS end-to-end test `make test-e2e-designer` (real app and core, SQLite).

**Known gaps (carry forward):**
- Amazon DocumentDB and Cosmos DB for MongoDB are unverified; unsupported calls map to `UNSUPPORTED`.
- SQLite constraint changes on an existing table are unsupported; a column alter is a table rebuild that must be applied on its own (ADR 0014).
- The Indexes, Stats and Validation panels have no end-to-end test against a running core; the designer on engines other than SQLite is untested end to end.

## Phase C — Productivity (it. 8–12)

### It. 8 — Editor intelligence & layout ✅ done
- Schema-aware autocomplete (tables, columns, aliases, Mongo fields from sampled schema).
- Formatter, snippets, command palette, shortcuts.
- Split panels / detachable panes.
- **Done when:** autocomplete is useful on a 500-table schema and stays under 50 ms.

**Status:** done in six PRs (#32 to #37): ADR 0015 and the completion contract; SQL completion in core; SQL formatter and Mongo completion; completion popup, snippets and format shortcut (keystroke to popup p95 19.4 ms first character, 25.1 ms narrowing, on 500 tables); action registry, palette and user keybindings; split editor groups with a persisted layout (ADR 0016).

A follow-up closed the layout gaps: tabs drag between groups, `⌘1` to `⌘4` focus a group, the focused group maximizes in the window, and the sidebar and the results/output pane resize, collapse and persist. Palette prefixes now follow the brief (`@` objects, `#` files; `:` is tabs), actions have an enabled-when predicate, the core completion budget runs in CI, and the keystroke-to-popup test runs there against a looser 150 ms limit because shared runners are slower (the 50 ms budget is still checked locally). Cold start (289 ms to core socket) and idle memory (107 MB footprint) were measured on the release build (`docs/perf/iteration-8.md`).

**Known gaps (carry forward):**
- Detached OS windows are not built and the spike was desk research without a prototype: Flutter's windowing API is still experimental (ADR 0016). Maximize in the window stands in.
- Table, collection and designer tabs are not restored after a restart.
- Bulk introspection on a 500-table schema was measured on PostgreSQL only.

### It. 9 — ER diagrams + materialize ✅ done
- Auto-generated ER diagram from schema (auto-layout, zoom, export SVG/PNG).
- Design mode: draw tables/relations → generate DDL → apply.
- Mongo: inferred schema diagram from sampling.
- **Done when:** a 100-table schema renders readably, and a designed diagram creates real tables.

**Status:** done in six PRs (#40 to #45): ADR 0017 and the `DiagramService` contract (protocol version 9); the schema graph loaded in bulk for the SQL engines (500 tables in 27 ms p95 on PostgreSQL); a read-only diagram with automatic layout, pan and zoom (500 tables open in 0.14 s, pan frames under 4 ms); SVG and PNG export and saved diagrams in the workspace; design mode, where drafted tables and relations become ordered DDL that is reviewed and applied (end-to-end on SQLite and PostgreSQL, integration-tested on every docker SQL engine); and a Mongo diagram inferred from sampled documents, with guessed relations marked, faded by confidence and hideable (the seeded database loads in 3 ms p50).

**Known gaps (carry forward):**
- Mongo relations are guesses checked against sampled values: they still miss references named unlike their collection.

### It. 10 — Remaining engines + connectivity ✅ done
- Oracle (go-ora), ClickHouse, DuckDB.
- Redis: key browser (SCAN), all types, TTL, CLI, pub/sub viewer.
- SSH tunnels (password/key/agent) and TLS for network engines. SQLite and DuckDB use local files.
- **Done when:** a CI matrix connects every engine in PRD §5 over direct, TLS and SSH, and each new engine passes the shared `enginetest` suites.

**Status:** done in PRs #51 to #59 (protocol version 10): ADRs 0018 (tunnels and TLS), 0019 (DuckDB behind the `duckdb` build tag) and 0020 (key-value model) with the additive contract (#51); Oracle (#53) and ClickHouse (#52); the SSH tunnel and shared TLS core with host-key checking (#54); the Redis and Valkey engine with `KeyValueService` (#55) and DuckDB behind its tag (#56); the Redis workspace in the app (#57); descriptor-driven connection settings, host-key dialogs, staged test results, a tunnel indicator in the status bar and the connectivity matrix (#58); and native bounded DuckDB streaming on a pinned driver fork (#59). On #59 every hosted check passed: the full direct/TLS/SSH matrix (Cosmos DB skipped, as it needs an account), DuckDB on macOS, Linux and Windows, and the Flutter and end-to-end jobs. Measurements are in `docs/perf/iteration-10.md`: a 1M-row or 1M-key stream keeps live heap flat on Oracle, ClickHouse and Redis, a DuckDB 10M-row `SELECT` peaks at 76 MiB RSS (296 MiB on the upstream driver), idle core memory with a tunnel open is 23.6 MB, and the release build used 139.4 MiB combined RSS idle (116.5 MiB in the Lane E measurement; budget 150 MB).

**Known gaps (carry forward):**
- DuckDB uses a pinned personal fork of the driver (`replace` in `core/go.mod`) for native streaming; it must go back to the upstream module when streaming lands there. A C++ crash in the library still takes core down (ADR 0019 keeps the helper process as the fallback).
- Oracle: TCPS and wallets are passed through but untested (no TCPS listener in the dev image); cancel does not interrupt `DBMS_SESSION.SLEEP`; LOB cells are cut to 1 MiB.
- ClickHouse: the designer and schema plan report `UNSUPPORTED` (table engine clauses need their own design); engine, sorting key and partition key are not shown in the UI because the proto has no field for them.
- Redis: Sentinel is covered by configuration tests only; on Cluster only database 0 exists and `Subscribe` uses one node; only ReJSON is supported among modules, untested against a server with the module; no keyspace notifications.
- The status bar reacts to tunnel loss reported by SQL execution. Idle tunnel loss and loss reported only through document or key-value RPCs still need session-health reporting.
- Cosmos DB for MongoDB keeps its opt-in smoke test; it has not run against a real account.
- Not measured: app-side memory while paging a full Redis keyspace or under high-volume pub/sub, combined app and core memory with a live tunnel, a cold-start time to the completed Hello, and DuckDB RSS on Linux and Windows.

### It. 11 — Visual builders
- Aggregation pipeline builder: stage cards, per-stage preview, export to code.
- Visual query builder: tables + joins + filters (SQL); filter/projection builder (Mongo).
- **Done when:** builder ↔ code round-trip works for typical queries.

**Closed in Iteration 12:** The Mongo filter builder has a dedicated capped, cancellable preview (ADR 0021 §5).

### It. 12 — SQL Mode for Mongo + GridFS
- SQL → MQL translator (SELECT/WHERE/ORDER/LIMIT/GROUP BY/JOIN→$lookup); show generated MQL.
- GridFS viewer: browse buckets, preview images/text/PDF, upload/download.
- **Done when:** the translator passes a test corpus of 100+ queries.

**Plan:** `docs/plans/iteration-12.md`. Decisions in ADRs 0022 (SQL mode) and 0023 (GridFS); the additive contract (`TranslateMongoSql`, `GridFsService`, protocol version 12) landed in PR 0.

**Known gaps (carry forward):**

- **App idle memory remains over budget.** A release build idles at about 154–164 MiB app RSS plus 33 MiB sidecar RSS 30 s after launch, against the 150 MB combined budget. This has not regressed: release builds of the It. 10 close-out and of main idle within 3 MiB of each other. The earlier 185.1 MiB sample was taken while macOS reallocated the window's drawables, and the It. 10 figure of 139.4 MiB does not reproduce at its own commit. Next: one sampling method (footprint with categories, several launches, untouched window) and a profile of the ~325 MB launch-time peak. PR #76 fixed the core GridFS memory issue: sidecar RSS fell from 258.1 MiB to 87.7 MiB at the 20 s checkpoint after closing GridFS and disconnecting, and 1 GiB round trips peak at about 50–55 MiB core RSS with upload at about 205 MiB/s. See [app idle memory, It. 10 vs main](docs/perf/iteration-12-app-idle.md) and [Iteration 12 measurements](docs/perf/iteration-12.md).

## Phase D — Data tooling (it. 13–16)

### It. 13 — Import/export + mock data
- Import/export CSV, JSON/NDJSON, SQL dump, Parquet (DuckDB).
- Mock data generator: per-column faker rules, FK-aware, bulk insert with progress.
- **Done when:** you can generate 1M realistic rows into Postgres and Mongo in reasonable time.

### It. 14 — Profiler, monitoring, clusters
- Explain-plan visualizer (Postgres, MySQL, Mongo, SQL Server).
- Server monitoring dashboard (connections, ops/sec, slow queries, cache hit).
- Replica set / sharded cluster topology view.
- **Done when:** the slowest queries in a test workload can be found and explained in the app.

### It. 15 — Task manager + notifications
- Core-side scheduler: cron/interval jobs (run script, export, import, compare).
- Task history, logs, retries; desktop notifications + webhook.
- **Done when:** a nightly export job runs while the UI is closed (core runs as a background agent).

### It. 16 — Data compare + real-time sync
- Schema diff (SQL + Mongo validators/indexes) → migration script.
- Data diff by key with summary + row-level view → sync script.
- Real-time one-way sync (Postgres logical replication / Mongo change streams → target).
- **Done when:** two databases diverged by a test script are reconciled exactly.

## Phase E — Pro & 1.0 (it. 17–19)

### It. 17 — Charts & dashboards
- Charts from saved queries (line, bar, pie, table, KPI); dashboard grid layout; auto-refresh.
- **Done when:** a monitoring dashboard can be built without code.

### It. 18 — AI assistant + MCP server
- Providers: Anthropic/OpenAI-compatible APIs + Ollama; keys stored in the keychain.
- NL → SQL/MQL with schema context, explain/optimize query, fix error.
- MCP server in core: list connections, describe schema, run read-only queries; per-connection opt-in; write access needs explicit approval.
- **Done when:** Claude Code / Cursor can query a dev DB via Queravue's MCP server, and prod-flagged connections are refused.

### It. 19 — RBAC dashboard + release hardening
- Users/roles/grants view and editor (Postgres, MySQL, Mongo).
- Packaging: signed + notarized macOS DMG, Windows MSIX/installer, Linux AppImage/deb; auto-update.
- Performance pass against the PRD budgets; accessibility; docs site.
- **Done when:** a v1.0 release candidate installs cleanly on all three OSes.

## Parallel tracks (continuous)
- Integration test matrix in CI against Docker DBs (testcontainers-go).
- Memory/startup benchmarks tracked per release.
- ADRs in `docs/adr/` for every significant decision.
