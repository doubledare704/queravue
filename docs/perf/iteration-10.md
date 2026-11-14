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
