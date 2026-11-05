# Queravue — Product Requirements Document

**Status:** Draft v0.1 · **Owner:** Oleksii · **Last updated:** 2026-11-05

## 1. Vision
A fast, lightweight, native desktop database workspace for SQL and NoSQL engines. It ships, free, the full feature set that tools like VisuaLeaf split across Community / Basic / Professional tiers. It should feel instant and stay light on memory: no Electron, no webview.

## 2. Target users
- **Backend / full-stack developers** who juggle Postgres, MySQL, MongoDB and Redis daily.
- **Data-curious engineers / analysts** who need to explore schemas, run queries, chart results.
- **Small teams** who want shared saved queries, dashboards and safe access to prod.

## 3. Goals
1. Parity with VisuaLeaf Community + Basic + Pro features (see §6).
2. One app for all target engines (see §5).
3. Low resource use: see non-functional requirements (§7).
4. Keyboard-first, fast UX: open a connection and run a query in < 5 s from launch.

## 4. Non-goals (v1)
- Web / SaaS version.
- Mobile apps.
- Being a full DBA suite (backup orchestration, replication setup wizards).
- Cloud account / sync service (local-first; team features via shared files/Git first).

## 5. Supported engines

| Engine | Go driver | Notes |
|---|---|---|
| PostgreSQL | `jackc/pgx` | also CockroachDB (wire-compatible) |
| MySQL / MariaDB | `go-sql-driver/mysql` | also TiDB |
| SQL Server | `microsoft/go-mssqldb` | |
| Oracle | `sijms/go-ora` | pure Go, no Instant Client |
| SQLite | `modernc.org/sqlite` (pure Go) | |
| ClickHouse | `ClickHouse/clickhouse-go` | |
| DuckDB | `marcboeker/go-duckdb` | cgo |
| MongoDB | `go.mongodb.org/mongo-driver` | also Azure Cosmos DB (Mongo API), Amazon DocumentDB |
| Redis | `redis/go-redis` | |

## 6. Feature scope
Tier labels show where VisuaLeaf puts each feature. In Queravue everything is free.

### 6.1 Foundation (VisuaLeaf "Community")
- Connection manager: unlimited connections, groups/folders, colors (e.g. red = prod), SSH tunnel, TLS, connection string import.
- SQL editor: syntax highlight, schema-aware autocomplete, format, run selection, multiple tabs, history.
- Result grid: virtualized, streams millions of rows, sort/filter, copy as CSV/JSON/INSERT, inline edit with commit/rollback.
- Schema browser + table management (create/alter/drop tables, columns, indexes, FKs).
- MongoDB: browse collections; document views (JSON / tree / table); filter/sort/projection; CRUD.
- MongoDB shell (mongosh-compatible subset, embedded JS engine).
- Index manager (SQL + Mongo).
- Saved queries & scripts (stored as files, Git-friendly).
- Visual schema: ER diagrams (auto-layout, export PNG/SVG).
- Mongo schema validation editor (`$jsonSchema`).
- Aggregation pipeline JSON editor.
- Collection / table statistics.

### 6.2 Power features (VisuaLeaf "Basic")
- Redis: key browser, all data types, TTL, pub/sub viewer, CLI.
- SQL Mode for MongoDB (SQL → MQL translation).
- GridFS viewer (browse, preview, upload/download).
- Split panel views (tabs side-by-side, detachable panes).
- Visual aggregation pipeline builder (stage cards, live per-stage preview).
- Visual query builder (SQL + Mongo, drag & drop).
- Materialize ER diagrams: design a diagram and generate/apply DDL.
- Query profiler / explain plan visualizer.
- Mock data generator (schema-aware, realistic fakers, bulk insert).
- AI assistant: NL → SQL/MQL, explain/optimize a query. Bring your own key (OpenAI/Anthropic/etc.) or local model (Ollama).
- Task manager: scheduled/background jobs (scripts, exports, imports).
- Server monitoring: ops/sec, connections, slow queries, memory.
- Replica sets & sharded clusters: topology view, member status, read preference.

### 6.3 Team & Pro features (VisuaLeaf "Professional")
- Charts & dashboards built from saved queries, auto-refresh.
- Unlimited tasks + task notifications (desktop notifications, webhook/Slack).
- Real-time data sync between connections (one-way, with mapping).
- Data compare: schema diff + data diff → sync script.
- RBAC dashboard: view/manage users and roles (Postgres, MySQL, MongoDB).
- MCP server: expose connections to AI tools (Claude, Cursor, etc.). Read-only by default; per-connection allow-list.

### 6.4 Extras (not in VisuaLeaf, needed for a usable tool)
- Import/export: CSV, JSON, NDJSON, SQL dump, Parquet (via DuckDB).
- Command palette, keyboard shortcuts, themes (light/dark).
- Auto-update, crash reporting (opt-in).

## 7. Non-functional requirements
- **Memory:** idle (UI + core) ≤ 150 MB; one 1M-row result loaded ≤ +200 MB. Rows stream in batches; the grid only keeps a window of rows in memory.
- **Startup:** cold start to usable window ≤ 1.5 s on Apple Silicon.
- **Responsiveness:** UI never blocks on I/O; every query can be cancelled.
- **Security:** credentials stored in the OS keychain (macOS Keychain / Windows Credential Manager / libsecret); never logged; core listens only on a local socket with a per-launch auth token.
- **Reliability:** a driver crash or panic must not crash the UI; the core auto-restarts.
- **Platforms:** macOS (arm64, x64), Windows x64, Linux x64.
- **Privacy:** no telemetry by default.

## 8. Architecture (summary)
See `docs/adr/0001-tech-stack.md` and `AGENTS.md`.
- **UI:** Flutter desktop (`app/`).
- **Core:** Go sidecar process (`core/`), launched by the UI.
- **Contract:** gRPC + protobuf (`proto/`). Unix domain socket on macOS/Linux; loopback TCP + token on Windows. Result rows are server-streamed in batches.
- **Engine abstraction:** a Go `Engine` interface with optional capability interfaces (`SchemaInspector`, `Explainer`, `DocumentStore`, `KeyValueStore`, `Monitor`, ...). The UI enables features based on reported capabilities.

## 9. Success metrics
- Daily use by the author replaces other DB GUIs.
- All §6 features implemented and covered by integration tests against Docker test DBs.
- Memory/startup budgets met in CI benchmarks.

## 10. Open questions
- License: open source (which?) or source-available?
- Data grid: build custom virtualized grid vs. adopt pluto_grid / trina_grid / Syncfusion (license).
- Code editor widget: re_editor vs. flutter_code_editor vs. custom.
- State management: Riverpod (proposed) vs. Bloc.
- Team features storage: Git-backed files vs. optional self-hosted sync later.
- Mongo shell: goja subset vs. delegating to installed `mongosh`.
