import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

const _traces = [
  'load', 'scroll_steady', 'scroll_fast', 'jump', 'scroll_900k',
  'resize', 'select', 'keyboard', 'theme',
];

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 30),
      responseDataCallback: (data) async {
        if (data == null) return;
        final out = Directory('build/perf')..createSync(recursive: true);
        final name = '${data['grid']}_${data['mode']}';
        final result = <String, Object?>{};
        for (final e in data.entries) {
          if (e.key.startsWith('img_')) {
            File('${out.path}/${name}_${e.key.substring(4)}.png')
                .writeAsBytesSync(base64Decode(e.value as String));
          } else if (_traces.contains(e.key) && e.value is Map) {
            final raw = e.value as Map<String, dynamic>;
            File('${out.path}/${name}_${e.key}.timeline.json')
                .writeAsStringSync(jsonEncode(raw));
            result[e.key] = '${name}_${e.key}.timeline.json';
          } else {
            result[e.key] = e.value;
          }
        }
        File('${out.path}/$name.json')
            .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
        stdout.writeln('wrote ${out.path}/$name.json');
      },
    );
