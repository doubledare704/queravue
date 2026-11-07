// This is a generated file - do not edit.
//
// Generated from queravue/v1/stats.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $2;
import 'schema.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// StatEntry is an engine-specific figure shown as a label and value.
class StatEntry extends $pb.GeneratedMessage {
  factory StatEntry({
    $core.String? key,
    $core.String? label,
    $core.String? value,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (value != null) result.value = value;
    return result;
  }

  StatEntry._();

  factory StatEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatEntry copyWith(void Function(StatEntry) updates) =>
      super.copyWith((message) => updates(message as StatEntry)) as StatEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatEntry create() => StatEntry._();
  @$core.override
  StatEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatEntry>(create);
  static StatEntry? _defaultInstance;

  /// Stable key, for example "last_autovacuum" or "avg_obj_size".
  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  /// Label to show.
  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  /// Value already formatted as text by the core.
  @$pb.TagNumber(3)
  $core.String get value => $_getSZ(2);
  @$pb.TagNumber(3)
  set value($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => $_clearField(3);
}

/// TableStats holds the common figures; unknown ones are unset, never zero.
class TableStats extends $pb.GeneratedMessage {
  factory TableStats({
    $fixnum.Int64? estimatedRows,
    $fixnum.Int64? dataBytes,
    $fixnum.Int64? indexBytes,
    $fixnum.Int64? totalBytes,
    $core.Iterable<StatEntry>? extras,
  }) {
    final result = create();
    if (estimatedRows != null) result.estimatedRows = estimatedRows;
    if (dataBytes != null) result.dataBytes = dataBytes;
    if (indexBytes != null) result.indexBytes = indexBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (extras != null) result.extras.addAll(extras);
    return result;
  }

  TableStats._();

  factory TableStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'estimatedRows')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'dataBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'indexBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<StatEntry>(5, _omitFieldNames ? '' : 'extras',
        subBuilder: StatEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableStats copyWith(void Function(TableStats) updates) =>
      super.copyWith((message) => updates(message as TableStats)) as TableStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableStats create() => TableStats._();
  @$core.override
  TableStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableStats>(create);
  static TableStats? _defaultInstance;

  /// Estimated row or document count.
  @$pb.TagNumber(1)
  $fixnum.Int64 get estimatedRows => $_getI64(0);
  @$pb.TagNumber(1)
  set estimatedRows($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEstimatedRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearEstimatedRows() => $_clearField(1);

  /// Bytes used by table or collection data.
  @$pb.TagNumber(2)
  $fixnum.Int64 get dataBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set dataBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDataBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataBytes() => $_clearField(2);

  /// Bytes used by all indexes.
  @$pb.TagNumber(3)
  $fixnum.Int64 get indexBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set indexBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIndexBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearIndexBytes() => $_clearField(3);

  /// Total bytes on disk, when the server reports a total that differs from data plus indexes.
  @$pb.TagNumber(4)
  $fixnum.Int64 get totalBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set totalBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalBytes() => $_clearField(4);

  /// Engine-specific entries in display order.
  @$pb.TagNumber(5)
  $pb.PbList<StatEntry> get extras => $_getList(4);
}

/// GetStatsRequest selects the table or collection.
class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    return result;
  }

  GetStatsRequest._();

  factory GetStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatsRequest))
          as GetStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsRequest create() => GetStatsRequest._();
  @$core.override
  GetStatsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(create);
  static GetStatsRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table or collection (Mongo: database + table as collection, schema empty).
  @$pb.TagNumber(2)
  $1.TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureTableRef() => $_ensure(1);
}

/// GetStatsResponse carries the statistics or an error.
class GetStatsResponse extends $pb.GeneratedMessage {
  factory GetStatsResponse({
    TableStats? stats,
    $2.AdminError? error,
  }) {
    final result = create();
    if (stats != null) result.stats = stats;
    if (error != null) result.error = error;
    return result;
  }

  GetStatsResponse._();

  factory GetStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<TableStats>(1, _omitFieldNames ? '' : 'stats',
        subBuilder: TableStats.create)
    ..aOM<$2.AdminError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse copyWith(void Function(GetStatsResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatsResponse))
          as GetStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsResponse create() => GetStatsResponse._();
  @$core.override
  GetStatsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetStatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStatsResponse>(create);
  static GetStatsResponse? _defaultInstance;

  /// Statistics; unset when error is set.
  @$pb.TagNumber(1)
  TableStats get stats => $_getN(0);
  @$pb.TagNumber(1)
  set stats(TableStats value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStats() => $_has(0);
  @$pb.TagNumber(1)
  void clearStats() => $_clearField(1);
  @$pb.TagNumber(1)
  TableStats ensureStats() => $_ensure(0);

  /// Set when the call failed.
  @$pb.TagNumber(2)
  $2.AdminError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($2.AdminError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.AdminError ensureError() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
