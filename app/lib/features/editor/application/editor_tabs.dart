import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../domain/query_models.dart';
import '../domain/text_offsets.dart';
import '../../schema/domain/schema_models.dart';
import 'query_run.dart';

/// Distinguishes between SQL query tabs and table browse tabs.
enum TabKind { query, table, collection, shell, designer }

/// One workspace tab (SQL editor or Table browser/editor).
class EditorTab {
  EditorTab({
    required this.id,
    required this.connectionId,
    required this.title,
    this.kind = TabKind.query,
    this.tableRef,
    this.newTable = false,
    this.shellDatabase = '',
    CodeLineEditingController? controller,
  }) : controller = controller ?? CodeLineEditingController();

  final String id;
  final String connectionId;
  final String title;
  final TabKind kind;
  final TableRef? tableRef;

  /// For a designer tab: the table does not exist yet.
  final bool newTable;
  final String shellDatabase;
  final CodeLineEditingController controller;

  bool get isQuery => kind == TabKind.query;
  bool get isTable => kind == TabKind.table;
  bool get isCollection => kind == TabKind.collection;
  bool get isShell => kind == TabKind.shell;
  bool get isDesigner => kind == TabKind.designer;

  /// The same tab, with its editor kept, under a new title.
  EditorTab withTitle(String newTitle) => EditorTab(
    id: id,
    connectionId: connectionId,
    title: newTitle,
    kind: kind,
    tableRef: tableRef,
    newTable: newTable,
    shellDatabase: shellDatabase,
    controller: controller,
  );
}

@immutable
class EditorTabsState {
  const EditorTabsState({
    this.tabs = const [],
    this.activeByConnection = const {},
  });

  final List<EditorTab> tabs;

  /// Active tab id per connection id.
  final Map<String, String> activeByConnection;

  List<EditorTab> tabsFor(String connectionId) => [
    for (final t in tabs)
      if (t.connectionId == connectionId) t,
  ];

  EditorTab? activeFor(String? connectionId) {
    if (connectionId == null) return null;
    final id = activeByConnection[connectionId];
    return tabs.where((t) => t.id == id).firstOrNull ??
        tabsFor(connectionId).firstOrNull;
  }
}

/// Editor tabs of all connections, and the run actions on them.
class EditorTabs extends Notifier<EditorTabsState> {
  int _seq = 0;

  // Not read from `state`: provider state is off limits during disposal.
  final List<EditorTab> _live = [];

  @override
  EditorTabsState build() {
    ref.onDispose(() {
      for (final t in _live) {
        t.controller.dispose();
      }
      _live.clear();
    });
    return const EditorTabsState();
  }

  /// Opens a new tab for [connectionId] and makes it active.
  EditorTab open(String connectionId) {
    final n = state.tabsFor(connectionId).length + 1;
    final tab = EditorTab(
      id: 'tab-${++_seq}',
      connectionId: connectionId,
      title: 'Query $n',
    );
    ref.read(queryRunProvider(tab.id).notifier).bind(connectionId);
    _live.add(tab);
    state = EditorTabsState(
      tabs: [...state.tabs, tab],
      activeByConnection: {...state.activeByConnection, connectionId: tab.id},
    );
    return tab;
  }

  /// Opens a Table tab for [connectionId] and [tableRef]. If already open, focuses it.
  EditorTab openTable(String connectionId, TableRef tableRef) {
    final existing = state.tabs
        .where(
          (t) =>
              t.isTable &&
              t.connectionId == connectionId &&
              t.tableRef == tableRef,
        )
        .firstOrNull;
    if (existing != null) {
      select(existing.id);
      return existing;
    }

    final tab = EditorTab(
      id: 'tab-${++_seq}',
      connectionId: connectionId,
      title: tableRef.table,
      kind: TabKind.table,
      tableRef: tableRef,
    );
    _live.add(tab);
    state = EditorTabsState(
      tabs: [...state.tabs, tab],
      activeByConnection: {...state.activeByConnection, connectionId: tab.id},
    );
    return tab;
  }

  /// Opens the table designer on [tableRef]; with [newTable] the ref names
  /// the schema and table to create. An existing table's designer is reused.
  EditorTab openDesigner(
    String connectionId,
    TableRef tableRef, {
    bool newTable = false,
  }) {
    if (!newTable) {
      final existing = state.tabs
          .where(
            (t) =>
                t.isDesigner &&
                !t.newTable &&
                t.connectionId == connectionId &&
                t.tableRef == tableRef,
          )
          .firstOrNull;
      if (existing != null) {
        select(existing.id);
        return existing;
      }
    }
    final tab = EditorTab(
      id: 'tab-${++_seq}',
      connectionId: connectionId,
      title: newTable ? 'New table' : 'Design ${tableRef.table}',
      kind: TabKind.designer,
      tableRef: tableRef,
      newTable: newTable,
    );
    _live.add(tab);
    state = EditorTabsState(
      tabs: [...state.tabs, tab],
      activeByConnection: {...state.activeByConnection, connectionId: tab.id},
    );
    return tab;
  }

