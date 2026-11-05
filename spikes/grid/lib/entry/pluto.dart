import 'package:flutter/widgets.dart';

import '../app.dart';
import '../grids/grid_handle.dart';
import '../grids/pluto_grid_variant.dart';

const grid = 'pluto';
Widget build(GridArgs a, String m) => PlutoGridVariant(args: a);

void main() {
  harness = Harness(grid, kMode);
  runApp(const SpikeApp(builder: build));
}
