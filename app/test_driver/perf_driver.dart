import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Collects the report of integration_test/grid_perf_test.dart into
/// build/perf/grid_perf.json.
Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 10),
  responseDataCallback: (data) async {
    if (data == null) return;
    final out = Directory('build/perf')..createSync(recursive: true);
    File('${out.path}/grid_perf.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln('wrote ${out.path}/grid_perf.json');
  },
);
