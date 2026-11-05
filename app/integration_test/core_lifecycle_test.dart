// End-to-end: real app + real queravued sidecar.
// Run with `make test-e2e` (builds the core first).
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/core_client/core_supervisor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(
    WidgetTester tester,
    String what,
    bool Function() done, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 50));
      if (done()) return;
    }
    fail('timed out waiting for $what');
  }

  bool showsConnected() =>
      find.textContaining('Core connected v').evaluate().isNotEmpty;

  testWidgets('connects, survives kill -9 of the core, and recovers', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final supervisor = container.read(coreSupervisorProvider);
    final statuses = <CoreStatus>[];
    final sub = supervisor.statusChanges.listen(statuses.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QueravueApp(),
      ),
    );
    await pumpUntil(tester, 'first connect', showsConnected);

    final firstPid = supervisor.corePid!;
    expect(Process.killPid(firstPid, ProcessSignal.sigkill), isTrue);

    // The UI drops to Reconnecting…, then the new core connects.
    await pumpUntil(
      tester,
      'reconnecting',
      () => statuses.any((s) => s is CoreReconnecting),
      timeout: const Duration(seconds: 5),
    );
    await pumpUntil(
      tester,
      'reconnect',
      () => showsConnected() && supervisor.corePid != firstPid,
    );
    expect(statuses.whereType<CoreReconnecting>(), isNotEmpty);
    expect(supervisor.corePid, isNot(firstPid));
  });
}