  /// Opens a document tab for collection [ref] (`ref.database` and
  /// `ref.table`). If already open, focuses it.
  EditorTab openCollection(String connectionId, TableRef ref) {
    final existing = state.tabs
        .where(
          (t) =>
              t.isCollection &&
              t.connectionId == connectionId &&
              t.tableRef == ref,
        )
        .firstOrNull;
    if (existing != null) {
      select(existing.id);
      return existing;
    }
    final tab = EditorTab(
      id: 'tab-${++_seq}',
      connectionId: connectionId,
      title: ref.table,
      kind: TabKind.collection,
      tableRef: ref,
    );
    _live.add(tab);
    state = EditorTabsState(
      tabs: [...state.tabs, tab],
      activeByConnection: {...state.activeByConnection, connectionId: tab.id},
    );
    return tab;
  }

  /// Opens a Mongo shell tab for [connectionId] and makes it active.
  EditorTab openShell(String connectionId, {String database = ''}) {
    final n = state.tabsFor(connectionId).where((t) => t.isShell).length + 1;
    final tab = EditorTab(
      id: 'tab-${++_seq}',
      connectionId: connectionId,
      title: 'Shell $n',
      kind: TabKind.shell,
      shellDatabase: database,
    );
    _live.add(tab);
    state = EditorTabsState(
      tabs: [...state.tabs, tab],
      activeByConnection: {...state.activeByConnection, connectionId: tab.id},
    );
    return tab;
  }

  /// Renames a tab, e.g. after it was saved as a workspace file.
  void retitle(String tabId, String title) {
    final i = state.tabs.indexWhere((t) => t.id == tabId);
    if (i < 0 || state.tabs[i].title == title) return;
    final renamed = state.tabs[i].withTitle(title);
    final live = _live.indexWhere((t) => t.id == tabId);
    if (live >= 0) _live[live] = renamed;
    state = EditorTabsState(
      tabs: [...state.tabs]..[i] = renamed,
      activeByConnection: state.activeByConnection,
    );
  }

  /// Opens a Query tab populated with SQL text.
  EditorTab openQueryWithSql(String connectionId, String sql) {
    final tab = open(connectionId);
    tab.controller.text = sql;
    return tab;
  }

  /// Closes a tab: cancels its statement, closes its session and results.
  void close(String tabId) {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null) return;
    final remaining = [
      for (final t in state.tabs)
        if (t.id != tabId) t,
    ];
    final active = Map.of(state.activeByConnection);
    if (active[tab.connectionId] == tabId) {
      final siblings = [
        for (final t in remaining)
          if (t.connectionId == tab.connectionId) t,
      ];
      if (siblings.isEmpty) {
        active.remove(tab.connectionId);
      } else {
        active[tab.connectionId] = siblings.last.id;
      }
    }
    state = EditorTabsState(tabs: remaining, activeByConnection: active);
    ref.invalidate(queryRunProvider(tabId));
    // The editor widget may still be in the tree for this frame.
    _live.remove(tab);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => tab.controller.dispose(),
    );
  }

  /// Makes [tabId] the active tab of its connection.
  void select(String tabId) {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null) return;
    state = EditorTabsState(
      tabs: state.tabs,
      activeByConnection: {
        ...state.activeByConnection,
        tab.connectionId: tabId,
      },
    );
  }

  /// Runs statements of the tab's text. [mode] selects the statement at the
  /// cursor or all of them; with a non-empty selection, a cursor run runs the
  /// selection instead.
  Future<void> run(String tabId, ExecuteMode mode) async {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null) return;
    final c = tab.controller;
    final text = c.text;
    final lines = [
      for (var i = 0; i < c.codeLines.length; i++) c.codeLines[i].text,
    ];
    final sel = c.selection;
    final start = offsetOfPosition(lines, sel.startIndex, sel.startOffset);
    final end = offsetOfPosition(lines, sel.endIndex, sel.endOffset);
    var effective = mode;
    TextSpanRange? range;
    if (mode == ExecuteMode.statementAtCursor && end > start) {
      effective = ExecuteMode.selection;
    }
    if (effective == ExecuteMode.selection) range = TextSpanRange(start, end);
    await ref
        .read(queryRunProvider(tabId).notifier)
        .run(
          text: text,
          cursorOffset: offsetOfPosition(
            lines,
            sel.extentIndex,
            sel.extentOffset,
          ),
          mode: effective,
          selection: range,
        );
  }

  /// Cancels the tab's running statement.
  Future<void> cancel(String tabId) =>
      ref.read(queryRunProvider(tabId).notifier).cancel();
}

/// All editor tabs.
final editorTabsProvider = NotifierProvider<EditorTabs, EditorTabsState>(
  EditorTabs.new,
);
