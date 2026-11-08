# Editor

Design decisions are in [ADR 0015](adr/0015-completion-and-formatting.md); this page describes behaviour as it ships.

## Completion & formatting

Status: SQL completion (PR 2), the SQL formatter and Mongo completion (PR 3) are done in core. The UI follows in PR 4.

### SQL completion
- `CompletionService.Complete` takes the current statement and a UTF-16 cursor offset and returns items in ranked order. Sort by `sort_key` ascending to get the same order.
- Context kinds: `sql`, `shell` and `mongo_query` all work. `sql` needs a connection that speaks SQL, the other two need a document store; otherwise the answer is `UNSUPPORTED`.
- Ranking tiers: in-scope aliases and tables, then columns of in-scope tables, then other schema objects, then keywords and functions. Inside a tier: prefix, word start or word initials (`oi` finds `order_items`), substring, then subsequence; then recently used names; then alphabetical.
- Clauses understood: select list, `FROM`/`JOIN`, `ON`/`USING`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `INSERT` column list, `UPDATE ... SET`, `RETURNING`, after `schema.` and `alias.`.
- Aliases with or without `AS`, CTEs (explicit column lists, or derived from the select list), subquery aliases (`*` expands from the inner tables), quoted identifiers per dialect, correlated outer queries, `UNION` branches.
- Inside string literals and comments nothing completes. On SQL that does not parse, the answer is keywords plus all tables.
- Insert text is quoted with the dialect's quotes only when needed (reserved word, characters outside `[A-Za-z0-9_]`, upper case in PostgreSQL). If the user already typed an opening quote, the item replaces from the quote and is quoted.
- Keyword and function lists per dialect are in `core/internal/completion/keywords.go`.

### Mongo completion
Capabilities: there is no separate capability. The UI offers `mongo_query` completion when the connection declares `document_store`, and `shell` completion when it declares `shell`.

Field paths:
- `DocumentService.SampleFieldPaths` samples a collection (`$sample`, or the first documents when `$sample` is unavailable) and reports nested paths with types and frequency: `address.city`, `tags.[]`, `items.[].sku`. Defaults: 100 documents, depth 6 (at most 12), 2,000 paths; `truncated` says the path limit cut the list. `_id` comes first, then by frequency, then by path.
- Results are cached per session, database, collection, sample size and depth for 5 minutes and shared with completion. `refresh` samples again. The cache is dropped by `RefreshSchema`, index changes, DDL-like changes that invalidate the schema cache, and session close. Concurrent requests for the same collection share one sample.
- `Complete` waits at most 150 ms for a first sample. If it is not ready the answer carries operators and methods only and `is_incomplete = true`, so the UI asks again; the sample keeps running and the next request finds it cached.

Shell (`kind = shell`): a lightweight JavaScript lexer (nothing is run) classifies the cursor position.
- `db.` lists collections (cached 30 s) and database methods. A collection whose name is not a plain identifier, or equals a database method, is inserted as `getCollection("name")`.
- `db.<collection>.`, `db.getCollection("x").` and `db["x"].` list collection methods.
- After a call chain that contains `find` or `aggregate`, `.` lists cursor methods.
- A key position inside an object literal lists field paths and operators for the role of that object: the first argument of `find`, `findOne`, `count*`, `delete*`, `update*`, `replaceOne`, `findOneAnd*` is a filter; the second of `find` and `findOne` and `.projection()` is a projection; `.sort()` and `createIndex` take field paths; the second argument of the update methods takes update operators, and the keys inside `$set` and the other field operators are field paths; the argument of `aggregate` is a pipeline: stage operators at stage level, filter keys inside `$match`, field paths in `$project`, `$sort` and the like, `_id` and accumulators inside `$group`, the documented keys of `$lookup` and `$unwind`.
- Inside a filter: field paths are written the way queries address them (array segments dropped, so `items.sku`), plus `$and`, `$or`, `$nor` and the other top-level operators. Inside `{ field: { ` the comparison, element, array and evaluation operators appear. Inside `$elemMatch`, field paths are relative to the array element. Value positions, strings, comments and regular expressions complete nothing.
- Keys are inserted bare when they are plain identifiers (`name`, `$gt`) and quoted otherwise (`"address.city"`). If you already typed an opening quote, the item replaces from the quote and is quoted; an auto-closed quote after the cursor is replaced too.
- At the start of a statement, `db` and the shell helpers (`ObjectId`, `ISODate`, ...) complete.

