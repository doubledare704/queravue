import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/sidebar_mode.dart';
import '../application/workspace_controller.dart';
import '../domain/workspace_models.dart';
import 'workspace_dialogs.dart';
import 'workspace_flows.dart';

/// Sidebar panel: folder tree of the workspace, search, and file actions.
class WorkspacePanel extends ConsumerStatefulWidget {
  const WorkspacePanel({super.key});

  @override
  ConsumerState<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends ConsumerState<WorkspacePanel> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Changes made while the panel was hidden were not watched.
    Future.microtask(() {
      if (!mounted) return;
      unawaited(ref.read(workspaceProvider.notifier).refresh());
      _serveFocusRequest();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _serveFocusRequest() {
    if (!ref.read(workspaceSearchFocusProvider)) return;
    ref.read(workspaceSearchFocusProvider.notifier).consume();
    _focus.requestFocus();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(workspaceProvider.notifier).search(v),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workspaceSearchFocusProvider, (_, wanted) {
      if (wanted) _serveFocusRequest();
    });
    final s = ref.watch(workspaceProvider);
    final scheme = Theme.of(context).colorScheme;
    final home = s.roots.isEmpty ? null : FilePath(s.roots.first.id, '');
    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Workspace',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: const Key('ws-new-sql'),
                  tooltip: 'New SQL file',
                  icon: const Icon(Icons.code, size: 18),
                  onPressed: () => newScriptFlow(context, ref, FileKind.sql),
                ),
                IconButton(
                  key: const Key('ws-new-mongo'),
                  tooltip: 'New Mongo script',
                  icon: const Icon(Icons.terminal, size: 18),
                  onPressed: () => newScriptFlow(context, ref, FileKind.mongo),
                ),
                IconButton(
                  key: const Key('ws-new-folder'),
                  tooltip: 'New folder',
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  onPressed: home == null
                      ? null
                      : () => _newFolder(context, home),
                ),
                IconButton(
                  key: const Key('ws-refresh'),
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () =>
                      ref.read(workspaceProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: TextField(
              key: const Key('ws-search'),
              controller: _search,
              focusNode: _focus,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search files (text, #tag)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: s.isSearch
                ? _Results(state: s)
                : s.error != null && s.roots.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      s.error!,
                      key: const Key('ws-error'),
                      style: TextStyle(color: scheme.error),
                    ),
                  )
                : !s.loaded
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _Tree(rows: flattenWorkspace(s)),
          ),
        ],
      ),
    );
  }

  Future<void> _newFolder(BuildContext context, FilePath dir) async {
    final name = await promptText(
      context,
      title: 'New folder',
      label: 'Folder name',
      confirm: 'Create',
    );
    if (name == null || !context.mounted) return;
    try {
      await ref.read(workspaceProvider.notifier).createFolder(dir, name);
    } on WorkspaceFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _Tree extends ConsumerWidget {
  const _Tree({required this.rows});
  final List<WorkspaceRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) {
      return const Center(child: Text('No workspace folder.'));
    }
    return ListView.builder(
      key: const Key('ws-tree'),
      itemCount: rows.length,
      itemExtent: 30,
      itemBuilder: (_, i) => WorkspaceRowTile(row: rows[i]),
    );
  }
}

/// One row of the tree.
class WorkspaceRowTile extends ConsumerWidget {
  const WorkspaceRowTile({super.key, required this.row});

  final WorkspaceRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isRoot = row.entry == null;
    final icon = row.isDir
        ? (row.expanded ? Icons.folder_open : Icons.folder)
        : switch (row.entry!.kind) {
            FileKind.sql => Icons.code,
            FileKind.mongo => Icons.terminal,
            FileKind.other => Icons.description_outlined,
          };
    final scriptKind = row.entry?.kind ?? FileKind.other;
    final canOpen = !row.isDir && scriptKind != FileKind.other;
    final title = row.entry?.meta.title ?? '';
    final path = row.file.path;
    return InkWell(
      key: Key('ws-row-${isRoot ? row.file.root : path}'),
      onTap: () {
        if (row.isDir) {
          unawaited(ref.read(workspaceProvider.notifier).toggle(row.file));
        } else if (canOpen) {
          unawaited(openFileFlow(context, ref, row.file));
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: 8.0 + row.depth * 14, right: 0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: row.isDir ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Tooltip(
                message: title.isEmpty ? row.name : '$title — ${row.name}',
                child: Text(
                  title.isNotEmpty && !row.isDir ? title : row.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: canOpen || row.isDir ? null : cs.outline,
                  ),
                ),
              ),
            ),
            PopupMenuButton<_Action>(
              key: Key('ws-menu-${isRoot ? row.file.root : path}'),
              iconSize: 16,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 16),
              onSelected: (a) => unawaited(_run(context, ref, a)),
              itemBuilder: (_) => [
                if (row.isDir) ...const [
                  PopupMenuItem(
                    value: _Action.newSql,
                    child: Text('New SQL file'),
                  ),
                  PopupMenuItem(
                    value: _Action.newMongo,
                    child: Text('New Mongo script'),
                  ),
                  PopupMenuItem(
                    value: _Action.newFolder,
                    child: Text('New folder'),
                  ),
                ],
                if (!isRoot) ...const [
                  PopupMenuItem(
                    value: _Action.rename,
                    child: Text('Rename / move…'),
                  ),
                  PopupMenuItem(value: _Action.delete, child: Text('Delete')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, _Action a) async {
    final ws = ref.read(workspaceProvider.notifier);
    void say(String m) =>
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(m)));
    try {
      switch (a) {
        case _Action.newSql:
          await newScriptFlow(context, ref, FileKind.sql, dir: row.file);
        case _Action.newMongo:
          await newScriptFlow(context, ref, FileKind.mongo, dir: row.file);
        case _Action.newFolder:
          final name = await promptText(
            context,
            title: 'New folder',
            label: 'Folder name',
            confirm: 'Create',
          );
          if (name != null) await ws.createFolder(row.file, name);
        case _Action.rename:
          final to = await promptText(
            context,
            title: 'Rename or move',
            label: 'New path in the workspace',
            initial: row.file.path,
            confirm: 'Rename',
          );
          if (to != null && to != row.file.path) {
            await ws.rename(row.file, to.replaceAll(RegExp(r'^/+'), ''));
          }
        case _Action.delete:
          final ok = await confirmDeleteEntry(
            context,
            name: row.name,
            isDir: row.isDir,
          );
          if (ok) await ws.delete(row.file);
      }
    } on WorkspaceFailure catch (e) {
      say(e.message);
    }
  }
}

enum _Action { newSql, newMongo, newFolder, rename, delete }

class _Results extends ConsumerWidget {
  const _Results({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.searchError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(state.searchError!, key: const Key('ws-search-error')),
      );
    }
    if (state.hits.isEmpty) {
      return Center(
        child: state.searching
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Text('No matching files.', key: Key('ws-no-hits')),
      );
    }
    return ListView.builder(
      key: const Key('ws-results'),
      itemCount: state.hits.length,
      itemBuilder: (_, i) {
        final h = state.hits[i];
        return ListTile(
          key: Key('ws-hit-${h.file.path}'),
          dense: true,
          leading: Icon(
            h.kind == FileKind.mongo ? Icons.terminal : Icons.code,
            size: 18,
          ),
          title: Text(h.meta.title.isNotEmpty ? h.meta.title : h.file.name),
          subtitle: Text(
            h.snippet.isEmpty
                ? h.file.path
                : '${h.file.path}:${h.line}  ${h.snippet}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => openFileFlow(context, ref, h.file),
        );
      },
    );
  }
}
