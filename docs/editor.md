# Editor

Design decisions are in [ADR 0015](adr/0015-completion-and-formatting.md); this page describes behaviour as it ships.

## Completion & formatting

Status: SQL completion (PR 2), the SQL formatter and Mongo completion (PR 3) are done in core. The completion popup, snippets and the format shortcut (PR 4) are done in the app. The action registry and palette (PR 5) and the split layout (PR 6) are done; tab dragging, maximize and resizable panes came in a follow-up.

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

### Completion in the app
Where it works: the SQL editor, the Mongo shell editor and the three Mongo query bar fields (filter, sort, projection). A connection must declare `completion` (SQL), `shell` (shell) or `document_store` (query bar); otherwise the editor never asks.

How a keystroke becomes a popup (`app/lib/features/completion/`):
- Every edit asks the core in the background and cancels the previous question (`CompletionEngine`). The request carries only the statement around the caret for SQL (split on semicolons outside quotes and comments), or the text around the caret for the shell, never the whole file.
- `suggest` is synchronous. While the typed text extends the identifier the last answer was asked for, it filters and re-ranks that answer locally with the core's rules, so the popup does not wait for the network. The answer for the context a keystroke opens (a space after `FROM`, a dot) was asked for by the keystroke before it. Local filtering is skipped when the text before the identifier changed, the identifier got shorter (backspace), or the statement changed; the popup then appears with the next keystroke.
- A newer answer refreshes a popup that is already open, so an incomplete first answer is replaced by the exact one a few milliseconds later.
- The ranking rules exist twice, in `core/internal/completion/match.go` and `app/lib/features/completion/domain/local_filter.dart`. `core/internal/completion/testdata/match_cases.json` holds the shared cases; `go test ./internal/completion -update-match` rewrites it, and `app/test/features/completion/match_golden_test.dart` checks the Dart side.
- Keys: ↑ ↓ choose, Enter or Tab accept, Esc closes, a click accepts. In the query bar the popup opens under the field.
- While the catalog loads, the popup says "loading columns…".

re_editor opened its popup 50 ms after the keystroke, which is the whole budget, and only after a frame had laid the text out. The app vendors re_editor 0.10.0 (`app/third_party/re_editor/`, see `QUERAVUE.md` there) with the popup opening after the frame that laid the typed text out.

### Snippets
- Built in per context (`app/lib/features/completion/domain/snippets.dart`): `sel`, `selw`, `selc`, `ins`, `upd`, `del`, `cte`, `join` for SQL; `find`, `agg`, `upd1`, `ins1` for the shell.
- Your own snippets live in `.queravue/snippets.json` in the first workspace folder, read through the workspace service. Edit the file in any editor; it is read once per app run.

```json
[
  {
    "trigger": "ord",
    "body": "SELECT * FROM orders WHERE $0",
    "description": "orders filter",
    "contexts": ["sql"]
  }
]
```

`contexts` is optional (all contexts) and may hold `sql`, `shell` and `mongo_query`. `$0` marks the caret; the editor can only put it on the line where the snippet starts, so a `$0` on a later line puts the caret at the end of the first line. Entries without `trigger` or `body` are skipped.
- A snippet is offered when the typed text is a prefix of its trigger, above the server's items, and never right after a dot.

### Formatting in the app
Shift+Alt+F (palette: "Format SQL") formats the selection, or the statement at the caret, through `FormatSQL` with the session's dialect. Failures leave the text as it was: an unterminated string moves the caret to it and shows the message; a text that changed while the core was formatting is not overwritten. The connection must declare `format`.

## Actions, palette and shortcuts

### One registry
`app/lib/shared/actions/` holds `AppAction` (id, title, category, default chord, enabled-when, run). `enabledWhen` reads providers through a `watch` function; an action that is not enabled is greyed out in the palette and the menu bar, sorts after the enabled ones, and its shortcut does nothing (the key is still consumed). `builtinActionsProvider` lists every action of the app. The command palette, the keyboard shortcuts and the macOS menu bar are all built from that list through `actionRegistryProvider`, so an action added there appears in all three.

A chord is stored platform independent: `primary` is Cmd on macOS and Ctrl elsewhere (`primary+shift+enter`, `alt+shift+f`, `escape`). The palette shows it in the platform's own notation (`⌥⇧F`, `Ctrl+Alt+Shift+F`).

The menu bar items have no key equivalent on purpose: a native one is handled before Flutter sees the key and would take Enter and Escape from the editors. Shortcuts stay with Flutter.

### Palette
- No prefix: actions, open tabs, connections and workspace files (file names; searched through the core after two characters).
- `>` actions only, `@` tables and collections the schema tree has loaded for the selected connection, `#` workspace files (searched from the first character), `:` open tabs.
- Ranking: prefix of the title, then a word start, then a substring, then a subsequence; ties keep the order actions, tabs, connections, objects, files.
- "Go to tab" and "Go to database object" open the palette with `:` and `@`.

### Keybindings
- User chords live in `.queravue/keybindings.json` in the first workspace root: `{"editor.new": "primary+j", "editor.cancel": null}`. `null` removes the shortcut. Bad entries and unknown action ids are skipped and listed in the shortcuts dialog, never fatal.
- Two actions on one chord is a conflict: neither fires, the palette marks both and the shortcuts dialog (palette: "Keyboard shortcuts") lists them, so one of them can be changed.
- The dialog changes a shortcut by capturing the next key combination, clears it, or restores the default; changes are written to the file.

## Editor groups and layout

- Tab context menu (right-click) and the palette: split right, split down, move tab to next group; focus next and previous group. Defaults: `⌘\`, `⌘⇧\`, `⌘⌥→`, `⌘⌥←`, `⌘⌥⇧→`. `⌘1` to `⌘4` focus a group by position. Click a group to focus it; the focused group has a coloured top edge when the editor is split.
- Drag a tab to move it: dropped on another tab it lands in front of that tab (this also reorders tabs inside a group), dropped anywhere else on a group it joins the end of that group. The target is outlined while the tab is over it.
- Drag the divider between groups to resize; groups never get smaller than 18 % of the pane, and there are at most four.
- Closing or dragging away the last tab of a group removes the group.
- Maximize (`⌘⇧M`, or the button at the right of a group's tab bar): the focused group fills the window, the sidebar and the other groups are hidden and keep their state; the same shortcut restores them. This stands in for detached windows (ADR 0016).
- Sidebar: drag its right edge to resize (180 to 520 px), `⌘B` or a double-click on the edge hides it.
- Results and shell output: drag the bar under the editor to resize, `⌘J` or a double-click on the bar hides the pane, a click on the bar brings it back. The share is the same for every tab.
- Layout, open query and shell tabs, unsaved text and the pane sizes are saved to `.queravue/layout.json` in the first workspace root and restored on start; tabs bound to a file load it when first shown. Maximize is not saved. Keep the file out of version control. Table, collection and designer tabs are not restored.
- Design, limits and the detached-window decision: ADR 0016.

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
