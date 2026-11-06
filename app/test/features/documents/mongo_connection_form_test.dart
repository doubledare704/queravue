import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_form_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/connections/presentation/connection_actions.dart';
import 'package:queravue/features/connections/presentation/connection_dialog.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

/// The Mongo descriptor as the core sends it (abridged).
const _mongo = EngineSpec(
  id: 'mongodb',
  displayName: 'MongoDB',
  family: 'mongodb',
  supportsUri: true,
  uriExample: 'mongodb://user@localhost:27017/?replicaSet=rs0',
  capabilities: {'connect', 'schema_inspector', 'document_store'},
  fields: [
    FieldSpec(
      key: 'hosts',
      label: 'Hosts',
      required: true,
      defaultValue: 'localhost:27017',
    ),
    FieldSpec(
      key: 'srv',
      label: 'SRV (mongodb+srv)',
      kind: FieldKind.boolean,
      defaultValue: 'false',
    ),
    FieldSpec(key: 'replica_set', label: 'Replica set'),
    FieldSpec(key: 'username', label: 'User'),
    FieldSpec(key: 'password', label: 'Password', kind: FieldKind.password),
    FieldSpec(
      key: 'auth_mechanism',
      label: 'Auth mechanism',
      kind: FieldKind.select,
      defaultValue: 'default',
      options: ['default', 'SCRAM-SHA-256', 'SCRAM-SHA-1', 'MONGODB-X509'],
    ),
    FieldSpec(
      key: 'tls',
      label: 'TLS',
      kind: FieldKind.boolean,
      defaultValue: 'false',
    ),
    FieldSpec(key: 'tls_ca_file', label: 'CA file', kind: FieldKind.file),
  ],
);

/// Parses mongodb:// URIs like the core does: the password is returned apart.
class _MongoRepo extends FakeConnectionsRepository {
  _MongoRepo() {
    engines = [_mongo];
  }

  @override
  Future<({Map<String, String> params, String? password})> parseUri(
    String engineId,
    String uri,
  ) async {
    final u = Uri.parse(uri);
    final info = u.userInfo.split(':');
    return (
      params: {
        'hosts': '${u.host}:${u.port}',
        if (info.first.isNotEmpty) 'username': info.first,
        if (u.queryParameters['replicaSet'] != null)
          'replica_set': u.queryParameters['replicaSet']!,
        if (u.queryParameters['tls'] != null) 'tls': u.queryParameters['tls']!,
      },
      password: info.length > 1 ? info[1] : null,
    );
  }
}

Future<FakeConnectionsRepository> pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _MongoRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeCoreOverrides(repo),
        filePickerProvider.overrideWithValue(() async => '/certs/ca.pem'),
      ],
      child: MaterialApp(
        home: ConnectionDialog(args: ConnectionFormArgs(engines: repo.engines)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

String text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key('field-$key'))).controller!.text;

void main() {
  testWidgets('the form is built from the descriptor, not from the engine id', (
    tester,
  ) async {
    await pump(tester);
    expect(text(tester, 'hosts'), 'localhost:27017');
    for (final k in [
      'hosts',
      'srv',
      'replica_set',
      'username',
      'password',
      'tls',
      'tls_ca_file',
    ]) {
      expect(find.byKey(Key('field-$k')), findsOneWidget, reason: k);
    }
    // Select fields render as dropdowns with the descriptor's default.
    expect(find.text('Auth mechanism'), findsOneWidget);
    expect(find.text('default'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('field-password')))
          .obscureText,
      isTrue,
    );
    expect(find.byKey(const Key('field-uri')), findsOneWidget);
  });

  testWidgets(
    'pasting a mongodb URI fills the fields and keeps the password apart',
    (tester) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('field-uri')),
        'mongodb://ann:s3cret@db.local:27018/app?replicaSet=rs0&tls=true',
      );
      await tester.tap(find.byKey(const Key('apply-uri')));
      await tester.pumpAndSettle();
      expect(text(tester, 'hosts'), 'db.local:27018');
      expect(text(tester, 'username'), 'ann');
      expect(text(tester, 'replica_set'), 'rs0');
      expect(text(tester, 'password'), 's3cret');
      // The password never lands in a params field.
      for (final k in ['hosts', 'username', 'replica_set']) {
        expect(text(tester, k), isNot(contains('s3cret')));
      }
    },
  );

  testWidgets('saving stores params without the password', (tester) async {
    final repo = await pump(tester);
    await tester.enterText(find.byKey(const Key('field-username')), 'ann');
    await tester.enterText(find.byKey(const Key('field-password')), 'pw1');
    await tester.tap(find.byKey(const Key('save-connection')));
    await tester.pumpAndSettle();
    final saved = repo.items.single;
    expect(saved.engineId, 'mongodb');
    expect(saved.params['username'], 'ann');
    expect(saved.params.values, isNot(contains('pw1')));
    expect(repo.passwords[saved.id], 'pw1');
  });
}
