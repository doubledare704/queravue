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
    expect(relation.column, 'customers_id');
    expect(relation.toColumn, 'id');
    expect(relation.newColumn?.typeName, 'int');
    expect(relation.newColumn?.nullable, isTrue);

    final toSerial = suggestRelation(_customers, _drawn(drawn, 'invoices'));
    expect(toSerial.newColumn?.typeName, 'integer');
  });

  test('a suggested relation reuses a column the table already has', () {
    final orders = table('orders', columns: ['id', 'customers_id']);
    final relation = suggestRelation(orders, _customers);
    expect(relation.newColumn, isNull);
    expect(relation.column, 'customers_id');
  });

  test('only a one-column primary key can be referenced', () {
    expect(referenceProblem(_customers), isNull);
    expect(
      referenceProblem(const DiagramTable(name: 'log')),
      contains('no primary key'),
    );
    final composite = DiagramTable(
      name: 'pair',
      columns: const [
        DiagramColumn(name: 'a', primaryKeyOrder: 1),
        DiagramColumn(name: 'b', primaryKeyOrder: 2),
      ],
    );
    expect(referenceProblem(composite), contains('2 columns'));
  });

  test('the draft is drawn as new tables, columns and relations', () {
    final draft = const DiagramDraft(tables: [_invoices])
        .withRelation(suggestRelation(_customers, table('invoices')))
        .withRelation(
          const DraftRelation(
            name: 'fk_invoices_customers',
            fromTable: 'invoices',
            column: 'customer_id',
            toTable: 'customers',
            toColumn: 'id',
            newColumn: ColumnDraft(name: 'customer_id', typeName: 'int'),
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
              column: 'customer_id',
              toTable: 'customers',
              toColumn: 'id',
              newColumn: ColumnDraft(name: 'customer_id', typeName: 'int'),
              onDelete: ReferentialAction.cascade,
            ),
          )
          .withRelation(
            const DraftRelation(
              name: 'fk_customers_invoices',
              fromTable: 'customers',
              column: 'last_invoice',
              toTable: 'invoices',
              toColumn: 'id',
              newColumn: ColumnDraft(name: 'last_invoice', typeName: 'integer'),
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
        column: 'invoices_id',
        toTable: 'invoices',
        toColumn: 'id',
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
        column: 'customer_id',
        toTable: 'customers',
        toColumn: 'id',
        newColumn: ColumnDraft(name: 'customer_id', typeName: 'int'),
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
    expect(relation.newColumn?.name, 'customer_id');

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
