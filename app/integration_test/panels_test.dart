// End-to-end: the Indexes, Stats and Validation sections against a real
// core.
//
//   make db-up           # the Mongo test needs the dev replica set
//   make test-e2e-panels
//
// SQLite needs no server. The Mongo test uses MONGO_HOST/MONGO_PORT
// (default 127.0.0.1:27017, replica set rs0).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/admin/data/admin_repository.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/designer/data/design_repository.dart';
import 'package:queravue/features/designer/domain/design_models.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _type(WidgetTester tester, String text) async {
  final field = find.byKey(const Key('validation-text'));
  await tester.tap(field);
  await tester.pump();
  await tester.enterText(field, text);
}

bool _present(Key key) => find.byKey(key).evaluate().isNotEmpty;

String _statementOnScreen() =>
    (find.byKey(const Key('statement-preview')).evaluate().first.widget
            as SelectableText)
        .data!;

Future<ProviderContainer> _startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const QueravueApp()),
  );
  await _pumpUntil(
    tester,
    'core connected',
    () => container.read(coreStatusProvider) is CoreConnected,
  );
  await container.read(connectionsControllerProvider.future);
  return container;
}

Future<ConnectionProfile> _connect(
  WidgetTester tester,
  ProviderContainer container,
  ConnectionProfile profile,
) async {
  final connections = container.read(connectionsRepositoryProvider);
  final saved = await connections.create(profile);
  addTearDown(() async {
    try {
      await connections.delete(saved.id);
    } catch (_) {}
  });
  await container.read(connectionsControllerProvider.notifier).reload();
  container.read(selectedConnectionProvider.notifier).select(saved.id);
  await tester.pumpAndSettle();
  return saved;
}

