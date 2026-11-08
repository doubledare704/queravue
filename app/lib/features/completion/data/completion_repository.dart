import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/completion.pbgrpc.dart' as pb;
import '../../../core_client/gen/queravue/v1/query.pb.dart' as qpb;
import '../domain/completion_models.dart';

/// Completion and formatting through the core.
abstract interface class CompletionRepository {
  /// Asks for candidates. Completing [cancel] cancels the call in the core.
  Future<CompletionResult> complete(
    CompletionRequest request, {
    required Future<void> cancel,
  });

  Future<FormatSqlResult> formatSql({
    required String sessionId,
    required String text,
    FormatSqlOptions options,
    int? rangeStart,
    int? rangeEnd,
  });
}

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcCompletionRepository(() => supervisor.connection);
});

class GrpcCompletionRepository implements CompletionRepository {
  GrpcCompletionRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _timeout = Duration(seconds: 5);

  @override
  Future<CompletionResult> complete(
    CompletionRequest request, {
    required Future<void> cancel,
  }) async {
    final conn = _connection();
    if (conn == null) {
      return const CompletionResult(error: 'Core not connected');
    }
    final call = conn.completionService.complete(
      pb.CompleteRequest(
        sessionId: request.sessionId,
        kind: switch (request.context) {
          CompletionContext.sql =>
            pb.CompletionContextKind.COMPLETION_CONTEXT_KIND_SQL,
          CompletionContext.shell =>
            pb.CompletionContextKind.COMPLETION_CONTEXT_KIND_SHELL,
          CompletionContext.mongoQuery =>
            pb.CompletionContextKind.COMPLETION_CONTEXT_KIND_MONGO_QUERY,
        },
        text: request.text,
        cursorOffset: request.cursorOffset,
        maxItems: request.maxItems,
        database: request.database,
        schema: request.schema,
        collection: request.collection,
      ),
      options: CallOptions(timeout: _timeout),
    );
    unawaited(cancel.then((_) => call.cancel()));
    try {
      final resp = await call;
      if (resp.hasError()) return CompletionResult(error: resp.error.message);
      return CompletionResult(
        items: [for (final i in resp.items) _item(i)],
        isIncomplete: resp.isIncomplete,
        catalogState: switch (resp.catalogState) {
          pb.CatalogState.CATALOG_STATE_COLD => CatalogState.cold,
          pb.CatalogState.CATALOG_STATE_WARMING => CatalogState.warming,
          pb.CatalogState.CATALOG_STATE_READY => CatalogState.ready,
          _ => CatalogState.unspecified,
        },
      );
    } on GrpcError catch (e) {
      return CompletionResult(error: e.message ?? 'completion failed');
    }
  }

  CompletionItem _item(pb.CompletionItem i) => CompletionItem(
    label: i.label,
    kind: _kind(i.kind),
    detail: i.detail,
    insertText: i.insertText,
    replaceStart: i.replace.start,
    replaceEnd: i.replace.end,
    sortKey: i.sortKey,
  );

  static CompletionKind _kind(pb.CompletionItemKind k) => switch (k) {
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_KEYWORD =>
      CompletionKind.keyword,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_FUNCTION =>
      CompletionKind.function,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_TABLE => CompletionKind.table,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_VIEW => CompletionKind.view,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_COLUMN => CompletionKind.column,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_SCHEMA => CompletionKind.schema,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_DATABASE =>
      CompletionKind.database,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_ALIAS => CompletionKind.alias,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_COLLECTION =>
      CompletionKind.collection,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_FIELD => CompletionKind.field,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_OPERATOR =>
      CompletionKind.operator,
    pb.CompletionItemKind.COMPLETION_ITEM_KIND_METHOD => CompletionKind.method,
    _ => CompletionKind.unspecified,
  };

  @override
  Future<FormatSqlResult> formatSql({
    required String sessionId,
    required String text,
    FormatSqlOptions options = const FormatSqlOptions(),
    int? rangeStart,
    int? rangeEnd,
  }) async {
    final conn = _connection();
    if (conn == null) return const FormatSqlResult(error: 'Core not connected');
    final req = pb.FormatSQLRequest(
      sessionId: sessionId,
      text: text,
      options: pb.FormatOptions(
        keywordCase: switch (options.keywordCase) {
          KeywordCase.upper => pb.KeywordCase.KEYWORD_CASE_UPPER,
          KeywordCase.lower => pb.KeywordCase.KEYWORD_CASE_LOWER,
          KeywordCase.preserve => pb.KeywordCase.KEYWORD_CASE_PRESERVE,
        },
        indentWidth: options.indentWidth,
        commaStyle: options.leadingCommas
            ? pb.CommaStyle.COMMA_STYLE_LEADING
            : pb.CommaStyle.COMMA_STYLE_TRAILING,
        maxLineWidth: options.maxLineWidth,
      ),
    );
    if (rangeStart != null && rangeEnd != null) {
      req.range = qpb.TextRange(start: rangeStart, end: rangeEnd);
    }
    try {
      final resp = await conn.completionService.formatSQL(
        req,
        options: CallOptions(timeout: _timeout),
      );
      if (resp.hasError()) {
        return FormatSqlResult(
          error: resp.error.message,
          errorPosition: resp.error.hasPosition() ? resp.error.position : null,
        );
      }
      return FormatSqlResult(
        formattedText: resp.formattedText,
        replaceStart: resp.replacedRange.start,
        replaceEnd: resp.replacedRange.end,
      );
    } on GrpcError catch (e) {
      return FormatSqlResult(error: e.message ?? 'formatting failed');
    }
  }
}
