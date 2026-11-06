// This is a generated file - do not edit.
//
// Generated from queravue/v1/table.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'query.pb.dart' as $1;
import 'schema.pb.dart' as $2;
import 'table.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'table.pbenum.dart';

/// FilterCondition represents a single leaf predicate on a column.
class FilterCondition extends $pb.GeneratedMessage {
  factory FilterCondition({
    $core.String? column,
    FilterOp? op,
    $core.Iterable<$1.Value>? values,
  }) {
    final result = create();
    if (column != null) result.column = column;
    if (op != null) result.op = op;
    if (values != null) result.values.addAll(values);
    return result;
  }

  FilterCondition._();

  factory FilterCondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilterCondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilterCondition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aE<FilterOp>(2, _omitFieldNames ? '' : 'op', enumValues: FilterOp.values)
    ..pPM<$1.Value>(3, _omitFieldNames ? '' : 'values',
        subBuilder: $1.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterCondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterCondition copyWith(void Function(FilterCondition) updates) =>
      super.copyWith((message) => updates(message as FilterCondition))
          as FilterCondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilterCondition create() => FilterCondition._();
  @$core.override
  FilterCondition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilterCondition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilterCondition>(create);
  static FilterCondition? _defaultInstance;

  /// Name of the column.
  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);

  /// Comparison operator.
  @$pb.TagNumber(2)
  FilterOp get op => $_getN(1);
  @$pb.TagNumber(2)
  set op(FilterOp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOp() => $_has(1);
  @$pb.TagNumber(2)
  void clearOp() => $_clearField(2);

  /// Operand values (none for IS NULL/IS NOT NULL; 1 for comparisons/LIKE; 2 for BETWEEN; 1+ for IN).
  @$pb.TagNumber(3)
  $pb.PbList<$1.Value> get values => $_getList(2);
}

/// FilterGroup is a composite node containing conditions and nested groups joined by a logical operator.
class FilterGroup extends $pb.GeneratedMessage {
  factory FilterGroup({
    LogicalOp? op,
    $core.Iterable<FilterCondition>? conditions,
    $core.Iterable<FilterGroup>? groups,
  }) {
    final result = create();
    if (op != null) result.op = op;
    if (conditions != null) result.conditions.addAll(conditions);
    if (groups != null) result.groups.addAll(groups);
    return result;
  }

  FilterGroup._();

