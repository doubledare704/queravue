# CLAUDE.md

@AGENTS.md

## Claude Code specifics
- MCP servers for this repo are in `.mcp.json` (Dart/Flutter tooling, gopls).
- After editing Dart, use the Dart MCP `analyze_files` tool and `hot_reload` if the app is running.
- After editing Go, run `go build ./... && go test ./...` in `core/` before reporting done.
- Use plan mode for anything touching `proto/` or the `Engine` interface.
- Follow "Code style: names over comments" in AGENTS.md. Default to writing no comments; rename or extract instead. Put explanations that need more than two lines into `docs/` (md files), not into code.
- Keep generated-code, test and implementation files lean: no restating doc comments, no narration of obvious steps.
