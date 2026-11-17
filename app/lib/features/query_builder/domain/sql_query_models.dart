import 'dart:convert';

import 'package:flutter/foundation.dart';

enum SqlJoinKindModel {
  inner('INNER JOIN'),
  left('LEFT JOIN'),
  right('RIGHT JOIN'),
  full('FULL JOIN');

  const SqlJoinKindModel(this.label);
  final String label;
}

enum SqlAggregateFn {
  count('COUNT'),
  sum('SUM'),
  avg('AVG'),
  min('MIN'),
  max('MAX');

  const SqlAggregateFn(this.label);
  final String label;
}

enum SqlOperatorKind {
  eq('=', 1),
  ne('<>', 1),
  lt('<', 1),
  le('<=', 1),
  gt('>', 1),
  ge('>=', 1),
  like('LIKE', 1),
  inList('IN', -1),
  between('BETWEEN', 2),
  isNull('IS NULL', 0);

  const SqlOperatorKind(this.label, this.arity);
  final String label;
  final int arity;
}

enum SqlBoolOpKind {
  and('AND'),
  or('OR');

  const SqlBoolOpKind(this.label);
  final String label;
}

enum SqlNullsPlacement {
  unspecified('Default'),
  first('NULLS FIRST'),
  last('NULLS LAST');

  const SqlNullsPlacement(this.label);
  final String label;
}

enum QueryBuilderErrorKindModel {
  invalidModel,
  parse,
  unsupportedConstruct,
  notSql,
}

class QueryBuilderException implements Exception {
  const QueryBuilderException({
    required this.kind,
    required this.message,
    this.offset,
    this.coreUnavailable = false,
  });

  final QueryBuilderErrorKindModel kind;
  final String message;
  final int? offset;
  final bool coreUnavailable;

  @override
  String toString() => message;
}

@immutable
class SqlTableRefModel {
  const SqlTableRefModel({
    this.schema = '',
    required this.table,
    this.alias = '',
  });

  final String schema;
  final String table;
  final String alias;

  String get effectiveAlias => alias.isNotEmpty ? alias : table;

  String get qualifiedName =>
      schema.isNotEmpty && schema != 'main' ? '$schema.$table' : table;

  SqlTableRefModel copyWith({String? schema, String? table, String? alias}) =>
      SqlTableRefModel(
        schema: schema ?? this.schema,
        table: table ?? this.table,
        alias: alias ?? this.alias,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlTableRefModel &&
          schema == other.schema &&
          table == other.table &&
          alias == other.alias;

  @override
  int get hashCode => Object.hash(schema, table, alias);
}

@immutable
class SqlColumnRefModel {
  const SqlColumnRefModel({this.tableAlias = '', this.column = ''});

  final String tableAlias;
  final String column;

  String get display {
    if (tableAlias.isEmpty) return column.isEmpty ? '*' : column;
    return column.isEmpty ? '$tableAlias.*' : '$tableAlias.$column';
  }

  SqlColumnRefModel copyWith({String? tableAlias, String? column}) =>
      SqlColumnRefModel(
        tableAlias: tableAlias ?? this.tableAlias,
        column: column ?? this.column,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlColumnRefModel &&
          tableAlias == other.tableAlias &&
          column == other.column;

  @override
  int get hashCode => Object.hash(tableAlias, column);
}

@immutable
class SqlAggregateExprModel {
  const SqlAggregateExprModel({
    required this.function,
    this.column = const SqlColumnRefModel(),
    this.distinct = false,
  });

  final SqlAggregateFn function;
  final SqlColumnRefModel column;
  final bool distinct;

  String get display {
    final arg = column.column.isEmpty ? '*' : column.display;
    final prefix = distinct ? 'DISTINCT ' : '';
    return '${function.label}($prefix$arg)';
  }

  SqlAggregateExprModel copyWith({
    SqlAggregateFn? function,
    SqlColumnRefModel? column,
    bool? distinct,
  }) => SqlAggregateExprModel(
    function: function ?? this.function,
    column: column ?? this.column,
    distinct: distinct ?? this.distinct,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlAggregateExprModel &&
          function == other.function &&
          column == other.column &&
          distinct == other.distinct;

  @override
  int get hashCode => Object.hash(function, column, distinct);
}

@immutable
class SqlSelectItemModel {
  const SqlSelectItemModel.column(this.column, {this.alias = ''})
    : aggregate = null;

  const SqlSelectItemModel.aggregate(this.aggregate, {this.alias = ''})
    : column = null;

  final SqlColumnRefModel? column;
  final SqlAggregateExprModel? aggregate;
  final String alias;

  bool get isAggregate => aggregate != null;

