import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../schema/domain/schema_models.dart';
import '../domain/diagram_layout.dart';
import '../domain/diagram_models.dart';
import '../domain/diagram_scene.dart';

/// Below this zoom a table shows only its name; below [boxesOnlyScale] not
/// even that, and relations are straight lines.
const titlesOnlyScale = 0.5;
const boxesOnlyScale = 0.16;

const _gutter = 26.0;
const _rightPadding = 8.0;
const _maxCachedTexts = 6000;

/// Laid-out texts kept between frames; panning repaints the same ones.
class DiagramTextCache {
  final _painters = <String, TextPainter>{};

  TextPainter get(String text, TextStyle style, double maxWidth, String key) {
    final id = '$key|${maxWidth.round()}|$text';
    final cached = _painters[id];
    if (cached != null) return cached;
    if (_painters.length >= _maxCachedTexts) clear();
    return _painters[id] = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(maxWidth, 0));
  }

  void clear() {
    for (final p in _painters.values) {
      p.dispose();
    }
    _painters.clear();
  }
}

class DiagramPainter extends CustomPainter {
  DiagramPainter({
    required this.graph,
    required this.tablesByName,
    required this.rects,
    required this.selected,
    required this.scale,
    required this.offset,
    required this.colors,
    required this.texts,
    this.fullDetail = false,
  });

  final SchemaGraph graph;
  final Map<String, DiagramTable> tablesByName;
  final Map<String, Rect> rects;
  final String? selected;
  final double scale;
  final Offset offset;
  final ColorScheme colors;
  final DiagramTextCache texts;

  /// Draws columns and titles at any scale, for export.
  final bool fullDetail;

  bool get _showsColumns => fullDetail || scale >= titlesOnlyScale;
  bool get _showsTitles => fullDetail || scale >= boxesOnlyScale;

