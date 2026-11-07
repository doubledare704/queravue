# ADR 0012 — Index manager and statistics

**Status:** Accepted · 2026-11-07

## Context
Iteration 7 adds an index manager (list, create, drop, usage) and table or collection statistics for every SQL engine and for Mongo, DocumentDB and Cosmos DB. Today `DescribeTable` returns only name, columns, unique and primary for an index, and `SchemaObject` carries a size. The shell already runs `createIndex`, `getIndexes` and `stats` as raw commands. Related: ADR 0003 (capabilities), 0007 (schema model), 0008 (dialect layer), 0009 (document model), 0011.

## Decision

### 1. Three optional capabilities
Per ADR 0003, each is an interface on `Conn` with a capability name in the descriptor and an entry in `CapabilityInterfaces`; the UI gates on the name only.

- `CapIndexManager = "index_manager"`: `IndexManager{ ListIndexes }`. Engines that create and drop natively also implement `IndexWriter{ CreateIndex; DropIndex }`, each with a `dryRun` flag that only builds the statement.
- `CapStats = "stats"`: `StatsProvider{ TableStats }`.
- `CapValidation = "validation"` is defined in ADR 0013.

`ListIndexes` and `TableStats` are implemented by every engine that can answer them. Only Mongo implements `IndexWriter`. On SQL engines create and drop are built by `Dialect.CreateIndex` and `Dialect.DropIndex` and run through `Executor`, so a SQL engine adds no write code. The API layer picks the path with `engine.As[IndexWriter]`, never from an engine id. The split keeps `CapIndexManager` meaning one interface, as the registry test requires.

### 2. Index model
`engine.IndexInfo` is separate from the `IndexDef` that `DescribeTable` returns, so the schema tree stays cheap. It holds the `IndexSpec` (name, keys with kind, unique, method, partial predicate, include columns, free-form options), `is_primary`, optional size and `IndexUsage`. Key kinds cover SQL ascending and descending, and Mongo hashed, text and 2dsphere. `IndexDef` and `IndexDetails` are unchanged.

### 3. Usage and statistics sources
Usage is optional and says so (`IndexUsage.available`); the UI shows "not available", never zero.

| Engine | Index list | Usage | Table stats |
|---|---|---|---|
| PostgreSQL | `pg_index`, `pg_class` | `pg_stat_user_indexes` (scans, no last-used time) | `pg_stat_user_tables`, `pg_total_relation_size` |
| CockroachDB | `SHOW INDEXES` | unavailable | row estimate from table statistics; no sizes |
| MySQL, MariaDB | `information_schema.statistics` | `performance_schema` index I/O when enabled (MariaDB ships it off), else unavailable | `information_schema.tables`; index sizes from `mysql.innodb_index_stats` |
| TiDB | as MySQL | unavailable | as MySQL, row estimate from statistics |
| SQL Server | `sys.indexes` | `sys.dm_db_index_usage_stats` (since last restart) | `sys.dm_db_partition_stats` |
| SQLite | `PRAGMA index_list`, `index_xinfo` | unavailable | `dbstat` sizes when compiled in, `sqlite_stat1` rows when analyzed, page size and count |
| MongoDB | `listIndexes` | `$indexStats` (ops, since) | `collStats` |
| DocumentDB, Cosmos DB | `listIndexes` | `$indexStats` if the server accepts it | `collStats` if accepted |

For Mongo variants, rejection of `$indexStats` or `collStats` becomes `UNSUPPORTED` (ADR 0013 §5), and the panel reports it instead of failing. Support per variant is verified by the DocumentDB Local smoke test and recorded in `docs/engines/`; Cosmos DB stays marked unverified.

Statistics are read from server metadata and never scan data. Unknown figures are unset. Engine-specific figures travel as formatted `StatEntry` rows so the UI needs no per-engine layout.

### 4. Contract
`IndexService` (`ListIndexes`, `CreateIndex`, `DropIndex`) and `StatsService` (`GetStats`) address a table or collection by `TableRef`; for Mongo, `database` plus `table` (the collection) with an empty schema. Failures are in-band `AdminError` (`proto/queravue/v1/admin.proto`), as with `DocumentError`.

### 5. Safety
- `CreateIndex` and `DropIndex` support `dry_run`, which returns the statement without running it: SQL DDL, or the `createIndexes`/`dropIndexes` command as shell text.
- Every write on a connection flagged `production` needs `confirmed=true`, the ADR 0009 §8 mechanism, checked in the API layer where the flag lives.
- `DropIndex` needs `confirmed=true` on every connection, because dropping an index can make queries slow until it is rebuilt.
- `CreateIndex` on a big table can lock writes on some engines; the preview carries a warning, for example `CREATE INDEX` without `CONCURRENTLY` on PostgreSQL. Online creation (`CONCURRENTLY`, `ONLINE = ON`) is not offered yet: PostgreSQL's `CONCURRENTLY` cannot run inside a transaction block, so it needs its own execution path.
- Every applied change is recorded in the query history as the statement that ran.

### 6. Protocol version
`protocol_version` becomes 7 when the services are first served (PR 2), as in ADRs 0009 and 0010.

## Consequences
- SQL engines gain no write code for indexes; correctness of generated DDL is covered by golden tests per dialect (ADR 0013).
- Usage statistics differ in meaning between engines (since restart, since reset, since the last stats reset). The UI shows the "since" time when known and does not compare engines.
- Cosmos DB behaviour is unverified, as elsewhere.
