# Schema diagrams

Status: the read-only diagram works for SQL engines. Export, saved diagrams, design mode and the Mongo diagram are not built yet; `PreviewDiagramDDL` / `ApplyDiagramDDL` still answer UNSUPPORTED. This page fills in as the Iteration 9 PRs land.

## Using the diagram
- Open it from the schema tree (right-click a schema, "Open diagram"), from the palette ("Open schema diagram") or with `⌘⇧D`. The palette and the shortcut use the schema of the active tab, or the connection's default schema. One diagram tab per schema.
- A table shows its columns with their types (`?` marks a nullable one), `PK` and `FK` tags, and at most 24 rows; views have a differently coloured header.
- A relation runs from the referencing column, where it ends in a fork, to the referenced column, where it ends in a dot.
- Drag the background or scroll to pan. Scroll with `Ctrl` or `⌘`, pinch, or press `+` and `-` to zoom; `0` or the fit button shows everything.
- Drag a table to move it. Click a table to select it: its relations are highlighted and the others fade. Double-click opens the table.
- "Arrange automatically" puts every table back where the layout places it; "Reload" reads the schema again.
- Zoomed out below 50 % a table shows only its name, below 16 % only its box, and relations become straight lines.
- Loading shows the table count and can be cancelled.

## How it is drawn
- Layout (`app/lib/features/diagram/domain/diagram_layout.dart`): a table goes to the right of every table it references (rank = longest chain of references; a reference that closes a cycle is ignored). Inside a rank, tables sit next to the tables they reference. A rank with many tables is split into columns of even height, sized so the whole diagram is about as wide as a window. Tables without relations form a block at the end. It runs on the UI thread: 500 tables take under 2 ms.
- Box sizes come from text lengths, so nothing is measured during layout.
- Painting (`diagram_painter.dart`): one canvas; only tables and relations that touch the viewport are drawn, and laid-out texts are cached between frames.
- Positions live in the tab and are lost when it closes, until saved diagrams land.

## Limits
- In a schema where a few tables are referenced by hundreds, relations are long and cross behind other tables; selecting a table is the way to follow its relations.
- A relation to a table in another schema is not drawn.

## What is still to come
- **ER diagram of a schema:** tables with their columns and keys, foreign keys as lines, laid out automatically; pan, zoom, drag tables, hide tables.
- **Export:** the whole diagram as SVG or PNG.
- **Saved diagrams:** `.queravue/diagrams/<name>.json` in the workspace keeps positions and hidden tables, not a copy of the schema.
- **Design mode:** draw tables and relations, review the generated DDL, apply it. The same confirmation rules as the table designer apply.
- **Mongo:** collections with their sampled fields; references between collections are guesses and are drawn as such.

## Contract
`proto/queravue/v1/diagram.proto`:
- `GetSchemaGraph` streams the tables of a schema in batches, each with columns and relations, and progress counters.
- `PreviewDiagramDDL` and `ApplyDiagramDDL` take `SchemaChange` steps for several tables; the core orders the statements.

The app enables diagrams from the `schema_graph` capability.

## How the graph is loaded
- Three queries per schema, whatever its size: the object list (`ListObjects`), every column with nullability and primary-key position (`ListKeyedColumns`), and every foreign key (`ListRelations`). The last two are the `RelationLister` interface in `core/internal/engine/graph.go`.
- PostgreSQL, CockroachDB, MySQL, MariaDB, TiDB, SQL Server and SQLite implement it and report `schema_graph`. MongoDB does not yet.
- The load waits for a running statement on the session to finish, and stops when the call is cancelled.
- A loaded graph is kept per session, database and schema until the session's schema cache is invalidated (DDL from the editor or the designer, a refresh, the session closing). `refresh = true` reloads it.
- Tables are streamed 50 per message. A table keeps at most 200 columns; `columns_truncated` says when more exist.
- SQLite foreign keys have no names; they get `fk_<table>_<n>`, as in table details. A reference without a column list is resolved to the referenced table's primary key.

Design and budgets: ADR 0017.
