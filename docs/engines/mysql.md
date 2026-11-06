# MySQL, MariaDB and TiDB

One package, `core/internal/engine/mysql`, built on `go-sql-driver/mysql`, with three variants:

| Variant | id | Default port | Dev service |
|---|---|---|---|
| MySQL 8.x | `mysql` | 3306 | `mysql` (3306) |
| MariaDB 11.x | `mariadb` | 3306 | `mariadb` (3307) |
| TiDB 8.x | `tidb` | 4000 | `tidb` (4000, unistore playground) |

Connection form: host, port, database (optional), user, password (keychain), TLS (`disable`, `preferred`, `skip-verify`, `verify`). URIs: `mysql://`, `mariadb://`, `tidb://`, or a go-sql-driver DSN.

## Behaviour
- **Dialect:** `` `ident` `` quoting, `?` placeholders, `LIMIT n`, no `NULLS FIRST/LAST` (emulated with `col IS NULL`), backslash-escaping string previews. `sqlsplit` understands backslash escapes, `#` and `-- ` comments, backtick identifiers and the `DELIMITER` client command (procedure bodies need it, as in the `mysql` client).
- **Schema:** a MySQL schema is a database. The tree is databases → one schema named like the database → tables/views. System schemas are hidden. Row estimates come from `information_schema.tables.table_rows` (an estimate for InnoDB). Views show no estimate.
- **Editing:** tables need a primary key or a unique index whose columns are all `NOT NULL`; otherwise they are read-only with a reason.
- **Streaming and cancel:** rows are read from the socket as the grid consumes them. Cancelling (or closing a result early) sends `KILL QUERY <id>` on a second connection, so the server stops and the session stays usable. If the kill itself fails the socket is cut.
- **Time zone:** sessions run in UTC, so `TIMESTAMP` values arrive as UTC. `DATETIME` is shown as stored (treated as UTC wall-clock).

## Types
| MySQL type | Value |
|---|---|
| `TINYINT`..`BIGINT`, `YEAR` | int (unsigned `BIGINT` above 2^63-1 → decimal) |
| `FLOAT`, `DOUBLE` | float |
| `DECIMAL` | decimal (exact text) |
| `DATETIME`, `TIMESTAMP` | timestamp; zero dates (`0000-00-00 …`) stay text |
| `DATE`, `TIME` | text |
| `BIT`, `BINARY`, `VARBINARY`, `BLOB`, `GEOMETRY` | bytes |
| `JSON` | JSON (MariaDB's `JSON` is `LONGTEXT`, so it shows as text) |
| everything else | text |

## Known limitations
- `TINYINT(1)` is reported as boolean by the schema (column definitions) but result sets carry it as an integer, because the driver does not expose the display width.
- Only the first result set of a `CALL` is read; multi-statement text is split by Queravue and run statement by statement.
- Server notices/warnings (`SHOW WARNINGS`) are not collected yet.
- TiDB runs in the single-process unistore mode in dev: fine for compatibility tests, not for performance numbers. `TABLE_ROWS` depends on TiDB statistics.
- DDL commits implicitly in MySQL-family servers, so "rollback" in the table view only covers DML.

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait mysql mariadb tidb
docker exec -i queravue-dev-mariadb-1 mariadb -h tidb -P 4000 -uroot < dev/seed/tidb/01_schema.sql   # TiDB has no init dir
cd core && go test -tags=integration ./internal/engine/mysql/...
```
mysql and mariadb load `dev/seed/<name>/` on first start of their volume; remove the volume (`docker compose down -v`) to reload.
