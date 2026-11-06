import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/domain/cancellation.dart';
import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';
import '../../schema/domain/schema_models.dart';
import '../../table_view/application/pending_changes_controller.dart';
import '../../table_view/domain/table_models.dart';
import '../application/copy_service.dart';
import '../application/result_window.dart';
import '../domain/cell_format.dart';
import '../domain/selection.dart';
import 'fixed_grid_view.dart';
import 'value_viewer.dart';

/// Uniform row height; long and multi-line values are truncated in the cell
/// and opened in the value viewer (ADR 0004).
const double kGridRowHeight = 28;

/// Virtualized result grid over a [ResultWindow]. It renders only the cells
/// on screen and reads rows through the window, which fetches pages from the
/// core as the user scrolls.
class ResultGrid extends ConsumerStatefulWidget {
  const ResultGrid({
    super.key,
    required this.resultId,
    this.sorts = const [],
    this.onSort,
    this.canEdit = false,
    this.onCellDoubleTap,
    this.onRowSelected,
    this.pendingChanges,
    this.tableDetails,
  });

  final String resultId;
  final List<SortClause> sorts;
  final void Function(String column, {bool isMulti})? onSort;
  final bool canEdit;
  final void Function(int rowIndex, int colIndex, Object? currentValue)?
  onCellDoubleTap;
  final ValueChanged<int>? onRowSelected;
  final PendingChangesState? pendingChanges;
  final TableDetails? tableDetails;

  @override
  ConsumerState<ResultGrid> createState() => _ResultGridState();
}

class _ResultGridState extends ConsumerState<ResultGrid> {
  final _v = ScrollController();
  final _h = ScrollController();
  final _focus = FocusNode(debugLabel: 'result-grid');
  List<double> _widths = const [];
  int _widthsFor = -1;
  GridSelection? _sel;
  bool _viewer = false;
  Offset _lastDoubleTap = Offset.zero;
  bool _reportScheduled = false;

  ResultWindow get _win =>
      ref.read(resultWindowProvider(widget.resultId).notifier);

  @override
  void initState() {
    super.initState();
    _v.addListener(_scheduleReport);
  }

