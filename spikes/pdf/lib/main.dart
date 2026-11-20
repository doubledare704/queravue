import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'fixture_loader.dart';
import 'pdfrx_preview.dart';
import 'spike_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.environment['SPIKE_SCENARIO'] == 'idle_eager_init') {
    await initializePdfrxRuntime();
  }
  runApp(
    SpikeApp(
      variantName: 'pdfrx',
      previewBuilder: _buildInteractivePreview,
      scenarioRunner: _runPdfrxScenario,
    ),
  );
}

Widget _buildInteractivePreview(
  BuildContext context,
  Uint8List bytes,
  String sourceName,
  ValueChanged<String> onStatus,
) {
  final controller = PdfViewerController();
  return PdfrxPreviewPane(
    key: ValueKey<String>(sourceName),
    bytes: bytes,
    sourceName: sourceName,
    controller: controller,
    onFirstPageReady: (metrics) {
      onStatus(
        'Rendered page 1/${metrics.pageCount} in ${metrics.firstPageMs} ms '
        '(viewerReady ${metrics.viewerReadyMs} ms)',
      );
    },
    onError: (error) => onStatus('Preview error: $error'),
  );
}

Future<Map<String, Object?>?> _runPdfrxScenario(
  String scenario,
  SpikeHost host,
) async {
  if (scenario == 'idle_eager_init') {
    final idleSeconds =
        int.tryParse(Platform.environment['SPIKE_IDLE_SECONDS'] ?? '') ?? 30;
    return runIdleScenario(
      host.sampler,
      mode: 'idle_pdfrx_eager_init',
      idleSeconds: idleSeconds,
    );
  }
  if (scenario == 'pdfrx_single') {
    final fixtureId = Platform.environment['SPIKE_FIXTURE'] ?? 'one_page';
    final fixture = SpikeFixture.fromId(fixtureId);
    final result = await _exerciseFixture(
      host,
      fixture,
      runId: 'single_${DateTime.now().microsecondsSinceEpoch}',
      postCloseFinalSeconds: 10,
    );
    return <String, Object?>{
      'scenario': 'pdfrx_single',
      ...result,
    };
  }
  if (scenario == 'pdfrx_sequence') {
    final steps = <Map<String, Object?>>[];
    for (final fixture in SpikeFixture.values) {
      final step = await _exerciseFixture(
        host,
        fixture,
        runId: 'seq_${fixture.id}_${DateTime.now().microsecondsSinceEpoch}',
        postCloseFinalSeconds: fixture == SpikeFixture.images30MiB ? 10 : 5,
      );
      steps.add(step);
    }
    return <String, Object?>{
      'scenario': 'pdfrx_sequence',
      'steps': steps,
      'maxRssBytes': ProcessInfo.maxRss,
    };
  }
  return null;
}

Future<Map<String, Object?>> _exerciseFixture(
  SpikeHost host,
  SpikeFixture fixture, {
  required String runId,
  required int postCloseFinalSeconds,
}) async {
  await Future<void>.delayed(const Duration(seconds: 3));
  final beforeLoadRss = host.sampler.currentRss();
  host.sampler.resetPeakToCurrent();

  Uint8List? bytes = await loadFixtureBytes(fixture);
  final byteLength = bytes.length;
  final bytesLoadedRss = host.sampler.currentRss();

  final controller = PdfViewerController();
  final paintedPages = <int>{};
  final firstPageCompleter = Completer<PdfrxPreviewMetrics>();
  final sourceName = '${fixture.id}_$runId';

  await host.mountCustomPreview(
    PdfrxPreviewPane(
      key: ValueKey<String>(sourceName),
      bytes: bytes,
      sourceName: sourceName,
      controller: controller,
      onFirstPageReady: (metrics) {
        if (!firstPageCompleter.isCompleted) {
          firstPageCompleter.complete(metrics);
        }
      },
      onPagePainted: paintedPages.add,
      onError: (error) {
        if (!firstPageCompleter.isCompleted) {
          firstPageCompleter.completeError(error);
        }
      },
    ),
  );

  final metrics = await firstPageCompleter.future.timeout(
    const Duration(seconds: 30),
  );
  final afterPage1Rss = host.sampler.currentRss();

  final stops = _scrollStopsFor(fixture, metrics.pageCount);
  var failedStops = 0;
  if (stops.isEmpty) {
    await Future<void>.delayed(const Duration(seconds: 1));
  } else {
    for (final page in stops) {
      await controller.goToPage(
        pageNumber: page,
        duration: const Duration(milliseconds: 50),
      );
      final ready = await waitForVisiblePagesReady(controller);
      if (!ready) failedStops++;
    }
  }

  final peakDuringShowRss = host.sampler.peakBytes;
  final paintedList = paintedPages.toList()..sort();

  // Drop the Dart reference before unmounting so GC can reclaim the PDF bytes.
  bytes = null;
  await host.unmountPreview();

  await Future<void>.delayed(const Duration(seconds: 5));
  final afterClose5sRss = host.sampler.currentRss();

  if (postCloseFinalSeconds > 5) {
    await Future<void>.delayed(Duration(seconds: postCloseFinalSeconds - 5));
  }
  final afterCloseFinalRss = host.sampler.currentRss();

  PaintingBinding.instance.imageCache.clear();
  await Future<void>.delayed(const Duration(seconds: 1));
  final afterImageCacheClearRss = host.sampler.currentRss();

  if (failedStops > 0) {
    throw StateError(
      'Fixture ${fixture.id} had $failedStops failed scroll renders',
    );
  }

  return <String, Object?>{
    'fixture': fixture.id,
    'bytes': byteLength,
    'pageCount': metrics.pageCount,
    'viewerReadyMs': metrics.viewerReadyMs,
    'firstPageMs': metrics.firstPageMs,
    'scrollStops': stops.length,
    'paintedPagesCount': paintedList.length,
    'beforeLoadRssBytes': beforeLoadRss,
    'bytesLoadedRssBytes': bytesLoadedRss,
    'afterPage1RssBytes': afterPage1Rss,
    'peakDuringShowRssBytes': peakDuringShowRss,
    'afterClose5sRssBytes': afterClose5sRss,
    'afterClose${postCloseFinalSeconds}sRssBytes': afterCloseFinalRss,
    'afterImageCacheClearRssBytes': afterImageCacheClearRss,
    'maxRssBytes': ProcessInfo.maxRss,
  };
}

List<int> _scrollStopsFor(SpikeFixture fixture, int pageCount) {
  return switch (fixture) {
    SpikeFixture.onePage => const <int>[],
    SpikeFixture.text300 => <int>[
      for (var p = 2; p <= 15 && p <= pageCount; p++) p,
      for (final p in const <int>[50, 100, 150, 200, 250, 300])
        if (p <= pageCount) p,
    ],
    SpikeFixture.images30MiB => <int>[
      for (var p = 2; p <= pageCount; p++) p,
    ],
  };
}
