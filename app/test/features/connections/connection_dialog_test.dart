import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_form_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/connections/presentation/connection_actions.dart';
import 'package:queravue/features/connections/presentation/connection_dialog.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

/// Opens the dialog from a button so pop() results can be observed.
Future<List<ConnectionProfile?>> pumpDialog(
  WidgetTester tester,
  FakeConnectionsRepository repo, {
  ConnectionProfile? initial,
  String? pickedFile,
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <ConnectionProfile?>[];
  final args = ConnectionFormArgs(engines: repo.engines, initial: initial);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeCoreOverrides(repo),
        filePickerProvider.overrideWithValue(() async => pickedFile),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showDialog<ConnectionProfile>(
                context: context,
                builder: (_) => ConnectionDialog(args: args),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

String fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key('field-$key'))).controller!.text;

void main() {
  testWidgets('renders fields from the engine spec', (tester) async {
    await pumpDialog(tester, FakeConnectionsRepository());
    expect(find.text('New connection'), findsOneWidget);
    for (final key in ['host', 'port', 'database', 'user', 'password']) {
      expect(find.byKey(Key('field-$key')), findsOneWidget, reason: key);
    }
    expect(fieldText(tester, 'host'), 'localhost');
    expect(fieldText(tester, 'port'), '5432');
    expect(find.text('prefer'), findsOneWidget);
    final pw = tester.widget<TextField>(
      find.byKey(const Key('field-password')),
    );
    expect(pw.obscureText, isTrue);
  });

  testWidgets('switching to SQLite shows a file picker', (tester) async {
    await pumpDialog(
      tester,
      FakeConnectionsRepository(),
      pickedFile: '/tmp/data.db',
    );
    await tester.tap(find.byKey(const Key('field-engine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SQLite').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('field-host')), findsNothing);
    expect(find.byKey(const Key('field-password')), findsNothing);
    expect(find.byKey(const Key('browse-path')), findsOneWidget);
    expect(find.text('Read-only'), findsOneWidget);

    await tester.tap(find.byKey(const Key('browse-path')));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'path'), '/tmp/data.db');
  });

  testWidgets('pasting a URI fills the fields', (tester) async {
    await pumpDialog(tester, FakeConnectionsRepository());
    await tester.enterText(
      find.byKey(const Key('field-uri')),
      'postgres://bob:pw@db.local:6543/app',
    );
    await tester.tap(find.byKey(const Key('apply-uri')));
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'host'), 'db.local');
    expect(fieldText(tester, 'port'), '6543');
    expect(fieldText(tester, 'user'), 'bob');
    expect(fieldText(tester, 'database'), 'app');
    expect(fieldText(tester, 'password'), 'pw');
    expect(fieldText(tester, 'uri'), isEmpty);
  });

  testWidgets('Test shows version and latency', (tester) async {
    final repo = FakeConnectionsRepository();
    await pumpDialog(tester, repo);
    await tester.tap(find.byKey(const Key('test-connection')));
    await tester.pumpAndSettle();
    expect(find.text('PostgreSQL 17.11 · 1 ms'), findsOneWidget);
    expect(repo.testCalls, hasLength(1));
  });

  testWidgets('Test shows a friendly error', (tester) async {
    final repo = FakeConnectionsRepository()
      ..nextResult = const TestFailed(
        ConnectionErrorKind.auth,
        'password authentication failed for user "bob"',
      );
    await pumpDialog(tester, repo);
    await tester.tap(find.byKey(const Key('test-connection')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Wrong user or password: password authentication'),
      findsOneWidget,
    );
  });

  testWidgets('Save validates, then saves and closes', (tester) async {
    final repo = FakeConnectionsRepository();
    final results = await pumpDialog(tester, repo);

    await tester.enterText(find.byKey(const Key('field-name')), 'Docker PG');
    await tester.enterText(find.byKey(const Key('field-password')), 'pw');
    await tester.enterText(find.byKey(const Key('field-folder')), 'Dev');
    await tester.tap(find.byKey(const Key('field-production')));
    await tester.tap(find.byKey(const Key('save-connection')));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectionDialog), findsNothing);
    final saved = repo.items.single;
    expect(saved.name, 'Docker PG');
    expect(saved.folder, 'Dev');
    expect(saved.production, isTrue);
    expect(saved.params.containsKey('password'), isFalse);
    expect(repo.passwords[saved.id], 'pw');
    expect(results.single?.id, saved.id);
  });

  testWidgets('edit shows the stored password hint and Forget', (tester) async {
    const existing = ConnectionProfile(
      id: 'c1',
      name: 'PG',
      engineId: 'postgres',
      params: {'host': 'db'},
      hasPassword: true,
    );
    final repo = FakeConnectionsRepository(initial: [existing])
      ..passwords['c1'] = 'stored';
    await pumpDialog(tester, repo, initial: existing);
    expect(find.text('Edit connection'), findsOneWidget);
    expect(fieldText(tester, 'host'), 'db');
    expect(
      find.text('Saved in keychain — leave empty to keep'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clear-stored-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-connection')));
    await tester.pumpAndSettle();
    expect(repo.passwords, isEmpty);
  });
}
