# ADR 0006 — Query execution: sessions, result spool, cancel

**Status:** Accepted · 2026-11-05

## Context
Iteration 2 runs SQL and shows results of up to millions of rows. ADR 0003 defined the `Executor` capability and ADR 0004 requires a server-side window source (`FetchRows`). The UI must stay within PRD budgets (idle ≤ 150 MB, 1M rows ≤ +200 MB) and cancel must stop the server-side query.

## Decision
- **Executor** (ADR 0003 shape): `Execute(ctx, Statement{SQL, Params}, RowSink) (Summary, error)`. The sink receives `Columns` and `Batch` (≤ 500 rows; returning `ErrStop` ends reading cleanly); `Summary` has rows affected, duration and notices.
- **Sessions:** `SessionService.Open(connection_id)` connects and keeps one `Conn`. Statements on a session run sequentially (per-session mutex). Idle sessions close after 30 min. `Cancel(session_id)` cancels the running statement's context; Postgres additionally sends a native cancel request so the server stops the query even while rows are being fetched.
- **Splitting in core:** per-dialect scanner (`internal/sqlsplit`). `Execute` takes `{text, cursor_offset, mode, selection}` and returns statement ranges. **Offsets on the wire are UTF-16 code units** (what Dart and re_editor index by); core converts from byte offsets.
- **Spool:** every statement gets a `result_id`. Rows are written to a temp file in 500-row pages, each page a serialized `RowBatch`, with an in-memory page-offset index (≈16 B/page), so any page is one seek + read. Memory is one page of write buffer plus the index. Cap per result defaults to 2 GB (`--spool-cap`); at the cap, reading stops and the result is marked truncated. Files are removed on `CloseResult`/session close and stale spool dirs are swept at start (`os.TempDir()/queravue-<uid>/spool/<pid>`).
- **Streaming:** `QueryService.Execute` streams columns, the first window of rows, throttled progress (`rows_spooled`, `done`) and a summary. Rows past the first window are only delivered by `FetchRows`/`CopyRange`. If the client drops the stream, the query is cancelled.
- **Multiple statements:** one `result_id` per statement; stops at the first error.
- **Copy:** `CopyRange` formats TSV/CSV/JSON in core and streams text chunks.

## Consequences
- Disk use is bounded per result, not globally; many large open results can still fill the disk. Revisit with a global budget if it shows up.
- The UI never holds more than its page window (ADR 0004).
- Spool format is internal and may change between versions; spools never outlive the core process.
