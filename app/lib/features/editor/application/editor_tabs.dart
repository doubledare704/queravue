import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../domain/query_models.dart';
import '../domain/text_offsets.dart';
import '../../schema/domain/schema_models.dart';
import 'query_run.dart';

/// Distinguishes between SQL query tabs and table browse tabs.
enum TabKind { query, table }

/// One workspace tab (SQL editor or Table browser/editor).
class EditorTab {
  EditorTab({
    required this.id,
    required this.connectionId,
    required this.title,
    this.kind = TabKind.query,
    this.tableRef,
    CodeLineEditingController? controller,
  }) : controller = controller ?? CodeLineEditingController();

  final String id;
  final String connectionId;
  final String title;
  final TabKind kind;
  final TableRef? tableRef;
  final CodeLineEditingController controller;

  bool get isQuery => kind == TabKind.query;
  bool get isTable => kind == TabKind.table;
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
