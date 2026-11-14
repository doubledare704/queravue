# ClickHouse

Package `core/internal/engine/clickhouse`, built on `ClickHouse/clickhouse-go/v2` (Apache-2.0) over the native protocol. HTTP is not used.

Connection form: host, native port (9000; 9440 with TLS), database (`default`), user (`default`), password (keychain) and TLS (`disable`, `skip-verify`, `verify`). URI: `clickhouse://user@host:9000/database?secure=true` (`skip_verify=true` for `skip-verify`; `tcp://` is accepted too). The TLS section moves to the shared `TlsSettings` with ADR 0018.

## Behaviour
- **Dialect:** backtick quoting, `?` placeholders, `LIMIT n`, native `NULLS FIRST/LAST` and `ILIKE`, `unhex('…')` for byte previews. Tables are addressed as `` `database`.`table` `` (the database is the schema).
- **Splitting and completion:** `sqlsplit.ClickHouse` reads backslash escapes in `'…'`, backtick and `"…"` identifiers, `#` and `--` comments and has no `DELIMITER` command. Completion has ClickHouse keyword and function lists (function names keep their case).
- **Streaming:** the session sets `max_block_size = 8192`; core re-batches to 500 rows. Memory stays flat (see `docs/perf/iteration-10.md`).
- **Cancel:** cancelling the context makes the driver send a cancel packet and drop that connection; the server stops the query (checked against `system.processes` in `TestIntegrationCancelReachesServer`). The session is a small pool (4 connections), so the next statement uses a fresh connection.
- **Statements:** only `SELECT`, `WITH`, `SHOW`, `DESCRIBE`, `EXPLAIN`, `EXISTS`, `CHECK` and `VALUES` read rows; everything else is executed without a result. ClickHouse reports no affected-row count, so `rows_affected` is 0 after DML.
- **Schema:** databases (`system.databases`; `system`, `information_schema` hidden) → tables, views and materialized views (`system.tables`; `.inner*` tables hidden) → columns (`system.columns`). The sorting key, primary key and partition key appear as entries in the table's index list (`sorting key`, `primary key` when it differs, `partition key`). Columns of the primary key carry their position. The table engine (`MergeTree`, `View`, …) is read into `SchemaObject.TableEngine` and `TableDetails.TableEngine`; it is not in the proto yet (see gaps).
- **Schema graph:** columns and types are listed, there are no foreign keys, so tables show without relations.
- **Editing:** table-view edits are disabled with a reason. `ALTER … UPDATE/DELETE` are asynchronous mutations, so a grid edit could not be confirmed or rolled back. Use the SQL editor.

## Types
| ClickHouse type | Value |
|---|---|
| `Int8`–`Int64`, `UInt8`–`UInt32` | int |
| `UInt64`, `Int128`, `UInt128`, `Int256`, `UInt256` | decimal (exact text) |
| `Float32`, `Float64` | float |
| `Decimal(P, S)` | decimal (exact text) |
| `Bool` | boolean |
| `String`, `FixedString`, `Enum8/16`, `IPv4`, `IPv6` | text |
| `Date`, `Date32` | text (`YYYY-MM-DD`) |
| `DateTime`, `DateTime64(p, 'zone')` | timestamp, in the column's time zone |
| `UUID` | UUID |
| `Array(T)` | array of the element values |
| `Map`, `Tuple`, `JSON`, `Object` | JSON text |
| `Nullable(T)`, `LowCardinality(T)` | the value of `T`, or NULL |

## Gaps
- **Designer and schema plan report `UNSUPPORTED`.** `CREATE TABLE` needs an engine clause, `ORDER BY`, `PARTITION BY`, `TTL` and codecs, and `ALTER` can not change the sorting key. That needs its own design; the generic column/index/foreign-key builders do not fit.
- **No index management and no table stats.** Data-skipping indexes and projections are not listed as indexes; only the keys above are.
- **Engine, sorting key and partition key are not shown in the UI yet.** Core fills them in; showing the engine badge needs a field in the proto (`SchemaObject` and `TableDetails`).
- **Single result set per statement**, like the other SQL engines.
- **Multi-statement text is split by the editor**; the native protocol runs one statement per call.
- **`JSON`/`Object` columns** arrive as the driver decodes them (JSON text). Enable them on the server with `allow_experimental_json_type` where the version still needs it.
- **Named `Tuple` values** are JSON objects; unnamed ones are JSON arrays.
- **`--` comments** need no trailing space in the splitter, as in ClickHouse.
- **Transactions** (`BEGIN TRANSACTION`) are experimental on the server and not used.
- **SSH tunnel** (clickhouse-go `DialContext`) arrives with the tunnel work (ADR 0018).

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait clickhouse
cd core && go test -tags=integration ./internal/engine/clickhouse/
```
The seed in `dev/seed/clickhouse/` is loaded on the first start of the container. For a volume that already exists, reload it:
```bash
docker compose -f dev/docker-compose.yml exec -T clickhouse clickhouse-client --user queravue --password queravue --multiquery < dev/seed/clickhouse/01_schema.sql
```
Overrides: `CLICKHOUSE_HOST`, `CLICKHOUSE_NATIVE_PORT`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, `CLICKHOUSE_DB`.
