import 'package:flutter/foundation.dart';

import 'ejson.dart';

/// Failure class of a document operation (mirrors DocumentErrorKind).
enum DocErrorKind {
  unspecified,
  parse,
  conflict,
  notFound,
  confirmationRequired,
  auth,
  network,
  timeout,
  canceled,
  unsupported,
  server,
}

/// Which request input a parse error refers to.
enum DocInput { none, filter, sort, projection, document }

/// A typed failure reported by the core.
@immutable
class DocumentError {
  const DocumentError({
    required this.kind,
    required this.message,
    this.input = DocInput.none,
    this.position,
    this.documentIndex,
    this.currentDocument,
  });

  final DocErrorKind kind;
  final String message;
  final DocInput input;

  /// For parse errors: UTF-16 offset in the input.
  final int? position;
  final int? documentIndex;

  /// For conflicts: the document as stored now, canonical EJSON; null if it
  /// was deleted.
  final String? currentDocument;

  @override
  String toString() => message;
}

/// Thrown by a [DocumentRepository] call that the core reported as failed.
class DocumentFailure implements Exception {
  const DocumentFailure(this.error);
  final DocumentError error;

  @override
  String toString() => error.message;
}

/// Filter, sort, projection and paging of a document query.
@immutable
class FindQuery {
  const FindQuery({
    this.filter = '',
    this.sort = '',
    this.projection = '',
    this.skip = 0,
    this.limit = 0,
  });

  final String filter;
  final String sort;
  final String projection;
  final int skip;

  /// Documents to fetch; 0 means no limit.
  final int limit;

  FindQuery copyWith({
    String? filter,
    String? sort,
    String? projection,
    int? skip,
    int? limit,
  }) => FindQuery(
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    projection: projection ?? this.projection,
    skip: skip ?? this.skip,
    limit: limit ?? this.limit,
  );

  @override
  bool operator ==(Object other) =>
      other is FindQuery &&
      other.filter == filter &&
      other.sort == sort &&
      other.projection == projection &&
      other.skip == skip &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(filter, sort, projection, skip, limit);
}

/// A group of documents from a Find stream.
@immutable
class DocBatch {
  const DocBatch({
    required this.offset,
    required this.documents,
    this.done = false,
  });

  final int offset;
  final List<String> documents;
  final bool done;
}

/// Result of Count.
@immutable
class CountResult {
  const CountResult({required this.count, required this.exact});
  final int count;
  final bool exact;
}

/// One sampled top-level field.
@immutable
class FieldStat {
  const FieldStat({
    required this.name,
    this.types = const [],
    this.frequency = 1,
  });

  final String name;

  /// `$type` aliases seen, most frequent first.
  final List<String> types;
  final double frequency;
}

/// A loaded document: canonical EJSON text, decoded lazily.
class DocItem {
  DocItem(this.text);

  /// Canonical EJSON as received from the core. Kept verbatim: it is the
  /// `expected_document` of an edit.
  final String text;

  Object? _value;
  bool _decoded = false;

  /// Decoded EJSON (wrapper maps preserved). Null if the text is invalid.
  Object? get value {
    if (!_decoded) {
      _decoded = true;
      try {
        _value = decodeEjson(text);
      } on FormatException {
        _value = null;
      }
    }
    return _value;
  }

  /// Canonical EJSON of `_id`, or null if the document has none (projected
  /// away).
  String? get idText {
    final v = value;
    if (v is Map && v.containsKey('_id')) return compactEjson(v['_id']);
    return null;
  }
}
