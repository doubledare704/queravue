# Iteration 13 plan — Import/export + mock data

**Status:** In progress · 2026-11-27 · Protocol version 13 · PR 0 (ADRs 0024 and 0025, contract) done

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
  - `ListFormats` returns the import and export formats this core build supports (Parquet only with the `duckdb` tag).
  - `ExportResult`, `ExportTable` and `ExportCollection` are server streams of `ExportEvent`: a header, byte chunks of at most 1 MiB with progress, then a summary or an error.
  - `InferImport` is a client stream of the first bytes; it returns the format, columns, types and a preview.
  - `Import` is a bidirectional stream: the app sends a header (target: existing table, new table or collection; mappings; format options; error policy; `single_transaction`; `confirmed`) and then chunks; core streams back progress and a summary with committed rows and row errors, and a summary may follow an error.
  - Typed `TransferError` kinds: PARSE, MAPPING, CONSTRAINT, CONFIRMATION_REQUIRED, AUTH, NETWORK, TIMEOUT, CANCELED, UNSUPPORTED, SERVER.
- `proto/queravue/v1/mockdata.proto`, `MockDataService` (`SuggestMockSpec`, `PreviewMock`, `RunMock`), as in ADR 0025 §6. A `MockSpec` is a seed and targets, each with rows and `MockColumnRule`s (faker kind as a string, sequence, ranges, weighted values, constant, pattern, foreign key, embedded document, array, skip).
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

## Batch 1 prompts (after PR 0)

