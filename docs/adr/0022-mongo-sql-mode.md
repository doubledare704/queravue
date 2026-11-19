# ADR 0022 — SQL mode for MongoDB

**Status:** Proposed · 2026-11-19

## Context
Iteration 12 adds SQL mode: the user writes a `SELECT` against a Mongo connection, sees the generated MQL and runs it. The roadmap exit criterion is a translator that passes a corpus of 100+ queries. Related: ADR 0003 (capabilities), ADR 0008 (dialect layer and `sqlsplit`), ADR 0009 (document model, EJSON), ADR 0010 (shell cursors), ADR 0021 (builders, parse subset and error rules).

## Decision

### 1. Translation lives in core, with its own AST
A new package `core/internal/mongosql`, pure and without I/O. It reuses the `sqlsplit` lexer through a new `mongosql` lexer flavour and follows the structure of the querybuilder parser (ADR 0021 §4), but builds its own small AST instead of `SqlQueryModel`. SQL mode needs constructs the builder model deliberately leaves out (`NOT`, arithmetic, `COUNT(DISTINCT)`, typed literal functions), and the builder contract must not grow for them.

Rejected: translating in Dart (the lexers and dialect layer are Go), and an external SQL-to-MQL library (none is maintained, pure Go and permissively licensed).

### 2. Accepted dialect
- Keywords are case-insensitive, field names case-sensitive.
- Identifiers are bare, `"quoted"` or `` `quoted` ``.
- A dotted name is a field path. Its first segment is a qualifier only when it matches a `FROM` or `JOIN` alias or collection name; otherwise the whole name is a path (`address.city`).
- Typed literals: `OBJECTID('…')`, `DATE '…'`, `TIMESTAMP '…'`, `NUMBERLONG(…)`, `NUMBERDECIMAL('…')`. Bare numbers follow ADR 0009's relaxed rule (integer → Int32 if it fits, else Int64; decimal → Double).
- No parameter placeholders.

### 3. Supported subset
- `SELECT [DISTINCT]` with `*`, fields, aliases, and the aggregates `COUNT(*)`, `COUNT(f)`, `COUNT(DISTINCT f)`, `SUM`, `AVG`, `MIN`, `MAX`.
- `FROM coll [alias]`, `[INNER|LEFT] JOIN coll [alias] ON a.f = b.g [AND …]`.
- `WHERE` and `HAVING` with `AND`, `OR`, `NOT`, comparisons, `IN`, `NOT IN`, `BETWEEN`, `LIKE`, `ILIKE`, `NOT LIKE`, `IS [NOT] NULL`, and `+ - * /` on numbers.
- `GROUP BY` fields; `ORDER BY` fields, aliases or ordinals with `ASC`/`DESC`; `LIMIT`, `OFFSET`, `LIMIT n, m`.

Everything else (`RIGHT`/`FULL` joins, subqueries, CTEs, `UNION`, window functions, `INSERT`/`UPDATE`/`DELETE`, DDL) fails with `UNSUPPORTED_CONSTRUCT` and the offset of the construct. SQL mode is read-only. As in ADR 0021 §3, the translator never guesses.

### 4. Output shape
The simplest correct form:
- **FIND** (filter, projection, sort, skip, limit) when there is no join, group, aggregate, `DISTINCT` or computed column.
- **AGGREGATE** (a pipeline) otherwise.

Both come back as canonical EJSON and as shell code (`db.getSiblingDB("shop").orders.find(…)` / `.aggregate([…])`).

### 5. Joins
An equality `ON` becomes `$lookup` with `localField`/`foreignField`, then `$unwind` (`preserveNullAndEmptyArrays: true` for `LEFT`). A compound `ON` becomes `$lookup` with `let` and a `pipeline` of `$match: {$expr: …}`; the result carries a warning, because older DocumentDB and Cosmos DB servers reject that form.

### 6. Semantics are shown, not hidden
Where SQL and MQL differ, the translator produces the natural MQL and attaches a warning when the query touches the difference. Each case has a corpus entry and is listed in `docs/engines/mongodb.md`:
- `IS NULL` also matches a missing field.
- `=` on an array field matches any element.
- Comparisons do not cross BSON type brackets (`age > 30` skips `"40"`).
- `LIKE` becomes an anchored, escaped `$regex`; `ILIKE` adds the `i` option.
- `COUNT(f)` counts documents where `f` is neither null nor missing.
- `ORDER BY` sorts null and missing first.

### 7. Execution: no new path
The app runs the generated shell code in a shell (ADR 0010), opens the cursor handle in the document views and pages it with `Find` or `FetchCursor`. Preview uses the capped preview of ADR 0021 §5. "Open in pipeline builder" passes the pipeline to the builder's import.

### 8. Contract and gating
One additive RPC on `QueryBuilderService`: `TranslateMongoSql(session_id, database, sql)` returns the collection, the kind (`FIND` or `AGGREGATE`), the find documents or the pipeline, shell code, warnings and a `QueryBuilderError` (`PARSE` or `UNSUPPORTED_CONSTRUCT`, offsets in UTF-8 bytes like the rest of the service). The session only resolves the default database. The UI offers SQL mode when the connection has `document_store` and `shell`; there is no new capability and nothing reads the engine id.

## Consequences
- Protocol version 12 (shared with ADR 0023).
- The supported subset is the contract the corpus pins down: growing it adds corpus cases, not RPCs.
- A differential test runs comparable corpus queries on Mongo and on SQLite and compares the results.
- The SQL builder (ADR 0021) could later target Mongo through this translator; not in scope.
