# ADR 0019 — DuckDB and cgo

**Status:** Proposed · 2026-11-14 (adds a cgo dependency; needs owner sign-off before Lane C starts)

## Context
DuckDB's Go driver wraps the C++ library through cgo. AGENTS.md prefers pure-Go drivers "except DuckDB" and says to ask before adding cgo dependencies. This ADR records the decision.

The Go module is `github.com/duckdb/duckdb-go` (formerly `github.com/marcboeker/go-duckdb`, MIT). Lane C confirms the module path and licence against the tagged release before adding it.

## Decision
**(a) Link the driver into core behind a `duckdb` build tag.** The default build stays cgo-free; the release build and the DuckDB CI jobs build with `-tags duckdb`. Without the tag the engine is not registered.

| | (a) build tag in core | (b) `queravued-duckdb` helper |
|---|---|---|
| Cross-compiling | Needs a C++ toolchain per target (macOS universal, Windows, Linux amd64/arm64): native runners, not cross-compiles | Same toolchain need, but only for the helper |
| Binary size | Core grows by the DuckDB library (tens of MB) | Core unchanged; helper carries the library |
| CI cost | One extra cgo job per OS | Extra binary, protocol and packaging on top |
| Crash isolation | A C++ crash takes core down; Go `recover` cannot catch it | Helper dies alone |
| Complexity | Same `Engine` interface, no new process | A second process protocol, lifecycle and updater path |

Crash isolation is the weak point of (a). It is accepted because (b) needs a new process protocol and release path for one engine, and DuckDB is embedded and in-process by design. Revisit if crashes show up in the field.

## Consequences
- CI builds the cgo variant on macOS, Linux and Windows runners; `go build ./... && go test ./...` also runs with `-tags duckdb`.
- The default developer build needs no C++ toolchain.
- DuckDB is the only cgo dependency. Adding another still needs a new ADR.
- Not chosen: (b). Kept as the fallback if (a)'s crashes or release builds prove unmanageable.
