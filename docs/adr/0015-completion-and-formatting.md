# ADR 0015 — Completion & formatting

**Status:** Accepted · 2026-11-08

## Context
Iteration 8 adds schema-aware completion to the SQL editor, the Mongo shell and the Mongo query bar, plus a SQL formatter. The PRD budget is autocomplete ≤ 50 ms from keystroke to visible popup, on a 500-table, ~7,500-column schema.

What exists today:
- Per-dialect scanners in `internal/sqlsplit` (ADR 0006) and the `Dialect` layer (ADR 0008). The scanner is internal; there is no public token API.
- A session-scoped schema cache loaded lazily in four levels (ADR 0007). Columns come from per-table `GetTableDetails`, which would mean 500 RPCs to know a 500-table schema.
- `SampleFields` (ADR 0009) returns top-level Mongo fields only.
- Offsets on the wire are UTF-16 code units (ADR 0006).

Related: ADR 0003 (capabilities), 0005 (re_editor), 0010 (shell runtime), 0011 (workspace).

## Decision

### 1. Completion runs in core
The UI sends `CompletionService.Complete` with the text of the current statement and a cursor offset relative to that text (UTF-16). The UI picks the statement with the same `sqlsplit` rules core uses; it never sends the whole file. For `shell` the window is the current script chunk; for `mongo_query` it is the whole input.

Core already holds the lexers and the schema cache, so no catalog, lexer or dialect rule is duplicated in Dart.

**Latency budget (p95):**

| Step | Budget |
|---|---|
| Keystroke → request sent (no debounce) | 2 ms |
| Unix-socket RPC round trip, excluding work | 2 ms |
| Core completion (analyze + rank), Go benchmark | ≤ 10 ms |
| Decode + filter + popup frame | ≤ 15 ms |
| Headroom for frame scheduling | ~20 ms |

**Stale requests.** The UI cancels the in-flight `Complete` on every keystroke (ADR 0006: everything is cancellable). Core checks `ctx` between analysis and ranking.

**Local re-filtering.** Core returns every candidate for the context up to `max_items`, with `is_incomplete = false` when nothing was cut. While the user extends the same identifier prefix in the same context (same replace-range start, same context), the UI filters and re-sorts the last list locally by the documented ranking and does not call core. A request is sent again when the context changes (a `.`, a keyword, a new clause), the prefix shrinks, the cursor leaves the range, `is_incomplete` is true, or the catalog state changed.

**Rejected: complete in Dart over a catalog snapshot.** It removes the RPC but needs a second implementation of the lexers, clause analysis, quoting and ranking, a snapshot protocol (about 300–500 KB for 7,500 columns, resent after every DDL), and invalidation logic duplicated on both sides. The measured RPC cost is ~2 ms, so the saving is small against a 50 ms budget, and local re-filtering already covers the fast typing path.

### 2. Catalog warm-up
- **Bulk introspection.** An optional engine interface, `engine.ColumnLister` behind `CapCompletion`, lists every column of a schema in one query (Postgres/Cockroach `pg_attribute`, MySQL-family `information_schema.columns`, SQL Server `sys.columns`, SQLite `pragma_table_info` joined over `sqlite_master`).
- **Own catalog, not the ADR 0007 cache.** The columns go into a completion catalog (`internal/completion`), kept per session and database and published as immutable snapshots. They are not written into the ADR 0007 table-details cache: a cached `TableDetails` without indexes and foreign keys would reach the table view as if it were complete. The object list comes from `ListObjects`, and the schema cache is only the invalidation trigger (below).
- **Start and cancel.** Core starts warming in the background when a session opens (database = the session default; SQL engines whose default database is unknown to core, such as MySQL, start on the first `Complete` or `WarmCatalog` that names one). Closing the session cancels it. A `WarmCatalog` for a database that is already loading joins that load; when its last caller leaves, a load that a caller started is cancelled, while the automatic one at session open runs on.
- **Sharing the connection.** Each warm-up query takes the session's statement slot (`Session.Begin`) and waits, polling every 25 ms, while a user statement runs, so warming never makes a user query fail with "busy". It holds the slot only for one query at a time.
- **Progress.** `WarmCatalog` is a server stream of counters (`schemas_done/total`, `tables_loaded`, `columns_loaded`) ending with `done`. The UI shows "loading columns…" from it.
- **Never blocks.** `Complete` answers from whatever is cached. Tables come from the object list (one cheap query, loaded first); columns appear as they arrive. Each response carries `catalog_state` = `COLD`, `WARMING` or `READY`.
- **Invalidation.** The schema cache notifies listeners on every invalidation (`RefreshSchema`, `SchemaDesignService`, `IndexService`, session close), and the completion manager drops that session's catalogs; the next `Complete` or `WarmCatalog` loads them again. `QueryService` also invalidates the schema cache after a successful statement whose first token is `CREATE`, `ALTER`, `DROP` or `RENAME`; this also fixes the table browser not noticing DDL run from the editor. Detection is conservative: when in doubt, invalidate. Invalidation is per session, not per table.

### 3. Ranking
Candidates are grouped in tiers, in this order:
1. Aliases and tables in scope of the statement.
2. Columns of in-scope tables (and CTE or subquery columns where derivable).
3. Other schema objects (schemas, tables out of scope, views).
4. Keywords and functions.

