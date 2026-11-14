# Iteration 10 perf results

## Lane A: Oracle

Apple Silicon laptop, 2026-11-14, `gvenzl/oracle-free:23.26.3-slim-faststart` (arm64) from `dev/docker-compose.yml`, core and database on the same machine, `go-ora` v2.9.0 with `PREFETCH_ROWS=500`.

```bash
docker compose -f dev/docker-compose.yml up -d --wait oracle
cd core && go test -count=1 -tags=integration -v -run 'Suite/(Stream|Cancel)' ./internal/engine/oracle/
cd core && ORACLE_PERF=1 go test -count=1 -tags=integration -v -run Perf ./internal/engine/oracle/
```

### Streaming
`SELECT "id", "val", "label" FROM "million_items"` with a limit, into a sink that only counts rows. The heap is read after a forced GC every 10 batches, so it is live memory.

| Rows | Time | Rows/s | Peak live heap |
|---|---|---|---|
| 10,000 | 19 ms | 526,000 | 1 MB |
| 100,000 | 108 ms | 923,000 | 3 MB |
| 1,000,000 | 771 ms | 1,298,000 | 3 MB |

The shared suite's one-column 1M-row stream (`Stream1MMemory`) grows the heap from 1 MB to 3 MB, inside its 32 MB window. Cancelling a million-row stream after two batches returns `KindCanceled` and the session answers the next statement.

### Cancel
A context that ends 600 ms into the statement (`TestIntegrationCancelRunningStatement`):

| Statement | Stopped after |
|---|---|
| query that computes before its first row (self cross join) | 0.60 s |
| `DELETE` driven by a cross join | 0.60 s |
| PL/SQL `LOOP NULL; END LOOP` | 0.61 s |
| `DBMS_SESSION.SLEEP(20)` | 20.0 s (the break is not honoured during the sleep) |

### LOBs
50 rows with a 4 MB `CLOB` each (200 MB), and 10,000 rows with a 200-character `CLOB` and a 2-byte `BLOB`. `PRE` is the driver's inline fetch (the default here), `POST` streams each LOB from a locator.

| Mode | 50 x 4 MB: time | peak live heap | 10,000 small LOBs: time | peak live heap |
|---|---|---|---|---|
| `PRE` | 309 ms | 4 MB | 25 ms | 1 MB |
| `POST` | 1,192 ms | 4 MB | 2,028 ms | 1 MB |

Live memory is flat in both modes, because the driver decodes a row at a time and core caps each cell at 1 MiB. Without a forced GC the 4 MB case reaches 895 MB of heap (`PRE`) or 250 MB (`POST`) between collections: that is garbage, which the Go GC reclaims, but a process under a small memory limit sees the churn. `PRE` stays the default because small LOBs are common (any `CLOB` column) and 80 times faster.

### Catalog cost
Schema `QUERAVUE` with 500 tables of 15 columns (7,542 columns, 502 foreign keys), statistics gathered, owner-filtered queries. First call includes the server's parse of the dictionary views; the second is warm.

| Call | First | Warm | Rows |
|---|---|---|---|
| `ListObjects` | 302 ms | 310 ms | 509 |
| `ListColumns` (completion) | 110 ms | 106 ms | 7,542 |
| `ListKeyedColumns` (graph) | 422 ms | 136 ms | 7,542 |
| `ListRelations` (graph) | 324 ms | 56 ms | 502 |
| `DescribeTable` (one table) | 744 ms | 38 ms | 15 |
| `ListIndexes` (one table) | 451 ms | 8 ms | 1 |

The owner filter is what keeps these cheap. The same views without it, on a database that holds only Oracle-maintained schemas besides this one:

| Query | Time | Rows |
|---|---|---|
| `COUNT(*)` of `ALL_TAB_COLUMNS`, all owners | 328 ms | 32,639 |
| `COUNT(*)` of `ALL_TAB_COLUMNS`, one owner | 79 ms | 7,542 |
| `COUNT(*)` of `ALL_CONSTRAINTS`, all owners | 384 ms | 1,208 |
| `COUNT(*)` of `ALL_CONS_COLUMNS`, all owners | 169 ms | 1,206 |

