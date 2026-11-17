import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/query_builder/application/sql_query_builder_controller.dart';
import 'package:queravue/features/query_builder/data/query_builder_repository.dart';
import 'package:queravue/features/query_builder/domain/sql_query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';
import 'fake_query_builder.dart';

const _conn = ConnectionProfile(
  id: 'c1',
  name: 'Local PG',
  engineId: 'postgres',
  params: {'database': 'queravue'},
);

void main() {
  test('proto conversion round-trips a complex SqlQueryDraft', () {
    const draft = SqlQueryDraft(
      from: SqlTableRefModel(schema: 'public', table: 'orders', alias: 'o'),
      joins: [
        SqlJoinModel(
          kind: SqlJoinKindModel.left,
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
          alias: 'customer',
        ),
        SqlSelectItemModel.aggregate(
          SqlAggregateExprModel(
            function: SqlAggregateFn.sum,
            column: SqlColumnRefModel(tableAlias: 'o', column: 'total'),
          ),
          alias: 'gross',
        ),
      ],
      distinct: true,
      where: SqlConditionGroupModel(
        op: SqlBoolOpKind.and,
        children: [
          SqlComparisonModel(
            left: SqlColumnOperand(
              SqlColumnRefModel(tableAlias: 'o', column: 'status'),
            ),
            op: SqlOperatorKind.inList,
            operands: [
              SqlLiteralOperand(SqlStringLiteral('paid')),
              SqlLiteralOperand(SqlStringLiteral('shipped')),
            ],
          ),
          SqlComparisonModel(
            left: SqlColumnOperand(
              SqlColumnRefModel(tableAlias: 'o', column: 'total'),
            ),
            op: SqlOperatorKind.between,
            operands: [
              SqlLiteralOperand(SqlIntLiteral(10)),
              SqlLiteralOperand(SqlDoubleLiteral(99.5)),
            ],
          ),
        ],
      ),
      groupBy: [SqlColumnRefModel(tableAlias: 'c', column: 'name')],
      having: SqlComparisonModel(
        left: SqlAggregateOperand(
          SqlAggregateExprModel(function: SqlAggregateFn.count),
        ),
        op: SqlOperatorKind.gt,
        operands: [SqlLiteralOperand(SqlIntLiteral(2))],
      ),
      orderBy: [
        SqlOrderTermModel(
          expression: SqlAggregateOperand(
            SqlAggregateExprModel(
              function: SqlAggregateFn.sum,
              column: SqlColumnRefModel(tableAlias: 'o', column: 'total'),
            ),
          ),
          descending: true,
          nulls: SqlNullsPlacement.last,
        ),
      ],
      limit: 50,
      offset: 10,
    );

    final decoded = sqlModelFromProto(sqlModelToProto(draft));
    expect(decoded, draft);
  });

  test('utf8ByteOffsetToUtf16 maps multi-byte runes accurately', () {
    const text = "SELECT 'héllo😀' FROM t";
    final unionIdx = text.indexOf('FROM');
    // 'é' is 2 bytes (1 UTF-16 unit), '😀' is 4 bytes (2 UTF-16 units).
    final utf8BytesBefore = unionIdx + 1 + 2;
    expect(utf8ByteOffsetToUtf16(text, utf8BytesBefore), unionIdx);
  });

  test('controller loads schema, computes FK join suggestions, generates SQL, and runs/cancels preview', () async {
    final qbRepo = FakeQueryBuilderRepository();
    final queryRepo = FakeQueryRepository(totalRows: 5)
      ..script = const [
        PlanEvent([TextSpanRange(0, 10)]),
        StartedEvent(0, 'res-1'),
        ColumnsEvent(0, fakeColumns),
        RowsEvent(0, [
          [1, 'row-1'],
        ]),
        SummaryEvent(
          statementIndex: 0,
          rowsAffected: 0,
          rowsSpooled: 1,
          duration: Duration(milliseconds: 5),
          notices: [],
          truncated: false,
          hasRows: true,
        ),
      ];
    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(FakeConnectionsRepository(initial: const [_conn])),
        queryBuilderRepositoryProvider.overrideWithValue(qbRepo),
        schemaRepositoryProvider.overrideWithValue(
          FakeBuilderSchemaRepository(),
        ),
        queryRepositoryProvider.overrideWithValue(queryRepo),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedConnectionProvider.notifier).select('c1');
    final tab = container.read(editorTabsProvider.notifier).open('c1');
    final sub = container.listen(sqlQueryBuilderProvider(tab.id), (_, _) {});
    addTearDown(sub.close);

    final ctrl = container.read(sqlQueryBuilderProvider(tab.id).notifier);
    await ctrl.openFromEditor('');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    var s = container.read(sqlQueryBuilderProvider(tab.id));
    expect(s.inBuilderMode, isTrue);
    expect(s.availableTables.map((t) => t.table), ['customers', 'orders']);

    await ctrl.setFromTable(const TableRef(schema: 'public', table: 'orders'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    s = container.read(sqlQueryBuilderProvider(tab.id));
    expect(s.generatedSql, 'SELECT * FROM public.orders AS o');
    expect(s.joinSuggestions, hasLength(1));
    expect(s.joinSuggestions.first.targetTable, 'customers');

    await ctrl.applyJoinSuggestion(s.joinSuggestions.first);
    await ctrl.toggleColumnSelect(
      const SqlColumnRefModel(tableAlias: 'c', column: 'name'),
    );
    await ctrl.addSelectItem(
      const SqlSelectItemModel.aggregate(
        SqlAggregateExprModel(
          function: SqlAggregateFn.sum,
          column: SqlColumnRefModel(tableAlias: 'o', column: 'total'),
        ),
        alias: 'sum_total',
      ),
    );
    await ctrl.setDistinct(true);
    await ctrl.setLimit(250);

    s = container.read(sqlQueryBuilderProvider(tab.id));
    expect(s.generatedSql, contains('INNER JOIN public.customers AS c'));
    expect(s.generatedSql, contains('ON o.customer_id = c.id'));
    expect(s.generatedSql, contains('SUM(o.total) AS "sum_total"'));
    expect(s.generatedSql, contains('LIMIT 250'));

    // Preview applies the default 100 row cap since draft limit (250) > 100.
    await ctrl.runPreview();
    expect(queryRepo.executed, hasLength(1));
    expect(queryRepo.executed.single.text, contains('LIMIT 100'));

    // Open in editor writes generated SQL and switches out of builder mode.
    ctrl.openInEditor(tab.controller);
    expect(tab.controller.text, s.generatedSql);
    expect(
      container.read(sqlQueryBuilderProvider(tab.id)).inBuilderMode,
      isFalse,
    );

    // Cancel during an active preview run calls QueryRepository.cancel.
    queryRepo.holdOpen = Completer<void>();
    await ctrl.openFromEditor(tab.controller.text);
    final previewFuture = ctrl.runPreview();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await ctrl.cancelPreview();
    expect(queryRepo.cancelCalls, 1);
    queryRepo.holdOpen!.complete();
    await previewFuture;
  });

  test('openFromEditor handles commentsDropped and keeps editor open on UNSUPPORTED_CONSTRUCT', () async {
    final qbRepo = FakeQueryBuilderRepository()
      ..nextParseOutcome = const ParseSqlOutcome(
        model: SqlQueryDraft(
          from: SqlTableRefModel(table: 'customers', alias: 'c'),
        ),
        commentsDropped: true,
      );
    final queryRepo = FakeQueryRepository();
    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(FakeConnectionsRepository(initial: const [_conn])),
        queryBuilderRepositoryProvider.overrideWithValue(qbRepo),
        schemaRepositoryProvider.overrideWithValue(
          FakeBuilderSchemaRepository(),
        ),
        queryRepositoryProvider.overrideWithValue(queryRepo),
      ],
    );
    addTearDown(container.dispose);

    final tab = container.read(editorTabsProvider.notifier).open('c1');
    final sub = container.listen(sqlQueryBuilderProvider(tab.id), (_, _) {});
    addTearDown(sub.close);
    final ctrl = container.read(sqlQueryBuilderProvider(tab.id).notifier);

    await ctrl.openFromEditor('-- note\nSELECT * FROM customers c');
    var s = container.read(sqlQueryBuilderProvider(tab.id));
    expect(s.inBuilderMode, isTrue);
    expect(s.commentsDropped, isTrue);
    expect(s.generatedSql, 'SELECT * FROM customers AS c');

    ctrl.openInEditor(tab.controller);
    qbRepo.parseError = const QueryBuilderException(
      kind: QueryBuilderErrorKindModel.unsupportedConstruct,
      message: 'CTEs are not supported',
      offset: 0,
    );
    const cteSql = 'WITH x AS (SELECT 1) SELECT * FROM x';
    await ctrl.openFromEditor(cteSql);
    s = container.read(sqlQueryBuilderProvider(tab.id));
    expect(s.inBuilderMode, isFalse);
    expect(s.editorUnsupportedMessage, 'CTEs are not supported');
    expect(s.editorUnsupportedOffset, 0);
  });
}
