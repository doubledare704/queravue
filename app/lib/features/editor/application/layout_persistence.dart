import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/panes/pane_sizes.dart';
import '../../connections/application/connections_controller.dart';
import '../../schema/domain/schema_models.dart';
import '../../workspace/application/tab_files.dart';
import '../../workspace/data/workspace_repository.dart';
import '../../workspace/domain/workspace_models.dart';
import '../domain/editor_layout.dart';
import 'editor_layout_controller.dart';
import 'editor_tabs.dart';

const layoutDir = '.queravue';
const layoutPath = '$layoutDir/layout.json';
const layoutFileVersion = 1;
const maxDraftChars = 200000;
const saveDelay = Duration(milliseconds: 800);

/// What a restored tab still has to load when it is first shown.
class _Unloaded {
  const _Unloaded({this.file, this.draft});
  final FilePath? file;
  final String? draft;
}

/// Saves the open query, shell and diagram tabs and how they are split to
/// `.queravue/layout.json` in the first workspace root, and puts them back on
/// the next start. Table, collection and designer tabs need a live session
/// and are not restored.
///
/// Restoring creates tabs without reading anything but the layout file; a
/// tab's file or draft is loaded the first time the tab is shown.
final layoutPersistenceProvider = Provider<LayoutPersistence>((ref) {
  final persistence = LayoutPersistence(ref);
  ref.onDispose(persistence.dispose);
  persistence.start();
  return persistence;
});

class LayoutPersistence {
  LayoutPersistence(this._ref);

  final Ref _ref;
  final _unloaded = <String, _Unloaded>{};
  Timer? _timer;
  bool _restoring = false;
  bool _restored = false;
  bool _disposed = false;

  WorkspaceRepository get _repo => _ref.read(workspaceRepositoryProvider);

