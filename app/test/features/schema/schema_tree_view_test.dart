import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/schema/presentation/schema_tree_view.dart';

class _FakeSchemaRepository implements SchemaRepository {
  @override
  Future<List<String>> listDatabases(
    String sessionId, {
    bool refresh = false,
  }) async => ['postgres'];

  @override
  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  }) async => ['public'];

  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    String? schema,
    bool refresh = false,
  }) async => const [
    SchemaObject(
      name: 'customers',
      type: SchemaObjectType.table,
      rowCountEstimate: 1250,
    ),
    SchemaObject(
      name: 'orders',
      type: SchemaObjectType.table,
      rowCountEstimate: 1000000,
    ),
  ];

  @override
  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  }) async => TableDetails(
    tableRef: tableRef,
    type: SchemaObjectType.table,
    canEdit: true,
    columns: const [
      ColumnDetails(
        name: 'id',
        typeName: 'int4',
        kind: ColumnKind.integer,
        nullable: false,
        isPrimaryKey: true,
      ),
      ColumnDetails(
        name: 'name',
        typeName: 'text',
        kind: ColumnKind.text,
        nullable: true,
        isPrimaryKey: false,
      ),
    ],
  );

  @override
  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]) async {}
}

class _TestConnectionSessionController extends ConnectionSessionController {
  _TestConnectionSessionController() : super('conn1');

  @override
  ConnectionSessionState build() {
    return const ConnectionSessionState(
      session: SessionInfo(
        id: 'sess-123',
        product: 'PostgreSQL',
        version: '16.0',
        capabilities: {'query'},
      ),
    );
  }
}

class _MongoSessionController extends ConnectionSessionController {
  _MongoSessionController() : super('conn1');

  @override
  ConnectionSessionState build() => const ConnectionSessionState(
    session: SessionInfo(
      id: 'sess-mongo',
      product: 'MongoDB',
      version: '8.0',
      capabilities: {'document_store', 'schema_graph'},
    ),
  );
}

void main() {
  group('SchemaTreeView widget tests', () {
    testWidgets('renders schema nodes, expands objects, and filters items', (
      tester,
    ) async {
      final fakeRepo = _FakeSchemaRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schemaRepositoryProvider.overrideWithValue(fakeRepo),
            connectionSessionProvider('conn1')
                .overrideWith(_TestConnectionSessionController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 260,
                child: SchemaTreeView(connectionId: 'conn1'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show database node
      expect(find.text('postgres'), findsOneWidget);

      // Tap database node to expand schemas
      await tester.tap(find.text('postgres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('public'), findsOneWidget);

      // Tap schema node to expand tables
      await tester.tap(find.text('public'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tables should now be visible with formatted row counts
      expect(find.text('customers'), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
      expect(find.text('~1.3k rows'), findsOneWidget);
      expect(find.text('~1M rows'), findsOneWidget);

      // Test filter as you type
      await tester.enterText(
        find.byKey(const Key('schema-tree-filter')),
        'cust',
      );
      await tester.pump();

      expect(find.text('customers'), findsOneWidget);
      expect(find.text('orders'), findsNothing);
    });

    testWidgets('a Mongo database offers its inferred diagram', (tester) async {
      final container = ProviderContainer(
        overrides: [
          schemaRepositoryProvider.overrideWithValue(_FakeSchemaRepository()),
          connectionSessionProvider('conn1')
              .overrideWith(_MongoSessionController.new),
          connectionHasSchemaGraphProvider('conn1').overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 260,
                child: SchemaTreeView(connectionId: 'conn1'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('postgres'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open diagram'));
      await tester.pumpAndSettle();

      final tab = container.read(editorTabsProvider).tabs.single;
      expect(tab.isDiagram, isTrue);
      expect(tab.tableRef?.database, 'postgres');
      expect(tab.tableRef?.schema, '');
    });
  });
}
