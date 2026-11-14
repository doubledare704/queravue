# DuckDB

Package `core/internal/engine/duckdb`, built on `github.com/duckdb/duckdb-go/v2` (MIT, the DuckDB Foundation's successor of `marcboeker/go-duckdb`). The driver links the DuckDB C++ library through cgo, so **the engine exists only in builds made with `-tags duckdb`** (ADR 0019). Without the tag the default build stays cgo-free and the engine is not registered.

## Building with DuckDB
```bash
make core-duckdb              # core/bin/queravued with the engine (CGO_ENABLED=1)
make test-core-duckdb         # go test -race -tags duckdb ./...
make lint-core-duckdb
cd core && CGO_ENABLED=1 go build -tags duckdb ./... && CGO_ENABLED=1 go test -tags duckdb ./...
```
A C compiler is required (Xcode command line tools, `gcc` on Linux, MinGW-w64 on Windows). The DuckDB library itself is not compiled: it comes as a prebuilt static archive from the `go.duckdb.org/libduckdb/<os>-<arch>` modules (macOS arm64/amd64, Linux arm64/amd64, Windows amd64). `CGO_ENABLED=0 go build -tags duckdb` fails, because the driver has no pure-Go fallback. Each OS is built natively in CI (`core-duckdb` job); there is no cross-compiling.

## Connection
Form: **Database file** (a path, or `:memory:`), **Read-only**, **Create file if missing**, and an optional **Memory limit** (`4GB`; the default is 80% of RAM). URI: `duckdb:///abs/path.duckdb`, `duckdb://rel/path`, `duckdb://:memory:` or a bare path, with `?access_mode=read_only` (or `read_only=true`) and `memory_limit=`.
- A missing file is an error unless **Create file if missing** is on, so a typo does not make an empty database. `:memory:` is a private database that vanishes on disconnect.
- File engine, like SQLite: no SSH tunnel and no TLS (the descriptor reports neither) and no password.
- `ATTACH 'other.duckdb' AS other` works in the editor. Attached databases appear in the schema tree as further databases (the file you opened is one too, named after the file: `analytics.duckdb` is `analytics`).

### Locking
DuckDB allows **one process with write access**, or any number of read-only processes when nobody writes.
- Another process holds the file: the connect fails with `KindTimeout` and a message that says the file is locked by another process, names it (PID and program, as DuckDB reports them) and suggests closing it or opening read-only. The error wraps `duckdb.ErrFileLocked`. Opening read-only while a writer holds the file fails the same way. Checked against a second process in `TestFileLockedByAnotherProcess`.
- The same file twice **inside Queravue**: read-write twice shares one database instance, but read-only next to read-write is refused (`KindInvalidConfig`, "already open with other settings"). Close the other connection first.
- A file that is not a DuckDB database (or comes from an incompatible storage version) is `KindInvalidConfig`.

## Behaviour
- **Dialect:** double-quote identifiers, `?` placeholders, `LIMIT n`, `NULLS FIRST/LAST`, `ILIKE`, `BEGIN TRANSACTION`. Tables in an attached database are `"db"."schema"."table"`.
- **Splitting:** `sqlsplit.DuckDB` reads Postgres-style lexing: nested block comments, `E'…'` escapes and **dollar quotes** (`$$…$$`, `$tag$…$tag$`; DuckDB supports them, `$1` stays a parameter), but no `BEGIN ATOMIC` and no function bodies. A plain `'…'` has no backslash escapes. Completion has DuckDB keyword and function lists (`read_parquet`, `read_csv`, `list_transform`, `QUALIFY`, `PIVOT`, `GROUP BY ALL`, …).
- **Statements:** `INSERT`, `UPDATE`, `DELETE` report `rows_affected` (DuckDB hands them back as a one-row `Count` result, which core turns into the count); DDL, `SET`, `ATTACH`, `BEGIN`/`COMMIT` and similar return nothing; `RETURNING`, `SELECT`, `SHOW`, `DESCRIBE`, `SUMMARIZE`, `EXPLAIN`, `COPY … TO` and the rest return rows.
- **Session:** statements run on one connection, so transactions, `SET`, `USE`, `ATTACH` and temporary tables span statements. Schema listings use a second connection and work while a long statement runs; they see only committed changes.
- **Cancel:** cancelling the context calls `duckdb_interrupt`; a running aggregate, `CREATE TABLE AS` or join stops in about the cancel time (0.60 s and 0.63 s for a 600 ms deadline) and the session answers the next statement. Native SELECT fetches stay interruptible for the lifetime of the stream. Cancellation stops delivery, closes the native result, and leaves the work connection available for the next statement.
- **Files:** `SELECT … FROM read_parquet('f.parquet')`, `read_csv('f.csv')`, `read_json` and `FROM 'f.parquet'` work like any table. There is no import/export UI yet (Iteration 13).
- **Schema:** databases (`duckdb_databases()`, system and temp hidden) → schemas (`duckdb_schemas()`) → tables and views (`duckdb_tables()`, `duckdb_views()`, row estimate from `estimated_size`) → columns (`duckdb_columns()`), primary, unique and foreign keys (`duckdb_constraints()`) and indexes (`duckdb_indexes()`; the key columns are read from the stored `CREATE INDEX`). A column whose default is `nextval(…)` is shown as auto-generated. Completion and the schema graph use one query per schema, also for attached databases.
- **Editing:** by primary key, or a unique `NOT NULL` key; views and key-less tables are read-only with a reason. DuckDB implements an update of an indexed column as delete plus insert, which can trip a unique or foreign-key check inside one transaction (a DuckDB limitation).

## Types
| DuckDB type | Value |
|---|---|
| `TINYINT`…`BIGINT`, `UTINYINT`…`UINTEGER` | int |
| `UBIGINT`, `HUGEINT`, `UHUGEINT`, `BIGNUM` | decimal (exact text; small `UBIGINT` values are int) |
| `DECIMAL(P, S)` | decimal (exact text) |
| `FLOAT`, `DOUBLE` | float |
| `BOOLEAN` | boolean |
| `VARCHAR`, `ENUM`, `BIT` | text |
| `INTERVAL` | text, DuckDB's format (`1 year 2 months 3 days 04:05:06.5`) |
| `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMP_S/MS/NS` | text (`2026-03-04`, `05:06:07`, `2026-03-04 05:06:07.123456`): they carry no zone |
| `TIMESTAMP WITH TIME ZONE` | timestamp (an instant) |
| `BLOB` | bytes |
| `UUID` | UUID |
| `JSON` | JSON text |
| `LIST`, `ARRAY` (`T[]`, `T[n]`) | array of the element values |
| `STRUCT`, `MAP` | JSON text |
| `UNION` | the value of the active member (its tag is not shown) |

## Designer and schema plan
Supported: create table (columns, primary key, unique, check, foreign keys), add, drop and rename column, alter column type, nullability and default, rename and drop table, add and drop index.
- **Auto-increment** does not exist in DuckDB; an "auto-generated" column gets `CREATE SEQUENCE <table>_<column>_seq` and `DEFAULT nextval('…')` in the same script. Dropping the table leaves its sequence behind.
- **Foreign keys** can only be declared when the table is created (`ALTER TABLE … ADD FOREIGN KEY` does not exist), so diagram design orders created tables so that referenced tables come first and refuses a foreign key on an existing table. Only `NO ACTION` and `RESTRICT` exist: `CASCADE`, `SET NULL` and `SET DEFAULT` are refused with a reason.
- **Constraints:** `ADD UNIQUE` works, `ADD CHECK` and `DROP CONSTRAINT` do not (refused with a reason; create a new table, copy, swap).
- **Dependency limit:** DuckDB refuses most `ALTER`s (rename, type change, drop column, add constraint) on a table that has an index of its own, or that another table's foreign key references. The generated script warns; the error comes from DuckDB when it runs. Adding a column is allowed.
- No index methods, included columns or partial indexes (DuckDB's ART indexes take columns only). No index list/management UI and no table stats yet (`index_manager` and `stats` are not reported).

## Limitations
- **Native streaming applies to editor statements that DuckDB classifies as SELECT.** The driver fetches native chunks as core needs them, keeping the same parameter bindings, column metadata and value conversions. DuckDB may still buffer query working data for operators such as sorts and joins. Other row-producing statements use complete results. In particular, an early grid stop after a write with `RETURNING` preserves the completed write. See [the RSS measurements](../perf/iteration-10.md#streaming-and-memory).
- **A crash in the DuckDB library takes core down** (a C++ abort cannot be recovered in Go). ADR 0019 accepts this and keeps a helper process as the fallback.
- **`STRUCT` field order is lost**: the driver returns a Go map, so fields are written sorted by name. A `UUID` or `BLOB` inside a `LIST` or `STRUCT` loses its type name and shows as bytes (`\x…`).
- **`JSON` values** are re-serialized (compact, keys sorted): spacing and key order of the stored text are not kept.
- **Parameters:** arrays and structs cannot be bound; write them in SQL.
- **One result set per statement**, like the other SQL engines. Multi-statement text is split by the editor.
- **Extensions** (`INSTALL`, `LOAD`, `httpfs`, `spatial`) run as SQL. They download from the network; core does not manage them.
- **Windows** needs MinGW-w64 for cgo; paths with `?` are refused.

## Driver maintenance

Core uses a local copy of the MIT-licensed [duckdb-go v2.20000.0](https://github.com/duckdb/duckdb-go/tree/v2.20000.0), with the same DuckDB 2.0.0 native archives. Its public Go API has no streaming option. The local extension uses the [DuckDB pending streaming API](https://duckdb.org/docs/2.0/clients/c/api#duckdb_pending_prepared_streaming) and keeps the driver's interrupt handler active through native fetch and cleanup. DuckDB marks that entry point deprecated. Recheck the [upstream streaming work](https://github.com/duckdb/duckdb-go/pull/227) before updating the driver. A replacement needs to interrupt blocked fetches, report fetch-time errors and leave the session reusable after early close.

## Testing
```bash
cd core && CGO_ENABLED=1 go test -tags duckdb ./internal/engine/duckdb/
```
No container: the tests build a DuckDB file from `dev/seed/duckdb/01_seed.sql` (the shared seed, plus a 1M-row `million_items`) and run the shared `enginetest` suite on it (connect, 100k and 1M streams, cancel, stop early, schema tree, filter and sort, completion columns, schema graph, edit with rollback). The designer round trip is DuckDB-specific (`ddl_test.go`) because the shared one needs foreign key actions and `DROP CONSTRAINT`. Locking is tested against a second process (the test binary re-runs itself). Measurements: `DUCKDB_PERF=1 go test -tags duckdb -v -run Perf ./internal/engine/duckdb/`.
