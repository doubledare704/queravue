# Schema diagrams

Status: the diagram, export, saved diagrams and design mode work for SQL engines; MongoDB, DocumentDB and Cosmos DB get a diagram inferred from sampled documents (Iteration 9).

## Using the diagram
- Open it from the schema tree (right-click a schema, "Open diagram"), from the palette ("Open schema diagram") or with `⌘⇧D`. The palette and the shortcut use the schema of the active tab, or the connection's default schema. One diagram tab per schema.
- A table shows its columns with their types (`?` marks a nullable one), `PK` and `FK` tags, and at most 24 rows; views have a differently coloured header.
- A relation runs from the referencing column, where it ends in a fork, to the referenced column, where it ends in a dot.
- Drag the background or scroll to pan. Scroll with `Ctrl` or `⌘`, pinch, or press `+` and `-` to zoom; `0` or the fit button shows everything.
- Drag a table to move it. Click a table to select it: its relations are highlighted and the others fade. Double-click opens the table.
- "Arrange automatically" puts every table back where the layout places it; "Reload" reads the schema again.
- Zoomed out below 50 % a table shows only its name, below 16 % only its box, and relations become straight lines.
- A table of another schema that this one references appears as a small grey box with a dashed outline, titled `schema.table` and listing only the referenced columns; the rest of that table is not loaded. It is laid out, moved, hidden and saved (under `schema.table`) like the others. Double-click it, or right-click "Open the … diagram", to open that schema's diagram. The summary counts these relations ("k to other schemas"). It is never a relation target in design mode.
- Right-click a table to open it or hide it from the diagram. "Show n hidden" in the toolbar, or the palette entry "Show hidden tables", brings them back where they were; a table whose spot was taken meanwhile goes beside the diagram.

## Saving
- `⌘S` on a diagram tab saves it to `.queravue/diagrams/<name>.json` in the first workspace root, asking for a name the first time; `⌘⇧S` saves under a new name. A name that is taken asks before replacing the file. The tab takes the name; the toolbar shows it, with "changed" after a table moved or was hidden. Unsaved diagrams show "not saved".
- The file keeps the connection (id and name), database, schema, the top-left corner of every table and the hidden tables, one table per line and sorted, so it diffs well in Git. It does not copy the schema. A draft is kept under `draft`, one drafted table or relation per line.
- Opening a saved diagram (palette "Open saved diagram…", or the file from the workspace tree) reads the schema again: known tables go where they were saved, tables added since are laid out beside them, dropped tables are left out. The connection is found by id, else by name, so a diagram works on another machine with a connection of the same name.
- A diagram tab, saved or not, comes back after a restart, and loads when it is first shown. A saved diagram whose file is gone or broken opens with the automatic layout and says so in the toolbar.
- Unsaved moves are lost when the tab closes or the app quits; nothing asks first.
- "Reload" keeps the current arrangement and reads only the schema again.

## Design mode
Draw new tables and relations on the diagram, review the DDL, apply it. Available when the connection draws diagrams and runs SQL (`schema_graph` and `execute` capabilities).
- **New table:** the toolbar button, the palette entry "New table on the diagram" or `⌘⌥T`; on an empty schema, the button in the middle. A dialog asks for the name and the columns (name, type, default, nullable, primary key, auto-increment), starting with `id integer` as the key. The table appears near the middle of the view, where it covers nothing, with a dashed outline and a differently coloured header.
- **Relation:** right-click a table, "Add relation…", pick the referenced table and what happens on delete. The relation points at the referenced table's primary key through a column named `<table>_<key>`: reused when the table has it, added otherwise, with the key's type (`serial` becomes `integer`). Only tables with a one-column primary key can be referenced here; composite references go through the table designer. A relation can start at a drafted table or an existing one; on an existing table it adds the column and the foreign key.
- Drafted columns and relations are drawn in the primary colour, relations dashed.
- **Edit:** double-click a drafted table, or right-click it for "Edit table…", "Remove drafted table" and "Remove relation to …". Renaming a drafted table carries its relations along.
- **Review:** "Review n changes" in the toolbar (or the palette entry "Review and apply diagram changes") shows the statements the core will run, its warnings, and whether they run in one transaction. Apply runs them; the dialog is the confirmation for destructive statements and connections flagged production, as in the table designer. If a statement fails, the error shows and the draft stays.
- After an apply the draft is cleared and the schema read again; the new tables stay where they were drawn.
- "Discard" in the toolbar drops the whole draft after asking.
- The draft is saved with the diagram (see Saving) and survives "Reload". A drafted table that exists in the database by the time the diagram loads is dropped from the draft.

