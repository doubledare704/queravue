# Bulk loading

Import and mock data insert through `engine.RowLoader` (capability `bulk_load`) and `engine.DocumentLoader` (`document_load`), never through `Execute` (ADR 0024 §8). This page lists what each engine does and where the quirks are.

## Contract
- The loader pulls batches from the source until `io.EOF`. The **source decides the batch size**, in bytes, not rows: about 1 MiB is a good target. Loaders do not coalesce batches.
- Each batch commits on its own. When ctx is cancelled or the source fails, the loader stops before committing the next batch and returns the committed `LoadStats` together with the error. A source error is wrapped with `%w`, so `errors.Is` still finds it.
- `LoadStats.Rows` counts rows the server reports as inserted, not rows sent: a table that skips rows (SQLite `ON CONFLICT IGNORE`, a Postgres trigger returning NULL) counts fewer.
- A load never ends a transaction the caller has open. Postgres and CockroachDB refuse with `KindUnsupported` while one is open; MySQL and SQLite do not need to (see below).
- Rows and documents are never logged, and error messages never quote them: constraint messages name the table, key or constraint only.
- Errors are `*engine.Error`. A rejected constraint (unique, not null, foreign key, check, collection validator) is `KindConstraint`; a cancelled load is `KindCanceled`; a malformed document is `KindParse` with the index of the document in its batch.

## Engines
| Engine | Path | Batch is atomic |
|---|---|---|
| PostgreSQL, CockroachDB | `COPY … FROM STDIN` in text format, one transaction per batch | yes |
| SQLite | prepared multi-row `INSERT` (at most 500 rows and 32,000 bound values per statement), one transaction per batch | yes |
| MySQL, MariaDB, TiDB | prepared multi-row `INSERT` kept under half of `max_allowed_packet` (read once per load, capped at 4 MiB per statement), one transaction per batch | yes, on InnoDB |
| SQL Server | TDS bulk copy (`INSERT BULK`) with `CHECK_CONSTRAINTS`, `FIRE_TRIGGERS` and `KEEP_NULLS`, one transaction per batch | yes |
| Oracle | array binding: one `INSERT` with one array per bind variable, at most 10,000 rows per call, one transaction per batch | yes |
| ClickHouse | native-protocol batch insert, one block per batch, on a connection of its own | yes (one block) |
| DuckDB (`duckdb` tag, cgo) | appender, one transaction per batch | yes |
| MongoDB, DocumentDB, Cosmos DB | unordered `InsertMany`, split into calls of about 2 MiB of BSON | no |

### PostgreSQL and CockroachDB
- Text format lets the server parse every column type, including those `engine.Value` has no kind for (dates, intervals, enums). `bytea` is written as `\\x` hex on PostgreSQL. CockroachDB takes COPY text bytes as the raw value, so it gets octal escapes.
- Arrays are written as array literals. CockroachDB has no nested arrays, so a nested `Array` value fails there with a server error.
- Server messages outside the classes that only name objects (`08 23 25 28 3D 40 42 53 54 55 57`) are replaced by a message with the SQLSTATE, because messages such as "invalid input syntax for type integer" quote the value.

### SQLite
- A transaction the caller has open makes the load fail, because SQLite does not nest them.
- `engine.Value` bool is stored as 0 or 1 and reads back as an integer. Decimals and UUIDs go into text columns.

### MySQL family
- A load takes a connection of its own from the pool (three connections: statements, `KILL QUERY`, load), because `START TRANSACTION` would otherwise commit the caller's open transaction.
- Tables on a storage engine that cannot roll back (MyISAM, MEMORY, Aria, ARCHIVE, CSV, …) are refused with `KindUnsupported` before anything is written, since a failed batch would leave part of it behind with no way to count it.
- Statements, and the `max_allowed_packet` lookup, run on a context that cancelling ctx does not reach, because the driver closes the socket on cancel. A watcher sends `KILL QUERY` instead, and cuts the socket if the kill fails, as `Execute` does. The batch rolls back.
- Duplicate-key messages are rebuilt from the key name, since MySQL's own message quotes the value.

### SQL Server
- `go-mssqldb` has native bulk copy, and it is strict about the Go type each column takes, so a load first reads the target's column types from `sys.columns` and converts every value (integers range-checked, GUIDs written in the wire byte order). A missing table or column is `KindNotFound`.
- Columns bulk copy cannot write (`xml`, `json`, `sql_variant`, spatial, `hierarchyid`, `rowversion`) are refused with `KindUnsupported` before anything is written.
- The whole batch is converted before the bulk stream starts, because the driver cannot abort a stream that is open. Integers for a `decimal` column go as text so they take the column's scale.
- `char`, `varchar` and `text` columns whose collation is not `_UTF8` accept ASCII only: bulk copy writes the UTF-8 bytes as they are, which a legacy code page would store as other characters. `nchar` and `nvarchar` take any text.
- The connection is one pinned session, so a load cannot get a connection of its own. It refuses with `KindUnsupported` while `@@TRANCOUNT` is above zero, rather than nest a transaction.
- Without `CHECK_CONSTRAINTS` bulk copy skips CHECK and foreign key checks and leaves the constraints untrusted; the loader asks for them, so a violation is `KindConstraint` as it is for `INSERT`.
- The server's duplicate-key messages ("The duplicate key value is (…)") quote the value; they are rebuilt from the constraint or index name. Conversion and truncation errors get a generic message.
- `LoadStats.Rows` is the row count of the bulk copy's `DONE` token.

