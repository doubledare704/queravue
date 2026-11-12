import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/data/diagram_files.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import '../../support/fake_diagram.dart';

const _saved = SavedDiagram(
  connectionId: 'c1',
  connectionName: 'Local PG',
  schema: 'public',
  positions: {
    'orders': Offset(320, 0),
    'customers': Offset(0, 12.5),
    'a "quoted" name': Offset(-40, 900),
  },
  hidden: {'orders', 'audit'},
);

void main() {
  test('a saved diagram is one sorted line per table and reads back', () {
    final text = _saved.toJson();
    expect(text, '''
{
  "version": 1,
  "connection": "c1",
  "connectionName": "Local PG",
  "database": "",
  "schema": "public",
  "tables": {
    "a \\"quoted\\" name": {"x": -40, "y": 900},
    "customers": {"x": 0, "y": 12.5},
    "orders": {"x": 320, "y": 0}
  },
  "hidden": ["audit","orders"]
}
''');
    final back = SavedDiagram.fromJson(text)!;
    expect(back.connectionId, 'c1');
    expect(back.connectionName, 'Local PG');
    expect(back.schema, 'public');
    expect(back.positions, _saved.positions);
    expect(back.hidden, _saved.hidden);
    expect(back.toJson(), text);
  });

  test('an empty diagram is still valid JSON', () {
    const empty = SavedDiagram(connectionId: 'c1');
    expect(SavedDiagram.fromJson(empty.toJson())!.positions, isEmpty);
  });

  test('anything else is not a saved diagram', () {
    for (final text in [
      '',
      'not json',
      '[]',
      '{"version": 2, "connection": "c1", "tables": {}}',
      '{"version": 1, "tables": {}}',
      '{"version": 1, "connection": "c1", "tables": {"t": {"x": "1", "y": 2}}}',
      '{"version": 1, "connection": "c1", "tables": {"t": [1, 2]}}',
      '{"version": 1, "connection": "c1", "tables": {}, "hidden": "t"}',
    ]) {
      expect(SavedDiagram.fromJson(text), isNull, reason: text);
    }
  });

  test('saved tables keep their spot; new ones go beside them', () {
    final graph = SchemaGraph([
      table('customers'),
      table('orders', references: {'customer_id': 'customers'}),
      table('invoices', references: {'order_id': 'orders'}),
      table('refunds', references: {'invoice_id': 'invoices'}),
    ]);
    final rects = placeSaved(graph, const {
      'customers': Offset(0, 0),
      'orders': Offset(300, 40),
      'dropped_table': Offset(9000, 9000),
    });
    expect(
      rects.keys,
      unorderedEquals(['customers', 'orders', 'invoices', 'refunds']),
    );
    expect(rects['customers']!.topLeft, Offset.zero);
    expect(rects['orders']!.topLeft, const Offset(300, 40));
    expect(rects['orders']!.size, tableSize(graph.tables[1]));
    final savedRight = rects['orders']!.right;
    expect(rects['invoices']!.left, greaterThan(savedRight));
    expect(rects['refunds']!.left, greaterThan(rects['invoices']!.right));
    expect(rects['invoices']!.top, 0);
  });

  test('without saved positions the automatic layout is used', () {
    final graph = generatedGraph(30);
    expect(placeSaved(graph, const {}), layoutGraph(graph).rects);
  });

  test('diagram names and paths', () {
    expect(validDiagramName('  Orders overview '), 'Orders overview');
    expect(validDiagramName('orders.json'), 'orders');
    expect(validDiagramName('v1.2_draft-b'), 'v1.2_draft-b');
    for (final bad in [
      '',
      '   ',
      '.hidden',
      'a/b',
      r'a\b',
      'naïve',
      'x' * 81,
    ]) {
      expect(validDiagramName(bad), isNull, reason: bad);
    }
    expect(
      isSavedDiagramPath(const FilePath('ws', '.queravue/diagrams/a.json')),
      isTrue,
    );
    expect(
      isSavedDiagramPath(const FilePath('ws', '.queravue/diagrams/x/a.json')),
      isFalse,
    );
    expect(
      isSavedDiagramPath(const FilePath('ws', '.queravue/layout.json')),
      isFalse,
    );
    expect(
      isSavedDiagramPath(const FilePath('ws', 'diagrams/a.json')),
      isFalse,
    );
    expect(
      diagramNameOf(const FilePath('ws', '.queravue/diagrams/Sales v2.json')),
      'Sales v2',
    );
  });
}
