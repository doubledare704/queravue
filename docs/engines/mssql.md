# SQL Server

Package `core/internal/engine/mssql`, built on `microsoft/go-mssqldb`. SQL login only (Windows/Entra authentication is not supported yet).

Connection form: host, port (1433), database (optional), user (`sa`), password (keychain), encryption (`disable`, `optional` = login packet only, `required`, `strict` = TDS 8) and "Trust server certificate". A server with a self-signed certificate (the dev container) needs the trust option, otherwise connecting fails with a TLS error. URI: `sqlserver://user@host:1433?database=x&encrypt=required&TrustServerCertificate=true`; named instances are not supported (give the port).

## Behaviour
- **Dialect:** `[ident]` quoting, `@p1` placeholders, `OFFSET 0 ROWS FETCH NEXT n ROWS ONLY`, `BEGIN TRANSACTION`, `N'…'` string previews, `NULLS FIRST/LAST` emulated with a `CASE` term. Tables are addressed as `[database].[schema].[table]`.
- **Pagination needs `ORDER BY`:** the table view sorts by the primary key when no sort is chosen. Without a key it falls back to `ORDER BY (SELECT NULL)` and the result summary carries the notice "Row order is not stable…".
- **Splitting:** `sqlsplit` handles `[a]]b]`, `N'…'`, nested block comments and the `GO` batch separator (a line of its own, optional count and trailing `--` comment). `CREATE`/`ALTER` of a procedure, function, trigger or view runs to the next `GO`, so semicolons inside the body do not split it. A `GO n` count is accepted but the batch runs once.
- **Schema:** databases (`sys.databases`, system databases hidden) → schemas (`sys.schemas`) → tables and views (`sys.objects`) → columns, indexes and foreign keys (`sys.columns`, `sys.indexes`/`index_columns`, `sys.foreign_keys`). Row estimates come from `sys.dm_db_partition_stats` for the connection's own database and from `sys.partitions` for others (that DMV only sees the current database).
- **Editing:** tables need a primary key or a unique index on `NOT NULL` columns; otherwise read-only with a reason. Views are read-only.
- **Cancel:** cancelling sends a TDS attention signal; the server stops the query and the session stays usable.

## Types
| SQL Server type | Value |
|---|---|
| `tinyint`, `smallint`, `int`, `bigint` | int |
| `bit` | boolean |
| `real`, `float` | float |
| `decimal`, `numeric`, `money`, `smallmoney` | decimal (exact text) |
| `datetime`, `datetime2`, `smalldatetime`, `datetimeoffset` | timestamp (offset kept for `datetimeoffset`; naive types are read as UTC) |
| `date`, `time` | text |
| `uniqueidentifier` | UUID (the wire byte order of the first three groups is swapped back) |
| `binary`, `varbinary`, `image`, `rowversion` | bytes |
| `nvarchar(max)`, `varchar(max)`, `xml`, everything else | text |

## Known limitations
- **Only the first result set** of a batch is returned (the protocol has no multi-result concept yet; this PR does not change `proto/`). Later result sets are discarded. Run statements separately or use `GO`.
- **`rowversion` columns** are shown as bytes. They are not marked read-only in the editor yet; writing one fails with the server's error.
- `PRINT` and `RAISERROR` messages are not collected as notices.
- Strings are sent as `nvarchar`; comparing against a `varchar` column can prevent an index seek.
- The Docker image is amd64 only and runs under emulation on Apple Silicon (enable Rosetta in OrbStack / Docker Desktop).

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait mssql
docker compose -f dev/docker-compose.yml --profile seed up mssql-seed
cd core && go test -tags=integration ./internal/engine/mssql/ && go test -tags=integration -run MSSQL ./internal/api/
```
