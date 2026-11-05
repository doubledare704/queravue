import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/core_launcher.dart';
import 'package:queravue/core_client/core_supervisor.dart';

import '../support/fakes.dart';

void main() {
  group('backoffDelay', () {
    const cases = {
      1: 250,
      2: 500,
      3: 1000,
      4: 2000,
      5: 4000,
      6: 5000,
      50: 5000,
    };
    cases.forEach((attempt, ms) {
      test('attempt $attempt -> ${ms}ms', () {
        expect(backoffDelay(attempt), Duration(milliseconds: ms));
      });
    });
  });

  group('CoreSupervisor', () {
    late FakeCoreLauncher launcher;
    late List<FakeCoreConnection> connections;
    late List<int> backoffAttempts;
    late CoreSupervisor supervisor;
    late List<CoreStatus> statuses;

    CoreSupervisor build({
      bool autoBeat = true,
      bool hangOnClose = false,
      Duration heartbeatTimeout = const Duration(seconds: 5),
      Duration stableAfter = const Duration(minutes: 1),
    }) {
      final s = CoreSupervisor(
        launcher: launcher,
        connector: (CoreHandle h) async {
          final c = FakeCoreConnection(
            h as FakeCoreHandle,
            autoBeat: autoBeat,
            hangOnClose: hangOnClose,
          );
          connections.add(c);
          return c;
        },
        heartbeatTimeout: heartbeatTimeout,
        stableAfter: stableAfter,
        backoff: (attempt) {
          backoffAttempts.add(attempt);
          return const Duration(milliseconds: 1);
        },
      );
      s.statusChanges.listen(statuses.add);
      return s;
    }

    Future<T> waitFor<T extends CoreStatus>({int skip = 0}) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final matches = statuses.whereType<T>();
        if (matches.length > skip) return matches.elementAt(skip);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('timed out waiting for $T #${skip + 1}; got $statuses');
    }

    setUp(() {
      launcher = FakeCoreLauncher();
      connections = [];
      backoffAttempts = [];
      statuses = [];
    });

    tearDown(() => supervisor.dispose());

    test('starts in CoreStarting and connects', () async {
      supervisor = build();
      expect(supervisor.status, isA<CoreStarting>());
      supervisor.start();
      final connected = await waitFor<CoreConnected>();
      expect(connected.info.version, '0.1.0-dev');
      expect(supervisor.corePid, 1000);
      expect(supervisor.connection, isNotNull);
    });

    test('restarts after the core is killed', () async {
      supervisor = build()..start();
      await waitFor<CoreConnected>();

      launcher.handles.first.die(); // kill -9
      final reconnecting = await waitFor<CoreReconnecting>();
      expect(reconnecting.attempt, 1);
      expect(reconnecting.reason, isNotEmpty);

      await waitFor<CoreConnected>(skip: 1);
      expect(launcher.handles, hasLength(2));
      expect(connections.first.closed, isTrue);
      expect(supervisor.corePid, 1001);
    });

    test('restarts even if closing the dead connection hangs', () async {
      supervisor = build(hangOnClose: true)..start();
      await waitFor<CoreConnected>();
      launcher.handles.first.die();
      await waitFor<CoreConnected>(skip: 1);
      expect(launcher.handles, hasLength(2));
    });

    test('backs off with increasing attempts while launch fails', () async {
      launcher.failures.addAll([
        CoreLaunchException('boom 1'),
        CoreLaunchException('boom 2'),
        CoreLaunchException('boom 3'),
      ]);
      supervisor = build()..start();
      await waitFor<CoreConnected>();
      expect(backoffAttempts, [1, 2, 3]);
      expect(statuses.whereType<CoreReconnecting>().map((s) => s.attempt), [
        1,
        2,
        3,
      ]);
    });

    test('kills a hung core that stops sending heartbeats', () async {
      supervisor = build(
        autoBeat: false,
        heartbeatTimeout: const Duration(milliseconds: 50),
      )..start();
      await waitFor<CoreConnected>();
      final reconnecting = await waitFor<CoreReconnecting>();
      expect(reconnecting.reason, contains('no heartbeat'));
      expect(launcher.handles.first.killed, isTrue);
    });

    test('heartbeats keep a healthy core alive', () async {
      supervisor = build(
        autoBeat: false,
        heartbeatTimeout: const Duration(milliseconds: 100),
      )..start();
      await waitFor<CoreConnected>();
      for (var i = 0; i < 6; i++) {
        connections.single.beat();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      expect(statuses.whereType<CoreReconnecting>(), isEmpty);
    });

    test('resets the attempt counter after a stable run', () async {
      supervisor = build(stableAfter: Duration.zero)..start();
      await waitFor<CoreConnected>();
      launcher.handles[0].die();
      await waitFor<CoreConnected>(skip: 1);
      launcher.handles[1].die();
      await waitFor<CoreConnected>(skip: 2);
      expect(backoffAttempts, [1, 1]);
    });

    test('dispose shuts the core down gracefully', () async {
      supervisor = build()..start();
      await waitFor<CoreConnected>();
      await supervisor.dispose();
      expect(launcher.handles.single.shutDown, isTrue);
      expect(launcher.handles.single.killed, isFalse);
      expect(connections.single.closed, isTrue);
      expect(
        launcher.handles,
        hasLength(1),
        reason: 'no restart after dispose',
      );
    });
  });

  test('ProcessCoreLauncher reports a missing binary', () async {
    final launcher = ProcessCoreLauncher(binaryPath: '/nonexistent/queravued');
    await expectLater(launcher.launch(), throwsA(isA<CoreLaunchException>()));
  });
}
