import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/query_builder/application/sql_query_builder_controller.dart';
import 'package:queravue/features/query_builder/data/query_builder_repository.dart';
import 'package:queravue/features/query_builder/domain/sql_query_models.dart';
import 'package:queravue/features/query_builder/presentation/sql_query_builder_view.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/builder_golden_comparator.dart';
import '../../support/providers.dart';
import 'fake_query_builder.dart';

class _GoldenSession extends ConnectionSessionController {
  _GoldenSession() : super('c1');

  @override
  ConnectionSessionState build() => const ConnectionSessionState(
    session: SessionInfo(
      id: 'sess-1',
      product: 'PostgreSQL',
      version: '17.1',
      capabilities: {'connect', 'execute', 'schema_inspector'},
    ),
  );
}

Future<void> pumpBuilder(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(1100, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final qbRepo = FakeQueryBuilderRepository()
    ..nextParseOutcome = const ParseSqlOutcome(
      model: SqlQueryDraft(
        from: SqlTableRefModel(schema: 'public', table: 'orders', alias: 'o'),
        joins: [
          SqlJoinModel(
            kind: SqlJoinKindModel.inner,
            table: SqlTableRefModel(
              schema: 'public',
              table: 'customers',
              alias: 'c',
            ),
            on: SqlComparisonModel(
              left: SqlColumnOperand(
                SqlColumnRefModel(tableAlias: 'o', column: 'customer_id'),
              ),
              op: SqlOperatorKind.eq,
              operands: [
                SqlColumnOperand(
                  SqlColumnRefModel(tableAlias: 'c', column: 'id'),
                ),
              ],
            ),
          ),
        ],
        select: [
          SqlSelectItemModel.column(
            SqlColumnRefModel(tableAlias: 'c', column: 'name'),
          ),
          SqlSelectItemModel.aggregate(
            SqlAggregateExprModel(
              function: SqlAggregateFn.sum,
              column: SqlColumnRefModel(tableAlias: 'o', column: 'total'),
            ),
            alias: 'gross',
          ),
        ],
        where: SqlComparisonModel(
          left: SqlColumnOperand(
            SqlColumnRefModel(tableAlias: 'o', column: 'status'),
          ),
          op: SqlOperatorKind.eq,
          operands: [SqlLiteralOperand(SqlStringLiteral('paid'))],
        ),
        groupBy: [SqlColumnRefModel(tableAlias: 'c', column: 'name')],
        orderBy: [
          SqlOrderTermModel(
            expression: SqlColumnOperand(
              SqlColumnRefModel(tableAlias: 'c', column: 'name'),
            ),
          ),
        ],
        limit: 50,
      ),
      commentsDropped: false,
    );

  final conns = FakeConnectionsRepository(
    initial: const [
      ConnectionProfile(
        id: 'c1',
        name: 'PG',
        engineId: 'postgres',
        params: {'database': 'queravue'},
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(conns),
      connectionSessionProvider('c1').overrideWith(_GoldenSession.new),
      queryBuilderRepositoryProvider.overrideWithValue(qbRepo),
      schemaRepositoryProvider.overrideWithValue(FakeBuilderSchemaRepository()),
      queryRepositoryProvider.overrideWithValue(FakeQueryRepository()),
    ],
  );
  addTearDown(container.dispose);

  final tab = container.read(editorTabsProvider.notifier).open('c1');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: brightness,
          ),
        ),
        home: Scaffold(body: SqlQueryBuilderView(tab: tab)),
      ),
    ),
  );
  await container
      .read(sqlQueryBuilderProvider(tab.id).notifier)
      .openFromEditor('SELECT * FROM public.orders o');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SQL query builder view, light', (tester) async {
    useBuilderGoldenComparator();
    await pumpBuilder(tester, Brightness.light);
    await expectLater(
      find.byType(SqlQueryBuilderView),
      matchesGoldenFile('goldens/sql_query_builder_light.png'),
    );
  });

  testWidgets('SQL query builder view, dark', (tester) async {
    useBuilderGoldenComparator();
    await pumpBuilder(tester, Brightness.dark);
    await expectLater(
      find.byType(SqlQueryBuilderView),
      matchesGoldenFile('goldens/sql_query_builder_dark.png'),
    );
  });
}
