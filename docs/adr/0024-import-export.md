# ADR 0024 — Import and export

**Status:** Proposed · 2026-11-27

## Context
Iteration 13 adds import and export of CSV, TSV, JSON, NDJSON, SQL dumps and Parquet, and a mock data generator (ADR 0025) that needs the same fast insert path. Files can be gigabytes, so neither core nor app may hold a whole file or result. Related: ADR 0003 (capabilities), ADR 0006 (result spool), ADR 0008 (dialects), ADR 0009 (EJSON, production confirmation), ADR 0019 (DuckDB behind a build tag), ADR 0023 (bytes over gRPC).

## Decision

### 1. Bytes travel over gRPC; the app owns the filesystem
Export is a server stream: a header, byte chunks of at most 1 MiB, then a summary. Import is a stream from the app: a header, then chunks, with progress and the summary streamed back. The app reads and writes files through its open and save dialogs. The GridFS upload transport (`app/lib/core_client/gridfs_upload.dart`) becomes one byte-upload helper that both use. Rejected, as in ADR 0023 §3: core reading or writing paths sent by the UI.

### 2. Formats live in core
A new package `core/internal/dataformat` holds streaming readers and writers. Readers yield batches of typed `engine.Value` rows; writers consume them. Neither holds more than one batch.
- CSV and TSV: RFC 4180 quoting, configurable delimiter, quote and null text, header on or off, UTF-8 with an optional BOM. Other encodings fail with a clear error.
- JSON array and NDJSON: SQL rows as objects keyed by column name; Mongo documents as relaxed or canonical EJSON (ADR 0009).
- SQL dump (export): `INSERT` statements in the target dialect via `sqldialect`, multi-row where the dialect allows it, with an optional `CREATE TABLE`.
- Parquet: §3.

`results.Formatter` moves behind the same writer interface, so copy and export share one encoder. Clipboard output retains its original line endings, null representation and JSON layout.

Delimited files reserve the unquoted null token for NULL. Quoting that token preserves it as text, including a quoted empty string when the null token is empty. Delimited readers yield text and NULL so the import mapping can apply the destination types after sampling. Inference treats fixed-point numbers as decimals, widens a numeric column to float when the sample contains exponent notation representable as a float, and reports incompatible kinds as text with a warning. JSON strings remain text except when they match UUIDs or timestamps. JSON readers use an explicit column list or the sorted keys of the first object. Missing keys yield NULL. For sparse files with keys that first appear in later objects, supply a column list for the fields to import. JSON file exports suffix duplicate names without taking names already present in the result. Relaxed EJSON readers normalize documents to canonical EJSON for the Mongo loader.

### 3. Parquet through embedded DuckDB
Core opens a private in-memory DuckDB instance per Parquet transfer, separate from any user connection. It sets `memory_limit` and a `temp_directory` inside the spool directory (ADR 0006), so large files spill to disk instead of growing RSS. `read_parquet` and `COPY … TO` need paths, so only core-owned temporary files are used, never a path from the UI:
- Import: core spools the uploaded bytes to a temp file, streams `SELECT * FROM read_parquet(<temp>)` with the bounded DuckDB streaming from iteration 10, feeds the target's loader, and deletes the file.
- Export: core appends source rows into a DuckDB temp table, runs `COPY … TO <temp> (FORMAT parquet)`, streams the file, and deletes it.

DuckDB is linked only with the `duckdb` build tag (ADR 0019); release builds have it. `TransferService.ListFormats` reports the formats of this build, and the UI hides Parquet when it is missing. A C++ crash takes core down and core restarts, as ADR 0019 accepts. Nested Parquet types are rejected in v1.

### 4. Export sources
- A spooled result by `result_id`, read from the spool, not the server.
- A whole table with an optional filter and sort, as a streaming `SELECT` that is not spooled.
- A Mongo collection with filter, projection and sort via `Find`. For CSV the user picks field paths (suggested by `SampleFieldPaths`); nested values are written as EJSON text.

### 5. Import targets
- An existing table, with a column mapping and coercion into the column's value kind.
- A new table, whose columns are inferred from a sample. Its `CREATE TABLE` is built by `sqldialect` and reviewed before it runs, as in the designer.
- A Mongo collection: JSON or NDJSON as EJSON; CSV rows as flat documents with opt-in type inference.

`InferImport` sniffs the format, columns, types and a preview from the first bytes; `Import` then runs with the mapping.

### 6. Batches, errors and cancel
Rows commit per batch by default. A single transaction is available where the engine supports it. On a bad row the import stops (default) or skips it and reports up to N errors with line and column. Cancel stops after the current batch and reports the committed count; committed batches are never silently rolled back.

Format readers target batches of at most 500 rows and about 1 MiB. A record above the batch target travels alone, including in SQL dumps. The configurable single-record ceiling defaults to 64 MiB. Readers report malformed data after delivering any preceding good rows, so a caller can either stop or request the next batch. Transport and cancellation errors stop the current batch immediately. Recovery follows record boundaries. If an unterminated quoted field or JSON array element makes the rest of the stream ambiguous, the reader reports the incomplete record. Error lines and byte columns start at one, and absolute byte offsets start at zero.

### 7. SQL script import
A `.sql` file runs statement by statement through an incremental `sqlsplit` over the stream and stops at the first error with its line. Engine-native dump formats (`pg_dump` `COPY … FROM stdin` blocks, `mysqldump`-specific syntax) are out of scope.

### 8. Bulk loading capabilities
- `bulk_load` → `engine.RowLoader.LoadRows(ctx, target, columns, source)` for tables.
- `document_load` → `engine.DocumentLoader.LoadDocuments(ctx, database, collection, source)` for collections.

Sources are pull iterators of batches, so back-pressure is natural. Stats come back together with an error, so a partial load is reported. Batches are sized in bytes, not rows (the iteration 12 lesson). Each engine uses its native path: pgx `CopyFrom` (Postgres, CockroachDB), bulk copy (SQL Server), batch insert (ClickHouse), the appender (DuckDB), multi-row `INSERT` sized to `max_allowed_packet` (MySQL), array binding (Oracle), a prepared insert in a transaction (SQLite), and unordered `InsertMany` (Mongo variants). Import and mock data have no other insert path.

### 9. Safety
Import into a connection flagged production needs `confirmed=true`, otherwise `CONFIRMATION_REQUIRED` and nothing changes (ADR 0009 §8). A new-table import shows its DDL first. Row data is never logged.

### 10. Errors
Failures the user can act on are in-band `TransferError`: PARSE, MAPPING, CONSTRAINT, CONFIRMATION_REQUIRED, AUTH, NETWORK, TIMEOUT, CANCELED, UNSUPPORTED, SERVER. Unknown sessions or results are gRPC `NOT_FOUND`; a session without the needed capability is `FAILED_PRECONDITION`.

## Consequences
- New `TransferService` in `transfer.proto`; protocol version 13 (shared with ADR 0025).
- Memory stays bounded for any file size, at the cost of a copy through gRPC. Parquet also costs temporary disk of up to about twice the file size.
- Parquet needs a DuckDB build; default developer builds lack it.
- Scheduled exports (iteration 15) will need a decision on a core-owned export directory.
