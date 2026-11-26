import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/gen/queravue/v1/querybuilder.pb.dart' as pb;
import '../../../core_client/query_builder_client.dart';
import '../../documents/domain/models.dart';
import '../domain/mongo_sql_translation.dart';

abstract interface class MongoSqlRepository {
  Future<MongoSqlTranslation> translate({
    required String sessionId,
    required String database,
    required String sql,
    required Future<void> cancel,
  });
}

final mongoSqlRepositoryProvider = Provider<MongoSqlRepository>(
  (ref) => GrpcMongoSqlRepository(ref.watch(queryBuilderClientProvider)),
);

class GrpcMongoSqlRepository implements MongoSqlRepository {
  GrpcMongoSqlRepository(this._client);

  final QueryBuilderClient _client;

  @override
  Future<MongoSqlTranslation> translate({
    required String sessionId,
    required String database,
    required String sql,
    required Future<void> cancel,
  }) async {
    try {
      final call = _client.translateMongoSql(
        pb.TranslateMongoSqlRequest(
          sessionId: sessionId,
          database: database,
          sql: sql,
        ),
      );
      cancel.then((_) => call.cancel()).ignore();
      return _translation(await call);
    } on GrpcError catch (e) {
      throw MongoSqlFailure(
        MongoSqlErrorKind.other,
        MongoSqlDiagnostic(e.message ?? 'Translation failed.'),
      );
    }
  }
}

MongoSqlTranslation _translation(pb.TranslateMongoSqlResponse response) {
  if (response.hasError()) {
    final error = response.error;
    final kind = switch (error.kind) {
      pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_PARSE =>
        MongoSqlErrorKind.parse,
      pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT =>
        MongoSqlErrorKind.unsupportedConstruct,
      _ => MongoSqlErrorKind.other,
    };
    throw MongoSqlFailure(
      kind,
      MongoSqlDiagnostic(
        error.message,
        byteOffset: error.hasOffset() ? error.offset : null,
      ),
    );
  }

  final warnings = [
    for (final warning in response.warnings)
      MongoSqlDiagnostic(
        warning.message,
        byteOffset: warning.hasOffset() ? warning.offset : null,
      ),
  ];
  return switch (response.kind) {
    pb.MongoSqlResultKind.MONGO_SQL_RESULT_KIND_FIND => MongoSqlFind(
      database: response.database,
      collection: response.collection,
      shellCode: response.shellCode,
      warnings: warnings,
      query: FindQuery(
        filter: response.filterEjson,
        projection: response.projectionEjson,
        sort: response.sortEjson,
        skip: response.skip.toInt(),
        limit: response.limit.toInt(),
      ),
    ),
    pb.MongoSqlResultKind.MONGO_SQL_RESULT_KIND_AGGREGATE => MongoSqlAggregate(
      database: response.database,
      collection: response.collection,
      shellCode: response.shellCode,
      warnings: warnings,
      pipelineEjson: response.pipelineEjson,
    ),
    _ => throw const MongoSqlFailure(
      MongoSqlErrorKind.other,
      MongoSqlDiagnostic('Core returned an unknown translation kind.'),
    ),
  };
}
