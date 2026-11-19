import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/document.pb.dart' as doc;
import '../../../core_client/gen/queravue/v1/querybuilder.pb.dart' as pb;
import '../../../core_client/query_builder_client.dart';
import '../application/document_preview_controller.dart';
import '../application/document_tab_controller.dart';
import '../data/document_repository.dart';
import '../domain/models.dart';

class FilterBuilderState {
  const FilterBuilderState({
    this.open = false,
    this.loading = false,
    this.model,
    this.error,
    this.cannotShow = false,
    this.fields = const [],
    this.output,
    this.previewQuery,
    this.revision = 0,
  });
  final bool open;
  final bool loading;
  final pb.MongoFindModel? model;
  final String? error;
  final bool cannotShow;
  final List<doc.FieldPathStat> fields;
  final pb.GenerateMongoQueryResponse? output;
  final FindQuery? previewQuery;
  final int revision;
}

final filterBuilderProvider =
    NotifierProvider.family<
      FilterBuilderController,
      FilterBuilderState,
      String
    >(FilterBuilderController.new);

class FilterBuilderController extends Notifier<FilterBuilderState> {
  FilterBuilderController(this.tabId);
  final String tabId;
  int _sequence = 0;
  int _revision = 0;
  int _sampleSequence = 0;
  ResponseFuture<dynamic>? _call;
  ResponseFuture<doc.SampleFieldPathsResponse>? _sample;
  QueryBuilderClient get _client => ref.read(queryBuilderClientProvider);

  @override
  FilterBuilderState build() {
    ref.onDispose(() {
      _call?.cancel();
      _sample?.cancel();
    });
    return const FilterBuilderState();
  }

  void close() {
    _sequence++;
    _sampleSequence++;
    unawaited(_call?.cancel());
    _sample?.cancel();
    state = const FilterBuilderState();
  }

  Future<void> open(
    String filter,
    String projection,
    String sort,
    String? sessionId,
    String database,
    String collection,
  ) async {
    state = const FilterBuilderState(open: true, loading: true);
    final sampleSequence = ++_sampleSequence;
    final parsing = parse(filter, projection, sort);
    if (sessionId != null) {
      try {
        final connection = ref.read(coreSupervisorProvider).connection;
        final call = connection?.documentService.sampleFieldPaths(
          doc.SampleFieldPathsRequest(
            sessionId: sessionId,
            database: database,
            collection: collection,
          ),
        );
        _sample = call;
        final response = await call;
        if (!ref.mounted || !state.open || sampleSequence != _sampleSequence) {
          return;
        }
        state = FilterBuilderState(
          open: true,
          loading: state.loading,
          model: state.model,
          error: state.error,
          cannotShow: state.cannotShow,
          output: state.output,
          previewQuery: state.previewQuery,
          revision: state.revision,
          fields: response?.paths.toList() ?? [],
        );
      } catch (_) {}
    }
    await parsing;
  }

  Future<void> parse(String filter, String projection, String sort) async {
    if (!state.open) return;
    if (!state.loading) {
      state = FilterBuilderState(
        open: true,
        loading: true,
        fields: state.fields,
      );
    }
    final seq = ++_sequence;
    unawaited(_call?.cancel());
    try {
      final call = _client.parseMongoQuery(
        pb.ParseMongoQueryRequest(
          filterEjson: filter,
          projectionEjson: projection,
          sortEjson: sort,
        ),
      );
      _call = call;
      final response = await call;
      if (!ref.mounted || seq != _sequence) return;
      if (response.hasError()) {
        final kind = response.error.kind;
        state = FilterBuilderState(
          open: true,
          error: response.error.message,
          cannotShow:
              kind == pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_PARSE ||
              kind ==
                  pb
                      .QueryBuilderErrorKind
                      .QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT,
          fields: state.fields,
        );
      } else {
        state = FilterBuilderState(
          open: true,
          model: response.model,
          previewQuery: FindQuery(
            filter: filter,
            projection: projection,
            sort: sort,
          ),
          fields: state.fields,
          revision: ++_revision,
        );
      }
    } catch (e) {
      if (ref.mounted && seq == _sequence) {
        state = FilterBuilderState(
          open: true,
          error: e.toString(),
          fields: state.fields,
        );
      }
    }
  }

  Future<void> update(
    pb.MongoFindModel model, {
    bool resetFields = false,
  }) async {
    final seq = ++_sequence;
    unawaited(_call?.cancel());
    state = FilterBuilderState(
      open: true,
      model: model,
      fields: state.fields,
      revision: resetFields ? ++_revision : state.revision,
    );
    try {
      final call = _client.generateMongoQuery(
        pb.GenerateMongoQueryRequest(model: model),
      );
      _call = call;
      final response = await call;
      if (!ref.mounted || seq != _sequence) return;
      state = FilterBuilderState(
        open: true,
        model: model,
        fields: state.fields,
        error: response.hasError() ? response.error.message : null,
        output: response.hasError() ? null : response,
        previewQuery: response.hasError()
            ? null
            : FindQuery(
                filter: response.filterEjson,
                projection: response.projectionEjson,
                sort: response.sortEjson,
              ),
        revision: state.revision,
      );
    } catch (e) {
      if (ref.mounted && seq == _sequence) {
        state = FilterBuilderState(
          open: true,
          model: model,
          fields: state.fields,
          error: e.toString(),
          revision: state.revision,
        );
      }
    }
  }

  Future<void> runPreview() async {
    final query = state.previewQuery;
    final tab = ref.read(documentTabProvider(tabId));
    final sessionId = tab.sessionId;
    if (!state.open || query == null || sessionId == null) return;
    await ref
        .read(documentPreviewProvider(tabId).notifier)
        .runFind(
          CollectionTarget(sessionId, tab.database, tab.collection),
          query.copyWith(skip: tab.draft.skip, limit: tab.draft.limit),
        );
  }
}