Inside a tier: prefix match, then camelCase / underscore-word match (`oi` → `order_items`), then fuzzy subsequence; then a recency boost; then alphabetical. Matching is case-insensitive. The recency store is a bounded LRU per session in core, not persisted.

Insert text is the plain name unless the dialect needs quoting (reserved word, characters outside the unquoted set, case that the engine would fold), in which case `Dialect.QuoteIdent` is used. Each item carries a `sort_key` (fixed-width string) so the UI can sort without knowing the rules; local re-filtering recomputes order with the same tier/match rules, kept in sync by a shared golden test.

Analysis never fails: on unparsable or incomplete SQL it returns keywords plus all tables.

**Recency without an accept signal.** The protocol has no "item accepted" message, so core treats every identifier in the statement being edited as used, per session, with a time window (very recent: 2 minutes, recent: 30 minutes). Names typed in recent statements rank first inside a tier and match class. Recency never lifts an item across a tier or match-class boundary.

**Context analysis.** `completion.Analyze` runs over the `sqlsplit` token stream. It builds a block tree (statement, set-operation branches, parenthesised groups) and finds the clause by the last clause keyword before the cursor in the innermost block, tables and aliases from `FROM`/`JOIN`/`UPDATE`/`INSERT INTO`, CTEs from `WITH`, and the columns of derived tables from their select lists (`*` expands from the inner tables). Outer blocks' tables stay in scope for correlated subqueries. Unqualified names resolve against the requested schema, else `public`, `dbo` or `main`, else the only schema.

### 4. Mongo
- **Field paths.** A new `SampleFieldPaths` RPC in `DocumentService` samples nested paths with types and frequency. `SampleFields` is unchanged (It. 5 stays compatible). Paths use dots; array elements use the `[]` segment: `address.city`, `tags.[]`, `items.[].sku`. Depth is capped (default 6) and the number of paths is capped. Results are cached per collection for a TTL (default 5 minutes) and dropped by an explicit refresh, by index changes (through the schema cache), and on session close. Validation rules do not change sampled data, so they do not invalidate it.
- **Shell.** A lightweight JS lexer around the cursor (no code runs, goja is not involved) classifies the position: `db.` → collections; `db.<coll>.` → collection methods; `<cursor>.` → cursor methods; a key position inside a filter, projection, update or pipeline-stage object → field paths and operators (`$eq`, `$in`, `$elemMatch`, …); a value position after `$`-operator → nothing special.
- **Query bar.** `mongo_query` uses the same key/operator analysis on EJSON text, with the collection supplied in the request.
- Method, cursor-method and operator lists are written by hand from the MongoDB manual.

### 5. Formatter
- Lives in core, per dialect, on the lexer exported from `sqlsplit`. This ADR requires `sqlsplit` to expose a token stream (kind, byte range, text) that preserves comments and whitespace; the scanner's internals stay private.
- Options: `keyword_case` (upper, lower, preserve), `indent_width`, `comma_style` (trailing, leading), `max_line_width`. Formats a selection or the statement chosen by the UI (empty range = whole text).
- Safety invariants, enforced by tests and by a runtime self-check that falls back to the unchanged text:
  - idempotent: `format(format(x)) == format(x)`;
  - token-preserving: the token stream is identical except for whitespace and keyword case;
  - comments, string literals and dollar-quoted bodies are untouched;
  - unknown syntax passes through unchanged rather than erroring.
- Errors are typed with a UTF-16 position (lexing failures such as an unterminated string).
- JavaScript formatting for the shell is out of scope. Pretty-printing EJSON in the query bar stays UI-side.

### 6. Contract
`proto/queravue/v1/completion.proto` adds `CompletionService` (`Complete`, `WarmCatalog`, `FormatSQL`) and `document.proto` adds `SampleFieldPaths`. All changes are additive; existing field numbers are untouched. Failures are returned in-band as `AdminError` (kinds `UNSUPPORTED`, `INVALID` with `position`, `CANCELED`, `SERVER`), the same type index, stats and design use, so the UI keeps one error path.

Capabilities `completion` and `format` are added as names. Engines declare them, and their interface mappings in `CapabilityInterfaces` are added, in the PRs that implement them (PR 2 for SQL completion and bulk columns, PR 3 for Mongo and the formatter). Until then no engine declares them and the handlers return an in-band `UNSUPPORTED`. Mongo completion has no capability of its own: the UI keys it on `document_store` (query bar) and `shell` (shell). `format` is implemented by core alone, so it has no Conn interface; `engine.CapabilitiesWithoutInterface` lists it for the registry test, and the four SQL engine families declare it. The UI enables completion and format by capability and context kind, never by engine id. Protocol version becomes 8.

## Consequences
- Core grows an exported SQL token API and a per-session catalog that must stay inside the 150 MB idle budget. A 500-table schema is a few MB; the cache is bounded per session and PR 2 measures it in `docs/perf/iteration-8.md`.
- Every keystroke that changes context costs one RPC. That is accepted because the measured cost is small and removes a second implementation in Dart.
- Local re-filtering means ranking rules exist in Go and Dart. A shared golden file guards drift; if it hurts, the UI can drop local filtering and rely on the 10 ms core path.
- Warm-up costs one extra query per schema, plus one `ListObjects`, at session open. It is background, cancellable and skipped on engines without the bulk interface (they fall back to lazy per-table details).
- Statement-keyword invalidation can over-invalidate; that costs a re-warm, not correctness.
