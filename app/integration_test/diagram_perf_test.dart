// Diagram budgets against the real core and the seeded 500-table Postgres
// schema (ADR 0017): open the diagram, then pan and zoom it.
//
//   docker compose -f dev/docker-compose.yml --profile large-schema up -d --wait postgres postgres-large-seed
//   make core
//   cd app && flutter drive --profile -d macos \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/diagram_perf_test.dart
// or `make test-perf-diagram`.
//
// Thresholds are asserted in profile mode only; debug builds record numbers.
// Raster times are not asserted: this macOS backend reports them as zero.
// DIAGRAM_SHOT_DIR=<folder> also writes PNGs of what the canvas shows.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/diagram/application/diagram_controller.dart';
import 'package:queravue/features/diagram/presentation/diagram_canvas.dart';
import 'package:queravue/features/diagram/presentation/diagram_export.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/shared/theme.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

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

Future<void> _dragInSteps(
  WidgetTester tester,
  Offset from,
  Offset step,
  int steps,
) async {
  final gesture = await tester.startGesture(
    from,
    kind: PointerDeviceKind.mouse,
  );
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(i < steps ~/ 2 ? step : -step);
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

Future<void> _shoot(WidgetTester tester, String name) async {
  final dir = Platform.environment['DIAGRAM_SHOT_DIR'];
  if (dir == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .descendant(
          of: find.byType(DiagramCanvas),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'a 500-table diagram opens, pans and zooms within budget',
    timeout: const Timeout(Duration(minutes: 5)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final report = <String, Object?>{
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

      final repo = container.read(connectionsRepositoryProvider);
      final saved = await repo.create(
        ConnectionProfile(
          name: 'diagram perf pg',
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
      // Not pumpAndSettle: a spinner in the live schema tree can keep it from
      // ever settling.
      await tester.pump(const Duration(milliseconds: 100));
      final session = await container
          .read(connectionSessionProvider(saved.id).notifier)
          .connect();
      expect(session, isNotNull, reason: 'the session must open');
      expect(session!.capabilities, contains('schema_graph'));

      final opening = Stopwatch()..start();
      final tab = container
          .read(editorTabsProvider.notifier)
          .openDiagram(saved.id, schema: _env('DIAGRAM_SCHEMA', 'large'));
      await _pumpUntil(
        tester,
        'the diagram',
        () =>
            container.read(diagramProvider(tab.id)) is! DiagramLoading &&
            find.byType(DiagramCanvas).evaluate().isNotEmpty,
      );
      await tester.pump();
      await tester.pump();
      report['open_ms'] = opening.elapsedMilliseconds;
      final ready = container.read(diagramProvider(tab.id)) as DiagramReady;
      report['tables'] = ready.graph.tables.length;
      report['relations'] = ready.graph.relationCount;
      final canvas = tester.state<DiagramCanvasState>(
        find.byType(DiagramCanvas),
      );
      report['fitted_scale'] = canvas.scale;
      await _shoot(tester, 'fitted');

      final centre = tester.getCenter(find.byType(DiagramCanvas));
      final corner =
          tester.getTopLeft(find.byType(DiagramCanvas)) + const Offset(4, 4);
      await binding.watchPerformance(
        () => _dragInSteps(tester, corner, const Offset(6, 4), 120),
        reportKey: 'pan_fitted',
      );

      canvas.zoomBy(0.3 / canvas.scale, centre);
      await tester.pump();
      await _shoot(tester, 'titles');
      await binding.watchPerformance(
        () => _dragInSteps(tester, corner, const Offset(8, 5), 120),
        reportKey: 'pan_titles',
      );

      canvas.zoomBy(0.8 / canvas.scale, centre);
      await tester.pump();
      await tester.pump();
      await _shoot(tester, 'columns');
      await binding.watchPerformance(
        () => _dragInSteps(tester, corner, const Offset(10, 6), 120),
        reportKey: 'pan_columns',
      );

      final svgWatch = Stopwatch()..start();
      final svg = diagramToSvg(
        graph: ready.visibleGraph,
        rects: ready.visibleRects,
        colors: lightTheme.colorScheme,
        title: tab.title,
      );
      report['svg_ms'] = svgWatch.elapsedMilliseconds;
      report['svg_kb'] = svg.length ~/ 1024;
      final pngWatch = Stopwatch()..start();
      final png = await diagramToPng(
        graph: ready.visibleGraph,
        rects: ready.visibleRects,
        colors: lightTheme.colorScheme,
      );
      report['png_ms'] = pngWatch.elapsedMilliseconds;
      report['png_px'] = '${png.width}x${png.height}';
      report['png_ratio'] = png.pixelRatio;
      report['png_kb'] = png.bytes.length ~/ 1024;
      final exportDir = Platform.environment['DIAGRAM_SHOT_DIR'];
      if (exportDir != null) {
        File('$exportDir/export.svg').writeAsStringSync(svg);
        File('$exportDir/export.png').writeAsBytesSync(png.bytes);
      }

      binding.reportData = {...?binding.reportData, ...report};
      debugPrint('DIAGRAM PERF ${binding.reportData}');

      expect(
        ready.graph.tables.length,
        greaterThanOrEqualTo(int.parse(_env('DIAGRAM_MIN_TABLES', '100'))),
      );
      if (kProfileMode) {
        expect(report['open_ms']! as int, lessThan(1000));
        expect(report['svg_ms']! as int, lessThan(1000));
        expect(report['png_ms']! as int, lessThan(5000));
        for (final key in ['pan_fitted', 'pan_titles', 'pan_columns']) {
          final frames = binding.reportData![key]! as Map<String, dynamic>;
          expect(
            frames['90th_percentile_frame_build_time_millis'] as num,
            lessThan(8),
            reason: '$key p90 UI frame time',
          );
        }
      }
    },
  );
}
