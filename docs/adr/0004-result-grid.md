# ADR 0004 — Result grid: own grid on a fixed-row-height 2D viewport

**Status:** Accepted · 2026-11-05

## Context
ROADMAP It. 2 needs a result grid that can show `SELECT * FROM generate_series(1,1000000)`, scroll it smoothly and stay within the PRD §7 budget: a 1M-row result may add at most +200 MB, and "the grid only keeps a window of rows in memory". It also needs column resize, multi-cell selection with copy, keyboard navigation and light/dark theming.

PRD §10 left the choice open: a custom grid, or pluto_grid, trina_grid or Syncfusion. The working hypothesis was a custom grid on `two_dimensional_scrollables`' `TableView`, because then we control the memory window.

## Spike
Code is in `spikes/grid/`; method and how to re-run are in `spikes/README.md`.

- **Data:** 1,000,000 rows × 12 columns (ints, doubles, bools, 6 string columns, 11% NULLs) streamed in 500-row batches.
- **Setup:** profile build, macOS 27.2, Apple M4 Pro, window 1440×900, Flutter 3.47.9.
- **Two modes:** *full* keeps every row in the UI. *Window* keeps an LRU of 40 pages × 500 rows (20k rows) and fetches missing pages asynchronously, standing in for a core RPC.
- **Candidates:**
  1. **TableView grid**: our thin grid (header, row numbers, selection, keyboard, TSV copy, resize) on `TableView` 0.5.6.
  2. **FixedGrid**: the same grid code on `FixedGridView`, a ~250-line fixed-row-height viewport on the SDK's `TwoDimensionalScrollView` (`spikes/grid/lib/grids/fixed_grid_view.dart`). It was added during the spike after (1) failed.
  3. trina_grid 2.4.0.
  4. pluto_grid 8.1.0.
  5. syncfusion_flutter_datagrid 35.1.43.

## Results
How to read the numbers:
- **Frame times** are UI-thread ms per frame (build + layout + paint), as p90 / worst, from `traceAction` timelines. Raster time was at most 2.3 ms at p90 for every candidate, so it is not shown.
- **Memory** is process RSS after loading the rows, minus RSS of the idle app, from runs without timeline capture.
- **Jump** is the time from `jumpTo(row 900000)` until the id cell `900000` is on screen.
- **Steady scroll** is a wheel scroll of ~4 rows per frame. **Fast scroll** moves 100 rows per frame, so every visible row changes every frame.

| | FixedGrid · window | FixedGrid · full | TableView grid · window | TableView grid · full | Syncfusion · full | Syncfusion · window | pluto · full | trina · full |
|---|---|---|---|---|---|---|---|---|
| **Memory, 1M rows loaded** | **+40 MB** | +437 MB | +295 MB | +683 MB | +881 MB | hangs (see below) | +1,936 MB | +2,559 MB |
| Peak RSS during run | 250 MB | 739 MB | 590 MB | 1,159 MB | 1,181 MB | — | 2,801 MB | 3,623 MB |
| Stream 1M rows (2,000 batches) | 0.5 s | 0.7 s | 1.7 s | 2.2 s | 1.5 s | — | 2.8 s | **44.6 s**, UI frozen (15 frames drawn) |
| Frames while streaming, p90 | 2.4 ms | 3.3 ms | **156 ms** | **184 ms** | 17.1 ms | — | 7.7 ms | 6.7 ms (but see above) |
| Steady scroll, p90 / worst | **5.8 / 9.2** | 7.3 / 10.5 | 10.7 / 12.8 | 10.7 / 12.6 | 9.6 / 11.1 | — | 9.5 / 13.1 | 13.0 / 16.4 |
| Fast scroll, p90 | 18.4 | 21.1 | 34.7 | 40.1 | 22.2 | — | 44.6 | 37.1 |
| Steady scroll at row 900k, p90 | 6.7 | 8.4 | 10.8 (one 237 ms fetch frame) | 10.8 | 9.4 | — | 9.6 | 12.4 |
| Jump to row 900k | 31 ms | 19 ms | 21 ms | 25 ms | 22 ms | — | 53 ms | **not reached** (row 900000 not visible after 1.5 s) |
| Column resize, p90 / worst | 4.8 / 6.0 | 5.7 / 6.3 | **261 / 268** | **288 / 297** | 9.8 / 27.0 | — | 7.4 / 8.5 | 6.6 / 7.2 |
| Keyboard nav (arrows / PgDn), p90 / worst | 10.7 / 19.4 | 11.1 / 16.8 | **264 / 286** | **297 / 309** | 22.6 / 36.8 | — | 5.6 / 26.1 | 14.1 / 29.9 |
| Theme switch, worst frame | 15.0 | 16.3 | 254 | 300 | 42.0 | — | 18.9 | 72.2 |
| Multi-cell selection | own (rectangular, mouse / shift / keyboard) | same | same | same | **rows only** | — | built-in cell range | built-in cell range |
| Copy 1k × 12 cells | 3 ms | 4 ms | 3 ms | 3 ms | **2.2 s** (no built-in copy; we build TSV from `selectedRows`) | hangs | 6 ms (built-in ⌘C) | 19 ms (built-in ⌘C) |
| Copy 100k × 3 cells | 143 ms | 79 ms | 132 ms | 64 ms | **14.1 s** | — | 94 ms | 201 ms |
| Light/dark theming | from `ColorScheme`, no extra code | same | same | same | `SfDataGridTheme` | — | separate `PlutoGridConfiguration.dark()` | `TrinaGridConfiguration.dark()` or `TrinaGridStyleConfig.fromTheme()` |
| Can use a row window | **yes** (grid reads rows by index) | — | yes, but TableView still stores per-row metrics | — | only through a lazy `List<DataGridRow>`, which hangs (below) | **no** | no: needs `PlutoRow` objects for every row | no: needs `TrinaRow` objects for every row |
| License | BSD-3 (SDK + our code) | | BSD-3 (flutter.dev package) | | **Syncfusion Community / commercial** | | MIT (last release 2025-12) | MIT (active fork of pluto) |

