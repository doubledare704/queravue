import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/gen/queravue/v1/querybuilder.pb.dart' as pb;
import '../../../core_client/query_builder_client.dart';
import '../domain/sql_query_models.dart';

abstract interface class QueryBuilderRepository {
  Future<String> generateSql({
    required String sessionId,
    required SqlQueryDraft model,
  });

  Future<ParseSqlOutcome> parseSql({
    required String sessionId,
    required String sql,
  });
}

final queryBuilderRepositoryProvider = Provider<QueryBuilderRepository>(
  (ref) => GrpcQueryBuilderRepository(ref.watch(queryBuilderClientProvider)),
);

class GrpcQueryBuilderRepository implements QueryBuilderRepository {
  GrpcQueryBuilderRepository(this._client);

  final QueryBuilderClient _client;

  @override
  Future<String> generateSql({
    required String sessionId,
    required SqlQueryDraft model,
  }) async {
    try {
      final resp = await _client.generateSql(
        pb.GenerateSqlRequest(
          sessionId: sessionId,
          model: sqlModelToProto(model),
        ),
      );
      if (resp.hasError()) {
        throw _mapError(resp.error);
      }
      return resp.sql;
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    } on StateError catch (e) {
      throw QueryBuilderException(
        kind: QueryBuilderErrorKindModel.notSql,
        message: e.message,
        coreUnavailable: true,
      );
    }
  }

  @override
  Future<ParseSqlOutcome> parseSql({
    required String sessionId,
    required String sql,
  }) async {
    try {
      final resp = await _client.parseSql(
        pb.ParseSqlRequest(sessionId: sessionId, sql: sql),
      );
      if (resp.hasError()) {
        throw _mapError(resp.error);
      }
      return ParseSqlOutcome(
        model: sqlModelFromProto(resp.model),
        commentsDropped: resp.commentsDropped,
      );
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    } on StateError catch (e) {
      throw QueryBuilderException(
        kind: QueryBuilderErrorKindModel.notSql,
        message: e.message,
        coreUnavailable: true,
      );
    }
  }

  QueryBuilderException _mapGrpcError(GrpcError e) => QueryBuilderException(
    kind: QueryBuilderErrorKindModel.invalidModel,
    message: e.message ?? e.toString(),
    coreUnavailable: e.code == StatusCode.unavailable,
  );

  QueryBuilderException _mapError(pb.QueryBuilderError err) =>
      QueryBuilderException(
        kind: switch (err.kind) {
          pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_PARSE =>
            QueryBuilderErrorKindModel.parse,
          pb
              .QueryBuilderErrorKind
              .QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT =>
            QueryBuilderErrorKindModel.unsupportedConstruct,
          pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_NOT_SQL =>
            QueryBuilderErrorKindModel.notSql,
          _ => QueryBuilderErrorKindModel.invalidModel,
        },
        message: err.message,
        offset: err.hasOffset() ? err.offset : null,
      );
}

pb.SqlQueryModel sqlModelToProto(SqlQueryDraft draft) {
  final out = pb.SqlQueryModel(
    distinct: draft.distinct,
    joins: [for (final j in draft.joins) _joinToProto(j)],
    select: [for (final s in draft.select) _selectItemToProto(s)],
    groupBy: [for (final g in draft.groupBy) _columnToProto(g)],
    orderBy: [for (final o in draft.orderBy) _orderToProto(o)],
  );
  if (draft.from != null) {
    out.from = _tableToProto(draft.from!);
  }
  if (draft.where != null) {
    out.where = _conditionToProto(draft.where!);
  }
  if (draft.having != null) {
    out.having = _conditionToProto(draft.having!);
  }
  if (draft.limit != null) {
    out.limit = Int64(draft.limit!);
  }
  if (draft.offset != null) {
    out.offset = Int64(draft.offset!);
  }
  return out;
}

