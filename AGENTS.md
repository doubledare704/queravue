# AGENTS.md — Queravue

Instructions for AI coding agents (Claude Code, Codex, Cursor, Gemini CLI, ...) and humans.
Product scope lives in `PRD.md`; delivery plan in `ROADMAP.md`; decisions in `docs/adr/`.

## What this is
Queravue is a native desktop DB GUI for SQL + NoSQL engines.
- **UI:** Flutter desktop app in `app/`.
- **Core:** Go sidecar process in `core/`. It owns all DB I/O.
- **Contract:** gRPC/protobuf in `proto/`. This is the only way UI and core talk.

## Repo layout (target; create pieces as iterations need them)
```
app/                    Flutter desktop app
  lib/
    core_client/        generated gRPC stubs + sidecar launcher
    features/<feature>/ UI by feature (connections, editor, grid, schema, mongo, redis, ...)
    shared/             widgets, theme, utils
  test/  integration_test/
core/                   Go module: github.com/<owner>/queravue/core
  cmd/queravued/        sidecar entrypoint
  internal/api/         gRPC service implementations (thin)
  internal/engine/      Engine interface, capabilities, registry
  internal/engine/<name>/  one package per engine (postgres, mysql, mssql, oracle, sqlite, clickhouse, duckdb, mongo, redis)
  internal/secrets/     OS keychain access
  internal/tunnel/      SSH tunnels
  internal/tasks/       scheduler
  internal/mcp/         MCP server
proto/queravue/v1/      .proto files (buf)
dev/docker-compose.yml  test databases
docs/adr/               architecture decision records
```

## Commands
```bash
# test databases
docker compose -f dev/docker-compose.yml up -d

# contract (run after any .proto change; commit generated code)
cd proto && buf lint && buf generate

# core
cd core && go build ./... && go test ./... && golangci-lint run
cd core && go test -tags=integration ./...      # needs docker DBs

# app
cd app && flutter pub get && flutter analyze && flutter test
cd app && flutter run -d macos
```

## Architecture rules
1. **UI never talks to a database directly.** All DB access goes through core via gRPC.
2. **Contract first:** change `.proto`, then regenerate, then implement core, then UI. Never break field numbers; deprecate instead.
3. **Engines implement capabilities, not one fat interface.** Base `Engine` (connect, ping, close, execute) plus optional interfaces (`SchemaInspector`, `Explainer`, `DocumentStore`, `KeyValueStore`, `Monitor`, `UserManager`). Core reports capabilities and the UI enables features based on them. Never use `if engine == "postgres"` in the UI.
4. **Results stream.** Queries return a server stream of row batches (default 500 rows). Never collect a full result set in memory, in core or UI.
5. **Everything is cancellable.** Pass `context.Context` through every core call; the UI exposes cancel for any operation > 300 ms.
6. **Core must not crash.** Recover panics at the gRPC boundary and in each driver goroutine; return typed errors.

## Code style: names over comments
Code explains itself through naming. Files stay small; comments do not pad them.
- Name classes, methods, variables, fields and tests so that a reader needs no comment to know what they are and do. If you feel the urge to comment a block, first try a rename or extracting a well-named function.
- Do not comment what the code already says: no doc comment that restates the name (`// Close closes the connection`), no per-field or per-line narration, no section banners, no commented-out code, no change-log or "added in PR x" notes.
- A comment is allowed only for what names cannot carry: a non-obvious *why* (a server quirk, a workaround, a trade-off, a hidden invariant, a concurrency or security constraint). Write it as one short line directly above the code it explains, never trailing.
- Exported Go identifiers need a doc comment only when the linter requires one or when it adds information beyond the name. Keep it to one sentence. Dart: same rule, no `///` that repeats the member name.
- Anything longer than two lines is documentation, not a comment: put it in `docs/` (engine notes in `docs/engines/`, decisions in `docs/adr/`) and, if needed, point to it with a one-line comment.
- When you touch a file, remove comments in the lines you change that break these rules. Do not mass-strip comments in code you are not changing.

## Go conventions
- Go ≥ 1.23. `gofmt`/`goimports`; `golangci-lint` clean.
- Wrap errors with context: `fmt.Errorf("postgres: list tables: %w", err)`. No `panic` for control flow.
- `context.Context` is the first param of anything doing I/O.
- Logging: `log/slog`, structured. **Never log credentials, connection strings with passwords, or row data.**
- Tests: table-driven unit tests; integration tests behind `//go:build integration` using docker-compose DBs or testcontainers-go.
- Prefer pure-Go drivers (avoid cgo) except DuckDB.

## Flutter / Dart conventions
- Latest stable Flutter; `flutter analyze` must be clean (`very_good_analysis` or `flutter_lints`).
- State management: Riverpod, plain Notifiers without codegen (ADR 0002). Feature-first folders.
- No business logic in widgets; widgets call providers/controllers, which call `core_client`.
- Large data: only virtualized lists/grids; never build widgets for off-screen rows.
- Keyboard-first: every main action has a shortcut and a command-palette entry.
- Golden tests for key widgets; integration tests drive the app against a real core + docker DBs.

## Performance budgets (from PRD — check on any change to the grid, streaming or startup)
- Idle memory (UI + core) ≤ 150 MB. 1M-row result ≤ +200 MB.
- Cold start ≤ 1.5 s on Apple Silicon. Autocomplete ≤ 50 ms.

## Security
- Secrets only in the OS keychain via `internal/secrets`. Config files hold references, not passwords.
- Core listens on a Unix socket (macOS/Linux) or loopback + random token (Windows); reject requests without the token.
- Connections flagged `production` default to read-only in the MCP server and require confirmation for destructive statements in the UI.

## Working agreement for agents
- Work iteration by iteration from `ROADMAP.md`. Keep PRs small and focused on one roadmap item.
- Before coding: read the relevant PRD section and ADRs. If a decision isn't covered, propose an ADR instead of guessing.
- Definition of done: builds + lint + unit tests green; integration tests added for new engine behaviour; budgets not regressed; docs/ADR updated.
- Don't add dependencies without a reason in the PR description; prefer well-maintained, permissively licensed packages (MIT/BSD/Apache).
- Don't copy code, UI assets, text or branding from VisuaLeaf or other proprietary tools. Re-implement features from their descriptions only.
- Ask before: changing the proto contract in a breaking way, adding cgo deps, changing the security model.
