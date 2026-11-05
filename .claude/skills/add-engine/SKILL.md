---
name: add-engine
description: Add a new database engine (driver) to the Queravue Go core end to end. Use when implementing support for a new SQL/NoSQL engine or a wire-compatible variant.
---
# Add a database engine to Queravue

Read `PRD.md` §5 and the "Architecture rules" in `AGENTS.md` first.

## Steps
1. **Driver choice:** prefer a pure-Go, permissively licensed (MIT/BSD/Apache), actively maintained driver. If the engine is wire-compatible with an existing one (CockroachDB→postgres, TiDB→mysql, Cosmos/DocumentDB→mongo), add a *variant* to the existing package instead of a new one.
2. **Package:** create `core/internal/engine/<name>/` with:
   - `engine.go`: implements base `Engine` (Connect, Ping, Close, Execute streaming row batches, Cancel via context).
   - one file per capability it supports (`schema.go` → `SchemaInspector`, `explain.go` → `Explainer`, `document.go` → `DocumentStore`, `kv.go` → `KeyValueStore`, `monitor.go` → `Monitor`, `users.go` → `UserManager`).
   - `dialect.go` (SQL engines): identifier quoting, pagination, introspection queries, type mapping to proto value types.
3. **Register** in `core/internal/engine/registry.go` with an id, display name, default port, connection-string parser, and capability list.
4. **Connection options:** TLS, SSH tunnel (via `internal/tunnel`), and auth modes. Secrets only via `internal/secrets`.
5. **Errors:** wrap as `fmt.Errorf("<name>: <op>: %w", err)`, mapping auth/network/syntax errors to typed core errors. Recover panics in goroutines.
6. **Dev DB:** add a service to `dev/docker-compose.yml` (pinned image tag, healthcheck, seed script in `dev/seed/<name>/`).
7. **Tests:**
   - unit tests for dialect and connection-string parsing (table-driven);
   - `//go:build integration` tests: connect, ping, stream 100k rows, cancel mid-stream, schema introspection, and each capability.
8. **Docs:** update the PRD §5 table, add an icon/id mapping in `app/lib/shared/engines.dart`, and note any limitations in `docs/engines/<name>.md`.

## Done when
- `go build ./... && go test ./... && go test -tags=integration ./internal/engine/<name>/...` pass.
- The UI shows the engine in "New connection" and enables only the features its capabilities report. No `if engine == "<name>"` checks in the UI.
- A 1M-row query streams without core memory growing beyond one batch window.
