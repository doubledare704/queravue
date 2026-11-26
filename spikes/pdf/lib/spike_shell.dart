import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'fixture_loader.dart';
import 'system_viewer.dart';

typedef PreviewWidgetBuilder = Widget Function(
  BuildContext context,
  Uint8List bytes,
  String sourceName,
  ValueChanged<String> onStatus,
);

typedef ScenarioRunner = Future<Map<String, Object?>?> Function(
  String scenario,
  SpikeHost host,
);

class RssSample {
  const RssSample({
    required this.elapsedMs,
    required this.rssBytes,
  });

  final int elapsedMs;
  final int rssBytes;
}

class RssSampler {
  final Stopwatch _watch = Stopwatch();
  final List<RssSample> samples = <RssSample>[];
  Timer? _timer;
  int _peakBytes = 0;

  int get peakBytes => _peakBytes;

  void start({Duration interval = const Duration(milliseconds: 100)}) {
    _watch.start();
    _record();
    _timer = Timer.periodic(interval, (_) => _record());
  }

  void _record() {
    final rss = ProcessInfo.currentRss;
    if (rss > _peakBytes) _peakBytes = rss;
    samples.add(RssSample(elapsedMs: _watch.elapsedMilliseconds, rssBytes: rss));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _record();
  }

  int currentRss() {
    final rss = ProcessInfo.currentRss;
    if (rss > _peakBytes) _peakBytes = rss;
    return rss;
  }

  void resetPeakToCurrent() {
    _peakBytes = ProcessInfo.currentRss;
  }
}

class SpikeHost {
  SpikeHost({
    required this.sampler,
    required this.systemViewer,
    required this.mountCustomPreview,
    required this.unmountPreview,
    required this.setStatus,
  });

  final RssSampler sampler;
  final SystemPdfViewer systemViewer;
  final Future<void> Function(Widget widget) mountCustomPreview;
  final Future<void> Function() unmountPreview;
  final ValueChanged<String> setStatus;
}

Future<void> writeSpikeReport(Map<String, Object?> payload) async {
  final path = Platform.environment['SPIKE_REPORT_PATH'];
  final encoded = const JsonEncoder.withIndent('  ').convert(payload);
  if (path != null && path.isNotEmpty) {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString('$encoded\n', flush: true);
  }
  stdout.writeln('SPIKE_REPORT $encoded');
}

double bytesToMiB(int bytes) => bytes / (1024 * 1024);

Future<Map<String, Object?>> runIdleScenario(
  RssSampler sampler, {
  required String mode,
  required int idleSeconds,
}) async {
  final t0Rss = sampler.currentRss();
  await Future<void>.delayed(const Duration(seconds: 5));
  final t5Rss = sampler.currentRss();
  final remaining = idleSeconds - 5;
  if (remaining > 0) {
    await Future<void>.delayed(Duration(seconds: remaining));
  }
  final endRss = sampler.currentRss();
  return <String, Object?>{
    'scenario': mode,
    'idleSeconds': idleSeconds,
    't0RssBytes': t0Rss,
    't5RssBytes': t5Rss,
    'endRssBytes': endRss,
    'peakRssBytes': sampler.peakBytes,
    'maxRssBytes': ProcessInfo.maxRss,
  };
}

