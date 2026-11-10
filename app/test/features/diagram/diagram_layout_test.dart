import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';

import '../../support/fake_diagram.dart';

void expectNoOverlap(Map<String, Rect> rects) {
  final boxes = rects.entries.toList();
  for (var i = 0; i < boxes.length; i++) {
    for (var j = i + 1; j < boxes.length; j++) {
      expect(
        boxes[i].value.overlaps(boxes[j].value),
        isFalse,
        reason: '${boxes[i].key} overlaps ${boxes[j].key}',
      );
    }
  }
}

void main() {
  test('a table sits to the right of every table it references', () {
    final rects = layoutGraph(
      SchemaGraph([
        table('order_items', references: {'order_id': 'orders'}),
        table('orders', references: {'customer_id': 'customers'}),
        table('customers'),
      ]),
    ).rects;
    expect(rects['customers']!.right, lessThan(rects['orders']!.left));
    expect(rects['orders']!.right, lessThan(rects['order_items']!.left));
  });

  test('tables without relations come after the connected ones', () {
    final rects = layoutGraph(
      SchemaGraph([
        table('audit_log'),
        table('orders', references: {'customer_id': 'customers'}),
        table('customers'),
      ]),
    ).rects;
    expect(rects['orders']!.right, lessThan(rects['audit_log']!.left));
  });

  test('cycles, self references and unknown tables do not break it', () {
    final rects = layoutGraph(
      SchemaGraph([
        table('a', references: {'b_id': 'b'}),
        table('b', references: {'c_id': 'c'}),
        table('c', references: {'a_id': 'a'}),
        table('tree', references: {'parent_id': 'tree'}),
        table('orphan', references: {'gone_id': 'dropped_table'}),
      ]),
    ).rects;
    expect(rects, hasLength(5));
    expectNoOverlap(rects);
  });

  test('the result does not depend on the order tables arrive in', () {
    final graph = generatedGraph(120);
    final shuffled = SchemaGraph(graph.tables.reversed.toList());
    expect(layoutGraph(shuffled).rects, layoutGraph(graph).rects);
  });

  test('a wide rank is split into columns and nothing overlaps', () {
    final layout = layoutGraph(generatedGraph(500));
    expect(layout.rects, hasLength(500));
    expectNoOverlap(layout.rects);
    final bounds = layout.bounds;
    expect(bounds.width / bounds.height, inInclusiveRange(0.4, 4));
  });

  test('100 tables are laid out within 100 ms', () {
    final graph = generatedGraph(100);
    layoutGraph(graph);
    final watch = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      layoutGraph(graph);
    }
    final each = watch.elapsedMicroseconds / 10000;
    // ignore: avoid_print
    print('LAYOUT_100_MS ${each.toStringAsFixed(2)}');
    expect(each, lessThan(100));

    final large = generatedGraph(500);
    watch.reset();
    layoutGraph(large);
    // ignore: avoid_print
    print(
      'LAYOUT_500_MS ${(watch.elapsedMicroseconds / 1000).toStringAsFixed(2)}',
    );
  });

  test('a box grows with its text, within limits, and caps its rows', () {
    final small = tableSize(table('t'));
    expect(small.width, tableMinWidth);
    expect(small.height, tableHeaderHeight + tableRowHeight + 6);

    final wide = tableSize(
      table(
        't',
        columns: ['a_very_long_column_name_that_goes_on_and_on_for_ever'],
      ),
    );
    expect(wide.width, tableMaxWidth);

    final tall = table('t', columns: [for (var i = 0; i < 60; i++) 'c$i']);
    expect(shownRowCount(tall), maxRowsShown + 1);
    expect(hiddenColumnCount(tall), 60 - maxRowsShown);
    expect(hiddenColumnCount(table('t')), 0);
  });

  test('an empty graph has an empty layout', () {
    final layout = layoutGraph(const SchemaGraph([]));
    expect(layout.rects, isEmpty);
    expect(layout.bounds, Rect.zero);
  });
}
