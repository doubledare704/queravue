# ADR 0016 — Editor groups and detached windows

**Status:** Accepted · 2026-11-08

## Context
Iteration 8 asks for split editor groups, resizable panes and a layout that survives a restart, and a spike on detaching a pane into its own OS window. Tabs are in memory only (`EditorTabs`), keyed by connection, with one active tab per connection that most actions read.

## Decision

### Groups
- A layout is kept per connection, beside the tabs, not inside them: `EditorLayout` holds the groups (ordered tab ids and an active tab each), the focused group, one split axis and the groups' shares. `EditorTabs` keeps its own active tab per connection and it is always the focused group's active tab, so run, save, format and every other "active tab" action work unchanged.
- The layout follows the tabs (`reconcile`): closed tabs leave, a new tab joins the focused group, selecting a tab focuses its group, and an empty group disappears and gives its share to a neighbour.
- A tab is dragged onto a group (joins its end) or onto a tab (lands in front of it); `EditorLayout.moveTab` is the one operation behind both and behind reordering inside a group. Dropping on a group's edge to create a new split is not built.
- Splitting moves the active tab into a new group; a tab cannot show twice because its editor controller is single. The first split picks the axis (right or down), later splits keep it. At most four groups, and no group below 18 % of the pane.
- Closing a tab shows its neighbour in the same group, not the connection's last tab (`EditorTabs.closeSuccessor`, set by the layout; a direct provider read would be a cycle).
- Tab bodies are built the first time the tab is shown and then kept, so background tabs cost nothing.

### Persistence
- `.queravue/layout.json` in the first workspace root (the same place as snippets and keybindings): per connection the query and shell tabs (title, bound file, unsaved text up to 200,000 characters) and the layout with tab positions instead of ids, plus the selected connection. Written 800 ms after a change and when the app quits; never before the file was read, so a slow start cannot overwrite it.
- Restoring runs after the core is ready and reads nothing but that file. A tab bound to a file is created empty and loads the file, with its unsaved text on top, the first time it is shown. A tab without a file gets its text at once.
- Table, collection and designer tabs are not restored: they need a live session, and reopening them is one click.
- A file that is missing, not JSON, of another version, or does not match its own tabs is ignored: the app starts fresh.
- Not chosen: storing it in the core. It would need a proto change for state that belongs to one machine's UI.

### Detached windows (spike)
Desk research on 2026-11-08; no prototype was built.
- Flutter's own desktop windowing API exists, but only on the main channel behind `--enable-windowing`, marked experimental. The stable channel (3.44) does not export it.
- Plugins exist (`desktop_multi_window`, `multi_window`, `multiview_desktop`). The multi-view one shares one engine, isolate and provider container, which would suit this app; it needs Wayland on Linux, and none of them is the framework's own answer.
- What a detached window would need here that is not free: one provider container for all windows (tabs, sessions, layout), native window state in the layout file, behaviour when the main window closes, and keyboard shortcuts per window.

Decision: do not ship detached windows in Iteration 8. The stand-in is an in-window maximize: the focused group fills the window while the sidebar and the other groups are hidden but stay mounted (`Offstage`), so nothing is reloaded on restore. The flag lives in `PaneSizes` with the sidebar width and the editor/output share, and is the only field of it that is not saved. Groups inside one window are done. Revisit when the windowing API reaches the stable channel; the layout model already allows a group to become a window, since a group is a list of tab ids with an active one.

## Consequences
- Every "active tab" action keeps working with groups; the cost is one extra provider (`editorLayoutProvider`) that must stay in step with the tabs.
- Draft text is saved only after a change or on quit, so a crash can lose edits made since the last save.
- `.queravue/layout.json` is machine state and is best kept out of version control; the docs say so.
