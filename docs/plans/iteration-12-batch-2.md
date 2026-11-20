# Iteration 12 — batch 2 (parallel jobs)

**Date:** 2026-11-20 · Base: `main` at `4832ed4` (PRs #66, #67, #68, #69 merged)

## State of `main`
| PR | Merged as | What landed |
|---|---|---|
| 0 | #66 | ADRs 0022/0023, `TranslateMongoSql` + `GridFsService` contract, protocol 12 |
| 1 | #68 | `core/internal/mongosql`: lexer, parser, AST (already has `join`, `aggregateCall`, `arithmetic` nodes), FIND translation, warnings, shell code, 156 corpus cases (`testdata/corpus`, `-update`), `TranslateMongoSql` handler |
| 3 | #67 | `DocumentPreviewController` (`runFind`, `runShell`, cap, cancel after `kCancelDelay`) + `DocumentPreviewPane`; filter and pipeline builders use it; It. 11 gap closed in ROADMAP |
| 5 | #69 | `engine.GridFS` on Mongo (all variants declare `gridfs`), full `GridFsService`, integration tests, 1 GiB round-trip numbers in `docs/perf/iteration-12.md` |

Checked on `origin/main`: `go build`, `go vet`, `go test ./...`, `golangci-lint` clean; `flutter analyze` clean, `flutter test` 696 passed.

Still missing for the iteration: aggregate translation and the differential test (PR 2), the SQL mode tab (PR 4), the GridFS viewer (PR 6), the PDF spike, and docs/perf/roadmap close-out (PR 7).

## Jobs in this batch
| Job | Area | Depends on | Can run now |
|---|---|---|---|
| A — PR 2 aggregate translation | `core/internal/mongosql` | — | yes |
| B — PR 4 SQL mode tab | `app/lib/features/mongo_sql/` (new) | contract only; aggregate results appear once A merges | yes |
| C — PDF preview spike | `spikes/pdf/`, ADR 0023 §6 | — | yes |
| D — PR 6 GridFS viewer | `app/lib/features/gridfs/` (new) | C only for the PDF renderer; ships with the system-viewer default | yes |
| E — PR 7 close-out | docs, perf, ROADMAP | A, B, C, D merged | **no, run last** |

**Shared files (B and D both touch them):** `app/lib/features/editor/application/editor_tabs.dart` (`TabKind`), `layout_persistence.dart`, `features/schema/presentation/schema_tree_view.dart` (context menu), `features/command_palette/application/builtin_actions.dart`. Keep edits there additive and minimal (one enum value, one menu entry, one action); whichever merges second rebases. A and C touch no app files.

---

## Prompt A — PR 2: aggregate translation + differential test

```text
Repository: Queravue (Flutter desktop UI in app/, Go core in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: names over comments, ctx first, wrapped errors, integration tests behind //go:build integration, no new dependencies without a reason. Do NOT change anything under proto/.

Context: Iteration 12 adds SQL mode for MongoDB. Read docs/adr/0022-mongo-sql-mode.md (the contract), docs/plans/iteration-12.md (PR 2 row), and the existing package core/internal/mongosql (lex.go, parse.go, ast.go, condition.go, translate.go, warnings.go, shell.go, corpus_test.go). PR 1 implemented FIND translation and returns UNSUPPORTED_CONSTRUCT for anything that needs a pipeline; corpus cases such as unsupported_count_star, unsupported_count_distinct, unsupported_inner_join, unsupported_computed_column and unsupported_arithmetic_in_where pin that today.

Task: implement iteration 12 PR 2 on a new branch `iteration-12-pr2-mongosql-aggregate` from the latest origin/main.
1. AGGREGATE translation (MONGO_SQL_RESULT_KIND_AGGREGATE, pipeline_ejson as a canonical EJSON array, shell code `.aggregate([...])`) whenever the statement has GROUP BY, aggregates (COUNT(*), COUNT(f), COUNT(DISTINCT f), SUM, AVG, MIN, MAX), HAVING, DISTINCT, computed columns (+ - * / on numbers, also in WHERE via $expr), or JOIN. FIND stays the output for everything PR 1 already handles — do not change existing FIND goldens.
2. Stage order: $match (WHERE, pushed before $lookup when it only touches the base collection) → $lookup/$unwind → $match (rest of WHERE) → $group → $match (HAVING) → $project/$addFields → $sort → $skip → $limit. DISTINCT becomes $group on the selected fields.
3. JOIN mapping per ADR 0022 §5: equality ON → $lookup localField/foreignField + $unwind (preserveNullAndEmptyArrays true for LEFT); compound ON → $lookup with let + pipeline + $match $expr, plus a warning about older DocumentDB/Cosmos DB. RIGHT/FULL/CROSS joins stay UNSUPPORTED_CONSTRUCT with offsets. Qualified fields from the joined alias resolve to the $lookup "as" path.
4. COUNT(f) counts documents where f is neither null nor missing (ADR 0022 §6), with the warning. ORDER BY may reference select aliases and ordinals after $group.
5. Flip the PR 1 "unsupported_*" cases that are now supported into real goldens (rename them to describe the feature), keep every genuinely unsupported construct with kind and offset. Bring the corpus to at least 100 supported cases plus the unsupported ones (it is ~156 total today; aim for ~220).
6. Differential test (//go:build integration, core/internal/mongosql): load one flat fixture with no null/missing ambiguity into the docker Mongo (dev/docker-compose.yml service `mongo`) and into in-memory SQLite (modernc.org/sqlite, already a dependency). Tag corpus cases as comparable (e.g. a `comparable: true` field in the .mql.json or a list in the test), run the SQL on SQLite and the generated MQL on Mongo, and compare results as multisets (ordered when ORDER BY is total). At least 60 comparable cases.
7. Assert each ADR 0022 §6 semantic case against the real server in the integration test, not only as golden text.
8. Add a benchmark for translation time per corpus query and put p50/p95 in docs/perf/iteration-12.md under a "Lane T" heading.

Done when: `cd core && go build ./... && go vet ./... && go test ./... && golangci-lint run` are green, `go test -tags=integration ./internal/mongosql/...` is green with `docker compose -f dev/docker-compose.yml up -d --wait mongo`, corpus has ≥100 supported cases, and a PR titled "Iteration 12 PR 2: SQL → MongoDB aggregate translation" is open against main describing what changed and the comparable-case count.
```

## Prompt B — PR 4: SQL mode tab in the app

```text
Repository: Queravue (Flutter desktop UI in app/, Go core in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: Riverpod plain Notifiers without codegen (ADR 0002), feature-first folders, no business logic in widgets, keyboard-first (shortcut + command-palette entry), capability gating only (never check engine ids), names over comments. Do NOT change proto/ or core/.

Context: Read docs/adr/0022-mongo-sql-mode.md (§7 execution, §8 gating), docs/plans/iteration-12.md (PR 4 row) and docs/plans/iteration-12-batch-2.md. The core RPC QueryBuilderService.TranslateMongoSql (app/lib/core_client/gen/queravue/v1/querybuilder.pb*.dart) already works for FIND queries; AGGREGATE translations arrive in a parallel PR and use the same response shape (kind, pipeline_ejson, shell_code), so build for both kinds now and test AGGREGATE with fakes. Reuse, do not duplicate:
- DocumentPreviewController.runFind / runShell and DocumentPreviewPane (app/lib/features/documents/application/document_preview_controller.dart, presentation/document_preview_pane.dart) for the capped, cancellable preview.
- The shell path (app/lib/features/shell/, ShellService Eval → cursor handle → FetchCursor) and the document views for full runs.
- The pipeline builder (app/lib/features/documents/pipeline_builder/) for "Open in pipeline builder"; showPipelineBuilder currently only takes a PipelineTarget, so add an optional initial pipeline (EJSON text) and feed it through the builder's existing import.
- The editor widget, SQL highlighting and completion popup from app/lib/features/editor/ and app/lib/features/completion/; field suggestions from DocumentService.SampleFieldPaths, collection names from the schema listing.

Task: implement iteration 12 PR 4 on a new branch `iteration-12-pr4-sql-mode` from the latest origin/main.
1. New feature folder app/lib/features/mongo_sql/ (domain, data repository wrapping TranslateMongoSql, application controller, presentation).
2. A "SQL mode" tab kind (add one TabKind value in features/editor/application/editor_tabs.dart and persist it in layout_persistence.dart). Opened from the schema tree context menu on a Mongo database or collection ("Query with SQL"), from the command palette ("Open SQL mode"), and with a shortcut that does not clash with existing bindings. Offered only when the connection has both `document_store` and `shell` capabilities.
3. Layout: SQL editor on top; a generated MQL pane with a Shell / EJSON toggle and copy; a warnings strip listing MongoSqlWarning messages (click jumps to offset); results below. Translate on edit with a short debounce; PARSE and UNSUPPORTED_CONSTRUCT errors underline the SQL at the returned UTF-8 offset (convert to UTF-16 for the editor) and keep the last good MQL visible but marked stale.
4. Actions: Preview (capped, via DocumentPreviewController), Run (full, through a shell and the document views, Cancel after 300 ms), Open in pipeline builder (AGGREGATE only), Copy MQL.
5. Save as a workspace file is optional; skip unless trivial.
6. Tests: controller tests with a fake repository for FIND, AGGREGATE, PARSE and UNSUPPORTED results; widget tests for the tab (error underline, warnings, toggle, gating hides the entry without the capabilities); a golden for the MQL pane. Keep existing goldens green.
7. Update docs/engines/mongodb.md with a short "SQL mode" usage section (link ADR 0022 for the semantics list).

Shared files with a parallel GridFS PR: editor_tabs.dart, layout_persistence.dart, schema_tree_view.dart, builtin_actions.dart. Keep your changes there additive and small.

Done when: `cd app && flutter analyze && flutter test` are green and a PR titled "Iteration 12 PR 4: SQL mode tab for MongoDB" is open against main.
```

## Prompt C — PDF preview spike

```text
Repository: Queravue (Flutter desktop app in app/, Go core in core/). Read AGENTS.md (dependency and performance-budget rules) and docs/adr/0023-gridfs.md §5–§6.

Task: a time-boxed (half day) spike that decides how the GridFS viewer previews PDFs. Work on a new branch `iteration-12-pdf-spike` from the latest origin/main. Do NOT add dependencies to app/pubspec.yaml; build the prototype as a separate minimal Flutter macOS app under spikes/pdf/ (look at spikes/README.md and the existing spikes for the layout).

Compare:
1. In-app rendering with `pdfrx` (MIT, bundles PDFium): render page 1 and scroll pages of (a) a 1-page PDF, (b) a 300-page text PDF, (c) a 30 MiB image-heavy PDF, all loaded from memory bytes (the viewer gets bytes over gRPC, never a path).
2. System viewer: write bytes to a temp file and open it with the OS default app (macOS `open`, Windows `start`, Linux `xdg-open`, or url_launcher if already a dependency of app/).

Measure for option 1 on macOS release builds: added app bundle size, idle RSS delta with the package linked but unused, RSS peak while showing each file and after closing it, time to first page. Note licensing of the bundled PDFium binaries and Windows/Linux support.

Deliverables:
- spikes/pdf/ with the prototype and a README containing the measurements and how to reproduce them.
- An edit to docs/adr/0023-gridfs.md §6 recording the decision: adopt pdfrx only if the idle-memory delta keeps the app within the 150 MB idle budget (see docs/perf/iteration-10.md for the current baseline) and the size cost is modest; otherwise the system viewer. State the numbers.
- A PR titled "Iteration 12: PDF preview spike for GridFS" against main.
```

## Prompt D — PR 6: GridFS viewer in the app

```text
Repository: Queravue (Flutter desktop UI in app/, Go core in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: Riverpod plain Notifiers without codegen (ADR 0002), feature-first folders, no business logic in widgets, virtualized lists only, keyboard-first (shortcut + command-palette entry), capability gating only (never check engine ids), names over comments, memory budgets. Do NOT change proto/ or core/.

Context: Read docs/adr/0023-gridfs.md, the GridFS section of docs/engines/mongodb.md, docs/plans/iteration-12.md (PR 6 row) and docs/plans/iteration-12-batch-2.md. The core GridFsService is fully implemented (proto/queravue/v1/gridfs.proto; Dart client at app/lib/core_client/gen/queravue/v1/gridfs.pbgrpc.dart, exposed as CoreConnection.gridFsService in app/lib/core_client/core_connection.dart; the test fake in app/test/support/fakes.dart throws, so tests use a fake repository). Follow the structure of an existing feature such as app/lib/features/keyvalue/ or app/lib/features/documents/ (data repository → application controller → presentation).

Task: implement iteration 12 PR 6 on a new branch `iteration-12-pr6-gridfs-viewer` from the latest origin/main.
1. New feature folder app/lib/features/gridfs/ with a repository wrapping ListBuckets, ListFiles (server stream of batches), Download (header then ≤1 MiB chunks, optional offset/length), Upload (client stream: header then chunks), DeleteFile, RenameFile, mapping GridFsError kinds to typed failures.
2. Schema tree: when the connection has the `gridfs` capability, show a "GridFS" node per database listing buckets, and hide the `<bucket>.files` / `<bucket>.chunks` collections behind it with a toggle to show them (ADR 0023 §2). Opening a bucket opens a GridFS tab (add one TabKind value; persist it in layout_persistence.dart).
3. Bucket tab: virtualized file list (reuse the grid from ADR 0004 / app/lib/features/grid/) with filename, length (human-readable), upload date, content type, id; relaxed EJSON filter + sort bar; paging like the document tab (one extra row to detect a next page); Cancel replaces Refresh after 300 ms.
4. Preview panel for the selected file using ranged Download, with ADR 0023 §5 caps: text up to 1 MiB (UTF-8, else a hex view), images up to 32 MiB (PNG, JPEG, GIF, WebP, BMP via Image.memory), PDF up to 32 MiB. Type from content_type, then magic bytes of the first 512 bytes. Larger files show metadata and Download. Release preview bytes when the selection changes.
5. PDF: a parallel spike decides the renderer. Ship the default from ADR 0023 §6: write the bytes to a temp file and open in the system viewer. Put it behind a small interface (e.g. PdfPreviewer) so the spike's outcome can swap the implementation without touching the panel.
6. Upload (file picker → stream file in ~1 MiB chunks, progress, cancel; optional content type and metadata), Download (save dialog → stream to file, progress, cancel), Rename, Delete. On production connections Delete and replacing Upload ask first and resend with confirmed=true after CONFIRMATION_REQUIRED (same UX as document deletes). Never read a whole file into memory for upload or download.
7. Commands: palette entries and shortcuts for Upload, Download, Delete, Refresh in a GridFS tab.
8. Tests: repository/controller tests with fakes (paging, ranged preview, sniffing, upload cancel, confirmation flow), widget tests and goldens for the file list and preview panel. If app/integration_test has a pattern for real-core e2e (see docs/testing.md), add one e2e: upload → preview → download → delete on the docker Mongo.
9. Measure and add to docs/perf/iteration-12.md under "Lane G: app": app RSS during a 1 GiB upload and download, 32 MiB image preview peak and release, combined idle memory after a GridFS session (budget 150 MB).

Shared files with a parallel SQL mode PR: editor_tabs.dart, layout_persistence.dart, schema_tree_view.dart, builtin_actions.dart. Keep your changes there additive and small.

Done when: `cd app && flutter analyze && flutter test` are green, measurements are recorded, and a PR titled "Iteration 12 PR 6: GridFS viewer" is open against main. If a new package is needed (e.g. file_selector), justify it in the PR description per AGENTS.md.
```

## Prompt E — PR 7: close-out (run after A–D are merged)

```text
Repository: Queravue. Read AGENTS.md, ROADMAP.md (It. 10 and It. 11 sections show the status format), docs/plans/iteration-12.md, docs/plans/iteration-12-batch-2.md, ADRs 0022 and 0023, and docs/perf/iteration-12.md.

Task: close iteration 12 on a branch `iteration-12-pr7-closeout` from the latest origin/main. No code changes except fixes needed to make checks pass.
1. Verify the exit criteria on main: translator corpus ≥100 supported cases passing (`cd core && go test ./internal/mongosql/...`), differential test green (`go test -tags=integration ./internal/mongosql/...` with the docker Mongo), GridFS 1 GiB round-trip flat memory (core numbers exist; app numbers from PR 6), filter-builder preview gap closed. Run the full checks: `cd proto && buf lint`, `cd core && go build ./... && go test ./... && golangci-lint run`, `cd app && flutter analyze && flutter test`.
2. ROADMAP.md: mark It. 12 ✅ done with a Status paragraph (PR numbers, protocol 12, ADRs 0022/0023, corpus size, key measurements) and a "Known gaps (carry forward)" list collected from the PRs (e.g. Cosmos DB unverified, DocumentDB $lookup-pipeline limits, PDF approach).
3. ADRs 0022 and 0023: Status → Accepted, with any deviations the implementation made.
4. docs/plans/iteration-12.md: status Done, link the PRs per row.
5. docs/perf/iteration-12.md: fill the "Not measured yet" section or move remaining items to the known gaps.
6. Open a PR titled "Iteration 12 PR 7: close-out (roadmap, ADR status, perf)" against main.
```