Future<Map<String, Object?>> runSystemViewerScenario(SpikeHost host) async {
  final beforeRss = host.sampler.currentRss();
  host.sampler.resetPeakToCurrent();
  final results = <Map<String, Object?>>[];

  for (final fixture in SpikeFixture.values) {
    final loadStartRss = host.sampler.currentRss();
    final bytes = await loadFixtureBytes(fixture);
    final afterReadRss = host.sampler.currentRss();

    final launch = await host.systemViewer.openBytes(
      bytes,
      suggestedName: '${fixture.id}.pdf',
      background: true,
    );
    final afterLaunchRss = host.sampler.currentRss();

    results.add(<String, Object?>{
      'fixture': fixture.id,
      'bytes': bytes.length,
      'writeMs': launch.writeDuration.inMilliseconds,
      'launchMs': launch.launchDuration.inMilliseconds,
      'exitCode': launch.exitCode,
      'tempFile': launch.filePath,
      'loadStartRssBytes': loadStartRss,
      'afterReadRssBytes': afterReadRss,
      'afterLaunchRssBytes': afterLaunchRss,
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  await Future<void>.delayed(const Duration(seconds: 2));
  final peakRss = host.sampler.peakBytes;
  await host.systemViewer.cleanup();
  await Future<void>.delayed(const Duration(seconds: 1));
  final afterCleanupRss = host.sampler.currentRss();

  return <String, Object?>{
    'scenario': 'system_viewer',
    'beforeRssBytes': beforeRss,
    'peakRssBytes': peakRss,
    'afterCleanupRssBytes': afterCleanupRss,
    'maxRssBytes': ProcessInfo.maxRss,
    'fixtures': results,
  };
}

class SpikeApp extends StatefulWidget {
  const SpikeApp({
    super.key,
    required this.variantName,
    this.previewBuilder,
    this.scenarioRunner,
  });

  final String variantName;
  final PreviewWidgetBuilder? previewBuilder;
  final ScenarioRunner? scenarioRunner;

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  final RssSampler _sampler = RssSampler();
  final SystemPdfViewer _systemViewer = SystemPdfViewer();
  SpikeFixture _selectedFixture = SpikeFixture.onePage;
  Uint8List? _loadedBytes;
  Widget? _customPreview;
  bool _showingPreview = false;
  String _status = 'Idle';
  Timer? _uiRssTimer;
  int _liveRssBytes = ProcessInfo.currentRss;

  @override
  void initState() {
    super.initState();
    _sampler.start();
    _uiRssTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _liveRssBytes = ProcessInfo.currentRss;
        });
      }
    });

    final scenario = Platform.environment['SPIKE_SCENARIO'];
    if (scenario != null && scenario.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAutomatedScenario(scenario);
      });
    }
  }

  @override
  void dispose() {
    _uiRssTimer?.cancel();
    _sampler.stop();
    unawaited(_systemViewer.cleanup());
    super.dispose();
  }

  Future<void> _mountCustomPreview(Widget preview) async {
    if (!mounted) return;
    setState(() {
      _customPreview = preview;
      _showingPreview = true;
    });
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _unmountPreview() async {
    if (!mounted) return;
    setState(() {
      _customPreview = null;
      _loadedBytes = null;
      _showingPreview = false;
    });
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _runAutomatedScenario(String scenario) async {
    final host = SpikeHost(
      sampler: _sampler,
      systemViewer: _systemViewer,
      mountCustomPreview: _mountCustomPreview,
      unmountPreview: _unmountPreview,
      setStatus: (msg) {
        if (mounted) setState(() => _status = msg);
      },
    );

    try {
      final idleSeconds =
          int.tryParse(Platform.environment['SPIKE_IDLE_SECONDS'] ?? '') ?? 30;
      Map<String, Object?>? report;

      if (scenario == 'idle') {
        report = await runIdleScenario(
          _sampler,
          mode: 'idle_${widget.variantName}',
          idleSeconds: idleSeconds,
        );
      } else if (scenario == 'system_viewer') {
        report = await runSystemViewerScenario(host);
      } else if (widget.scenarioRunner != null) {
        report = await widget.scenarioRunner!(scenario, host);
      }

      if (report == null) {
        throw ArgumentError('Unsupported SPIKE_SCENARIO: $scenario');
      }
      _sampler.stop();
      await writeSpikeReport(report);
      await _systemViewer.cleanup();
      exit(0);
    } catch (error, stack) {
      stderr.writeln('Scenario $scenario failed: $error\n$stack');
      await _systemViewer.cleanup();
      exit(2);
    }
  }

  Future<void> _previewInApp(SpikeFixture fixture) async {
    final builder = widget.previewBuilder;
    if (builder == null) {
      setState(() => _status = 'In-app preview unavailable in baseline build');
      return;
    }
    setState(() {
      _selectedFixture = fixture;
      _status = 'Loading ${fixture.label}...';
    });
    final bytes = await loadFixtureBytes(fixture);
    if (!mounted) return;
    setState(() {
      _loadedBytes = bytes;
      _showingPreview = true;
      _customPreview = null;
      _status =
          'Loaded ${fixture.label} (${bytesToMiB(bytes.length).toStringAsFixed(2)} MiB)';
    });
  }

  Future<void> _openInSystemViewer(SpikeFixture fixture) async {
    setState(() {
      _selectedFixture = fixture;
      _status = 'Opening ${fixture.label} in system viewer...';
    });
    final bytes = await loadFixtureBytes(fixture);
    final result = await _systemViewer.openBytes(
      bytes,
      suggestedName: fixture.fileName,
    );
    if (!mounted) return;
    setState(() {
      _status =
          'Opened ${fixture.fileName} (write ${result.writeDuration.inMilliseconds} ms, '
          'launch ${result.launchDuration.inMilliseconds} ms, exit ${result.exitCode})';
    });
  }

  void _closePreview() {
    setState(() {
      _showingPreview = false;
      _loadedBytes = null;
      _customPreview = null;
      _status = 'Preview closed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeBytes = _loadedBytes;
    final previewWidget = _customPreview ??
        (_showingPreview && activeBytes != null && widget.previewBuilder != null
            ? widget.previewBuilder!(
                context,
                activeBytes,
                '${_selectedFixture.id}_${identityHashCode(activeBytes)}',
                (msg) {
                  if (mounted) setState(() => _status = msg);
                },
              )
            : null);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'pdf_spike (${widget.variantName})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final f in SpikeFixture.values)
                      ChoiceChip(
                        label: Text(f.label),
                        selected: _selectedFixture == f,
                        onSelected: (_) => setState(() => _selectedFixture = f),
                      ),
                    if (widget.previewBuilder != null)
                      FilledButton(
                        onPressed: () => _previewInApp(_selectedFixture),
                        child: const Text('Preview (pdfrx)'),
                      ),
                    OutlinedButton(
                      onPressed: () => _openInSystemViewer(_selectedFixture),
                      child: const Text('Open in system viewer'),
                    ),
                    if (_showingPreview)
                      TextButton(
                        onPressed: _closePreview,
                        child: const Text('Close preview'),
                      ),
                    Text(
                      'RSS: ${bytesToMiB(_liveRssBytes).toStringAsFixed(1)} MiB',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Text(_status),
            ),
            Expanded(
              child: previewWidget ??
                  Center(
                    child: Text(
                      'Select a fixture and choose Preview (pdfrx) or Open in system viewer.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
