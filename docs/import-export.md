# Import and export

`TransferService` (ADR 0024) moves files between the app and a connection. File bytes travel over gRPC in chunks of at most 1 MiB; the app owns the filesystem and core never opens a path the UI sends. Neither side holds a whole file or result.

Implementation: `core/internal/api/transfer_*.go` (RPCs), `core/internal/transfer` (pipeline, mapping, coercion, script runner, Parquet), `core/internal/dataformat` (readers and writers). Measurements: [Iteration 13, Lane F](perf/iteration-13.md).

## Formats
| Format | Export | Import | Notes |
|---|---|---|---|
| CSV, TSV | yes | yes | RFC 4180 quoting; `delimiter`, `quote`, `header`, `null_text`. An unquoted empty field is NULL unless `null_text` says otherwise; a quoted empty field is an empty string. |
| JSON, NDJSON | yes | yes | SQL rows as objects keyed by column name. Documents as relaxed or canonical Extended JSON (`json_flavor`). |
| SQL | INSERTs in the connection's dialect, optional `CREATE TABLE` | a script, statement by statement | See [SQL scripts](#sql-scripts). |
| Parquet | yes | yes | Only in a core built with the `duckdb` tag. `ListFormats` reports what the build supports. |

`header` is a plain bool: an export without it writes no header row, and `InferImport` always detects it (the app can flip it afterwards).

## Export
All three exports are server streams of `ExportEvent`: a header (format and suggested file name), chunks with throttled progress, then a summary or a typed error. Cancelling the call stops the export.

- **`ExportResult`** reads a spooled result by `result_id`, optionally a subset of columns by index. It waits for rows still arriving. A result cut at the spool size cap exports what was spooled; there is no marker in the file.
- **`ExportTable`** runs a streaming `SELECT` (filter and sort as in `TableService`) that is not spooled. `columns` picks and orders columns. `sql_include_ddl` adds a `CREATE TABLE` built from `DescribeTable` (columns and primary key; no indexes or foreign keys), or from the result's own types when the connection cannot describe the table. `sql_target_table` renames the table in the dump.
- **`ExportCollection`** runs `Find` with filter, projection and sort. JSON and NDJSON write documents. CSV, TSV and Parquet need `field_paths` (dotted, `[]` for every array element, a number for one); a missing path is NULL, nested values are written as EJSON text, and every Parquet column is text because values differ in type across documents. SQL is not offered for collections.

## Import
`InferImport` takes the first bytes (core reads at most 4 MiB), detects format, delimiter and header, infers a kind per column from up to 1,000 rows, suggests the engine's native type for a new table, and returns up to 20 preview rows. For a document connection, JSON and NDJSON give `preview_documents_ejson` instead of columns. Parquet keeps its schema in the footer, so only a whole file (up to 512 MiB, spooled to disk) yields columns; a partial one gets a warning.

`Import` is a bidirectional stream: the header, then chunks. Core pulls chunks only as fast as the loader commits batches, so the app is held back by gRPC flow control.

