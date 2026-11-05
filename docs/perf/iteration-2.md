# Iteration 2 perf results

`make test-perf` (profile build, macOS, Apple M4 Pro, 1440×900, docker Postgres 17, 2026-11-05).
Scenario from `spikes/grid`, now through the real core: `SELECT … FROM generate_series(1,1000000)` with six columns.

| | Result | Budget |
|---|---|---|
| Steady scroll, UI frame p90 / worst | 1.8 / 2.9 ms | < 12 ms |
| Steady scroll at row 900k, p90 | 1.6 ms | — |
| Jump to row 900k (`FetchRows` + paint) | 16 ms | < 100 ms |
| App RSS growth, idle → after 1M rows and scrolling | +19 MB (peak 214 MB) | < 200 MB |
| Run to finish (1M rows incl. server-side md5) | 11.6 s | — |

Core side (`make test-integration`, `TestIntegrationMillionRowsSpoolFetchAndHeap`): 1M narrow rows spool in ~0.6 s, core heap growth ~3 MB (budget 50 MB), `FetchRows` at offset 900k in ~0.2 ms.

Note: app idle RSS in the profile build is 182 MB before any query, above the 150 MB idle target for UI + core. That is the Flutter macOS runtime and predates this iteration; it is not part of the grid's growth.
