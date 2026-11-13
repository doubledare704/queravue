import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/designer/domain/design_models.dart';
import 'package:queravue/features/diagram/domain/diagram_draft.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_diagram.dart';

const _invoices = DraftTable(
  name: 'invoices',
  columns: [
    ColumnDraft(
      name: 'id',
      typeName: 'serial',
      nullable: false,
      primaryKey: true,
    ),
    ColumnDraft(name: 'total', typeName: 'numeric(10,2)'),
  ],
);

final _customers = table('customers', columns: ['id', 'name']);

const _orderLines = DiagramTable(
  name: 'order_lines',
  columns: [
    DiagramColumn(name: 'order_id', typeName: 'bigint', primaryKeyOrder: 1),
    DiagramColumn(name: 'line_no', typeName: 'int', primaryKeyOrder: 2),
    DiagramColumn(name: 'qty', typeName: 'int'),
  ],
);

DiagramTable _drawn(SchemaGraph graph, String name) =>
    graph.tables.firstWhere((t) => t.name == name);

void main() {
  test('a suggested relation adds a column named after the referenced key', () {
    final drawn = graphWithDraft(
      SchemaGraph([_customers]),
      const DiagramDraft(tables: [_invoices]),
    );
    final relation = suggestRelation(
      _drawn(drawn, 'invoices'),
      _customers,
      takenNames: {'fk_invoices_customers'},
    );
    expect(relation.name, 'fk_invoices_customers_2');
    expect(relation.columns, ['customers_id']);
    expect(relation.toColumns, ['id']);
    expect(relation.newColumns.single.typeName, 'int');
    expect(relation.newColumns.single.nullable, isTrue);

    final toSerial = suggestRelation(_customers, _drawn(drawn, 'invoices'));
    expect(toSerial.newColumns.single.typeName, 'integer');
  });

  test('a suggested relation reuses a column the table already has', () {
    final orders = table('orders', columns: ['id', 'customers_id']);
    final relation = suggestRelation(orders, _customers);
    expect(relation.newColumns, isEmpty);
    expect(relation.columns, ['customers_id']);
  });

  test('only a table with a primary key can be referenced', () {
    expect(referenceProblem(_customers), isNull);
    expect(referenceProblem(_orderLines), isNull);
    expect(
      referenceProblem(const DiagramTable(name: 'log')),
      contains('no primary key'),
    );
  });

  test('a composite key is referenced column by column, in key order', () {
    final shipments = table(
      'shipments',
      columns: ['id', 'order_lines_line_no'],
    );
    final relation = suggestRelation(shipments, _orderLines);
    expect(relation.toColumns, ['order_id', 'line_no']);
    expect(relation.columns, ['order_lines_order_id', 'order_lines_line_no']);
    expect(relation.newColumns.single.name, 'order_lines_order_id');
    expect(relation.newColumns.single.typeName, 'bigint');
    expect(
      describeRelation(relation, 'shipments'),
      'Adds column order_lines_order_id bigint, uses column '
      'order_lines_line_no to shipments, referencing order_lines '
      '(order_id, line_no).',
    );
  });

  test('a composite key can go through columns the table already has', () {
    final shipments = table('shipments', columns: ['id', 'order_id', 'line']);
    final relation = relationThrough(shipments, _orderLines, [
      'order_id',
      'line',
    ]);
    expect(relation.columns, ['order_id', 'line']);
    expect(relation.newColumns, isEmpty);

    final mixed = relationThrough(shipments, _orderLines, ['order_id', null]);
    expect(mixed.columns, ['order_id', 'order_lines_line_no']);
    expect(mixed.newColumns.single.typeName, 'int');

    expect(throughProblem(['line', 'line']), contains('two key columns'));
    expect(throughProblem(['line', null]), isNull);
  });

  test('a new column whose name is taken gets a numbered one', () {
    final shipments = table('shipments', columns: ['id', 'customers_id']);
    final relation = relationThrough(shipments, _customers, [null]);
    expect(relation.columns, ['customers_id_2']);
  });

  test('a composite relation is drawn once and created with all its '
      'columns, new ones first in key order', () {
    final draft = const DiagramDraft().withRelation(
      relationThrough(
        table('shipments', columns: ['id', 'line']),
        _orderLines,
        [null, 'line'],
      ),
    );
    final drawn = graphWithDraft(
      SchemaGraph([
        table('shipments', columns: ['id', 'line']),
        _orderLines,
      ]),
      draft,
    );
    final shipments = _drawn(drawn, 'shipments');
    expect(shipments.relations.single.columns, [
      'order_lines_order_id',
      'line',
    ]);
    expect(shipments.isForeignKeyColumn('line'), isTrue);
    expect(drawn.relationCount, 1);

    final changes = draftChanges(draft).single.changes;
    expect(
      (changes.first as AddColumnChange).column.name,
      'order_lines_order_id',
    );
    final fk = (changes.last as AddForeignKeyChange).foreignKey;
    expect(fk.columns, ['order_lines_order_id', 'line']);
    expect(fk.referencedColumns, ['order_id', 'line_no']);
  });

  test('a relation saved before composite keys still reads', () {
    final back = DiagramDraft.fromJson({
      'relations': [
        {
          'name': 'fk',
          'from': 'orders',
          'column': 'customer_id',
          'to': 'customers',
          'toColumn': 'id',
          'newColumn': {'name': 'customer_id', 'type': 'int'},
        },
      ],
    })!;
    final relation = back.relations.single;
    expect(relation.columns, ['customer_id']);
    expect(relation.toColumns, ['id']);
    expect(relation.newColumns.single.typeName, 'int');

    final round = DiagramDraft.fromJson(back.toJson())!.relations.single;
    expect(round.columns, ['customer_id']);
    expect(round.newColumns.single.name, 'customer_id');
  });

  test('the draft is drawn as new tables, columns and relations', () {
    final draft = const DiagramDraft(tables: [_invoices])
        .withRelation(suggestRelation(_customers, table('invoices')))
        .withRelation(
          const DraftRelation(
            name: 'fk_invoices_customers',
            fromTable: 'invoices',
            columns: ['customer_id'],
            toTable: 'customers',
            toColumns: ['id'],
            newColumns: [ColumnDraft(name: 'customer_id', typeName: 'int')],
          ),
        );
    final drawn = graphWithDraft(SchemaGraph([_customers]), draft);
    final customers = _drawn(drawn, 'customers');
    expect(customers.draft, isFalse);
    expect(customers.columns.last.name, 'invoices_id');
    expect(customers.columns.last.draft, isTrue);
    expect(customers.relations.single.draft, isTrue);

    final invoices = _drawn(drawn, 'invoices');
    expect(invoices.draft, isTrue);
    expect(
      [for (final c in invoices.columns) c.name],
      ['id', 'total', 'customer_id'],
    );
    expect(invoices.primaryKey.single.name, 'id');
    expect(invoices.relations.single.referencedTable, 'customers');
    expect(drawn.relationCount, 2);
  });

  test(
    'the draft becomes a create per new table and adds on existing ones',
    () {
      final draft = const DiagramDraft(tables: [_invoices])
          .withRelation(
            const DraftRelation(
              name: 'fk_invoices_customers',
              fromTable: 'invoices',
              columns: ['customer_id'],
              toTable: 'customers',
              toColumns: ['id'],
              newColumns: [ColumnDraft(name: 'customer_id', typeName: 'int')],
              onDelete: ReferentialAction.cascade,
            ),
          )
          .withRelation(
            const DraftRelation(
              name: 'fk_customers_invoices',
              fromTable: 'customers',
              columns: ['last_invoice'],
              toTable: 'invoices',
              toColumns: ['id'],
              newColumns: [
                ColumnDraft(name: 'last_invoice', typeName: 'integer'),
              ],
            ),
          );
      final changes = draftChanges(draft, schema: 'app');
      expect(
        [for (final t in changes) t.table.qualifiedName],
        ['app.invoices', 'app.customers'],
      );
      final create = changes.first.changes.single as CreateTableChange;
      expect(
        [for (final c in create.columns) c.name],
        ['id', 'total', 'customer_id'],
      );
      final fk = create.constraints.foreignKeys.single;
      expect(fk.referencedSchema, 'app');
      expect(fk.onDelete, ReferentialAction.cascade);
      expect(changes.last.changes.map((c) => c.runtimeType), [
        AddColumnChange,
        AddForeignKeyChange,
      ]);
    },
  );

  test('renaming a drafted table moves its relations; removing drops them', () {
    final draft = const DiagramDraft(tables: [_invoices]).withRelation(
      const DraftRelation(
        name: 'fk',
        fromTable: 'customers',
        columns: ['invoices_id'],
        toTable: 'invoices',
        toColumns: ['id'],
      ),
    );
    final renamed = draft.withTable(
      _invoices.renamed('bills'),
      replacing: 'invoices',
    );
    expect(renamed.tables.single.name, 'bills');
    expect(renamed.relations.single.toTable, 'bills');
    expect(renamed.withoutTable('bills').isEmpty, isTrue);
  });

  test(
    'a drafted table needs a free name and named, typed, distinct columns',
    () {
      const ok = DraftTable(
        name: 'a',
        columns: [ColumnDraft(name: 'id', typeName: 'int')],
      );
      expect(draftTableProblem(ok, {}), isNull);
      expect(draftTableProblem(ok, {'a'}), contains('already on the diagram'));
      expect(
        draftTableProblem(const DraftTable(name: ' ', columns: []), {}),
        contains('needs a name'),
      );
      expect(
        draftTableProblem(const DraftTable(name: 'a', columns: []), {}),
        contains('at least one column'),
      );
      expect(
        draftTableProblem(
          const DraftTable(
            name: 'a',
            columns: [
              ColumnDraft(name: 'id', typeName: 'int'),
              ColumnDraft(name: 'id', typeName: 'int'),
            ],
          ),
          {},
        ),
        contains('twice'),
      );
      expect(
        draftTableProblem(
          const DraftTable(
            name: 'a',
            columns: [ColumnDraft(name: 'id')],
          ),
          {},
        ),
        contains('needs a type'),
      );
    },
  );

  test('a saved diagram keeps its draft; one without a draft still reads', () {
    final draft = const DiagramDraft(tables: [_invoices]).withRelation(
      const DraftRelation(
        name: 'fk_invoices_customers',
        fromTable: 'invoices',
        columns: ['customer_id'],
        toTable: 'customers',
        toColumns: ['id'],
        newColumns: [ColumnDraft(name: 'customer_id', typeName: 'int')],
        onDelete: ReferentialAction.setNull,
      ),
    );
    final saved = SavedDiagram(
      connectionId: 'c1',
      positions: const {'invoices': Offset(10, 20)},
      draft: draft,
    );
    final text = saved.toJson();
    expect(text, contains('\n      {"name":"invoices","columns":'));
    final back = SavedDiagram.fromJson(text)!;
    expect(back.draft.tables.single.columns.first.typeName, 'serial');
    expect(back.draft.tables.single.columns.first.primaryKey, isTrue);
    expect(back.draft.tables.single.columns.first.nullable, isFalse);
    final relation = back.draft.relations.single;
    expect(relation.onDelete, ReferentialAction.setNull);
    expect(relation.newColumns.single.name, 'customer_id');

    final plain = const SavedDiagram(connectionId: 'c1').toJson();
    expect(plain, isNot(contains('draft')));
    expect(SavedDiagram.fromJson(plain)!.draft.isEmpty, isTrue);
    expect(
      SavedDiagram.fromJson(
        plain.replaceFirst('"hidden"', '"draft": 3, "hidden"'),
      ),
      isNull,
    );
  });
}
