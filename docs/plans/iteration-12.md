# Iteration 12 plan — SQL Mode for Mongo + GridFS

**Status:** In progress · 2026-11-19 · Protocol version 12 · PR 0 (ADRs 0022 and 0023, contract) done

## Goal (from ROADMAP)
- SQL → MQL translator (SELECT / WHERE / ORDER / LIMIT / GROUP BY / JOIN → `$lookup`); show the generated MQL.
- GridFS viewer: browse buckets, preview images / text / PDF, upload / download.
- **Done when:** the translator passes a test corpus of 100+ queries.

Added exit criteria, so the GridFS half has one too:
- A 1 GiB file uploads and downloads through the app with flat core and app memory (no full file in memory on either side), and both directions can be cancelled.
- The It. 11 carry-forward gap is closed: the Mongo filter builder has the capped, cancellable preview ADR 0021 §5 specifies.

## What we build on
| Need | Existing piece | ADR |
|---|---|---|
| Lexing SQL with positions | `core/internal/sqlsplit` lexers | 0008 |
| Recursive-descent SELECT parser, error offsets, `UNSUPPORTED_CONSTRUCT` style | `core/internal/querybuilder/parse.go` | 0021 |
| Running a pipeline and paging its cursor | `ShellService.Eval` → cursor handle → `FetchCursor` | 0010 §5 |
| Typed values, relaxed literal rules | EJSON code in `engine/mongo` | 0009 §1 |
| Field-path suggestions | `DocumentService.SampleFieldPaths` | 0009, 0021 §6 |
| Pipeline import from text | pipeline builder import | 0021, `docs/builders.md` |
| Production confirmation | `CONFIRMATION_REQUIRED` + `confirmed=true` | 0009 §8, 0013 |
| Capability gating, no engine ids in Dart | descriptor capabilities | 0003 |

## Decisions to record (PR 0)

### ADR 0022 — SQL mode for MongoDB
1. **Translation lives in core**, in a new package `core/internal/mongosql`, pure and without I/O (same reasoning as ADR 0021 §2: the lexers and dialect layer are Go). It has its own small AST rather than reusing `SqlQueryModel`, because SQL mode needs constructs the builder model deliberately excludes (`NOT`, arithmetic, a few scalar functions, `COUNT(DISTINCT)`, `CASE` later) and we must not grow the builder contract for them. The parser reuses the `sqlsplit` lexer through a new `mongosql` lexer flavour and copies the structure of the querybuilder parser.
2. **Accepted dialect.** Keywords are case-insensitive; field names are case-sensitive. Identifiers may be bare, `"quoted"` or `` `quoted` ``. Dotted names are field paths: the first segment is a qualifier only when it matches a `FROM`/`JOIN` alias or collection, otherwise the whole name is a path (`address.city`). Typed literals: `OBJECTID('…')`, `DATE '…'`, `TIMESTAMP '…'`, `NUMBERLONG(…)`, `NUMBERDECIMAL('…')`; bare numbers follow ADR 0009's relaxed rule. No parameter placeholders.
3. **Supported subset (the contract the corpus pins down).**
   - `SELECT [DISTINCT]` with `*`, fields, aliases, aggregates `COUNT(*)`, `COUNT(f)`, `COUNT(DISTINCT f)`, `SUM`, `AVG`, `MIN`, `MAX`.
   - `FROM coll [alias]`, `[INNER|LEFT] JOIN coll ON a.f = b.g [AND …]`.
   - `WHERE` / `HAVING`: `AND`, `OR`, `NOT`, comparisons, `IN`, `NOT IN`, `BETWEEN`, `LIKE` / `ILIKE` / `NOT LIKE`, `IS [NOT] NULL`, `+ - * /` on numbers.
   - `GROUP BY` fields, `ORDER BY` fields, aliases or ordinals with `ASC`/`DESC`, `LIMIT`, `OFFSET` (and `LIMIT n, m`).
   - Out of scope, reported as `UNSUPPORTED_CONSTRUCT` with an offset: `RIGHT`/`FULL` joins, subqueries, CTEs, `UNION`, window functions, `INSERT`/`UPDATE`/`DELETE`/DDL. SQL mode is read-only.
