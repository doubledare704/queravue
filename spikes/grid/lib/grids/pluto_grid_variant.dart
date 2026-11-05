// pluto_grid variant. pluto owns PlutoRow/PlutoCell models for every row, so
// there is no window mode: all streamed rows are converted and appended.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../data/dataset.dart';
import 'grid_handle.dart';

class PlutoGridVariant extends StatefulWidget {
  const PlutoGridVariant({super.key, required this.args});
  final GridArgs args;
  @override
  State<PlutoGridVariant> createState() => _PlutoGridVariantState();
}

class _PlutoGridVariantState extends State<PlutoGridVariant>
    implements GridHandle {
  PlutoGridStateManager? _sm;
  final List<PlutoRow> _pending = [];
  final List<PlutoRow> _rows = []; // must be growable: the grid appends in place

  late final List<PlutoColumn> _columns = [
    for (final c in kColumns)
      PlutoColumn(
        title: c,
        field: c,
        type: PlutoColumnType.text(),
        readOnly: true,
        width: kColWidth,
        enableContextMenu: false,
        enableColumnDrag: false,
      ),
  ];

  @override
  void initState() {
    super.initState();
    widget.args.registerSink(_onBatch);
    widget.args.onHandle(this);
  }

  void _onBatch(int start, List<List<Object?>> batch) {
    final rows = [
      for (final r in batch)
        PlutoRow(
          cells: {
            for (var i = 0; i < kColumns.length; i++)
              kColumns[i]: PlutoCell(value: r[i] ?? 'NULL'),
          },
        ),
    ];
    final sm = _sm;
    if (sm == null) {
      _pending.addAll(rows);
    } else {
      sm.appendRows(rows);
    }
  }

  @override
  Future<void> jumpToRow(int row) async {
    final sm = _sm!;
    sm.scroll.bodyRowsVertical!.jumpTo(row * sm.rowTotalHeight);
  }

  @override
  void resizeColumn(int col, double delta) =>
      _sm!.resizeColumn(_sm!.refColumns[col], delta);

  @override
  Future<String?> selectAndCopy(int r0, int c0, int r1, int c1) async {
    final sm = _sm!;
    sm.setSelectingMode(PlutoGridSelectingMode.cell);
    sm.setCurrentCell(sm.refRows[r0].cells[kColumns[c0]], r0);
    sm.setCurrentSelectingPosition(
      cellPosition: PlutoGridCellPosition(columnIdx: c1, rowIdx: r1),
    );
    final text = sm.currentSelectingText;
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  @override
  int? get currentRow => _sm?.currentRowIdx;

  @override
  Widget build(BuildContext context) {
    final dark = widget.args.dark;
    const h = kRowHeight;
    return PlutoGrid(
      columns: _columns,
      rows: _rows,
      onLoaded: (e) {
        _sm = e.stateManager;
        _sm!.setSelectingMode(PlutoGridSelectingMode.cell);
        if (_pending.isNotEmpty) {
          _sm!.appendRows(List.of(_pending));
          _pending.clear();
        }
      },
      configuration: dark
          ? const PlutoGridConfiguration.dark(
              style: PlutoGridStyleConfig.dark(rowHeight: h, columnHeight: h),
            )
          : const PlutoGridConfiguration(
              style: PlutoGridStyleConfig(rowHeight: h, columnHeight: h),
            ),
    );
  }
}
