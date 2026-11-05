import 'dart:math' as math;

/// A rectangular cell selection: an anchor cell and a focus cell.
class GridSelection {
  const GridSelection({
    required this.anchorRow,
    required this.anchorCol,
    required this.focusRow,
    required this.focusCol,
  });

  /// A single cell.
  const GridSelection.cell(int row, int col)
    : this(anchorRow: row, anchorCol: col, focusRow: row, focusCol: col);

  /// Every cell of a result.
  const GridSelection.all(int rows, int cols)
    : this(
        anchorRow: 0,
        anchorCol: 0,
        focusRow: rows > 0 ? rows - 1 : 0,
        focusCol: cols > 0 ? cols - 1 : 0,
      );

  final int anchorRow;
  final int anchorCol;
  final int focusRow;
  final int focusCol;

  int get top => math.min(anchorRow, focusRow);
  int get bottom => math.max(anchorRow, focusRow);
  int get left => math.min(anchorCol, focusCol);
  int get right => math.max(anchorCol, focusCol);

  int get rowCount => bottom - top + 1;
  int get colCount => right - left + 1;
  int get cellCount => rowCount * colCount;

  bool contains(int row, int col) =>
      row >= top && row <= bottom && col >= left && col <= right;

  /// Moves the focus to ([row], [col]), clamped to the grid. Without
  /// [extend] the anchor follows, collapsing the selection.
  GridSelection moveFocus(
    int row,
    int col, {
    required bool extend,
    required int rows,
    required int cols,
  }) {
    final r = row.clamp(0, math.max(0, rows - 1)).toInt();
    final c = col.clamp(0, math.max(0, cols - 1)).toInt();
    return GridSelection(
      anchorRow: extend ? anchorRow : r,
      anchorCol: extend ? anchorCol : c,
      focusRow: r,
      focusCol: c,
    );
  }

  /// Selects whole rows between the anchor row and [row].
  GridSelection rows(int row, {required bool extend, required int cols}) =>
      GridSelection(
        anchorRow: extend ? anchorRow : row,
        anchorCol: 0,
        focusRow: row,
        focusCol: math.max(0, cols - 1),
      );

  /// Selects a whole column.
  GridSelection column(int col, {required int rows}) => GridSelection(
    anchorRow: 0,
    anchorCol: col,
    focusRow: math.max(0, rows - 1),
    focusCol: col,
  );

  @override
  bool operator ==(Object other) =>
      other is GridSelection &&
      other.anchorRow == anchorRow &&
      other.anchorCol == anchorCol &&
      other.focusRow == focusRow &&
      other.focusCol == focusCol;

  @override
  int get hashCode => Object.hash(anchorRow, anchorCol, focusRow, focusCol);
}
