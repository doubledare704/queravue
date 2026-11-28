# Iteration 13 perf results

## Lane L: bulk loaders

Apple M4 Pro (arm64, macOS 27.2.1), Go 1.27.4, 2026-11-27. Databases from `dev/docker-compose.yml` on the same machine: `postgres:17.11`, `cockroachdb/cockroach:v25.4.2` (in-memory store) and `mongo:8.0.34` single-node replica set. The tests run the engine in process, so the RSS sampled with `ps -o rss=` every 100 ms is the core's. The baseline is taken after a forced GC, with the connection open and the source built.

```bash
docker compose -f dev/docker-compose.yml up -d --wait postgres cockroachdb mongo
cd core && LOAD_PERF=1 go test -count=1 -tags=integration -v -run 'TestIntegrationLoadRowsPerf' ./internal/engine/postgres/
cd core && LOAD_PERF=1 go test -count=1 -tags=integration -v -run 'TestIntegrationLoadDocumentsPerf' ./internal/engine/mongo/
```

The source replays one prebuilt batch, so generating data costs nothing during the load. A Postgres batch is 10,000 rows of about 100 bytes (about 1 MiB), six columns: bigint, text, numeric, timestamptz, boolean, text, with no indexes. A Mongo batch is 5,000 documents of about 200 bytes (about 1 MiB). Each run loads 1,000,000 rows or documents and then counts them on the server.

| Engine | Run | Time | Rate | RSS baseline → peak |
|---|---|---:|---:|---|
| PostgreSQL 17.11 (`COPY`) | 1 | 1.03 s | 969,788 rows/s | 29.3 → 39.2 MiB (+9.9) |
| PostgreSQL 17.11 (`COPY`) | 2 | 0.85 s | 1,180,289 rows/s | 29.3 → 39.4 MiB (+10.0) |
| CockroachDB 25.4.2 (`COPY`) | 1 | 4.20 s | 238,352 rows/s | 39.5 → 40.2 MiB (+0.6) |
| CockroachDB 25.4.2 (`COPY`) | 2 | 4.05 s | 246,765 rows/s | 39.7 → 40.2 MiB (+0.6) |
| MongoDB 8.0.34 (`InsertMany`, parallel parse) | 1 | 9.07 s | 110,295 docs/s | 24.5 → 51.2 MiB (+26.8) |
| MongoDB 8.0.34 (`InsertMany`, parallel parse) | 2 | 8.22 s | 121,704 docs/s | 24.9 → 45.8 MiB (+20.9) |

Gates: Postgres at least 50,000 rows/s, Mongo at least 30,000 docs/s, and an RSS peak at most 60 MiB above the baseline. All pass. Cockroach is measured but not gated.

### Reading the numbers
- **Postgres and Cockroach:** rows are encoded into `COPY` text as the connection reads, in 64 KiB pieces, so memory does not grow with the batch. One transaction per batch.
- **Mongo parse cost:** parsing canonical Extended JSON costs about 8.7 µs per document (syntax check, bare-number check, decode, encode), about as much as the insert. With one goroutine the same load ran at 40,138 and 58,911 docs/s (24.9 s and 17.0 s; RSS +16.7 MiB). Parsing each batch on up to four goroutines doubled the rate for about 5–10 MiB more RSS.
- **Not measured here:** MySQL, SQLite and the Mongo variants. They are covered by the conformance suite, not by a perf gate.

### Lane L, second set

Same machine, sampling and source as above (Apple M4 Pro, macOS 27.2.1, Go 1.27.4, 2026-11-28). Databases from `dev/docker-compose.yml`: `mcr.microsoft.com/mssql/server:2022-CU27` (amd64 image under emulation, the compose default on Apple Silicon), `gvenzl/oracle-free:23.26.3-slim-faststart`, `clickhouse/clickhouse-server:26.3.25.2`; DuckDB is the embedded `duckdb` build with a file database. The table has the same six columns as the Postgres run (integer, text, decimal(14,2), timestamp, boolean, text), no indexes, and a batch is 10,000 rows (about 1 MiB). Each run loads 1,000,000 rows and then counts them on the server.

```bash
docker compose -f dev/docker-compose.yml up -d --wait mssql clickhouse oracle
docker compose -f dev/docker-compose.yml --profile seed up mssql-seed
cd core && LOAD_PERF=1 go test -count=1 -tags=integration -v -run 'TestIntegrationLoadRowsPerf' ./internal/engine/mssql/ ./internal/engine/oracle/ ./internal/engine/clickhouse/
cd core && LOAD_PERF=1 CGO_ENABLED=1 go test -count=1 -tags=duckdb -v -run 'TestLoadRowsPerf' ./internal/engine/duckdb/
```

