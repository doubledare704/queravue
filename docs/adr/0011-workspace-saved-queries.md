# ADR 0011 — Workspace and saved queries

**Status:** Accepted · 2026-11-06

## Context
Users save SQL queries and Mongo scripts, organise them in folders, search them and keep them in Git. The It. 15 scheduler runs saved scripts with the UI closed, and charts (It. 11) reuse saved queries. Related: ADR 0010 (shell), 0006 (UTF-16 offsets).

## Decision

### 1. Core owns workspace I/O
`internal/workspace` does all file reading, writing, search and watching; the UI goes through `WorkspaceService`. The scheduler uses the package directly.

### 2. Roots
A workspace is a user-chosen folder. The default is `~/Queravue/workspace`, created on first use. Several roots are allowed; the list is stored in core settings and managed by `GetRoots`/`SetRoots`. Each root has an id. On the wire, every path is `root_id` plus a slash-separated path relative to that root. Absolute paths appear only in `SetRoots`.

### 3. Files
- `.sql` for SQL queries, `.mongo.js` for Mongo scripts. Other files are listed but not opened as scripts.
- An optional header lives in the leading comment block: `--` lines or `/* */` for SQL, `//` lines or `/* */` for JS. Keys: `title`, `description`, `connection`, `tags` (comma-separated). Example:
  ```
  -- title: Active users
  -- connection: analytics-prod
  -- tags: reports, users
  ```
- `connection` is a connection id or name. **Credentials never go into files.** If the name is unknown, the file opens unbound.
- A file with a header is still valid plain SQL/JS, since the header is comments. A file without a header is valid and gets no header unless the user adds metadata.
- Unknown header keys are kept as they are when the header is rewritten.

### 4. Path safety
Every path is cleaned and checked to stay inside its root. `..` is rejected. Symlinks are resolved and rejected if the target is outside the root. Errors are `PATH_ESCAPES_ROOT`.

### 5. Atomic writes and conflicts
Writes go to a temp file in the same directory and are renamed over the target. `Read` returns `mtime` and a content hash (SHA-256). `Write` carries `expected_mtime` and `expected_hash`; if the file on disk differs, nothing is written and the reply is `CONFLICT` with the current content, mtime and hash. The UI asks "reload or keep mine"; "keep mine" sends `Write` again with `force=true`. Creating a file that exists is `ALREADY_EXISTS`.

### 6. Watching
`Watch` streams change events (`CREATED`, `MODIFIED`, `DELETED`, `RENAMED`) for the roots, from fsnotify with a debounce (about 200 ms) that coalesces editor save bursts and git checkouts. Core ignores events caused by its own writes. `.git` is not watched.

### 7. Search
`Search(text, tags)` matches file names, titles, tags and full text, case-insensitively. Results stream as they are found and the call is cancellable. `.git` and files over a size cap (default 2 MiB) are skipped.

### 8. Contract
`protocol_version` becomes 6 when the service is served (5 added `ShellService`).

`WorkspaceService`: `GetRoots`, `SetRoots`, `ListTree`, `Read`, `Write`, `Create`, `Rename` (also moves), `Delete`, `Search` (server stream), `Watch` (server stream). Failures are in-band `WorkspaceError`. `Delete` removes the file; the UI always confirms.

## Consequences
- Plain files work with Git, editors and CI. Team sharing is a Git concern, not ours.
- Without file locking, the hash check narrows but does not close the window between check and rename; accepted for an interactive tool.
- Large trees are listed one directory at a time (`ListTree` takes a path), so opening a huge workspace stays cheap.
- New dependency: `github.com/fsnotify/fsnotify` (BSD-3-Clause).
