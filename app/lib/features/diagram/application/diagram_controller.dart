import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../workspace/domain/workspace_models.dart';
import '../data/diagram_files.dart';
import '../data/diagram_repository.dart';
import '../domain/diagram_layout.dart';
import '../domain/diagram_models.dart';
import '../domain/saved_diagram.dart';

sealed class DiagramState {
  const DiagramState();
}

class DiagramLoading extends DiagramState {
  const DiagramLoading({this.tablesDone = 0, this.tablesTotal = 0});

  final int tablesDone;
  final int tablesTotal;
}

class DiagramFailed extends DiagramState {
  const DiagramFailed(this.message);

  final String message;
}

class DiagramReady extends DiagramState {
  DiagramReady({
    required this.graph,
    required this.rects,
    this.hidden = const {},
    this.selected,
    this.layoutRevision = 0,
    this.dirty = false,
    this.notice,
  }) : visibleGraph = hidden.isEmpty
           ? graph
           : SchemaGraph([
               for (final t in graph.tables)
                 if (!hidden.contains(t.name)) t,
             ]),
       visibleRects = hidden.isEmpty
           ? rects
           : {
               for (final e in rects.entries)
                 if (!hidden.contains(e.key)) e.key: e.value,
             };

  final SchemaGraph graph;

  /// Box of every table by name, hidden ones included, so a table comes
  /// back where it was.
  final Map<String, Rect> rects;
  final Set<String> hidden;
  final String? selected;

  /// Grows when every box moved at once, so the view can fit the diagram again.
  final int layoutRevision;

  /// Changed since it was loaded or saved.
  final bool dirty;

  /// Something the user should know about how the diagram was loaded.
  final String? notice;

  final SchemaGraph visibleGraph;
  final Map<String, Rect> visibleRects;

  bool get isEmpty => graph.tables.isEmpty;

  Rect get bounds => DiagramLayout(visibleRects).bounds;

  DiagramReady copyWith({
    Map<String, Rect>? rects,
    Set<String>? hidden,
    String? Function()? selected,
    int? layoutRevision,
    bool? dirty,
  }) => DiagramReady(
    graph: graph,
    rects: rects ?? this.rects,
    hidden: hidden ?? this.hidden,
    selected: selected == null ? this.selected : selected(),
    layoutRevision: layoutRevision ?? this.layoutRevision,
    dirty: dirty ?? this.dirty,
    notice: notice,
  );
}

/// The diagram of one diagram tab, by tab id.
final diagramProvider =
    NotifierProvider.family<DiagramController, DiagramState, String>(
      DiagramController.new,
    );

class DiagramController extends Notifier<DiagramState> {
  DiagramController(this.tabId);

  final String tabId;
  StreamSubscription<GraphBatch>? _loading;
  int _generation = 0;

  @override
  DiagramState build() {
    ref.onDispose(_stopLoading);
    unawaited(Future.microtask(load));
    return const DiagramLoading();
  }

  void _stopLoading() {
    unawaited(_loading?.cancel());
    _loading = null;
  }

  EditorTab? get _tab =>
      ref.read(editorTabsProvider).tabs.where((t) => t.id == tabId).firstOrNull;

  Future<void> load({bool refresh = false}) async {
    final generation = ++_generation;
    _stopLoading();
    final tab = _tab;
    if (tab == null) return;
    final shown = state;
    final previous = shown is DiagramReady ? shown : null;
    state = const DiagramLoading();
    final (saved, notice) = previous == null
        ? await _readSaved(tab)
        : (null, null);
    if (generation != _generation) return;
    final session = await ref
        .read(connectionSessionProvider(tab.connectionId).notifier)
        .connect();
    if (generation != _generation) return;
    if (session == null) {
      state = const DiagramFailed('Could not connect');
      return;
    }
    final tables = <DiagramTable>[];
    final done = Completer<void>();
    _loading = ref
        .read(diagramRepositoryProvider)
        .loadGraph(
          sessionId: session.id,
          database: tab.tableRef?.database ?? '',
          schema: tab.tableRef?.schema ?? '',
          refresh: refresh,
        )
        .listen(
          (batch) {
            if (generation != _generation) return;
            tables.addAll(batch.tables);
            state = DiagramLoading(
              tablesDone: batch.tablesDone,
              tablesTotal: batch.tablesTotal,
            );
          },
          onError: (Object e) {
            if (generation != _generation) return;
            state = DiagramFailed(
              e is DiagramFailure ? e.message : 'Loading the diagram failed',
            );
            done.complete();
          },
          onDone: () {
            if (generation == _generation && state is DiagramLoading) {
              _show(SchemaGraph(tables), saved, previous, notice);
            }
            if (!done.isCompleted) done.complete();
          },
          cancelOnError: true,
        );
    await done.future;
  }

