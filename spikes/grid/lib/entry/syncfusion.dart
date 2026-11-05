import 'package:flutter/widgets.dart';

import '../app.dart';
import '../grids/grid_handle.dart';
import '../grids/syncfusion_grid_variant.dart';

const grid = 'syncfusion';
Widget build(GridArgs a, String m) =>
    SyncfusionGridVariant(args: a, window: m == 'window');

void main() {
  harness = Harness(grid, kMode);
  runApp(const SpikeApp(builder: build));
}
