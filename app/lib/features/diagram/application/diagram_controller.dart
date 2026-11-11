import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../data/diagram_repository.dart';
import '../domain/diagram_layout.dart';
import '../domain/diagram_models.dart';

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

@immutable
class DiagramReady extends DiagramState {
  const DiagramReady({
    required this.graph,
    required this.rects,
    this.selected,
    this.layoutRevision = 0,
  });

  final SchemaGraph graph;

  /// Box of every table by name; changes when a table is dragged.
  final Map<String, Rect> rects;
  final String? selected;

  /// Grows when every box moved at once, so the view can fit the diagram again.
  final int layoutRevision;

  bool get isEmpty => graph.tables.isEmpty;

  Rect get bounds => DiagramLayout(rects).bounds;
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
    state = const DiagramLoading();
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
              _show(SchemaGraph(tables), revision: 0);
            }
            if (!done.isCompleted) done.complete();
          },
          cancelOnError: true,
        );
    await done.future;
  }

  /// Stops a running load and says so; a no-op once the diagram is shown.
  void cancel() {
    if (state is! DiagramLoading) return;
    _generation++;
    _stopLoading();
    state = const DiagramFailed('Cancelled');
  }

  void _show(SchemaGraph graph, {required int revision}) {
    state = DiagramReady(
      graph: graph,
      rects: layoutGraph(graph).rects,
      layoutRevision: revision,
    );
  }

  /// Puts every table back where the automatic layout places it.
  void relayout() {
    final current = state;
    if (current is DiagramReady) {
      _show(current.graph, revision: current.layoutRevision + 1);
    }
  }

  void select(String? table) {
    final current = state;
    if (current is! DiagramReady || current.selected == table) return;
    state = DiagramReady(
      graph: current.graph,
      rects: current.rects,
      selected: table,
      layoutRevision: current.layoutRevision,
    );
  }

  void moveTable(String table, Offset delta) {
    final current = state;
    if (current is! DiagramReady) return;
    final rect = current.rects[table];
    if (rect == null) return;
    state = DiagramReady(
      graph: current.graph,
      rects: {...current.rects, table: rect.shift(delta)},
      selected: table,
      layoutRevision: current.layoutRevision,
    );
  }
}
