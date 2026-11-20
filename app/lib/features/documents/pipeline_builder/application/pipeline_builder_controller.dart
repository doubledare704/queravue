import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../connections/application/connection_session.dart';
import '../../../schema/data/schema_repository.dart';
import '../../application/document_preview_controller.dart';
import '../../data/document_repository.dart';
import '../domain/pipeline_codec.dart';
import '../domain/pipeline_stage.dart';
import '../domain/stage_forms.dart';

@immutable
class PipelineTarget {
  const PipelineTarget({
    required this.connectionId,
    required this.database,
    required this.collection,
  });

  final String connectionId;
  final String database;
  final String collection;

  @override
  bool operator ==(Object other) =>
      other is PipelineTarget &&
      other.connectionId == connectionId &&
      other.database == database &&
      other.collection == collection;

  @override
  int get hashCode => Object.hash(connectionId, database, collection);
}

@immutable
class PipelineBuilderState {
  const PipelineBuilderState({
    this.stages = const [],
    this.selectedId,
    this.previewLimit = kDefaultPreviewLimit,
    this.fieldNames = const [],
    this.collectionNames = const [],
    this.notice,
  });

  final List<PipelineStage> stages;
  final int? selectedId;
  final int previewLimit;
  final List<String> fieldNames;
  final List<String> collectionNames;
  final String? notice;

