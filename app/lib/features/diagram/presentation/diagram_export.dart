import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/diagram_layout.dart';
import '../domain/diagram_models.dart';
import '../domain/diagram_scene.dart';
import 'diagram_painter.dart';

const exportMargin = 24.0;
const maxPngPixels = 24000000;
const maxPngSide = 16384;
const preferredPngPixelRatio = 2.0;

const _fontFamily =
    "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
const _gutter = 26.0;
const _rightPadding = 8.0;
const _radius = 6.0;

Rect _exportBounds(Map<String, Rect> rects) =>
    DiagramLayout(rects).bounds.inflate(exportMargin);

/// The whole diagram as an SVG document, drawn like the canvas at full
/// detail. Text widths are estimated, so long names are cut a little early.
String diagramToSvg({
  required SchemaGraph graph,
  required Map<String, Rect> rects,
  required ColorScheme colors,
  String title = '',
}) {
  final bounds = _exportBounds(rects);
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${_n(bounds.width)}" height="${_n(bounds.height)}" '
      'viewBox="0 0 ${_n(bounds.width)} ${_n(bounds.height)}">',
    );
  if (title.isNotEmpty) out.writeln('<title>${_escape(title)}</title>');
  out
    ..writeln(
      '<rect width="100%" height="100%" fill="${_hex(colors.surface)}"/>',
    )
    ..writeln(
      '<g transform="translate(${_n(-bounds.left)} ${_n(-bounds.top)})" '
      'font-family="$_fontFamily">',
    );
  final byName = {for (final t in graph.tables) t.name: t};
  for (final r in drawnRelations(graph, rects)) {
    _writeRelation(out, r, byName[r.relation.referencedTable], colors);
  }
  for (final table in graph.tables) {
    final rect = rects[table.name];
    if (rect != null) _writeTable(out, table, rect, colors);
  }
  out
    ..writeln('</g>')
    ..writeln('</svg>');
  return out.toString();
}

void _writeRelation(
  StringBuffer out,
  DrawnRelation r,
  DiagramTable? target,
  ColorScheme colors,
) {
  final c = relationCurve(r, target: target, rowsDrawn: true);
  final stroke = _hex(colors.outline);
  final dash = r.relation.inferred ? ' stroke-dasharray="6 4"' : '';
  final inferred = r.relation.inferred;
  if (inferred) {
    final opacity = inferredOpacity(r.relation.confidence).toStringAsFixed(2);
    out.writeln('<g opacity="$opacity">');
  }
  out
    ..writeln(
      '<path d="M${_p(c.start)} C${_p(c.control1)} ${_p(c.control2)} '
      '${_p(c.end)}" fill="none" stroke="$stroke" stroke-width="1.2"$dash/>',
    )
    ..writeln(
      '<path d="M${_p(c.forkTip)} L${_p(c.forkUpper)} '
      'M${_p(c.forkTip)} L${_p(c.forkLower)}" fill="none" '
      'stroke="$stroke" stroke-width="1.2"/>',
    )
    ..writeln(
      '<circle cx="${_n(c.end.dx)}" cy="${_n(c.end.dy)}" '
      'r="${_n(endDotRadius)}" fill="$stroke"/>',
    );
  if (inferred) out.writeln('</g>');
}

void _writeTable(
  StringBuffer out,
  DiagramTable table,
  Rect rect,
  ColorScheme colors,
) {
  final isView = table.isView;
  final header = isView ? colors.tertiaryContainer : colors.primaryContainer;
  final onHeader = isView
      ? colors.onTertiaryContainer
      : colors.onPrimaryContainer;
  final x = rect.left, y = rect.top, w = rect.width, h = rect.height;
  out
    ..writeln('<g>')
    ..writeln(
      '<rect x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
      'rx="$_radius" fill="${_hex(colors.surfaceContainerLow)}"/>',
    )
    ..writeln(
      '<path d="M${_n(x)} ${_n(y + tableHeaderHeight)} '
      'V${_n(y + _radius)} A$_radius $_radius 0 0 1 ${_n(x + _radius)} ${_n(y)} '
      'H${_n(x + w - _radius)} A$_radius $_radius 0 0 1 ${_n(x + w)} ${_n(y + _radius)} '
      'V${_n(y + tableHeaderHeight)} Z" fill="${_hex(header)}"/>',
    )
    ..writeln(
      '<rect x="${_n(x)}" y="${_n(y)}" width="${_n(w)}" height="${_n(h)}" '
      'rx="$_radius" fill="none" stroke="${_hex(colors.outlineVariant)}"/>',
    );
  _writeText(
    out,
    _fit(table.name, w - 20, 13, bold: true),
    x: x + 10,
    y: y + tableHeaderHeight / 2,
    size: 13,
    color: onHeader,
    bold: true,
  );
  final shown = math.min(table.columns.length, maxRowsShown);
  for (var i = 0; i < shown; i++) {
    _writeColumn(
      out,
      table,
      table.columns[i],
      Offset(x, y + tableHeaderHeight + i * tableRowHeight),
      w,
      colors,
    );
  }
  final hidden = hiddenColumnCount(table);
  if (hidden > 0) {
    _writeText(
      out,
      table.columns.length > maxRowsShown
          ? '… ${table.columns.length - maxRowsShown} more'
          : '… more',
      x: x + _gutter,
      y: y + tableHeaderHeight + (shown + 0.5) * tableRowHeight,
      size: 11,
      color: colors.onSurfaceVariant,
    );
  }
  out.writeln('</g>');
}

