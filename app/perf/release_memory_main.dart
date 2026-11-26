import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/shared/image_cache_limits.dart';

import 'release_memory_scenario.dart';
import 'rss_report.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  limitImageCache();
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const QueravueApp()),
  );
  final reportPath =
      Platform.environment['QUERAVUE_PERF_OUT'] ??
      '${Directory.systemTemp.path}/queravue-release-perf.md';
  final output = File(reportPath).openWrite();
  var failure = 0;
  try {
    await _awaitCorePid(container);
    final report = RssReport(
      corePid: container.read(coreSupervisorProvider).corePid!,
      output: output,
      reportPath: reportPath,
    );
    await ReleaseMemoryScenario(container, report).run();
  } on Object catch (error, stack) {
    stderr.writeln('release perf scenario failed: $error\n$stack');
    failure = 1;
  } finally {
    await disposeCore(container);
    await output.close();
    exit(failure);
  }
}

Future<void> _awaitCorePid(ProviderContainer container) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (container.read(coreSupervisorProvider).corePid == null) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('core did not start');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
