# Schema diagrams

Status: contract only. ADR 0017 and `DiagramService` exist; the core answers every call with UNSUPPORTED and the app has no diagram view yet. This page fills in as the Iteration 9 PRs land.

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

Design and budgets: ADR 0017.
