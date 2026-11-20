import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/mongo_sql/data/mongo_sql_repository.dart';
import 'package:queravue/features/mongo_sql/domain/mongo_sql_translation.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';

const findSql = "SELECT * FROM orders WHERE note = '😀' AND status IS NULL";
const warning = MongoSqlDiagnostic(
  'IS NULL also matches missing fields.',
  byteOffset: 52,
);
const findTranslation = MongoSqlFind(
  database: 'shop',
  collection: 'orders',
  shellCode: 'db.orders.find({status: null}).skip(2)',
  query: FindQuery(
    filter: '{"status":null}',
    sort: '{"status":{"\$numberInt":"1"}}',
    skip: 2,
  ),
  warnings: [warning],
);

const aggregateSql = 'SELECT COUNT(*) FROM orders';
const aggregate = MongoSqlAggregate(
  database: 'shop',
  collection: 'orders',
  shellCode: 'db.orders.aggregate([{\$group:{_id:null,n:{\$sum:1}}}])',
  pipelineEjson: '[{"\$group":{"_id":null,"n":{"\$sum":{"\$numberInt":"1"}}}}]',
);

const parseSql = "SELECT '😀'\nFROM ?";
const unsupportedSql = 'DELETE FROM orders';
const parseError = MongoSqlFailure(
  MongoSqlErrorKind.parse,
  MongoSqlDiagnostic('Expected a collection.', byteOffset: 19),
);
const unsupportedError = MongoSqlFailure(
  MongoSqlErrorKind.unsupportedConstruct,
  MongoSqlDiagnostic('Only SELECT is supported.', byteOffset: 0),
);

const aggregateCursor = ShellCursorEvent(
  CursorHandle(
    cursorId: 'orders-count',
    kind: CursorKind.aggregate,
    database: 'shop',
    collection: 'orders',
  ),
);

class FakeMongoSqlRepository implements MongoSqlRepository {
  final requests = <({String sessionId, String database, String sql})>[];
  final cancellations = <String>[];
  final responses = <String, Future<MongoSqlTranslation> Function()>{};

  @override
  Future<MongoSqlTranslation> translate({
    required String sessionId,
    required String database,
    required String sql,
    required Future<void> cancel,
  }) async {
    requests.add((sessionId: sessionId, database: database, sql: sql));
    cancel.then((_) => cancellations.add(sql)).ignore();
    if (responses[sql] case final response?) return response();
    return switch (sql) {
      aggregateSql => aggregate,
      parseSql => throw parseError,
      unsupportedSql => throw unsupportedError,
      _ => findTranslation,
    };
  }
}