void _writeColumn(
  StringBuffer out,
  DiagramTable table,
  DiagramColumn column,
  Offset origin,
  double width,
  ColorScheme colors,
) {
  final middle = origin.dy + tableRowHeight / 2;
  if (column.isPrimaryKey || table.isForeignKeyColumn(column.name)) {
    _writeText(
      out,
      column.isPrimaryKey ? 'PK' : 'FK',
      x: origin.dx + 7,
      y: middle,
      size: 9,
      color: column.isPrimaryKey ? colors.primary : colors.tertiary,
      bold: true,
    );
  }
  final type = _fit(
    column.nullable ? '${column.typeName}?' : column.typeName,
    width * 0.45,
    11,
  );
  _writeText(
    out,
    type,
    x: origin.dx + width - _rightPadding,
    y: middle,
    size: 11,
    color: colors.onSurfaceVariant,
    anchorEnd: true,
  );
  final typeWidth = _estimatedWidth(type, 11);
  _writeText(
    out,
    _fit(
      column.name,
      width - _gutter - _rightPadding - typeWidth - 8,
      12,
      bold: column.isPrimaryKey,
    ),
    x: origin.dx + _gutter,
    y: middle,
    size: 12,
    color: colors.onSurface,
    bold: column.isPrimaryKey,
  );
}

void _writeText(
  StringBuffer out,
  String text, {
  required double x,
  required double y,
  required double size,
  required Color color,
  bool bold = false,
  bool anchorEnd = false,
}) {
  final weight = bold ? ' font-weight="600"' : '';
  final anchor = anchorEnd ? ' text-anchor="end"' : '';
  out.writeln(
    '<text x="${_n(x)}" y="${_n(y)}" font-size="${_n(size)}" '
    'dominant-baseline="central" fill="${_hex(color)}"$weight$anchor>'
    '${_escape(text)}</text>',
  );
}

double _charWidth(double size, {bool bold = false}) =>
    size * (bold ? 0.62 : 0.56);

double _estimatedWidth(String text, double size, {bool bold = false}) =>
    text.length * _charWidth(size, bold: bold);

String _fit(String text, double maxWidth, double size, {bool bold = false}) {
  final room = (maxWidth / _charWidth(size, bold: bold)).floor();
  if (text.length <= room) return text;
  if (room <= 1) return '…';
  return '${text.substring(0, room - 1)}…';
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String _n(double v) {
  final rounded = (v * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1);
}

String _p(Offset o) => '${_n(o.dx)} ${_n(o.dy)}';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A rendered PNG and the pixels per diagram unit it was drawn at.
typedef PngExport = ({
  Uint8List bytes,
  double pixelRatio,
  int width,
  int height,
});

/// Pixels per diagram unit for a PNG of [size]: twice as sharp as the
/// screen when that fits the pixel and side limits, less when it does not.
double pngPixelRatio(Size size) {
  final byArea = math.sqrt(maxPngPixels / (size.width * size.height));
  final bySide = maxPngSide / math.max(size.width, size.height);
  return math.min(preferredPngPixelRatio, math.min(byArea, bySide));
}

/// The whole diagram rasterised at full detail on a solid background.
Future<PngExport> diagramToPng({
  required SchemaGraph graph,
  required Map<String, Rect> rects,
  required ColorScheme colors,
}) async {
  final bounds = _exportBounds(rects);
  final ratio = pngPixelRatio(bounds.size);
  final width = (bounds.width * ratio).ceil();
  final height = (bounds.height * ratio).ceil();
  final texts = DiagramTextCache();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = colors.surface,
    );
  DiagramPainter(
    graph: graph,
    tablesByName: {for (final t in graph.tables) t.name: t},
    rects: rects,
    selected: null,
    scale: ratio,
    offset: -bounds.topLeft * ratio,
    colors: colors,
    texts: texts,
    fullDetail: true,
  ).paint(canvas, Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(width, height);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return (
        bytes: data!.buffer.asUint8List(),
        pixelRatio: ratio,
        width: width,
        height: height,
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
    texts.clear();
  }
}
