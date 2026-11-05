// Drives one grid variant through the spike scenarios. Run in profile mode:
//   flutter drive --profile -d macos --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_<grid>_test.dart [--dart-define=MODE=window]
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_spike/app.dart';
import 'package:grid_spike/data/dataset.dart';
import 'package:integration_test/integration_test.dart';

const _streams = ['Dart', 'Embedder', 'GC'];

/// TRACE=false runs the same actions without timeline capture, for clean RSS.
const _trace = bool.fromEnvironment('TRACE', defaultValue: true);

int _rssMb() => ProcessInfo.currentRss ~/ (1 << 20);

Future<void> _idle(WidgetTester t, [int ms = 1500]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _wheel(WidgetTester t, Offset at, double dy, int frames) async {
  final p = TestPointer(7, PointerDeviceKind.mouse);
  await t.sendEventToBinding(p.hover(at));
  for (var i = 0; i < frames; i++) {
    await t.sendEventToBinding(p.scroll(Offset(0, dy)));
    await t.pump();
  }
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey k, PhysicalKeyboardKey p) async {
  await t.sendKeyDownEvent(k, physicalKey: p);
  await t.sendKeyUpEvent(k, physicalKey: p);
}

Future<String> _snapshot(WidgetTester t) async {
  final rb = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('grid')));
  final img = await rb.toImage(pixelRatio: 0.6);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return base64Encode(bytes!.buffer.asUint8List());
}

Future<void> _traced(IntegrationTestWidgetsFlutterBinding b, Future<void> Function() action,
    {required String reportKey, List<String> streams = _streams}) {
  // Step marker so a hung run shows where it stopped.
  debugPrint('STEP $reportKey ${DateTime.now().toIso8601String()}');
  if (!_trace) return action();
  return b.traceAction(action, reportKey: reportKey, streams: streams);
}

void runGridPerf(String grid, GridBuilder build) {
  harness = Harness(grid, kMode);
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('grid perf: $grid/$kMode', timeout: const Timeout(Duration(minutes: 30)),
      (tester) async {
    final m = <String, Object?>{'grid': grid, 'mode': _trace ? kMode : '${kMode}_mem', 'rows': kTotalRows};
    final errors = <String>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.exceptionAsString().split('\n').first);
      prevOnError?.call(d);
    };

    await tester.pumpWidget(SpikeApp(builder: build));
    await _idle(tester, 2000);
    m['rss_idle_mb'] = _rssMb();

    // 1. Stream 1M rows in 500-row batches while the UI renders.
    late Duration load;
    await _traced(binding, () async {
      load = await harness.load();
      await _idle(tester, 300);
    }, reportKey: 'load', streams: _streams);
    m['load_ms'] = load.inMilliseconds;
    await _idle(tester, 3000);
    m['rss_loaded_mb'] = _rssMb();
    m['resident_rows'] = harness.store.residentRows;
    final h = harness.handle!;
    final center = tester.getCenter(find.byKey(const ValueKey('grid')));

    // 2. Steady wheel scroll (~4 rows per frame) and fast scroll (100 rows per frame).
    await _traced(binding, () => _wheel(tester, center, 120, 240), reportKey: 'scroll_steady', streams: _streams);
    await _traced(binding, () => _wheel(tester, center, 2800, 120), reportKey: 'scroll_fast', streams: _streams);

    // 3. Jump to row 900k; time until the id cell "900000" is on screen.
    final sw = Stopwatch()..start();
    var found = false;
    await _traced(binding, () async {
      await h.jumpToRow(900000);
      for (var i = 0; i < 120 && !found; i++) {
        await tester.pump();
        found = find.text('900000').evaluate().isNotEmpty;
      }
    }, reportKey: 'jump', streams: _streams);
    m['jump_ms'] = sw.elapsedMilliseconds;
    m['jump_found'] = found;
    await _traced(binding, () => _wheel(tester, center, 120, 120), reportKey: 'scroll_900k', streams: _streams);
    m['rss_after_scroll_mb'] = _rssMb();

    // 4. Column resize: 40 frames of +4 px on column 2.
    await _traced(binding, () async {
      for (var i = 0; i < 40; i++) {
        h.resizeColumn(2, 4);
        await tester.pump();
      }
    }, reportKey: 'resize', streams: _streams);

    // 5. Multi-cell selection + copy (1k x 12 near the viewport, then 100k x 3).
    await _traced(binding, () async {
      final s1 = Stopwatch()..start();
      final t1 = await h.selectAndCopy(899000, 0, 899999, 11);
      m['copy_1k_ms'] = s1.elapsedMilliseconds;
      m['copy_1k_lines'] = t1 == null ? null : '\n'.allMatches(t1).length;
      await _idle(tester, 300);
      final s2 = Stopwatch()..start();
      final t2 = await h.selectAndCopy(0, 0, 99999, 2);
      m['copy_100k_ms'] = s2.elapsedMilliseconds;
      m['copy_100k_lines'] = t2 == null ? null : '\n'.allMatches(t2).length;
      await _idle(tester, 300);
    }, reportKey: 'select', streams: _streams);
    await Clipboard.setData(const ClipboardData(text: ''));

    // 6. Keyboard navigation: focus a cell, then arrows / page down.
    await h.jumpToRow(500000);
    await _idle(tester, 500);
    await tester.tapAt(center);
    await _idle(tester, 300);
    final before = h.currentRow;
    await _traced(binding, () async {
      for (var i = 0; i < 150; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      for (var i = 0; i < 20; i++) {
        await _key(tester, LogicalKeyboardKey.pageDown, PhysicalKeyboardKey.pageDown);
        await tester.pump();
      }
      for (var i = 0; i < 11; i++) {
        await _key(tester, LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
        await tester.pump();
      }
    }, reportKey: 'keyboard', streams: _streams);
    m['kbd_row_before'] = before;
    m['kbd_row_after'] = h.currentRow;

    // 7. Theme: light snapshot, switch to dark, dark snapshot.
    m['img_light'] = await _snapshot(tester);
    await _traced(binding, () async {
      harness.dark.value = true;
      await _idle(tester, 600);
    }, reportKey: 'theme', streams: _streams);
    m['img_dark'] = await _snapshot(tester);

    m['rss_end_mb'] = _rssMb();
    m['rss_peak_mb'] = ProcessInfo.maxRss ~/ (1 << 20);
    m['errors'] = errors.toSet().take(10).toList();
    FlutterError.onError = prevOnError;
    binding.reportData = {...?binding.reportData, ...m};
  });
}