4. **Output shape.** The simplest form that is correct: a `find` spec (filter, projection, sort, skip, limit) when there is no join, group, aggregate, `DISTINCT` or computed column; otherwise an aggregation pipeline. Both are returned as canonical EJSON plus shell code (`db.orders.find(…)` / `db.orders.aggregate([…])`).
5. **Join mapping.** Equality `ON` → `$lookup` with `localField`/`foreignField` followed by `$unwind` (`preserveNullAndEmptyArrays: true` for `LEFT`). Compound `ON` → `$lookup` with `let` + `pipeline` + `$expr`, and the result carries a compatibility note because older DocumentDB and Cosmos DB servers reject `$expr` in `$lookup`.
6. **Semantics we document instead of hiding** (listed in `docs/engines/mongodb.md`, each with a corpus case): `IS NULL` also matches a missing field; `=` on an array field matches any element; comparisons do not cross BSON type brackets; `LIKE` becomes an anchored `$regex` with escaping; `COUNT(f)` counts documents where `f` is neither null nor missing; `ORDER BY` puts null and missing first. The translation result carries these as warnings when a query triggers them.
7. **Execution: no new path.** The app runs the generated shell code in a shell (ADR 0010), opens the cursor handle in the document views and pages it with `Find` / `FetchCursor`. Preview uses the capped preview below. "Open in pipeline builder" hands the pipeline to the existing builder import.
8. **Contract.** One additive RPC on `QueryBuilderService`: `TranslateMongoSql(session_id, sql) → {collection, kind (FIND|AGGREGATE), find spec | pipeline EJSON, shell_code, warnings[], error}`. Errors reuse `QueryBuilderError` (`PARSE`, `UNSUPPORTED_CONSTRUCT`, offsets in UTF-8 bytes like the rest of the service). The session id is used only to pick the default database. **Gating:** the UI offers SQL mode when the connection has `document_store` and `shell`; no new capability, nothing reads the engine id.

