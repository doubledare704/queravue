// Grid perf budget against the real core and the docker Postgres (ADR 0004).
// Scenario from spikes/grid: stream 1M rows, steady scroll, jump to row 900k,
// RSS growth. Thresholds are asserted in profile mode only; debug builds just
// record numbers.
//
//   make db-up core
//   cd app && flutter drive --profile -d macos \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/grid_perf_test.dart
// or `make test-perf`.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/application/query_run.dart';
import 'package:queravue/features/editor/application/query_status.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

int _rssMb() => ProcessInfo.currentRss ~/ (1 << 20);

Future<void> _pumpUntil(
  WidgetTester tester,
  String what,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (done()) return;
  }
  fail('timed out waiting for $what');
}

Future<void> _idle(WidgetTester t, int ms) async {
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    '1M rows: stream, scroll, jump and memory stay within budget',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final report = <String, Object?>{
        'rows': 1000000,
        'mode': kProfileMode ? 'profile' : 'debug',
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QueravueApp(),
        ),
      );
      await _pumpUntil(
        tester,
        'core connected',
        () => container.read(coreStatusProvider) is CoreConnected,
        timeout: const Duration(seconds: 30),
      );

      // A saved connection to the docker Postgres (dev/docker-compose.yml).
      final repo = container.read(connectionsRepositoryProvider);
      final saved = await repo.create(
        ConnectionProfile(
          name: 'perf pg',
          engineId: 'postgres',
          params: {
            'host': _env('PG_HOST', '127.0.0.1'),
            'port': _env('PG_PORT', '5432'),
            'database': _env('PG_DB', 'queravue'),
            'user': _env('PG_USER', 'queravue'),
            'sslmode': 'disable',
          },
        ),
        password: _env('PG_PASSWORD', 'queravue'),
      );
      addTearDown(() => repo.delete(saved.id));
      await container.read(connectionsControllerProvider.notifier).reload();
      container.read(selectedConnectionProvider.notifier).select(saved.id);
      await tester.pumpAndSettle();

      final tab = container.read(editorTabsProvider.notifier).open(saved.id);
      await tester.pumpAndSettle();
      await _idle(tester, 1500);
      final rssIdle = _rssMb();
      report['rss_idle_mb'] = rssIdle;

      // 1. Run: 1M rows into the core's spool; the UI only holds a window.
      tab.controller.text =
          "SELECT g - 1 AS id, md5(g::text) AS hash, 'row ' || g AS label, "
          'g % 7 = 0 AS flag, g * 1.5 AS amount, now() AS ts '
          'FROM generate_series(1, 1000000) g';
      await tester.pump();
      final load = Stopwatch()..start();
      await tester.tap(find.byKey(const Key('run-button')));
      await _pumpUntil(tester, 'run to finish', () {
        final run = container.read(queryRunProvider(tab.id));
        if (run.phase == RunPhase.failed) fail('query failed: ${run.message}');
        return run.phase == RunPhase.finished;
      }, timeout: const Duration(minutes: 2));
      report['load_ms'] = load.elapsedMilliseconds;
      await _idle(tester, 1500);
      expect(
        container.read(queryStatusProvider).text,
        contains('1,000,000 rows'),
      );
      report['rss_loaded_mb'] = _rssMb();

      // The grid's vertical scroll controller: the Scrollbar whose extent
      // covers 1M rows (the editor has scrollbars of its own).
      final vertical = tester
          .widgetList<Scrollbar>(find.byType(Scrollbar))
          .map((b) => b.controller)
          .whereType<ScrollController>()
          .firstWhere((c) => c.hasClients && c.position.maxScrollExtent > 1e6);
      final center = tester.getCenter(find.text('id'));

      // 2. Steady wheel scroll, ~4 rows per frame.
      await binding.watchPerformance(
        () => _wheel(tester, center + const Offset(0, 200), 112, 240),
        reportKey: 'scroll_steady',
      );

      // 3. Jump to row 900,000: time until its id cell is on screen.
      final jump = Stopwatch()..start();
      vertical.jumpTo(900000 * 28.0);
      var found = false;
      for (var i = 0; i < 120 && !found; i++) {
        await tester.pump();
        found = find.text('900000').evaluate().isNotEmpty;
      }
      report['jump_ms'] = jump.elapsedMilliseconds;
      report['jump_found'] = found;
      await binding.watchPerformance(
        () => _wheel(tester, center + const Offset(0, 200), 112, 120),
        reportKey: 'scroll_at_900k',
      );
      await _idle(tester, 500);
      expect(
        container.read(queryStatusProvider).text,
        matches(RegExp(r'rows 9\d\d,\d{3}–')),
        reason: 'status bar shows the window position',
      );

      final rssEnd = _rssMb();
      report['rss_end_mb'] = rssEnd;
      report['rss_peak_mb'] = ProcessInfo.maxRss ~/ (1 << 20);
      report['rss_growth_mb'] = rssEnd - rssIdle;
      binding.reportData = {...?binding.reportData, ...report};
      debugPrint('PERF ${binding.reportData}');

      expect(found, isTrue, reason: 'row 900000 never appeared');
      expect(
        rssEnd - rssIdle,
        lessThan(200),
        reason: 'app RSS growth budget (PRD §7)',
      );
      if (kProfileMode) {
        final steady =
            binding.reportData!['scroll_steady']! as Map<String, dynamic>;
        expect(
          steady['90th_percentile_frame_build_time_millis'] as num,
          lessThan(12),
          reason: 'steady scroll p90 UI frame time',
        );
        expect(
          report['jump_ms'] as int,
          lessThan(100),
          reason: 'jump to row 900k',
        );
      }
    },
  );
}