### Oracle
- go-ora binds a `[]any` per column as an array when every bind variable is an array. Its `float64` encoding is Oracle `NUMBER`, which cannot carry NaN, infinities or magnitudes outside 1e-125 to 1e125 (the server turned `-1e300` into NaN and `1e-200` into `1e+56`); a column with such a float goes as text for the whole batch, which `BINARY_DOUBLE` converts.
- `LoadStats.Rows` is the row count the server reports for the array statement.
- Since 23ai a unique violation adds a second line (`ORA-03301`) that quotes the key values. Only the first line of an `ORA-` message is kept.
- Oracle stores an empty string and an empty `RAW` as NULL, so they read back as NULL.
- `NUMBER` columns convert decimal text with the session's `NLS_NUMERIC_CHARACTERS`; a session that changes it would misread `1.5`. Execute binds decimals the same way.
- A transaction opened with `SET TRANSACTION` stays open on the pinned session; the load refuses with `KindUnsupported` while it is.
- `JSON` columns take the JSON text, and the engine reads them back as bytes of that text.
- go-ora also has a direct-path `BulkCopy`; it bypasses the session's transaction and is not used.

### ClickHouse
- A load opens a native connection of its own (same options as the pool) and sends one block per batch. ClickHouse has no transactions, so the batch is atomic only as a block: a block is written whole, or rejected whole when the server throws. A block that spans several partitions becomes several parts, so rejection after a partial write is not possible, but a crash mid-insert is outside the contract.
- Constraints: only `CHECK` and `NOT NULL`-ness exist. A violated `CHECK` (code 469) is `KindConstraint`, named by constraint; the server's "Column values" tail is dropped. ClickHouse has no unique or foreign keys, so a duplicate key is not an error.
- The driver writes the type's default for a NULL in a column that is not `Nullable`. The loader refuses it with `KindConstraint` instead.
- The native protocol sends no inserted-row count for a batch (no `Progress`, `ProfileInfo` or `InsertedRows` event arrives), so `LoadStats.Rows` is the number of rows in blocks the server accepted. ClickHouse does not drop rows of an accepted block, but a replicated table that deduplicates an identical block still counts it.
- Driver errors for a value it cannot append are replaced by a message that does not quote the value.
- The column types are read from `system.columns`. `Tuple`, `Map`, `Nested`, `JSON`, `Variant`, `Dynamic`, aggregate and geo types are refused with `KindUnsupported`. `String` takes bytes. `Date` and `Date32` drop the time of day, because the driver rounds a pre-1970 date with a time to the next day.

### DuckDB
- The appender runs on the work connection, so `BEGIN` fails when the caller has a transaction open; that is `KindUnsupported`. Each batch is `BEGIN`, appender, `COMMIT`.
- `LoadStats.Rows` is the number of rows appended in a batch whose commit succeeded: the appender gives no count and drops no rows.
- The appender takes the Go type each column needs, so a load reads `duckdb_columns()` first. `DECIMAL` is scaled exactly and rounded half away from zero, as a cast would, before the precision check, `JSON` takes `json.RawMessage`, lists take the element type of `T[]`. `STRUCT`, `MAP`, `UNION`, `BIT`, `INTERVAL` and `TIME` columns are refused with `KindUnsupported`.
- Duplicate-key and foreign-key messages quote the key; they are rebuilt without it.
- DuckDB runs in the core's process, so the rows it holds count toward the core's RSS until a checkpoint writes them out ([perf](../perf/iteration-13.md)).

### Mongo family
- A batch is parsed first (on up to four goroutines), so a malformed document commits nothing from its batch. Parsing is strict canonical EJSON; bare numbers are rejected, as in `Insert`.
- `InsertMany` is unordered: a duplicate key rejects that document and the rest of the call still inserts. `LoadStats.Rows` counts what the server inserted, so after a constraint error it can be higher than the batches that finished cleanly. `LoadStats.Batches` counts `InsertMany` calls that finished without an error.
- If the connection breaks during a call, the number inserted by that call is unknown and is not counted.

## Tests
`enginetest.RunRowLoader` and `enginetest.RunDocumentLoader` run against every loader: a round trip of every value kind the engine supports, an empty source, cancel and source errors that leave whole batches only, a constraint violation in the middle of a batch, and the error message not quoting data. The Postgres, CockroachDB, MySQL, MariaDB, TiDB, SQL Server, Oracle, ClickHouse and Mongo suites are integration tests against `dev/docker-compose.yml`; the SQLite and DuckDB (`-tags duckdb`, cgo) suites run with the unit tests. The row suite also loads one batch of 2,500 rows, larger than any single insert statement. A target can replace the keyed table's DDL, the key that violates it and skip the open-transaction case (ClickHouse has no transactions, and its keyed table has a `CHECK` instead of a primary key). SQL Server, Oracle, ClickHouse and DuckDB have extra cases for refused column types and an open transaction. `make test-docdb` runs the Mongo suite against DocumentDB Local, and `QV_COSMOS_URI` against Cosmos DB. Perf: [Iteration 13, Lane L](../perf/iteration-13.md).
