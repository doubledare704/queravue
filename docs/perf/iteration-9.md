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

## Not measured yet
- A 500-table schema on engines other than PostgreSQL: only PostgreSQL has the large seed.
- The streamed RPC end to end, and memory of a cached 500-table graph in the running core.
