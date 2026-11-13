# ADR 0014 — SQLite column alters by table rebuild

**Status:** Accepted · 2026-11-07 · amends ADR 0013 §3

## Context
SQLite cannot change a column's type, nullability, default or collation in place. ADR 0013 deferred the documented rebuild (create new table, copy rows, drop old, rename) because SQLite does not report inline `CHECK` and `UNIQUE` constraints, so a rebuild built from `DescribeTable` would lose them silently.

## Decision
- Since Iteration 9, the rebuild also adds columns and foreign keys, so a foreign key on an existing column can be added; a single-column key on a column added in the same script is instead written into its `ADD COLUMN` without a rebuild. Existing rows are not checked against a new key: the rebuild requires foreign keys not enforced.
- The rebuild starts from the table's own `CREATE TABLE` text in `sqlite_master`, not from the reported columns. Only the altered column's definition is rewritten; every other column, table constraint (`PRIMARY KEY`, `UNIQUE`, `CHECK`, `FOREIGN KEY`), and table option (`WITHOUT ROWID`, `STRICT`) is kept as written.
- `engine.TableDetails` gains `Rebuild *TableRebuild` (`CreateSQL`, `DependentSQL`, `Blockers`), filled only by SQLite. `DependentSQL` holds the `CREATE INDEX` and `CREATE TRIGGER` statements of the table, recreated after the swap. `Blockers` lists why the engine will not rebuild.
- `sqldialect.BuildDDL` emits, for one or more `AlterColumn` changes on the table: `CREATE TABLE` under a temporary name, `INSERT ... SELECT` of every column, `DROP TABLE`, `ALTER TABLE ... RENAME TO`, then the dependent statements. It runs in the service's transaction like any SQLite DDL, so a failed copy (for example `NOT NULL` over existing NULLs) rolls everything back.
- The rewrite is conservative and returns `UNSUPPORTED` with the reason instead of guessing when:
  - the `CREATE TABLE` text contains comments, a `CONSTRAINT` name on the column, a generated column, or is not a plain `CREATE TABLE name (...)`;
  - `Blockers` is not empty: foreign keys are enforced on the connection (a `DROP TABLE` would run implicit deletes and cascades), or a view or a trigger on another table mentions the table;
  - the change set contains anything besides `AlterColumn` on that table. Renames, adds, drops and index changes in the same script would be lost or reordered by a rebuild; the designer says to apply them in a separate step.
- The preview warns that rows are copied (slow and write-locking on large tables). A type change marks the statements destructive.

## Consequences
- Constraints survive a rebuild because their text is never regenerated.
- The designer's usual "rename and retype in one go" is rejected on SQLite with a clear message; two steps work.
- Identity (`AUTOINCREMENT`) changes stay unsupported.
