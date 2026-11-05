import 'package:flutter/widgets.dart';

import '../data/dataset.dart';

const double kRowHeight = 28;
const double kColWidth = 130;

/// Uniform control surface so one integration test drives every grid.
abstract class GridHandle {
  /// Scrolls so [row] is at the top of the viewport.
  Future<void> jumpToRow(int row);

  /// Widens column [col] by [delta] logical px, the same path a header drag uses.
  void resizeColumn(int col, double delta);

  /// Selects the rectangle and returns the text that copy would put on the
  /// clipboard (TSV), or null if the grid cannot do it.
  Future<String?> selectAndCopy(int r0, int c0, int r1, int c1);

  /// Row index of the focused/current cell, if the grid has one.
  int? get currentRow;
}

typedef BatchSink = void Function(int start, List<List<Object?>> rows);

class GridArgs {
  GridArgs({
    required this.store,
    required this.dark,
    required this.onHandle,
    required this.registerSink,
  });
  final RowStore store;
  final bool dark;
  final ValueChanged<GridHandle> onHandle;

  /// Grids that own their row models register a sink that receives each batch.
  final ValueChanged<BatchSink> registerSink;
}

String toTsv(Iterable<List<Object?>> rows, int c0, int c1) {
  final sb = StringBuffer();
  for (final r in rows) {
    for (var c = c0; c <= c1; c++) {
      if (c > c0) sb.write('\t');
      sb.write(formatValue(r[c]));
    }
    sb.write('\n');
  }
  return sb.toString();
}
