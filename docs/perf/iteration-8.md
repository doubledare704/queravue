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

## Not measured yet
- Keystroke → popup frame (50 ms budget): needs the UI, PR 4.
- Bulk introspection timings on MySQL, MariaDB, SQL Server, CockroachDB and TiDB. The queries are covered by the shared `BulkColumns` integration suite; only PostgreSQL, MySQL and MariaDB were run locally.
- Cold start and idle memory with the warm-up running at session open: the catalog is small, but the whole-process numbers need the perf-check run with the UI.
