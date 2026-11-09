# Iteration 8 perf results (editor intelligence)

## PR 2: core completion

Apple M4 Pro, 2026-11-08, PostgreSQL 17 from `dev/docker-compose.yml`. The schema is `dev/seed/postgres/large` (500 tables, 7,480 columns, 480 foreign keys) next to the standard seed.

```bash
docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed
cd core && go test -count=1 -tags=integration -run TestIntegrationLargeSchema -v ./internal/completion/
cd core && go test -run xxx -bench Complete -benchmem ./internal/completion/
```

Catalog warm-up, in process against the real server:

| | Result | Budget |
|---|---|---|
| Warm-up of 2 schemas, 509 tables, 7,512 columns (one `ListObjects` and one bulk column query per schema) | 13.7 ms | background, cancellable |
| Heap held by that catalog | +0.46 MiB | idle memory ≤ 150 MB |

Core completion on that catalog (`Complete` only, no RPC; 300 runs per scenario):

| Scenario | p50 | p95 |
|---|---|---|
| select list, empty prefix, 3 tables in scope | 230 µs | 472 µs |
| `alias.` columns | 5.3 µs | 17 µs |
| `alias.pre` columns | 4.5 µs | 13 µs |
| `FROM ` empty prefix (all tables) | 157 µs | 414 µs |
| `FROM inv` prefix | 148 µs | 370 µs |
| `FROM ci` word initials | 169 µs | 390 µs |
| `WHERE sta` unqualified prefix | 178 µs | 418 µs |
| `sel` keyword at statement start | 150 µs | 374 µs |
| CTE columns | 2.2 µs | 5.5 µs |

Budget: core completion ≤ 10 ms p95. The worst scenario is about 20 times under it.

Go benchmark (`BenchmarkCompleteOn500Tables`, generated 500-table catalog, 200 items returned):

| Scenario | ns/op | B/op | allocs/op |
|---|---|---|---|
| select list empty | 224,000 | 293,743 | 2,511 |
| `alias.` columns | 6,359 | 9,631 | 110 |
| `FROM ` empty | 186,000 | 272,726 | 2,046 |
| `FROM inv` | 166,000 | 328,139 | 4,252 |
| `WHERE sta` | 196,000 | 359,886 | 5,211 |
| keyword start | 170,000 | 335,076 | 4,543 |

## Mongo completion (core)

Go benchmark (`BenchmarkCompleteMongoFilterKeys`, a sample with about 2,000 distinct nested paths, filter key position, Apple M4 Pro): 0.69 ms/op, 1.2 MB/op, 21,263 allocs/op. Budget ≤ 10 ms. Sampling cost on a real server is paid once per collection and 5 minutes; `Complete` never waits more than 150 ms for it.

## Keystroke to popup (app, profile build)

`make test-perf-completion` (`app/integration_test/completion_perf_test.dart`): the real app and core, the seeded Postgres 17 schema `large` (500 tables, about 7,500 columns), Apple M4 Pro, macOS profile build. Typing is injected as IME deltas into the SQL editor, one character at a time with 90 ms between characters; the clock runs from the insertion until the frame that shows the popup, vsync included. 6 rounds of 4 scenarios (`FROM large.` + `account_a`, alias columns after `x.`, `SELECT ` + `co`, a second table after `JOIN large.`).

| Measurement | Samples | p50 | p95 | Budget |
|---|---|---|---|---|
| First character of a word (popup opens) | 24 | 13.4 ms | 19.4 ms | 50 ms |
| Next characters (list narrows) | 72 | | 25.1 ms | 50 ms |
| `Complete` round trip over the socket, no UI | 60 | | 2.8 ms | |

The test asserts both p95 values in profile mode. The first character is fast because the previous keystroke (the dot, the space) already asked the core; a keystroke that opens a context nobody asked about yet (a paste) shows its popup one keystroke later, not measured here. re_editor's own 50 ms delay is removed by the vendored patch (`docs/editor.md`).

Along the way the run found a core bug that the unit tests could not: the first warm-up of a session raced with the schema browser on the same driver connection (`conn busy`), failed silently and never retried, so completion stayed cold. Warm-up queries now retry while the connection is busy, a failed warm-up is logged and retried after 5 seconds.

## Layout restore
Restoring 60 query tabs in two groups from `.queravue/layout.json` takes 6 ms in the unit test (fake repository, so it measures the model and tab creation, not the core's file read). Only the layout file is read; a bound file is read when its tab is first shown, and a tab body is built only then, so cold start does not grow with the number of saved tabs. Whole-app cold start was not re-measured.

## Not measured yet
- Bulk introspection timings on MySQL, MariaDB, SQL Server, CockroachDB and TiDB. The queries are covered by the shared `BulkColumns` integration suite; only PostgreSQL, MySQL and MariaDB were run locally.
- Cold start and idle memory with the warm-up running at session open: the catalog is small, but the whole-process numbers need the perf-check run with the UI.
