# Editor

Design decisions are in [ADR 0015](adr/0015-completion-and-formatting.md); this page describes behaviour as it ships.

## Completion & formatting

Status: SQL completion in core is done (Iteration 8, PR 2). Mongo completion and the formatter land in PR 3, the UI in PR 4.

### SQL completion
- `CompletionService.Complete` takes the current statement and a UTF-16 cursor offset and returns items in ranked order. Sort by `sort_key` ascending to get the same order.
- Context kinds: `sql` works. `shell` and `mongo_query` answer `UNSUPPORTED` until PR 3.
- Ranking tiers: in-scope aliases and tables, then columns of in-scope tables, then other schema objects, then keywords and functions. Inside a tier: prefix, word start or word initials (`oi` finds `order_items`), substring, then subsequence; then recently used names; then alphabetical.
- Clauses understood: select list, `FROM`/`JOIN`, `ON`/`USING`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `INSERT` column list, `UPDATE ... SET`, `RETURNING`, after `schema.` and `alias.`.
- Aliases with or without `AS`, CTEs (explicit column lists, or derived from the select list), subquery aliases (`*` expands from the inner tables), quoted identifiers per dialect, correlated outer queries, `UNION` branches.
- Inside string literals and comments nothing completes. On SQL that does not parse, the answer is keywords plus all tables.
- Insert text is quoted with the dialect's quotes only when needed (reserved word, characters outside `[A-Za-z0-9_]`, upper case in PostgreSQL). If the user already typed an opening quote, the item replaces from the quote and is quoted.
- Keyword and function lists per dialect are in `core/internal/completion/keywords.go`.

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
- `FormatSQL` formats a selection or statement; options are keyword case, indent width, comma style and max line width. Not available yet (PR 3).
