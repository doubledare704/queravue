// End-to-end: the table designer against the docker PostgreSQL.
//
//   make db-up
//   make test-e2e-designer-postgres
//
// Creates a table with an identity key, a foreign key, a unique and a check
// constraint through the designer, then edits it (type, nullability, new
// column, dropped foreign key) and checks the server's own description of
// the table after each apply. Connection settings: PG_HOST, PG_PORT, PG_DB,
// PG_USER, PG_PASSWORD (defaults match dev/docker-compose.yml).
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
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/history/data/history_repository.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

const _parent = 'qv_e2e_parent';
const _child = 'qv_e2e_child';

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

bool _present(Key key) => find.byKey(key).evaluate().isNotEmpty;

List<String> _previewedStatements() => [
  for (final e in find.byKey(const Key('statement-preview')).evaluate())
    (e.widget as SelectableText).data!,
];

Future<void> _type(WidgetTester tester, Key key, String text) async {
  final field = find.byKey(key);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pump();
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _applyAndWait(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('ddl-apply')));
  await _pumpUntil(
    tester,
    'dialog closed',
    () => !_present(const Key('ddl-apply')),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PostgreSQL: design a table with constraints, then edit it',
    timeout: const Timeout(Duration(minutes: 4)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
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
      await container.read(connectionsControllerProvider.future);

      final connections = container.read(connectionsRepositoryProvider);
      final saved = await connections.create(
        ConnectionProfile(
          name: 'e2e designer postgres',
          engineId: 'postgres',
          params: {
            'host': _env('PG_HOST', '127.0.0.1'),
            'port': _env('PG_PORT', '5432'),
            'database': _env('PG_DB', 'queravue'),
            'user': _env('PG_USER', 'queravue'),
            'sslmode': 'disable',
          },
        ),
        password: _env('PG_PASSWORD', 'queravue'),
      );
      addTearDown(() async {
        try {
          await connections.delete(saved.id);
        } catch (_) {}
      });
      await container.read(connectionsControllerProvider.notifier).reload();
      container.read(selectedConnectionProvider.notifier).select(saved.id);
      await tester.pumpAndSettle();

      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(saved.id).notifier)
            .connect(),
      );
      expect(session, isNotNull, reason: 'is the dev PostgreSQL up?');

      Future<void> exec(String sql) async {
        final events = await tester.runAsync(
          () => container
              .read(queryRepositoryProvider)
              .execute(ExecuteRequest(sessionId: session!.id, text: sql))
              .toList(),
        );
        final failure = events!.whereType<ErrorEvent>().firstOrNull;
        expect(failure, isNull, reason: 'running: $sql');
      }

      Future<void> dropTables() async {
        await exec('DROP TABLE IF EXISTS $_child');
        await exec('DROP TABLE IF EXISTS $_parent');
      }

      await dropTables();
      addTearDown(() async {
        try {
          await container
              .read(queryRepositoryProvider)
              .execute(
                ExecuteRequest(
                  sessionId: session!.id,
                  text: 'DROP TABLE IF EXISTS $_child',
                ),
              )
              .toList();
          await container
              .read(queryRepositoryProvider)
              .execute(
                ExecuteRequest(
                  sessionId: session.id,
                  text: 'DROP TABLE IF EXISTS $_parent',
                ),
              )
              .toList();
        } catch (_) {}
      });
      await exec('CREATE TABLE $_parent (id integer PRIMARY KEY)');

      final schema = container.read(schemaRepositoryProvider);
      Future<TableDetails> describe() async => (await tester.runAsync(
        () => schema.getTableDetails(
          session!.id,
          const TableRef(schema: 'public', table: _child),
          refresh: true,
        ),
      ))!;

      // ---- design a new table ----
      container
          .read(editorTabsProvider.notifier)
          .openDesigner(
            saved.id,
            const TableRef(schema: 'public', table: ''),
            newTable: true,
          );
      await tester.pumpAndSettle();
      await _type(tester, const Key('designer-table-name'), _child);
      await tester.tap(find.byKey(const Key('col-identity-0')));
      await tester.tap(find.byKey(const Key('designer-add-column')));
      await tester.pump();
      await _type(tester, const Key('col-name-1'), 'parent_id');
      await _type(tester, const Key('col-type-1'), 'integer');
      await tester.tap(find.byKey(const Key('col-nullable-1')));
      await tester.tap(find.byKey(const Key('designer-add-column')));
      await tester.pump();
      await _type(tester, const Key('col-name-2'), 'title');
      await _type(tester, const Key('col-type-2'), 'varchar(20)');
      await tester.pump();

      await tester.tap(find.byKey(const Key('add-fk')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('fk-columns'), 'parent_id');
      await _type(tester, const Key('fk-ref-table'), _parent);
      await _type(tester, const Key('fk-ref-columns'), 'id');
      await tester.tap(find.byKey(const Key('fk-on-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CASCADE').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fk-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-unique')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('unique-columns'), 'title');
      await tester.tap(find.byKey(const Key('unique-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-check')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('check-expression'), 'length(title) > 0');
      await tester.tap(find.byKey(const Key('check-save')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('designer-review')));
      await _pumpUntil(
        tester,
        'create preview',
        () => _previewedStatements().isNotEmpty,
      );
      final createSql = _previewedStatements();
      expect(createSql.single, contains('GENERATED BY DEFAULT AS IDENTITY'));
      expect(
        createSql.single,
        contains(
          'FOREIGN KEY ("parent_id") REFERENCES "public"."$_parent" ("id") ON DELETE CASCADE',
        ),
      );
      expect(createSql.single, contains('UNIQUE ("title")'));
      expect(createSql.single, contains('CHECK (length(title) > 0)'));
      expect(
        find.text('Runs in one transaction: a failure rolls everything back.'),
        findsOneWidget,
      );
      await _applyAndWait(tester);

      final created = await describe();
      final id = created.columns.firstWhere((c) => c.name == 'id');
      expect(id.identity, isTrue);
      expect(id.isPrimaryKey, isTrue);
      expect(created.foreignKeys.single.onDelete, ReferentialAction.cascade);
      expect(created.foreignKeys.single.referencedTable, _parent);
      final fkName = created.foreignKeys.single.name;

      // ---- edit it ----
      container
          .read(editorTabsProvider.notifier)
          .openDesigner(
            saved.id,
            const TableRef(schema: 'public', table: _child),
          );
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        'designer loaded',
        () => _present(const Key('col-name-2')),
      );
      await _type(tester, const Key('col-type-2'), 'varchar(50)');
      await tester.tap(find.byKey(const Key('col-nullable-2')));
      await tester.tap(find.byKey(const Key('designer-add-column')));
      await tester.pump();
      await _type(tester, const Key('col-name-3'), 'note');
      await _type(tester, const Key('col-type-3'), 'text');
      await tester.pump();
      await tester.ensureVisible(find.byKey(Key('drop-fk-$fkName')));
      await tester.tap(find.byKey(Key('drop-fk-$fkName')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('designer-review')));
      await _pumpUntil(
        tester,
        'edit preview',
        () => _previewedStatements().isNotEmpty,
      );
      final editSql = _previewedStatements();
      expect(editSql, hasLength(4));
      expect(editSql[0], contains('DROP CONSTRAINT "$fkName"'));
      expect(editSql[1], contains('ALTER COLUMN "title" TYPE varchar(50)'));
      expect(editSql[2], contains('ALTER COLUMN "title" SET NOT NULL'));
      expect(editSql[3], contains('ADD COLUMN "note" text'));
      expect(find.text('Apply (destructive)'), findsOneWidget);
      await _applyAndWait(tester);

      final edited = await describe();
      expect(edited.foreignKeys, isEmpty);
      final title = edited.columns.firstWhere((c) => c.name == 'title');
      expect(title.typeName, contains('50'));
      expect(title.nullable, isFalse);
      expect(edited.columns.map((c) => c.name), contains('note'));

      final history = await tester.runAsync(
        () => container
            .read(historyRepositoryProvider)
            .listHistory(connectionId: saved.id, limit: 100),
      );
      final ran = history!.items.map((i) => i.queryText).toList();
      for (final sql in [...createSql, ...editSql]) {
        expect(ran, contains(sql));
      }
    },
  );
}
