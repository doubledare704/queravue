import 'package:flutter/foundation.dart';

enum CompletionContext { sql, shell, mongoQuery }

enum CompletionKind {
  unspecified,
  keyword,
  function,
  table,
  view,
  column,
  schema,
  database,
  alias,
  collection,
  field,
  operator,
  method,
  snippet,
}

enum CatalogState { unspecified, cold, warming, ready }

@immutable
class CompletionItem {
  const CompletionItem({
    required this.label,
    required this.kind,
    required this.insertText,
    required this.replaceStart,
    required this.replaceEnd,
    required this.sortKey,
    this.detail = '',
  });

  final String label;
  final CompletionKind kind;
  final String detail;
  final String insertText;

  /// Range of the request text the item replaces, in UTF-16 code units
  /// relative to the request text.
  final int replaceStart;
  final int replaceEnd;
  final String sortKey;
}

@immutable
class CompletionResult {
  const CompletionResult({
    this.items = const [],
    this.isIncomplete = false,
    this.catalogState = CatalogState.unspecified,
    this.error,
  });

  final List<CompletionItem> items;
  final bool isIncomplete;
  final CatalogState catalogState;
  final String? error;
}

@immutable
class CompletionRequest {
  const CompletionRequest({
    required this.sessionId,
    required this.context,
    required this.text,
    required this.cursorOffset,
    this.maxItems = 0,
    this.database = '',
    this.schema = '',
    this.collection = '',
  });

  final String sessionId;
  final CompletionContext context;
  final String text;
  final int cursorOffset;
  final int maxItems;
  final String database;
  final String schema;
  final String collection;
}

@immutable
class FormatSqlOptions {
  const FormatSqlOptions({
    this.keywordCase = KeywordCase.upper,
    this.indentWidth = 2,
    this.leadingCommas = false,
    this.maxLineWidth = 100,
  });

  final KeywordCase keywordCase;
  final int indentWidth;
  final bool leadingCommas;
  final int maxLineWidth;
}

enum KeywordCase { upper, lower, preserve }

@immutable
class FormatSqlResult {
  const FormatSqlResult({
    this.formattedText = '',
    this.replaceStart = 0,
    this.replaceEnd = 0,
    this.error,
    this.errorPosition,
  });

  final String formattedText;
  final int replaceStart;
  final int replaceEnd;
  final String? error;
  final int? errorPosition;
}
