// syncfusion_flutter_datagrid variant (Syncfusion Community/commercial license).
//
// Full mode: a materialized List<DataGridRow> (the documented way).
// Window mode: a lazy List<DataGridRow> over the WindowStore, which works only
// while sorting/grouping/filtering are off (those call rows.toList()).
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../data/dataset.dart';
import 'grid_handle.dart';

const Set<int> _numeric = {0, 4, 5, 11};

class SyncfusionGridVariant extends StatefulWidget {
  const SyncfusionGridVariant({
    super.key,
    required this.args,
    required this.window,
  });
  final GridArgs args;
  final bool window;
  @override
  State<SyncfusionGridVariant> createState() => _SyncfusionGridVariantState();
}

class _SyncfusionGridVariantState extends State<SyncfusionGridVariant>
    implements GridHandle {
  final _controller = DataGridController();
  final List<double> _widths = List.filled(kColumns.length, kColWidth);
  late final _Source _source;

  @override
  void initState() {
    super.initState();
    if (widget.window) {
      _source = _Source(_LazyRows(widget.args.store));
      widget.args.store.addListener(_source.refresh);
    } else {
      _source = _Source(<DataGridRow>[]);
      widget.args.registerSink(_onBatch);
    }
    widget.args.onHandle(this);
  }

  @override
  void dispose() {
    if (widget.window) widget.args.store.removeListener(_source.refresh);
    super.dispose();
  }

  void _onBatch(int start, List<List<Object?>> batch) {
    final list = _source.rows;
    for (final r in batch) {
      list.add(
        DataGridRow(
          cells: [
            for (var i = 0; i < kColumns.length; i++)
              DataGridCell<Object?>(columnName: kColumns[i], value: r[i]),
          ],
        ),
      );
    }
    _source.refresh();
  }

  @override
  Future<void> jumpToRow(int row) => _controller.scrollToRow(row.toDouble());

  @override
  void resizeColumn(int col, double delta) =>
      setState(() => _widths[col] += delta);

  @override
  Future<String?> selectAndCopy(int r0, int c0, int r1, int c1) async {
    // Only whole-row selection exists; no built-in copy. Build TSV ourselves.
    final rows = _source.rows;
    _controller.selectedRows = [for (var r = r0; r <= r1; r++) rows[r]];
    final text = toTsv(
      _controller.selectedRows.map(
        (r) => [for (final c in r.getCells()) c.value],
      ),
      c0,
      c1,
    );
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  @override
  int? get currentRow => _controller.currentCell.rowIndex;

  @override
  Widget build(BuildContext context) {
    _source.style = Theme.of(context).textTheme.bodySmall!;
    return SfDataGrid(
      source: _source,
      controller: _controller,
      rowHeight: kRowHeight,
      headerRowHeight: kRowHeight,
      gridLinesVisibility: GridLinesVisibility.both,
      headerGridLinesVisibility: GridLinesVisibility.both,
      selectionMode: SelectionMode.multiple,
      navigationMode: GridNavigationMode.cell,
      allowColumnsResizing: true,
      columnResizeMode: ColumnResizeMode.onResize,
      onColumnResizeUpdate: (d) {
        setState(() => _widths[d.columnIndex] = d.width);
        return true;
      },
      columns: [
        for (var i = 0; i < kColumns.length; i++)
          GridColumn(
            columnName: kColumns[i],
            width: _widths[i],
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: Text(kColumns[i], overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }
}

class _Source extends DataGridSource {
  _Source(this._rows);
  final List<DataGridRow> _rows;
  TextStyle style = const TextStyle();

  @override
  List<DataGridRow> get rows => _rows;

  void refresh() => notifyListeners();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final cells = row.getCells();
    return DataGridRowAdapter(
      cells: [
        for (var i = 0; i < cells.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: _numeric.contains(i)
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              formatValue(cells[i].value),
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _LazyRows extends ListBase<DataGridRow> {
  _LazyRows(this.store);
  final RowStore store;
  final Map<int, _LazyRow> _live = {};

  @override
  int get length => store.rowCount;
  @override
  set length(int v) => throw UnsupportedError('read-only');
  @override
  DataGridRow operator [](int i) {
    // Keep identity stable for the few rows the grid holds on to.
    if (_live.length > 4000) _live.clear();
    return _live.putIfAbsent(i, () => _LazyRow(store, i));
  }

  @override
  void operator []=(int i, DataGridRow v) =>
      throw UnsupportedError('read-only');
}

class _LazyRow extends DataGridRow {
  _LazyRow(this.store, this.index) : super(cells: const []);
  final RowStore store;
  final int index;
  @override
  List<DataGridCell> getCells() {
    final r = store.rowAt(index);
    return [
      for (var i = 0; i < kColumns.length; i++)
        DataGridCell<Object?>(
          columnName: kColumns[i],
          value: r == null ? '…' : r[i],
        ),
    ];
  }
}
