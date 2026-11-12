# Iteration 9 perf results (schema diagrams)

## PR 2: schema graph in core

Apple M4 Pro, 2026-11-10, databases from `dev/docker-compose.yml`.

```bash
docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed
cd core && go test -count=1 -tags=integration -run TestIntegrationLargeSchemaGraph -v ./internal/diagram/
cd core && go test -run xxx -bench Assemble -benchmem ./internal/diagram/
cd core && go test -count=1 -tags=integration -v -run '/SchemaGraph$' ./internal/engine/...
```

Loading the graph of schema `large` on PostgreSQL 17 (500 tables, 7,480 columns, 480 foreign keys; three queries plus assembly, 30 runs in process, no RPC):

| | p50 | p95 | Budget |
|---|---|---|---|
| `diagram.Load` | 18.6 ms | 26.9 ms | 200 ms p95 |

Assembly alone (`BenchmarkAssemble500Tables`, generated 500 tables of 15 columns): 0.28 ms/op, 1.19 MB/op, 3,004 allocs/op.

The two bulk queries on the standard seed (about 35 columns and 2 foreign keys per engine, one run each, from the shared `SchemaGraph` integration test):

| Engine | Keyed columns | Relations |
|---|---|---|
| PostgreSQL 17 | 2.3 ms | 1.2 ms |
| CockroachDB 25.4 | 9.8 ms | 26.6 ms |
| MySQL 8.4 | 1.5 ms | 0.6 ms |
| MariaDB 11.4 | 1.4 ms | 1.1 ms |
| TiDB 8.5 | 2.7 ms | 8.2 ms |
| SQL Server 2022 (amd64 under emulation, first call) | 31.1 ms | 51.6 ms |

## PR 3: diagram view (app, profile build)

`make test-perf-diagram` (`app/integration_test/diagram_perf_test.dart`): the real app and core, schema `large` on PostgreSQL 17 (500 tables, 480 relations), Apple M4 Pro, macOS profile build, 1440 x 900 window. Panning is a mouse drag of 120 steps, one frame per step.

| Measurement | Result | Budget |
|---|---|---|
| Open: tab created to diagram on screen (load, layout, first frames) | 137 ms | 1 s |
| Pan, whole diagram visible (10 % zoom, boxes only): UI frame p90 / worst | 2.8 ms / 3.3 ms | 16 ms |
| Pan at 30 % (names only): UI frame p90 / worst | 2.1 ms / 3.8 ms | 16 ms |
| Pan at 80 % (columns shown): UI frame p90 / worst | 2.2 ms / 2.7 ms | 16 ms |

The test asserts the open time and a p90 UI frame time under 8 ms in profile mode. Raster times are not asserted: this backend reports them as zero.

Layout alone (unit test, debug mode): 100 tables in 0.3 ms, 500 tables in 1.4 ms (budget 100 ms for 100 tables), so it stays on the UI thread.

## PR 4: export (app, profile build)

Same run as PR 3 (`make test-perf-diagram`), exporting what the diagram shows with the functions the export actions use, file writing excluded.

| Schema | SVG | PNG |
|---|---|---|
| `large`: 500 tables, 480 relations | 17 ms, 1.9 MB | 1.07 s, 5,713 × 4,202 px at 0.58 px per unit (24 MP cap), 6.3 MB |
| `public`: 9 tables, 2 relations | under 1 ms, 11 KB | 0.15 s, 3,684 × 824 px at 2 px per unit, 0.3 MB |

The test asserts SVG under 1 s and PNG under 5 s in profile mode. Making the PNG blocks no frame for long: the picture is recorded on the UI thread in about the time of one frame, the encoding happens off it. Peak memory during a 24 MP export was not measured.

Two of nine local runs of this test stalled until the 5-minute timeout, and one took 77 s; the stall was never caught in the act. The likely cause is the test's `pumpAndSettle` after selecting the connection, which never returns while a spinner in the live schema tree keeps animating; it now pumps once. Four runs after the change passed in about 10 s each. That is too few to call the stall gone.

## Not measured yet
- Memory of the app with a 500-table diagram open.
- The diagram perf test is local only (`make test-perf-diagram`), not in CI.
- A 500-table schema on engines other than PostgreSQL: only PostgreSQL has the large seed.
- The streamed RPC end to end, and memory of a cached 500-table graph in the running core.
