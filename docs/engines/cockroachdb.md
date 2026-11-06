# CockroachDB

A variant (`cockroachdb`, default port 26257, user `root`) of the `postgres` engine package: same pgx driver, same dialect, same executor. Differences are handled inside `core/internal/engine/postgres`, never in the UI.

## Behaviour that differs from PostgreSQL
- **Row estimates:** `pg_class.reltuples` is not maintained. Estimates come from `crdb_internal.table_row_statistics` (table statistics), so a table shows 0 until statistics exist (automatic after a while, or `CREATE STATISTICS`).
- **Hidden `rowid`:** tables created without a primary key get an implicit hidden `rowid` primary key. It is excluded from the column list and not treated as a key, so such tables are read-only like on PostgreSQL.
- **Cancel:** a cancelled context sends the PostgreSQL cancel request, which CockroachDB honours (verified mid-stream on a 1M-row scan).

## Known limitations
- Only insecure and password logins are exercised; client certificates are not configurable yet.
- `SERIAL` columns default to `unique_rowid()` (large, non-sequential ids) unless `serial_normalization` is changed; the dev seed switches it to `sql_sequence`.
- Statement notices are not surfaced.

## Testing
The dev service uses an in-memory store (a disk-backed 1M-row seed takes ~12 minutes on a laptop VM), so reload the seed after each restart.
```bash
docker compose -f dev/docker-compose.yml up -d --wait cockroachdb
docker exec -i queravue-dev-cockroachdb-1 ./cockroach sql --insecure < dev/seed/cockroachdb/01_schema.sql
cd core && go test -tags=integration -run IntegrationSuiteCockroach ./internal/engine/postgres/
```
The same shared suite (`internal/engine/enginetest`) runs against PostgreSQL (`IntegrationSuitePostgres`).