### Targets and mapping
- **Existing table.** Without `mappings`, file columns go by position into the table's leading columns, or by name for JSON, NDJSON and Parquet. With `mappings`, `source_index` (0-based) goes to `target_column` (case-insensitive; the table's spelling is used). A target column that does not exist, or one mapped twice, is `MAPPING`.
- **New table.** `new_table` carries the columns and native types the app chose (start from `InferImport`'s `suggested_type_name`). Core builds `CREATE TABLE` with `sqldialect`, runs it, and returns the DDL in `ImportSummary.ddl`. To review it before it runs, preview the same columns with `SchemaDesignService.PreviewDDL`. If the table exists the import fails with the server's error and changes nothing. If the load fails later, the new table stays with the batches that committed.
- **Collection.** JSON and NDJSON documents are normalised to canonical EJSON. CSV, TSV and Parquet rows become flat documents of text fields named after the header or the mapping (a dot in a name is kept as is); NULL becomes `null`. There is no type inference for CSV into a collection yet.

Every row goes through `engine.RowLoader` or `engine.DocumentLoader`; there is no other insert path.

### Coercion
A delimited file gives text and NULL; the value is converted to the target column's kind before loading. Failures name the column, never the value.

| Target kind | Accepted |
|---|---|
| integer | integers, integral decimals (`3.0`) |
| float, decimal | any number; decimals keep their digits |
| boolean | `true/false`, `t/f`, `yes/no`, `y/n`, `1/0` |
| timestamp | RFC 3339, `YYYY-MM-DD hh:mm:ss[.f][Z]`, `YYYY-MM-DD`; zone-less values are UTC |
| uuid | any case, stored canonical |
| bytes | `\x` hex |
| JSON | valid JSON text |
| text | anything |

Types without a kind of their own (dates, enums, arrays) arrive as text and the server parses them.

### Errors, batches and cancel
- Rows commit per batch, as the loader decides. A committed batch is never rolled back.
- `IMPORT_ERROR_POLICY_STOP` (default): the first bad row stops the import. Rows before it are loaded first, then the typed error and a summary follow. The row error has the 1-based line (CSV, TSV, NDJSON, SQL) or record number (JSON, Parquet) and the target column.
- `IMPORT_ERROR_POLICY_SKIP`: bad rows are skipped and reported, up to `max_row_errors` (default 1,000); one more stops the import. When the server rejects a row for a constraint, the batch is retried row by row, so the offending rows get their own line numbers. This holds only for loaders whose failed batch commits nothing (Postgres, CockroachDB, SQLite, MySQL on InnoDB); a loader that may have committed part of the batch (Mongo) stops with `CONSTRAINT` instead.
- A constraint failure under STOP reports the range of lines of the failed batch, because the server does not say which row failed.
- **Cancel** is cancelling the RPC. Core stops after the current batch. A cancelled RPC cannot receive more events, so the app learns the committed count from the last progress event; core still tries to send `CANCELED` and a summary. Progress is throttled to every 200 ms.
- `single_transaction` is rejected as `UNSUPPORTED`: the loaders commit per batch and none can span batches yet.
- Messages never contain row values. Engine messages that quote data are replaced by the loaders; a failing statement in an SQL script is quoted as the engine reports it, because the text came from the user's own file.

### Production connections
`confirmed=true` is required on a connection flagged production; otherwise `CONFIRMATION_REQUIRED` and nothing changes.

### SQL scripts
Format `SQL` runs the file as a script through an incremental `sqlsplit` over the stream (dollar quotes, MySQL `DELIMITER`, SQL Server `GO` and Oracle `/` follow the connection's dialect). Each statement runs on its own; the import stops at the first error and reports the line the statement starts on. `rows_committed` is the sum of the rows the server reports for the statements, and a script that opens its own transaction is that transaction's business. A statement may be at most 64 MiB. Engine-native dump formats (`pg_dump` `COPY ... FROM stdin` blocks, `mysqldump`-specific syntax) are out of scope.

## Parquet
Core opens a private DuckDB per transfer, with `memory_limit` (24 MiB), one thread and its temporary files inside the spool directory (ADR 0006). Paths are always core-owned temp files, never from the UI, and they are deleted when the transfer ends, fails or is cancelled; a crash leaves them in the per-process spool directory, which the next start sweeps.

- **Export** appends rows to a table in a DuckDB file in the temp directory, flushing every 2,048 rows, then `COPY ... TO` a temp file and streams it out. Peak disk is the DuckDB file plus the Parquet file.
- **Import** spools the upload to a temp file and streams `SELECT ... FROM read_parquet(...)` in batches.
- **Types.** Booleans, signed integers, unsigned integers up to 32 bits and floats pass through. Decimals, 64-bit unsigned and wider integers, UUIDs and everything else without a kind arrive as text (a decimal keeps its digits, a UUID stays a UUID). Dates and zone-less timestamps become timestamps in UTC. Exports write decimals, UUIDs, JSON and arrays as strings and timestamps with a time zone.
- **Nested columns** (lists, structs, maps, unions) are rejected with `UNSUPPORTED` naming the column.
- DuckDB's resident memory is larger than its `memory_limit`; see the Lane F numbers.

## Known gaps
- No `single_transaction`; no native dump formats; no Excel.
- No type inference for CSV into a collection.
- `header` cannot be forced off by `InferImport`.
- A JSON file's columns are the sorted keys of its first object; keys that first appear later are an error. Import such files with the columns present in the first object.
- Exports from a result do not say when the spool was truncated.
- Cancel cannot deliver a summary to a client that has gone; use the progress events.
- Parquet export of a collection writes text columns only; Parquet decimals and UUIDs are exported as strings.
