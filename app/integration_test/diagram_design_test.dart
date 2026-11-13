// End-to-end: design mode on the schema diagram, with the real app and core.
//
//   make test-e2e-diagram-design      (SQLite file; PostgreSQL when the docker one is up)
//
// Drafts two tables on the diagram, the referencing one first, draws a
// relation between them, applies the DDL and checks the server's own
// description of the tables. PostgreSQL uses its own schema, dropped after;
// it is skipped when QV_E2E_SKIP_POSTGRES is set. Connection settings:
// PG_HOST, PG_PORT, PG_DB, PG_USER, PG_PASSWORD.
import 'dart:io';

import 'package:flutter/gestures.dart';
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
import 'package:queravue/features/diagram/application/diagram_controller.dart';
import 'package:queravue/features/diagram/presentation/diagram_canvas.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import 'support/settle.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

const _books = 'qv_e2e_books';
const _authors = 'qv_e2e_authors';
const _pgSchema = 'qv_e2e_diagram';

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

Future<({ProviderContainer container, String connectionId, String sessionId})>
_start(
  WidgetTester tester,
  ConnectionProfile profile, {
  String? password,
}) async {
  tester.view.physicalSize = const Size(1440, 1000);
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
  final connections = container.read(connectionsRepositoryProvider);
  final saved = await connections.create(profile, password: password);
  addTearDown(() async {
    try {
      await connections.delete(saved.id);
    } catch (_) {}
  });
  await container.read(connectionsControllerProvider.notifier).reload();
  container.read(selectedConnectionProvider.notifier).select(saved.id);
  await settle(tester);
  final session = await tester.runAsync(
    () =>
        container.read(connectionSessionProvider(saved.id).notifier).connect(),
  );
  expect(session, isNotNull, reason: 'could not connect to ${profile.name}');
  return (container: container, connectionId: saved.id, sessionId: session!.id);
}

Future<void> _exec(
  WidgetTester tester,
  ProviderContainer container,
  String sessionId,
  String sql,
) async {
  final events = await tester.runAsync(
    () => container
        .read(queryRepositoryProvider)
        .execute(ExecuteRequest(sessionId: sessionId, text: sql))
        .toList(),
  );
  final failure = events!.whereType<ErrorEvent>().firstOrNull;
  expect(failure, isNull, reason: 'running: $sql');
}

