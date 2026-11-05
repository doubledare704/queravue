import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

const _a = ConnectionProfile(
  id: 'a',
  name: 'Alpha',
  engineId: 'postgres',
  folder: 'Work',
);
const _b = ConnectionProfile(
  id: 'b',
  name: 'beta',
  engineId: 'sqlite',
  folder: 'Work/Clients',
);
const _z = ConnectionProfile(id: 'z', name: 'Zed', engineId: 'sqlite');

void main() {
  group('ConnectionsController', () {
    test('loads connections from the repository', () async {
      final c = makeContainer(FakeConnectionsRepository(initial: [_a, _z]));
      final list = await c.read(connectionsControllerProvider.future);
      expect(list.map((e) => e.id), ['a', 'z']);
    });

    test('reports core not connected', () async {
      final c = makeContainer(FakeConnectionsRepository(), ready: false);
      await expectLater(
        c.read(connectionsControllerProvider.future),
        throwsA(
          isA<ConnectionsException>().having(
            (e) => e.coreUnavailable,
            'coreUnavailable',
            true,
          ),
        ),
      );
    });

    test('save creates, then updates, and refreshes the list', () async {
      final repo = FakeConnectionsRepository();
      final c = makeContainer(repo);
      await c.read(connectionsControllerProvider.future);
      final ctrl = c.read(connectionsControllerProvider.notifier);

      final created = await ctrl.save(
        const ConnectionProfile(name: 'New', engineId: 'postgres'),
        password: 'pw',
      );
      expect(created.id, isNotEmpty);
      expect(created.hasPassword, isTrue);
      expect(repo.passwords[created.id], 'pw');
      expect(c.read(connectionsControllerProvider).value, hasLength(1));

      await ctrl.save(created.copyWith(name: 'Renamed'), clearPassword: true);
      final list = c.read(connectionsControllerProvider).value!;
      expect(list.single.name, 'Renamed');
      expect(list.single.hasPassword, isFalse);
    });

    test('delete clears selection and connect status', () async {
      final repo = FakeConnectionsRepository(initial: [_a]);
      final c = makeContainer(repo);
      await c.read(connectionsControllerProvider.future);
      c.read(selectedConnectionProvider.notifier).select('a');
      await c.read(connectionTestsProvider.notifier).connect('a');
      expect(c.read(connectionTestsProvider), contains('a'));

      await c.read(connectionsControllerProvider.notifier).delete('a');
      expect(c.read(connectionsControllerProvider).value, isEmpty);
      expect(c.read(selectedConnectionProvider), isNull);
      expect(c.read(connectionTestsProvider), isNot(contains('a')));
    });
  });

  group('ConnectionTestsController', () {
    test('tracks connecting then the result', () async {
      final repo = FakeConnectionsRepository(initial: [_a]);
      final c = makeContainer(repo);
      final future = c.read(connectionTestsProvider.notifier).connect('a');
      expect(c.read(connectionTestsProvider)['a'], isA<Connecting>());
      await future;
      final status = c.read(connectionTestsProvider)['a'];
      expect(
        status,
        isA<Connected>().having((s) => s.result, 'result', isA<TestPassed>()),
      );
      expect(repo.testCalls.single.id, 'a');
      expect(repo.testCalls.single.password, isNull);
    });

    test('maps failures to friendly headlines', () async {
      final repo = FakeConnectionsRepository(initial: [_a])
        ..nextResult = const TestFailed(
          ConnectionErrorKind.auth,
          'password authentication failed for user "u"',
        );
      final c = makeContainer(repo);
      final r = await c.read(connectionTestsProvider.notifier).connect('a');
      expect((r as TestFailed).headline, 'Wrong user or password');
    });
  });

  group('friendly error headlines', () {
    const cases = {
      ConnectionErrorKind.auth: 'Wrong user or password',
      ConnectionErrorKind.network: "Can't reach the server",
      ConnectionErrorKind.tls: 'TLS/SSL handshake failed',
      ConnectionErrorKind.notFound: 'Database or file not found',
      ConnectionErrorKind.timeout: 'Connection timed out',
      ConnectionErrorKind.invalidConfig: 'Invalid settings',
      ConnectionErrorKind.unknown: 'Connection failed',
    };
    cases.forEach((kind, want) {
      test(kind.name, () => expect(TestFailed(kind, '').headline, want));
    });
  });

  group('buildConnectionTree', () {
    String describe(List<TreeRow> rows) => rows
        .map(
          (r) => switch (r) {
            FolderRow(:final name, :final depth, :final expanded) =>
              '${'  ' * depth}${expanded ? 'v' : '>'} $name',
            ConnectionRow(:final profile, :final depth) =>
              '${'  ' * depth}- ${profile.name}',
          },
        )
        .join('\n');

    test('nests folders, subfolders before connections, sorted', () {
      final rows = buildConnectionTree([_z, _b, _a], const {});
      expect(describe(rows), '''
v Work
  v Clients
    - beta
  - Alpha
- Zed''');
      final work = rows.first as FolderRow;
      expect(work.count, 2);
    });

    test('collapsed folders hide their contents', () {
      final rows = buildConnectionTree([_z, _b, _a], const {'Work'});
      expect(describe(rows), '> Work\n- Zed');
    });
  });
}