Cold `DescribeTable` is the slowest first-use cost (744 ms): opening a table for the first time after connecting pays for parsing the constraint and index views. Not measured: a database with tens of thousands of objects, and a connection that lacks `SELECT` on the `DBA_` views (core uses only `ALL_` views).


## Lane B: ClickHouse

Dev container `clickhouse/clickhouse-server:26.3.25.2`, native protocol on localhost, Apple Silicon, `go test -tags=integration ./internal/engine/clickhouse/` (three runs).

| Measurement | Result | Budget |
|---|---|---|
| Stream 1M rows (`million_items`, `id` as int): time | 130–160 ms | n/a |
| Heap during the 1M-row stream | 1 MB before, 3 MB peak | ≤ +200 MB |
| Stream 100k rows | 20–50 ms | n/a |
| Cancel mid-stream (1M-row query, cancelled after 2 batches) | stopped after 1,000 rows | stops promptly |
| Cancel reaches the server (`sleepEachRow` query gone from `system.processes`) | within 150 ms of the cancel | n/a |

Not measured: a wide 1M-row result (many columns, strings, arrays), the app-side grid memory, and a TLS connection.


## Lane C: DuckDB

Apple Silicon laptop, 2026-11-14, macOS, `duckdb-go` v2.20000.0 (DuckDB 2.0.0), in-process, no container. The file is `dev/seed/duckdb/01_seed.sql` (1M-row `million_items`, 16.8 MB on disk).

```bash
cd core && CGO_ENABLED=1 go test -count=1 -tags duckdb -v -run 'TestEngineSuite/(Stream|Cancel)' ./internal/engine/duckdb/
cd core && CGO_ENABLED=1 go test -count=1 -tags duckdb -v -run TestCancel ./internal/engine/duckdb/
cd core && DUCKDB_PERF_FILE=/tmp/qv.duckdb DUCKDB_PERF=1 go test -count=1 -tags duckdb -v -run Perf ./internal/engine/duckdb/   # run twice: the second run opens the existing file
```

### Binary size
`CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' ./cmd/queravued` against `CGO_ENABLED=1 ... -tags duckdb` (macOS arm64):

| Build | `queravued` |
|---|---|
| default (no tag, no cgo) | 57.7 MB |
| `-tags duckdb` | 114.2 MB (+56.5 MB) |

### Streaming and memory
`SELECT` into a sink that only counts rows, second process (it only opened the file). The Go heap is read every 20 batches; resident memory is `ps` of the test process, sampled every 20 ms.

| Result | Time | Rows/s | Go heap | Peak resident |
|---|---|---|---|---|
| idle, file open | | | 0 MB | 45.7 MB (19.8 MB before opening) |
| 1M rows x 3 columns | 164 ms | 6,096,000 | 0 to 3 MB | 83 MB (+37 MB) |
| 1M rows, one `INTEGER` | 45 ms | 22,096,000 | 0 to 3 MB | 84 MB |
| 10M rows x 2 columns | 1.19 s | 8,435,000 | 0 to 3 MB | 296 MB (+250 MB) |
| 10M rows x 2 (about 600 MB of result), `memory_limit=256MB` | 1.52 s | | | 796 MB |

The shared suite's `Stream1MMemory` grows the Go heap from 0 to 3 MB, inside its 32 MB window, and the 1M-row cancel stops after 1,000 rows.

**The Go heap is flat, the process is not.** `duckdb-go` runs a statement to completion and then reads the result in chunks, so the whole result lives in DuckDB's memory until the statement ends: resident memory grows with the result, about 12 bytes per cell, and the finished result's pages are not returned to the OS right away. `memory_limit` does not cap it (the 600 MB result went past 256 MB). The idle budget (150 MB for UI and core) holds with the engine linked and a file open (45.7 MB); the 1M-row budget of +200 MB holds (+37 MB) for narrow rows and is the thing to watch for wide ones. A streaming path through `duckdb_pending_prepared_streaming` is the fix if it matters (docs/engines/duckdb.md, Limitations).

### Cancel
A context that ends 600 ms into the statement (`TestCancelInterruptsARunningStatement`):

| Statement | Stopped after |
|---|---|
| `SELECT count(*)` over a cross join of `range()` | 0.60 s |
| `CREATE TABLE AS` over a cross join | 0.63 s |

