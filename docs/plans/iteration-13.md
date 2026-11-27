# Iteration 13 plan — Import/export + mock data

**Status:** Planned · 2026-11-27 · Protocol version 13

## Goal (from ROADMAP)
- Import/export CSV, JSON/NDJSON, SQL dump, Parquet (DuckDB).
- Mock data generator: per-column faker rules, FK-aware, bulk insert with progress.
- **Done when:** you can generate 1M realistic rows into Postgres and Mongo in reasonable time.

"Reasonable time" as numbers, measured on the docker databases on Apple Silicon:
- 1M generated rows into a Postgres table with one foreign key in ≤ 20 s (≥ 50k rows/s), and 1M documents into Mongo in ≤ 35 s (≥ 30k docs/s).
- Core RSS **peak** during either run ≤ baseline + 60 MiB. Iteration 12 showed that macOS keeps freed pages resident, so the peak is the number that matters.

Added exit criteria, so the import/export half has one too:
- A 1 GiB CSV imports into Postgres and a 1M-row table exports to each format with flat core and app memory. Both directions can be cancelled, and a cancelled import reports how many rows were committed.
- A file exported from each engine imports back into the same engine with equal rows (round-trip test).

## What we build on
| Need | Existing piece | ADR |
|---|---|---|
| Bytes between app and core, app owns the filesystem | GridFS `Download` server stream; `Upload` client stream over `app/lib/core_client/gridfs_upload.dart` (own HTTP/2 transport, because grpc-dart queues client messages ahead of flow control) | 0023 §3 |
| Query results without holding them in memory | result spool, `FetchRows`, `CopyRange` | 0006 |
| CSV / TSV / JSON text of rows | `core/internal/results/format.go` (`Formatter`) | 0006 |
| Typed cells | `engine.Value` kinds | 0003 |
| Identifiers, placeholders, literals, DDL per SQL family | `core/internal/sqldialect` (`Dialect`, `BuildDDL`, `FormatLiteral`) | 0008, 0013 |
| Statement splitting | `core/internal/sqlsplit` | 0008 |
| Tables, columns, FKs; bulk FK graph | `SchemaInspector.DescribeTable`, `engine.RelationLister` | 0007, 0017 |
| Mongo field paths and types | `DocumentStore.SampleFieldPaths`, EJSON code in `engine/mongo` | 0009 |
| Reviewed DDL before apply | designer and diagram design flows | 0013, 0017 |
| Production confirmation | `CONFIRMATION_REQUIRED` + `confirmed=true` | 0009 §8 |
| Capability gating, no engine ids in Dart | descriptor capabilities | 0003 |

## Decisions to record (PR 0)

### ADR 0024 — Import and export
1. **Bytes travel over gRPC; the app owns the filesystem** (same rule as ADR 0023 §3). Export is a server stream of encoded bytes in chunks of at most 1 MiB. Import is a client stream: a header, then chunks. The app reads and writes files through its open and save dialogs. The GridFS upload transport is generalised into one byte-upload helper that both use.
2. **Formats live in core**, in a new package `core/internal/dataformat`, pure and streaming: readers produce batches of typed rows, writers consume them, and neither holds more than one batch.
   - CSV and TSV: RFC 4180, delimiter, quote and escape characters, header row on or off, UTF-8 with an optional BOM. Other encodings are rejected with a clear error.
   - JSON array and NDJSON: SQL rows as objects keyed by column name. Mongo documents as relaxed or canonical EJSON.
   - SQL dump (export): `INSERT` statements in the target dialect via `sqldialect`, multi-row where the dialect allows it, with optional `CREATE TABLE` from `BuildDDL`.
   - Parquet: see §3.
   The existing `results.Formatter` moves behind the same writer interface so copy and export share one encoder.
