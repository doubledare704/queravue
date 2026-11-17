# ADR 0021 — Visual query builders

**Status:** Proposed · 2026-11-17

## Context
Iteration 11 adds three builders: a Mongo aggregation pipeline builder, a Mongo filter/projection/sort builder and a SQL query builder (tables, joins, filters). Each must round-trip with code for typical queries. Related: ADR 0003 (capabilities), ADR 0007 (schema model), ADR 0008 (dialect layer), ADR 0009 (document model), ADR 0010 (shell cursors), ADR 0013 (confirmation).

## Decision

### 1. The model is the source of truth, code is a projection
Each builder edits a typed model held in the app. Code is generated from the model. Code is parsed back into the model only for a supported subset. The UI never builds query text itself.

| Builder | Model | Code form |
|---|---|---|
| Pipeline | ordered list of stages: operator, EJSON body, enabled flag | EJSON array of single-key documents |
| Mongo filter | condition tree (and, or, nor, not, field + operator + value), projection list, sort list | EJSON filter, projection and sort documents |
| SQL | tables with aliases, joins, select list with aggregates, where/having trees, group by, order by, limit | one `SELECT` statement |

### 2. Generation and parsing live in core
A new `QueryBuilderService` in `querybuilder.proto`, backed by `core/internal/querybuilder`:
- `GenerateSql(SqlQueryModel) → sql` uses the session's dialect (ADR 0008): quoting, qualification, placeholders and pagination. Values become literals through `FormatLiteral`, so the text can be shown and executed.
- `ParseSql(sql) → SqlQueryModel`.
- `GenerateMongoQuery(MongoFindModel)` and `ParseMongoQuery(filter, projection, sort)`.
- Pipelines need no RPC. The model is the stage array, so the app converts it to and from EJSON directly.

The UI enables a builder from capabilities (`sql` for the SQL builder, `document_store` for the Mongo builders), never from engine ids (ADR 0003).

### 3. Round-trip contract
- **Builder → code always succeeds** for every model the UI can produce.
- **Code → builder** succeeds for the supported subset and otherwise returns `UNSUPPORTED_CONSTRUCT` with the offending position. The UI then keeps the text in the editor and says the query cannot be shown visually. It never guesses.
- Supported SQL: single `SELECT`, inner/left/right/full joins with equality or compound `ON`, column and aggregate select list with aliases, `WHERE`/`HAVING` trees over comparison, `IN`, `BETWEEN`, `LIKE`, `IS NULL`, `GROUP BY`, `ORDER BY`, `LIMIT`/`OFFSET`. Out of scope: subqueries, CTEs, window functions, set operations, vendor hints.
- Supported Mongo filter: `$and`, `$or`, `$nor`, `$not`, comparison, `$in`, `$nin`, `$exists`, `$regex`, `$type`. Other operators are kept as raw EJSON leaves so they survive and stay editable as text.
- Supported pipeline stages: every stage is a card. Stages with a typed form: `$match`, `$group`, `$project`, `$sort`, `$limit`, `$skip`, `$unwind`, `$lookup`, `$addFields`, `$count`. All others use a raw EJSON card, so any pipeline loads.
- Round-trip means the normalized model survives `parse(generate(m)) == m`, and the generated text of a parsed query is semantically equal to the original. Formatting and comments are not preserved, and the UI warns when comments are dropped.

### 4. SQL parser
A hand-written recursive-descent parser over the `sqlsplit` lexers (ADR 0008), restricted to the subset above. Rejected: `pg_query_go` (cgo, forbidden by AGENTS.md outside DuckDB), a MySQL-only parser library (one dialect), and a Dart parser (no mature option, and the dialect layer is in Go).

### 5. Preview
- **Pipeline:** per-stage preview runs the enabled stages up to the selected card plus `$limit` (default 20) through the existing `ShellService` `AGGREGATE` cursor (ADR 0010). No new execution path.
- **SQL and Mongo filter:** preview runs the generated query through the normal editor session and streaming grid with a row cap, and is cancellable.
- `$out` and `$merge` are never run by preview. Running them in full follows ADR 0013 (`CONFIRMATION_REQUIRED`).
- The SQL builder only produces `SELECT`; writes stay in the editor and table designer.

### 6. Suggestions
Join suggestions come from foreign keys in the schema model (ADR 0007). Mongo field and operator suggestions come from `SampleFieldPaths` (ADR 0009), including the `$lookup` target collection.

## Consequences
- The proto change is additive; protocol version 11. Field numbers are fixed once released; new stage types and operators add enum values or use the raw EJSON leaf.
- Per-dialect SQL output comes free from ADR 0008. A new SQL engine needs no builder work.
- The supported-subset list is the contract the round-trip corpus tests pin down. Extending it adds corpus cases, not new RPCs.
- Visual joins across multiple connections, subqueries and CTEs are out of scope.
- Rollout: this ADR and the proto land first, then the SQL, Mongo pipeline and Mongo filter builders can be built in parallel.
