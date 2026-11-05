import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/grid/presentation/fixed_grid_view.dart';

Widget _grid({
  required int rows,
  required int cols,
  List<int>? built,
  ScrollController? v,
}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 400,
      height: 300,
      child: FixedGridView(
        verticalDetails: ScrollableDetails.vertical(controller: v),
        rowHeight: 20,
        columnWidths: List.filled(cols + 1, 80),
        colors: const GridPaintColors(
          line: Colors.grey,
          stripe: Colors.black12,
        ),
        delegate: TwoDimensionalChildBuilderDelegate(
          maxXIndex: cols,
          maxYIndex: rows,
          builder: (_, vic) {
            built?.add(vic.yIndex);
            return Text('${vic.yIndex},${vic.xIndex}');
          },
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('zero rows and zero columns do not throw', (tester) async {
    for (final (r, c) in [(0, 0), (0, 3), (5, 0)]) {
      await tester.pumpWidget(_grid(rows: r, cols: c));
      expect(tester.takeException(), isNull, reason: '$r rows × $c cols');
    }
  });

  testWidgets('layout builds only the visible rows of a million', (
    tester,
  ) async {
    final built = <int>[];
    await tester.pumpWidget(_grid(rows: 1000000, cols: 3, built: built));
    expect(built.where((r) => r > 0).toSet().length, lessThan(20));
    expect(find.text('1,1'), findsOneWidget);
  });

  testWidgets('jumping deep lands on the right rows in O(visible)', (
    tester,
  ) async {
    final v = ScrollController();
    addTearDown(v.dispose);
    final built = <int>[];
    await tester.pumpWidget(_grid(rows: 1000000, cols: 3, built: built, v: v));
    built.clear();
    v.jumpTo(900000 * 20.0);
    await tester.pump();
    expect(find.text('900001,1'), findsOneWidget);
    expect(find.text('0,1'), findsOneWidget, reason: 'header stays pinned');
    expect(built.toSet().length, lessThan(40));
  });
}
