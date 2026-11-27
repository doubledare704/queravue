# Bulk loading

Import and mock data insert through `engine.RowLoader` (capability `bulk_load`) and `engine.DocumentLoader` (`document_load`), never through `Execute` (ADR 0024 §8). This page lists what each engine does and where the quirks are.

## Contract
- The loader pulls batches from the source until `io.EOF`. The **source decides the batch size**, in bytes, not rows: about 1 MiB is a good target. Loaders do not coalesce batches.
- Each batch commits on its own. When ctx is cancelled or the source fails, the loader stops before committing the next batch and returns the committed `LoadStats` together with the error. A source error is wrapped with `%w`, so `errors.Is` still finds it.
- Rows and documents are never logged, and error messages never quote them: constraint messages name the table, key or constraint only.
- Errors are `*engine.Error`. A rejected constraint (unique, not null, foreign key, check, collection validator) is `KindConstraint`; a cancelled load is `KindCanceled`; a malformed document is `KindParse` with the index of the document in its batch.

## Engines
| Engine | Path | Batch is atomic |
|---|---|---|
| PostgreSQL, CockroachDB | `COPY … FROM STDIN` in text format, one transaction per batch | yes |
| SQLite | prepared multi-row `INSERT` (at most 500 rows and 32,000 bound values per statement), one transaction per batch | yes |
| MySQL, MariaDB, TiDB | prepared multi-row `INSERT` kept under half of `max_allowed_packet` (read once per load, capped at 4 MiB per statement), one transaction per batch | yes, on InnoDB |
| MongoDB, DocumentDB, Cosmos DB | unordered `InsertMany`, split into calls of about 2 MiB of BSON | no |

### PostgreSQL and CockroachDB
- Text format lets the server parse every column type, including those `engine.Value` has no kind for (dates, intervals, enums). `bytea` is written as `\\x` hex on PostgreSQL. CockroachDB takes COPY text bytes as the raw value, so it gets octal escapes.
- Arrays are written as array literals. CockroachDB has no nested arrays, so a nested `Array` value fails there with a server error.
- Server messages outside the classes that only name objects (`08 23 25 28 3D 40 42 53 54 55 57`) are replaced by a message with the SQLSTATE, because messages such as "invalid input syntax for type integer" quote the value.

### SQLite
- `engine.Value` bool is stored as 0 or 1 and reads back as an integer. Decimals and UUIDs go into text columns.

### MySQL family
- Statements run on a context that cancelling ctx does not reach, because the driver closes the socket on cancel. A watcher sends `KILL QUERY` on the second connection instead, and the batch rolls back.
- Duplicate-key messages are rebuilt from the key name, since MySQL's own message quotes the value.

### Mongo family
- A batch is parsed first (on up to four goroutines), so a malformed document commits nothing from its batch. Parsing is strict canonical EJSON; bare numbers are rejected, as in `Insert`.
- `InsertMany` is unordered: a duplicate key rejects that document and the rest of the call still inserts. `LoadStats.Rows` counts what the server inserted, so after a constraint error it can be higher than the batches that finished cleanly. `LoadStats.Batches` counts `InsertMany` calls that finished without an error.
- If the connection breaks during a call, the number inserted by that call is unknown and is not counted.

## Tests
`enginetest.RunRowLoader` and `enginetest.RunDocumentLoader` run against every loader: a round trip of every value kind the engine supports, an empty source, cancel and source errors that leave whole batches only, a constraint violation in the middle of a batch, and the error message not quoting data. The Postgres, CockroachDB, MySQL, MariaDB, TiDB and Mongo suites are integration tests against `dev/docker-compose.yml`; SQLite's runs with the unit tests. `make test-docdb` runs the Mongo suite against DocumentDB Local, and `QV_COSMOS_URI` against Cosmos DB. Perf: [Iteration 13, Lane L](../perf/iteration-13.md).
