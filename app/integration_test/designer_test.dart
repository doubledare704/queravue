// End-to-end: real app + real queravued + a SQLite file (no docker needed).
//
//   make test-e2e-designer
//
// Designs a new table in the table designer, reviews and applies its DDL,
// then edits the table (rename, add a column) and checks that the
// statements previewed are the statements the core ran and recorded.
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
import 'package:queravue/features/history/data/history_repository.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

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

List<String> _previewedStatements() => [
  for (final e in find.byKey(const Key('statement-preview')).evaluate())
    (e.widget as SelectableText).data!,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'design a table, apply its DDL, then edit it',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final dir = Directory.systemTemp.createTempSync('qv_designer_e2e');

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
          name: 'e2e designer sqlite',
          engineId: 'sqlite',
          params: {
            'path': '${dir.path}/designer.db',
            'create_if_missing': 'true',
          },
        ),
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
      expect(session, isNotNull);
      final schema = container.read(schemaRepositoryProvider);
      Future<List<String>> columns(String table) async {
        final details = await tester.runAsync(
          () => schema.getTableDetails(
            session!.id,
            TableRef(schema: 'main', table: table),
            refresh: true,
          ),
        );
        return [for (final c in details!.columns) c.name];
      }

      container
          .read(editorTabsProvider.notifier)
          .openDesigner(
            saved.id,
            const TableRef(schema: 'main', table: ''),
            newTable: true,
          );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('designer-table-name')),
        'e2e_items',
      );
      await tester.tap(find.byKey(const Key('designer-add-column')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('col-name-1')), 'title');
      await tester.enterText(find.byKey(const Key('col-type-1')), 'text');
      await tester.pump();
      await tester.tap(find.byKey(const Key('designer-review')));
      await _pumpUntil(
        tester,
        'create preview',
        () => _previewedStatements().isNotEmpty,
      );
      final createSql = _previewedStatements();
      expect(createSql.single, startsWith('CREATE TABLE'));
      expect(createSql.single, contains('"title" text'));
      await tester.tap(find.byKey(const Key('ddl-apply')));
      await _pumpUntil(
        tester,
        'dialog closed',
        () => find.byKey(const Key('ddl-apply')).evaluate().isEmpty,
      );
      expect(await columns('e2e_items'), ['id', 'title']);

      container
          .read(editorTabsProvider.notifier)
          .openDesigner(
            saved.id,
            const TableRef(schema: 'main', table: 'e2e_items'),
          );
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        'designer loaded',
        () => find.byKey(const Key('col-name-1')).evaluate().isNotEmpty,
      );
      await tester.enterText(find.byKey(const Key('col-name-1')), 'name');
      await tester.tap(find.byKey(const Key('designer-add-column')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('col-name-2')), 'qty');
      await tester.enterText(find.byKey(const Key('col-type-2')), 'integer');
      await tester.pump();
      await tester.tap(find.byKey(const Key('designer-review')));
      await _pumpUntil(
        tester,
        'edit preview',
        () => _previewedStatements().isNotEmpty,
      );
      final editSql = _previewedStatements();
      expect(editSql, hasLength(2));
      expect(editSql[0], contains('RENAME COLUMN "title" TO "name"'));
      expect(editSql[1], contains('ADD COLUMN "qty" integer'));
      await tester.tap(find.byKey(const Key('ddl-apply')));
      await _pumpUntil(
        tester,
        'dialog closed',
        () => find.byKey(const Key('ddl-apply')).evaluate().isEmpty,
      );
      expect(await columns('e2e_items'), ['id', 'name', 'qty']);

      final history = await tester.runAsync(
        () => container
            .read(historyRepositoryProvider)
            .listHistory(connectionId: saved.id),
      );
      final ran = history!.items.map((i) => i.queryText).toList();
      for (final sql in [...createSql, ...editSql]) {
        expect(ran, contains(sql));
      }
    },
  );
}
