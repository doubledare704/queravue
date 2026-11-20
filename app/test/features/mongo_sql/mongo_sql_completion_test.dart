import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:queravue/features/mongo_sql/data/mongo_sql_completion_repository.dart';

void main() {
  final collections = <MongoSqlCollectionScope>[];
  final samples = <MongoSqlFieldScope>[];
  final repository = MongoSqlCompletionRepository(
    listCollections: (scope) async {
      collections.add(scope);
      return ['orders', 'archived.orders'];
    },
    sampleFields: (scope) async {
      samples.add(scope);
      return ['address.city', 'display name'];
    },
  );

  Future<CompletionResult> complete(String sql, {int? cursor}) =>
      repository.complete(
        CompletionRequest(
          sessionId: 'session-1',
          context: CompletionContext.sql,
          database: 'shop',
          text: sql,
          cursorOffset: cursor ?? sql.length,
        ),
        cancel: Completer<void>().future,
      );

  test(
    'collection candidates come from the catalog with SQL identifier quoting',
    () async {
      const sql = 'SELECT * FROM /* collection */ arch';
      final result = await complete(sql);
      expect(collections.single, (session: 'session-1', database: 'shop'));
      final candidate = result.items.last;
      expect(candidate.kind, CompletionKind.collection);
      expect(candidate.insertText, '"archived.orders"');
      expect(candidate.replaceStart, sql.lastIndexOf('arch'));
    },
  );

  test('field candidates use the joined collection and preserve its qualifier', () async {
    const sql =
        'SELECT customer.address.c FROM orders JOIN customers AS customer ON orders.id = customer.id';
    final cursor = sql.indexOf(' FROM');
    final result = await complete(sql, cursor: cursor);
    expect(samples.single, (
      session: 'session-1',
      database: 'shop',
      collection: 'customers',
    ));
    expect(result.items.map((item) => item.insertText), [
      'address.city',
      '"display name"',
    ]);
    expect(result.items.first.replaceStart, sql.indexOf('address'));
  });

  test('strings and comments suppress completion', () async {
    expect(
      (await complete("SELECT * FROM orders WHERE name = 'FROM us")).items,
      isEmpty,
    );
    expect((await complete('SELECT * FROM orders -- FROM us')).items, isEmpty);
  });
}
