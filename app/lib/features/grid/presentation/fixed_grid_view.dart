// A minimal 2D viewport for result grids (ported from spikes/grid, ADR 0004), built on the Flutter SDK's
// TwoDimensionalScrollView / RenderTwoDimensionalViewport.
//
// Unlike TableView, rows have one fixed height, so visible rows are computed
// arithmetically: layout cost is O(visible cells) regardless of row count, and
// no per-row metrics are stored. Row 0 is a pinned header, column 0 a pinned
// row-number column.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class GridPaintColors {
  const GridPaintColors({required this.line, required this.stripe});
  final Color line;
  final Color stripe;
  @override
  bool operator ==(Object other) =>
      other is GridPaintColors && other.line == line && other.stripe == stripe;
  @override
  int get hashCode => Object.hash(line, stripe);
}

class FixedGridView extends TwoDimensionalScrollView {
  const FixedGridView({
    super.key,
    super.verticalDetails,
    super.horizontalDetails,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required this.rowHeight,
    required this.columnWidths,
    required this.colors,
  });

  final double rowHeight;

  /// Widths including the pinned column at index 0.
  final List<double> columnWidths;
  final GridPaintColors colors;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return _FixedGridViewport(
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      mainAxis: mainAxis,
      rowHeight: rowHeight,
      columnWidths: columnWidths,
      colors: colors,
    );
  }
}

class _FixedGridViewport extends TwoDimensionalViewport {
  const _FixedGridViewport({
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    required this.rowHeight,
    required this.columnWidths,
    required this.colors,
  });
  final double rowHeight;
  final List<double> columnWidths;
  final GridPaintColors colors;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) =>
      RenderFixedGrid(
        horizontalOffset: horizontalOffset,
        horizontalAxisDirection: horizontalAxisDirection,
        verticalOffset: verticalOffset,
        verticalAxisDirection: verticalAxisDirection,
        delegate: delegate as TwoDimensionalChildBuilderDelegate,
        mainAxis: mainAxis,
        childManager: context as TwoDimensionalChildManager,
        rowHeight: rowHeight,
        columnWidths: columnWidths,
        colors: colors,
      );

  @override
  void updateRenderObject(BuildContext context, RenderFixedGrid renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..delegate = delegate
      ..mainAxis = mainAxis
      ..rowHeight = rowHeight
      ..columnWidths = columnWidths
      ..colors = colors;
  }
}

class RenderFixedGrid extends RenderTwoDimensionalViewport {
  RenderFixedGrid({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    required super.childManager,
    required double rowHeight,
    required List<double> columnWidths,
    required GridPaintColors colors,
  }) : _rowHeight = rowHeight, // ignore: prefer_initializing_formals
       _widths = columnWidths,
       _colors = colors; // ignore: prefer_initializing_formals

  double _rowHeight;
  set rowHeight(double v) {
    if (v == _rowHeight) return;
    _rowHeight = v;
    markNeedsLayout();
  }

  List<double> _widths;
  set columnWidths(List<double> v) {
    if (listEquals(v, _widths)) return;
    _widths = v;
    markNeedsLayout();
  }

  GridPaintColors _colors;
  set colors(GridPaintColors v) {
    if (v == _colors) return;
    _colors = v;
    markNeedsPaint();
  }

  List<double> _x = const [0];
  int _r0 = 1, _r1 = 0, _c0 = 1, _c1 = 0;

