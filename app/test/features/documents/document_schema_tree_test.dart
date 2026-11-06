import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/schema/presentation/schema_tree_view.dart';

import '../../support/document_harness.dart';
import '../../support/fake_connections_repository.dart';
import '../../support/fake_document_repository.dart';
import '../../support/providers.dart';

class _MongoSchemaRepo implements SchemaRepository {
  final calls = <String>[];

  @override
  Future<List<String>> listDatabases(
    String sessionId, {
    bool refresh = false,
  }) async => ['shop'];

  @override
  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  }) async {
    calls.add('listSchemas');
    return const [];
  }

  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  }) async {
    calls.add('listObjects:$database:"$schema"');
    return const [
      SchemaObject(
        name: 'users',
        type: SchemaObjectType.collection,
        rowCountEstimate: 1250,
      ),
      SchemaObject(
        name: 'events',
        type: SchemaObjectType.collection,
        rowCountEstimate: 1000000,
      ),
      SchemaObject(name: 'paid.orders', type: SchemaObjectType.view),
      SchemaObject(
        name: 'audit',
        type: SchemaObjectType.collection,
        capped: true,
        rowCountEstimate: 1,
      ),
    ];
  }

  @override
  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  }) => throw StateError('collections are not described column by column');

  @override
  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]) async {}
}

class _MongoSession extends ConnectionSessionController {
  _MongoSession() : super('c1');

  @override
  ConnectionSessionState build() => const ConnectionSessionState(
    session: SessionInfo(
      id: 's1',
      product: 'MongoDB',
      version: '8.0',
      capabilities: {'connect', 'schema_inspector', 'document_store'},
    ),
  );
}

void main() {
  testWidgets('databases list collections directly and open document tabs', (
    tester,
  ) async {
    final repo = _MongoSchemaRepo();
    final c = ProviderContainer(
      overrides: [
        schemaRepositoryProvider.overrideWithValue(repo),
        connectionSessionProvider('c1').overrideWith(_MongoSession.new),
        ...documentOverrides(FakeDocumentRepository()),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: SingleChildScrollView(
                child: SchemaTreeView(connectionId: 'c1'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('shop'), findsOneWidget);
    await tester.tap(find.text('shop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // No schema level: collections come straight from listObjects(db, "").
    expect(repo.calls, ['listObjects:shop:""']);
    expect(find.text('users'), findsOneWidget);
    expect(find.text('~1.3k docs'), findsOneWidget);
    expect(find.text('~1M docs'), findsOneWidget);
    expect(find.text('paid.orders'), findsOneWidget);

    // A collection opens a document tab, not a table tab; names with dots work.
    await tester.tap(find.text('paid.orders'));
    await tester.pump();
    final tabs = c.read(editorTabsProvider).tabs;
    expect(tabs.single.isCollection, isTrue);
    expect(tabs.single.tableRef!.database, 'shop');
    expect(tabs.single.tableRef!.table, 'paid.orders');

    // Opening it again focuses the same tab.
    await tester.tap(find.text('paid.orders'));
    await tester.pump();
    expect(c.read(editorTabsProvider).tabs.length, 1);

    await tester.tap(find.text('users'));
    await tester.pump();
    expect(c.read(editorTabsProvider).tabs.length, 2);
    // Collections have no column children to expand.
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  test('document-only connections hide SQL entry points', () async {
    final fake = FakeConnectionsRepository(
      initial: [
        const ConnectionProfile(id: 'c1', name: 'M', engineId: 'mongodb'),
        const ConnectionProfile(id: 'c2', name: 'P', engineId: 'postgres'),
      ],
    )..engines = [mongoEngine, pgEngine];
    final c = makeContainer(fake);
    await c.read(connectionsControllerProvider.future);
    await c.read(enginesProvider.future);
    expect(c.read(connectionIsDocumentOnlyProvider('c1')), isTrue);
    expect(c.read(connectionIsDocumentOnlyProvider('c2')), isFalse);
    expect(c.read(connectionIsDocumentOnlyProvider('missing')), isFalse);
  });
}
