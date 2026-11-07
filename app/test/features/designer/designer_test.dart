import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/designer/data/design_repository.dart';
import 'package:queravue/features/designer/domain/design_models.dart';
import 'package:queravue/features/designer/presentation/designer_tab_view.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';
import '../../support/shell_workspace_fakes.dart';

class _OrdersSchema extends EmptySchemaRepository {
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
        typeName: 'integer',
        kind: ColumnKind.integer,
        nullable: false,
        isPrimaryKey: true,
        identity: true,
      ),
      ColumnDetails(
        name: 'note',
        typeName: 'text',
        kind: ColumnKind.text,
        nullable: true,
        isPrimaryKey: false,
      ),
    ],
  );
}

class _FakeDesign implements DesignRepository {
  bool destructive = false;
  final previews = <List<SchemaChangeModel>>[];
  final applied = <List<SchemaChangeModel>>[];
  final confirmations = <bool>[];

  DdlPreview _preview() => DdlPreview(
    statements: [
      DdlStatementModel(
        sql: 'ALTER TABLE t DO SOMETHING;',
        destructive: destructive,
        summary: 'Do something',
      ),
    ],
    warnings: const ['Careful.'],
    transactional: false,
  );

  @override
  Future<AdminResult<DdlPreview>> preview(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes,
  ) async {
    previews.add(changes);
    return AdminResult.ok(_preview());
  }

  @override
  Future<AdminResult<DdlApplied>> apply(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes, {
    bool confirmed = false,
  }) async {
    applied.add(changes);
    confirmations.add(confirmed);
    return AdminResult.ok(
      DdlApplied(
        statements: _preview().statements,
        executed: 1,
        transactional: false,
      ),
    );
  }
}

ColumnDraft _col(
  String name,
  String type, {
  bool nullable = true,
  String? original,
}) => ColumnDraft(
  name: name,
  typeName: type,
  nullable: nullable,
  originalName: original ?? name,
);

Future<(ProviderContainer, EditorTab, _FakeDesign)> _open(
  WidgetTester tester, {
  bool newTable = false,
}) async {
  final design = _FakeDesign();
  final container = ProviderContainer(
    overrides: [
      designRepositoryProvider.overrideWithValue(design),
      schemaRepositoryProvider.overrideWithValue(_OrdersSchema()),
      queryRepositoryProvider.overrideWithValue(FakeQueryRepository()),
      ...fakeCoreOverrides(
        FakeConnectionsRepository(
          initial: [
            const ConnectionProfile(id: 'c1', name: 'DB', engineId: 'postgres'),
          ],
        )..engines = [pgEngine],
      ),
    ],
  );
  addTearDown(container.dispose);
  final tab = container
      .read(editorTabsProvider.notifier)
      .openDesigner(
        'c1',
        const TableRef(schema: 'public', table: 'orders'),
        newTable: newTable,
      );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: DesignerTabView(tab: tab)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, tab, design);
}

void main() {
  group('diffDesign', () {
    final original = TableDetails(
      tableRef: const TableRef(table: 'orders'),
      type: SchemaObjectType.table,
      canEdit: true,
      columns: const [
        ColumnDetails(
          name: 'id',
          typeName: 'integer',
          kind: ColumnKind.integer,
          nullable: false,
          isPrimaryKey: true,
        ),
        ColumnDetails(
          name: 'note',
          typeName: 'text',
          kind: ColumnKind.text,
          nullable: true,
          isPrimaryKey: false,
        ),
        ColumnDetails(
          name: 'old',
          typeName: 'text',
          kind: ColumnKind.text,
          nullable: true,
          isPrimaryKey: false,
        ),
      ],
    );

    test('a new table is one create', () {
      final changes = diffDesign(columns: [_col('id', 'integer')]);
      expect(changes.single, isA<CreateTableChange>());
    });

    test('unchanged columns produce nothing', () {
      final columns = [
        _col('id', 'integer', nullable: false),
        _col('note', 'text'),
        _col('old', 'text'),
      ];
      expect(diffDesign(original: original, columns: columns), isEmpty);
    });

    test('orders renames, alters, adds, then drops', () {
      final columns = [
        _col('id', 'integer', nullable: false),
        _col('remark', 'varchar(20)', original: 'note'),
        const ColumnDraft(name: 'extra', typeName: 'int'),
      ];
      final changes = diffDesign(original: original, columns: columns);
      expect(changes.map((c) => c.runtimeType), [
        RenameColumnChange,
        AlterColumnChange,
        AddColumnChange,
        DropColumnChange,
      ]);
      expect((changes[0] as RenameColumnChange).to, 'remark');
      expect((changes[1] as AlterColumnChange).after.typeName, 'varchar(20)');
      expect((changes[3] as DropColumnChange).name, 'old');
    });
  });

  testWidgets('designs a new table and applies it after review', (
    tester,
  ) async {
    final (_, _, design) = await _open(tester, newTable: true);

    await tester.enterText(
      find.byKey(const Key('designer-table-name')),
      'customers',
    );
    await tester.tap(find.byKey(const Key('designer-add-column')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('col-name-1')), 'name');
    await tester.enterText(find.byKey(const Key('col-type-1')), 'text');
    await tester.pump();

    await tester.tap(find.byKey(const Key('designer-review')));
    await tester.pumpAndSettle();
    expect(find.text('ALTER TABLE t DO SOMETHING;'), findsOneWidget);
    expect(find.text('Careful.'), findsOneWidget);
    expect(
      find.text(
        'Each statement commits as it runs: a failure leaves earlier ones applied.',
      ),
      findsOneWidget,
    );
    expect(design.applied, isEmpty);

    await tester.tap(find.byKey(const Key('ddl-apply')));
    await tester.pumpAndSettle();
    final create = design.applied.single.single as CreateTableChange;
    expect(create.columns.map((c) => c.name), ['id', 'name']);
    expect(create.columns.first.primaryKey, isTrue);
    expect(design.confirmations, [true]);
  });

  testWidgets('a nameless table is not sent', (tester) async {
    final (_, _, design) = await _open(tester, newTable: true);
    await tester.tap(find.byKey(const Key('designer-review')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a table name.'), findsOneWidget);
    expect(design.previews, isEmpty);
  });

  testWidgets('editing an existing table sends only the differences', (
    tester,
  ) async {
    final (_, _, design) = await _open(tester);
    expect(find.byKey(const Key('designer-table-name')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('designer-review')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('col-name-1')), 'remark');
    await tester.enterText(find.byKey(const Key('col-type-1')), 'varchar(20)');
    await tester.pump();
    await tester.tap(find.byKey(const Key('col-remove-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('designer-review')));
    await tester.pumpAndSettle();

    final sent = design.previews.single;
    expect(sent.map((c) => c.runtimeType), [
      RenameColumnChange,
      AlterColumnChange,
      DropColumnChange,
    ]);
  });

  testWidgets('destructive changes are flagged on the apply button', (
    tester,
  ) async {
    final (_, _, design) = await _open(tester);
    design.destructive = true;
    await tester.tap(find.byKey(const Key('col-remove-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('designer-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ddl-destructive')), findsOneWidget);
    expect(find.text('Apply (destructive)'), findsOneWidget);
  });
}