SqlQueryDraft sqlModelFromProto(pb.SqlQueryModel msg) => SqlQueryDraft(
  from: msg.hasFrom() ? _tableFromProto(msg.from) : null,
  joins: [for (final j in msg.joins) _joinFromProto(j)],
  select: [for (final s in msg.select) _selectItemFromProto(s)],
  distinct: msg.distinct,
  where: msg.hasWhere() ? _conditionFromProto(msg.where) : null,
  groupBy: [for (final g in msg.groupBy) _columnFromProto(g)],
  having: msg.hasHaving() ? _conditionFromProto(msg.having) : null,
  orderBy: [for (final o in msg.orderBy) _orderFromProto(o)],
  limit: msg.hasLimit() ? msg.limit.toInt() : null,
  offset: msg.hasOffset() ? msg.offset.toInt() : null,
);

pb.SqlTableRef _tableToProto(SqlTableRefModel t) =>
    pb.SqlTableRef(schema: t.schema, table: t.table, alias: t.alias);

SqlTableRefModel _tableFromProto(pb.SqlTableRef t) =>
    SqlTableRefModel(schema: t.schema, table: t.table, alias: t.alias);

pb.SqlColumnRef _columnToProto(SqlColumnRefModel c) =>
    pb.SqlColumnRef(tableAlias: c.tableAlias, column: c.column);

SqlColumnRefModel _columnFromProto(pb.SqlColumnRef c) =>
    SqlColumnRefModel(tableAlias: c.tableAlias, column: c.column);

pb.SqlAggregateExpr _aggToProto(SqlAggregateExprModel a) => pb.SqlAggregateExpr(
  function: switch (a.function) {
    SqlAggregateFn.count => pb.SqlAggregate.SQL_AGGREGATE_COUNT,
    SqlAggregateFn.sum => pb.SqlAggregate.SQL_AGGREGATE_SUM,
    SqlAggregateFn.avg => pb.SqlAggregate.SQL_AGGREGATE_AVG,
    SqlAggregateFn.min => pb.SqlAggregate.SQL_AGGREGATE_MIN,
    SqlAggregateFn.max => pb.SqlAggregate.SQL_AGGREGATE_MAX,
  },
  column: _columnToProto(a.column),
  distinct: a.distinct,
);

SqlAggregateExprModel _aggFromProto(pb.SqlAggregateExpr a) =>
    SqlAggregateExprModel(
      function: switch (a.function) {
        pb.SqlAggregate.SQL_AGGREGATE_SUM => SqlAggregateFn.sum,
        pb.SqlAggregate.SQL_AGGREGATE_AVG => SqlAggregateFn.avg,
        pb.SqlAggregate.SQL_AGGREGATE_MIN => SqlAggregateFn.min,
        pb.SqlAggregate.SQL_AGGREGATE_MAX => SqlAggregateFn.max,
        _ => SqlAggregateFn.count,
      },
      column: _columnFromProto(a.column),
      distinct: a.distinct,
    );

pb.SqlSelectItem _selectItemToProto(SqlSelectItemModel s) {
  if (s.aggregate != null) {
    return pb.SqlSelectItem(aggregate: _aggToProto(s.aggregate!), alias: s.alias);
  }
  return pb.SqlSelectItem(
    column: _columnToProto(s.column ?? const SqlColumnRefModel()),
    alias: s.alias,
  );
}

SqlSelectItemModel _selectItemFromProto(pb.SqlSelectItem s) {
  if (s.whichExpression() == pb.SqlSelectItem_Expression.aggregate) {
    return SqlSelectItemModel.aggregate(
      _aggFromProto(s.aggregate),
      alias: s.alias,
    );
  }
  return SqlSelectItemModel.column(_columnFromProto(s.column), alias: s.alias);
}