Query bar (`kind = mongo_query`): the same key and operator analysis on EJSON text, with the collection from the request. Keys and operators are always inserted quoted. The request does not say whether the input is a filter, a sort or a projection, so the root object is treated as a filter.

Method, cursor-method and operator lists are written by hand from the MongoDB manual (`core/internal/completion/mongo_tables.go`).

### Catalog
- Core warms a catalog in the background when a session opens: one `ListObjects` and one bulk column query per schema (`engine.ColumnLister`, capability `completion`).
- `Complete` never waits for it. `catalog_state` is `COLD`, `WARMING` or `READY`; tables appear before columns.
- `WarmCatalog` streams progress for the "loading columns…" hint.
- The catalog is dropped when the schema cache is invalidated (refresh, designer, index changes, session close) and after `CREATE`/`ALTER`/`DROP`/`RENAME` run from the editor.

### Seeds and benchmarks
- `docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed` loads schema `large`: 500 tables, about 7,500 columns, 480 foreign keys.
- `cd core && go test -run xxx -bench Complete -benchmem ./internal/completion/`
- `cd core && go test -tags=integration -run TestIntegrationLargeSchema -v ./internal/completion/`
- Results are in `docs/perf/iteration-8.md`.

### Formatting
`FormatSQL` formats the whole text or a UTF-16 range of it with the dialect of the session (or `dialect` when no session is given: `postgres`, `mysql`, `mssql`, `sqlite` and their wire-compatible names).

Options: keyword case (upper by default, lower, preserve), indent width (default 2, 1 to 8), comma style (trailing by default, leading) and maximum line width (default 100, 40 to 400).

Layout:
- Each clause starts a line: `SELECT`, `FROM`, joins with their `ON`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`, `OFFSET`, set operations, `VALUES`, `SET`, `RETURNING`, `ON CONFLICT`, `ON DUPLICATE KEY UPDATE`, `OUTPUT`.
- A clause stays on one line when it fits the line width. Otherwise lists break one item per line, and `WHERE`, `HAVING` and `ON` break before `AND` and `OR`.
- Parenthesised groups stay inline when they fit. Subqueries that do not fit open on the same line, indent their clauses and close on a line of their own.
- Spacing is normalised around operators, commas and dots. Casts (`::`), JSON arrows, parameters (`$1`, `:name`, `@name`, `?`) and array subscripts keep their shape.

What it touches:
- Only whitespace and the case of keywords. Identifiers, quoted names, strings, dollar-quoted bodies and comments are never changed; comments keep their position relative to the tokens they follow.
- Only plain `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `VALUES` and `WITH` statements (and `REPLACE` on MySQL and SQLite). Everything else, such as DDL, `MERGE`, `PRAGMA` and procedure bodies, is returned unchanged, as is anything with unbalanced parentheses. Text between statements (separators, blank lines, comments) is kept.
- Every statement is checked after formatting: the token sequence must match except for keyword case, and formatting the result again must give the same text. If either check fails the original text is returned.
- Text with an unterminated string, quoted identifier or block comment is an `INVALID` error whose `position` points at the start of the unterminated token.

Tests: `core/internal/format/testdata/*.in` hold at least 40 statements per dialect (a shared set plus dialect-specific ones); `*.golden` hold the expected output. After an intended layout change run `cd core && go test ./internal/format -run TestGoldenCorpus -update` and review the diff. `FuzzFormat` checks the two invariants on random input.