  PipelineBuilderState copyWith({
    List<PipelineStage>? stages,
    int? selectedId,
    bool clearSelection = false,
    int? previewLimit,
    List<String>? fieldNames,
    List<String>? collectionNames,
    String? notice,
    bool clearNotice = false,
  }) => PipelineBuilderState(
    stages: stages ?? this.stages,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    previewLimit: previewLimit ?? this.previewLimit,
    fieldNames: fieldNames ?? this.fieldNames,
    collectionNames: collectionNames ?? this.collectionNames,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

final pipelineBuilderProvider =
    NotifierProvider.family<
      PipelineBuilderController,
      PipelineBuilderState,
      PipelineTarget
    >(PipelineBuilderController.new);

class PipelineBuilderController extends Notifier<PipelineBuilderState> {
  PipelineBuilderController(this.target);

  final PipelineTarget target;

  String? _sessionId;

  DocumentPreviewController get _preview =>
      ref.read(documentPreviewProvider(target).notifier);

  @override
  PipelineBuilderState build() {
    unawaited(Future.microtask(_loadSuggestions));
    return const PipelineBuilderState();
  }

  Future<void> _loadSuggestions() async {
    final session = await _session();
    if (session == null || !ref.mounted) return;
    final collectionTarget = CollectionTarget(
      session,
      target.database,
      target.collection,
    );
    try {
      final sample = await ref
          .read(documentRepositoryProvider)
          .sampleFields(collectionTarget);
      if (ref.mounted) {
        state = state.copyWith(
          fieldNames: [for (final f in sample.fields) f.name],
        );
      }
    } on Object {
      // suggestions are optional
    }
    try {
      final objects = await ref
          .read(schemaRepositoryProvider)
          .listObjects(session, database: target.database, schema: '');
      if (ref.mounted) {
        state = state.copyWith(
          collectionNames: [for (final o in objects) o.name],
        );
      }
    } on Object {
      // suggestions are optional
    }
  }

  Future<String?> _session() async {
    if (_sessionId != null) return _sessionId;
    final session = await ref
        .read(connectionSessionProvider(target.connectionId).notifier)
        .connect();
    if (!ref.mounted || session == null) return null;
    if (!session.capabilities.contains('document_store')) return null;
    return _sessionId = session.id;
  }

  void _setStages(List<PipelineStage> stages, {int? select}) {
    _preview.reset();
    state = state.copyWith(
      stages: stages,
      selectedId: select,
      clearNotice: true,
    );
  }

  int _indexOf(int id) => state.stages.indexWhere((s) => s.id == id);

  void addStage(String operator, {int? afterId}) {
    final stage = PipelineStage.of(operator, defaultStageBody(operator));
    final stages = [...state.stages];
    final at = afterId == null ? stages.length : _indexOf(afterId) + 1;
    stages.insert(at, stage);
    _setStages(stages, select: stage.id);
  }

  void removeStage(int id) {
    final stages = [...state.stages]..removeWhere((s) => s.id == id);
    _preview.reset();
    state = state.copyWith(
      stages: stages,
      clearSelection: state.selectedId == id,
      clearNotice: true,
    );
  }

  void duplicateStage(int id) {
    final i = _indexOf(id);
    if (i < 0) return;
    final copy = state.stages[i].duplicate();
    _setStages([...state.stages]..insert(i + 1, copy), select: copy.id);
  }

  void setEnabled(int id, bool enabled) =>
      _replace(id, (s) => s.copyWith(enabled: enabled));

  void setOperator(int id, String operator) => _replace(
    id,
    (s) => s.copyWith(operator: operator, body: defaultStageBody(operator)),
  );

  void setBody(int id, Object? body) =>
      _replace(id, (s) => s.copyWith(body: body));

  void setRawText(int id, String text) => _replace(id, (s) {
    final parsed = _singleStage(text);
    return parsed == null
        ? s.withUnparsedText(text)
        : s.withContent(parsed.operator, parsed.body);
  });

  PipelineStage? _singleStage(String text) {
    try {
      final stages = importPipeline('[$text]').stages;
      return stages.length == 1 && !stages.single.isUnparsed
          ? stages.single
          : null;
    } on FormatException {
      return null;
    }
  }

  void setForm(int id, StageForm form) => setBody(id, form.toBody());

  void moveStage(int from, int to) {
    if (from < 0 || from >= state.stages.length) return;
    final stages = [...state.stages];
    final moved = stages.removeAt(from);
    stages.insert(to.clamp(0, stages.length), moved);
    _setStages(stages, select: state.selectedId);
  }

  void select(int id) {
    if (state.selectedId == id) return;
    _preview.reset();
    state = state.copyWith(selectedId: id);
  }

  void setPreviewLimit(int limit) =>
      state = state.copyWith(previewLimit: limit.clamp(1, 1000));

  void _replace(int id, PipelineStage Function(PipelineStage) change) {
    final i = _indexOf(id);
    if (i < 0) return;
    final stages = [...state.stages];
    stages[i] = change(stages[i]);
    _preview.reset();
    state = state.copyWith(stages: stages, clearNotice: true);
  }

  String exportJson() => pipelineToJson(state.stages);

  String exportShell() => pipelineToShell(target.collection, state.stages);

  bool importText(String text) {
    final PipelineImport imported;
    try {
      imported = importPipeline(text);
    } on FormatException catch (e) {
      state = state.copyWith(notice: e.message);
      return false;
    }
    final notes = [
      if (imported.keptAsRaw > 0)
        '${imported.keptAsRaw} stage(s) kept as raw text.',
      if (imported.ignoredTrailing) 'Text after the pipeline was ignored.',
      if (imported.collection != null &&
          imported.collection != target.collection)
        'The text names collection "${imported.collection}"; the builder keeps "${target.collection}".',
    ];
    _setStages(imported.stages);
    if (notes.isNotEmpty) state = state.copyWith(notice: notes.join(' '));
    return true;
  }

  List<PipelineStage> stagesUpTo(int id) {
    final end = _indexOf(id);
    if (end < 0) return const [];
    return [
      for (final s in state.stages.sublist(0, end + 1))
        if (s.enabled) s,
    ];
  }

  Future<void> runPreview(int id) async {
    if (ref.read(documentPreviewProvider(target)).running) return;
    select(id);
    final stages = stagesUpTo(id);
    final problem = _previewProblem(stages);
    if (problem != null) {
      _preview.fail(problem);
      return;
    }
    await _preview.runShell(
      connect: _session,
      database: target.database,
      limit: state.previewLimit,
      code: (limit) => pipelineToShell(target.collection, [
        ...stages,
        PipelineStage.of(r'$limit', limit),
      ]),
    );
  }

  String? _previewProblem(List<PipelineStage> stages) {
    if (stages.any((s) => s.isWrite)) {
      return r'Preview never runs $out or $merge. Select a stage before it.';
    }
    if (stages.any((s) => s.isUnparsed)) {
      return 'A stage before this one is not valid JSON. Fix or disable it first.';
    }
    return null;
  }
}
