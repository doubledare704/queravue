# Schema diagrams

Status: the core serves the schema graph for SQL engines (`GetSchemaGraph`). The app has no diagram view yet, and `PreviewDiagramDDL` / `ApplyDiagramDDL` still answer UNSUPPORTED. This page fills in as the Iteration 9 PRs land.

## What it will do
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
