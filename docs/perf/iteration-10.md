# Iteration 10 measurements

Each lane keeps its own section.

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
