import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/shared/widgets/status_bar.dart';

class _FixedStatus extends CoreStatusController {
  _FixedStatus(this._status);

  final CoreStatus _status;

  @override
  CoreStatus build() => _status;
}

Future<void> _pumpBar(
  WidgetTester tester,
  CoreStatus status,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [coreStatusProvider.overrideWith(() => _FixedStatus(status))],
    child: const MaterialApp(home: Scaffold(bottomNavigationBar: StatusBar())),
  ),
);

void main() {
  group('shortVersion', () {
    const cases = {
      '0.1.0-dev': 'v0.1',
      '1.2.3': 'v1.2',
      '2.0.0+build.5': 'v2.0',
      'weird': 'vweird',
    };
    cases.forEach((input, want) {
      test('$input -> $want', () => expect(shortVersion(input), want));
    });
  });

  testWidgets('shows starting state', (tester) async {
    await _pumpBar(tester, const CoreStarting());
    expect(find.text('Starting core…'), findsOneWidget);
  });

  testWidgets('shows connected version', (tester) async {
    await _pumpBar(
      tester,
      const CoreConnected(
        CoreInfo(version: '0.1.0-dev', protocolVersion: 1, capabilities: {}),
      ),
    );
    expect(find.text('Core connected v0.1'), findsOneWidget);
  });

  testWidgets('shows reconnecting on first attempt', (tester) async {
    await _pumpBar(
      tester,
      const CoreReconnecting(attempt: 1, reason: 'exited'),
    );
    expect(find.text('Reconnecting…'), findsOneWidget);
  });

  testWidgets('shows attempt count on later attempts', (tester) async {
    await _pumpBar(
      tester,
      const CoreReconnecting(attempt: 3, reason: 'exited'),
    );
    expect(find.text('Reconnecting… (attempt 3)'), findsOneWidget);
  });
}
