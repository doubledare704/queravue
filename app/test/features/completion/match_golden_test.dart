import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/domain/local_filter.dart';

void main() {
  test('matchName agrees with the core on the shared cases', () {
    final file = File('../core/internal/completion/testdata/match_cases.json');
    final cases = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    expect(cases.length, greaterThan(20));
    for (final c in cases) {
      final m = c as Map<String, dynamic>;
      final got = matchName(m['prefix'] as String, m['name'] as String);
      expect(
        got ?? -1,
        m['class'] as int,
        reason: 'prefix "${m['prefix']}" against "${m['name']}"',
      );
    }
  });
}