### How the statements are ordered
The core receives the changes per table and orders them (`core/internal/sqldialect/diagram_ddl.go`):
- New tables are created first, then the other changes, then every foreign key as `ALTER TABLE … ADD CONSTRAINT`. A table can reference one drafted after it, and two tables can reference each other.
- SQLite does not check the referenced table when a table is created, so there foreign keys stay inside `CREATE TABLE`, and created tables are ordered so a table follows those it references.
- A relation from an existing SQLite table usually adds its column: that is one `ALTER TABLE … ADD COLUMN … REFERENCES …`, which SQLite accepts when the column starts out NULL (a non-null or defaulted column is refused with the reason). A key on a column the table already has, or on several columns, rebuilds the table as for column alters (ADR 0014): it needs foreign keys not enforced on the connection, and existing rows are not checked against the new key; the review warns about both. The same applies in the table designer.
- PostgreSQL, SQL Server and SQLite run the script in one transaction. MySQL, MariaDB, TiDB and CockroachDB run the statements one at a time; the review says so, and after a failure the error says how many statements stay applied.

## Export
- `⌘⇧E` exports SVG, `⌘⌥⇧E` PNG; also in the toolbar's export menu and the palette. The file goes wherever the save dialog says, outside the workspace.
- Only the shown tables are exported, all of them, not just the part on screen, with every column and title regardless of zoom.
- Exports use the light theme, so they read well in documents and on paper.
- PNG is drawn at twice the screen size when that stays under 24 megapixels and 16,384 px a side, smaller when it does not; the message after an export says the size and the scale.
- SVG text widths are estimated, so long names and types are cut with `…` a little earlier than on screen. The font is the system sans-serif.
- Drafted tables are exported too. PNG draws them as on screen; SVG draws them like the other tables.
- Loading shows the table count and can be cancelled.

## How it is drawn
- Layout (`app/lib/features/diagram/domain/diagram_layout.dart`): a table goes to the right of every table it references (rank = longest chain of references; a reference that closes a cycle is ignored). Inside a rank, tables sit next to the tables they reference. A rank with many tables is split into columns of even height, sized so the whole diagram is about as wide as a window. Tables without relations form a block at the end. It runs on the UI thread: 500 tables take under 2 ms.
- Box sizes come from text lengths, so nothing is measured during layout.
- Painting (`diagram_painter.dart`): one canvas; only tables and relations that touch the viewport are drawn, and laid-out texts are cached between frames.
- Canvas, SVG and PNG share one geometry (`diagram_scene.dart`), so the files match what is on screen.

## Limits
- In a schema where a few tables are referenced by hundreds, relations are long and cross behind other tables; selecting a table is the way to follow its relations.

## Mongo: the inferred diagram
- Right-click a database in the schema tree, "Open diagram", or use the palette and `⌘⇧D`; without a database in the active tab the connection's default database is used.
- Each collection is a box with the field paths of a sample: `_id` first (marked `PK`), then by how many sampled documents have the field. A field missing from some documents, or holding `null`, is nullable (`?`). The type shown is the most frequent one other than `null`. Array elements use the segment `[]`, as in the field list (`items.[].sku`).
- There is no schema to read, so the relations are guesses, drawn dashed and fainter the less sure they are. The summary counts them ("n inferred"). "Hide inferred" in the toolbar, or the palette entry "Show or hide inferred relations", removes them from the view; the choice is saved with the diagram (`"hideInferred": true`).
- Design mode is not offered: Mongo connections have no `execute` capability.
- Each collection is sampled with `$sample` (100 documents by default, `sample_size` up to 1000), four at a time. Loading shows an indeterminate bar until every collection is sampled, because a relation needs the `_id` type of the collection it points at; the tables then stream as on SQL engines. Cancel stops the sampling. The seeded dev database (6 collections, one of 1M documents) loads in about 3 ms p50, 29 ms p95.

