# ADR 0013 — DDL generation, table designer and Mongo validation

**Status:** Accepted · 2026-11-07

## Context
Iteration 7 lets users create and alter tables visually and review the DDL before it runs, and edit a Mongo collection's `$jsonSchema` validator. The dialect layer (ADR 0008) quotes and paginates but generates no DDL. `TableService.ApplyChanges` is the model for dry-run, production confirmation and history. Related: ADR 0007, 0008, 0009 §8, 0012.

## Decision

### 1. Structured changes, not SQL from the UI
The UI sends `SchemaChange` steps (`create_table`, `drop_table`, `rename_table`, `add/drop/rename/alter column`, `add_foreign_key`, `add_unique`, `add_check`, `drop_constraint`, `add_index`, `drop_index`) in order. The core builds the SQL. The UI never assembles DDL text, so quoting and syntax live in one place per dialect.

### 2. DDL builders in the dialect layer
`sqldialect` gains a `DDL` builder per dialect, next to `Dialect`. It returns statements, each with a summary and a `destructive` flag, plus warnings. Engine ids are never switched on outside engine and dialect packages. Differences handled here:

- identifier quoting and qualified names (ADR 0008);
- identity: `GENERATED ... AS IDENTITY` (PostgreSQL, CockroachDB), `AUTO_INCREMENT` (MySQL family), `IDENTITY(1,1)` (SQL Server), `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite);
- altering a column: one `ALTER COLUMN` per property on PostgreSQL, `MODIFY COLUMN` with the full definition on MySQL, `ALTER COLUMN` with the full type on SQL Server; SQLite and CockroachDB use their limited forms;
- `DROP INDEX name ON table` on MySQL and SQL Server, `DROP INDEX name` elsewhere;
- constraint drops by kind (`DROP FOREIGN KEY` on MySQL, `DROP CONSTRAINT` elsewhere);
- renames: `RENAME COLUMN`, `sp_rename` on SQL Server.

`AlterColumn` carries `before` and `after`, and the builder emits only what differs, so the preview shows the real change.

### 3. Operations an engine cannot do
The builder returns `UNSUPPORTED` with the reason instead of a partial translation. On SQLite that covers altering a column, adding a foreign key, unique or check constraint to an existing table, and dropping a constraint. The documented rebuild recipe (create new table, copy rows, drop old, rename) is deferred: SQLite does not expose inline `CHECK` and `UNIQUE` constraints, so a rebuild could silently lose them. Other engines reject what they cannot do themselves: SQL Server default changes need the default's constraint name (`UNSUPPORTED`), MySQL has no `SET DEFAULT` for foreign keys, SQL Server has no `RESTRICT`, and PostgreSQL and SQL Server cannot toggle identity in place.

### 4. Preview, apply, transactions
- `PreviewDDL` returns the exact statements and warnings, and runs nothing.
- `ApplyDDL` rebuilds the statements from the same changes, so the run always matches the preview of the same request, and executes them in `sess.Begin` as `ApplyChanges` does.
- DDL transactionality differs, and the response says which applies (`transactional`):
  - PostgreSQL, SQL Server and SQLite: one transaction; an error rolls everything back.
  - MySQL, MariaDB and TiDB: DDL commits implicitly. A warning is shown in the preview and `executed_statements` tells the UI how far a failed run got.
  - CockroachDB: schema changes in one explicit transaction are limited; statements run one at a time with the same partial-run reporting. A `Conn` whose DDL transactionality differs from its dialect's says so through `TransactionalDDL()` (`api.DDLTransactionality`).
- After a successful apply the schema cache is invalidated for the table (`schema.Cache.Invalidate`), and each statement is recorded in the history.

### 5. Safety
- `confirmed=true` is required on connections flagged production for every apply, and on any connection when a statement is `destructive` (drop table, drop column, drop constraint or index, and a type change that can narrow data). Statements keep the order of the changes; each carries its `destructive` flag so the preview can mark them.
- Without confirmation the core refuses with `CONFIRMATION_REQUIRED` and changes nothing.
- The table designer is offered only on connections that can execute SQL and inspect schema.

### 6. Mongo validation
- `CapValidation = "validation"`: `ValidationManager{ GetValidation; SetValidation }`, implemented by the Mongo engines.
- The validator is a canonical EJSON document, normally `{"$jsonSchema": {...}}`, with `validationLevel` (off, moderate, strict) and `validationAction` (error, warn). `GetValidation` reads them from the collection options (`ListCollectionSpecifications`, already used by `ListObjects`). `SetValidation` runs `collMod`; an empty validator removes the rule.
- The validator text is parsed before sending; a parse error returns `INVALID` with a UTF-16 position (ADR 0006). `dry_run` returns the `collMod` command as shell text.
- Operators that Cosmos DB and DocumentDB support unevenly are not blocked by the core; the server's rejection is returned as the server's message. `collMod` and `$jsonSchema` support per variant is verified by the smoke tests and recorded in `docs/engines/`.
- `UNSUPPORTED` mapping: Mongo error codes 59 (CommandNotFound), 115 (CommandNotSupported) and 238 (NotImplemented) become `ADMIN_ERROR_KIND_UNSUPPORTED` in the classifier (`mongo/errors.go`), next to the existing code 166 (view).
- The editor can start from a schema inferred from `SampleFields` (ADR 0009): a starting point the user edits, never applied automatically.

### 7. Model growth
Additive only, no renumbering: `ColumnDetails.identity`, `ColumnDetails.collation`, `ForeignKeyDetails.on_delete` and `on_update` (new `ReferentialAction`), mirrored in `engine.ColumnDef` and `engine.ForeignKeyDef` and filled by each engine's `DescribeTable`, so the designer opens an existing table in the state the server reports. Type length and precision stay inside `type_name` (`varchar(255)`), as the schema browser already reports them, so the UI does not need a second type model.

### 8. Contract
`SchemaDesignService` (`PreviewDDL`, `ApplyDDL`) in `design.proto`, `ValidationService` in `validation.proto`. Errors are in-band `AdminError`. `protocol_version` becomes 7 when the first of these services is served.

## Consequences
- One golden test suite per dialect pins the generated DDL; enginetest apply-and-describe checks that the server accepts it and reports the result back.
- MySQL-family users can end up with a partly applied script after a failure; the UI states this up front in the preview and after a failed run.
- SQLite alters are intentionally narrower than other engines; column changes beyond add, drop and rename are reported as unsupported.
- The designer models columns, keys, unique and check constraints and indexes. Triggers, partitions, table options and engine-specific storage settings are not designed here; users run them in the SQL editor.
- The first designer screen edits columns (name, type, default, nullability, auto-generated, primary key on a new table). Foreign keys, unique and check constraints are supported by `SchemaDesignService` but have no screen yet; indexes are managed in the Indexes panel. A new table's primary key and an existing column's auto-generated flag cannot be changed in the designer.
