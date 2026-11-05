import 'package:flutter/widgets.dart';

import '../app.dart';
import '../grids/grid_handle.dart';
import '../grids/tableview_grid.dart';

const grid = 'tableview';
Widget build(GridArgs a, String m) => TableViewGrid(args: a);

void main() {
  harness = Harness(grid, kMode);
  runApp(const SpikeApp(builder: build));
}
