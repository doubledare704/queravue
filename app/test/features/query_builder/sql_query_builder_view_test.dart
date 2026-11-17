import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/query_builder/data/query_builder_repository.dart';
import 'package:queravue/features/query_builder/domain/sql_query_models.dart';
import 'package:queravue/features/query_builder/presentation/sql_query_builder_view.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';
import 'fake_query_builder.dart';

const _sqlConn = ConnectionProfile(
  id: 'sql1',
  name: 'PG',
  engineId: 'pg_engine',
  params: {'database': 'queravue'},
);

const _docConn = ConnectionProfile(
  id: 'doc1',
  name: 'Mongo',
  engineId: 'doc_engine',
);

const _engines = [
  EngineSpec(
    id: 'pg_engine',
    displayName: 'Postgres',
    fields: [],
    capabilities: {'connect', 'execute', 'schema_inspector', 'format'},
  ),
  EngineSpec(
    id: 'doc_engine',
    displayName: 'MongoDB',
    fields: [],
    capabilities: {'connect', 'schema_inspector', 'document_store', 'shell'},
  ),
];

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(
      version: '0.1.0-dev',
      protocolVersion: 11,
      capabilities: {'query'},
    ),
  );
}

Future<
  ({
    ProviderContainer container,
    FakeQueryBuilderRepository qbRepo,
    FakeQueryRepository queryRepo,
  })
