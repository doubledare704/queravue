import 'package:flutter/foundation.dart';

/// Supported filter operators.
enum FilterOp {
  equals('='),
  notEquals('!='),
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  like('LIKE'),
  ilike('ILIKE'),
  inList('IN'),
  isNull('IS NULL'),
  isNotNull('IS NOT NULL'),
  between('BETWEEN');

  const FilterOp(this.label);
  final String label;

  bool get requiresNoValue =>
      this == FilterOp.isNull || this == FilterOp.isNotNull;
  bool get requiresTwoValues => this == FilterOp.between;
  bool get requiresList => this == FilterOp.inList;
}

/// Logical connective within a filter group.
enum LogicalOp { and, or }

/// Single column predicate.
@immutable
class FilterCondition {
  const FilterCondition({
    required this.column,
    this.op = FilterOp.equals,
    this.values = const [],
  });

  final String column;
  final FilterOp op;
  final List<String> values;

  FilterCondition copyWith({
    String? column,
    FilterOp? op,
    List<String>? values,
  }) => FilterCondition(
    column: column ?? this.column,
    op: op ?? this.op,
    values: values ?? this.values,
  );
}

/// Composite tree group of filter conditions.
@immutable
class FilterGroup {
  const FilterGroup({
    this.op = LogicalOp.and,
    this.conditions = const [],
    this.groups = const [],
  });

  final LogicalOp op;
  final List<FilterCondition> conditions;
  final List<FilterGroup> groups;

  bool get isEmpty => conditions.isEmpty && groups.isEmpty;

  FilterGroup copyWith({
    LogicalOp? op,
    List<FilterCondition>? conditions,
    List<FilterGroup>? groups,
  }) => FilterGroup(
    op: op ?? this.op,
    conditions: conditions ?? this.conditions,
    groups: groups ?? this.groups,
  );
}

/// Full filter specification for table browsing.
@immutable
class TableFilter {
  const TableFilter({this.root = const FilterGroup(), this.rawWhere = ''});

  final FilterGroup root;
  final String rawWhere;

  bool get isEmpty => root.isEmpty && rawWhere.trim().isEmpty;

  /// Generates a human-readable preview of the WHERE clause.
  String toWherePreview() {
    if (rawWhere.trim().isNotEmpty) {
      return rawWhere.trim();
    }
    return formatGroupPreview(root);
  }

  TableFilter copyWith({FilterGroup? root, String? rawWhere}) =>
      TableFilter(root: root ?? this.root, rawWhere: rawWhere ?? this.rawWhere);
}

String formatConditionPreview(FilterCondition c) {
  if (c.column.isEmpty) return '';
  switch (c.op) {
    case FilterOp.isNull:
      return '${c.column} IS NULL';
    case FilterOp.isNotNull:
      return '${c.column} IS NOT NULL';
    case FilterOp.between:
      final v1 = c.values.isNotEmpty ? c.values[0] : '?';
      final v2 = c.values.length > 1 ? c.values[1] : '?';
      return '${c.column} BETWEEN \'$v1\' AND \'$v2\'';
    case FilterOp.inList:
      return '${c.column} IN (${c.values.map((v) => '\'$v\'').join(', ')})';
    default:
      final val = c.values.isNotEmpty ? c.values[0] : '';
      return '${c.column} ${c.op.label} \'$val\'';
  }
}

String formatGroupPreview(FilterGroup g) {
  if (g.isEmpty) return '';
  final parts = <String>[];
  for (final c in g.conditions) {
    final p = formatConditionPreview(c);
    if (p.isNotEmpty) parts.add(p);
  }
  for (final sub in g.groups) {
    final p = formatGroupPreview(sub);
    if (p.isNotEmpty) parts.add('($p)');
  }
  final joiner = g.op == LogicalOp.and ? ' AND ' : ' OR ';
  return parts.join(joiner);
}

/// Sort direction for column ordering.
enum SortDirection { asc, desc }

/// NULL placement in sorted output.
enum NullsOrder { unspecified, first, last }

/// Single column sort specification.
@immutable
class SortClause {
  const SortClause({
    required this.column,
    this.direction = SortDirection.asc,
    this.nulls = NullsOrder.unspecified,
  });

  final String column;
  final SortDirection direction;
  final NullsOrder nulls;

  SortClause copyWith({
    String? column,
    SortDirection? direction,
    NullsOrder? nulls,
  }) => SortClause(
    column: column ?? this.column,
    direction: direction ?? this.direction,
    nulls: nulls ?? this.nulls,
  );

  SortClause toggle() {
    if (direction == SortDirection.asc) {
      return SortClause(
        column: column,
        direction: SortDirection.desc,
        nulls: nulls,
      );
    }
    return SortClause(
      column: column,
      direction: SortDirection.asc,
      nulls: nulls,
    );
  }
}

/// Type of pending row change.
enum RowChangeType { insert, update, delete }

/// Mutation applied to a row.
@immutable
class RowChange {
  const RowChange({
    required this.type,
    this.keys = const {},
    this.values = const {},
  });

  final RowChangeType type;

  /// Primary key column values identifying the row (UPDATE and DELETE).
  final Map<String, Object?> keys;

  /// New column values to apply (INSERT and UPDATE).
  final Map<String, Object?> values;
}

/// Outcome of applying changes.
@immutable
class ApplyChangesResult {
  const ApplyChangesResult({
    required this.generatedSql,
    this.rowsAffected = 0,
    required this.dryRun,
    required this.success,
    this.errorMessage,
  });

  final String generatedSql;
  final int rowsAffected;
  final bool dryRun;
  final bool success;
  final String? errorMessage;
}