**Base:** `main` at `6eec1e1` (PR 0 merged as #81). The contract, the stub `TransferService` and `MockDataService`, `engine.RowLoader` / `engine.DocumentLoader`, the capabilities `bulk_load` / `document_load` and protocol version 13 are on main.

| Job | PR | Area | Depends on | Can run now |
|---|---|---|---|---|
| F1 | 1 | `core/internal/dataformat` (new), `core/internal/results` | — | yes |
| L1 | 2 | `core/internal/engine/{postgres,sqlite,mysql,mongo,enginetest}` | — | yes |
| M1 | 5 | `core/internal/mockdata` (new), `core/internal/api/mockdata_service.go` | L1 for the real run; uses a fake loader until then | yes |
| A1 | 6 | `app/lib/features/transfer/` (new), `app/lib/core_client/` upload helper | F2 (PR 4) for real data; builds on fakes | yes |
| A2 | 7 | `app/lib/features/mock_data/` (new) | M1 for real data; builds on fakes | yes |

PR 3 (L2: SQL Server, Oracle, ClickHouse, DuckDB loaders) starts when L1's conformance suite is merged. PR 4 (F2: `TransferService`) starts when F1 and L1 are merged. Both go in batch 2.

**Shared files:**
- A1 and A2 both touch `app/lib/features/editor/application/editor_tabs.dart` (`TabKind`), `app/lib/features/schema/presentation/schema_tree_view.dart` (context menu) and `app/lib/features/command_palette/application/builtin_actions.dart`. Keep edits there additive (one enum value, one menu entry, one action each); whichever merges second rebases.
- L1 and M1 both read `engine/load.go` and must not change it. A contract change goes through a separate PR.
- No job changes anything under `proto/`.

### Prompt F1 — PR 1: streaming file formats

```text
Repository: Queravue (Flutter desktop UI in app/, Go core in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: names over comments, ctx first, wrapped errors, table-driven tests, no new dependencies without a reason in the PR. Do NOT change anything under proto/.

Context: Iteration 13 adds import and export. Read docs/adr/0024-import-export.md (§2 formats, §6 errors), docs/plans/iteration-13.md (PR 1 row, Testing), core/internal/results/format.go (the current TSV/CSV/JSON Formatter used by QueryService.CopyRange) and core/internal/engine/execute.go (engine.Value kinds).

Task: implement PR 1 on a new branch `iteration-13-pr1-dataformat` from the latest origin/main.
1. New package core/internal/dataformat with streaming readers and writers. A Writer takes columns once, then batches of []engine.Value rows, writing to an io.Writer. A Reader reads from an io.Reader and yields batches of rows. Neither holds more than one batch. Cap batches by bytes (about 1 MiB) as well as rows (500).
2. Formats: CSV and TSV (RFC 4180 quoting; configurable delimiter, quote and null text; header on/off; UTF-8 with optional BOM; any other encoding is a clear error with the byte offset), JSON array and NDJSON of objects keyed by column name, and an SQL dump writer that emits INSERT statements through sqldialect (QuoteIdent, QualifyTable, FormatLiteral), multi-row up to a byte cap, with optional CREATE TABLE from the existing DDL builder. Document readers/writers for Mongo are relaxed or canonical EJSON per line or array; reuse the EJSON helpers in core/internal/engine/mongo or move the minimum needed to a shared place.
3. Type sniffing for tabular files: from the first N rows, infer a ValueKind per column (bool, int, float, decimal, timestamp, uuid, json, text) and nullability. Mixed columns fall back to text with a warning. This feeds InferImport in PR 4.
4. Bad rows: the reader reports line and column for every error and can continue after one (the SKIP policy), never panicking.
5. Move results.Formatter behind the new Writer interface so CopyRange and export share one encoder. CopyRange output must stay byte-identical; prove it with the existing tests plus a golden test.
6. Tests: goldens per format in core/internal/dataformat/testdata (quoting, embedded newlines, empty vs NULL, unicode, wide rows, every engine.Value kind) regenerated with -update; Go fuzz tests for the CSV and NDJSON readers; a test that reads a generated 1 GiB CSV from an io.Reader with flat heap (sample runtime/metrics and assert the live-heap peak stays under a few MiB).

Done when: `cd core && go build ./... && go vet ./... && go test ./... && golangci-lint run` are green and a PR titled "Iteration 13 PR 1: streaming file formats" is open against main with the 1 GiB read numbers in its description.
```

### Prompt L1 — PR 2: bulk loaders on Postgres, SQLite, MySQL and Mongo

```text
Repository: Queravue. Read AGENTS.md and CLAUDE.md first and follow them. Do NOT change anything under proto/ or core/internal/engine/load.go.

Context: Iteration 13 needs one fast insert path for import and mock data. Read docs/adr/0024-import-export.md §8 (loader capabilities), docs/adr/0003-engine-interface.md, core/internal/engine/load.go (RowLoader, DocumentLoader, RowBatchSource, DocumentBatchSource, LoadStats), core/internal/engine/descriptor.go (CapBulkLoad, CapDocumentLoad, CapabilityInterfaces), the engine packages postgres, sqlite, mysql and mongo, core/internal/engine/enginetest and docs/perf/iteration-12.md (why batches are sized in bytes and gates use the RSS peak).

Task: implement PR 2 on a new branch `iteration-13-pr2-loaders` from the latest origin/main.
1. RowLoader on Postgres and every Postgres-wire variant it serves (CockroachDB included) with pgx CopyFrom; on SQLite with a prepared multi-row insert inside a transaction per batch; on MySQL with multi-row INSERT batches sized below max_allowed_packet (read it once per load). Declare CapBulkLoad on those descriptors.
2. DocumentLoader on Mongo and its variants (DocumentDB, Cosmos DB) with unordered InsertMany in batches of about 1–2 MiB of BSON. Declare CapDocumentLoad.
3. Contract of every loader: pull batches from the source until io.EOF; commit per batch; on ctx cancel or a source error, stop after the current batch and return the committed LoadStats together with the error; map server errors to engine errors (constraint violations as their own kind so PR 4 can report CONSTRAINT); never log row values.
4. Conformance suite in core/internal/engine/enginetest (a RowLoader suite and a DocumentLoader suite): load a fixture with every engine.Value kind the engine supports and read it back through Execute/Find; empty source; cancel mid-load leaves only whole committed batches; a unique violation in the middle of a batch returns stats plus a constraint error. Wire it into each engine's integration tests (//go:build integration, docker DBs from dev/docker-compose.yml).
5. Perf test (integration, opt-in env like GRIDFS_MEMORY_PERF): 1M generated rows into Postgres and 1M documents into Mongo from a fixed in-memory source. Record rows/s and the core RSS peak (sample ps -o rss= every 100 ms) and assert the peak ≤ baseline + 60 MiB. Put the numbers in docs/perf/iteration-13.md under "Lane L".

Done when: core build/vet/tests/lint are green; the integration suites pass on the docker Postgres, CockroachDB, MySQL, SQLite and Mongo (and DocumentDB Local via make test-docdb if available); Postgres ≥ 50k rows/s and Mongo ≥ 30k docs/s; and a PR titled "Iteration 13 PR 2: bulk loaders (Postgres, SQLite, MySQL, Mongo)" is open against main.
```

### Prompt M1 — PR 5: mock data generator in core

```text
Repository: Queravue. Read AGENTS.md and CLAUDE.md first and follow them. Do NOT change anything under proto/ or core/internal/engine/load.go.

Context: Read docs/adr/0025-mock-data.md, docs/plans/iteration-13.md (PR 5 row, exit criteria), proto/queravue/v1/mockdata.proto (MockSpec, MockColumnRule and the rule messages, MockError kinds), core/internal/api/mockdata_service.go (stub), core/internal/engine/load.go, core/internal/engine/graph.go (RelationLister), core/internal/engine/schema.go (DescribeTable) and DocumentStore.SampleFieldPaths in core/internal/engine/document.go. Real loaders land in PR 2 on another branch; until it merges, test against a fake RowLoader/DocumentLoader.

Task: implement PR 5 on a new branch `iteration-13-pr5-mockdata` from the latest origin/main.
1. New package core/internal/mockdata: one generator per rule (faker kind, sequence, int/float/decimal range, time range, weighted values, constant, pattern, foreign key, embedded document, array, skip), plus null_ratio and unique. Everything is deterministic for a seed: derive one source per target and column from the seed, so the preview equals the first rows of a run and adding a column does not change other columns.
2. Faker: add github.com/brianvoe/gofakeit/v7 (MIT) and give the reason in the PR. Expose a fixed list of supported faker kinds. Write in-house any kind that is not deterministic with a seeded source.
3. Default rules: heuristics from column name and type (email, name, phone, city, country, url, *_at / *_date → time range in the last two years, identity/serial/default columns → skip, booleans, numerics, uuid, json) and from sampled Mongo field paths, including nested documents and arrays.
4. FK planner: order targets topologically with RelationLister; FK columns get a foreign_key rule; report cycles as MockCycle with edges and nullability; draw child keys from keys generated in this run (compact set) or from a capped sample of existing parent keys. Unique rules use sequences or bounded retries, then fail with UNIQUE_EXHAUSTED and the column.
5. MockDataService: SuggestMockSpec, PreviewMock (default 20 rows, max 200, nothing written) and RunMock (progress per target throttled to about 4 per second, target_done, summary; cancel stops after the current batch; production connections need confirmed, otherwise CONFIRMATION_REQUIRED). Use the RowLoader/DocumentLoader the session's Conn exposes; FAILED_PRECONDITION without one.
6. Tests: unit tests per rule (ranges, null ratio within tolerance on 100k rows, uniqueness, patterns), seed determinism, planner order and cycle reports, and service tests with a fake loader. After PR 2 is on main, rebase and add an integration test that generates 1M rows into a Postgres table with an FK and 1M documents into Mongo. Assert Postgres ≤ 20 s, Mongo ≤ 35 s and core RSS peak ≤ baseline + 60 MiB, and record the numbers in docs/perf/iteration-13.md under "Lane M".

Done when: core build/vet/tests/lint are green, the integration test meets the exit numbers (or, if PR 2 is not merged yet, the PR says so and the fake-loader tests are green), and a PR titled "Iteration 13 PR 5: mock data generator (core)" is open against main.
```

### Prompt A1 — PR 6: import and export in the app

```text
Repository: Queravue. Read AGENTS.md and CLAUDE.md first and follow them: Riverpod plain Notifiers (ADR 0002), feature-first folders, no business logic in widgets, keyboard-first, capability gating with no engine ids in Dart, golden tests for key widgets. Do NOT change anything under proto/ or core/.

Context: Read docs/adr/0024-import-export.md, docs/plans/iteration-13.md (PR 6 row), proto/queravue/v1/transfer.proto (generated Dart in app/lib/core_client/gen/queravue/v1/transfer.*), app/lib/core_client/core_connection.dart (transferService) and app/lib/core_client/gridfs_upload.dart (own HTTP/2 transport for client streams, because grpc-dart queues client messages ahead of flow control). Look at app/lib/features/gridfs (save/open dialogs, temp files, progress and cancel) and app/lib/features/grid/application/copy_service.dart. The core TransferService is a stub until PR 4; build against a fake repository and the real contract.

Task: implement PR 6 on a new branch `iteration-13-pr6-transfer-ui` from the latest origin/main.
1. Generalise gridfs_upload.dart into one client-streaming / bidirectional helper for any method path, keeping its auth, flow-control, error and cancel behaviour and its tests. Import is a bidirectional stream: send header + ≤1 MiB chunks read from the file while reading ImportResponse events. Keep GridFS upload working through the helper.
2. app/lib/features/transfer: a repository over TransferService (ListFormats, the three exports, InferImport, Import), a controller per flow and the UI.
   - Export from the result grid, a table (schema tree) and a collection: format picker limited to ListFormats, format options, save dialog, progress with cancel (cancel visible after 300 ms), a summary.
   - Import wizard from the schema tree, a table and a collection: open dialog; InferImport over the first few MiB; a preview grid with inferred types; column mapping; target (existing table, new table with editable columns and a DDL review step, or collection); error policy; single transaction; production confirmation; progress, cancel and a row-error report with line numbers.
3. Gate on capabilities: import into tables needs bulk_load, into collections document_load; export needs execute or document_store. Parquet appears only when ListFormats lists it.
4. Command palette entries and shortcuts for Export… and Import…; keep shared-file edits additive (see "Shared files" in the plan).
5. Tests: unit tests for the helper with an in-process HTTP/2 server (bidi events, trailers-only errors, cancel), controller tests with a fake repository, widget tests and goldens for the export dialog, the mapping step and the error report. When PR 4 has merged, add an e2e test (integration_test) for CSV import → grid → export on SQLite and the docker Postgres.

Done when: `cd app && flutter analyze && flutter test` are green, GridFS upload still passes its tests, and a PR titled "Iteration 13 PR 6: import and export UI" is open against main, noting whether the e2e test ran against a real PR 4 core.
```

### Prompt A2 — PR 7: mock data designer in the app

```text
Repository: Queravue. Read AGENTS.md and CLAUDE.md first and follow them (Riverpod plain Notifiers, feature-first, no business logic in widgets, keyboard-first, capability gating, goldens for key widgets). Do NOT change anything under proto/ or core/.

Context: Read docs/adr/0025-mock-data.md, docs/plans/iteration-13.md (PR 7 row), proto/queravue/v1/mockdata.proto (generated Dart in app/lib/core_client/gen/queravue/v1/mockdata.*) and app/lib/core_client/core_connection.dart (mockDataService). Look at an existing tool tab such as app/lib/features/query_builder or app/lib/features/gridfs for tab wiring, and at the result grid for showing preview rows. The core MockDataService is a stub until PR 5; build against a fake repository.

Task: implement PR 7 on a new branch `iteration-13-pr7-mock-data-ui` from the latest origin/main.
1. app/lib/features/mock_data: repository over MockDataService, a controller holding the MockSpec, and a mock data tab opened from the schema tree (tables or collections, multi-select) and from the command palette.
2. UI:
   - A target list in FK order with row counts and a cycle banner that names the edges and offers "set nullable FK to NULL" or "leave table out".
   - A per-column rule editor: the rule kind plus its fields, faker kind from faker_kinds, null ratio, unique, and nested rules for documents and arrays.
   - Seed and a "new seed" action.
   - A preview grid (PreviewMock, refreshed after edits with a debounce).
   - Run with per-target progress, rows/s, cancel (visible after 300 ms), production confirmation and a summary.
3. Gate on capabilities: tables need bulk_load and schema_inspector; collections need document_load.
4. Save and load the spec as a workspace file `*.mock.json` (ADR 0011) if it fits in this PR; otherwise leave it out and say so in the PR.
5. Command palette entry and shortcut; keep shared-file edits additive (see "Shared files" in the plan).
6. Tests: controller tests with a fake repository (rule edits, cycle handling, run progress, cancel), widget tests and goldens for the rule editor and the target list. When PR 5 has merged, add an e2e test that generates 10k rows into the seeded Postgres and Mongo.

Done when: `cd app && flutter analyze && flutter test` are green and a PR titled "Iteration 13 PR 7: mock data designer" is open against main, noting whether the e2e test ran against a real PR 5 core.
```
