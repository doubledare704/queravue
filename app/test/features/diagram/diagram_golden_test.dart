import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/presentation/diagram_canvas.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_diagram.dart';

final _graph = SchemaGraph([
  table('customers', columns: ['id', 'name', 'email']),
  table(
    'orders',
    columns: ['id', 'customer_id', 'total'],
    references: {'customer_id': 'customers'},
  ),
  table(
    'order_items',
    columns: ['id', 'order_id', 'quantity'],
    references: {'order_id': 'orders'},
  ),
  const DiagramTable(
    name: 'order_totals',
    type: SchemaObjectType.view,
    columns: [DiagramColumn(name: 'total', typeName: 'numeric')],
  ),
]);

Future<void> pumpDiagram(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(1000, 420);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: brightness,
        ),
      ),
      home: Scaffold(
        body: DiagramCanvas(
          graph: _graph,
          rects: layoutGraph(_graph).rects,
          selected: 'orders',
          layoutRevision: 0,
          onSelect: (_) {},
          onMoveTable: (_, _) {},
          onOpenTable: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('diagram with a selected table, light', (tester) async {
    await pumpDiagram(tester, Brightness.light);
    await expectLater(
      find.byType(DiagramCanvas),
      matchesGoldenFile('goldens/diagram_light.png'),
    );
  });

  testWidgets('diagram with a selected table, dark', (tester) async {
    await pumpDiagram(tester, Brightness.dark);
    await expectLater(
      find.byType(DiagramCanvas),
      matchesGoldenFile('goldens/diagram_dark.png'),
    );
  });
}