Future<void> _openSection(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(Key('admin-section-$name')));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SQLite: create and drop an index, read statistics',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      final container = await _startApp(tester);
      final dir = Directory.systemTemp.createTempSync('qv_panels_e2e');
      final saved = await _connect(
        tester,
        container,
        ConnectionProfile(
          name: 'e2e panels sqlite',
          engineId: 'sqlite',
          params: {
            'path': '${dir.path}/panels.db',
            'create_if_missing': 'true',
          },
        ),
      );
      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(saved.id).notifier)
            .connect(),
      );
      expect(session, isNotNull);

      const ref = TableRef(schema: 'main', table: 'e2e_panel');
      final created = await tester.runAsync(
        () => container.read(designRepositoryProvider).apply(session!.id, ref, [
          const CreateTableChange([
            ColumnDraft(
              name: 'id',
              typeName: 'integer',
              nullable: false,
              primaryKey: true,
            ),
            ColumnDraft(name: 'title', typeName: 'text'),
          ]),
        ], confirmed: true),
      );
      expect(created!.error, isNull);

      container.read(editorTabsProvider.notifier).openTable(saved.id, ref);
      await tester.pumpAndSettle();
      expect(_present(const Key('admin-section-indexes')), isTrue);
      expect(_present(const Key('admin-section-stats')), isTrue);
      expect(
        _present(const Key('admin-section-validation')),
        isFalse,
        reason: 'SQLite has no validators',
      );

      await _openSection(tester, 'indexes');
      await _pumpUntil(
        tester,
        'index list',
        () => find.text('No indexes.').evaluate().isNotEmpty,
      );

      await tester.tap(find.byKey(const Key('new-index')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('index-name')), 'ix_title');
      await tester.enterText(find.byKey(const Key('index-keys')), 'title');
      await tester.pump();
      await tester.tap(find.byKey(const Key('index-online')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('index-preview')));
      await _pumpUntil(
        tester,
        'the online refusal',
        () => _present(const Key('index-error')),
      );
      expect(
        (find.byKey(const Key('index-error')).evaluate().first.widget as Text)
            .data,
        contains('cannot build an index online'),
      );
      await tester.tap(find.byKey(const Key('index-online')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('index-preview')));
      await _pumpUntil(
        tester,
        'index preview',
        () => _present(const Key('statement-preview')),
      );
      expect(_statementOnScreen(), contains('"ix_title" ON "e2e_panel"'));
      await tester.tap(find.byKey(const Key('index-create')));
      await _pumpUntil(
        tester,
        'index listed and dialog closed',
        () =>
            find.text('ix_title').evaluate().isNotEmpty &&
            !_present(const Key('index-create')),
      );

      await tester.tap(find.byKey(const Key('drop-index-ix_title')));
      await _pumpUntil(
        tester,
        'drop preview',
        () => _present(const Key('statement-preview')),
      );
      expect(_statementOnScreen(), contains('DROP INDEX'));
      await tester.tap(find.byKey(const Key('index-drop-confirm')));
      await _pumpUntil(
        tester,
        'index dropped',
        () => find.text('No indexes.').evaluate().isNotEmpty,
      );

      await _openSection(tester, 'stats');
      await _pumpUntil(
        tester,
        'stats',
        () => _present(const Key('stat-Page size')),
      );
    },
  );

  testWidgets(
    'Mongo: indexes, statistics and the validator',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      final container = await _startApp(tester);
      final host =
          '${_env('MONGO_HOST', '127.0.0.1')}:${_env('MONGO_PORT', '27017')}';
      final saved = await _connect(
        tester,
        container,
        ConnectionProfile(
          name: 'e2e panels mongo',
          engineId: 'mongodb',
          params: {
            'hosts': host,
            'replica_set': 'rs0',
            'database': 'queravue_e2e',
          },
        ),
      );
      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(saved.id).notifier)
            .connect(),
      );
      expect(session, isNotNull, reason: 'is the dev Mongo up?');
      expect(
        session!.capabilities,
        containsAll(['index_manager', 'stats', 'validation']),
      );

      final collection = 'panels_${DateTime.now().millisecondsSinceEpoch}';
      await tester.runAsync(
        () => container.read(documentRepositoryProvider).insert(
          CollectionTarget(session.id, 'queravue_e2e', collection),
          ['{"name":"a"}'],
        ),
      );
      final ref = TableRef(database: 'queravue_e2e', table: collection);
      container.read(editorTabsProvider.notifier).openCollection(saved.id, ref);
      await tester.pumpAndSettle();

      await _openSection(tester, 'indexes');
      await _pumpUntil(
        tester,
        'the _id index',
        () => find.text('_id_').evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('new-index')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('index-name')), 'ix_name');
      await tester.enterText(find.byKey(const Key('index-keys')), 'name');
      await tester.pump();
      await tester.tap(find.byKey(const Key('index-preview')));
      await _pumpUntil(
        tester,
        'index preview',
        () => _present(const Key('statement-preview')),
      );
      expect(_statementOnScreen(), contains('createIndex'));
      await tester.tap(find.byKey(const Key('index-create')));
      await _pumpUntil(
        tester,
        'index listed and dialog closed',
        () =>
            find.text('ix_name').evaluate().isNotEmpty &&
            !_present(const Key('index-create')),
      );

      await _openSection(tester, 'stats');
      await _pumpUntil(
        tester,
        'stats',
        () => find.text('Estimated rows').evaluate().isNotEmpty,
      );

      await _openSection(tester, 'validation');
      await _pumpUntil(
        tester,
        'validator editor',
        () => _present(const Key('validation-text')),
      );
      final admin = container.read(adminRepositoryProvider);
      await tester.tap(find.byKey(const Key('validation-starter')));
      await _pumpUntil(
        tester,
        'the sample starter',
        () => _present(const Key('validation-starter-note')),
      );
      final starter = tester
          .widget<TextField>(find.byKey(const Key('validation-text')))
          .controller!
          .text;
      expect(starter, contains(r'$jsonSchema'));
      expect(starter, contains('"name"'));
      expect(
        (await tester.runAsync(() => admin.getValidation(session.id, ref)))!
            .value!
            .validator,
        isEmpty,
        reason: 'the starter is not applied',
      );
      await _type(
        tester,
        '{"\$jsonSchema":{"bsonType":"object","required":["name"]}}',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('validation-preview')));
      await _pumpUntil(
        tester,
        'command preview',
        () => _present(const Key('statement-preview')),
      );
      expect(_statementOnScreen(), contains('collMod'));
      await tester.tap(find.byKey(const Key('validation-apply')));
      await _settle(tester);
      final applied = await tester.runAsync(
        () => admin.getValidation(session.id, ref),
      );
      expect(applied!.value!.validator, contains(r'$jsonSchema'));

      await _type(tester, '');
      await tester.pump();
      await tester.tap(find.byKey(const Key('validation-apply')));
      await _settle(tester);
      final removed = await tester.runAsync(
        () => admin.getValidation(session.id, ref),
      );
      expect(removed!.value!.validator, isEmpty);

      await _type(tester, '{"a": ');
      await tester.pump();
      await tester.tap(find.byKey(const Key('validation-apply')));
      await _pumpUntil(
        tester,
        'syntax error position',
        () => _present(const Key('validation-error')),
      );
      expect(
        (find.byKey(const Key('validation-error')).evaluate().first.widget
                as Text)
            .data,
        startsWith('Line 1, column'),
      );
    },
  );
}
