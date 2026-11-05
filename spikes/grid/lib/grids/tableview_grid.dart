// Thin result grid on two_dimensional_scrollables' TableView.
//
// The grid reads rows from a RowStore by index; it never owns row models, so
// the store decides how many rows are resident (all, or a sliding window).
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../data/dataset.dart';
import 'fixed_grid_view.dart';
import 'grid_handle.dart';

const double _rowHeaderWidth = 72;
const Set<int> _numeric = {0, 4, 5, 11};

class TableViewGrid extends StatefulWidget {
  const TableViewGrid({
    super.key,
    required this.args,
    this.fixedViewport = false,
  });
  final GridArgs args;

  /// false: two_dimensional_scrollables TableView. true: FixedGridView on the
  /// SDK's 2D viewport (O(visible) layout, no per-row metrics).
  final bool fixedViewport;
  @override
  State<TableViewGrid> createState() => _TableViewGridState();
}

class _TableViewGridState extends State<TableViewGrid> implements GridHandle {
  final _v = ScrollController();
  final _h = ScrollController();
  final _focus = FocusNode(debugLabel: 'grid');
  final List<double> _widths = List.filled(kColumns.length, kColWidth);
  int _ar = 0, _ac = 0, _fr = 0, _fc = 0; // anchor + focus cell
  bool _hasSel = false;

  RowStore get _store => widget.args.store;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    widget.args.onHandle(this);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _v.dispose();
    _h.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  // ---- GridHandle ----
  @override
  Future<void> jumpToRow(int row) async {
    _v.jumpTo(math.min(row * kRowHeight, _v.position.maxScrollExtent));
  }

  @override
  void resizeColumn(int col, double delta) => setState(() {
    _widths[col] = math.max(40, _widths[col] + delta);
  });

  @override
  Future<String?> selectAndCopy(int r0, int c0, int r1, int c1) async {
    setState(() {
      _ar = r0;
      _ac = c0;
      _fr = r1;
      _fc = c1;
      _hasSel = true;
    });
    return _copy();
  }

  @override
  int? get currentRow => _fr;

  // ---- selection / clipboard ----
  bool _inSel(int r, int c) {
    if (!_hasSel) return false;
    return r >= math.min(_ar, _fr) &&
        r <= math.max(_ar, _fr) &&
        c >= math.min(_ac, _fc) &&
        c <= math.max(_ac, _fc);
  }