pb.SqlJoin _joinToProto(SqlJoinModel j) => pb.SqlJoin(
  kind: switch (j.kind) {
    SqlJoinKindModel.inner => pb.SqlJoinKind.SQL_JOIN_KIND_INNER,
    SqlJoinKindModel.left => pb.SqlJoinKind.SQL_JOIN_KIND_LEFT,
    SqlJoinKindModel.right => pb.SqlJoinKind.SQL_JOIN_KIND_RIGHT,
    SqlJoinKindModel.full => pb.SqlJoinKind.SQL_JOIN_KIND_FULL,
  },
  table: _tableToProto(j.table),
  on: _conditionToProto(j.on),
);

SqlJoinModel _joinFromProto(pb.SqlJoin j) => SqlJoinModel(
  kind: switch (j.kind) {
    pb.SqlJoinKind.SQL_JOIN_KIND_LEFT => SqlJoinKindModel.left,
    pb.SqlJoinKind.SQL_JOIN_KIND_RIGHT => SqlJoinKindModel.right,
    pb.SqlJoinKind.SQL_JOIN_KIND_FULL => SqlJoinKindModel.full,
    _ => SqlJoinKindModel.inner,
  },
  table: _tableFromProto(j.table),
  on: _conditionFromProto(j.on),
);

pb.SqlCondition _conditionToProto(SqlConditionNode node) => switch (node) {
  SqlComparisonModel() => pb.SqlCondition(
    comparison: pb.SqlComparison(
      left: _operandToProto(node.left),
      op: _operatorToProto(node.op),
      operands: [for (final op in node.operands) _operandToProto(op)],
      negated: node.negated,
    ),
  ),
  SqlConditionGroupModel() => pb.SqlCondition(
    group: pb.SqlConditionGroup(
      op: node.op == SqlBoolOpKind.or
          ? pb.SqlBoolOp.SQL_BOOL_OP_OR
          : pb.SqlBoolOp.SQL_BOOL_OP_AND,
      children: [for (final c in node.children) _conditionToProto(c)],
      negated: node.negated,
    ),
  ),
};

SqlConditionNode _conditionFromProto(pb.SqlCondition cond) {
  if (cond.whichNode() == pb.SqlCondition_Node.group) {
    final g = cond.group;
    return SqlConditionGroupModel(
      op: g.op == pb.SqlBoolOp.SQL_BOOL_OP_OR
          ? SqlBoolOpKind.or
          : SqlBoolOpKind.and,
      children: [for (final c in g.children) _conditionFromProto(c)],
      negated: g.negated,
    );
  }
  final cmp = cond.comparison;
  return SqlComparisonModel(
    left: _operandFromProto(cmp.left),
    op: _operatorFromProto(cmp.op),
    operands: [for (final o in cmp.operands) _operandFromProto(o)],
    negated: cmp.negated,
  );
}

pb.SqlOperator _operatorToProto(SqlOperatorKind op) => switch (op) {
  SqlOperatorKind.eq => pb.SqlOperator.SQL_OPERATOR_EQ,
  SqlOperatorKind.ne => pb.SqlOperator.SQL_OPERATOR_NE,
  SqlOperatorKind.lt => pb.SqlOperator.SQL_OPERATOR_LT,
  SqlOperatorKind.le => pb.SqlOperator.SQL_OPERATOR_LE,
  SqlOperatorKind.gt => pb.SqlOperator.SQL_OPERATOR_GT,
  SqlOperatorKind.ge => pb.SqlOperator.SQL_OPERATOR_GE,
  SqlOperatorKind.like => pb.SqlOperator.SQL_OPERATOR_LIKE,
  SqlOperatorKind.inList => pb.SqlOperator.SQL_OPERATOR_IN,
  SqlOperatorKind.between => pb.SqlOperator.SQL_OPERATOR_BETWEEN,
  SqlOperatorKind.isNull => pb.SqlOperator.SQL_OPERATOR_IS_NULL,
};