### Findings
1. **TableView is O(rows) per relayout.** With a finite `rowCount`, any delegate change makes `RenderTableViewport._updateRowMetrics` walk every row. That covers a new streamed batch, a column width change, a selection/focus change (which rebuilds the delegate) and a theme switch. Each walk calls `rowBuilder` and stores one `_Span` per row. At 1M rows that costs ~230–300 ms per frame. It explains the resize, keyboard, streaming and theme numbers, and the extra ~255 MB in window mode (1M `_Span` objects). Scrolling alone does not trigger the walk, which is why steady scroll looks fine. The hypothesis is **half right**: owning the row window is correct, but TableView is the wrong viewport at 1M rows unless upstream adds a uniform-extent fast path.
2. **A fixed-row-height viewport removes that cost.** It works out the visible rows as `offset ~/ rowHeight` and has no per-row state, so layout is O(visible cells) whatever the row count. The same grid code on `FixedGridView` holds 5–11 ms p90 for every interaction at 1M rows. Pinned header and row-number column are painted in separate clipped passes.
3. **The row window is required by the budget.** Even our lean in-memory representation (`List<Object?>` per row) costs +437 MB for 1M rows. trina, pluto and Syncfusion wrap every cell in their own objects and cost 2–6× more (+0.9 to +2.6 GB). Only the windowed store (+40 MB) meets the +200 MB budget.
4. **Syncfusion cannot sit on a window.** It identifies rows by object identity and does linear `indexOf` / `contains` scans over `rows` and `selectedRows`. A lazy row list therefore hung the app in the selection step: 100% CPU, killed after 8+ minutes, reproduced twice. Even in full mode, copying 1k selected rows took 2.2 s and 100k rows took 14 s. Selection is whole rows only, and it has no clipboard support. Its license also rules it out on its own. It is free only for organisations under US$1M revenue with fewer than 5 developers, and "under no circumstances" without a Community or commercial license (`syncfusion_flutter_core/LICENSE`). That does not fit a free, possibly open-source app whose contributors and forkers would each need their own license.
5. **trina and pluto** have the best built-in features: cell-range selection, ⌘C, resize, keyboard navigation and dark configs. But both require a model object per row, so they cannot meet the memory budget at 1M rows. trina also freezes the UI for 45 s while appending 1M rows, and its jump did not land on row 900k. pluto is fast but uses +1.9 GB, and its last release was 2025-12.
6. **What all candidates have in common:** fast scroll (100 new rows per frame) costs 14–27 ms p50 in every grid. That is cell widget build plus text layout. For FixedGrid it is the next optimisation target: paragraph caching, or painting text directly in the render object instead of one `Text` widget per cell.

## Decision
Build the result grid ourselves on **`FixedGridView`**, a fixed-row-height viewport on the SDK's `TwoDimensionalScrollView`. It reads rows by index from a **windowed row store** that holds a bounded number of 500-row pages and fetches missing pages from core.

- `app/lib/features/grid/`: viewport (from the spike, hardened), a `ResultWindow` controller (a Riverpod notifier that adapts a plain-Dart LRU page cache), plus cell rendering, selection, keyboard and clipboard.
- Uniform row height is part of the contract. Multi-line cell values are shown truncated and opened in a value viewer.
- Copy of large ranges, and "copy all", is served by core (format in core, stream to the clipboard / export), not by materialising rows in the UI.
- Do not add trina_grid, pluto_grid, syncfusion_flutter_datagrid or two_dimensional_scrollables to `app/`.

## Consequences
- **Proto change needed (ask first, per AGENTS.md):** the window store needs core to keep a server-side result cursor or spool and answer `FetchRows(result_id, offset, limit)`. The current streaming `Execute` keeps working for the first window and for small results. This must go through the `proto-change` workflow before It. 2 implementation.
- We own grid features that libraries would have given us: sort indicators, column reorder, a value viewer, semantics/accessibility and RTL. Sorting and filtering of large results are pushed down to SQL in core, which is also the only way they scale.
- Fast-scroll frame time (≈18 ms p90) misses a 120 Hz budget. It is acceptable for It. 2 and tracked as a perf item for the `perf-check` skill.
- A grid golden test and an integration test with 1M rows (both modes) are added to `app/` when the grid lands, reusing the spike scenario.
- Spike-only note: Flutter 3.47.9's `gen_snapshot` crashes building a profile binary that links all four grid packages together ("illegal cid … `_window_macos.dart`"). It is moot once only our grid ships, but worth reporting upstream.

## Alternatives considered
- **TableView grid:** rejected. It is O(rows) per relayout and stores per-row metrics (finding 1).
- **trina_grid / pluto_grid:** rejected. They need a model per row, so no window and +1.9 to +2.6 GB at 1M rows. trina also freezes on load.
- **syncfusion_flutter_datagrid:** rejected. Its license doesn't fit a free app, it hangs with a windowed row source, selection is rows only, and copy has no built-in support and is slow.