  @override
  void layoutChildSequence() {
    assert(_widths.isNotEmpty, 'columnWidths must include the pinned column');
    final d = delegate as TwoDimensionalChildBuilderDelegate;
    final rows = (d.maxYIndex ?? -1) + 1; // including header
    final cols = _widths.length;
    final h = _rowHeight;
    _x = List<double>.filled(cols + 1, 0);
    for (var c = 0; c < cols; c++) {
      _x[c + 1] = _x[c] + _widths[c];
    }
    final pinW = _widths[0];
    final vw = viewportDimension.width, vh = viewportDimension.height;

    verticalOffset.applyContentDimensions(
      0,
      math.max(0, (rows - 1) * h - (vh - h)),
    );
    horizontalOffset.applyContentDimensions(0, math.max(0, _x[cols] - vw));
    final vo = verticalOffset.pixels, ho = horizontalOffset.pixels;

    _r0 = 1 + (vo ~/ h);
    _r1 = math.min(rows - 1, 1 + ((vo + vh - h) ~/ h));
    _c0 = 1;
    while (_c0 < cols - 1 && _x[_c0 + 1] <= pinW + ho) {
      _c0++;
    }
    _c1 = _c0;
    while (_c1 < cols - 1 && _x[_c1 + 1] < ho + vw) {
      _c1++;
    }
    if (cols <= 1) {
      // Only the pinned column exists: no scrolling columns to place.
      _c0 = 1;
      _c1 = 0;
    }

    void place(int r, int c, double x, double y) {
      final child = buildOrObtainChildFor(ChildVicinity(xIndex: c, yIndex: r));
      if (child == null) return;
      child.layout(BoxConstraints.tightFor(width: _widths[c], height: h));
      parentDataOf(child).layoutOffset = Offset(x, y);
    }

    double yOf(int r) => r * h - vo;
    // Painted in layout order: scrolling cells, then pinned column, header, corner.
    for (var r = _r0; r <= _r1; r++) {
      for (var c = _c0; c <= _c1; c++) {
        place(r, c, _x[c] - ho, yOf(r));
      }
    }
    for (var r = _r0; r <= _r1; r++) {
      place(r, 0, 0, yOf(r));
    }
    for (var c = _c0; c <= _c1; c++) {
      place(0, c, _x[c] - ho, 0);
    }
    if (rows > 0) place(0, 0, 0, 0);
  }

  final _bodyClip = LayerHandle<ClipRectLayer>();
  final _colClip = LayerHandle<ClipRectLayer>();
  final _headClip = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _bodyClip.layer = null;
    _colClip.layer = null;
    _headClip.layer = null;
    super.dispose();
  }

  void _paintCells(
    PaintingContext ctx,
    Offset off,
    int r0,
    int r1,
    int c0,
    int c1,
  ) {
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        final child = getChildFor(ChildVicinity(xIndex: c, yIndex: r));
        if (child != null) {
          ctx.paintChild(child, off + parentDataOf(child).paintOffset!);
        }
      }
    }
  }

  /// Paints in four clipped passes so pinned header/column sit above the body
  /// (the base class paints row-major, which would draw body cells on top).
  @override
  void paint(PaintingContext context, Offset offset) {
    final vo = verticalOffset.pixels, ho = horizontalOffset.pixels;
    final h = _rowHeight, pinW = _widths[0];
    final w = size.width, hh = size.height;
    final stripe = Paint()..color = _colors.stripe;
    for (var r = _r0; r <= _r1; r++) {
      if (r.isEven) {
        context.canvas.drawRect(
          Rect.fromLTWH(offset.dx, offset.dy + r * h - vo, w, h),
          stripe,
        );
      }
    }
    _bodyClip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(pinW, h, w - pinW, hh - h),
      (c, o) => _paintCells(c, o, _r0, _r1, _c0, _c1),
      oldLayer: _bodyClip.layer,
    );
    _colClip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(0, h, pinW, hh - h),
      (c, o) => _paintCells(c, o, _r0, _r1, 0, 0),
      oldLayer: _colClip.layer,
    );
    _headClip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(pinW, 0, w - pinW, h),
      (c, o) => _paintCells(c, o, 0, 0, _c0, _c1),
      oldLayer: _headClip.layer,
    );
    _paintCells(context, offset, 0, 0, 0, 0);

    final line = Paint()
      ..color = _colors.line
      ..strokeWidth = 0.5;
    final canvas = context.canvas;
    final bottom = offset.dy + math.min(hh, (_r1 + 1) * h - vo);
    for (var c = _c0; c <= _c1 + 1 && c < _x.length; c++) {
      final x = offset.dx + _x[c] - ho;
      if (x > offset.dx + pinW) {
        canvas.drawLine(Offset(x, offset.dy), Offset(x, bottom), line);
      }
    }
    canvas.drawLine(
      Offset(offset.dx + pinW, offset.dy),
      Offset(offset.dx + pinW, bottom),
      line,
    );
    canvas.drawLine(
      Offset(offset.dx, offset.dy + h),
      Offset(offset.dx + w, offset.dy + h),
      line,
    );
  }
}
