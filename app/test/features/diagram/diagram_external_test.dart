import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/domain/diagram_scene.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';
import 'package:queravue/features/diagram/presentation/diagram_export.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';

import '../../support/diagram_harness.dart';
import '../../support/fake_diagram.dart';
import 'diagram_files_ui_test.dart' show answerPrompt, chord;

DiagramRelation _to(
  String column,
  String table, {
  String schema = '',
  String referencedColumn = 'id',
}) => DiagramRelation(
  name: 'fk_$column',
  columns: [column],
  referencedSchema: schema,
  referencedTable: table,
  referencedColumns: [referencedColumn],
);

final billing = SchemaGraph([
  table('customers', columns: ['id', 'name']),
  DiagramTable(
    name: 'orders',
    columns: const [
      DiagramColumn(name: 'id', primaryKeyOrder: 1),
      DiagramColumn(name: 'customer_id'),
      DiagramColumn(name: 'billing_customer_id'),
      DiagramColumn(name: 'billing_code'),
    ],
    relations: [
      _to('customer_id', 'customers'),
      _to('billing_customer_id', 'customers', schema: 'billing'),
      _to(
        'billing_code',
        'customers',
        schema: 'billing',
        referencedColumn: 'code',
      ),
    ],
  ),
]);

void main() {
  test('a reference into another schema gets its own box, never the '
      'same-named local table', () {
    final drawn = withExternalTables(billing);
    expect(drawn.tables.map((t) => t.name), [
      'customers',
      'orders',
      'billing.customers',
    ]);
    final external = drawn.tables.last;
    expect(external.isExternal, isTrue);
    expect(external.externalSchema, 'billing');
    expect(external.localName, 'customers');
    expect(external.columns.map((c) => c.name), ['id', 'code']);

    final orders = drawn.tables[1];
    expect(orders.relations.map((r) => r.referencedTable), [
      'customers',
      'billing.customers',
      'billing.customers',
    ]);
    expect(drawn.localTableCount, 2);
    expect(drawn.externalRelationCount, 2);

    final rects = layoutGraph(drawn).rects;
    final targets = {
      for (final r in drawnRelations(drawn, rects))
        r.relation.columns.single: r.toRect,
    };
    expect(targets['customer_id'], rects['customers']);
    expect(targets['billing_customer_id'], rects['billing.customers']);
  });

  test('a schema without outside references is left as it is', () {
    expect(identical(withExternalTables(shop), shop), isTrue);
  });

  test('external boxes are dashed in the SVG', () {
    final drawn = withExternalTables(billing);
    final svg = diagramToSvg(
      graph: drawn,
      rects: layoutGraph(drawn).rects,
      colors: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    expect(svg, contains('billing.customers'));
    expect('stroke-dasharray="5 4"'.allMatches(svg).length, 1);
  });

  testWidgets('an external table is counted, opens its own schema and is '
      'saved by its qualified name', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(billing));
    expect(
      find.text('2 tables · 3 relations · 2 to other schemas'),
      findsOneWidget,
    );
    final external = ready(env).rects['billing.customers']!;

    await tester.tapAt(
      onScreen(tester, external.center),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open the billing diagram'), findsOneWidget);
    expect(find.byKey(const Key('diagram-menu-relation')), findsNothing);
    await tester.tap(find.byKey(const Key('diagram-menu-open')));
    await tester.pumpAndSettle();
    final opened = env.container
        .read(editorTabsProvider)
        .tabs
        .where((t) => t.isDiagram && t.tableRef?.schema == 'billing');
    expect(opened, hasLength(1));

    env.container.read(editorTabsProvider.notifier).select(env.tabId);
    await tester.pumpAndSettle();
    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, 'billing');
    final saved = SavedDiagram.fromJson(
      env.workspace.contents['.queravue/diagrams/billing.json']!,
    )!;
    expect(saved.positions.containsKey('billing.customers'), isTrue);
  });

  testWidgets('an external table is not offered as a relation target', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(billing));
    await tester.tapAt(
      onScreen(tester, ready(env).rects['customers']!.center),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagram-menu-relation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('draft-relation-target')));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(MenuItemButton, 'billing.customers'),
      findsNothing,
    );
    expect(find.widgetWithText(MenuItemButton, 'orders'), findsWidgets);
  });
}