SqlOperatorKind _operatorFromProto(pb.SqlOperator op) => switch (op) {
  pb.SqlOperator.SQL_OPERATOR_NE => SqlOperatorKind.ne,
  pb.SqlOperator.SQL_OPERATOR_LT => SqlOperatorKind.lt,
  pb.SqlOperator.SQL_OPERATOR_LE => SqlOperatorKind.le,
  pb.SqlOperator.SQL_OPERATOR_GT => SqlOperatorKind.gt,
  pb.SqlOperator.SQL_OPERATOR_GE => SqlOperatorKind.ge,
  pb.SqlOperator.SQL_OPERATOR_LIKE => SqlOperatorKind.like,
  pb.SqlOperator.SQL_OPERATOR_IN => SqlOperatorKind.inList,
  pb.SqlOperator.SQL_OPERATOR_BETWEEN => SqlOperatorKind.between,
  pb.SqlOperator.SQL_OPERATOR_IS_NULL => SqlOperatorKind.isNull,
  _ => SqlOperatorKind.eq,
};

pb.SqlOperand _operandToProto(SqlOperandModel op) => switch (op) {
  SqlColumnOperand(:final column) => pb.SqlOperand(
    column: _columnToProto(column),
  ),
  SqlLiteralOperand(:final literal) => pb.SqlOperand(
    literal: _literalToProto(literal),
  ),
  SqlAggregateOperand(:final aggregate) => pb.SqlOperand(
    aggregate: _aggToProto(aggregate),
  ),
};

SqlOperandModel _operandFromProto(pb.SqlOperand op) => switch (op.whichKind()) {
  pb.SqlOperand_Kind.literal => SqlLiteralOperand(
    _literalFromProto(op.literal),
  ),
  pb.SqlOperand_Kind.aggregate => SqlAggregateOperand(
    _aggFromProto(op.aggregate),
  ),
  _ => SqlColumnOperand(_columnFromProto(op.column)),
};

pb.SqlLiteral _literalToProto(SqlLiteralModel lit) => switch (lit) {
  SqlNullLiteral() => pb.SqlLiteral(nullValue: true),
  SqlBoolLiteral(:final value) => pb.SqlLiteral(boolValue: value),
  SqlIntLiteral(:final value) => pb.SqlLiteral(intValue: Int64(value)),
  SqlDoubleLiteral(:final value) => pb.SqlLiteral(doubleValue: value),
  SqlStringLiteral(:final value) => pb.SqlLiteral(stringValue: value),
};

SqlLiteralModel _literalFromProto(pb.SqlLiteral lit) => switch (lit.whichValue()) {
  pb.SqlLiteral_Value.nullValue => const SqlNullLiteral(),
  pb.SqlLiteral_Value.boolValue => SqlBoolLiteral(lit.boolValue),
  pb.SqlLiteral_Value.intValue => SqlIntLiteral(lit.intValue.toInt()),
  pb.SqlLiteral_Value.doubleValue => SqlDoubleLiteral(lit.doubleValue),
  pb.SqlLiteral_Value.stringValue => SqlStringLiteral(lit.stringValue),
  pb.SqlLiteral_Value.notSet => const SqlNullLiteral(),
};

pb.SqlOrderTerm _orderToProto(SqlOrderTermModel t) => pb.SqlOrderTerm(
  expression: _operandToProto(t.expression),
  descending: t.descending,
  nulls: switch (t.nulls) {
    SqlNullsPlacement.first => pb.SqlNulls.SQL_NULLS_FIRST,
    SqlNullsPlacement.last => pb.SqlNulls.SQL_NULLS_LAST,
    SqlNullsPlacement.unspecified => pb.SqlNulls.SQL_NULLS_UNSPECIFIED,
  },
);

SqlOrderTermModel _orderFromProto(pb.SqlOrderTerm t) => SqlOrderTermModel(
  expression: _operandFromProto(t.expression),
  descending: t.descending,
  nulls: switch (t.nulls) {
    pb.SqlNulls.SQL_NULLS_FIRST => SqlNullsPlacement.first,
    pb.SqlNulls.SQL_NULLS_LAST => SqlNullsPlacement.last,
    _ => SqlNullsPlacement.unspecified,
  },
);
