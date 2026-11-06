# ADR 0008 — SQL dialect layer

**Status:** Accepted · 2026-11-06

## Context
Until It. 3 the SQL syntax rules were scattered: `sqlbuilder.QuoteIdent` always wrote `"x"`, placeholders and the SQLite `main` schema were handled by a two-value enum in `sqlbuilder`, `sqlsplit` had its own two-value enum, and `session`/`table_service` chose between them with `Desc.Family == …`. Iteration 4 adds MySQL (backticks, `?`), SQL Server (`[x]`, `@p1`, `OFFSET … FETCH` that requires `ORDER BY`) and a real CockroachDB. AGENTS.md forbids engine-id switches outside engine packages.

## Decision
New package `core/internal/sqldialect`:

```go
type Dialect interface {
    ID() string
    QuoteIdent(name string) string
    QualifyTable(schema, table string) string      // SQLite "main" omitted; MSSQL may add a database part
    Placeholder(n int) string                      // $n, ?, @pn
    OrderTerm(quotedCol string, desc bool, nulls Nulls) string
    Paginate(sql string, limit uint64, hasOrderBy bool) (out string, stable bool)
    FormatLiteral(v engine.Value) string           // previews only, never executed
    Lexer() sqlsplit.Dialect
}
type Provider interface{ Dialect() Dialect }       // implemented by a SQL Conn
func Of(c engine.Conn) (Dialect, bool)
```

- **Engines expose their dialect** by implementing `Provider` on their `Conn`. `session.Open` stores it as `Session.Dialect`; `sqlbuilder`, the table view, edit code and statement splitting read it from there. No engine-id or family switches remain outside engine packages.
- **`engine.Engine`, `engine.Conn` and `CapabilityInterfaces` are unchanged.** `Provider` is a separate optional interface (ADR 0003 style). It lives in `sqldialect`, not `engine`, because `sqldialect` imports `engine.Value`; putting it in `engine` would create an import cycle. It is not a user-visible capability, so the UI is unaffected.
- **Pagination.** `Paginate` receives SQL without a terminator. LIMIT dialects append `LIMIT n`. Dialects that need `ORDER BY` for `OFFSET … FETCH` add `ORDER BY (SELECT NULL)` when `hasOrderBy` is false and return `stable=false`; callers surface "order not stable". Callers that know a primary key should add it as the sort first (SQL Server, PR 4).
- **NULL ordering.** Dialects without `NULLS FIRST/LAST` (MySQL, SQL Server) emulate it inside `OrderTerm` with a leading `col IS NULL` term.
- **Lexer.** Each dialect names its `sqlsplit` lexer; `sqlsplit` gains `MySQL` (PR 2) and `MSSQL` (PR 4) lexers.
- **Compatibility.** Postgres and SQLite output is byte-for-byte unchanged. `sqlbuilder` keeps `Dialect`, `DialectPostgres`, `DialectSQLite` and a deprecated `QuoteIdent` as thin aliases so existing callers and tests keep compiling.
- CockroachDB shares the `Postgres` dialect; MariaDB and TiDB share `MySQL`.

## Consequences
- A new SQL engine adds one dialect file plus `Dialect()` on its Conn; no central switch.
- `Paginate` currently takes only a limit (the table view pages by re-querying); an offset parameter is added when keyset/offset paging lands.
- Literal formatting for previews is per dialect, so e.g. byte literals can differ (`X'..'`, `0x..`).