  factory FilterGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilterGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilterGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<LogicalOp>(1, _omitFieldNames ? '' : 'op',
        enumValues: LogicalOp.values)
    ..pPM<FilterCondition>(2, _omitFieldNames ? '' : 'conditions',
        subBuilder: FilterCondition.create)
    ..pPM<FilterGroup>(3, _omitFieldNames ? '' : 'groups',
        subBuilder: FilterGroup.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterGroup copyWith(void Function(FilterGroup) updates) =>
      super.copyWith((message) => updates(message as FilterGroup))
          as FilterGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilterGroup create() => FilterGroup._();
  @$core.override
  FilterGroup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilterGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilterGroup>(create);
  static FilterGroup? _defaultInstance;

  /// Logical operator joining children (AND or OR).
  @$pb.TagNumber(1)
  LogicalOp get op => $_getN(0);
  @$pb.TagNumber(1)
  set op(LogicalOp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOp() => $_has(0);
  @$pb.TagNumber(1)
  void clearOp() => $_clearField(1);

  /// Leaf conditions in this group.
  @$pb.TagNumber(2)
  $pb.PbList<FilterCondition> get conditions => $_getList(1);

  /// Nested filter groups.
  @$pb.TagNumber(3)
  $pb.PbList<FilterGroup> get groups => $_getList(2);
}

/// TableFilter contains structured filter conditions and an optional raw WHERE escape hatch.
class TableFilter extends $pb.GeneratedMessage {
  factory TableFilter({
    FilterGroup? root,
    $core.String? rawWhere,
  }) {
    final result = create();
    if (root != null) result.root = root;
    if (rawWhere != null) result.rawWhere = rawWhere;
    return result;
  }

  TableFilter._();

  factory TableFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<FilterGroup>(1, _omitFieldNames ? '' : 'root',
        subBuilder: FilterGroup.create)
    ..aOS(2, _omitFieldNames ? '' : 'rawWhere')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableFilter copyWith(void Function(TableFilter) updates) =>
      super.copyWith((message) => updates(message as TableFilter))
          as TableFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableFilter create() => TableFilter._();
  @$core.override
  TableFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableFilter>(create);
  static TableFilter? _defaultInstance;

  /// Root filter group of conditions.
  @$pb.TagNumber(1)
  FilterGroup get root => $_getN(0);
  @$pb.TagNumber(1)
  set root(FilterGroup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRoot() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoot() => $_clearField(1);
  @$pb.TagNumber(1)
  FilterGroup ensureRoot() => $_ensure(0);

  /// Optional raw SQL WHERE clause snippet, shown with a safety warning in the UI.
  @$pb.TagNumber(2)
  $core.String get rawWhere => $_getSZ(1);
  @$pb.TagNumber(2)
  set rawWhere($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawWhere() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawWhere() => $_clearField(2);
}

/// SortClause specifies ordering on a single column.
class SortClause extends $pb.GeneratedMessage {
  factory SortClause({
    $core.String? column,
    SortDirection? direction,
    NullsOrder? nulls,
  }) {
    final result = create();
    if (column != null) result.column = column;
    if (direction != null) result.direction = direction;
    if (nulls != null) result.nulls = nulls;
    return result;
  }

  SortClause._();

  factory SortClause.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SortClause.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SortClause',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aE<SortDirection>(2, _omitFieldNames ? '' : 'direction',
        enumValues: SortDirection.values)
    ..aE<NullsOrder>(3, _omitFieldNames ? '' : 'nulls',
        enumValues: NullsOrder.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SortClause clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SortClause copyWith(void Function(SortClause) updates) =>
      super.copyWith((message) => updates(message as SortClause)) as SortClause;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SortClause create() => SortClause._();
  @$core.override
  SortClause createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SortClause getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SortClause>(create);
  static SortClause? _defaultInstance;

  /// Name of the column to sort on.
  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);

  /// Sort direction (ASC or DESC).
  @$pb.TagNumber(2)
  SortDirection get direction => $_getN(1);
  @$pb.TagNumber(2)
  set direction(SortDirection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDirection() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirection() => $_clearField(2);

  /// Placement of NULL values.
  @$pb.TagNumber(3)
  NullsOrder get nulls => $_getN(2);
  @$pb.TagNumber(3)
  set nulls(NullsOrder value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNulls() => $_has(2);
  @$pb.TagNumber(3)
  void clearNulls() => $_clearField(3);
}

/// OpenTableRequest configures table browsing.
class OpenTableRequest extends $pb.GeneratedMessage {
  factory OpenTableRequest({
    $core.String? sessionId,
    $2.TableRef? tableRef,
    TableFilter? filter,
    $core.Iterable<SortClause>? sort,
    $fixnum.Int64? pageSize,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (filter != null) result.filter = filter;
    if (sort != null) result.sort.addAll(sort);
    if (pageSize != null) result.pageSize = pageSize;
    return result;
  }

  OpenTableRequest._();

  factory OpenTableRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenTableRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenTableRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$2.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $2.TableRef.create)
    ..aOM<TableFilter>(3, _omitFieldNames ? '' : 'filter',
        subBuilder: TableFilter.create)
    ..pPM<SortClause>(4, _omitFieldNames ? '' : 'sort',
        subBuilder: SortClause.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenTableRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenTableRequest copyWith(void Function(OpenTableRequest) updates) =>
      super.copyWith((message) => updates(message as OpenTableRequest))
          as OpenTableRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenTableRequest create() => OpenTableRequest._();
  @$core.override
  OpenTableRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenTableRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenTableRequest>(create);
  static OpenTableRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table reference to browse.
  @$pb.TagNumber(2)
  $2.TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef($2.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.TableRef ensureTableRef() => $_ensure(1);

  /// Structured filter and optional raw WHERE clause.
  @$pb.TagNumber(3)
  TableFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(TableFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);
  @$pb.TagNumber(3)
  TableFilter ensureFilter() => $_ensure(2);

  /// Multi-column sort clauses in priority order.
  @$pb.TagNumber(4)
  $pb.PbList<SortClause> get sort => $_getList(3);

  /// Page size limit (e.g. 500); 0 means unlimited rows.
  @$pb.TagNumber(5)
  $fixnum.Int64 get pageSize => $_getI64(4);
  @$pb.TagNumber(5)
  set pageSize($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPageSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearPageSize() => $_clearField(5);
}

/// OpenTableResponse carries events from opening and spooling a table query.
class OpenTableResponse extends $pb.GeneratedMessage {
  factory OpenTableResponse({
    $core.String? sql,
    $1.ExecuteResponse? event,
  }) {
    final result = create();
    if (sql != null) result.sql = sql;
    if (event != null) result.event = event;
    return result;
  }

  OpenTableResponse._();

  factory OpenTableResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenTableResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenTableResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sql')
    ..aOM<$1.ExecuteResponse>(2, _omitFieldNames ? '' : 'event',
        subBuilder: $1.ExecuteResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenTableResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenTableResponse copyWith(void Function(OpenTableResponse) updates) =>
      super.copyWith((message) => updates(message as OpenTableResponse))
          as OpenTableResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenTableResponse create() => OpenTableResponse._();
  @$core.override
  OpenTableResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenTableResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenTableResponse>(create);
  static OpenTableResponse? _defaultInstance;

  /// Dialect-specific generated SQL query, provided on the initial response event.
  @$pb.TagNumber(1)
  $core.String get sql => $_getSZ(0);
  @$pb.TagNumber(1)
  set sql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearSql() => $_clearField(1);

  /// Spooling and execution events reusing the QueryService event channel.
  @$pb.TagNumber(2)
  $1.ExecuteResponse get event => $_getN(1);
  @$pb.TagNumber(2)
  set event($1.ExecuteResponse value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEvent() => $_has(1);
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ExecuteResponse ensureEvent() => $_ensure(1);
}

/// ColumnValue pairs a column name with its cell value.
class ColumnValue extends $pb.GeneratedMessage {
  factory ColumnValue({
    $core.String? column,
    $1.Value? value,
  }) {
    final result = create();
    if (column != null) result.column = column;
    if (value != null) result.value = value;
    return result;
  }

  ColumnValue._();

  factory ColumnValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColumnValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColumnValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aOM<$1.Value>(2, _omitFieldNames ? '' : 'value',
        subBuilder: $1.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnValue copyWith(void Function(ColumnValue) updates) =>
      super.copyWith((message) => updates(message as ColumnValue))
          as ColumnValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColumnValue create() => ColumnValue._();
  @$core.override
  ColumnValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColumnValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColumnValue>(create);
  static ColumnValue? _defaultInstance;

  /// Column name.
  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);

  /// Cell value.
  @$pb.TagNumber(2)
  $1.Value get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($1.Value value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Value ensureValue() => $_ensure(1);
}

/// RowChange represents an insert, update, or delete on a table.
class RowChange extends $pb.GeneratedMessage {
  factory RowChange({
    RowChangeType? type,
    $core.Iterable<ColumnValue>? keys,
    $core.Iterable<ColumnValue>? values,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (keys != null) result.keys.addAll(keys);
    if (values != null) result.values.addAll(values);
    return result;
  }

  RowChange._();

  factory RowChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RowChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RowChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<RowChangeType>(1, _omitFieldNames ? '' : 'type',
        enumValues: RowChangeType.values)
    ..pPM<ColumnValue>(2, _omitFieldNames ? '' : 'keys',
        subBuilder: ColumnValue.create)
    ..pPM<ColumnValue>(3, _omitFieldNames ? '' : 'values',
        subBuilder: ColumnValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowChange copyWith(void Function(RowChange) updates) =>
      super.copyWith((message) => updates(message as RowChange)) as RowChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RowChange create() => RowChange._();
  @$core.override
  RowChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RowChange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowChange>(create);
  static RowChange? _defaultInstance;

  /// Type of row mutation.
  @$pb.TagNumber(1)
  RowChangeType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(RowChangeType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// Primary key column values identifying the target row (for UPDATE and DELETE).
  @$pb.TagNumber(2)
  $pb.PbList<ColumnValue> get keys => $_getList(1);

  /// New column values to apply (for INSERT and UPDATE).
  @$pb.TagNumber(3)
  $pb.PbList<ColumnValue> get values => $_getList(2);
}

/// ApplyChangesRequest applies pending mutations to a table.
class ApplyChangesRequest extends $pb.GeneratedMessage {
  factory ApplyChangesRequest({
    $core.String? sessionId,
    $2.TableRef? tableRef,
    $core.Iterable<RowChange>? changes,
    $core.bool? dryRun,
    $core.bool? confirmProduction,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (changes != null) result.changes.addAll(changes);
    if (dryRun != null) result.dryRun = dryRun;
    if (confirmProduction != null) result.confirmProduction = confirmProduction;
    return result;
  }

  ApplyChangesRequest._();

  factory ApplyChangesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyChangesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyChangesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$2.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $2.TableRef.create)
    ..pPM<RowChange>(3, _omitFieldNames ? '' : 'changes',
        subBuilder: RowChange.create)
    ..aOB(4, _omitFieldNames ? '' : 'dryRun')
    ..aOB(5, _omitFieldNames ? '' : 'confirmProduction')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyChangesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyChangesRequest copyWith(void Function(ApplyChangesRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyChangesRequest))
          as ApplyChangesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyChangesRequest create() => ApplyChangesRequest._();
  @$core.override
  ApplyChangesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyChangesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyChangesRequest>(create);
  static ApplyChangesRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Target table reference.
  @$pb.TagNumber(2)
  $2.TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef($2.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.TableRef ensureTableRef() => $_ensure(1);

  /// List of mutations to apply in one transaction.
  @$pb.TagNumber(3)
  $pb.PbList<RowChange> get changes => $_getList(2);

  /// If true, returns generated SQL preview without executing statements.
  @$pb.TagNumber(4)
  $core.bool get dryRun => $_getBF(3);
  @$pb.TagNumber(4)
  set dryRun($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDryRun() => $_has(3);
  @$pb.TagNumber(4)
  void clearDryRun() => $_clearField(4);

  /// Explicit confirmation flag required when modifying production connections.
  @$pb.TagNumber(5)
  $core.bool get confirmProduction => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmProduction($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmProduction() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmProduction() => $_clearField(5);
}

/// ApplyChangesResponse reports the outcome of applying table mutations.
class ApplyChangesResponse extends $pb.GeneratedMessage {
  factory ApplyChangesResponse({
    $core.String? generatedSql,
    $fixnum.Int64? rowsAffected,
    $core.bool? dryRun,
    $core.bool? success,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (generatedSql != null) result.generatedSql = generatedSql;
    if (rowsAffected != null) result.rowsAffected = rowsAffected;
    if (dryRun != null) result.dryRun = dryRun;
    if (success != null) result.success = success;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  ApplyChangesResponse._();

  factory ApplyChangesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyChangesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyChangesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'generatedSql')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rowsAffected', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'dryRun')
    ..aOB(4, _omitFieldNames ? '' : 'success')
    ..aOS(5, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyChangesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyChangesResponse copyWith(void Function(ApplyChangesResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyChangesResponse))
          as ApplyChangesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyChangesResponse create() => ApplyChangesResponse._();
  @$core.override
  ApplyChangesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyChangesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyChangesResponse>(create);
  static ApplyChangesResponse? _defaultInstance;

  /// Generated SQL statements (e.g. BEGIN; INSERT...; UPDATE...; COMMIT;).
  @$pb.TagNumber(1)
  $core.String get generatedSql => $_getSZ(0);
  @$pb.TagNumber(1)
  set generatedSql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGeneratedSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearGeneratedSql() => $_clearField(1);

  /// Total rows affected across all executed statements.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rowsAffected => $_getI64(1);
  @$pb.TagNumber(2)
  set rowsAffected($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowsAffected() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowsAffected() => $_clearField(2);

  /// True if the request was a preview dry run.
  @$pb.TagNumber(3)
  $core.bool get dryRun => $_getBF(2);
  @$pb.TagNumber(3)
  set dryRun($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDryRun() => $_has(2);
  @$pb.TagNumber(3)
  void clearDryRun() => $_clearField(3);

  /// True if execution succeeded (or dry run completed without error).
  @$pb.TagNumber(4)
  $core.bool get success => $_getBF(3);
  @$pb.TagNumber(4)
  set success($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSuccess() => $_has(3);
  @$pb.TagNumber(4)
  void clearSuccess() => $_clearField(4);

  /// Detailed error message if the changes failed or were rejected.
  @$pb.TagNumber(5)
  $core.String get errorMessage => $_getSZ(4);
  @$pb.TagNumber(5)
  set errorMessage($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearErrorMessage() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