/// Drafts books (referencing) before authors (referenced), relates them and
/// applies; then the core reports both tables and the foreign key.
Future<void> _designAndApply(
  WidgetTester tester,
  ProviderContainer container, {
  required String connectionId,
  required String sessionId,
  required String schema,
}) async {
  final tabId = container
      .read(editorTabsProvider.notifier)
      .openDiagram(connectionId, schema: schema)
      .id;
  DiagramState state() => container.read(diagramProvider(tabId));
  await _pumpUntil(tester, 'diagram shown', () => state() is DiagramReady);
  await settle(tester);

  Future<void> draft(String name, {String? extraColumn}) async {
    final button = _present(const Key('diagram-empty-new-table'))
        ? const Key('diagram-empty-new-table')
        : const Key('diagram-new-table');
    await tapAndSettle(tester, find.byKey(button));
    await tester.enterText(find.byKey(const Key('draft-table-name')), name);
    if (extraColumn != null) {
      await tapAndSettle(tester, find.byKey(const Key('draft-add-column')));
      await tester.enterText(find.byKey(const Key('col-name-1')), extraColumn);
      await tester.enterText(
        find.byKey(const Key('col-type-1')),
        'varchar(80)',
      );
    }
    await tapAndSettle(tester, find.byKey(const Key('draft-table-save')));
  }

  await draft(_books, extraColumn: 'title');
  await draft(_authors, extraColumn: 'name');

  final ready = state() as DiagramReady;
  final canvas = tester.state<DiagramCanvasState>(find.byType(DiagramCanvas));
  canvas.fit();
  await settle(tester);
  final center = ready.rects[_books]!.center;
  await tester.tapAt(
    tester.getTopLeft(find.byType(DiagramCanvas)) + canvas.toScreen(center),
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await settle(tester);
  await tapAndSettle(tester, find.byKey(const Key('diagram-menu-relation')));
  await tapAndSettle(tester, find.byKey(const Key('draft-relation-target')));
  await tapAndSettle(
    tester,
    find.widgetWithText(MenuItemButton, _authors).last,
  );
  expect(find.textContaining('Adds column ${_authors}_id'), findsOneWidget);
  await tapAndSettle(tester, find.byKey(const Key('draft-relation-add')));

  await tester.tap(find.byKey(const Key('diagram-review-draft')));
  await _pumpUntil(
    tester,
    'DDL preview',
    () => find.byKey(const Key('statement-preview')).evaluate().isNotEmpty,
  );
  final statements = [
    for (final e in find.byKey(const Key('statement-preview')).evaluate())
      (e.widget as SelectableText).data!,
  ];
  final authorsAt = statements.indexWhere(
    (s) => s.contains('CREATE TABLE') && s.contains(_authors),
  );
  final referenceAt = statements.indexWhere((s) => s.contains('REFERENCES'));
  expect(authorsAt, isNonNegative, reason: statements.join('\n'));
  expect(referenceAt, isNonNegative, reason: statements.join('\n'));
  expect(
    referenceAt > authorsAt || statements[referenceAt].contains('CREATE TABLE'),
    isTrue,
    reason:
        'the reference comes after the table it points at:\n${statements.join('\n')}',
  );

  await tester.tap(find.byKey(const Key('ddl-apply')));
  await _pumpUntil(tester, 'applied and reloaded', () {
    final s = state();
    return !_present(const Key('ddl-apply')) &&
        s is DiagramReady &&
        s.draft.isEmpty &&
        s.graph.tables.any((t) => t.name == _authors);
  });
  final applied = state() as DiagramReady;
  final books = applied.graph.tables.firstWhere((t) => t.name == _books);
  expect(books.draft, isFalse);
  expect(books.relations.single.referencedTable, _authors);
  expect(applied.rects[_books]!.topLeft, ready.rects[_books]!.topLeft);

  final details = await tester.runAsync(
    () => container
        .read(schemaRepositoryProvider)
        .getTableDetails(
          sessionId,
          TableRef(schema: schema, table: _books),
          refresh: true,
        ),
  );
  expect(
    [for (final c in details!.columns) c.name],
    ['id', 'title', '${_authors}_id'],
  );
  final fk = details.foreignKeys.single;
  expect(fk.referencedTable, _authors);
  expect(fk.columns, ['${_authors}_id']);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SQLite: a designed diagram creates related tables',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('qv_diagram_e2e');
      addTearDown(() => dir.deleteSync(recursive: true));
      final env = await _start(
        tester,
        ConnectionProfile(
          name: 'e2e diagram sqlite',
          engineId: 'sqlite',
          params: {
            'path': '${dir.path}/diagram.db',
            'create_if_missing': 'true',
          },
        ),
      );
      await _designAndApply(
        tester,
        env.container,
        connectionId: env.connectionId,
        sessionId: env.sessionId,
        schema: 'main',
      );
    },
  );

  testWidgets(
    'PostgreSQL: a designed diagram creates related tables',
    skip: Platform.environment.containsKey('QV_E2E_SKIP_POSTGRES'),
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      final env = await _start(
        tester,
        ConnectionProfile(
          name: 'e2e diagram postgres',
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
      Future<void> exec(String sql) =>
          _exec(tester, env.container, env.sessionId, sql);
      await exec('DROP SCHEMA IF EXISTS $_pgSchema CASCADE');
      await exec('CREATE SCHEMA $_pgSchema');
      addTearDown(() async {
        try {
          await env.container
              .read(queryRepositoryProvider)
              .execute(
                ExecuteRequest(
                  sessionId: env.sessionId,
                  text: 'DROP SCHEMA IF EXISTS $_pgSchema CASCADE',
                ),
              )
              .toList();
        } catch (_) {}
      });
      await _designAndApply(
        tester,
        env.container,
        connectionId: env.connectionId,
        sessionId: env.sessionId,
        schema: _pgSchema,
      );
    },
  );
}
