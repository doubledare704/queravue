import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import 'core_connection.dart';
import 'core_providers.dart';
import 'gen/queravue/v1/querybuilder.pbgrpc.dart';

class QueryBuilderClient {
  QueryBuilderClient(this._connection);

  final CoreConnection? Function() _connection;

  static const _defaultTimeout = Duration(seconds: 15);

  CoreConnection get _conn {
    final conn = _connection();
    if (conn == null) throw StateError('Core is not connected');
    return conn;
  }

  Future<GenerateSqlResponse> generateSql(
    GenerateSqlRequest request, {
    Duration timeout = _defaultTimeout,
  }) => _conn.queryBuilderService.generateSql(
    request,
    options: CallOptions(timeout: timeout),
  );

  Future<ParseSqlResponse> parseSql(
    ParseSqlRequest request, {
    Duration timeout = _defaultTimeout,
  }) => _conn.queryBuilderService.parseSql(
    request,
    options: CallOptions(timeout: timeout),
  );
}

final queryBuilderClientProvider = Provider<QueryBuilderClient>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return QueryBuilderClient(() => supervisor.connection);
});