`duckdb_interrupt` works on a running statement; on a finished result the context is checked between batches. The session answers the next statement in both cases.

## Lane F: SSH tunnels and TLS

Apple Silicon laptop, 2026-11-14, `ssh-bastion` (`linuxserver/openssh-server` 10.3) and `postgres:17.11` from `dev/docker-compose.yml`, core and containers on the same machine.

```bash
cd core && NETCELLS_PERF=1 go test -count=1 -tags=integration -v -run TestIdleMemoryWithTunnelOpen ./internal/netcells/
```

| Measurement | Result | Budget |
|---|---|---|
| Resident memory of the test process (core code, all drivers linked) before opening | 22.6 MB | |
| Same, with a tunnel and a PostgreSQL session open and idle for 2 s | 23.6 MB | idle ≤ 150 MB (UI + core) |
| Go heap in use at that point | 2.4 MB | |
| Dial through the tunnel (password auth, local bastion) | 15 to 35 ms | |
| Open with a key file, with a passphrase-protected key | 40 ms, 360 ms | |

The passphrase-protected key costs its key derivation on every open, since the passphrase is read from the keychain and the key is parsed each time. Not measured: throughput of a large result over a tunnel, and a bastion across a real network.


## Lane D: Redis

Apple Silicon laptop, 2026-11-14, `redis:7.4.12` (arm64) from `dev/docker-compose.yml` seeded by `redis-seed` (1,000,030 keys), core and server on the same machine, `go-redis` v9.23.0, RESP3.

```bash
docker compose -f dev/docker-compose.yml up -d --wait redis
docker compose -f dev/docker-compose.yml --profile seed up redis-seed
cd core && REDIS_PERF=1 go test -count=1 -tags=integration -v -run 'PerfIdle|Memory' ./internal/engine/redis/
```

| Measurement | Result | Budget |
|---|---|---|
| Resident memory of the test process (core code, all drivers linked) before opening | 25.4 MB | |
| Same, with a Redis session open and idle for 2 s | 25.6 MB | idle ≤ 150 MB (UI + core) |
| Peak resident memory during `SCAN` of 1,000,000 keys (500 per page, 1,999 pages) | 26.2 MB | 1M-row result ≤ +200 MB |
| Live heap growth during the same scan (`TestIntegrationScan1MKeysKeepsMemoryFlat`, forced GC every 200 pages) | 0 KiB (test limit 16 MiB) | |
| `SCAN` of 1,000,000 keys, time | 0.6 to 1.0 s | |
| `HSCAN` of a 100,000-field hash in pages of 1,000 | 49 ms | |
| `GetKeyInfo` of that hash (`TYPE`, `PTTL`, `OBJECT ENCODING`, `MEMORY USAGE`, `HLEN`) | 1 ms | |

Keys stream to the sink page by page and are not kept, so memory does not depend on the keyspace. Not measured: a cluster scan at this size (the cluster image is emulated on Apple Silicon), a scan over an SSH tunnel, and the app-side key tree.


## Lane G verification

On Apple Silicon, a macOS release build used 139.4 MiB combined RSS (app plus sidecar, measured 30 seconds after launch with a temporary, empty config directory). Five launches reached the sidecar socket in 1,095, 252, 217, 236 and 233 ms (236 ms median). These samples measure socket readiness. The app's gRPC Hello completion and first frame were not timed.

The Go integration test process went from 25.5 MiB RSS to 26.4 MiB with the PostgreSQL SSH session open, using 2.4 MiB of Go heap. This is a separate measurement from the release app's idle result. Combined app and sidecar RSS with the UI holding a live tunnel was not measured.

All 41 applicable Lane G matrix cells passed locally against disposable Docker fixtures or temporary database files. Four file-engine cells are marked n/a. The hosted run and the optional Cosmos DB account check are pending. The matrix streams and cancels at 10,000 items per cell. A fresh Redis fixture scanned 1,000,000 keys in 1,999 pages in 877 ms. The test process peaked at 43.3 MiB RSS from 43.2 MiB idle. Whole-app 1M-row memory and DuckDB's native buffering acceptance remain open.