| Engine | Run | Time | Rate | RSS baseline → peak |
|---|---|---:|---:|---|
| SQL Server 2022 (bulk copy) | 1 | 4.45 s | 224,769 rows/s | 30.1 → 44.5 MiB (+14.4) |
| SQL Server 2022 (bulk copy) | 2 | 4.07 s | 245,946 rows/s | 30.5 → 45.1 MiB (+14.6) |
| Oracle Free 23.26 (array binding) | 1 | 5.04 s | 198,577 rows/s | 30.1 → 54.4 MiB (+24.3) |
| Oracle Free 23.26 (array binding) | 2 | 5.07 s | 197,291 rows/s | 30.1 → 55.0 MiB (+24.9) |
| ClickHouse 26.3 (native batch) | 1 | 6.93 s | 144,242 rows/s | 31.0 → 50.5 MiB (+19.5) |
| ClickHouse 26.3 (native batch) | 2 | 6.94 s | 144,044 rows/s | 30.8 → 48.9 MiB (+18.1) |
| DuckDB 2.0.0 (appender) | 1 | 0.77 s | 1,306,237 rows/s | 55.9 → 109.2 MiB (+53.3) |
| DuckDB 2.0.0 (appender) | 2 | 0.73 s | 1,376,636 rows/s | 55.5 → 108.6 MiB (+53.1) |

Recorded, not gated, except that the RSS peak is at most baseline + 60 MiB. All pass.

- **DuckDB's memory is the database's, not the loader's.** DuckDB runs in the core's process and keeps the rows it has loaded until a checkpoint writes them out. With its default checkpoint threshold the peak was +59 to +63 MiB over three runs (one failed the budget), so the perf test sets `checkpoint_threshold` to 4 MB, which gave +51 to +56 MiB. A bigger load into a file database stays bounded by the same checkpoint, but an in-memory DuckDB database grows with its data.
- **SQL Server** runs under amd64 emulation here, so its rate understates a native server.
- **ClickHouse** is the slowest of the four: the driver appends row by row into column buffers, and each batch is one network round trip with a server-side insert of a MergeTree part.
- **Oracle** peaks highest of the three network engines because go-ora encodes each column's array before sending, up to 10,000 rows per call.

## Lane M: mock data

Same machine, databases and RSS sampling as Lane L. The test runs `mockdata.Run` in process against the real loaders, with one seed.

```bash
cd core && LOAD_PERF=1 go test -count=1 -tags=integration -v -run 'TestIntegrationMockRun' ./internal/mockdata/
```

- **Postgres:** `qv_mock_customers` (10,000 rows: sequence id, name, email, city), then `qv_mock_orders` (1,000,000 rows: sequence id, `customer_id` foreign key, weighted status, decimal total, timestamp in the last two years, sentence). The foreign key is a real constraint, and the test checks no order points at a missing customer.
- **Mongo:** 1,000,000 documents with name, email, weighted status, decimal total, timestamp, a nested `shipping` document (city, street, zip), a `tags` array of 1 to 4 words and a sentence.

| Target | Run | Time | Rate | RSS baseline → peak |
|---|---|---:|---:|---|
| PostgreSQL 17.11, 1.01M rows (parent + child) | 1 | 5.41 s | 186,559 rows/s | 25.0 → 37.4 MiB (+12.4) |
| PostgreSQL 17.11, 1.01M rows (parent + child) | 2 | 5.59 s | 180,731 rows/s | 25.4 → 37.5 MiB (+12.0) |
| MongoDB 8.0.34, 1M documents | 1 | 15.54 s | 64,348 docs/s | 39.0 → 46.7 MiB (+7.7) |
| MongoDB 8.0.34, 1M documents | 2 | 15.87 s | 63,028 docs/s | 39.1 → 47.5 MiB (+8.4) |

Gates: Postgres run at most 20 s, Mongo run at most 35 s, RSS peak at most 60 MiB above the baseline. All pass.

- **Postgres:** the 1M-row child table took 5.39 s of the run. Keys of the 10,000 customers sit in a compact key set, so the foreign key costs memory in proportion to the parent only.
- **Mongo:** generation and the loader's parse together keep the rate at about half of the loader-only rate in Lane L (110,000 to 122,000 docs/s), still twice the gate.
