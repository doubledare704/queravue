# Workspace and saved queries

Saved SQL queries and Mongo scripts are plain files in workspace folders. Core owns all file access (`core/internal/workspace`, served as `WorkspaceService`), so the scheduler (iteration 15) can use the same files with the UI closed. Design: [ADR 0011](adr/0011-workspace-saved-queries.md).

## Folders
- Default: `~/Queravue/workspace`, created on first use. Override the default for a fresh install with `QUERAVUE_WORKSPACE`.
- The list of folders ("roots") is stored in `workspace.json` in the config directory. Several roots are allowed; each has a stable id, and every path on the wire is a root id plus a slash-separated path inside it.

## Files
| Extension | Kind |
|---|---|
| `.sql` | SQL query |
| `.mongo.js` | Mongo shell script |

Other files are listed in the tree but are not opened as scripts and are not searched.

### Header
An optional comment block at the top of the file holds metadata. It is still plain SQL/JS:

```sql
-- title: Active users
-- description: Users seen in the last 30 days
-- connection: analytics
-- tags: reports, users

SELECT * FROM users WHERE last_seen > now() - interval '30 days';
```

```js
// title: Remove stale sessions
// connection: staging
db.sessions.deleteMany({ expires: { $lt: new Date() } })
```

- Keys: `title`, `description`, `connection`, `tags` (comma-separated). Case-insensitive, one line each.
- Styles: `--` lines or `/* */` for SQL; `//` lines or `/* */` for JS. A block comment may start its lines with `*`.
- The header is the first comment block of the file; a blank line ends it. A comment without any of these keys is not a header and is never changed.
- `connection` is a connection id or name. Credentials never belong in a file.
- When core updates a header it changes known keys in place, appends new ones, removes emptied ones and keeps every other line, the body and the line-ending style.

## Safety
- Every path is resolved inside its root. `..`, absolute paths and symlinks (to files or folders) that lead outside the root are rejected with `PATH_ESCAPES_ROOT`. Search does not follow symlinks.
- Writes are atomic: a temp file in the same folder (`.qv-write-*`, hidden from the tree) is synced and renamed over the target. Existing file permissions are kept.
- Files over 2 MiB are not read, written or searched (`TOO_LARGE`).

## Saving without losing external edits
`Read` returns `mtime` and a SHA-256 `hash`. `Write` takes them back as `expected_hash` / `expected_mtime`:
- If `expected_hash` is set it alone decides; otherwise `expected_mtime` does. Neither set skips the check.
- On mismatch, or if the file was deleted, nothing is written and the reply is a `CONFLICT` error carrying the current file (unset if deleted).
- "Keep mine" resends the write with `force=true`; "reload" takes the content from the error.
- Check and rename are not one atomic step, so a writer that changes the file within those few milliseconds can still lose an update.

## Watching
`Watch` streams changes from the folders (fsnotify, one watch per directory, `.git` excluded):
- Events for one path are coalesced after a 200 ms quiet period, so an editor's save burst or a `git pull` yields one event per file.
- New folders are watched at once and the files already inside them are reported as created.
- Changes made through `WorkspaceService` are not echoed. The exception is rename, which is reported as one `RENAMED` event with `old_path`. An external rename appears as a deletion plus a creation.
- Watches cover the folders configured when `Watch` started; call it again after `SetRoots`.

## Search
`Search(text, tags)` streams script files as it finds them and stops when the call is cancelled or after 200 hits (configurable per request). Text matches the relative path, title, description, tags and file content, case-insensitively; every requested tag must be present. A content match reports the first matching line and a snippet.

## In the app
The sidebar switches between **Connections** and **Workspace**.

- **Tree.** Every workspace folder is a root; folders load when opened. A file with a `title` header shows the title (the file name is in the tooltip). The row menu has new SQL file, new Mongo script, new folder, rename / move (type a new path inside the workspace) and delete (always confirmed). The panel refreshes when shown and follows changes made on disk.
- **Search box.** Type text, or `#tag` words for tag filters (`daily #reports`). Results replace the tree until the box is cleared.
- **Open.** A `.sql` file opens in the SQL editor and a `.mongo.js` file in a Mongo shell tab. The connection is the one named in the header (id or name); if it is missing or does not fit the file type, the selected connection is used; with neither, the app asks you to select one. Opening an open file focuses its tab.
- **Save.** ⌘/Ctrl+S writes the tab to its file. A dot on the tab means the buffer differs from the file. If the file changed on disk, a dialog offers *Reload* or *Overwrite* (*Save anyway* if it was deleted).
- **Save as.** ⌘/Ctrl+⇧+S, or ⌘/Ctrl+S on a tab that has no file. Pick the workspace and a path (folders are created; the extension is added if missing), an optional title, and whether to write the connection's name into a header (`-- connection: …` / `// connection: …`). Saving onto an existing file asks first.
- **External changes.** While a tab is bound to a file, a change made on disk shows a banner with *Reload* and *Keep mine*; *Keep mine* lets the next save overwrite without asking again. A deleted file offers only *Keep mine* (saving recreates it). A rename of the file or its folder rebinds the tab.
- **Shortcuts and palette.** ⌘/Ctrl+O quick open, ⌘/Ctrl+⇧+F search, ⌘/Ctrl+⇧+T new Mongo shell; the palette has Open workspace file, New SQL file, New Mongo script, Search workspace, Save and Save as.

## Testing
```bash
cd core && go test ./internal/workspace/... ./internal/api/...
cd app && flutter test test/features/workspace
make test-e2e-shell    # real app and core, docker Mongo: save, restart, reopen, run
```
