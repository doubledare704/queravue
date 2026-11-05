// Drives one editor through the spike scenarios. Run in profile mode:
//   flutter drive --profile -d macos --endless-trace-buffer \
//     --driver=test_driver/perf_driver.dart --target=integration_test/perf_<editor>_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:editor_spike/app.dart';
import 'package:editor_spike/editors/editor_handle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _streams = ['Dart', 'Embedder', 'GC'];
int _rssMb() => ProcessInfo.currentRss ~/ (1 << 20);

Future<void> _idle(WidgetTester t, [int ms = 1000]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

/// Runs one step with a marker and a time limit; a timed-out step is recorded
/// and the scenario continues.
Future<void> _step(Map<String, Object?> m, String name, Future<void> Function() body,
    {Duration limit = const Duration(minutes: 5)}) async {
  debugPrint('STEP $name ${DateTime.now().toIso8601String()}');
  final sw = Stopwatch()..start();
  try {
    await body().timeout(limit);
  } on Exception catch (e) {
    m['${name}_failed'] = '${e.runtimeType} after ${sw.elapsed.inSeconds}s';
  }
}

Map<String, num> _pct(List<double> v) {
  v.sort();
  double q(double p) => v[((v.length - 1) * p).round()];
  double r(double x) => (x * 100).round() / 100;
  return {'n': v.length, 'p50': r(q(.5)), 'p90': r(q(.9)), 'p99': r(q(.99)), 'worst': r(v.last)};
}

Future<String> _snapshot(WidgetTester t) async {
  final rb = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('editor')));
  final img = await rb.toImage(pixelRatio: 0.6);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return base64Encode(bytes!.buffer.asUint8List());
}

void runEditorPerf(String editor, EditorBuilder build) {
  harness = Harness(editor);
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('editor perf: $editor', timeout: const Timeout(Duration(minutes: 20)), (tester) async {
    final m = <String, Object?>{'editor': editor};
    await tester.pumpWidget(SpikeApp(builder: build));
    await _idle(tester, 1500);
    m['rss_idle_mb'] = _rssMb();

    // 1. Load the 5,000-line script; time to first frame showing it.
    final sw = Stopwatch()..start();
    await binding.traceAction(() async {
      harness.load();
      await tester.pump();
      m['load_first_frame_ms'] = sw.elapsedMilliseconds;
      await _idle(tester, 1500);
    }, reportKey: 'load', streams: _streams);
    final h = harness.handle!;
    m['lines'] = h.lineCount;
    m['rss_loaded_mb'] = _rssMb();
    final center = tester.getCenter(find.byKey(const ValueKey('editor')));

    // 2. Typing in the middle of the file: mutation + one frame per keystroke.
    debugPrint('STEP cursor ${DateTime.now().toIso8601String()}');
    h.moveCursorTo(2500, 0);
    await _idle(tester, 500);
    const typed = "SELECT id, name FROM crm.customers WHERE region = 'eu' ORDER BY id;\n";
    final keys = <double>[];
    await _step(m, 'typing', () => binding.traceAction(() async {
      final deadline = Stopwatch()..start();
      outer:
      for (var rep = 0; rep < 3; rep++) {
        for (final ch in typed.split('')) {
          // Self-limit: a timeout cannot cancel this loop, so stop it here.
          if (deadline.elapsed > const Duration(seconds: 60)) {
            m['typing_stopped_after_s'] = 60;
            break outer;
          }
          final k = Stopwatch()..start();
          h.insert(ch);
          await tester.pump();
          keys.add(k.elapsedMicroseconds / 1000);
        }
      }
    }, reportKey: 'typing', streams: _streams));
    if (keys.isNotEmpty) m['keystroke_ms'] = _pct(keys);

    // 3. Wheel scroll through the file.
    await _step(m, 'scroll', () => binding.traceAction(() async {
      final p = TestPointer(9, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(p.hover(center));
      final deadline = Stopwatch()..start();
      for (var i = 0; i < 200 && deadline.elapsed < const Duration(seconds: 60); i++) {
        await tester.sendEventToBinding(p.scroll(const Offset(0, 120)));
        await tester.pump();
      }
    }, reportKey: 'scroll', streams: _streams));

    // 4. Find and replace.
    await _step(m, 'find', () async {
      final f = Stopwatch()..start();
      m['find_matches'] = await h.find('JOIN');
      m['find_ms'] = f.elapsedMilliseconds;
    });
    await _idle(tester, 300);
    await _step(m, 'replace', () async {
      final r = Stopwatch()..start();
      m['replace_all_matches'] = await h.replaceAll('JOIN', 'INNER JOIN');
      await tester.pump();
      m['replace_all_ms'] = r.elapsedMilliseconds;
    });
    await _idle(tester, 300);

    // 5. Autocomplete hook: type a prefix and see whether our popup is used.
    // Typed through the text-input channel (as the macOS IME does), because
    // re_editor only opens completions for user input, not controller edits.
    await _step(m, 'autocomplete', () async {
      tester.testTextInput.register();
      await tester.tapAt(center);
      await _idle(tester, 200);
      h.moveCursorTo(9, 0); // empty line, so the typed prefix is the whole word
      await _idle(tester, 300);
      for (final ch in 'cust'.split('')) {
        final st = tester.testTextInput.editingState;
        if (st == null) {
          m['ime_state_missing'] = true;
          break;
        }
        final text = st['text'] as String;
        final a = st['selectionBase'] as int, b = st['selectionExtent'] as int;
        final lo = a < b ? a : b, hi = a < b ? b : a;
        tester.testTextInput.updateEditingValue(TextEditingValue(
          text: text.replaceRange(lo, hi, ch),
          selection: TextSelection.collapsed(offset: lo + 1),
        ));
        await _idle(tester, 80);
      }
      await _idle(tester, 300);
      m['custom_popup'] = find.byKey(kCustomPopupKey).evaluate().isNotEmpty || h.customPopupVisible;
      m['any_popup_text_customers'] = find.textContaining('customers').evaluate().length;
      tester.testTextInput.unregister();
    });
    m['multi_cursor'] = h.supportsMultiCursor;

    // 6. Theme.
    debugPrint('STEP theme ${DateTime.now().toIso8601String()}');
    m['img_light'] = await _snapshot(tester);
    harness.dark.value = true;
    await _idle(tester, 800);
    m['img_dark'] = await _snapshot(tester);

    m['rss_end_mb'] = _rssMb();
    m['rss_peak_mb'] = ProcessInfo.maxRss ~/ (1 << 20);
    binding.reportData = {...?binding.reportData, ...m};
  });
}