  @override
  void dispose() {
    _v.removeListener(_scheduleReport);
    _v.dispose();
    _h.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ---- sizing ----

  double get _rowHeaderWidth {
    final digits = math.max(
      2,
      '${ref.read(resultWindowProvider(widget.resultId)).rowCount}'.length,
    );
    return math.max(56, digits * 9.0 + 28);
  }

  void _ensureWidths(List<ResultColumn> cols) {
    if (_widthsFor == cols.length && _widths.length == cols.length) return;
    _widthsFor = cols.length;
    _widths = [
      for (final c in cols)
        math.max(c.kind.isNumeric ? 96.0 : 150.0, c.name.length * 8.0 + 28),
    ];
  }

  void resizeColumn(int col, double delta) {
    setState(() {
      _widths = List.of(_widths);
      _widths[col] = math.max(40, _widths[col] + delta);
    });
  }

  // ---- viewport reporting ----

  void _scheduleReport() {
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      if (!mounted) return;
      _reportViewport();
    });
  }

  void _reportViewport() {
    if (!_v.hasClients) return;
    final total = ref.read(resultWindowProvider(widget.resultId)).rowCount;
    if (total == 0) return;
    final top = (_v.offset ~/ kGridRowHeight).clamp(0, total - 1);
    final rows = math.max(
      1,
      (_v.position.viewportDimension ~/ kGridRowHeight) - 1,
    );
    final bottom = math.min(total - 1, top + rows);
    _win.setViewport(top, bottom);
    ref.read(viewportProvider(widget.resultId).notifier).set(top, bottom);
  }

  // ---- selection ----

  int get _rows => ref.read(resultWindowProvider(widget.resultId)).rowCount;
  int get _cols =>
      ref.read(resultWindowProvider(widget.resultId)).columns.length;

  void _select(GridSelection s) {
    setState(() => _sel = s);
    _ensureVisible(s.focusRow, s.focusCol);
  }

  void _moveFocus(int r, int c, {required bool extend}) {
    final cur = _sel ?? const GridSelection.cell(0, 0);
    _select(cur.moveFocus(r, c, extend: extend, rows: _rows, cols: _cols));
  }

  void _ensureVisible(int r, int c) {
    if (!_v.hasClients || !_h.hasClients) return;
    final top = r * kGridRowHeight;
    final view = _v.position.viewportDimension - kGridRowHeight;
    if (top < _v.offset) {
      _v.jumpTo(top);
    } else if (top + kGridRowHeight > _v.offset + view) {
      _v.jumpTo(
        math.min(top + kGridRowHeight - view, _v.position.maxScrollExtent),
      );
    }
    var left = 0.0;
    for (var i = 0; i < c && i < _widths.length; i++) {
      left += _widths[i];
    }
    if (c >= _widths.length) return;
    final hview = _h.position.viewportDimension - _rowHeaderWidth;
    if (left < _h.offset) {
      _h.jumpTo(left);
    } else if (left + _widths[c] > _h.offset + hview) {
      _h.jumpTo(
        math.min(left + _widths[c] - hview, _h.position.maxScrollExtent),
      );
    }
  }

  /// Scrolls so [row] is at the top. Used by tests and "go to row".
  void jumpToRow(int row) {
    if (!_v.hasClients) return;
    _v.jumpTo(math.min(row * kGridRowHeight, _v.position.maxScrollExtent));
  }

  // ---- keyboard ----

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance;
    final shift = k.isShiftPressed;
    final mod = k.isMetaPressed || k.isControlPressed;
    final page = _v.hasClients
        ? math.max(1, (_v.position.viewportDimension ~/ kGridRowHeight) - 2)
        : 20;
    final lastRow = _rows - 1, lastCol = _cols - 1;
    final cur = _sel ?? const GridSelection.cell(0, 0);
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(
          mod ? lastRow : cur.focusRow + 1,
          cur.focusCol,
          extend: shift,
        );
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(mod ? 0 : cur.focusRow - 1, cur.focusCol, extend: shift);
      case LogicalKeyboardKey.arrowRight:
        _moveFocus(
          cur.focusRow,
          mod ? lastCol : cur.focusCol + 1,
          extend: shift,
        );
      case LogicalKeyboardKey.arrowLeft:
        _moveFocus(cur.focusRow, mod ? 0 : cur.focusCol - 1, extend: shift);
      case LogicalKeyboardKey.pageDown:
        _moveFocus(cur.focusRow + page, cur.focusCol, extend: shift);
      case LogicalKeyboardKey.pageUp:
        _moveFocus(cur.focusRow - page, cur.focusCol, extend: shift);
      case LogicalKeyboardKey.home:
        _moveFocus(mod ? 0 : cur.focusRow, 0, extend: shift);
      case LogicalKeyboardKey.end:
        _moveFocus(mod ? lastRow : cur.focusRow, lastCol, extend: shift);
      case LogicalKeyboardKey.keyA when mod:
        if (_rows > 0 && _cols > 0) _select(GridSelection.all(_rows, _cols));
      case LogicalKeyboardKey.keyC when mod:
        unawaited(_copy(header: shift));
      case LogicalKeyboardKey.enter:
        if (_sel != null && widget.onCellDoubleTap != null) {
          final r = _sel!.focusRow;
          final c = _sel!.focusCol;
          final row = _win.rowAt(r);
          final v = row != null && c < row.length ? row[c] : null;
          widget.onCellDoubleTap!(r, c, v);
          return KeyEventResult.handled;
        }
      case LogicalKeyboardKey.space when !mod:
        if (_sel != null) setState(() => _viewer = !_viewer);
      case LogicalKeyboardKey.escape when _viewer:
        setState(() => _viewer = false);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- pointer ----

  (int, int)? _hit(Offset p) {
    if (p.dy < kGridRowHeight) return null;
    final r = (p.dy - kGridRowHeight + _v.offset) ~/ kGridRowHeight;
    if (r >= _rows) return null;
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
    final cur = _sel ?? GridSelection.cell(r, math.max(c, 0));
    if (c == -1) {
      _select(cur.rows(r, extend: shift, cols: _cols));
      widget.onRowSelected?.call(r);
    } else {
      _moveFocus(r, c, extend: shift);
      widget.onRowSelected?.call(r);
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (e.buttons != kPrimaryMouseButton) return;
    final hit = _hit(e.localPosition);
    final cur = _sel;
    if (hit == null || hit.$2 < 0 || cur == null) return;
    if (hit.$1 != cur.focusRow || hit.$2 != cur.focusCol) {
      setState(() {
        _sel = cur.moveFocus(
          hit.$1,
          hit.$2,
          extend: true,
          rows: _rows,
          cols: _cols,
        );
      });
    }
  }

  void _onDoubleTap() {
    final hit = _hit(_lastDoubleTap);
    if (hit == null || hit.$2 < 0) return;
    if (widget.onCellDoubleTap != null) {
      final r = hit.$1;
      final c = hit.$2;
      final row = _win.rowAt(r);
      final v = row != null && c < row.length ? row[c] : null;
      widget.onCellDoubleTap!(r, c, v);
      return;
    }
    setState(() => _viewer = true);
  }

  // ---- copy ----

  /// Copies the selection (or everything with [all]). Selections of up to
  /// 10k cells that are fully in the window are built locally; the rest goes
  /// through the core with progress and cancel.
  Future<void> _copy({
    CopyFormat format = CopyFormat.tsv,
    bool header = false,
    bool all = false,
  }) async {
    final cols = ref.read(resultWindowProvider(widget.resultId)).columns;
    final sel = all
        ? (_rows > 0 && cols.isNotEmpty
              ? GridSelection.all(_rows, cols.length)
              : null)
        : _sel;
    if (sel == null) return;
    final colIdx = [
      for (var c = sel.left; c <= sel.right && c < cols.length; c++) c,
    ];
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (format != CopyFormat.json && sel.cellCount <= kLocalCopyMaxCells) {
      final rows = _win.residentRange(sel.top, sel.bottom + 1);
      if (rows != null) {
        final text = formatDelimited(
          rows,
          colIdx,
          format: format,
          header: header ? cols : null,
        );
        await Clipboard.setData(ClipboardData(text: text));
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              'Copied ${sel.rowCount} rows × ${colIdx.length} columns',
            ),
          ),
        );
        return;
      }
    }

    final token = CancellationToken();
    final progress = ValueNotifier<int>(0);
    final total = sel.rowCount;
    var dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CopyProgressDialog(
          progress: progress,
          total: total,
          onCancel: token.cancel,
        ),
      ).whenComplete(() => dialogOpen = false),
    );
    try {
      final text = await copyViaCore(
        ref.read(queryRepositoryProvider),
        resultId: widget.resultId,
        start: sel.top,
        end: sel.bottom + 1,
        columns: all ? const [] : colIdx,
        format: format,
        includeHeader: header,
        onProgress: (n) => progress.value = n,
        cancel: token,
      );
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Copied $total rows × ${colIdx.length} columns'),
        ),
      );
    } on OperationCancelled {
      messenger?.showSnackBar(const SnackBar(content: Text('Copy cancelled')));
    } on Object catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Copy failed: $e')));
    } finally {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final win = ref.watch(resultWindowProvider(widget.resultId));
    final cols = win.columns;
    _ensureWidths(cols);
    _scheduleReport();
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall!;
    final text = base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cs.onSurface,
    );
    final muted = text.copyWith(color: cs.onSurfaceVariant);
    final nullStyle = muted.copyWith(fontStyle: FontStyle.italic);
    final selColor = cs.primaryContainer.withValues(alpha: 0.6);
    final headerBg = cs.surfaceContainerHigh;
    final rowHeaderW = _rowHeaderWidth;
    final sel = _sel;
    final window = _win;

    Widget cell(int vr, int vc) {
      final r = vr - 1, c = vc - 1;
      if (vr == 0) {
        if (c < 0) return ColoredBox(color: headerBg);
        final colName = cols[c].name;
        final sortIdx = widget.sorts.indexWhere((s) => s.column == colName);
        final sort = sortIdx >= 0 ? widget.sorts[sortIdx] : null;
        String? sortIndicator;
        if (sort != null) {
          final arrow = sort.direction == SortDirection.asc ? '▲' : '▼';
          final order = widget.sorts.length > 1 ? ' ${sortIdx + 1}' : '';
          sortIndicator = '$arrow$order';
        }
        return ColoredBox(
          color: headerBg,
          child: _HeaderCell(
            column: cols[c],
            style: text.copyWith(fontWeight: FontWeight.w600),
            sortIndicator: sortIndicator,
            onTap: () {
              if (widget.onSort != null) {
                final shift = HardwareKeyboard.instance.isShiftPressed;
                widget.onSort!(colName, isMulti: shift);
              } else {
                _select(
                  (sel ?? GridSelection.cell(0, c)).column(
                    c,
                    rows: win.rowCount,
                  ),
                );
              }
            },
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
      final row = window.rowAt(r);
      var v = row != null && c < row.length ? row[c] : null;
      final loading = row == null;

      // Check pending changes
      var isDeleted = false;
      var isCellUpdated = false;
      if (widget.tableDetails != null &&
          widget.pendingChanges != null &&
          row != null) {
        final pkCols = widget.tableDetails!.primaryKeyColumns;
        if (pkCols.isNotEmpty) {
          final pkValues = <String, Object?>{};
          for (final pk in pkCols) {
            final colIdx = cols.indexWhere((col) => col.name == pk.name);
            if (colIdx >= 0 && colIdx < row.length) {
              pkValues[pk.name] = row[colIdx];
            }
          }
          if (pkValues.length == pkCols.length) {
            final pkKey = makePkKey(pkValues);
            isDeleted = widget.pendingChanges!.isDeleted(pkKey);
            if (widget.pendingChanges!.hasUpdatedValue(pkKey, cols[c].name)) {
              isCellUpdated = true;
              v = widget.pendingChanges!.getUpdatedValue(pkKey, cols[c].name);
            }
          }
        }
      }

      TextStyle cellStyle = loading ? muted : (v == null ? nullStyle : text);
      if (isDeleted) {
        cellStyle = cellStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          color: cs.error,
        );
      } else if (isCellUpdated) {
        cellStyle = cellStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade800,
        );
      }

      final child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: cols[c].kind.isNumeric
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            loading ? '…' : cellPreview(v),
            style: cellStyle,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      final selected = sel != null && sel.contains(r, c);
      final focused = sel != null && r == sel.focusRow && c == sel.focusCol;
      Color? cellBg;
      if (selected) {
        cellBg = selColor;
      } else if (isDeleted) {
        cellBg = cs.errorContainer.withValues(alpha: 0.3);
      } else if (isCellUpdated) {
        cellBg = Colors.amber.withValues(alpha: 0.15);
      }
      if (!selected && !focused && cellBg == null) return child;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: cellBg,
          border: focused ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        child: child,
      );
    }

    final grid = FixedGridView(
      verticalDetails: ScrollableDetails.vertical(controller: _v),
      horizontalDetails: ScrollableDetails.horizontal(controller: _h),
      rowHeight: kGridRowHeight,
      columnWidths: [rowHeaderW, ..._widths],
      colors: GridPaintColors(
        line: cs.outlineVariant,
        stripe: cs.surfaceContainerLowest,
      ),
      delegate: TwoDimensionalChildBuilderDelegate(
        maxXIndex: cols.length,
        maxYIndex: win.rowCount,
        builder: (_, v) => cell(v.yIndex, v.xIndex),
      ),
    );

    final focusRow = sel?.focusRow, focusCol = sel?.focusCol;
    final viewerRow = _viewer && focusRow != null && focusCol != null
        ? window.rowAt(focusRow)
        : null;

    return Semantics(
      container: true,
      label: 'Result grid, ${win.rowCount} rows, ${cols.length} columns',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GridToolbar(
            selection: sel,
            hasRows: win.rowCount > 0,
            onCopy: (f, h) => unawaited(_copy(format: f, header: h)),
            onCopyAll: (f, h) =>
                unawaited(_copy(format: f, header: h, all: true)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _focus,
                    autofocus: true,
                    onKeyEvent: _onKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTapDown: (d) => _lastDoubleTap = d.localPosition,
                      onDoubleTap: _onDoubleTap,
                      child: Listener(
                        onPointerDown: _onDown,
                        onPointerMove: _onMove,
                        child: Scrollbar(
                          controller: _v,
                          thumbVisibility: true,
                          notificationPredicate: (n) =>
                              n.metrics.axis == Axis.vertical,
                          child: Scrollbar(
                            controller: _h,
                            thumbVisibility: true,
                            notificationPredicate: (n) =>
                                n.metrics.axis == Axis.horizontal,
                            child: grid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_viewer &&
                    focusRow != null &&
                    focusCol != null &&
                    focusCol < cols.length)
                  ValueViewerPanel(
                    value: viewerRow != null && focusCol < viewerRow.length
                        ? viewerRow[focusCol]
                        : null,
                    column: cols[focusCol],
                    row: focusRow,
                    onClose: () => setState(() => _viewer = false),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.style,
    required this.onTap,
    required this.onResize,
    this.sortIndicator,
  });

  final ResultColumn column;
  final TextStyle style;
  final VoidCallback onTap;
  final ValueChanged<double> onResize;
  final String? sortIndicator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Tooltip(
            message: column.typeName.isEmpty
                ? column.name
                : '${column.name} (${column.typeName})',
            waitDuration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Align(
                alignment: column.kind.isNumeric
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        column.name,
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sortIndicator != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        sortIndicator!,
                        style: style.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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

class _GridToolbar extends StatelessWidget {
  const _GridToolbar({
    required this.selection,
    required this.hasRows,
    required this.onCopy,
    required this.onCopyAll,
  });

  final GridSelection? selection;
  final bool hasRows;
  final void Function(CopyFormat format, bool header) onCopy;
  final void Function(CopyFormat format, bool header) onCopyAll;

  @override
  Widget build(BuildContext context) {
    final sel = selection;
    final label = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sel == null ? '' : '${sel.rowCount} × ${sel.colCount} selected',
              style: label,
            ),
          ),
          PopupMenuButton<(CopyFormat, bool, bool)>(
            key: const Key('grid-copy-menu'),
            tooltip: 'Copy',
            enabled: hasRows,
            icon: const Icon(Icons.copy_all, size: 16),
            onSelected: (v) =>
                v.$3 ? onCopyAll(v.$1, v.$2) : onCopy(v.$1, v.$2),
            itemBuilder: (_) => [
              if (sel != null) ...[
                const PopupMenuItem(
                  value: (CopyFormat.tsv, false, false),
                  child: Text('Copy selection (TSV)'),
                ),
                const PopupMenuItem(
                  value: (CopyFormat.tsv, true, false),
                  child: Text('Copy selection with header'),
                ),
                const PopupMenuItem(
                  value: (CopyFormat.csv, true, false),
                  child: Text('Copy selection as CSV'),
                ),
                const PopupMenuItem(
                  value: (CopyFormat.json, false, false),
                  child: Text('Copy selection as JSON'),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: (CopyFormat.tsv, true, true),
                child: Text('Copy all (TSV)'),
              ),
              const PopupMenuItem(
                value: (CopyFormat.csv, true, true),
                child: Text('Copy all as CSV'),
              ),
              const PopupMenuItem(
                value: (CopyFormat.json, false, true),
                child: Text('Copy all as JSON'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyProgressDialog extends StatelessWidget {
  const _CopyProgressDialog({
    required this.progress,
    required this.total,
    required this.onCancel,
  });

  final ValueListenable<int> progress;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('copy-progress'),
      title: const Text('Copying…'),
      content: ValueListenableBuilder<int>(
        valueListenable: progress,
        builder: (_, n, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: total > 0 ? (n / total).clamp(0.0, 1.0) : null,
            ),
            const SizedBox(height: 8),
            Text('$n of $total rows'),
          ],
        ),
      ),
      actions: [TextButton(onPressed: onCancel, child: const Text('Cancel'))],
    );
  }
}