### ADR 0023 — GridFS
1. **Capability** `CapGridFS = "gridfs"` with `engine.GridFS` on the Mongo `Conn` (`ListBuckets`, `ListFiles`, `OpenDownload`, `OpenUpload`, `Delete`, `Rename`), mapped in `CapabilityInterfaces`, declared by all Mongo variants. Implemented on the driver's `gridfs` bucket API.
2. **Buckets** are discovered as `<name>.files` + `<name>.chunks` pairs. The tree shows them under a "GridFS" node per database and hides the two collections behind it (with a toggle to show them, since they are still ordinary collections).
3. **Transport: bytes stream over gRPC, the app owns the filesystem.** `Download` is a server stream of ≤ 1 MiB chunks with an optional `offset`/`length` (used by preview); `Upload` is a client stream (header with filename, metadata EJSON, content type, then chunks). The app writes and reads files through its save/open dialogs. Rejected: the core reading or writing paths given by the UI — it widens what the core can touch on disk and does not fit a later remote or scheduled core. Back-pressure comes from the streams; neither side holds a whole file.
4. **Listing** pages `<bucket>.files` with filter / sort / skip / limit (ADR 0009 §3 paging, filter in relaxed EJSON). Rows show `_id`, filename, length, upload date, content type (`metadata.contentType`, falling back to the legacy top-level `contentType`) and metadata.
5. **Preview** fetches at most N bytes through `Download` with `length`: text 1 MiB (UTF-8, else a hex view), images 32 MiB (PNG, JPEG, GIF, WebP, BMP via `Image.memory`), PDF 32 MiB. Type is decided by content type, then by magic bytes of the first 512 bytes. Larger files show metadata and "Download".
6. **PDF.** Decide after a half-day spike (PR 6): render in app with `pdfrx` (MIT, bundles PDFium) **if** it stays within the app-size and idle-memory budgets; otherwise write to a temp file and open in the system viewer. Recommendation: system viewer for v1 unless the spike is clearly cheap.
7. **Safety.** `Delete` (and overwrite on upload) needs `confirmed=true` on production connections, otherwise `CONFIRMATION_REQUIRED` (ADR 0009 §8). Rename does not.
8. **Contract.** New `gridfs.proto` with `GridFsService`; protocol version 12 (shared with ADR 0022's RPC).

## PRs and lanes
PR 0 lands first. Then three lanes run in parallel: **T** (translator), **P** (preview), **G** (GridFS).

| PR | Lane | Scope | Done when |
|---|---|---|---|
| 0 | — | ADRs 0022 and 0023, `querybuilder.proto` `TranslateMongoSql`, `gridfs.proto`, `buf generate`, stub services returning `UNIMPLEMENTED`, protocol version 12 | `buf lint` clean, generated code committed, Hello reports 12 |
| 1 | T | `mongosql` lexer flavour, parser and AST; find-shaped translation (`WHERE`, projection, `ORDER BY`, `LIMIT`/`OFFSET`, typed literals, `LIKE` escaping); golden corpus harness | ≥ 50 corpus cases green; every unsupported construct has a case asserting kind and offset |
| 2 | T | Pipeline translation: `GROUP BY`, aggregates, `HAVING`, `DISTINCT`, computed columns, `JOIN` → `$lookup`; warnings; differential integration test | corpus ≥ 100 green; differential test green on the docker Mongo |
| 3 | P | Capped, cancellable document preview (row cap, `max_time_ms`, Cancel after 300 ms) as a shared widget/controller; wire it into the Mongo filter builder | It. 11 gap closed; widget test covers cap and cancel |
| 4 | T | App SQL mode tab: SQL editor (lexer highlight, collection and `SampleFieldPaths` completion), generated MQL pane (shell / EJSON toggle), Run via shell → document views, preview via PR 3, "Open in pipeline builder", error underline at offset, warnings strip; palette entry and shortcut | widget tests + golden for the MQL pane; e2e on the seeded Mongo |
| 5 | G | Core GridFS: engine interface on Mongo, `GridFsService` (list buckets/files, ranged download, client-stream upload, delete with confirmation, rename); unit tests and integration tests on Mongo and DocumentDB Local | 1 GiB round-trip with flat core heap; cancel mid-upload leaves no orphan chunks (driver aborts and deletes them) |
| 6 | G | App GridFS viewer: tree node, virtualized file list with filter and paging, preview panel (text/hex, image, PDF per spike), upload/download with progress and cancel, delete/rename dialogs; PDF spike result recorded in ADR 0023 | widget tests, goldens for list and preview; e2e upload → preview → download → delete |
| 7 | — | Docs (`docs/engines/mongodb.md` SQL mode + semantics + GridFS; DocumentDB/Cosmos notes), `docs/perf/iteration-12.md`, ROADMAP status and known gaps | measurements below recorded |

## Testing
- **Translation corpus** `core/internal/mongosql/testdata/corpus/`: each `name.sql` has `name.mql.json` (kind, collection, spec or pipeline, warnings). Regenerate with `-update` and review the diff, like the shell corpus. Groups: filters (~30), projection/sort/paging (~15), literals and types (~10), aggregates and grouping (~20), joins (~15), unsupported constructs with offsets (~15).
- **Differential test** (`//go:build integration`): a flat fixture without null/missing ambiguity is loaded into Mongo and into in-memory SQLite (already a pure-Go dependency). For every corpus case tagged `comparable`, results from SQLite and from running the generated MQL must be equal as multisets (ordered when `ORDER BY` is total). Target ≥ 60 comparable cases.
- **Semantics cases** for each item in ADR 0022 §6, asserted on the docker Mongo, not only as golden text.
- **GridFS**: unit tests for bucket detection and content-type sniffing; integration tests for ranged download, upload cancel, production confirmation, and a file written by `mongofiles`/another driver being readable (interop).
- **Compatibility**: run the translation integration suite and GridFS suite on DocumentDB Local (`make test-docdb`); record which `$lookup` forms fail. Cosmos DB stays unverified.

## Measurements for `docs/perf/iteration-12.md`
- Translation time per corpus query (p50/p95); budget well under the 50 ms completion budget so it can run on keystroke.
- GridFS 1 GiB upload and download: throughput, core heap and app RSS over time.
- Preview of a 32 MiB image: app RSS peak and release.
- Idle memory after a GridFS session ≤ 150 MB combined.

## Risks
- **Semantic mismatch** between SQL and MQL (nulls, arrays, type brackets) — mitigated by warnings, documented semantics and the differential test; the UI always shows the MQL that actually runs.
- **Scope creep in the SQL subset** — the corpus is the contract; anything not in ADR 0022 §3 fails with an offset, never a guess (same rule as ADR 0021 §3).
- **PDF dependency** — size and memory cost decided by the spike, with a no-dependency fallback.
- **DocumentDB / Cosmos DB gaps** in `$lookup` pipelines and GridFS index creation — surfaced as server errors and warnings; documented.

## Open questions
1. PDF preview: in-app (`pdfrx`) vs. system viewer — default system viewer unless the spike is cheap.
2. Should SQL mode tabs be saveable to the workspace as `.sql` files tagged for Mongo (ADR 0011)? Proposed: yes, with a `-- queravue: mongo-sql` header line; small, can slip to It. 13.
3. Should the SQL builder (ADR 0021) later target Mongo through this translator? Out of scope here; note as a follow-up.
