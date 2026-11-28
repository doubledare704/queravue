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

## Lane F: import and export

Same machine, database and RSS sampling as Lane L. The tests call `TransferService` in process against the real Postgres (`postgres:17.11`), so the RSS is the core's. The source of the 1 GiB import is a generator that produces CSV on demand and hands it over in 1 MiB chunks; the exports discard the chunks they receive. No indexes.

```bash
docker compose -f dev/docker-compose.yml up -d --wait postgres
cd core && LOAD_PERF=1 go test -count=1 -tags=integration -v -timeout 40m -run 'TestIntegrationPerfImport1GiB' ./internal/api/
cd core && LOAD_PERF=1 CGO_ENABLED=1 go test -count=1 -tags=integration,duckdb -v -timeout 40m -run 'TestIntegrationPerfExport1MRows' ./internal/api/
```

The table has six columns: bigint, text, numeric, timestamptz, boolean, text (about 100 bytes a row).

| Run | Size | Time | Rate | RSS baseline → peak |
|---|---|---:|---:|---|
| Import 1 GiB CSV into Postgres (`COPY`) | 11,139,171 rows | 90.3 s | 123,397 rows/s, 11.3 MiB/s | 34.0 → 50.7 MiB (+16.7) |
| Export 1M rows to CSV | 90.8 MiB | 0.7 s | 1,405,038 rows/s | 35.4 → 47.0 MiB (+11.6) |
| Export 1M rows to NDJSON | 145.1 MiB | 1.0 s | 1,029,622 rows/s | 47.0 → 47.7 MiB (+0.6) |
| Export 1M rows to SQL dump | 103.4 MiB | 0.9 s | 1,151,161 rows/s | 47.7 → 48.3 MiB (+0.5) |
| Export 1M rows to Parquet | 18.9 MiB | 1.3 s | 758,474 rows/s | 48.3 → 114.7 MiB (+66.4) |

Gate: an RSS peak at most 60 MiB above the baseline. The import, CSV, NDJSON and SQL runs pass. **Parquet does not: +63 to +67 MiB over several runs.** The test allows it 25 MiB more than the others (`parquetRSSAllowanceMiB`); the cause and the options are below.

### Parquet
- Spool disk: the peak size of the transfer's temporary directory (DuckDB file, spill and the Parquet output) was 30.0 MiB for the 18.9 MiB file.
- DuckDB `memory_limit`: 24 MiB, one thread, insertion order not preserved.
- **Why it is over.** Loading DuckDB the first time costs about 23 MiB of resident memory (the library and its first database) before any row arrives, measured in a bare test as 15 → 38 MiB. The rest grows by about 40 MiB in the first 250,000 rows and then stays nearly flat. `memory_limit` barely moves the peak: 8, 12, 16 and 24 MiB gave +67, +63, +67 and +66 MiB, and 32 MiB with the appender flushed every 8,192 rows gave +78 MiB. At 16 MiB, before the appender was flushed in small pieces, DuckDB failed to allocate; at 8 MiB the run was slower (1.6 s).
- **What helped**, in the order found: a DuckDB file in the temp directory instead of `:memory:` (+105 MiB, flat after the first rows), flushing the appender every 8,192 and then 2,048 rows (DuckDB buffers about 200,000 rows natively otherwise; +105 → +78 MiB), one thread and no insertion order.
- **Tried and dropped:** staging the rows as NDJSON and running `COPY (SELECT * FROM read_ndjson(...)) TO ... (FORMAT parquet)`. `read_ndjson` allocates a 32 MiB buffer, so it cannot run inside a 12 MiB limit.
- Peak disk is the DuckDB file plus the Parquet file, 1.6 times the Parquet size for this table. Wide rows of long text compress differently, so the ratio varies.
- A second Parquet export right after the first grew RSS by another 20.5 MiB (105.7 → 126.3 MiB): macOS keeps the freed pages resident, so the peak does not return to the baseline between transfers, but it does not double either. The test asserts it stays inside the same allowance.
- The default build shows the same CSV, NDJSON and SQL numbers; those formats never load DuckDB.
