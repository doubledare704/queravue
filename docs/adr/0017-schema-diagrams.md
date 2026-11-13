# ADR 0017 — Schema diagrams and design mode

**Status:** Accepted · 2026-11-10

## Context
Iteration 9 adds an ER diagram generated from a schema (auto-layout, zoom, SVG and PNG export), a design mode that turns drawn tables and relations into DDL, and a diagram of a Mongo database inferred from sampling. It is done when a 100-table schema renders readably and a designed diagram creates real tables.

What exists:
- `SchemaInspector.DescribeTable` returns columns, indexes and foreign keys for one table per call (ADR 0007). A 500-table diagram would need 500 calls.
- `ColumnLister.ListColumns` lists a schema's columns in one query (ADR 0015) but has no key or nullability flags and no foreign keys.
- `SchemaDesignService` turns `SchemaChange` steps into DDL for one table per request (ADR 0013).
- `DocumentService.SampleFieldPaths` samples nested field paths with types and frequency (ADR 0015 §4).
- `WorkspaceService` reads and writes files under `.queravue/` (ADR 0011).
- `dev/seed/postgres/large` has 500 tables and 480 foreign keys.

## Decision

### 1. The graph comes from core in bulk, as a stream
A new optional Conn interface, `RelationLister`, lists the foreign keys and key columns of a whole schema with one query per kind of object. Its capability is `schema_graph`. `DiagramService.GetSchemaGraph` joins that with the object and column lists and streams `GraphTable` batches with progress counters; the last message has `done`. The UI never makes per-table calls to draw a diagram. The stream is cancellable and the result is cached under the ADR 0007 rules, with `refresh` to bypass.

One diagram is one schema. A foreign key into another schema keeps its `referenced_schema` (empty means the same schema), and the UI draws the target as a stub with only the referenced columns, which opens that schema's own diagram; the other schema is never loaded.

### 2. Layout runs in the UI and is written here
Positions are view state: the user drags tables, hides some, and saves the arrangement. A layered layout (rank by reference depth, order within a rank to reduce crossings, then assign coordinates) is written in Dart with no new dependency. It was planned to run off the UI thread for large graphs; measured at under 2 ms for 500 tables, it runs on it.

Not chosen:
- Layout in core. It keeps Dart thin, but every re-layout and drag-to-settle would be an RPC, and core would hold view state.
- A graph-layout package. It adds a dependency for a few hundred lines, and painting with culling needs our own scene model anyway.

Nothing is copied from another tool.

### 3. One painted canvas
The diagram is one custom-painted scene under a pan and zoom transform, not a widget per table. Only tables that intersect the viewport are painted. Below a zoom threshold a table collapses to its title box, and below a second one relations are drawn as straight lines. This keeps the rule that nothing off-screen builds widgets.

### 4. Export from the same scene
SVG is written by a small serializer over the scene model; PNG is the scene rasterised at a chosen scale. Both export the whole diagram, not the viewport, in the light theme. The PNG scale is two pixels per unit, lowered to stay under 24 megapixels and 16,384 px a side; the SVG estimates text widths rather than measuring them. Files are saved through `file_selector`, which the app already depends on.

### 5. Saved diagrams are workspace files
A diagram is saved as `.queravue/diagrams/<name>.json` through `WorkspaceService`: connection id, database, schema, table positions, hidden tables and, in design mode, the draft objects. It holds no schema snapshot; opening it loads the graph again and places known tables. Persistence needs no contract change.

### 6. Design mode reuses `SchemaChange`
The UI keeps sending structured changes and never builds DDL text (ADR 0013 §1). `PreviewDiagramDDL` and `ApplyDiagramDDL` accept changes for several tables at once. Core orders the statements: tables are created without their foreign keys first, then the foreign keys are added, so forward references and cycles work. The responses reuse `DdlStatement` and report whether the run is one transaction. Confirmation for destructive statements and for connections flagged production follows ADR 0013: the review dialog is the confirmation, as in the table designer.

SQLite cannot add a foreign key to an existing table but does not check the referenced table at `CREATE TABLE`, so there foreign keys stay inline and created tables are ordered so each follows those it references. Relations drawn on the diagram reference a one-column primary key; composite references stay with the table designer.

### 7. Mongo relations are inferred and say so
On document stores `GetSchemaGraph` samples each collection (bounded by `sample_size`, cancellable, with progress) and reports field paths as columns. A relation is suggested when a field's name and sampled type point at another collection's `_id`. Such a relation has `inferred = true` and a confidence, and the UI draws it differently and can hide it. No constraint is claimed.

As built (PR 6): the inference runs in core (`internal/diagram`), not in the Mongo engine, from `ListObjects` and `DocumentStore.SampleFieldPaths`; the engine stays a data source. `schema_graph` is therefore backed by `RelationLister` or by `DocumentStore`, recorded in `engine.CapabilityAlternatives`. Progress is coarser than first planned: a relation needs the `_id` type of the collection it points at, so every collection is sampled before the first table is sent, and the UI shows an indeterminate bar until then. Keeping `tables_done` meaning "tables sent" avoided a contract change. The naming and type rules and their confidences are in `docs/diagrams.md`.

### 8. Contract
`proto/queravue/v1/diagram.proto` adds `DiagramService` with `GetSchemaGraph` (server stream), `PreviewDiagramDDL` and `ApplyDiagramDDL`. It is additive; protocol version 9.

### 9. Budgets
- Graph load for 500 tables: 200 ms p95 in core, measured on the large PostgreSQL seed.
- Layout of 100 tables: 100 ms.
- A 500-table diagram open: inside the 150 MB idle budget.
- Pan and zoom: no frame over 16 ms in steady movement on 500 tables.

## Consequences
- Each SQL engine gains one bulk query for foreign keys and one for key columns; engines without them do not report `schema_graph` and the UI hides the diagram.
- Bulk foreign-key queries may be slower on TiDB and CockroachDB than on PostgreSQL. Only PostgreSQL has a 500-table seed, so the others are measured on the standard seed.
- A hand-written layout will be plainer than a specialised library's; the manual arrangement is saved, so it only has to be a good start.
- Inferred relations are heuristics and will include wrong edges. They are always marked.
- Multi-table apply on engines that commit DDL implicitly can stop half way; the response says how many statements ran, as `ApplyDDL` does.
