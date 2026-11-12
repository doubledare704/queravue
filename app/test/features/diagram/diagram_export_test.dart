import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/presentation/diagram_export.dart';
import 'package:queravue/shared/theme.dart';

import '../../support/fake_diagram.dart';

final _colors = lightTheme.colorScheme;

/// Fails unless every tag of [svg] is closed in order: enough to catch
/// broken output without an XML parser.
void expectWellFormed(String svg) {
  final tag = RegExp(r'<(/?)([A-Za-z]+)[^>]*?(/?)>');
  final open = <String>[];
  final body = svg.replaceFirst(RegExp(r'^<\?xml[^>]*\?>'), '');
  for (final m in tag.allMatches(body)) {
    final closing = m.group(1) == '/', name = m.group(2)!;
    if (m.group(3) == '/') continue;
    if (closing) {
      expect(open, isNotEmpty, reason: 'stray </$name>');
      expect(open.removeLast(), name, reason: '</$name> closes the wrong tag');
    } else {
      open.add(name);
    }
  }
  expect(open, isEmpty, reason: 'unclosed: $open');
  final text = body.replaceAll(tag, '');
  expect(text.contains('<'), isFalse);
  expect(RegExp(r'&(?!(amp|lt|gt|quot|apos);)').hasMatch(text), isFalse);
}

void main() {
  final graph = SchemaGraph([
    table('customers', columns: ['id', 'name']),
    table(
      'orders',
      columns: ['id', 'customer_id'],
      references: {'customer_id': 'customers'},
    ),
    DiagramTable(
      name: 'Q&A <"notes">',
      columns: const [DiagramColumn(name: "it's", typeName: 'text')],
      relations: const [
        DiagramRelation(
          columns: ['customer_id'],
          referencedTable: 'customers',
          referencedColumns: ['id'],
          inferred: true,
        ),
      ],
    ),
    table('a_table_with_a_really_long_name_that_cannot_fit_in_any_box_at_all'),
  ]);
  final rects = layoutGraph(graph).rects;

  test('the SVG is well formed and holds every table and relation', () {
    final svg = diagramToSvg(
      graph: graph,
      rects: rects,
      colors: _colors,
      title: 'Diagram <public>',
    );
    expectWellFormed(svg);
    expect(svg, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(svg, contains('<title>Diagram &lt;public&gt;</title>'));
    expect(svg, contains('>customers</text>'));
    expect(svg, contains('Q&amp;A &lt;&quot;notes&quot;&gt;'));
    expect(svg, contains('it&apos;s'));
    final longTitle = RegExp(r'>(a_table_with[^<]*)</text>').firstMatch(svg)!;
    expect(longTitle.group(1), endsWith('…'));
    expect(longTitle.group(1)!.length, lessThan(50));
    expect(RegExp(r'<path d="M[^"]* C').allMatches(svg), hasLength(2));
    expect(RegExp('stroke-dasharray').allMatches(svg), hasLength(1));
    expect(RegExp(r'<circle ').allMatches(svg), hasLength(2));
    expect(svg, contains('>PK</text>'));
    expect(svg, contains('>FK</text>'));
  });

  test('the SVG covers the diagram plus a margin, from the origin', () {
    final bounds = DiagramLayout(rects).bounds.inflate(exportMargin);
    final svg = diagramToSvg(graph: graph, rects: rects, colors: _colors);
    expect(svg, contains('viewBox="0 0 ${bounds.width.round()} '));
    expect(svg, isNot(contains('<title>')));
  });

  test('PNGs are sharp when small and shrink to stay within limits', () {
    expect(pngPixelRatio(const Size(800, 600)), preferredPngPixelRatio);
    final big = pngPixelRatio(const Size(12000, 8000));
    expect(12000 * 8000 * big * big, lessThanOrEqualTo(maxPngPixels + 1));
    final thin = pngPixelRatio(const Size(40000, 300));
    expect(40000 * thin, lessThanOrEqualTo(maxPngSide + 0.001));
  });

  testWidgets('the PNG is a PNG of the whole diagram at twice the size', (
    tester,
  ) async {
    final png = (await tester.runAsync(
      () => diagramToPng(graph: graph, rects: rects, colors: _colors),
    ))!;
    final bounds = DiagramLayout(rects).bounds.inflate(exportMargin);
    expect(png.pixelRatio, 2);
    expect(png.width, (bounds.width * 2).ceil());
    expect(png.height, (bounds.height * 2).ceil());
    expect(
      png.bytes.sublist(0, 8),
      Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    );
    final view = ByteData.sublistView(png.bytes);
    expect(view.getUint32(16), png.width);
    expect(view.getUint32(20), png.height);
  });
}