>
pumpWorkspace(WidgetTester tester, {String selectedId = 'sql1'}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final qbRepo = FakeQueryBuilderRepository();
  final queryRepo = FakeQueryRepository(totalRows: 2)
    ..script = const [
      PlanEvent([TextSpanRange(0, 10)]),
      StartedEvent(0, 'res-1'),
      ColumnsEvent(0, fakeColumns),
      RowsEvent(0, [
        [1, 'row-1'],
        [2, 'row-2'],
      ]),
      SummaryEvent(
        statementIndex: 0,
        rowsAffected: 0,
        rowsSpooled: 2,
        duration: Duration(milliseconds: 12),
        notices: [],
        truncated: false,
        hasRows: true,
      ),
    ];
  final conns = FakeConnectionsRepository(initial: const [_sqlConn, _docConn])
    ..engines = _engines;
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(conns),
      queryBuilderRepositoryProvider.overrideWithValue(qbRepo),
      schemaRepositoryProvider.overrideWithValue(FakeBuilderSchemaRepository()),
      queryRepositoryProvider.overrideWithValue(queryRepo),
      coreStatusProvider.overrideWith(_Connected.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  container.read(selectedConnectionProvider.notifier).select(selectedId);
  await tester.pumpAndSettle();
  return (container: container, qbRepo: qbRepo, queryRepo: queryRepo);
}

void main() {
  testWidgets(
    'Visual builder button is gated on SQL capabilities, not engine id',
    (tester) async {
      final env = await pumpWorkspace(tester, selectedId: 'sql1');
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('toggle-query-builder-button')),
        findsOneWidget,
      );

      env.container.read(selectedConnectionProvider.notifier).select('doc1');
      await tester.pumpAndSettle();
      env.container.read(editorTabsProvider.notifier).open('doc1');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('toggle-query-builder-button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'builds query with table picker, FK suggestion, aggregate, filter, preview, and opens in editor',
    (tester) async {
      final env = await pumpWorkspace(tester);
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle-query-builder-button')));
      await tester.pumpAndSettle();

      Future<void> scrollTo(Finder target) async {
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: find
              .descendant(
                of: find.byType(SqlQueryBuilderView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }

      // Pick FROM table "orders".
      await tester.tap(find.byKey(const Key('qb-from-table-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('public.orders').last);
      await tester.pumpAndSettle();

      await scrollTo(find.byKey(const Key('qb-generated-sql')));
      expect(find.byKey(const Key('qb-generated-sql')), findsOneWidget);
      expect(
        find.textContaining('SELECT * FROM public.orders AS o'),
        findsOneWidget,
      );

      // Apply FK join suggestion for customers.
      final fkChip = find.byKey(
        const Key('qb-fk-suggestion-fk_orders_customer'),
      );
      await tester.dragUntilVisible(
        fkChip,
        find
            .descendant(
              of: find.byType(SqlQueryBuilderView),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();
      expect(fkChip, findsOneWidget);
      await tester.tap(fkChip);
      await tester.pumpAndSettle();

      // Toggle a column chip and add an aggregate.
      await scrollTo(find.byKey(const Key('qb-col-chip-c.name')));
      await tester.tap(find.byKey(const Key('qb-col-chip-c.name')));
      await tester.pumpAndSettle();
      await scrollTo(find.byKey(const Key('qb-add-aggregate-button')));
      await tester.tap(find.byKey(const Key('qb-add-aggregate-button')));
      await tester.pumpAndSettle();

      // Add a WHERE condition and set LIMIT.
      await scrollTo(find.byKey(const Key('qb-where-add-condition')));
      await tester.tap(find.byKey(const Key('qb-where-add-condition')));
      await tester.pumpAndSettle();
      await scrollTo(find.byKey(const Key('qb-limit-field')));
      await tester.enterText(find.byKey(const Key('qb-limit-field')), '15');
      await tester.pumpAndSettle();

      await scrollTo(find.byKey(const Key('qb-generated-sql')));
      final sqlWidget = tester.widget<SelectableText>(
        find.byKey(const Key('qb-generated-sql')),
      );
      expect(sqlWidget.data, contains('INNER JOIN public.customers AS c'));
      expect(sqlWidget.data, contains('c.name'));
      expect(sqlWidget.data, contains('COUNT(*)'));
      expect(sqlWidget.data, contains('LIMIT 15'));

      // Run Preview and check streaming grid output.
      await tester.tap(find.byKey(const Key('qb-preview-button')));
      await tester.pumpAndSettle();
      expect(env.queryRepo.executed, hasLength(1));
      expect(find.text('row-1'), findsOneWidget);

      // Open in editor writes SQL back and returns to editor view.
      await tester.tap(find.byKey(const Key('qb-open-in-editor-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('run-button')), findsOneWidget);
      final tab = env.container.read(editorTabsProvider).tabs.single;
      expect(tab.controller.text, sqlWidget.data);
    },
  );

  testWidgets(
    'ParseSql commentsDropped warning and UNSUPPORTED_CONSTRUCT banner in editor',
    (tester) async {
      final env = await pumpWorkspace(tester);
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      final tab = env.container.read(editorTabsProvider).tabs.single;

      // Unsupported SQL keeps editor open and displays banner.
      tab.controller.text = 'WITH cte AS (SELECT 1) SELECT * FROM cte';
      env.qbRepo.parseError = const QueryBuilderException(
        kind: QueryBuilderErrorKindModel.unsupportedConstruct,
        message: 'only single SELECT statements are supported',
        offset: 0,
      );
      await tester.tap(find.byKey(const Key('toggle-query-builder-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qb-unsupported-banner')), findsOneWidget);
      expect(
        find.textContaining('only single SELECT statements are supported'),
        findsOneWidget,
      );
      expect(tab.controller.text, 'WITH cte AS (SELECT 1) SELECT * FROM cte');

      // Supported SQL with comments opens builder and warns comments were dropped.
      env.qbRepo.parseError = null;
      env.qbRepo.nextParseOutcome = const ParseSqlOutcome(
        model: SqlQueryDraft(
          from: SqlTableRefModel(schema: 'public', table: 'orders', alias: 'o'),
        ),
        commentsDropped: true,
      );
      tab.controller.text = '-- lead\nSELECT * FROM public.orders o';
      await tester.tap(find.byKey(const Key('toggle-query-builder-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('qb-comments-dropped-banner')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shortcut Ctrl+Alt+B toggles visual query builder', (
    tester,
  ) async {
    await pumpWorkspace(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qb-open-in-editor-button')), findsOneWidget);
  });
}