  // Far out, or beside a highlighted table, plain relations step back.
  double get _relationOpacity => selected != null
      ? 0.25
      : _showsColumns
      ? 1
      : _showsTitles
      ? 0.6
      : 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = Rect.fromLTWH(
      -offset.dx / scale,
      -offset.dy / scale,
      size.width / scale,
      size.height / scale,
    );
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(offset.dx, offset.dy)
      ..scale(scale);
    _paintRelations(canvas, visible);
    for (final table in graph.tables) {
      final rect = rects[table.name];
      if (rect != null && rect.overlaps(visible)) {
        _paintTable(canvas, table, rect);
      }
    }
    canvas.restore();
  }

  void _paintRelations(Canvas canvas, Rect visible) {
    final plain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / math.min(scale, 1)
      ..color = colors.outline.withValues(alpha: _relationOpacity);
    final highlighted = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 / math.min(scale, 1)
      ..color = colors.primary;
    final later = <DrawnRelation>[];
    for (final r in drawnRelations(graph, rects)) {
      if (!r.fromRect.expandToInclude(r.toRect).overlaps(visible)) continue;
      if (selected != null &&
          (r.from.name == selected || r.relation.referencedTable == selected)) {
        later.add(r);
      } else {
        _paintRelation(canvas, r, plain);
      }
    }
    for (final r in later) {
      _paintRelation(canvas, r, highlighted);
    }
  }

  void _paintRelation(Canvas canvas, DrawnRelation r, Paint relationPaint) {
    var paint = relationPaint;
    final curve = relationCurve(
      r,
      target: tablesByName[r.relation.referencedTable],
      rowsDrawn: _showsColumns,
    );
    if (!_showsTitles) {
      canvas.drawLine(curve.start, curve.end, paint);
      return;
    }
    final path = Path()
      ..moveTo(curve.start.dx, curve.start.dy)
      ..cubicTo(
        curve.control1.dx,
        curve.control1.dy,
        curve.control2.dx,
        curve.control2.dy,
        curve.end.dx,
        curve.end.dy,
      );
    if (r.relation.draft) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = paint.strokeWidth
        ..color = colors.primary;
    }
    if (r.relation.inferred || r.relation.draft) {
      _paintDashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
    canvas
      ..drawLine(curve.forkTip, curve.forkUpper, paint)
      ..drawLine(curve.forkTip, curve.forkLower, paint)
      ..drawCircle(curve.end, endDotRadius, Paint()..color = paint.color);
  }

  void _paintDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 10) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + 6, metric.length)),
          paint,
        );
      }
    }
  }

  void _paintTable(Canvas canvas, DiagramTable table, Rect rect) {
    final isSelected = table.name == selected;
    final box = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final isView = table.type != SchemaObjectType.table;
    final headerColor = table.draft
        ? colors.secondaryContainer
        : isView
        ? colors.tertiaryContainer
        : colors.primaryContainer;
    final onHeader = table.draft
        ? colors.onSecondaryContainer
        : isView
        ? colors.onTertiaryContainer
        : colors.onPrimaryContainer;
    canvas.drawRRect(box, Paint()..color = colors.surfaceContainerLow);
    if (!_showsColumns) {
      canvas.drawRRect(box, Paint()..color = headerColor);
    } else {
      canvas
        ..save()
        ..clipRRect(box)
        ..drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, tableHeaderHeight),
          Paint()..color = headerColor,
        )
        ..restore();
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isSelected ? 2.4 : 1) / math.min(scale, 1)
      ..color = isSelected || table.draft
          ? colors.primary
          : colors.outlineVariant;
    if (table.draft && !isSelected) {
      _paintDashed(canvas, Path()..addRRect(box), outline);
    } else {
      canvas.drawRRect(box, outline);
    }
    if (!_showsTitles) return;
    if (!_showsColumns) {
      _paintLargeTitle(canvas, table, rect, onHeader);
      return;
    }
    final title = texts.get(
      table.name,
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onHeader),
      rect.width - 20,
      isView ? 'view-title' : 'title',
    );
    title.paint(
      canvas,
      Offset(rect.left + 10, rect.top + (tableHeaderHeight - title.height) / 2),
    );
    final shown = math.min(table.columns.length, maxRowsShown);
    for (var i = 0; i < shown; i++) {
      _paintColumn(
        canvas,
        table,
        table.columns[i],
        Offset(rect.left, rect.top + tableHeaderHeight + i * tableRowHeight),
        rect.width,
      );
    }
    final hidden = hiddenColumnCount(table);
    if (hidden > 0) {
      final more = texts.get(
        table.columns.length > maxRowsShown
            ? '… ${table.columns.length - maxRowsShown} more'
            : '… more',
        TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        rect.width - _gutter - _rightPadding,
        'more',
      );
      more.paint(
        canvas,
        Offset(
          rect.left + _gutter,
          rect.top +
              tableHeaderHeight +
              shown * tableRowHeight +
              (tableRowHeight - more.height) / 2,
        ),
      );
    }
  }

  void _paintLargeTitle(
    Canvas canvas,
    DiagramTable table,
    Rect rect,
    Color color,
  ) {
    final fitsWidth = (rect.width - 12) / (table.name.length * 0.62);
    final size = math
        .min(math.min(12 / scale, fitsWidth), rect.height * 0.6)
        .clamp(13.0, 44.0)
        .roundToDouble();
    final title = texts.get(
      table.name,
      TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color),
      rect.width - 12,
      'large-$size-${color.toARGB32()}',
    );
    title.paint(
      canvas,
      Offset(
        rect.left + (rect.width - title.width) / 2,
        rect.top + (rect.height - title.height) / 2,
      ),
    );
  }

  void _paintColumn(
    Canvas canvas,
    DiagramTable table,
    DiagramColumn column,
    Offset origin,
    double width,
  ) {
    final isForeignKey = table.isForeignKeyColumn(column.name);
    if (column.isPrimaryKey || isForeignKey) {
      final tag = texts.get(
        column.isPrimaryKey ? 'PK' : 'FK',
        TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: column.isPrimaryKey ? colors.primary : colors.tertiary,
        ),
        _gutter,
        column.isPrimaryKey ? 'pk' : 'fk',
      );
      tag.paint(
        canvas,
        Offset(origin.dx + 7, origin.dy + (tableRowHeight - tag.height) / 2),
      );
    }
    final type = texts.get(
      column.nullable ? '${column.typeName}?' : column.typeName,
      TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
      width * 0.45,
      'type',
    );
    type.paint(
      canvas,
      Offset(
        origin.dx + width - _rightPadding - type.width,
        origin.dy + (tableRowHeight - type.height) / 2,
      ),
    );
    final name = texts.get(
      column.name,
      TextStyle(
        fontSize: 12,
        fontWeight: column.isPrimaryKey ? FontWeight.w600 : FontWeight.w400,
        color: column.draft ? colors.primary : colors.onSurface,
      ),
      width - _gutter - _rightPadding - type.width - 8,
      '${column.isPrimaryKey ? 'key-name' : 'name'}${column.draft ? '-draft' : ''}',
    );
    name.paint(
      canvas,
      Offset(
        origin.dx + _gutter,
        origin.dy + (tableRowHeight - name.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(DiagramPainter old) =>
      old.graph != graph ||
      old.rects != rects ||
      old.selected != selected ||
      old.scale != scale ||
      old.offset != offset ||
      old.colors != colors ||
      old.fullDetail != fullDetail;
}
