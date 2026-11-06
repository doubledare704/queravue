# ADR 0007 — Unified schema model and lazy introspection

**Status:** Accepted · 2026-11-05

## Context
Iteration 3 introduces the schema browser and table data view for PostgreSQL and SQLite. Looking ahead, Iteration 7 (index manager, stats, table designer, alter table preview) and Iteration 9 (ER diagrams, visual relational design, and inferred Mongo schemas) build directly upon the schema representation established here.

We need a schema abstraction that:
1. Conforms to the `engine.Conn` capability pattern (ADR 0003): engines declare `CapSchemaInspector` and optionally implement `SchemaInspector`.
2. Loads lazily in four distinct levels (`databases → schemas → objects [tables/views/matviews] → table details [columns, indexes, foreign keys]`) so opening a connection with thousands of tables remains instant (< 50 ms) without pulling megabytes of catalog metadata over the network.
3. Provides accurate, instant row-count estimates (e.g. `pg_class.reltuples` in PostgreSQL; none in SQLite) without running expensive `COUNT(*)` queries on multi-million row tables.
4. Determines table editability: tables without a primary key or a unique `NOT NULL` constraint cannot safely support single-row updates/deletes in an asynchronous virtualized window, and must be flagged read-only with a clear explanation.
5. Caches metadata per session with explicit `Refresh` invalidation.
6. Accommodates future relational engines (MySQL, SQL Server, Oracle, DuckDB) and NoSQL schemas (sampled document schemas in MongoDB) without breaking changes.

## Decision

### 1. Capability & Engine Interface
In `core/internal/engine`, declare `CapSchemaInspector Capability = "schema_inspector"` and the `SchemaInspector` interface:

```go
type ObjectType string

const (
    ObjectTypeTable            ObjectType = "table"
    ObjectTypeView             ObjectType = "view"
    ObjectTypeMaterializedView ObjectType = "materialized_view"
)

type SchemaObject struct {
    Name          string
    Type          ObjectType
    EstimatedRows int64 // -1 if unknown / unsupported
}

type ColumnDef struct {
    Name            string
    TypeName        string
    Kind            ValueKind
    Nullable        bool
    DefaultValue    *string
    IsPrimaryKey    bool
    PrimaryKeyOrder int // 1-based order for composite PKs; 0 if not PK
}

type IndexDef struct {
    Name      string
    Columns   []string
    IsUnique  bool
    IsPrimary bool
}

type ForeignKeyDef struct {
    Name              string
    Columns           []string
    ReferencedSchema  string
    ReferencedTable   string
    ReferencedColumns []string
}

type TableDetails struct {
    Database           string
    Schema             string
    Table              string
    Type               ObjectType
    Columns            []ColumnDef
    Indexes            []IndexDef
    ForeignKeys        []ForeignKeyDef
    EstimatedRows      int64
    CanEdit            bool
    EditDisabledReason string
}

type SchemaInspector interface {
    ListDatabases(ctx context.Context) ([]string, error)
    ListSchemas(ctx context.Context, database string) ([]string, error)
    ListObjects(ctx context.Context, database, schema string) ([]SchemaObject, error)
    DescribeTable(ctx context.Context, database, schema, table string) (TableDetails, error)
}
```

Caller discovery follows ADR 0003:
```go
if inspector, ok := engine.As[engine.SchemaInspector](conn); ok { ... }
```

### 2. Four-Level Lazy Loading
Introspection is partitioned into discrete RPCs:
1. `ListDatabases`: Lists accessible databases.
2. `ListSchemas`: Lists schemas inside a selected database (e.g., `public`, custom schemas in Postgres; `main` in SQLite).
3. `ListObjects`: Lists tables, views, and materialized views inside a schema along with their `ObjectType` and estimated row count.
4. `GetTableDetails`: Retrieves full column definitions, indexes, foreign keys, row estimates, and editability status for a single table.

This ensures UI latency stays strictly $O(1)$ relative to total schema size: expanding a node only inspects the immediate child level.

### 3. Editability Invariant
A table is editable (`CanEdit = true`) if and only if it has:
- A primary key (single or composite), OR
- At least one unique index/constraint whose columns are all `NOT NULL`.

If neither condition is met, `CanEdit` is `false`, and `EditDisabledReason` explicitly tells the user: `"Table has no primary key or unique NOT NULL column. Edits are disabled."`

### 4. Caching & Invalidation
The core maintains a session-scoped schema cache (`core/internal/schema`).
- Queries check the cache first.
- Calling `RefreshSchema` (or passing `refresh: true` in any inspection RPC) clears the cache for that scope and re-queries the database.
- Closing a session releases its cache.

### 5. Dialect Details
- **PostgreSQL:**
  - Schemas from `pg_namespace` (filtering `pg_toast`, `pg_temp_%`, `information_schema`).
  - Objects and row estimates from `pg_class` (`relkind IN ('r', 'p', 'v', 'm')`) and `reltuples::bigint`.
  - Column nullability, defaults, PK ordinal from `pg_attribute`, `pg_attrdef`, and `pg_index`.
  - Foreign keys from `pg_constraint` (`contype = 'f'`).
- **SQLite:**
  - Schemas: `main` (and any attached databases via `PRAGMA database_list`).
  - Objects from `sqlite_master WHERE type IN ('table', 'view')`. Estimated rows are `-1`.
  - Columns via `PRAGMA table_info` / `table_xinfo`.
  - Indexes via `PRAGMA index_list` + `PRAGMA index_info`.
  - Foreign keys via `PRAGMA foreign_key_list`.

## Consequences
- Clean separation: core encapsulates catalog and dialect differences; UI consumes a unified structure.
- It. 7 (table designer) and It. 9 (ER diagrams) can generate diagrams and DDL by reading `ColumnDef`, `IndexDef`, and `ForeignKeyDef` directly without changing the engine interface.
- Fast performance on large databases with thousands of objects.
- Mutation safety: read-only tables prevent data corruption or ambiguous row updates.

