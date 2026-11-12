import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'diagram_layout.dart';
import 'diagram_models.dart';

const forkLength = 9.0;
const forkSpread = 5.0;
const endDotRadius = 3.0;
const _sideClearance = 24.0;
const _minReach = 36.0;

/// One relation that can be drawn: both tables have a box.
typedef DrawnRelation = ({
  DiagramTable from,
  DiagramRelation relation,
  Rect fromRect,
  Rect toRect,
});

/// Relations whose two tables both have a box; self references are left out.
Iterable<DrawnRelation> drawnRelations(
  SchemaGraph graph,
  Map<String, Rect> rects,
) sync* {
  for (final table in graph.tables) {
    final fromRect = rects[table.name];
    if (fromRect == null) continue;
    for (final relation in table.relations) {
      if (relation.referencedTable == table.name) continue;
      final toRect = rects[relation.referencedTable];
      if (toRect == null) continue;
      yield (
        from: table,
        relation: relation,
        fromRect: fromRect,
        toRect: toRect,
      );
    }
  }
}

/// Vertical centre of [column]'s row. The header when the column is not
/// shown, the middle of the box when rows are not drawn at all.
double rowCenterY(
  DiagramTable table,
  Rect rect,
  String? column, {
  required bool rowsDrawn,
}) {
  if (!rowsDrawn || column == null) return rect.center.dy;
  final at = table.columns.indexWhere((c) => c.name == column);
  if (at < 0 || at >= maxRowsShown) return rect.top + tableHeaderHeight / 2;
  return rect.top + tableHeaderHeight + (at + 0.5) * tableRowHeight;
}

/// The curve of one relation: it leaves the referencing table at its column
/// and ends at the referenced column, on the sides that face each other.
@immutable
class RelationCurve {
  const RelationCurve({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
    required this.startOutward,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  /// -1 when the curve leaves the referencing table to the left, else 1.
  final double startOutward;

  /// The many-side mark: two short lines from [forkTip] to the box edge.
  Offset get forkTip => Offset(start.dx + startOutward * forkLength, start.dy);
  Offset get forkUpper => Offset(start.dx, start.dy - forkSpread);
  Offset get forkLower => Offset(start.dx, start.dy + forkSpread);
}

RelationCurve relationCurve(
  DrawnRelation r, {
  required DiagramTable? target,
  required bool rowsDrawn,
}) {
  final from = r.fromRect, to = r.toRect;
  final fromY = rowCenterY(
    r.from,
    from,
    r.relation.columns.firstOrNull,
    rowsDrawn: rowsDrawn,
  );
  final toY = target == null
      ? to.center.dy
      : rowCenterY(
          target,
          to,
          r.relation.referencedColumns.firstOrNull,
          rowsDrawn: rowsDrawn,
        );
  final Offset start, end;
  final double startOut, endOut;
  if (from.left > to.right + _sideClearance) {
    start = Offset(from.left, fromY);
    end = Offset(to.right, toY);
    startOut = -1;
    endOut = 1;
  } else if (to.left > from.right + _sideClearance) {
    start = Offset(from.right, fromY);
    end = Offset(to.left, toY);
    startOut = 1;
    endOut = -1;
  } else {
    start = Offset(from.right, fromY);
    end = Offset(to.right, toY);
    startOut = 1;
    endOut = 1;
  }
  final reach = math.max(_minReach, (end.dx - start.dx).abs() / 2);
  return RelationCurve(
    start: start,
    control1: Offset(start.dx + startOut * reach, start.dy),
    control2: Offset(end.dx + endOut * reach, end.dy),
    end: end,
    startOutward: startOut,
  );
}
