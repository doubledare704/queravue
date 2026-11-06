// End-to-end: real app + real queravued + the docker Mongo replica set.
//
//   make db-up core
//   docker compose -f dev/docker-compose.yml --profile seed up mongo-seed
//   make test-e2e-mongo
//
// Browses, filters, sorts, projects and pages the seeded collections, and
// inserts / edits / deletes documents (with a conflict) in a scratch
// collection, all through the app's own controllers and the real core.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/documents/application/document_tab_controller.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

Future<void> _pumpUntil(
  WidgetTester tester,
  String what,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('timed out waiting for $what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Mongo: browse, filter, sort, project, page, and insert/edit/delete',
    timeout: const Timeout(Duration(minutes: 5)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QueravueApp(),
        ),
      );
      await _pumpUntil(
        tester,
        'core connected',
        () => container.read(coreStatusProvider) is CoreConnected,
      );

      // The core lists the engines; Mongo is document-only.
      final repo = container.read(connectionsRepositoryProvider);
      final engines = await repo.listEngines();
      final mongo = engines.firstWhere((e) => e.id == 'mongodb');
      expect(
        mongo.capabilities,
        containsAll(['document_store', 'schema_inspector']),
      );
      expect(mongo.capabilities, isNot(contains('execute')));
      expect(
        mongo.fields.map((f) => f.key),
        containsAll(['hosts', 'replica_set', 'tls', 'auth_mechanism']),
      );

      // A pasted URI is parsed by the core into form fields.
      final host =
          '${_env('MONGO_HOST', '127.0.0.1')}:${_env('MONGO_PORT', '27017')}';
      final parsed = await repo.parseUri(
        'mongodb',
        'mongodb://u:pw@$host/queravue?replicaSet=rs0',
      );
      expect(parsed.params['hosts'], host);
      expect(parsed.params['replica_set'], 'rs0');
      expect(parsed.params['username'], 'u');
      expect(parsed.password, 'pw');
      expect(parsed.params.values, isNot(contains('pw')));

      final saved = await repo.create(
        ConnectionProfile(
          name: 'e2e mongo',
          engineId: 'mongodb',
          params: {'hosts': host, 'replica_set': 'rs0'},
        ),
      );
      addTearDown(() => repo.delete(saved.id));
      await container.read(connectionsControllerProvider.notifier).reload();
      container.read(selectedConnectionProvider.notifier).select(saved.id);
      await tester.pumpAndSettle();

      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(saved.id).notifier)
            .connect(),
      );
      expect(session, isNotNull, reason: 'is the dev Mongo up and seeded?');
      expect(session!.capabilities, contains('document_store'));
      expect(
        container.read(connectionIsDocumentOnlyProvider(saved.id)),
        isTrue,
      );

      DocumentTabState stateOf(String id) =>
          container.read(documentTabProvider(id));
      Future<void> settled(String id, {String what = 'query'}) => _pumpUntil(
        tester,
        what,
        () => stateOf(id).loaded && !stateOf(id).isLoading,
      );

      // ---- browse the seeded users collection ----
      final users = container
          .read(editorTabsProvider.notifier)
          .openCollection(
            saved.id,
            const TableRef(database: 'queravue', table: 'users'),
          );
      await tester.pumpAndSettle();
      await settled(users.id);
      var s = stateOf(users.id);
      expect(s.docs.length, 5);
      expect(s.columns.first.name, '_id');
      expect(
        s.columns.map((f) => f.name),
        containsAll(['name', 'visits', 'balance']),
      );
      await _pumpUntil(tester, 'count', () => stateOf(users.id).count != null);
      expect(stateOf(users.id).count!.count, 5);
      // Int64 beyond 2^53 survives the whole path as text.
      expect(
        s.docs.any((d) => d.text.contains('"\$numberLong":"9007199254740993"')),
        isTrue,
      );
      // The table is on screen (columns off screen are not built).
      expect(find.byKey(const Key('doc-table')), findsOneWidget);

      final c = container.read(documentTabProvider(users.id).notifier);
      await c.run(
        const FindQuery(
          filter: '{"age": {"\$gte": 70}}',
          sort: '{"name": -1}',
          projection: '{"name": 1}',
        ),
      );
      await settled(users.id);
      s = stateOf(users.id);
      expect(s.docs.length, 2);
      expect(s.docs.first.text, contains('Edsger'));
      expect(s.docs.first.text, isNot(contains('email')));

      // A parse error comes back positioned, next to the filter input.
      await c.run(const FindQuery(filter: '{"a": ]}'));
      await settled(users.id);
      expect(stateOf(users.id).queryError!.input, DocInput.filter);
      expect(stateOf(users.id).queryError!.position, 6);

      // ---- page through 1M events: the UI holds one page ----
      final events = container
          .read(editorTabsProvider.notifier)
          .openCollection(
            saved.id,
            const TableRef(database: 'queravue', table: 'events'),
          );
      await tester.pumpAndSettle();
      await settled(events.id);
      final e = container.read(documentTabProvider(events.id).notifier);
      await e.run(const FindQuery(sort: '{"n": 1}'));
      await settled(events.id);
      expect(stateOf(events.id).docs.length, 50);
      expect(stateOf(events.id).hasNext, isTrue);
      await _pumpUntil(
        tester,
        'events count',
        () => stateOf(events.id).count != null,
      );
      expect(stateOf(events.id).count!.count, 1000000);
      await e.nextPage();
      await settled(events.id);
      expect(stateOf(events.id).docs.length, 50);
      expect(
        stateOf(events.id).docs.first.text,
        contains('"n":{"\$numberInt":"50"}'),
      );

      // ---- insert / edit / conflict / delete in a scratch collection ----
      final scratchName = 'e2e_${DateTime.now().millisecondsSinceEpoch}';
      final scratch = container
          .read(editorTabsProvider.notifier)
          .openCollection(
            saved.id,
            TableRef(database: 'queravue', table: scratchName),
          );
      await tester.pumpAndSettle();
      await settled(scratch.id);
      final sc = container.read(documentTabProvider(scratch.id).notifier);

      var out = await tester.runAsync(
        () => sc.insert(
          '{"_id":{"\$numberInt":"1"},"name":"first","n":{"\$numberLong":"5"},"when":{"\$date":{"\$numberLong":"1700000000000"}}}',
        ),
      );
      expect(out, isA<WriteOk>());
      await settled(scratch.id);
      expect(
        stateOf(scratch.id).docs.single.text,
        contains('"n":{"\$numberLong":"5"}'),
      );

      final loadedDoc = stateOf(scratch.id).docs.single;
      out = await tester.runAsync(
        () => sc.replace(
          loadedDoc,
          '{"_id":{"\$numberInt":"1"},"name":"edited","n":{"\$numberLong":"5"},"when":{"\$date":{"\$numberLong":"1700000000000"}}}',
        ),
      );
      expect(out, isA<WriteOk>());
      await settled(scratch.id);
      final afterEdit = stateOf(scratch.id).docs.single;
      expect(afterEdit.text, contains('"name":"edited"'));
      // Types did not drift: still an Int64 and a Date.
      expect(afterEdit.text, contains('"n":{"\$numberLong":"5"}'));
      expect(afterEdit.text, contains('"\$date"'));

      // The same stale copy again: someone changed it since -> conflict.
      out = await tester.runAsync(
        () =>
            sc.replace(loadedDoc, '{"_id":{"\$numberInt":"1"},"name":"stale"}'),
      );
      expect(out, isA<WriteConflict>());
      expect((out! as WriteConflict).current, contains('"name":"edited"'));
      out = await tester.runAsync(
        () => sc.replace(
          loadedDoc,
          '{"_id":{"\$numberInt":"1"},"name":"overwritten"}',
          overwrite: true,
        ),
      );
      expect(out, isA<WriteOk>());
      await settled(scratch.id);
      expect(stateOf(scratch.id).docs.single.text, contains('overwritten'));

      // Bare numbers are refused with a message that names the wrappers.
      out = await tester.runAsync(() => sc.insert('{"x": 1}'));
      expect(out, isA<WriteFailed>());
      expect((out! as WriteFailed).error.message, contains('numberInt'));

      sc.select(0);
      out = await tester.runAsync(() => sc.deleteSelected(confirmed: true));
      expect(out, isA<WriteOk>());
      await settled(scratch.id);
      expect(stateOf(scratch.id).docs, isEmpty);
    },
  );
}