  Future<String> _copy() async {
    final r0 = math.min(_ar, _fr), r1 = math.max(_ar, _fr);
    final c0 = math.min(_ac, _fc), c1 = math.max(_ac, _fc);
    // Non-resident rows would come from a core FetchRows RPC; regenerate here.
    final rows = Iterable.generate(
      r1 - r0 + 1,
      (i) => _store.rowAt(r0 + i) ?? generateRow(r0 + i),
    );
    final text = toTsv(rows, c0, c1);
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  void _setFocusCell(int r, int c, {required bool extend}) {
    final maxR = math.max(0, _store.rowCount - 1);
    r = r.clamp(0, maxR);
    c = c.clamp(0, kColumns.length - 1);
    setState(() {
      _fr = r;
      _fc = c;
      if (!extend) {
        _ar = r;
        _ac = c;
      }
      _hasSel = true;
    });
    _ensureVisible(r, c);
  }

  void _ensureVisible(int r, int c) {
    if (!_v.hasClients) return;
    final top = r * kRowHeight;
    final view = _v.position.viewportDimension - kRowHeight;
    if (top < _v.offset) {
      _v.jumpTo(top);
    } else if (top + kRowHeight > _v.offset + view) {
      _v.jumpTo(math.min(top + kRowHeight - view, _v.position.maxScrollExtent));
    }
    var left = 0.0;
    for (var i = 0; i < c; i++) {
      left += _widths[i];
    }
    final hview = _h.position.viewportDimension - _rowHeaderWidth;
    if (left < _h.offset) {
      _h.jumpTo(left);
    } else if (left + _widths[c] > _h.offset + hview) {
      _h.jumpTo(
        math.min(left + _widths[c] - hview, _h.position.maxScrollExtent),
      );
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance;
    final shift = k.isShiftPressed;
    final mod = k.isMetaPressed || k.isControlPressed;
    final page = _v.hasClients
        ? math.max(1, (_v.position.viewportDimension ~/ kRowHeight) - 2)
        : 20;
    final last = _store.rowCount - 1;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _setFocusCell(mod ? last : _fr + 1, _fc, extend: shift);
      case LogicalKeyboardKey.arrowUp:
        _setFocusCell(mod ? 0 : _fr - 1, _fc, extend: shift);
      case LogicalKeyboardKey.arrowRight:
        _setFocusCell(_fr, mod ? kColumns.length - 1 : _fc + 1, extend: shift);
      case LogicalKeyboardKey.arrowLeft:
        _setFocusCell(_fr, mod ? 0 : _fc - 1, extend: shift);
      case LogicalKeyboardKey.pageDown:
        _setFocusCell(_fr + page, _fc, extend: shift);
      case LogicalKeyboardKey.pageUp:
        _setFocusCell(_fr - page, _fc, extend: shift);
      case LogicalKeyboardKey.home:
        _setFocusCell(mod ? 0 : _fr, 0, extend: shift);
      case LogicalKeyboardKey.end:
        _setFocusCell(mod ? last : _fr, kColumns.length - 1, extend: shift);
      case LogicalKeyboardKey.keyA when mod:
        setState(() {
          _ar = 0;
          _ac = 0;
          _fr = last;
          _fc = kColumns.length - 1;
        });
      case LogicalKeyboardKey.keyC when mod:
        _copy();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- pointer hit testing (one listener for the whole grid) ----
  (int, int)? _hit(Offset p) {
    if (p.dy < kRowHeight) return null; // header row handles its own gestures
    final r = ((p.dy - kRowHeight + _v.offset) ~/ kRowHeight);
    if (r >= _store.rowCount) return null;
    if (p.dx < _rowHeaderWidth) return (r, -1);
    var x = p.dx - _rowHeaderWidth + _h.offset;
    for (var c = 0; c < _widths.length; c++) {
      if (x < _widths[c]) return (r, c);
      x -= _widths[c];
    }
    return null;
  }

  void _onDown(PointerDownEvent e) {
    _focus.requestFocus();
    final hit = _hit(e.localPosition);
    if (hit == null) return;
    final (r, c) = hit;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (c == -1) {
      setState(() {
        if (!shift) _ar = r;
        _ac = 0;
        _fr = r;
        _fc = kColumns.length - 1;
        _hasSel = true;
      });
    } else {
      _setFocusCell(r, c, extend: shift);
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (e.buttons != kPrimaryMouseButton) return;
    final hit = _hit(e.localPosition);
    if (hit == null || hit.$2 < 0) return;
    if (hit.$1 != _fr || hit.$2 != _fc) {
      setState(() {
        _fr = hit.$1;
        _fc = hit.$2;
      });
    }
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cs.onSurface,
    );
    final muted = text.copyWith(color: cs.onSurfaceVariant);
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);
    final colDecoration = TableSpanDecoration(
      border: TableSpanBorder(trailing: border),
    );
    final headerRow = TableSpanDecoration(
      color: cs.surfaceContainerHigh,
      border: TableSpanBorder(trailing: border),
    );
    final stripe = TableSpanDecoration(color: cs.surfaceContainerLowest);
    final selColor = cs.primaryContainer.withValues(alpha: 0.6);

    final headerBg = cs.surfaceContainerHigh;
    Widget cell(int vr, int vc) {
      final r = vr - 1, c = vc - 1;
      if (vr == 0) {
        if (c < 0) return ColoredBox(color: headerBg);
        return ColoredBox(
          color: headerBg,
          child: _HeaderCell(
            label: kColumns[c],
            style: text.copyWith(fontWeight: FontWeight.w600),
            onResize: (d) => resizeColumn(c, d),
          ),
        );
      }
      if (c < 0) {
        return ColoredBox(
          color: headerBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('${r + 1}', style: muted, maxLines: 1),
            ),
          ),
        );
      }
      final row = _store.rowAt(r);
      final v = row?[c];
      final child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: _numeric.contains(c)
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            row == null ? '…' : formatValue(v),
            style: (row == null || v == null) ? muted : text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      final sel = _inSel(r, c);
      final focused = _hasSel && r == _fr && c == _fc;
      if (!sel && !focused) return child;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: sel ? selColor : null,
          border: focused ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        child: child,
      );
    }

    final Widget body = widget.fixedViewport
        ? FixedGridView(
            verticalDetails: ScrollableDetails.vertical(controller: _v),
            horizontalDetails: ScrollableDetails.horizontal(controller: _h),
            rowHeight: kRowHeight,
            columnWidths: [_rowHeaderWidth, ..._widths],
            colors: GridPaintColors(
              line: cs.outlineVariant,
              stripe: cs.surfaceContainerLowest,
            ),
            delegate: TwoDimensionalChildBuilderDelegate(
              maxXIndex: kColumns.length,
              maxYIndex: _store.rowCount,
              builder: (_, v) => cell(v.yIndex, v.xIndex),
            ),
          )
        : TableView.builder(
            verticalDetails: ScrollableDetails.vertical(controller: _v),
            horizontalDetails: ScrollableDetails.horizontal(controller: _h),
            pinnedRowCount: 1,
            pinnedColumnCount: 1,
            rowCount: _store.rowCount + 1,
            columnCount: kColumns.length + 1,
            columnBuilder: (i) => TableSpan(
              extent: FixedTableSpanExtent(
                i == 0 ? _rowHeaderWidth : _widths[i - 1],
              ),
              foregroundDecoration: colDecoration,
            ),
            rowBuilder: (i) => TableSpan(
              extent: const FixedTableSpanExtent(kRowHeight),
              backgroundDecoration: i == 0
                  ? headerRow
                  : (i.isEven ? stripe : null),
            ),
            cellBuilder: (_, vic) =>
                TableViewCell(child: cell(vic.row, vic.column)),
          );

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        child: Scrollbar(
          controller: _v,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
          child: Scrollbar(
            controller: _h,
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: body,
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.style,
    required this.onResize,
  });
  final String label;
  final TextStyle style;
  final ValueChanged<double> onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 6,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => onResize(d.delta.dx),
            ),
          ),
        ),
      ],
    );
  }
}
