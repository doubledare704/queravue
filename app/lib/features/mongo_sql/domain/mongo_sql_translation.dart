import 'dart:convert';

import '../../documents/domain/models.dart';

enum MqlFormat { shell, ejson }

class MongoSqlDiagnostic {
  const MongoSqlDiagnostic(this.message, {this.byteOffset});

  final String message;
  final int? byteOffset;
}

enum MongoSqlErrorKind { parse, unsupportedConstruct, other }

class MongoSqlFailure implements Exception {
  const MongoSqlFailure(this.kind, this.diagnostic);

  final MongoSqlErrorKind kind;
  final MongoSqlDiagnostic diagnostic;
}

sealed class MongoSqlTranslation {
  const MongoSqlTranslation({
    required this.database,
    required this.collection,
    required this.shellCode,
    this.warnings = const [],
  });

  final String database;
  final String collection;
  final String shellCode;
  final List<MongoSqlDiagnostic> warnings;

  String get ejson;

  String inFormat(MqlFormat format) => switch (format) {
    MqlFormat.shell => shellCode,
    MqlFormat.ejson => ejson,
  };
}

final class MongoSqlFind extends MongoSqlTranslation {
  const MongoSqlFind({
    required super.database,
    required super.collection,
    required super.shellCode,
    super.warnings,
    required this.query,
  });

  final FindQuery query;

  @override
  String get ejson => const JsonEncoder.withIndent('  ').convert({
    'filter': jsonDecode(query.filter.isEmpty ? '{}' : query.filter),
    if (query.projection.isNotEmpty) 'projection': jsonDecode(query.projection),
    if (query.sort.isNotEmpty) 'sort': jsonDecode(query.sort),
    if (query.skip > 0) 'skip': {'\$numberLong': '${query.skip}'},
    if (query.limit > 0) 'limit': {'\$numberLong': '${query.limit}'},
  });
}

final class MongoSqlAggregate extends MongoSqlTranslation {
  const MongoSqlAggregate({
    required super.database,
    required super.collection,
    required super.shellCode,
    super.warnings,
    required this.pipelineEjson,
  });

  final String pipelineEjson;

  @override
  String get ejson =>
      const JsonEncoder.withIndent('  ').convert(jsonDecode(pipelineEjson));
}

String quoteMongoSqlIdentifier(String name) =>
    '"${name.replaceAll('"', '""')}"';
