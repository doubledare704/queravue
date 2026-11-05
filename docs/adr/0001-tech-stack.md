# ADR 0001 — Tech stack: Flutter UI + Go core

**Status:** Accepted · 2026-11-05

## Context
Desktop DB GUI targeting VisuaLeaf Community+Basic+Pro parity. Constraints: low memory (no Electron/webview), fast dev loop, author's background in TS/JS/Python.

## Decision
- UI: Flutter desktop (Skia/Impeller, no webview, hot reload).
- Core: Go sidecar process owning all DB I/O, tasks, monitoring, MCP server.
- Contract: gRPC/protobuf over Unix socket (loopback + token on Windows).

## Rationale
- Go compiles in seconds; Flutter hot reload is sub-second. Rust was rejected for its slow compile loop.
- Go drivers cover every target engine, including pure-Go Oracle (go-ora).
- Flutter is strong for canvas-heavy UI (ER diagrams, visual builders, charts).
- A sidecar isolates driver crashes from the UI.

## Alternatives considered
Electron (too heavy); Tauri+Svelte (webview); Rust+GPUI (compile time, learning curve); Flutter+Rust core (compile time); Avalonia, Qt/PySide, Slint/Iced/egui (language cost or too much custom widget work).

## Consequences / risks
- Data grid and code editor quality in Flutter must be proven early (It. 2 spike).
- Flutter desktop multi-window maturity to be verified.
- Go GC adds ~10–30 MB vs Rust; acceptable within budget.
