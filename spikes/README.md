# Iteration 2 spikes (throwaway)

Throwaway apps used to pick the result grid (ADR 0004) and the SQL editor
(ADR 0005). Nothing here is imported by `app/` or `core/`. Delete the folder
once Iteration 2 ships.

## grid/

A 1,000,000 × 12 synthetic result (`lib/data/dataset.dart`) is streamed to the UI
in 500-row batches (`feed()` yields to the event loop between batches, like a
gRPC server stream). Each grid sits behind the same `GridHandle`, so one
scenario (`integration_test/scenario.dart`) drives all of them.

| entry (`lib/entry/`) | what it is |
|---|---|
| `tableview` | our thin grid on `two_dimensional_scrollables` `TableView` |
| `fixedgrid` | the same thin grid on `FixedGridView` (`lib/grids/fixed_grid_view.dart`), a fixed-row-height viewport on the SDK's `TwoDimensionalScrollView` |
| `trina` | `trina_grid` |
| `pluto` | `pluto_grid` |
| `syncfusion` | `syncfusion_flutter_datagrid` |

`MODE=full` keeps every row in memory. `MODE=window` (tableview, fixedgrid,
syncfusion) uses `WindowStore`: an LRU of 40 pages × 500 rows. Missing pages
are "fetched" asynchronously, standing in for a core `FetchRows` RPC.

Each grid has its own entrypoint. With Flutter 3.47.9, a profile (AOT) build
that links all four grid packages into one binary crashes `gen_snapshot`
("Class with illegal cid … `_window_macos.dart` `_Rect`"). Each package builds
fine on its own, and one entrypoint per grid also keeps each binary's memory
limited to its own grid.

Run (macOS, profile mode; the window is fixed at 1440×900):

```bash
cd spikes/grid
tool/run_all.sh                 # traced runs -> build/perf/*.json + *.timeline.json
tool/run_mem.sh                 # same actions, no timeline capture -> clean RSS
python3 tool/frame_stats.py build/perf > build/perf_summary.json
```

Frame stats come from the raw timelines. UI time is the async `Frame` event
(build + layout + paint on the UI thread). Raster time is `GPURasterizer::Draw`
on `io.flutter.raster`. Memory is process RSS (`ProcessInfo.currentRss`) of the
whole app, including the integration_test harness, so compare deltas, not
absolutes.

## editor/

A 5,000-line generated SQL script (`lib/sql_sample.dart`) is loaded into
`re_editor` or `flutter_code_editor`. Then the scenario types 207 characters at
line 2,500, wheel-scrolls the file, runs find and replace-all, types a prefix
to trigger completions, and switches theme. "Keystroke latency" covers one
mutation through the editor's own editing path plus the frame that shows it.

```bash
cd spikes/editor
flutter drive --profile -d macos --endless-trace-buffer --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_re_editor_test.dart     # or perf_fce_test.dart
python3 tool/frame_stats.py build/perf
```