### How a relation is guessed
`core/internal/diagram/infer.go`. For every sampled field other than `_id`:
1. **The name it refers by.** An id suffix is cut: `customerId`, `customer_id`, `customerID`, `tagIds.[]` and `customer._id` refer by `customer`, `tag`. A field without such a suffix refers by its own name (`author`).
2. **The collection that name points at.** Case, `_` and `-` are ignored. The same name wins (`person` → `person`), then the one collection whose singular it is (`customer` → `customers`, `category` → `categories`, `box` → `boxes`); two collections with that singular match neither. Views are never targets. When nothing matches and the field had an id suffix, its last words are tried (`parent_category_id` → `categories`, `createdByUserId` → `users`).
3. **The types.** The field's type must equal the target's `_id` type when the target was sampled.

| Field | Target `_id` | Confidence |
|---|---|---|
| `objectId`, id suffix | `objectId` | 0.9 |
| `objectId`, no suffix (`author`) | `objectId` | 0.7 |
| another type, id suffix (`book_id` string) | same type | 0.6 |
| `objectId`, id suffix | unknown (empty collection) | 0.5 |
| matched only by its last words | | 0.2 less |
| type differs, or no suffix and not `objectId` | | no relation |

The guesses will include wrong edges (a `userId` that holds an external id) and miss references named unlike their collection. They are never offered as constraints.

## Contract
`proto/queravue/v1/diagram.proto`:
- `GetSchemaGraph` streams the tables of a schema in batches, each with columns and relations, and progress counters.
- `PreviewDiagramDDL` and `ApplyDiagramDDL` take `SchemaChange` steps for several tables, one entry per table; the core orders the statements as above. A table listed twice, an entry without changes and a change the engine cannot express are refused in band (INVALID or UNSUPPORTED). They share the planning, confirmation, history and cache invalidation of `SchemaDesignService`.

The app enables diagrams from the `schema_graph` capability. `GraphRelation.inferred` and `confidence` mark the guessed relations; `GetSchemaGraphRequest.sample_size` sets the sample on document stores.

## How the graph is loaded
- Three queries per schema, whatever its size: the object list (`ListObjects`), every column with nullability and primary-key position (`ListKeyedColumns`), and every foreign key (`ListRelations`). The last two are the `RelationLister` interface in `core/internal/engine/graph.go`.
- PostgreSQL, CockroachDB, MySQL, MariaDB, TiDB, SQL Server and SQLite implement it and report `schema_graph`.
- Document stores report `schema_graph` through `DocumentStore` instead: core lists the collections and samples them (see Mongo above). `engine.CapabilityAlternatives` records that a capability can come from either interface, and the registry tests check it with `engine.Provides`.
- The load waits for a running statement on the session to finish, and stops when the call is cancelled.
- A loaded graph is kept per session, database, schema and sample size until the session's schema cache is invalidated (DDL from the editor or the designer, a refresh, the session closing). `refresh = true` reloads it.
- Tables are streamed 50 per message. A table keeps at most 200 columns; `columns_truncated` says when more exist.
- `ListRelations` leaves `ReferencedSchema` empty when the referenced table is in the listed schema, and names the schema otherwise. The app matches targets by schema and name, so a same-named table in another schema is never drawn as the target.
- SQLite foreign keys have no names; they get `fk_<table>_<n>`, as in table details. A reference without a column list is resolved to the referenced table's primary key.

Design and budgets: ADR 0017.
