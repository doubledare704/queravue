# ADR 0019 — DuckDB and cgo

**Status:** Accepted · 2026-11-14 (implemented in Iteration 10, Lane C)

## Context
DuckDB's Go driver wraps the C++ library through cgo. AGENTS.md prefers pure-Go drivers "except DuckDB" and says to ask before adding cgo dependencies. This ADR records the decision.

The Go module is `github.com/duckdb/duckdb-go` (formerly `github.com/marcboeker/go-duckdb`, MIT). Lane C confirmed both against the latest tagged release, `v2.20000.0` (DuckDB 2.0.0): the module is `github.com/duckdb/duckdb-go/v2`, its `LICENSE` is MIT (Copyright Marc Boeker and the Stichting DuckDB Foundation), and `marcboeker/go-duckdb` stopped at `v2.4.3`, so the move to `duckdb/duckdb-go` happened at `v2.5.0`. Since DuckDB 1.5 the version is `v2.MAJOR_MINOR_PATCH.x`, so `v2.20000.0` carries DuckDB 2.0.0. The library is not built from source: the driver pulls prebuilt static archives from `go.duckdb.org/libduckdb/<os>-<arch>` modules (macOS, Linux and Windows on amd64, plus arm64 on macOS and Linux). cgo is still needed, to link them, so a C compiler is required but a C++ build of DuckDB is not.

## Decision
**(a) Link the driver into core behind a `duckdb` build tag.** The default build stays cgo-free; the release build and the DuckDB CI jobs build with `-tags duckdb`. Without the tag the engine is not registered.

| | (a) build tag in core | (b) `queravued-duckdb` helper |
|---|---|---|
| Cross-compiling | Needs a C compiler per target (macOS universal, Windows, Linux amd64/arm64) to link the prebuilt library: native runners, not cross-compiles | Same toolchain need, but only for the helper |
| Binary size | Core grows by the DuckDB library: measured 57.7 MB to 114.2 MB (macOS arm64, `-s -w`), +56.5 MB | Core unchanged; helper carries the library |
| CI cost | One extra cgo job per OS | Extra binary, protocol and packaging on top |
| Crash isolation | A C++ crash takes core down; Go `recover` cannot catch it | Helper dies alone |
| Complexity | Same `Engine` interface, no new process | A second process protocol, lifecycle and updater path |

Crash isolation is the weak point of (a). It is accepted because (b) needs a new process protocol and release path for one engine, and DuckDB is embedded and in-process by design. Revisit if crashes show up in the field.

## Consequences
- CI builds the cgo variant on macOS, Linux and Windows runners; `go build ./... && go test ./...` also runs with `-tags duckdb`.
- The default developer build needs no C compiler for DuckDB; `make core-duckdb` builds with it (docs/engines/duckdb.md).
- CI keeps the existing jobs cgo-free and adds a `core-duckdb` job on macOS, Linux and Windows; the `core` job fails if the default build links DuckDB.
- DuckDB is the only cgo dependency. Adding another still needs a new ADR.
- Not chosen: (b). Kept as the fallback if (a)'s crashes or release builds prove unmanageable.