  SqlSelectItemModel copyWith({
    SqlColumnRefModel? column,
    SqlAggregateExprModel? aggregate,
    String? alias,
  }) {
    if (aggregate != null) {
      return SqlSelectItemModel.aggregate(
        aggregate,
        alias: alias ?? this.alias,
      );
    }
    if (column != null) {
      return SqlSelectItemModel.column(column, alias: alias ?? this.alias);
    }
    return this.aggregate != null
        ? SqlSelectItemModel.aggregate(
            this.aggregate,
            alias: alias ?? this.alias,
          )
        : SqlSelectItemModel.column(this.column, alias: alias ?? this.alias);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlSelectItemModel &&
          column == other.column &&
          aggregate == other.aggregate &&
          alias == other.alias;

  @override
  int get hashCode => Object.hash(column, aggregate, alias);
}

@immutable
sealed class SqlLiteralModel {
  const SqlLiteralModel();
}

final class SqlNullLiteral extends SqlLiteralModel {
  const SqlNullLiteral();

  @override
  bool operator ==(Object other) => other is SqlNullLiteral;

  @override
  int get hashCode => 0;
}

final class SqlBoolLiteral extends SqlLiteralModel {
  const SqlBoolLiteral(this.value);

  final bool value;

  @override
  bool operator ==(Object other) =>
      other is SqlBoolLiteral && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class SqlIntLiteral extends SqlLiteralModel {
  const SqlIntLiteral(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      other is SqlIntLiteral && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class SqlDoubleLiteral extends SqlLiteralModel {
  const SqlDoubleLiteral(this.value);

  final double value;

  @override
  bool operator ==(Object other) =>
      other is SqlDoubleLiteral && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class SqlStringLiteral extends SqlLiteralModel {
  const SqlStringLiteral(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is SqlStringLiteral && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
sealed class SqlOperandModel {
  const SqlOperandModel();
}

final class SqlColumnOperand extends SqlOperandModel {
  const SqlColumnOperand(this.column);

  final SqlColumnRefModel column;

  @override
  bool operator ==(Object other) =>
      other is SqlColumnOperand && column == other.column;

  @override
  int get hashCode => column.hashCode;
}

final class SqlLiteralOperand extends SqlOperandModel {
  const SqlLiteralOperand(this.literal);

  final SqlLiteralModel literal;

  @override
  bool operator ==(Object other) =>
      other is SqlLiteralOperand && literal == other.literal;

  @override
  int get hashCode => literal.hashCode;
}

final class SqlAggregateOperand extends SqlOperandModel {
  const SqlAggregateOperand(this.aggregate);

  final SqlAggregateExprModel aggregate;

  @override
  bool operator ==(Object other) =>
      other is SqlAggregateOperand && aggregate == other.aggregate;

  @override
  int get hashCode => aggregate.hashCode;
}

@immutable
sealed class SqlConditionNode {
  const SqlConditionNode();
}

final class SqlComparisonModel extends SqlConditionNode {
  const SqlComparisonModel({
    required this.left,
    required this.op,
    this.operands = const [],
    this.negated = false,
  });

  final SqlOperandModel left;
  final SqlOperatorKind op;
  final List<SqlOperandModel> operands;
  final bool negated;

  SqlComparisonModel copyWith({
    SqlOperandModel? left,
    SqlOperatorKind? op,
    List<SqlOperandModel>? operands,
    bool? negated,
  }) => SqlComparisonModel(
    left: left ?? this.left,
    op: op ?? this.op,
    operands: operands ?? this.operands,
    negated: negated ?? this.negated,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlComparisonModel &&
          left == other.left &&
          op == other.op &&
          negated == other.negated &&
          listEquals(operands, other.operands);

  @override
  int get hashCode => Object.hash(left, op, negated, Object.hashAll(operands));
}

final class SqlConditionGroupModel extends SqlConditionNode {
  const SqlConditionGroupModel({
    this.op = SqlBoolOpKind.and,
    required this.children,
    this.negated = false,
  });

  final SqlBoolOpKind op;
  final List<SqlConditionNode> children;
  final bool negated;

  SqlConditionGroupModel copyWith({
    SqlBoolOpKind? op,
    List<SqlConditionNode>? children,
    bool? negated,
  }) => SqlConditionGroupModel(
    op: op ?? this.op,
    children: children ?? this.children,
    negated: negated ?? this.negated,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlConditionGroupModel &&
          op == other.op &&
          negated == other.negated &&
          listEquals(children, other.children);

  @override
  int get hashCode => Object.hash(op, negated, Object.hashAll(children));
}

@immutable
class SqlJoinModel {
  const SqlJoinModel({
    this.kind = SqlJoinKindModel.inner,
    required this.table,
    required this.on,
  });

  final SqlJoinKindModel kind;
  final SqlTableRefModel table;
  final SqlConditionNode on;

  SqlJoinModel copyWith({
    SqlJoinKindModel? kind,
    SqlTableRefModel? table,
    SqlConditionNode? on,
  }) => SqlJoinModel(
    kind: kind ?? this.kind,
    table: table ?? this.table,
    on: on ?? this.on,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlJoinModel &&
          kind == other.kind &&
          table == other.table &&
          on == other.on;

  @override
  int get hashCode => Object.hash(kind, table, on);
}

@immutable
class SqlOrderTermModel {
  const SqlOrderTermModel({
    required this.expression,
    this.descending = false,
    this.nulls = SqlNullsPlacement.unspecified,
  });

  final SqlOperandModel expression;
  final bool descending;
  final SqlNullsPlacement nulls;

  SqlOrderTermModel copyWith({
    SqlOperandModel? expression,
    bool? descending,
    SqlNullsPlacement? nulls,
  }) => SqlOrderTermModel(
    expression: expression ?? this.expression,
    descending: descending ?? this.descending,
    nulls: nulls ?? this.nulls,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlOrderTermModel &&
          expression == other.expression &&
          descending == other.descending &&
          nulls == other.nulls;

  @override
  int get hashCode => Object.hash(expression, descending, nulls);
}

@immutable
class SqlQueryDraft {
  const SqlQueryDraft({
    this.from,
    this.joins = const [],
    this.select = const [],
    this.distinct = false,
    this.where,
    this.groupBy = const [],
    this.having,
    this.orderBy = const [],
    this.limit,
    this.offset,
  });

  final SqlTableRefModel? from;
  final List<SqlJoinModel> joins;
  final List<SqlSelectItemModel> select;
  final bool distinct;
  final SqlConditionNode? where;
  final List<SqlColumnRefModel> groupBy;
  final SqlConditionNode? having;
  final List<SqlOrderTermModel> orderBy;
  final int? limit;
  final int? offset;

  SqlQueryDraft copyWith({
    SqlTableRefModel? from,
    bool clearFrom = false,
    List<SqlJoinModel>? joins,
    List<SqlSelectItemModel>? select,
    bool? distinct,
    SqlConditionNode? where,
    bool clearWhere = false,
    List<SqlColumnRefModel>? groupBy,
    SqlConditionNode? having,
    bool clearHaving = false,
    List<SqlOrderTermModel>? orderBy,
    int? limit,
    bool clearLimit = false,
    int? offset,
    bool clearOffset = false,
  }) => SqlQueryDraft(
    from: clearFrom ? null : (from ?? this.from),
    joins: joins ?? this.joins,
    select: select ?? this.select,
    distinct: distinct ?? this.distinct,
    where: clearWhere ? null : (where ?? this.where),
    groupBy: groupBy ?? this.groupBy,
    having: clearHaving ? null : (having ?? this.having),
    orderBy: orderBy ?? this.orderBy,
    limit: clearLimit ? null : (limit ?? this.limit),
    offset: clearOffset ? null : (offset ?? this.offset),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlQueryDraft &&
          from == other.from &&
          listEquals(joins, other.joins) &&
          listEquals(select, other.select) &&
          distinct == other.distinct &&
          where == other.where &&
          listEquals(groupBy, other.groupBy) &&
          having == other.having &&
          listEquals(orderBy, other.orderBy) &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
    from,
    Object.hashAll(joins),
    Object.hashAll(select),
    distinct,
    where,
    Object.hashAll(groupBy),
    having,
    Object.hashAll(orderBy),
    limit,
    offset,
  );
}

@immutable
class JoinSuggestion {
  const JoinSuggestion({
    required this.constraintName,
    required this.existingAlias,
    required this.existingColumns,
    required this.targetSchema,
    required this.targetTable,
    required this.targetColumns,
  });

  final String constraintName;
  final String existingAlias;
  final List<String> existingColumns;
  final String targetSchema;
  final String targetTable;
  final List<String> targetColumns;

  String get displayLabel {
    final pairs = [
      for (var i = 0; i < existingColumns.length; i++)
        '$existingAlias.${existingColumns[i]} = $targetTable.${targetColumns[i]}',
    ].join(' AND ');
    return '$targetTable ($pairs)';
  }
}

@immutable
class ParseSqlOutcome {
  const ParseSqlOutcome({required this.model, required this.commentsDropped});

  final SqlQueryDraft model;
  final bool commentsDropped;
}

/// Converts a zero-based UTF-8 byte offset from core into a Dart UTF-16 offset.
int utf8ByteOffsetToUtf16(String text, int byteOffset) {
  if (byteOffset <= 0) return 0;
  var bytes = 0;
  var units = 0;
  for (final rune in text.runes) {
    final utf8Len = utf8.encode(String.fromCharCode(rune)).length;
    if (bytes + utf8Len > byteOffset) break;
    bytes += utf8Len;
    units += rune > 0xFFFF ? 2 : 1;
  }
  return units;
}
