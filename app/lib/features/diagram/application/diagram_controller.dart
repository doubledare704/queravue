import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../workspace/domain/workspace_models.dart';
import '../data/diagram_files.dart';
import '../data/diagram_repository.dart';
import '../../admin/domain/admin_models.dart';
import '../../designer/domain/design_models.dart';
import '../domain/diagram_draft.dart';
import '../domain/diagram_layout.dart';
import '../domain/diagram_models.dart';
import '../domain/saved_diagram.dart';

sealed class DiagramState {
  const DiagramState();
}

class DiagramLoading extends DiagramState {
  const DiagramLoading({
    this.tablesDone = 0,
    this.tablesTotal = 0,
    this.collectionsSampled = 0,
  });

  final int tablesDone;
  final int tablesTotal;

  /// Collections sampled so far, on document stores, before tables arrive.
  final int collectionsSampled;

  bool get isSampling => collectionsSampled > 0 && tablesDone == 0;
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
    this.draft = const DiagramDraft(),
    this.showInferred = true,
    SchemaGraph? drawn,
  }) : drawnGraph = drawn ?? graphWithDraft(graph, draft) {
    final related = showInferred
        ? drawnGraph
        : drawnGraph.withoutInferredRelations();
    visibleGraph = hidden.isEmpty
        ? related
        : SchemaGraph([
            for (final t in related.tables)
              if (!hidden.contains(t.name)) t,
          ]);
    visibleRects = hidden.isEmpty
        ? rects
        : {
            for (final e in rects.entries)
              if (!hidden.contains(e.key)) e.key: e.value,
          };
  }

  /// The schema as the database has it.
  final SchemaGraph graph;

  /// Box of every table by name, hidden and drafted ones included, so a
  /// table comes back where it was.
  final Map<String, Rect> rects;
  final Set<String> hidden;
  final String? selected;

  /// Grows when every box moved at once, so the view can fit the diagram again.
  final int layoutRevision;

  /// Changed since it was loaded or saved.
  final bool dirty;

  /// Something the user should know about how the diagram was loaded.
  final String? notice;

  final DiagramDraft draft;

  /// Draws the relations core guessed from sampled documents.
  final bool showInferred;

  /// [graph] with the draft drawn in.
  final SchemaGraph drawnGraph;

  late final SchemaGraph visibleGraph;
  late final Map<String, Rect> visibleRects;

  bool get isEmpty => graph.tables.isEmpty && draft.tables.isEmpty;

  Rect get bounds => DiagramLayout(visibleRects).bounds;

  DiagramTable? table(String name) =>
      drawnGraph.tables.where((t) => t.name == name).firstOrNull;

  DiagramReady copyWith({
    Map<String, Rect>? rects,
    Set<String>? hidden,
    String? Function()? selected,
    int? layoutRevision,
    bool? dirty,
    DiagramDraft? draft,
    bool? showInferred,
  }) => DiagramReady(
    graph: graph,
    rects: rects ?? this.rects,
    hidden: hidden ?? this.hidden,
    selected: selected == null ? this.selected : selected(),
    layoutRevision: layoutRevision ?? this.layoutRevision,
    dirty: dirty ?? this.dirty,
    notice: notice,
    draft: draft ?? this.draft,
    showInferred: showInferred ?? this.showInferred,
    drawn: draft == null ? drawnGraph : null,
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
              collectionsSampled: batch.collectionsSampled,
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
              _show(
                withExternalTables(SchemaGraph(tables)),
                saved,
                previous,
                notice,
              );
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
    final draft = _withoutBuiltTables(
      previous?.draft ?? saved?.draft ?? const DiagramDraft(),
      names,
    );
    final drawn = graphWithDraft(graph, draft);
    state = DiagramReady(
      graph: graph,
      rects: positions.isEmpty
          ? layoutGraph(drawn).rects
          : placeSaved(drawn, positions),
      hidden: hidden.intersection({
        ...names,
        ...draft.tables.map((t) => t.name),
      }),
      layoutRevision: previous?.layoutRevision ?? 0,
      dirty: previous?.dirty ?? false,
      notice: notice,
      draft: draft,
      showInferred: previous?.showInferred ?? !(saved?.hideInferred ?? false),
      drawn: drawn,
    );
  }

  /// A drafted table that now exists in the database is dropped from the
  /// draft, with the relations it would have created.
  DiagramDraft _withoutBuiltTables(DiagramDraft draft, Set<String> existing) {
    var out = draft;
    for (final t in draft.tables) {
      if (existing.contains(t.name)) out = out.withoutTable(t.name);
    }
    return out;
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

  void showInferredRelations(bool show) {
    final current = _ready;
    if (current == null || current.showInferred == show) return;
    state = current.copyWith(showInferred: show, dirty: true);
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
      draft: current.draft,
      hideInferred: !current.showInferred,
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

  /// Every table name on the diagram, drafted ones included.
  Set<String> get tableNames {
    final current = _ready;
    if (current == null) return const {};
    return {for (final t in current.drawnGraph.tables) t.name};
  }

  /// Adds [table] to the draft centred near [at] where nothing else is, or
  /// beside the diagram.
  void addDraftTable(DraftTable table, {Offset? at}) {
    final current = _ready;
    if (current == null) return;
    final draft = current.draft.withTable(table);
    final drawn = graphWithDraft(current.graph, draft);
    final box = drawn.tables.last;
    final size = tableSize(box);
    final rect = at != null
        ? freeSpot(
            at - size.center(Offset.zero) & size,
            current.visibleRects.values,
          )
        : layoutBeside([box], current.bounds)[box.name]!;
    _setDraft(current, draft, {...current.rects, table.name: rect}, table.name);
  }

  void replaceDraftTable(String name, DraftTable table) {
    final current = _ready;
    final rect = current?.rects[name];
    if (current == null || rect == null) return;
    final rects = {...current.rects}..remove(name);
    rects[table.name] = rect;
    _setDraft(
      current,
      current.draft.withTable(table, replacing: name),
      rects,
      table.name,
    );
  }

  void removeDraftTable(String name) {
    final current = _ready;
    if (current == null) return;
    _setDraft(
      current,
      current.draft.withoutTable(name),
      {...current.rects}..remove(name),
      current.selected == name ? null : current.selected,
    );
  }

  void addDraftRelation(DraftRelation relation) {
    final current = _ready;
    if (current == null) return;
    _setDraft(
      current,
      current.draft.withRelation(relation),
      current.rects,
      relation.fromTable,
    );
  }

  void removeDraftRelation(DraftRelation relation) {
    final current = _ready;
    if (current == null) return;
    _setDraft(
      current,
      current.draft.withoutRelation(relation),
      current.rects,
      current.selected,
    );
  }

  void discardDraft() {
    final current = _ready;
    if (current == null || current.draft.isEmpty) return;
    final rects = {...current.rects};
    for (final t in current.draft.tables) {
      rects.remove(t.name);
    }
    _setDraft(current, const DiagramDraft(), rects, null);
  }

  /// Box sizes follow the drawn tables, which grow and shrink with drafted
  /// columns.
  void _setDraft(
    DiagramReady current,
    DiagramDraft draft,
    Map<String, Rect> rects,
    String? selected,
  ) {
    final drawn = graphWithDraft(current.graph, draft);
    final sized = {...rects};
    for (final t in drawn.tables) {
      final rect = sized[t.name];
      if (rect != null) sized[t.name] = rect.topLeft & tableSize(t);
    }
    state = DiagramReady(
      graph: current.graph,
      rects: sized,
      hidden: current.hidden.intersection(sized.keys.toSet()),
      selected: selected,
      layoutRevision: current.layoutRevision,
      dirty: true,
      notice: current.notice,
      draft: draft,
      showInferred: current.showInferred,
      drawn: drawn,
    );
  }

  List<TableChangesModel> get _draftChanges {
    final current = _ready;
    final tab = _tab;
    if (current == null || tab == null) return const [];
    return draftChanges(
      current.draft,
      database: tab.tableRef?.database ?? '',
      schema: tab.tableRef?.schema ?? '',
    );
  }

  Future<String?> _sessionId() async {
    final tab = _tab;
    if (tab == null) return null;
    final session = await ref
        .read(connectionSessionProvider(tab.connectionId).notifier)
        .connect();
    return session?.id;
  }

  static const _notConnected = AdminResult<Never>.failed(
    AdminError(kind: AdminErrorKind.server, message: 'Could not connect'),
  );

  Future<AdminResult<DdlPreview>> previewDraft() async {
    final session = await _sessionId();
    if (session == null) return _notConnected;
    return ref
        .read(diagramRepositoryProvider)
        .previewDdl(session, _draftChanges);
  }

  /// Runs the draft's DDL; once it ran, the draft is cleared and the schema
  /// read again, keeping where the new tables were drawn.
  Future<AdminResult<DdlApplied>> applyDraft({bool confirmed = false}) async {
    final session = await _sessionId();
    if (session == null) return _notConnected;
    final result = await ref
        .read(diagramRepositoryProvider)
        .applyDdl(session, _draftChanges, confirmed: confirmed);
    final current = _ready;
    if (result.isOk && current != null) {
      state = current.copyWith(draft: const DiagramDraft());
      await load(refresh: true);
    }
    return result;
  }
}
