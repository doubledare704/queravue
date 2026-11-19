// This is a generated file - do not edit.
//
// Generated from queravue/v1/querybuilder.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'querybuilder.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'querybuilder.pbenum.dart';

/// QueryBuilderError describes why a builder call produced nothing.
class QueryBuilderError extends $pb.GeneratedMessage {
  factory QueryBuilderError({
    QueryBuilderErrorKind? kind,
    $core.String? message,
    $core.int? offset,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (offset != null) result.offset = offset;
    return result;
  }

  QueryBuilderError._();

  factory QueryBuilderError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QueryBuilderError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryBuilderError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<QueryBuilderErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: QueryBuilderErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aI(3, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryBuilderError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryBuilderError copyWith(void Function(QueryBuilderError) updates) =>
      super.copyWith((message) => updates(message as QueryBuilderError))
          as QueryBuilderError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryBuilderError create() => QueryBuilderError._();
  @$core.override
  QueryBuilderError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QueryBuilderError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryBuilderError>(create);
  static QueryBuilderError? _defaultInstance;

  /// Failure category.
  @$pb.TagNumber(1)
  QueryBuilderErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(QueryBuilderErrorKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// Human-readable explanation, safe to show to the user.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// Zero-based UTF-8 byte offset into the input text for PARSE and
  /// UNSUPPORTED_CONSTRUCT. Unset for other kinds.
  @$pb.TagNumber(3)
  $core.int get offset => $_getIZ(2);
  @$pb.TagNumber(3)
  set offset($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

/// GenerateSqlRequest is the input of GenerateSql.
class GenerateSqlRequest extends $pb.GeneratedMessage {
  factory GenerateSqlRequest({
    $core.String? sessionId,
    SqlQueryModel? model,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (model != null) result.model = model;
    return result;
  }

  GenerateSqlRequest._();

  factory GenerateSqlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateSqlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateSqlRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<SqlQueryModel>(2, _omitFieldNames ? '' : 'model',
        subBuilder: SqlQueryModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateSqlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateSqlRequest copyWith(void Function(GenerateSqlRequest) updates) =>
      super.copyWith((message) => updates(message as GenerateSqlRequest))
          as GenerateSqlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateSqlRequest create() => GenerateSqlRequest._();
  @$core.override
  GenerateSqlRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateSqlRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateSqlRequest>(create);
  static GenerateSqlRequest? _defaultInstance;

  /// Session id. Its engine decides quoting, qualification and pagination.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// The model to render.
  @$pb.TagNumber(2)
  SqlQueryModel get model => $_getN(1);
  @$pb.TagNumber(2)
  set model(SqlQueryModel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlQueryModel ensureModel() => $_ensure(1);
}

/// GenerateSqlResponse holds the statement or the failure.
class GenerateSqlResponse extends $pb.GeneratedMessage {
  factory GenerateSqlResponse({
    $core.String? sql,
    QueryBuilderError? error,
  }) {
    final result = create();
    if (sql != null) result.sql = sql;
    if (error != null) result.error = error;
    return result;
  }

  GenerateSqlResponse._();

  factory GenerateSqlResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateSqlResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateSqlResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sql')
    ..aOM<QueryBuilderError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: QueryBuilderError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateSqlResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateSqlResponse copyWith(void Function(GenerateSqlResponse) updates) =>
      super.copyWith((message) => updates(message as GenerateSqlResponse))
          as GenerateSqlResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateSqlResponse create() => GenerateSqlResponse._();
  @$core.override
  GenerateSqlResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateSqlResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateSqlResponse>(create);
  static GenerateSqlResponse? _defaultInstance;

  /// One SELECT statement without a terminator. Literals are inlined, so the
  /// text can be shown and executed as is.
  @$pb.TagNumber(1)
  $core.String get sql => $_getSZ(0);
  @$pb.TagNumber(1)
  set sql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearSql() => $_clearField(1);

  /// Set when generation failed.
  @$pb.TagNumber(2)
  QueryBuilderError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(QueryBuilderError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  QueryBuilderError ensureError() => $_ensure(1);
}

/// ParseSqlRequest is the input of ParseSql.
class ParseSqlRequest extends $pb.GeneratedMessage {
  factory ParseSqlRequest({
    $core.String? sessionId,
    $core.String? sql,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (sql != null) result.sql = sql;
    return result;
  }

  ParseSqlRequest._();

  factory ParseSqlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseSqlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseSqlRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'sql')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseSqlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseSqlRequest copyWith(void Function(ParseSqlRequest) updates) =>
      super.copyWith((message) => updates(message as ParseSqlRequest))
          as ParseSqlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseSqlRequest create() => ParseSqlRequest._();
  @$core.override
  ParseSqlRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseSqlRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseSqlRequest>(create);
  static ParseSqlRequest? _defaultInstance;

  /// Session id. Its engine decides the lexer and quoting rules.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// One SELECT statement.
  @$pb.TagNumber(2)
  $core.String get sql => $_getSZ(1);
  @$pb.TagNumber(2)
  set sql($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSql() => $_has(1);
  @$pb.TagNumber(2)
  void clearSql() => $_clearField(2);
}

/// ParseSqlResponse holds the model or the failure.
class ParseSqlResponse extends $pb.GeneratedMessage {
  factory ParseSqlResponse({
    SqlQueryModel? model,
    $core.bool? commentsDropped,
    QueryBuilderError? error,
  }) {
    final result = create();
    if (model != null) result.model = model;
    if (commentsDropped != null) result.commentsDropped = commentsDropped;
    if (error != null) result.error = error;
    return result;
  }

  ParseSqlResponse._();

  factory ParseSqlResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseSqlResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseSqlResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<SqlQueryModel>(1, _omitFieldNames ? '' : 'model',
        subBuilder: SqlQueryModel.create)
    ..aOB(2, _omitFieldNames ? '' : 'commentsDropped')
    ..aOM<QueryBuilderError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: QueryBuilderError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseSqlResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseSqlResponse copyWith(void Function(ParseSqlResponse) updates) =>
      super.copyWith((message) => updates(message as ParseSqlResponse))
          as ParseSqlResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseSqlResponse create() => ParseSqlResponse._();
  @$core.override
  ParseSqlResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseSqlResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseSqlResponse>(create);
  static ParseSqlResponse? _defaultInstance;

  /// The parsed model.
  @$pb.TagNumber(1)
  SqlQueryModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(SqlQueryModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlQueryModel ensureModel() => $_ensure(0);

  /// True if the text had comments that the model cannot hold.
  @$pb.TagNumber(2)
  $core.bool get commentsDropped => $_getBF(1);
  @$pb.TagNumber(2)
  set commentsDropped($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommentsDropped() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommentsDropped() => $_clearField(2);

  /// Set when parsing failed.
  @$pb.TagNumber(3)
  QueryBuilderError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(QueryBuilderError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  QueryBuilderError ensureError() => $_ensure(2);
}

/// SqlQueryModel is one SELECT statement in visual form.
class SqlQueryModel extends $pb.GeneratedMessage {
  factory SqlQueryModel({
    SqlTableRef? from,
    $core.Iterable<SqlJoin>? joins,
    $core.Iterable<SqlSelectItem>? select,
    $core.bool? distinct,
    SqlCondition? where,
    $core.Iterable<SqlColumnRef>? groupBy,
    SqlCondition? having,
    $core.Iterable<SqlOrderTerm>? orderBy,
    $fixnum.Int64? limit,
    $fixnum.Int64? offset,
  }) {
    final result = create();
    if (from != null) result.from = from;
    if (joins != null) result.joins.addAll(joins);
    if (select != null) result.select.addAll(select);
    if (distinct != null) result.distinct = distinct;
    if (where != null) result.where = where;
    if (groupBy != null) result.groupBy.addAll(groupBy);
    if (having != null) result.having = having;
    if (orderBy != null) result.orderBy.addAll(orderBy);
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  SqlQueryModel._();

  factory SqlQueryModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlQueryModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlQueryModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<SqlTableRef>(1, _omitFieldNames ? '' : 'from',
        subBuilder: SqlTableRef.create)
    ..pPM<SqlJoin>(2, _omitFieldNames ? '' : 'joins',
        subBuilder: SqlJoin.create)
    ..pPM<SqlSelectItem>(3, _omitFieldNames ? '' : 'select',
        subBuilder: SqlSelectItem.create)
    ..aOB(4, _omitFieldNames ? '' : 'distinct')
    ..aOM<SqlCondition>(5, _omitFieldNames ? '' : 'where',
        subBuilder: SqlCondition.create)
    ..pPM<SqlColumnRef>(6, _omitFieldNames ? '' : 'groupBy',
        subBuilder: SqlColumnRef.create)
    ..aOM<SqlCondition>(7, _omitFieldNames ? '' : 'having',
        subBuilder: SqlCondition.create)
    ..pPM<SqlOrderTerm>(8, _omitFieldNames ? '' : 'orderBy',
        subBuilder: SqlOrderTerm.create)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(10, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlQueryModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlQueryModel copyWith(void Function(SqlQueryModel) updates) =>
      super.copyWith((message) => updates(message as SqlQueryModel))
          as SqlQueryModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlQueryModel create() => SqlQueryModel._();
  @$core.override
  SqlQueryModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlQueryModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlQueryModel>(create);
  static SqlQueryModel? _defaultInstance;

  /// The first table. Required.
  @$pb.TagNumber(1)
  SqlTableRef get from => $_getN(0);
  @$pb.TagNumber(1)
  set from(SqlTableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlTableRef ensureFrom() => $_ensure(0);

  /// Joins in order of appearance.
  @$pb.TagNumber(2)
  $pb.PbList<SqlJoin> get joins => $_getList(1);

  /// Select list. Empty means all columns of every table.
  @$pb.TagNumber(3)
  $pb.PbList<SqlSelectItem> get select => $_getList(2);

  /// SELECT DISTINCT.
  @$pb.TagNumber(4)
  $core.bool get distinct => $_getBF(3);
  @$pb.TagNumber(4)
  set distinct($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDistinct() => $_has(3);
  @$pb.TagNumber(4)
  void clearDistinct() => $_clearField(4);

  /// WHERE condition. Unset means no filter.
  @$pb.TagNumber(5)
  SqlCondition get where => $_getN(4);
  @$pb.TagNumber(5)
  set where(SqlCondition value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasWhere() => $_has(4);
  @$pb.TagNumber(5)
  void clearWhere() => $_clearField(5);
  @$pb.TagNumber(5)
  SqlCondition ensureWhere() => $_ensure(4);

  /// GROUP BY columns.
  @$pb.TagNumber(6)
  $pb.PbList<SqlColumnRef> get groupBy => $_getList(5);

  /// HAVING condition. Unset means none.
  @$pb.TagNumber(7)
  SqlCondition get having => $_getN(6);
  @$pb.TagNumber(7)
  set having(SqlCondition value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasHaving() => $_has(6);
  @$pb.TagNumber(7)
  void clearHaving() => $_clearField(7);
  @$pb.TagNumber(7)
  SqlCondition ensureHaving() => $_ensure(6);

  /// ORDER BY terms in order.
  @$pb.TagNumber(8)
  $pb.PbList<SqlOrderTerm> get orderBy => $_getList(7);

  /// Row limit. Unset means no limit.
  @$pb.TagNumber(9)
  $fixnum.Int64 get limit => $_getI64(8);
  @$pb.TagNumber(9)
  set limit($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLimit() => $_has(8);
  @$pb.TagNumber(9)
  void clearLimit() => $_clearField(9);

  /// Rows to skip. Unset means none.
  @$pb.TagNumber(10)
  $fixnum.Int64 get offset => $_getI64(9);
  @$pb.TagNumber(10)
  set offset($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOffset() => $_has(9);
  @$pb.TagNumber(10)
  void clearOffset() => $_clearField(10);
}

/// SqlTableRef names a table and the alias used to refer to it.
class SqlTableRef extends $pb.GeneratedMessage {
  factory SqlTableRef({
    $core.String? schema,
    $core.String? table,
    $core.String? alias,
  }) {
    final result = create();
    if (schema != null) result.schema = schema;
    if (table != null) result.table = table;
    if (alias != null) result.alias = alias;
    return result;
  }

  SqlTableRef._();

  factory SqlTableRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlTableRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlTableRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'schema')
    ..aOS(2, _omitFieldNames ? '' : 'table')
    ..aOS(3, _omitFieldNames ? '' : 'alias')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlTableRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlTableRef copyWith(void Function(SqlTableRef) updates) =>
      super.copyWith((message) => updates(message as SqlTableRef))
          as SqlTableRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlTableRef create() => SqlTableRef._();
  @$core.override
  SqlTableRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlTableRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlTableRef>(create);
  static SqlTableRef? _defaultInstance;

  /// Schema, or empty for the default schema.
  @$pb.TagNumber(1)
  $core.String get schema => $_getSZ(0);
  @$pb.TagNumber(1)
  set schema($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSchema() => $_has(0);
  @$pb.TagNumber(1)
  void clearSchema() => $_clearField(1);

  /// Table or view name.
  @$pb.TagNumber(2)
  $core.String get table => $_getSZ(1);
  @$pb.TagNumber(2)
  set table($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearTable() => $_clearField(2);

  /// Alias, or empty to use the table name.
  @$pb.TagNumber(3)
  $core.String get alias => $_getSZ(2);
  @$pb.TagNumber(3)
  set alias($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlias() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlias() => $_clearField(3);
}

/// SqlJoin joins one more table to the query.
class SqlJoin extends $pb.GeneratedMessage {
  factory SqlJoin({
    SqlJoinKind? kind,
    SqlTableRef? table,
    SqlCondition? on,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (table != null) result.table = table;
    if (on != null) result.on = on;
    return result;
  }

  SqlJoin._();

  factory SqlJoin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlJoin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlJoin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<SqlJoinKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: SqlJoinKind.values)
    ..aOM<SqlTableRef>(2, _omitFieldNames ? '' : 'table',
        subBuilder: SqlTableRef.create)
    ..aOM<SqlCondition>(3, _omitFieldNames ? '' : 'on',
        subBuilder: SqlCondition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlJoin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlJoin copyWith(void Function(SqlJoin) updates) =>
      super.copyWith((message) => updates(message as SqlJoin)) as SqlJoin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlJoin create() => SqlJoin._();
  @$core.override
  SqlJoin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlJoin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SqlJoin>(create);
  static SqlJoin? _defaultInstance;

  /// Join type.
  @$pb.TagNumber(1)
  SqlJoinKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(SqlJoinKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// The joined table.
  @$pb.TagNumber(2)
  SqlTableRef get table => $_getN(1);
  @$pb.TagNumber(2)
  set table(SqlTableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearTable() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlTableRef ensureTable() => $_ensure(1);

  /// The ON condition. Required.
  @$pb.TagNumber(3)
  SqlCondition get on => $_getN(2);
  @$pb.TagNumber(3)
  set on(SqlCondition value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOn() => $_has(2);
  @$pb.TagNumber(3)
  void clearOn() => $_clearField(3);
  @$pb.TagNumber(3)
  SqlCondition ensureOn() => $_ensure(2);
}

/// SqlColumnRef names a column of a table in the query.
class SqlColumnRef extends $pb.GeneratedMessage {
  factory SqlColumnRef({
    $core.String? tableAlias,
    $core.String? column,
  }) {
    final result = create();
    if (tableAlias != null) result.tableAlias = tableAlias;
    if (column != null) result.column = column;
    return result;
  }

  SqlColumnRef._();

  factory SqlColumnRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlColumnRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlColumnRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tableAlias')
    ..aOS(2, _omitFieldNames ? '' : 'column')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlColumnRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlColumnRef copyWith(void Function(SqlColumnRef) updates) =>
      super.copyWith((message) => updates(message as SqlColumnRef))
          as SqlColumnRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlColumnRef create() => SqlColumnRef._();
  @$core.override
  SqlColumnRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlColumnRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlColumnRef>(create);
  static SqlColumnRef? _defaultInstance;

  /// Alias of the table, or empty if the query has one table.
  @$pb.TagNumber(1)
  $core.String get tableAlias => $_getSZ(0);
  @$pb.TagNumber(1)
  set tableAlias($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTableAlias() => $_has(0);
  @$pb.TagNumber(1)
  void clearTableAlias() => $_clearField(1);

  /// Column name. Empty together with a table_alias means "alias.*"; empty
  /// without one means "*".
  @$pb.TagNumber(2)
  $core.String get column => $_getSZ(1);
  @$pb.TagNumber(2)
  set column($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColumn() => $_has(1);
  @$pb.TagNumber(2)
  void clearColumn() => $_clearField(2);
}

/// SqlAggregateExpr applies an aggregate to a column.
class SqlAggregateExpr extends $pb.GeneratedMessage {
  factory SqlAggregateExpr({
    SqlAggregate? function,
    SqlColumnRef? column,
    $core.bool? distinct,
  }) {
    final result = create();
    if (function != null) result.function = function;
    if (column != null) result.column = column;
    if (distinct != null) result.distinct = distinct;
    return result;
  }

  SqlAggregateExpr._();

  factory SqlAggregateExpr.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlAggregateExpr.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlAggregateExpr',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<SqlAggregate>(1, _omitFieldNames ? '' : 'function',
        enumValues: SqlAggregate.values)
    ..aOM<SqlColumnRef>(2, _omitFieldNames ? '' : 'column',
        subBuilder: SqlColumnRef.create)
    ..aOB(3, _omitFieldNames ? '' : 'distinct')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlAggregateExpr clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlAggregateExpr copyWith(void Function(SqlAggregateExpr) updates) =>
      super.copyWith((message) => updates(message as SqlAggregateExpr))
          as SqlAggregateExpr;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlAggregateExpr create() => SqlAggregateExpr._();
  @$core.override
  SqlAggregateExpr createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlAggregateExpr getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlAggregateExpr>(create);
  static SqlAggregateExpr? _defaultInstance;

  /// The function. Never UNSPECIFIED here.
  @$pb.TagNumber(1)
  SqlAggregate get function => $_getN(0);
  @$pb.TagNumber(1)
  set function(SqlAggregate value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFunction() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunction() => $_clearField(1);

  /// The argument. An empty column means COUNT(*).
  @$pb.TagNumber(2)
  SqlColumnRef get column => $_getN(1);
  @$pb.TagNumber(2)
  set column(SqlColumnRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasColumn() => $_has(1);
  @$pb.TagNumber(2)
  void clearColumn() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlColumnRef ensureColumn() => $_ensure(1);

  /// COUNT(DISTINCT col) and the like.
  @$pb.TagNumber(3)
  $core.bool get distinct => $_getBF(2);
  @$pb.TagNumber(3)
  set distinct($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDistinct() => $_has(2);
  @$pb.TagNumber(3)
  void clearDistinct() => $_clearField(3);
}

enum SqlSelectItem_Expression { column, aggregate, notSet }

/// SqlSelectItem is one entry of the select list.
class SqlSelectItem extends $pb.GeneratedMessage {
  factory SqlSelectItem({
    SqlColumnRef? column,
    SqlAggregateExpr? aggregate,
    $core.String? alias,
  }) {
    final result = create();
    if (column != null) result.column = column;
    if (aggregate != null) result.aggregate = aggregate;
    if (alias != null) result.alias = alias;
    return result;
  }

  SqlSelectItem._();

  factory SqlSelectItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlSelectItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SqlSelectItem_Expression>
      _SqlSelectItem_ExpressionByTag = {
    1: SqlSelectItem_Expression.column,
    2: SqlSelectItem_Expression.aggregate,
    0: SqlSelectItem_Expression.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlSelectItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SqlColumnRef>(1, _omitFieldNames ? '' : 'column',
        subBuilder: SqlColumnRef.create)
    ..aOM<SqlAggregateExpr>(2, _omitFieldNames ? '' : 'aggregate',
        subBuilder: SqlAggregateExpr.create)
    ..aOS(3, _omitFieldNames ? '' : 'alias')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlSelectItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlSelectItem copyWith(void Function(SqlSelectItem) updates) =>
      super.copyWith((message) => updates(message as SqlSelectItem))
          as SqlSelectItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlSelectItem create() => SqlSelectItem._();
  @$core.override
  SqlSelectItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlSelectItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlSelectItem>(create);
  static SqlSelectItem? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SqlSelectItem_Expression whichExpression() =>
      _SqlSelectItem_ExpressionByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearExpression() => $_clearField($_whichOneof(0));

  /// A column, or "*" forms.
  @$pb.TagNumber(1)
  SqlColumnRef get column => $_getN(0);
  @$pb.TagNumber(1)
  set column(SqlColumnRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlColumnRef ensureColumn() => $_ensure(0);

  /// An aggregate over a column.
  @$pb.TagNumber(2)
  SqlAggregateExpr get aggregate => $_getN(1);
  @$pb.TagNumber(2)
  set aggregate(SqlAggregateExpr value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAggregate() => $_has(1);
  @$pb.TagNumber(2)
  void clearAggregate() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlAggregateExpr ensureAggregate() => $_ensure(1);

  /// Output name, or empty for none.
  @$pb.TagNumber(3)
  $core.String get alias => $_getSZ(2);
  @$pb.TagNumber(3)
  set alias($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlias() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlias() => $_clearField(3);
}

enum SqlLiteral_Value {
  nullValue,
  boolValue,
  intValue,
  doubleValue,
  stringValue,
  notSet
}

/// SqlLiteral is a constant value in a condition.
class SqlLiteral extends $pb.GeneratedMessage {
  factory SqlLiteral({
    $core.bool? nullValue,
    $core.bool? boolValue,
    $fixnum.Int64? intValue,
    $core.double? doubleValue,
    $core.String? stringValue,
  }) {
    final result = create();
    if (nullValue != null) result.nullValue = nullValue;
    if (boolValue != null) result.boolValue = boolValue;
    if (intValue != null) result.intValue = intValue;
    if (doubleValue != null) result.doubleValue = doubleValue;
    if (stringValue != null) result.stringValue = stringValue;
    return result;
  }

  SqlLiteral._();

  factory SqlLiteral.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlLiteral.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SqlLiteral_Value> _SqlLiteral_ValueByTag = {
    1: SqlLiteral_Value.nullValue,
    2: SqlLiteral_Value.boolValue,
    3: SqlLiteral_Value.intValue,
    4: SqlLiteral_Value.doubleValue,
    5: SqlLiteral_Value.stringValue,
    0: SqlLiteral_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlLiteral',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOB(1, _omitFieldNames ? '' : 'nullValue')
    ..aOB(2, _omitFieldNames ? '' : 'boolValue')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'intValue', $pb.PbFieldType.OS6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(4, _omitFieldNames ? '' : 'doubleValue')
    ..aOS(5, _omitFieldNames ? '' : 'stringValue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlLiteral clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlLiteral copyWith(void Function(SqlLiteral) updates) =>
      super.copyWith((message) => updates(message as SqlLiteral)) as SqlLiteral;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlLiteral create() => SqlLiteral._();
  @$core.override
  SqlLiteral createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlLiteral getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlLiteral>(create);
  static SqlLiteral? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  SqlLiteral_Value whichValue() => _SqlLiteral_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearValue() => $_clearField($_whichOneof(0));

  /// True for NULL.
  @$pb.TagNumber(1)
  $core.bool get nullValue => $_getBF(0);
  @$pb.TagNumber(1)
  set nullValue($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNullValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearNullValue() => $_clearField(1);

  /// Boolean.
  @$pb.TagNumber(2)
  $core.bool get boolValue => $_getBF(1);
  @$pb.TagNumber(2)
  set boolValue($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBoolValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearBoolValue() => $_clearField(2);

  /// Integer.
  @$pb.TagNumber(3)
  $fixnum.Int64 get intValue => $_getI64(2);
  @$pb.TagNumber(3)
  set intValue($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntValue() => $_clearField(3);

  /// Floating point.
  @$pb.TagNumber(4)
  $core.double get doubleValue => $_getN(3);
  @$pb.TagNumber(4)
  set doubleValue($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDoubleValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearDoubleValue() => $_clearField(4);

  /// Text, also used for dates and other values written as strings.
  @$pb.TagNumber(5)
  $core.String get stringValue => $_getSZ(4);
  @$pb.TagNumber(5)
  set stringValue($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStringValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearStringValue() => $_clearField(5);
}

enum SqlOperand_Kind { column, literal, aggregate, notSet }

/// SqlOperand is one side of a comparison or an ORDER BY term.
class SqlOperand extends $pb.GeneratedMessage {
  factory SqlOperand({
    SqlColumnRef? column,
    SqlLiteral? literal,
    SqlAggregateExpr? aggregate,
  }) {
    final result = create();
    if (column != null) result.column = column;
    if (literal != null) result.literal = literal;
    if (aggregate != null) result.aggregate = aggregate;
    return result;
  }

  SqlOperand._();

  factory SqlOperand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlOperand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SqlOperand_Kind> _SqlOperand_KindByTag = {
    1: SqlOperand_Kind.column,
    2: SqlOperand_Kind.literal,
    3: SqlOperand_Kind.aggregate,
    0: SqlOperand_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlOperand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<SqlColumnRef>(1, _omitFieldNames ? '' : 'column',
        subBuilder: SqlColumnRef.create)
    ..aOM<SqlLiteral>(2, _omitFieldNames ? '' : 'literal',
        subBuilder: SqlLiteral.create)
    ..aOM<SqlAggregateExpr>(3, _omitFieldNames ? '' : 'aggregate',
        subBuilder: SqlAggregateExpr.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlOperand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlOperand copyWith(void Function(SqlOperand) updates) =>
      super.copyWith((message) => updates(message as SqlOperand)) as SqlOperand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlOperand create() => SqlOperand._();
  @$core.override
  SqlOperand createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlOperand getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlOperand>(create);
  static SqlOperand? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  SqlOperand_Kind whichKind() => _SqlOperand_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearKind() => $_clearField($_whichOneof(0));

  /// A column.
  @$pb.TagNumber(1)
  SqlColumnRef get column => $_getN(0);
  @$pb.TagNumber(1)
  set column(SqlColumnRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlColumnRef ensureColumn() => $_ensure(0);

  /// A constant.
  @$pb.TagNumber(2)
  SqlLiteral get literal => $_getN(1);
  @$pb.TagNumber(2)
  set literal(SqlLiteral value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLiteral() => $_has(1);
  @$pb.TagNumber(2)
  void clearLiteral() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlLiteral ensureLiteral() => $_ensure(1);

  /// An aggregate, for HAVING and ORDER BY.
  @$pb.TagNumber(3)
  SqlAggregateExpr get aggregate => $_getN(2);
  @$pb.TagNumber(3)
  set aggregate(SqlAggregateExpr value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAggregate() => $_has(2);
  @$pb.TagNumber(3)
  void clearAggregate() => $_clearField(3);
  @$pb.TagNumber(3)
  SqlAggregateExpr ensureAggregate() => $_ensure(2);
}

/// SqlComparison compares an operand with zero or more others.
class SqlComparison extends $pb.GeneratedMessage {
  factory SqlComparison({
    SqlOperand? left,
    SqlOperator? op,
    $core.Iterable<SqlOperand>? operands,
    $core.bool? negated,
  }) {
    final result = create();
    if (left != null) result.left = left;
    if (op != null) result.op = op;
    if (operands != null) result.operands.addAll(operands);
    if (negated != null) result.negated = negated;
    return result;
  }

  SqlComparison._();

  factory SqlComparison.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlComparison.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlComparison',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<SqlOperand>(1, _omitFieldNames ? '' : 'left',
        subBuilder: SqlOperand.create)
    ..aE<SqlOperator>(2, _omitFieldNames ? '' : 'op',
        enumValues: SqlOperator.values)
    ..pPM<SqlOperand>(3, _omitFieldNames ? '' : 'operands',
        subBuilder: SqlOperand.create)
    ..aOB(4, _omitFieldNames ? '' : 'negated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlComparison clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlComparison copyWith(void Function(SqlComparison) updates) =>
      super.copyWith((message) => updates(message as SqlComparison))
          as SqlComparison;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlComparison create() => SqlComparison._();
  @$core.override
  SqlComparison createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlComparison getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlComparison>(create);
  static SqlComparison? _defaultInstance;

  /// Left side.
  @$pb.TagNumber(1)
  SqlOperand get left => $_getN(0);
  @$pb.TagNumber(1)
  set left(SqlOperand value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLeft() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeft() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlOperand ensureLeft() => $_ensure(0);

  /// Operator.
  @$pb.TagNumber(2)
  SqlOperator get op => $_getN(1);
  @$pb.TagNumber(2)
  set op(SqlOperator value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOp() => $_has(1);
  @$pb.TagNumber(2)
  void clearOp() => $_clearField(2);

  /// Right side. The count depends on the operator.
  @$pb.TagNumber(3)
  $pb.PbList<SqlOperand> get operands => $_getList(2);

  /// Wraps the comparison in NOT (NOT IN, NOT LIKE, IS NOT NULL, ...).
  @$pb.TagNumber(4)
  $core.bool get negated => $_getBF(3);
  @$pb.TagNumber(4)
  set negated($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNegated() => $_has(3);
  @$pb.TagNumber(4)
  void clearNegated() => $_clearField(4);
}

/// SqlConditionGroup combines conditions with AND or OR.
class SqlConditionGroup extends $pb.GeneratedMessage {
  factory SqlConditionGroup({
    SqlBoolOp? op,
    $core.Iterable<SqlCondition>? children,
    $core.bool? negated,
  }) {
    final result = create();
    if (op != null) result.op = op;
    if (children != null) result.children.addAll(children);
    if (negated != null) result.negated = negated;
    return result;
  }

  SqlConditionGroup._();

  factory SqlConditionGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlConditionGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlConditionGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<SqlBoolOp>(1, _omitFieldNames ? '' : 'op',
        enumValues: SqlBoolOp.values)
    ..pPM<SqlCondition>(2, _omitFieldNames ? '' : 'children',
        subBuilder: SqlCondition.create)
    ..aOB(3, _omitFieldNames ? '' : 'negated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlConditionGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlConditionGroup copyWith(void Function(SqlConditionGroup) updates) =>
      super.copyWith((message) => updates(message as SqlConditionGroup))
          as SqlConditionGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlConditionGroup create() => SqlConditionGroup._();
  @$core.override
  SqlConditionGroup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlConditionGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlConditionGroup>(create);
  static SqlConditionGroup? _defaultInstance;

  /// How the children combine.
  @$pb.TagNumber(1)
  SqlBoolOp get op => $_getN(0);
  @$pb.TagNumber(1)
  set op(SqlBoolOp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOp() => $_has(0);
  @$pb.TagNumber(1)
  void clearOp() => $_clearField(1);

  /// Child conditions. Needs at least one.
  @$pb.TagNumber(2)
  $pb.PbList<SqlCondition> get children => $_getList(1);

  /// Wraps the group in NOT.
  @$pb.TagNumber(3)
  $core.bool get negated => $_getBF(2);
  @$pb.TagNumber(3)
  set negated($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNegated() => $_has(2);
  @$pb.TagNumber(3)
  void clearNegated() => $_clearField(3);
}

enum SqlCondition_Node { comparison, group, notSet }

/// SqlCondition is a node of a WHERE, HAVING or ON tree.
class SqlCondition extends $pb.GeneratedMessage {
  factory SqlCondition({
    SqlComparison? comparison,
    SqlConditionGroup? group,
  }) {
    final result = create();
    if (comparison != null) result.comparison = comparison;
    if (group != null) result.group = group;
    return result;
  }

  SqlCondition._();

  factory SqlCondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlCondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SqlCondition_Node> _SqlCondition_NodeByTag =
      {
    1: SqlCondition_Node.comparison,
    2: SqlCondition_Node.group,
    0: SqlCondition_Node.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlCondition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SqlComparison>(1, _omitFieldNames ? '' : 'comparison',
        subBuilder: SqlComparison.create)
    ..aOM<SqlConditionGroup>(2, _omitFieldNames ? '' : 'group',
        subBuilder: SqlConditionGroup.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlCondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlCondition copyWith(void Function(SqlCondition) updates) =>
      super.copyWith((message) => updates(message as SqlCondition))
          as SqlCondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlCondition create() => SqlCondition._();
  @$core.override
  SqlCondition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlCondition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlCondition>(create);
  static SqlCondition? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SqlCondition_Node whichNode() => _SqlCondition_NodeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearNode() => $_clearField($_whichOneof(0));

  /// A leaf comparison.
  @$pb.TagNumber(1)
  SqlComparison get comparison => $_getN(0);
  @$pb.TagNumber(1)
  set comparison(SqlComparison value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasComparison() => $_has(0);
  @$pb.TagNumber(1)
  void clearComparison() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlComparison ensureComparison() => $_ensure(0);

  /// A nested group.
  @$pb.TagNumber(2)
  SqlConditionGroup get group => $_getN(1);
  @$pb.TagNumber(2)
  set group(SqlConditionGroup value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroup() => $_clearField(2);
  @$pb.TagNumber(2)
  SqlConditionGroup ensureGroup() => $_ensure(1);
}

/// SqlOrderTerm is one ORDER BY entry.
class SqlOrderTerm extends $pb.GeneratedMessage {
  factory SqlOrderTerm({
    SqlOperand? expression,
    $core.bool? descending,
    SqlNulls? nulls,
  }) {
    final result = create();
    if (expression != null) result.expression = expression;
    if (descending != null) result.descending = descending;
    if (nulls != null) result.nulls = nulls;
    return result;
  }

  SqlOrderTerm._();

  factory SqlOrderTerm.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SqlOrderTerm.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlOrderTerm',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<SqlOperand>(1, _omitFieldNames ? '' : 'expression',
        subBuilder: SqlOperand.create)
    ..aOB(2, _omitFieldNames ? '' : 'descending')
    ..aE<SqlNulls>(3, _omitFieldNames ? '' : 'nulls',
        enumValues: SqlNulls.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlOrderTerm clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlOrderTerm copyWith(void Function(SqlOrderTerm) updates) =>
      super.copyWith((message) => updates(message as SqlOrderTerm))
          as SqlOrderTerm;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlOrderTerm create() => SqlOrderTerm._();
  @$core.override
  SqlOrderTerm createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SqlOrderTerm getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlOrderTerm>(create);
  static SqlOrderTerm? _defaultInstance;

  /// The sorted expression. Never a literal.
  @$pb.TagNumber(1)
  SqlOperand get expression => $_getN(0);
  @$pb.TagNumber(1)
  set expression(SqlOperand value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpression() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpression() => $_clearField(1);
  @$pb.TagNumber(1)
  SqlOperand ensureExpression() => $_ensure(0);

  /// Descending order.
  @$pb.TagNumber(2)
  $core.bool get descending => $_getBF(1);
  @$pb.TagNumber(2)
  set descending($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescending() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescending() => $_clearField(2);

  /// NULL placement.
  @$pb.TagNumber(3)
  SqlNulls get nulls => $_getN(2);
  @$pb.TagNumber(3)
  set nulls(SqlNulls value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNulls() => $_has(2);
  @$pb.TagNumber(3)
  void clearNulls() => $_clearField(3);
}

/// GenerateMongoQueryRequest is the input of GenerateMongoQuery.
class GenerateMongoQueryRequest extends $pb.GeneratedMessage {
  factory GenerateMongoQueryRequest({
    MongoFindModel? model,
  }) {
    final result = create();
    if (model != null) result.model = model;
    return result;
  }

  GenerateMongoQueryRequest._();

  factory GenerateMongoQueryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateMongoQueryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateMongoQueryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MongoFindModel>(1, _omitFieldNames ? '' : 'model',
        subBuilder: MongoFindModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateMongoQueryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateMongoQueryRequest copyWith(
          void Function(GenerateMongoQueryRequest) updates) =>
      super.copyWith((message) => updates(message as GenerateMongoQueryRequest))
          as GenerateMongoQueryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateMongoQueryRequest create() => GenerateMongoQueryRequest._();
  @$core.override
  GenerateMongoQueryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateMongoQueryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateMongoQueryRequest>(create);
  static GenerateMongoQueryRequest? _defaultInstance;

  /// The model to render.
  @$pb.TagNumber(1)
  MongoFindModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(MongoFindModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  MongoFindModel ensureModel() => $_ensure(0);
}

/// GenerateMongoQueryResponse holds the documents or the failure.
class GenerateMongoQueryResponse extends $pb.GeneratedMessage {
  factory GenerateMongoQueryResponse({
    $core.String? filterEjson,
    $core.String? projectionEjson,
    $core.String? sortEjson,
    QueryBuilderError? error,
  }) {
    final result = create();
    if (filterEjson != null) result.filterEjson = filterEjson;
    if (projectionEjson != null) result.projectionEjson = projectionEjson;
    if (sortEjson != null) result.sortEjson = sortEjson;
    if (error != null) result.error = error;
    return result;
  }

  GenerateMongoQueryResponse._();

  factory GenerateMongoQueryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GenerateMongoQueryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenerateMongoQueryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filterEjson')
    ..aOS(2, _omitFieldNames ? '' : 'projectionEjson')
    ..aOS(3, _omitFieldNames ? '' : 'sortEjson')
    ..aOM<QueryBuilderError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: QueryBuilderError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateMongoQueryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenerateMongoQueryResponse copyWith(
          void Function(GenerateMongoQueryResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GenerateMongoQueryResponse))
          as GenerateMongoQueryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GenerateMongoQueryResponse create() => GenerateMongoQueryResponse._();
  @$core.override
  GenerateMongoQueryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GenerateMongoQueryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GenerateMongoQueryResponse>(create);
  static GenerateMongoQueryResponse? _defaultInstance;

  /// Filter as canonical EJSON. "{}" when the model has no filter.
  @$pb.TagNumber(1)
  $core.String get filterEjson => $_getSZ(0);
  @$pb.TagNumber(1)
  set filterEjson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilterEjson() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilterEjson() => $_clearField(1);

  /// Projection as canonical EJSON, or empty when there is none.
  @$pb.TagNumber(2)
  $core.String get projectionEjson => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectionEjson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectionEjson() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectionEjson() => $_clearField(2);

  /// Sort as canonical EJSON, or empty when there is none. Key order is the
  /// sort order.
  @$pb.TagNumber(3)
  $core.String get sortEjson => $_getSZ(2);
  @$pb.TagNumber(3)
  set sortEjson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortEjson() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortEjson() => $_clearField(3);

  /// Set when generation failed.
  @$pb.TagNumber(4)
  QueryBuilderError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(QueryBuilderError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  QueryBuilderError ensureError() => $_ensure(3);
}

/// ParseMongoQueryRequest is the input of ParseMongoQuery.
class ParseMongoQueryRequest extends $pb.GeneratedMessage {
  factory ParseMongoQueryRequest({
    $core.String? filterEjson,
    $core.String? projectionEjson,
    $core.String? sortEjson,
  }) {
    final result = create();
    if (filterEjson != null) result.filterEjson = filterEjson;
    if (projectionEjson != null) result.projectionEjson = projectionEjson;
    if (sortEjson != null) result.sortEjson = sortEjson;
    return result;
  }

  ParseMongoQueryRequest._();

  factory ParseMongoQueryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseMongoQueryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseMongoQueryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filterEjson')
    ..aOS(2, _omitFieldNames ? '' : 'projectionEjson')
    ..aOS(3, _omitFieldNames ? '' : 'sortEjson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseMongoQueryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseMongoQueryRequest copyWith(
          void Function(ParseMongoQueryRequest) updates) =>
      super.copyWith((message) => updates(message as ParseMongoQueryRequest))
          as ParseMongoQueryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseMongoQueryRequest create() => ParseMongoQueryRequest._();
  @$core.override
  ParseMongoQueryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseMongoQueryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseMongoQueryRequest>(create);
  static ParseMongoQueryRequest? _defaultInstance;

  /// Filter document as EJSON. Empty means no filter.
  @$pb.TagNumber(1)
  $core.String get filterEjson => $_getSZ(0);
  @$pb.TagNumber(1)
  set filterEjson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilterEjson() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilterEjson() => $_clearField(1);

  /// Projection document as EJSON. Empty means none.
  @$pb.TagNumber(2)
  $core.String get projectionEjson => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectionEjson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectionEjson() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectionEjson() => $_clearField(2);

  /// Sort document as EJSON. Empty means none.
  @$pb.TagNumber(3)
  $core.String get sortEjson => $_getSZ(2);
  @$pb.TagNumber(3)
  set sortEjson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortEjson() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortEjson() => $_clearField(3);
}

/// ParseMongoQueryResponse holds the model or the failure.
class ParseMongoQueryResponse extends $pb.GeneratedMessage {
  factory ParseMongoQueryResponse({
    MongoFindModel? model,
    QueryBuilderError? error,
  }) {
    final result = create();
    if (model != null) result.model = model;
    if (error != null) result.error = error;
    return result;
  }

  ParseMongoQueryResponse._();

  factory ParseMongoQueryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseMongoQueryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseMongoQueryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MongoFindModel>(1, _omitFieldNames ? '' : 'model',
        subBuilder: MongoFindModel.create)
    ..aOM<QueryBuilderError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: QueryBuilderError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseMongoQueryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseMongoQueryResponse copyWith(
          void Function(ParseMongoQueryResponse) updates) =>
      super.copyWith((message) => updates(message as ParseMongoQueryResponse))
          as ParseMongoQueryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseMongoQueryResponse create() => ParseMongoQueryResponse._();
  @$core.override
  ParseMongoQueryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseMongoQueryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseMongoQueryResponse>(create);
  static ParseMongoQueryResponse? _defaultInstance;

  /// The parsed model.
  @$pb.TagNumber(1)
  MongoFindModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(MongoFindModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  MongoFindModel ensureModel() => $_ensure(0);

  /// Set when parsing failed.
  @$pb.TagNumber(2)
  QueryBuilderError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(QueryBuilderError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  QueryBuilderError ensureError() => $_ensure(1);
}

/// MongoFindModel is a find filter, projection and sort in visual form.
class MongoFindModel extends $pb.GeneratedMessage {
  factory MongoFindModel({
    MongoCondition? filter,
    $core.Iterable<MongoProjectionField>? projection,
    $core.Iterable<MongoSortField>? sort,
  }) {
    final result = create();
    if (filter != null) result.filter = filter;
    if (projection != null) result.projection.addAll(projection);
    if (sort != null) result.sort.addAll(sort);
    return result;
  }

  MongoFindModel._();

  factory MongoFindModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoFindModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoFindModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MongoCondition>(1, _omitFieldNames ? '' : 'filter',
        subBuilder: MongoCondition.create)
    ..pPM<MongoProjectionField>(2, _omitFieldNames ? '' : 'projection',
        subBuilder: MongoProjectionField.create)
    ..pPM<MongoSortField>(3, _omitFieldNames ? '' : 'sort',
        subBuilder: MongoSortField.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoFindModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoFindModel copyWith(void Function(MongoFindModel) updates) =>
      super.copyWith((message) => updates(message as MongoFindModel))
          as MongoFindModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoFindModel create() => MongoFindModel._();
  @$core.override
  MongoFindModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoFindModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoFindModel>(create);
  static MongoFindModel? _defaultInstance;

  /// Filter tree. Unset means no filter.
  @$pb.TagNumber(1)
  MongoCondition get filter => $_getN(0);
  @$pb.TagNumber(1)
  set filter(MongoCondition value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFilter() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilter() => $_clearField(1);
  @$pb.TagNumber(1)
  MongoCondition ensureFilter() => $_ensure(0);

  /// Projection entries. Empty means all fields.
  @$pb.TagNumber(2)
  $pb.PbList<MongoProjectionField> get projection => $_getList(1);

  /// Sort entries in order.
  @$pb.TagNumber(3)
  $pb.PbList<MongoSortField> get sort => $_getList(2);
}

/// MongoConditionGroup combines conditions.
class MongoConditionGroup extends $pb.GeneratedMessage {
  factory MongoConditionGroup({
    MongoBoolOp? op,
    $core.Iterable<MongoCondition>? children,
  }) {
    final result = create();
    if (op != null) result.op = op;
    if (children != null) result.children.addAll(children);
    return result;
  }

  MongoConditionGroup._();

  factory MongoConditionGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoConditionGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoConditionGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<MongoBoolOp>(1, _omitFieldNames ? '' : 'op',
        enumValues: MongoBoolOp.values)
    ..pPM<MongoCondition>(2, _omitFieldNames ? '' : 'children',
        subBuilder: MongoCondition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoConditionGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoConditionGroup copyWith(void Function(MongoConditionGroup) updates) =>
      super.copyWith((message) => updates(message as MongoConditionGroup))
          as MongoConditionGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoConditionGroup create() => MongoConditionGroup._();
  @$core.override
  MongoConditionGroup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoConditionGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoConditionGroup>(create);
  static MongoConditionGroup? _defaultInstance;

  /// How the children combine.
  @$pb.TagNumber(1)
  MongoBoolOp get op => $_getN(0);
  @$pb.TagNumber(1)
  set op(MongoBoolOp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOp() => $_has(0);
  @$pb.TagNumber(1)
  void clearOp() => $_clearField(1);

  /// Child conditions. Needs at least one.
  @$pb.TagNumber(2)
  $pb.PbList<MongoCondition> get children => $_getList(1);
}

/// MongoFieldCondition tests one field path.
class MongoFieldCondition extends $pb.GeneratedMessage {
  factory MongoFieldCondition({
    $core.String? path,
    MongoOperator? op,
    $core.String? valueEjson,
    $core.String? regexOptions,
    $core.bool? negated,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (op != null) result.op = op;
    if (valueEjson != null) result.valueEjson = valueEjson;
    if (regexOptions != null) result.regexOptions = regexOptions;
    if (negated != null) result.negated = negated;
    return result;
  }

  MongoFieldCondition._();

  factory MongoFieldCondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoFieldCondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoFieldCondition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aE<MongoOperator>(2, _omitFieldNames ? '' : 'op',
        enumValues: MongoOperator.values)
    ..aOS(3, _omitFieldNames ? '' : 'valueEjson')
    ..aOS(4, _omitFieldNames ? '' : 'regexOptions')
    ..aOB(5, _omitFieldNames ? '' : 'negated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoFieldCondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoFieldCondition copyWith(void Function(MongoFieldCondition) updates) =>
      super.copyWith((message) => updates(message as MongoFieldCondition))
          as MongoFieldCondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoFieldCondition create() => MongoFieldCondition._();
  @$core.override
  MongoFieldCondition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoFieldCondition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoFieldCondition>(create);
  static MongoFieldCondition? _defaultInstance;

  /// Dotted field path, for example "address.city".
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// Operator.
  @$pb.TagNumber(2)
  MongoOperator get op => $_getN(1);
  @$pb.TagNumber(2)
  set op(MongoOperator value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOp() => $_has(1);
  @$pb.TagNumber(2)
  void clearOp() => $_clearField(2);

  /// The operand as canonical EJSON, so BSON types survive.
  @$pb.TagNumber(3)
  $core.String get valueEjson => $_getSZ(2);
  @$pb.TagNumber(3)
  set valueEjson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValueEjson() => $_has(2);
  @$pb.TagNumber(3)
  void clearValueEjson() => $_clearField(3);

  /// $options for REGEX, for example "i". Empty for other operators.
  @$pb.TagNumber(4)
  $core.String get regexOptions => $_getSZ(3);
  @$pb.TagNumber(4)
  set regexOptions($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRegexOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegexOptions() => $_clearField(4);

  /// Wraps the operator in $not.
  @$pb.TagNumber(5)
  $core.bool get negated => $_getBF(4);
  @$pb.TagNumber(5)
  set negated($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNegated() => $_has(4);
  @$pb.TagNumber(5)
  void clearNegated() => $_clearField(5);
}

enum MongoCondition_Node { field_1, group, rawEjson, notSet }

/// MongoCondition is a node of a filter tree.
class MongoCondition extends $pb.GeneratedMessage {
  factory MongoCondition({
    MongoFieldCondition? field_1,
    MongoConditionGroup? group,
    $core.String? rawEjson,
  }) {
    final result = create();
    if (field_1 != null) result.field_1 = field_1;
    if (group != null) result.group = group;
    if (rawEjson != null) result.rawEjson = rawEjson;
    return result;
  }

  MongoCondition._();

  factory MongoCondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoCondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MongoCondition_Node>
      _MongoCondition_NodeByTag = {
    1: MongoCondition_Node.field_1,
    2: MongoCondition_Node.group,
    3: MongoCondition_Node.rawEjson,
    0: MongoCondition_Node.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoCondition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<MongoFieldCondition>(1, _omitFieldNames ? '' : 'field',
        subBuilder: MongoFieldCondition.create)
    ..aOM<MongoConditionGroup>(2, _omitFieldNames ? '' : 'group',
        subBuilder: MongoConditionGroup.create)
    ..aOS(3, _omitFieldNames ? '' : 'rawEjson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoCondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoCondition copyWith(void Function(MongoCondition) updates) =>
      super.copyWith((message) => updates(message as MongoCondition))
          as MongoCondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoCondition create() => MongoCondition._();
  @$core.override
  MongoCondition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoCondition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoCondition>(create);
  static MongoCondition? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  MongoCondition_Node whichNode() =>
      _MongoCondition_NodeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearNode() => $_clearField($_whichOneof(0));

  /// A leaf on one field.
  @$pb.TagNumber(1)
  MongoFieldCondition get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1(MongoFieldCondition value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => $_clearField(1);
  @$pb.TagNumber(1)
  MongoFieldCondition ensureField_1() => $_ensure(0);

  /// A nested group.
  @$pb.TagNumber(2)
  MongoConditionGroup get group => $_getN(1);
  @$pb.TagNumber(2)
  set group(MongoConditionGroup value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroup() => $_clearField(2);
  @$pb.TagNumber(2)
  MongoConditionGroup ensureGroup() => $_ensure(1);

  /// A condition without a visual form, as one EJSON document that is merged
  /// into the filter as is, for example {"$expr": {...}}. It survives the
  /// round trip and is edited as text.
  @$pb.TagNumber(3)
  $core.String get rawEjson => $_getSZ(2);
  @$pb.TagNumber(3)
  set rawEjson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRawEjson() => $_has(2);
  @$pb.TagNumber(3)
  void clearRawEjson() => $_clearField(3);
}

/// MongoProjectionField is one projection entry.
class MongoProjectionField extends $pb.GeneratedMessage {
  factory MongoProjectionField({
    $core.String? path,
    MongoProjectionMode? mode,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (mode != null) result.mode = mode;
    return result;
  }

  MongoProjectionField._();

  factory MongoProjectionField.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoProjectionField.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoProjectionField',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aE<MongoProjectionMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: MongoProjectionMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoProjectionField clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoProjectionField copyWith(void Function(MongoProjectionField) updates) =>
      super.copyWith((message) => updates(message as MongoProjectionField))
          as MongoProjectionField;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoProjectionField create() => MongoProjectionField._();
  @$core.override
  MongoProjectionField createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoProjectionField getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoProjectionField>(create);
  static MongoProjectionField? _defaultInstance;

  /// Dotted field path.
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// Keep or drop.
  @$pb.TagNumber(2)
  MongoProjectionMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(MongoProjectionMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);
}

/// MongoSortField is one sort entry.
class MongoSortField extends $pb.GeneratedMessage {
  factory MongoSortField({
    $core.String? path,
    $core.bool? descending,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (descending != null) result.descending = descending;
    return result;
  }

  MongoSortField._();

  factory MongoSortField.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoSortField.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoSortField',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOB(2, _omitFieldNames ? '' : 'descending')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoSortField clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoSortField copyWith(void Function(MongoSortField) updates) =>
      super.copyWith((message) => updates(message as MongoSortField))
          as MongoSortField;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoSortField create() => MongoSortField._();
  @$core.override
  MongoSortField createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoSortField getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoSortField>(create);
  static MongoSortField? _defaultInstance;

  /// Dotted field path.
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// Descending order.
  @$pb.TagNumber(2)
  $core.bool get descending => $_getBF(1);
  @$pb.TagNumber(2)
  set descending($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescending() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescending() => $_clearField(2);
}

/// TranslateMongoSqlRequest is the input of TranslateMongoSql.
class TranslateMongoSqlRequest extends $pb.GeneratedMessage {
  factory TranslateMongoSqlRequest({
    $core.String? sessionId,
    $core.String? sql,
    $core.String? database,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (sql != null) result.sql = sql;
    if (database != null) result.database = database;
    return result;
  }

  TranslateMongoSqlRequest._();

  factory TranslateMongoSqlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranslateMongoSqlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranslateMongoSqlRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'sql')
    ..aOS(3, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateMongoSqlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateMongoSqlRequest copyWith(
          void Function(TranslateMongoSqlRequest) updates) =>
      super.copyWith((message) => updates(message as TranslateMongoSqlRequest))
          as TranslateMongoSqlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranslateMongoSqlRequest create() => TranslateMongoSqlRequest._();
  @$core.override
  TranslateMongoSqlRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranslateMongoSqlRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranslateMongoSqlRequest>(create);
  static TranslateMongoSqlRequest? _defaultInstance;

  /// Session id. Used to resolve the default database only.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// One SELECT statement.
  @$pb.TagNumber(2)
  $core.String get sql => $_getSZ(1);
  @$pb.TagNumber(2)
  set sql($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSql() => $_has(1);
  @$pb.TagNumber(2)
  void clearSql() => $_clearField(2);

  /// Database the collections belong to. Empty means the session's default
  /// database.
  @$pb.TagNumber(3)
  $core.String get database => $_getSZ(2);
  @$pb.TagNumber(3)
  set database($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDatabase() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatabase() => $_clearField(3);
}

/// MongoSqlWarning points at a place where MongoDB semantics differ from SQL,
/// for example IS NULL also matching a missing field.
class MongoSqlWarning extends $pb.GeneratedMessage {
  factory MongoSqlWarning({
    $core.String? message,
    $core.int? offset,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (offset != null) result.offset = offset;
    return result;
  }

  MongoSqlWarning._();

  factory MongoSqlWarning.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MongoSqlWarning.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MongoSqlWarning',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aI(2, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoSqlWarning clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MongoSqlWarning copyWith(void Function(MongoSqlWarning) updates) =>
      super.copyWith((message) => updates(message as MongoSqlWarning))
          as MongoSqlWarning;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MongoSqlWarning create() => MongoSqlWarning._();
  @$core.override
  MongoSqlWarning createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MongoSqlWarning getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MongoSqlWarning>(create);
  static MongoSqlWarning? _defaultInstance;

  /// Human-readable explanation, safe to show to the user.
  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  /// Zero-based UTF-8 byte offset into the SQL text of the construct the
  /// warning is about. Unset when it applies to the whole statement.
  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

/// TranslateMongoSqlResponse holds the translation or the failure.
class TranslateMongoSqlResponse extends $pb.GeneratedMessage {
  factory TranslateMongoSqlResponse({
    $core.String? database,
    $core.String? collection,
    MongoSqlResultKind? kind,
    $core.String? filterEjson,
    $core.String? projectionEjson,
    $core.String? sortEjson,
    $fixnum.Int64? skip,
    $fixnum.Int64? limit,
    $core.String? pipelineEjson,
    $core.String? shellCode,
    $core.Iterable<MongoSqlWarning>? warnings,
    QueryBuilderError? error,
  }) {
    final result = create();
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (kind != null) result.kind = kind;
    if (filterEjson != null) result.filterEjson = filterEjson;
    if (projectionEjson != null) result.projectionEjson = projectionEjson;
    if (sortEjson != null) result.sortEjson = sortEjson;
    if (skip != null) result.skip = skip;
    if (limit != null) result.limit = limit;
    if (pipelineEjson != null) result.pipelineEjson = pipelineEjson;
    if (shellCode != null) result.shellCode = shellCode;
    if (warnings != null) result.warnings.addAll(warnings);
    if (error != null) result.error = error;
    return result;
  }

  TranslateMongoSqlResponse._();

  factory TranslateMongoSqlResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranslateMongoSqlResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranslateMongoSqlResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'database')
    ..aOS(2, _omitFieldNames ? '' : 'collection')
    ..aE<MongoSqlResultKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: MongoSqlResultKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'filterEjson')
    ..aOS(5, _omitFieldNames ? '' : 'projectionEjson')
    ..aOS(6, _omitFieldNames ? '' : 'sortEjson')
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'skip', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(9, _omitFieldNames ? '' : 'pipelineEjson')
    ..aOS(10, _omitFieldNames ? '' : 'shellCode')
    ..pPM<MongoSqlWarning>(11, _omitFieldNames ? '' : 'warnings',
        subBuilder: MongoSqlWarning.create)
    ..aOM<QueryBuilderError>(12, _omitFieldNames ? '' : 'error',
        subBuilder: QueryBuilderError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateMongoSqlResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateMongoSqlResponse copyWith(
          void Function(TranslateMongoSqlResponse) updates) =>
      super.copyWith((message) => updates(message as TranslateMongoSqlResponse))
          as TranslateMongoSqlResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranslateMongoSqlResponse create() => TranslateMongoSqlResponse._();
  @$core.override
  TranslateMongoSqlResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranslateMongoSqlResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranslateMongoSqlResponse>(create);
  static TranslateMongoSqlResponse? _defaultInstance;

  /// Database the query runs against.
  @$pb.TagNumber(1)
  $core.String get database => $_getSZ(0);
  @$pb.TagNumber(1)
  set database($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDatabase() => $_has(0);
  @$pb.TagNumber(1)
  void clearDatabase() => $_clearField(1);

  /// Collection named in FROM.
  @$pb.TagNumber(2)
  $core.String get collection => $_getSZ(1);
  @$pb.TagNumber(2)
  set collection($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCollection() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollection() => $_clearField(2);

  /// Which operation the fields below describe.
  @$pb.TagNumber(3)
  MongoSqlResultKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(MongoSqlResultKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// FIND: filter as canonical EJSON. "{}" when there is no WHERE.
  @$pb.TagNumber(4)
  $core.String get filterEjson => $_getSZ(3);
  @$pb.TagNumber(4)
  set filterEjson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilterEjson() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilterEjson() => $_clearField(4);

  /// FIND: projection as canonical EJSON, or empty for all fields.
  @$pb.TagNumber(5)
  $core.String get projectionEjson => $_getSZ(4);
  @$pb.TagNumber(5)
  set projectionEjson($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProjectionEjson() => $_has(4);
  @$pb.TagNumber(5)
  void clearProjectionEjson() => $_clearField(5);

  /// FIND: sort as canonical EJSON, or empty when there is no ORDER BY. Key
  /// order is the sort order.
  @$pb.TagNumber(6)
  $core.String get sortEjson => $_getSZ(5);
  @$pb.TagNumber(6)
  set sortEjson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSortEjson() => $_has(5);
  @$pb.TagNumber(6)
  void clearSortEjson() => $_clearField(6);

  /// FIND: documents to skip.
  @$pb.TagNumber(7)
  $fixnum.Int64 get skip => $_getI64(6);
  @$pb.TagNumber(7)
  set skip($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSkip() => $_has(6);
  @$pb.TagNumber(7)
  void clearSkip() => $_clearField(7);

  /// FIND: maximum documents. Unset means no limit.
  @$pb.TagNumber(8)
  $fixnum.Int64 get limit => $_getI64(7);
  @$pb.TagNumber(8)
  set limit($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearLimit() => $_clearField(8);

  /// AGGREGATE: canonical EJSON array of single-key stage documents.
  @$pb.TagNumber(9)
  $core.String get pipelineEjson => $_getSZ(8);
  @$pb.TagNumber(9)
  set pipelineEjson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPipelineEjson() => $_has(8);
  @$pb.TagNumber(9)
  void clearPipelineEjson() => $_clearField(9);

  /// Runnable shell code for either kind, e.g.
  /// db.getSiblingDB("shop").orders.find({...}).
  @$pb.TagNumber(10)
  $core.String get shellCode => $_getSZ(9);
  @$pb.TagNumber(10)
  set shellCode($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasShellCode() => $_has(9);
  @$pb.TagNumber(10)
  void clearShellCode() => $_clearField(10);

  /// Semantic differences the statement touches. Empty when none.
  @$pb.TagNumber(11)
  $pb.PbList<MongoSqlWarning> get warnings => $_getList(10);

  /// Set when translation failed; all other fields are then empty.
  @$pb.TagNumber(12)
  QueryBuilderError get error => $_getN(11);
  @$pb.TagNumber(12)
  set error(QueryBuilderError value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasError() => $_has(11);
  @$pb.TagNumber(12)
  void clearError() => $_clearField(12);
  @$pb.TagNumber(12)
  QueryBuilderError ensureError() => $_ensure(11);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
