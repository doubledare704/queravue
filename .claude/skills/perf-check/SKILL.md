---
name: perf-check
description: Measure Queravue memory, startup and grid-scroll performance against the PRD budgets. Use after changes to streaming, the result grid, startup, or before a release.
---
# Performance check against PRD budgets

Budgets: idle (UI+core) ≤ 150 MB; 1M-row result ≤ +200 MB; cold start ≤ 1.5 s (Apple Silicon); autocomplete ≤ 50 ms; smooth grid scroll (no frames > 16 ms in steady scroll).

## Steps
1. Build release: `cd core && go build -o ../app/macos/queravued ./cmd/queravued` and `cd app && flutter build macos --release`.
2. Start the docker DBs, and make sure the seed tables exist (`bench_1m` in Postgres and Mongo).
3. **Startup:** launch 5 times; record time from process start to the "core connected" log line (the app logs `startup_ms`). Take the median.
4. **Idle memory:** after 30 s idle, measure resident memory of the app and `queravued` (macOS: `footprint <pid>` or `ps -o rss= -p <pid>`). Sum both.
5. **Large result:** run `SELECT * FROM bench_1m`, scroll to the end, then measure memory again. Repeat for Mongo `db.bench_1m.find()`.
6. **Scroll:** run `flutter drive --profile` with `integration_test/perf/grid_scroll_test.dart` and read the frame timings summary (worst and p90 build/raster).
7. **Autocomplete:** run the benchmark test in `app/test/perf/autocomplete_bench_test.dart` on the 500-table fixture.
8. Append results to `docs/perf/history.md` (date, commit, numbers), and compare with the previous row.

## Report
A table with metric, budget, current, previous, and pass/fail. For any regression > 10%, find the commit range responsible and suggest the likely cause.
