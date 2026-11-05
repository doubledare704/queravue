import 'package:flutter/widgets.dart';

import '../app.dart';
import '../grids/grid_handle.dart';
import '../grids/trina_grid_variant.dart';

const grid = 'trina';
Widget build(GridArgs a, String m) => TrinaGridVariant(args: a);

void main() {
  harness = Harness(grid, kMode);
  runApp(const SpikeApp(builder: build));
}
