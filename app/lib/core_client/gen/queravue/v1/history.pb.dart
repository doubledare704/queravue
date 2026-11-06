// This is a generated file - do not edit.
//
// Generated from queravue/v1/history.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $2;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// HistoryEntry records the execution of a single query statement.
class HistoryEntry extends $pb.GeneratedMessage {
  factory HistoryEntry({
    $fixnum.Int64? id,
    $core.String? connectionId,
    $core.String? queryText,
    $1.Timestamp? startedAt,
    $2.Duration? duration,
    $fixnum.Int64? rowsAffected,
    $core.String? error,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (connectionId != null) result.connectionId = connectionId;
    if (queryText != null) result.queryText = queryText;
    if (startedAt != null) result.startedAt = startedAt;
    if (duration != null) result.duration = duration;
    if (rowsAffected != null) result.rowsAffected = rowsAffected;
    if (error != null) result.error = error;
    return result;
  }

  HistoryEntry._();

  factory HistoryEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HistoryEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HistoryEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'connectionId')
    ..aOS(3, _omitFieldNames ? '' : 'queryText')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$2.Duration>(5, _omitFieldNames ? '' : 'duration',
        subBuilder: $2.Duration.create)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'rowsAffected', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(7, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryEntry copyWith(void Function(HistoryEntry) updates) =>
      super.copyWith((message) => updates(message as HistoryEntry))
          as HistoryEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HistoryEntry create() => HistoryEntry._();
  @$core.override
  HistoryEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HistoryEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HistoryEntry>(create);
  static HistoryEntry? _defaultInstance;

  /// Unique entry ID.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Connection ID the query was executed on.
  @$pb.TagNumber(2)
  $core.String get connectionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionId() => $_clearField(2);

  /// SQL text of the query. Never contains bound parameter values.
  @$pb.TagNumber(3)
  $core.String get queryText => $_getSZ(2);
  @$pb.TagNumber(3)
  set queryText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQueryText() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueryText() => $_clearField(3);

  /// Timestamp when query execution began.
  @$pb.TagNumber(4)
  $1.Timestamp get startedAt => $_getN(3);
  @$pb.TagNumber(4)
  set startedAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStartedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureStartedAt() => $_ensure(3);

  /// Elapsed execution time.
  @$pb.TagNumber(5)
  $2.Duration get duration => $_getN(4);
  @$pb.TagNumber(5)
  set duration($2.Duration value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDuration() => $_has(4);
  @$pb.TagNumber(5)
  void clearDuration() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Duration ensureDuration() => $_ensure(4);

  /// Number of rows affected or returned by the query.
  @$pb.TagNumber(6)
  $fixnum.Int64 get rowsAffected => $_getI64(5);
  @$pb.TagNumber(6)
  set rowsAffected($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRowsAffected() => $_has(5);
  @$pb.TagNumber(6)
  void clearRowsAffected() => $_clearField(6);

  /// Error message if execution failed, or empty on success.
  @$pb.TagNumber(7)
  $core.String get error => $_getSZ(6);
  @$pb.TagNumber(7)
  set error($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
}

/// ListHistoryRequest filters and paginates query history entries.
class ListHistoryRequest extends $pb.GeneratedMessage {
  factory ListHistoryRequest({
    $core.String? connectionId,
    $core.String? searchQuery,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (connectionId != null) result.connectionId = connectionId;
    if (searchQuery != null) result.searchQuery = searchQuery;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListHistoryRequest._();

  factory ListHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'searchQuery')
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryRequest copyWith(void Function(ListHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as ListHistoryRequest))
          as ListHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHistoryRequest create() => ListHistoryRequest._();
  @$core.override
  ListHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHistoryRequest>(create);
  static ListHistoryRequest? _defaultInstance;

  /// Optional connection ID filter; empty matches all connections.
  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  /// Optional text search string matched against query_text.
  @$pb.TagNumber(2)
  $core.String get searchQuery => $_getSZ(1);
  @$pb.TagNumber(2)
  set searchQuery($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSearchQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearSearchQuery() => $_clearField(2);

  /// Maximum number of entries to return (default 50, capped at 500).
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  /// Number of entries to skip for pagination.
  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);
}

/// ListHistoryResponse returns matching history entries.
class ListHistoryResponse extends $pb.GeneratedMessage {
  factory ListHistoryResponse({
    $core.Iterable<HistoryEntry>? entries,
    $fixnum.Int64? totalCount,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (totalCount != null) result.totalCount = totalCount;
    return result;
  }

  ListHistoryResponse._();

  factory ListHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<HistoryEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: HistoryEntry.create)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'totalCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryResponse copyWith(void Function(ListHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as ListHistoryResponse))
          as ListHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHistoryResponse create() => ListHistoryResponse._();
  @$core.override
  ListHistoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHistoryResponse>(create);
  static ListHistoryResponse? _defaultInstance;

  /// History entries ordered by started_at descending.
  @$pb.TagNumber(1)
  $pb.PbList<HistoryEntry> get entries => $_getList(0);

  /// Total number of entries matching the filter criteria.
  @$pb.TagNumber(2)
  $fixnum.Int64 get totalCount => $_getI64(1);
  @$pb.TagNumber(2)
  set totalCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalCount() => $_clearField(2);
}

/// ClearHistoryRequest specifies which history entries to remove.
class ClearHistoryRequest extends $pb.GeneratedMessage {
  factory ClearHistoryRequest({
    $core.String? connectionId,
  }) {
    final result = create();
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  ClearHistoryRequest._();

  factory ClearHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClearHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClearHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearHistoryRequest copyWith(void Function(ClearHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as ClearHistoryRequest))
          as ClearHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClearHistoryRequest create() => ClearHistoryRequest._();
  @$core.override
  ClearHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClearHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClearHistoryRequest>(create);
  static ClearHistoryRequest? _defaultInstance;

  /// Optional connection ID; if empty, all history is cleared.
  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);
}

/// ClearHistoryResponse is empty on success.
class ClearHistoryResponse extends $pb.GeneratedMessage {
  factory ClearHistoryResponse() => create();

  ClearHistoryResponse._();

  factory ClearHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClearHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClearHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearHistoryResponse copyWith(void Function(ClearHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as ClearHistoryResponse))
          as ClearHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClearHistoryResponse create() => ClearHistoryResponse._();
  @$core.override
  ClearHistoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClearHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClearHistoryResponse>(create);
  static ClearHistoryResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