3. **Parquet through embedded DuckDB, as the ROADMAP says.** Core opens a private in-memory DuckDB instance per transfer (not a user connection), with `memory_limit` and `temp_directory` set inside the spool directory (ADR 0006), so a large file spills to disk instead of growing RSS. DuckDB's `read_parquet` and `COPY … TO` need file paths, so the paths are core-owned temporary files only, never paths sent by the UI, which keeps §1 intact:
   - Import: core spools the uploaded bytes into a temp file in its spool directory, streams `SELECT * FROM read_parquet(<temp>)` through the bounded DuckDB streaming from iteration 10 (#59), feeds the rows to the target's loader, and deletes the file when the import ends.
   - Export: core appends the source rows into a DuckDB temp table with the appender, runs `COPY … TO <temp> (FORMAT parquet)`, streams the file out in ≤ 1 MiB chunks, and deletes it.
   - Availability: DuckDB is linked only with the `duckdb` build tag (ADR 0019). The release build has it; a default build does not. Core reports the formats it supports in `InferImport` and in a `ListFormats` call, and the UI hides Parquet when it is missing, without reading the build or an engine id.
   - Accepted cost, as in ADR 0019: a C++ crash in DuckDB takes core down, and the core restarts. The cgo DuckDB CI job runs the Parquet tests.
4. **Export sources.**
   - A result already in the spool, by `result_id`. This reuses ADR 0006, and export reads from the spool, not the server.
   - A whole table: a streaming `SELECT`, not spooled.
   - A Mongo collection with a filter, projection and sort: `Find`.
   For Mongo to CSV the user picks the field paths (suggested by `SampleFieldPaths`), and nested values are written as EJSON text.
5. **Import targets.**
   - An existing table, with a column mapping and type coercion into `engine.Value`.
   - A new table, whose `CREATE TABLE` is inferred from a sample of the file and reviewed like designer DDL before it runs.
   - A Mongo collection: documents from JSON or NDJSON as EJSON; CSV rows become flat documents with opt-in type inference.
   The flow is `InferImport` (sniff the format, columns and types from the first chunk), then `Import` with the mapping.
6. **Error and transaction policy.** Rows commit per batch by default. A single transaction is available where the engine supports it, with a warning for large files. On a bad row the import either stops (the default) or skips and reports up to N row errors with line numbers. On cancel, the import stops after the current batch and reports the committed count. A committed batch is never silently rolled back.
7. **SQL dump import** runs the file as a script, statement by statement, through an incremental `sqlsplit` over the stream, and stops at the first error with its line. Engine-native dump formats (`pg_dump` `COPY … FROM stdin` blocks, `mysqldump` options) are out of scope and noted as a known gap.
8. **Safety.** Import into a connection flagged production needs `confirmed=true`, otherwise `CONFIRMATION_REQUIRED` and nothing changes. A new-table import shows its DDL first. Row data is never logged.

### Shared by both ADRs — bulk loading capability
- `CapBulkLoad = "bulk_load"` with `engine.RowLoader` for tabular targets: `LoadRows(ctx, target, columns, source) (LoadStats, error)`. The source is a pull iterator of row batches, so back-pressure is natural.
- `CapDocumentLoad = "document_load"` with `engine.DocumentLoader` for documents: unordered `InsertMany` in batches of about 1–2 MiB, with the same batch-size discipline as the GridFS chunk writer.
- Each engine uses its native fast path:

  | Engine | Fast path |
  |---|---|
  | Postgres and CockroachDB | pgx `CopyFrom` |
  | SQL Server | bulk copy |
  | ClickHouse | batch insert |
  | DuckDB | appender (behind the build tag) |
  | MySQL | multi-row `INSERT` batches sized to `max_allowed_packet` |
  | Oracle | array binding |
  | SQLite | prepared insert in a transaction |
  | Mongo, DocumentDB, Cosmos DB | `DocumentLoader` |

  A conformance suite in `engine/enginetest` runs against every loader.
- Import and mock data both go through these interfaces. Neither has its own insert path.

### ADR 0025 — Mock data generator
1. **Generation lives in core**, in a new package `core/internal/mockdata`. It is deterministic for a given seed, so a preview equals the first rows of the run.
2. **Per-column rules.**
   - Kinds: a faker kind (name, email, phone, address parts, company, lorem, URL, UUID, IP, ...); a sequence; int, float or decimal range; a date or timestamp range; a weighted list of values; a constant; a pattern (`###-??`); a foreign-key reference.
   - Modifiers: null ratio and unique.
   - Default rules come from column name and type heuristics (`email` → email, `*_at` → timestamp in the last two years), so a table generates with one click. For Mongo, rules attach to field paths from `SampleFieldPaths`, including nested documents and arrays with a length range.
3. **Faker library: `github.com/brianvoe/gofakeit/v7`** (MIT, no transitive dependencies), with the `en` locale in v1. The reason goes in PR 5's description, as AGENTS.md asks. If a faker kind cannot be produced deterministically from a seeded source, it is implemented in-house instead.
4. **FK awareness.**
   - The plan orders the chosen tables topologically from the FK graph (`RelationLister`).
   - A child's FK values are drawn from the parent's keys: either the keys generated in this run, kept as a compact key set (1M int64 keys ≈ 8 MiB), or a capped sample of existing parent keys read with a streaming `SELECT`.
   - A cycle is reported before the run, with its edges. The user breaks it by setting a nullable FK to null, or by leaving one table out.
   - Unique columns use sequences or retry with a bounded attempt count, then fail with the column name.
   - Composite unique constraints are best effort and documented.
5. **Run.** The generator is a `RowLoader`/`DocumentLoader` source. Each table streams progress (rows, rows/s), and the run can be cancelled. Tables already finished stay committed and are reported. A production connection needs `confirmed=true`.
6. **Contract** (`mockdata.proto`, `MockDataService`):
   - `SuggestMockSpec(session, tables | collections)` returns the default rules and the table order.
   - `PreviewMock(spec, n)` returns sample rows without writing.
   - `RunMock(spec)` streams progress per table and a summary.
   The UI offers the generator when the connection has `bulk_load` and `schema_inspector`, or `document_load`. FK ordering uses `schema_graph` where the connection has it; without it, tables are generated in the order the user picks and FK columns get no default rule.

## Contract (PR 0)
- `proto/queravue/v1/transfer.proto`, `TransferService`:
  - `ExportResult` and `ExportTable` / `ExportCollection` are server streams: a header, byte chunks of at most 1 MiB, then a summary or an error.
  - `ListFormats` returns the import and export formats this core build supports (Parquet only with the `duckdb` tag).
  - `InferImport` is a client stream of the first bytes; it returns the format, columns, types and a preview.
  - `Import` is a client stream (a header with the target, mapping, format options, error policy and `confirmed`, then chunks). It returns a summary with committed rows and row errors.
  - Typed `TransferError` kinds: PARSE, MAPPING, CONSTRAINT, CONFIRMATION_REQUIRED, AUTH, NETWORK, TIMEOUT, CANCELED, UNSUPPORTED, SERVER.
- `proto/queravue/v1/mockdata.proto`, `MockDataService`, as in ADR 0025 §6.
- Capabilities `bulk_load` and `document_load` mapped in `CapabilityInterfaces`; no descriptor declares them until its loader lands.
- Protocol version 13. Stub services return `UNIMPLEMENTED`. Generated Go and Dart code is committed.

## PRs and lanes
PR 0 lands first. Then three core lanes and one app lane run in parallel: **F** (formats and transfer), **L** (loaders), **M** (mock data), **A** (app).

| PR | Lane | Scope | Done when |
|---|---|---|---|
| 0 | — | ADRs 0024 and 0025, `transfer.proto`, `mockdata.proto`, capability constants and interfaces, stubs, protocol version 13 | `buf lint` and `buf breaking` clean, generated code committed, Hello reports 13 |
| 1 | F | `dataformat`: CSV/TSV, JSON, NDJSON readers and writers, SQL dump writer, type sniffing; `results.Formatter` moved behind the writer interface | golden tests per format; CSV fuzz test; 1 GiB CSV read with flat heap |
| 2 | L | `RowLoader` on Postgres, CockroachDB, SQLite and MySQL; `DocumentLoader` on Mongo; `enginetest` loader conformance suite | conformance green on the docker DBs; Postgres 1M rows ≥ 50k rows/s, Mongo ≥ 30k docs/s with a fixed source |
| 3 | L | `RowLoader` on SQL Server, Oracle, ClickHouse and DuckDB (tagged) | conformance green on each; DuckDB in the cgo job |
| 4 | F | `TransferService`: exports from result, table and collection; `InferImport` and `Import` with mapping, error policy, cancel and confirmation; Parquet via embedded DuckDB with spooled temp files (cgo job) | round-trip integration test per engine and format; 1M-row export and 1 GiB import with peak core RSS ≤ baseline + 60 MiB |
| 5 | M | `mockdata`: rules, heuristics, seeded generators, FK planner with cycle report, unique handling; `MockDataService` on the loaders | unit tests per rule and planner; 1M rows into Postgres (with FK) and Mongo within the exit numbers |
| 6 | A | Export from grid, table and collection (format options, save dialog, progress, cancel); import wizard (open dialog, inferred preview, column mapping, new-table DDL review, error report); shared byte-upload helper from the GridFS transport; palette entries and shortcuts | widget tests and goldens for the wizard; e2e CSV import → grid → export on SQLite and Postgres |
| 7 | A | Mock data designer: table/collection picker with FK order and cycle warnings, per-column rule editor with defaults, preview grid, seed field, run with per-table progress and cancel | widget tests and goldens; e2e generate 10k rows into the seeded Postgres and Mongo |
| 8 | — | Docs (`docs/import-export.md`, `docs/mock-data.md`, engine notes for loader quirks), `docs/perf/iteration-13.md`, ROADMAP status and known gaps, ADR status | measurements below recorded |

Order: PR 1, 2 and 5 can start as soon as PR 0 merges; PR 5 develops against a fake loader until PR 2 lands. PR 3 follows PR 2's conformance suite. PR 4 needs PR 1 and PR 2. PR 6 and PR 7 start on the stubs and fakes and finish against PR 4 and PR 5.

## Testing
- **Format goldens** in `core/internal/dataformat/testdata/`: per format, files covering quoting, embedded newlines, empty vs null, unicode, wide rows and every `engine.Value` kind. Regenerate with `-update` and review the diff.
- **Fuzz**: the CSV and NDJSON readers never panic and never read past a batch limit.
- **Loader conformance** (`//go:build integration`): every `RowLoader` and `DocumentLoader` loads the same fixture of all value kinds. It is asserted by reading back through `Execute`/`Find`, plus cancel mid-load and a constraint violation in the middle of a batch.
- **Round trip**: per engine and format, export a fixture table, import it into a fresh table, and compare as multisets.
- **Mock data**: the same seed gives the same rows; FK values always exist in the parent; null ratios within tolerance on 100k rows; the cycle report names the edges.
- **Memory**: the 1 GiB import, the 1M-row export and both 1M mock runs sample core RSS (`ps -o rss=` every 100 ms) and assert the peak. Idle RSS after the run is logged, not asserted (iteration 12 finding).

## Measurements for `docs/perf/iteration-13.md`
- Mock data: 1M rows into Postgres (with an FK) and 1M documents into Mongo: time, rows/s, core RSS peak.
- Loader throughput per engine with a fixed source.
- Import of a 1 GiB CSV into Postgres: time, core and app RSS peak.
- Export of 1M rows to CSV, NDJSON, SQL dump and Parquet: time, bytes, core RSS peak. For Parquet, also the spool disk used and the DuckDB `memory_limit` setting.
- App RSS during an export and an import, with the release harness from iteration 12 (`make perf-idle-release`) and the fixed sampling method from `docs/perf/iteration-12-app-idle.md`.

## Risks
- **Throughput on non-native paths** (MySQL, Oracle, SQLite) may miss Postgres-like numbers. Only Postgres and Mongo are exit criteria; the others are recorded, not gated.
- **Memory from batch encoding** (the iteration 12 lesson): fix batch sizes in bytes, not rows, and gate on the RSS peak.
- **Type coercion surprises** on import (dates, decimals, booleans, empty strings): the inferred preview shows the target type per column, and the error report gives line and column.
- **Parquet type mapping** (decimals, timestamps with zones, nested types): flat types in v1; nested Parquet columns are rejected with a clear error.
- **Parquet memory and disk:** DuckDB buffers inside its own allocator. `memory_limit` plus spilling to the spool directory keep the RSS peak bounded; PR 4 measures it, and the gate is the same peak ≤ baseline + 60 MiB. A 1 GiB Parquet export needs up to about twice its size in spool disk for a moment.
- **Faker dependency** size and determinism: checked in PR 5. If it doesn't hold up, the needed kinds are written in-house.

## Open questions
1. Should mock specs and import mappings be saveable in the workspace (ADR 0011), for example `*.mock.json`? Proposed: yes for mock specs in PR 7, and import mappings later with the task manager (It. 15).
2. Scheduled exports in It. 15 will run in core without a save dialog. Proposed: keep the bytes-over-gRPC rule for now and decide a core-owned export directory in the It. 15 ADR.
3. Excel (`.xlsx`) import/export is not in the PRD; leave it out unless asked.
