# CLAUDE.md

@AGENTS.md

## Claude Code specifics
- MCP servers for this repo are in `.mcp.json` (Dart/Flutter tooling, gopls).
- After editing Dart, use the Dart MCP `analyze_files` tool and `hot_reload` if the app is running.
- After editing Go, run `go build ./... && go test ./...` in `core/` before reporting done.
- Use plan mode for anything touching `proto/` or the `Engine` interface.