  /// The tab's saved diagram. One that cannot be read is let go, so the
  /// schema still shows, with a notice that says why.
  Future<(SavedDiagram?, String?)> _readSaved(EditorTab tab) async {
    final file = tab.diagramFile;
    if (file == null) return (null, null);
    try {
      return (await ref.read(diagramFilesProvider).read(file), null);
    } on DiagramFailure catch (e) {
      ref
          .read(editorTabsProvider.notifier)
          .bindDiagram(
            tabId,
            null,
            'Diagram ${tab.tableRef?.schema ?? ''}'.trim(),
          );
      return (null, '${e.message}; showing the automatic layout.');
    }
  }

  /// Shows [graph] arranged as it was before a reload, else as [saved]
  /// says, else by the automatic layout.
  void _show(
    SchemaGraph graph,
    SavedDiagram? saved,
    DiagramReady? previous,
    String? notice,
  ) {
    final names = {for (final t in graph.tables) t.name};
    final positions = previous != null
        ? {for (final e in previous.rects.entries) e.key: e.value.topLeft}
        : saved?.positions ?? const <String, Offset>{};
    final hidden = previous?.hidden ?? saved?.hidden ?? const <String>{};
    state = DiagramReady(
      graph: graph,
      rects: positions.isEmpty
          ? layoutGraph(graph).rects
          : placeSaved(graph, positions),
      hidden: hidden.intersection(names),
      layoutRevision: previous?.layoutRevision ?? 0,
      dirty: previous?.dirty ?? false,
      notice: notice,
    );
  }

  /// Stops a running load and says so; a no-op once the diagram is shown.
  void cancel() {
    if (state is! DiagramLoading) return;
    _generation++;
    _stopLoading();
    state = const DiagramFailed('Cancelled');
  }

  DiagramReady? get _ready {
    final current = state;
    return current is DiagramReady ? current : null;
  }

  /// Puts every shown table where the automatic layout places it.
  void relayout() {
    final current = _ready;
    if (current == null) return;
    state = current.copyWith(
      rects: {...current.rects, ...layoutGraph(current.visibleGraph).rects},
      layoutRevision: current.layoutRevision + 1,
      dirty: true,
    );
  }

  void select(String? table) {
    final current = _ready;
    if (current == null || current.selected == table) return;
    state = current.copyWith(selected: () => table);
  }

  void moveTable(String table, Offset delta) {
    final current = _ready;
    final rect = current?.rects[table];
    if (current == null || rect == null) return;
    state = current.copyWith(
      rects: {...current.rects, table: rect.shift(delta)},
      selected: () => table,
      dirty: true,
    );
  }

  void hide(String table) {
    final current = _ready;
    if (current == null || current.hidden.contains(table)) return;
    state = current.copyWith(
      hidden: {...current.hidden, table},
      selected: () => current.selected == table ? null : current.selected,
      dirty: true,
    );
  }

  /// Shows hidden tables again: where they were, or beside the diagram when
  /// something has moved into their place since.
  void showAll() {
    final current = _ready;
    if (current == null || current.hidden.isEmpty) return;
    final shown = current.visibleRects.values;
    final blocked = [
      for (final t in current.graph.tables)
        if (current.hidden.contains(t.name) &&
            shown.any((r) => r.overlaps(current.rects[t.name]!)))
          t,
    ];
    state = current.copyWith(
      rects: {...current.rects, ...layoutBeside(blocked, current.bounds)},
      hidden: const {},
      dirty: true,
    );
  }

  /// What a saved file of this diagram holds.
  SavedDiagram? snapshot() {
    final current = _ready;
    final tab = _tab;
    if (current == null || tab == null) return null;
    final profile = ref
        .read(connectionsControllerProvider)
        .value
        ?.where((c) => c.id == tab.connectionId)
        .firstOrNull;
    return SavedDiagram(
      connectionId: tab.connectionId,
      connectionName: profile?.name ?? '',
      database: tab.tableRef?.database ?? '',
      schema: tab.tableRef?.schema ?? '',
      positions: {
        for (final e in current.rects.entries) e.key: e.value.topLeft,
      },
      hidden: current.hidden,
    );
  }

  /// Writes the diagram to [file] and binds the tab to it as [title].
  /// Throws [DiagramFailure].
  Future<void> saveTo(FilePath file, String title) async {
    final saved = snapshot();
    if (saved == null) throw const DiagramFailure('Nothing to save yet');
    await ref.read(diagramFilesProvider).write(file, saved);
    ref.read(editorTabsProvider.notifier).bindDiagram(tabId, file, title);
    final current = _ready;
    if (current != null) state = current.copyWith(dirty: false);
  }
}