  void start() {
    _ref.listen(coreReadyProvider, (_, ready) {
      if (ready) unawaited(restore());
    }, fireImmediately: true);
    for (final source in [
      editorTabsProvider,
      editorLayoutProvider,
      selectedConnectionProvider,
      paneSizesProvider,
    ]) {
      _ref.listen(source, (_, _) => _scheduleSave());
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }

  void _scheduleSave() {
    if (!_restored) return;
    _timer?.cancel();
    _timer = Timer(saveDelay, () => unawaited(flush()));
  }

  Future<void> restore() async {
    if (_restoring || _restored) return;
    _restoring = true;
    try {
      await _restoreFromFile();
    } on Object {
      // A missing or unreadable file means a fresh start.
    } finally {
      _restored = true;
      _restoring = false;
    }
  }

  Future<void> _restoreFromFile() async {
    final roots = await _repo.roots();
    if (roots.isEmpty) return;
    final file = await _repo.read(FilePath(roots.first.id, layoutPath));
    final json = jsonDecode(file.content);
    if (json is! Map<String, Object?> || json['version'] != layoutFileVersion) {
      return;
    }
    if (_disposed) return;
    if (json['panes'] != null) {
      _ref
          .read(paneSizesProvider.notifier)
          .restore(PaneSizes.fromJson(json['panes']));
    }
    final known = {
      for (final c in await _ref.read(connectionsControllerProvider.future))
        c.id,
    };
    if (_disposed || _ref.read(editorTabsProvider).tabs.isNotEmpty) return;
    final connections = json['connections'];
    if (connections is! Map<String, Object?>) return;
    final tabs = _ref.read(editorTabsProvider.notifier);
    for (final e in connections.entries) {
      final entry = e.value;
      if (!known.contains(e.key) || entry is! Map<String, Object?>) continue;
      final saved = entry['tabs'];
      if (saved is! List) continue;
      final ids = <String>[];
      for (final raw in saved) {
        final tab = _restoreTab(tabs, e.key, raw);
        if (tab != null) ids.add(tab);
      }
      final layout = EditorLayout.fromJson(entry['layout'], ids);
      if (layout != null && ids.isNotEmpty) {
        _ref.read(editorLayoutProvider.notifier).restore(e.key, layout);
      }
    }
    final selected = json['selected'];
    if (selected is String && known.contains(selected)) {
      _ref.read(selectedConnectionProvider.notifier).select(selected);
    }
  }

  String? _restoreTab(EditorTabs tabs, String connectionId, Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final kind = switch (raw['kind']) {
      'query' => TabKind.query,
      'shell' => TabKind.shell,
      'diagram' => TabKind.diagram,
      _ => null,
    };
    if (kind == null) return null;
    final fileJson = raw['file'];
    final file =
        fileJson is Map<String, Object?> &&
            fileJson['root'] is String &&
            fileJson['path'] is String
        ? FilePath(fileJson['root']! as String, fileJson['path']! as String)
        : null;
    if (kind == TabKind.diagram) {
      String text(String key) => raw[key] is String ? raw[key]! as String : '';
      return tabs
          .restoreTab(
            connectionId: connectionId,
            kind: kind,
            title: text('title').isEmpty ? 'Diagram' : text('title'),
            tableRef: TableRef(
              database: text('database'),
              schema: text('schema'),
              table: '',
            ),
            diagramFile: file,
          )
          .id;
    }
    final tab = tabs.restoreTab(
      connectionId: connectionId,
      kind: kind,
      title: raw['title'] is String ? raw['title']! as String : 'Query',
      shellDatabase: raw['database'] is String
          ? raw['database']! as String
          : '',
    );
    final draft = raw['draft'] is String ? raw['draft']! as String : null;
    if (file != null) {
      _unloaded[tab.id] = _Unloaded(file: file, draft: draft);
    } else if (draft != null) {
      tab.controller.text = draft;
    }
    return tab.id;
  }

  /// The restored tab that will show [file] once loaded, if there is one.
  String? unloadedTabFor(FilePath file) {
    for (final e in _unloaded.entries) {
      if (e.value.file == file) return e.key;
    }
    return null;
  }

  /// Loads the file or draft of a restored tab; a no-op for any other tab.
  Future<void> ensureLoaded(String tabId) async {
    final pending = _unloaded.remove(tabId);
    final file = pending?.file;
    if (pending == null || file == null) return;
    final tab = _ref
        .read(editorTabsProvider)
        .tabs
        .where((t) => t.id == tabId)
        .firstOrNull;
    if (tab == null) return;
    try {
      final content = await _repo.read(file);
      if (_disposed || !_tabIsOpen(tabId)) return;
      _ref.read(tabFileProvider(tabId).notifier).bind(file, content);
      tab.controller.text = pending.draft ?? content.content;
    } on Object {
      if (_tabIsOpen(tabId)) tab.controller.text = pending.draft ?? '';
    }
  }

  bool _tabIsOpen(String tabId) =>
      _ref.read(editorTabsProvider).tabs.any((t) => t.id == tabId);

  Map<String, Object?> snapshot() {
    final tabsState = _ref.read(editorTabsProvider);
    final layouts = _ref.read(editorLayoutProvider);
    final connections = <String, Object?>{};
    final byConnection = <String, List<EditorTab>>{};
    for (final t in tabsState.tabs) {
      if (t.isQuery || t.isShell || t.isDiagram) {
        byConnection.putIfAbsent(t.connectionId, () => []).add(t);
      }
    }
    for (final e in byConnection.entries) {
      final order = [for (final t in e.value) t.id];
      final layout = layouts.of(e.key).reconcile(tabIds: order);
      connections[e.key] = {
        'tabs': [for (final t in e.value) _tabJson(t)],
        'layout': layout.toJson(order),
      };
    }
    return {
      'version': layoutFileVersion,
      'selected': _ref.read(selectedConnectionProvider),
      'panes': _ref.read(paneSizesProvider).toJson(),
      'connections': connections,
    };
  }

  Map<String, Object?> _tabJson(EditorTab tab) {
    if (tab.isDiagram) {
      final file = tab.diagramFile;
      return {
        'kind': 'diagram',
        'title': tab.title,
        'database': tab.tableRef?.database ?? '',
        'schema': tab.tableRef?.schema ?? '',
        if (file != null) 'file': {'root': file.root, 'path': file.path},
      };
    }
    final pending = _unloaded[tab.id];
    final bound = _ref.read(tabFileProvider(tab.id));
    final file = pending?.file ?? bound?.file;
    String? draft;
    if (pending != null) {
      draft = pending.draft;
    } else {
      final text = tab.controller.text;
      final changed = bound == null ? text.isNotEmpty : text != bound.savedText;
      if (changed && text.length <= maxDraftChars) draft = text;
    }
    return {
      'kind': tab.isShell ? 'shell' : 'query',
      'title': tab.title,
      if (tab.isShell) 'database': tab.shellDatabase,
      if (file != null) 'file': {'root': file.root, 'path': file.path},
      'draft': ?draft,
    };
  }

  /// Writes the layout now. Called on a timer after changes and when the app
  /// quits.
  Future<void> flush() async {
    _timer?.cancel();
    if (!_restored || _disposed) return;
    final content =
        '${const JsonEncoder.withIndent('  ').convert(snapshot())}\n';
    try {
      final roots = await _repo.roots();
      if (roots.isEmpty) return;
      final file = FilePath(roots.first.id, layoutPath);
      try {
        await _repo.read(file);
        await _repo.write(file, content, force: true);
      } on Object {
        try {
          await _repo.create(FilePath(roots.first.id, layoutDir), isDir: true);
        } on Object {
          // The folder may already exist; creating the file reports real errors.
        }
        await _repo.create(file, content: content);
      }
    } on Object {
      // Not being able to save the layout must never disturb the editor.
    }
  }
}
