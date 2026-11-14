import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_form_controller.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/connections/domain/network_settings.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

const _saved = ConnectionProfile(
  id: 'c9',
  name: 'Prod PG',
  engineId: 'postgres',
  params: {'host': 'db', 'port': '5432', 'user': 'app'},
  folder: 'Work',
  color: ColorTag.red,
  production: true,
  hasPassword: true,
);

void main() {
  late FakeConnectionsRepository repo;
  late ProviderContainer c;

  setUp(() {
    repo = FakeConnectionsRepository(initial: [_saved])
      ..passwords['c9'] = 'stored';
    c = makeContainer(repo);
  });

  ({ConnectionFormController ctrl, ConnectionFormState Function() state}) open(
    ConnectionFormArgs args,
  ) {
    final p = connectionFormProvider(args);
    // Keep the auto-dispose provider alive for the test.
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
    return (ctrl: c.read(p.notifier), state: () => c.read(p));
  }

  test('new form starts with the first engine and its defaults', () {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    expect(f.state().engine.id, 'postgres');
    expect(f.state().values, {
      'host': 'localhost',
      'port': '5432',
      'database': 'postgres',
      'sslmode': 'prefer',
    });
  });

  test('switching engine resets to the new engine defaults', () {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    f.ctrl.setField('host', 'custom');
    f.ctrl.selectEngine('sqlite');
    expect(f.state().engine.id, 'sqlite');
    expect(f.state().values, {'read_only': 'false'});
    expect(f.state().revision, greaterThan(0));
  });

  test('applyUri fills fields and the password', () async {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    await f.ctrl.applyUri('postgres://bob:pw@h:6543/app');
    final s = f.state();
    expect(s.values['host'], 'h');
    expect(s.values['port'], '6543');
    expect(s.values['user'], 'bob');
    expect(s.values['database'], 'app');
    expect(s.values['sslmode'], 'prefer', reason: 'defaults kept');
    expect(s.password, 'pw');
    expect(s.passwordDirty, isTrue);
  });

  test('applyUri reports parse errors', () async {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    await f.ctrl.applyUri('mysql://x');
    expect(f.state().error, contains("Couldn't parse URI"));
  });

  test('save validates required fields', () async {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    f.ctrl.setField('host', '');
    expect(await f.ctrl.save(), isNull);
    expect(f.state().error, 'Host is required');
  });

  group('default name', () {
    test('is "<Engine> @ host:port/db" and tracks the fields', () {
      final f = open(ConnectionFormArgs(engines: repo.engines));
      expect(f.ctrl.defaultName, 'PostgreSQL @ localhost:5432/postgres');
      f.ctrl.setField('host', 'db.internal');
      f.ctrl.setField('database', 'shop');
      expect(f.ctrl.defaultName, 'PostgreSQL @ db.internal:5432/shop');
    });

    test('SQLite uses the file name', () {
      final f = open(ConnectionFormArgs(engines: repo.engines));
      f.ctrl.selectEngine('sqlite');
      f.ctrl.setField('path', '/Users/me/data/app.db');
      expect(f.ctrl.defaultName, 'app.db');
    });

    test(
      'is used on save when no name is typed, never the test result',
      () async {
        final f = open(ConnectionFormArgs(engines: repo.engines));
        await f.ctrl.test();
        expect(f.state().test, isA<FormTested>());
        final saved = await f.ctrl.save();
        expect(saved!.name, 'PostgreSQL @ localhost:5432/postgres');
        expect(saved.name, isNot(contains(' ms')));
      },
    );

    test('a typed name wins', () async {
      final f = open(ConnectionFormArgs(engines: repo.engines));
      f.ctrl.setName('Mine');
      expect((await f.ctrl.save())!.name, 'Mine');
    });
  });

  test(
    'persists network settings without embedding credentials in the profile',
    () async {
      const networkEngine = EngineSpec(
        id: 'network',
        displayName: 'Network database',
        fields: [],
        supportsSsh: true,
        supportsTls: true,
      );
      final form = open(const ConnectionFormArgs(engines: [networkEngine]));
      form.ctrl
        ..setNetworkField('ssh.enabled', 'true')
        ..setNetworkField('ssh.host', 'bastion.example')
        ..setNetworkField('ssh.user', 'operator')
        ..setNetworkField('ssh.auth', 'keyFile')
        ..setNetworkField('ssh.key', '/tmp/key')
        ..setNetworkField('ssh.passphrase', 'test passphrase')
        ..setNetworkField('jump.enabled', 'true')
        ..setNetworkField('jump.host', 'jump.example')
        ..setNetworkField('jump.user', 'operator')
        ..setNetworkField('jump.auth', 'agent')
        ..setNetworkField('tls.mode', 'verifyFull')
        ..setNetworkField('tls.ca', '/tmp/ca.pem');

      await form.ctrl.test();
      final saved = (await form.ctrl.save())!;
      expect(saved.ssh?.bastion.keyFile, '/tmp/key');
      expect(saved.ssh?.jump?.auth, SshAuth.agent);
      expect(saved.tls?.mode, TlsMode.verifyFull);
      expect(saved.tls?.caFile, '/tmp/ca.pem');
      expect(saved.params, isEmpty);
      expect(repo.lastTestSecrets?.sshPassphrase, 'test passphrase');
      expect(repo.lastSavedSecrets?.sshPassphrase, 'test passphrase');
    },
  );

  test('production defaults to false for new connections', () {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    expect(f.state().production, isFalse);
  });

  test('save creates a connection with the typed password', () async {
    final f = open(ConnectionFormArgs(engines: repo.engines));
    f.ctrl
      ..setName('Local')
      ..setFolder(' Dev ')
      ..setColor(ColorTag.green)
      ..setPassword('secret');
    final saved = await f.ctrl.save();
    expect(saved, isNotNull);
    expect(saved!.folder, 'Dev');
    expect(saved.color, ColorTag.green);
    expect(saved.params.containsKey('password'), isFalse);
    expect(repo.passwords[saved.id], 'secret');
    expect(c.read(connectionsControllerProvider).value, hasLength(2));
  });

  test('save surfaces repository errors', () async {
    repo.failNextSave = const ConnectionsException('Host is required');
    final f = open(ConnectionFormArgs(engines: repo.engines));
    f.ctrl.setName('x');
    expect(await f.ctrl.save(), isNull);
    expect(f.state().error, 'Host is required');
    expect(f.state().saving, isFalse);
  });

  group('edit', () {
    test('keeps the stored password unless changed', () async {
      final f = open(
        ConnectionFormArgs(engines: repo.engines, initial: _saved),
      );
      expect(f.state().hasStoredPassword, isTrue);
      expect(f.state().name, 'Prod PG');
      f.ctrl.setName('Renamed');
      final saved = await f.ctrl.save();
      expect(saved!.id, 'c9');
      expect(repo.passwords['c9'], 'stored');
    });

    test('clearing removes the stored password', () async {
      final f = open(
        ConnectionFormArgs(engines: repo.engines, initial: _saved),
      );
      f.ctrl.clearStoredPassword();
      await f.ctrl.save();
      expect(repo.passwords, isNot(contains('c9')));
    });

    test('test falls back to the stored password via id', () async {
      final f = open(
        ConnectionFormArgs(engines: repo.engines, initial: _saved),
      );
      f.ctrl.setField('host', 'other');
      await f.ctrl.test();
      final call = repo.testCalls.single;
      expect(call.id, 'c9');
      expect(call.password, isNull);
      expect(call.draft!.params['host'], 'other');
      expect(f.state().test, isA<FormTested>());
    });

    test('a typed password is sent with the test', () async {
      final f = open(
        ConnectionFormArgs(engines: repo.engines, initial: _saved),
      );
      f.ctrl.setPassword('typed');
      await f.ctrl.test();
      expect(repo.testCalls.single.password, 'typed');
    });
  });

  test('duplicate gets a new name and saves as a new connection', () async {
    final f = open(
      ConnectionFormArgs(
        engines: repo.engines,
        initial: _saved,
        duplicate: true,
      ),
    );
    expect(f.state().name, 'Prod PG copy');
    expect(f.state().production, isFalse);
    expect(f.state().hasStoredPassword, isFalse);
    final saved = await f.ctrl.save();
    expect(saved!.id, isNot('c9'));
    expect(saved.production, isFalse);
  });

  test('test can be cancelled', () async {
    repo.testGate = Completer<void>();
    final f = open(ConnectionFormArgs(engines: repo.engines));
    final running = f.ctrl.test();
    expect(f.state().test, isA<FormTesting>());
    f.ctrl.cancelTest();
    await running;
    expect(f.state().test, isA<FormTestIdle>());
  });

  test('test shows the failure', () async {
    repo.nextResult = const TestFailed(ConnectionErrorKind.network, 'refused');
    final f = open(ConnectionFormArgs(engines: repo.engines));
    await f.ctrl.test();
    final t = f.state().test as FormTested;
    expect((t.result as TestFailed).headline, "Can't reach the server");
  });
}
