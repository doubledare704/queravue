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
