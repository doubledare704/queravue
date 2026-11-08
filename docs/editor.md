# Editor

Design decisions are in [ADR 0015](adr/0015-completion-and-formatting.md); this page describes behaviour as it ships.

## Completion & formatting

Status: SQL completion in core (PR 2) and the SQL formatter (PR 3) are done. Mongo completion lands in the rest of PR 3, the UI in PR 4.

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
