// This is a generated file - do not edit.
//
// Generated from queravue/v1/index.proto.

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
import 'index.pbenum.dart';
import 'schema.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'index.pbenum.dart';

/// IndexKey is one part of an index key.
class IndexKey extends $pb.GeneratedMessage {
  factory IndexKey({
    $core.String? name,
    IndexKeyKind? kind,
    $core.bool? isExpression,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (isExpression != null) result.isExpression = isExpression;
    return result;
  }

  IndexKey._();

  factory IndexKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IndexKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<IndexKeyKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: IndexKeyKind.values)
    ..aOB(3, _omitFieldNames ? '' : 'isExpression')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexKey copyWith(void Function(IndexKey) updates) =>
      super.copyWith((message) => updates(message as IndexKey)) as IndexKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexKey create() => IndexKey._();
  @$core.override
  IndexKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IndexKey getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexKey>(create);
  static IndexKey? _defaultInstance;

  /// Column name, Mongo field path, or an expression for expression indexes.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Ordering or key kind.
  @$pb.TagNumber(2)
  IndexKeyKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(IndexKeyKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// True if name is an expression rather than a column. SQL only.
  @$pb.TagNumber(3)
  $core.bool get isExpression => $_getBF(2);
  @$pb.TagNumber(3)
  set isExpression($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsExpression() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsExpression() => $_clearField(3);
}

/// IndexUsage reports how often the server used an index since its counters were reset.
class IndexUsage extends $pb.GeneratedMessage {
  factory IndexUsage({
    $core.bool? available,
    $fixnum.Int64? scans,
    $fixnum.Int64? lastUsedUnixMs,
    $fixnum.Int64? trackingSinceUnixMs,
  }) {
    final result = create();
    if (available != null) result.available = available;
    if (scans != null) result.scans = scans;
    if (lastUsedUnixMs != null) result.lastUsedUnixMs = lastUsedUnixMs;
    if (trackingSinceUnixMs != null)
      result.trackingSinceUnixMs = trackingSinceUnixMs;
    return result;
  }

  IndexUsage._();

  factory IndexUsage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IndexUsage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexUsage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'scans', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(3, _omitFieldNames ? '' : 'lastUsedUnixMs')
    ..aInt64(4, _omitFieldNames ? '' : 'trackingSinceUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexUsage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexUsage copyWith(void Function(IndexUsage) updates) =>
      super.copyWith((message) => updates(message as IndexUsage)) as IndexUsage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexUsage create() => IndexUsage._();
  @$core.override
  IndexUsage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IndexUsage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IndexUsage>(create);
  static IndexUsage? _defaultInstance;

  /// False when the engine or variant keeps no usage statistics; the other fields are then unset.
  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  /// Number of times the index was used for a scan or lookup.
  @$pb.TagNumber(2)
  $fixnum.Int64 get scans => $_getI64(1);
  @$pb.TagNumber(2)
  set scans($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScans() => $_has(1);
  @$pb.TagNumber(2)
  void clearScans() => $_clearField(2);

  /// Unix milliseconds of the last use, when the server records it.
  @$pb.TagNumber(3)
  $fixnum.Int64 get lastUsedUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set lastUsedUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastUsedUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastUsedUnixMs() => $_clearField(3);

  /// Unix milliseconds since when the counters have been collecting, when known.
  @$pb.TagNumber(4)
  $fixnum.Int64 get trackingSinceUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set trackingSinceUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTrackingSinceUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrackingSinceUnixMs() => $_clearField(4);
}

/// IndexSpec is the definition of an index, used for creation and for display.
class IndexSpec extends $pb.GeneratedMessage {
  factory IndexSpec({
    $core.String? name,
    $core.Iterable<IndexKey>? keys,
    $core.bool? unique,
    $core.String? method,
    $core.String? partialPredicate,
    $core.Iterable<$core.String>? includeColumns,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? options,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (keys != null) result.keys.addAll(keys);
    if (unique != null) result.unique = unique;
    if (method != null) result.method = method;
    if (partialPredicate != null) result.partialPredicate = partialPredicate;
    if (includeColumns != null) result.includeColumns.addAll(includeColumns);
    if (options != null) result.options.addEntries(options);
    return result;
  }

  IndexSpec._();

  factory IndexSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IndexSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPM<IndexKey>(2, _omitFieldNames ? '' : 'keys',
        subBuilder: IndexKey.create)
    ..aOB(3, _omitFieldNames ? '' : 'unique')
    ..aOS(4, _omitFieldNames ? '' : 'method')
    ..aOS(5, _omitFieldNames ? '' : 'partialPredicate')
    ..pPS(6, _omitFieldNames ? '' : 'includeColumns')
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'options',
        entryClassName: 'IndexSpec.OptionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('queravue.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexSpec copyWith(void Function(IndexSpec) updates) =>
      super.copyWith((message) => updates(message as IndexSpec)) as IndexSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexSpec create() => IndexSpec._();
  @$core.override
  IndexSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IndexSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexSpec>(create);
  static IndexSpec? _defaultInstance;

  /// Index name. Empty on create lets the server choose.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Key parts in order.
  @$pb.TagNumber(2)
  $pb.PbList<IndexKey> get keys => $_getList(1);

  /// True for a unique index.
  @$pb.TagNumber(3)
  $core.bool get unique => $_getBF(2);
  @$pb.TagNumber(3)
  set unique($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnique() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnique() => $_clearField(3);

  /// Access method, for example "btree", "hash", "gin", "gist"; empty means the engine default.
  @$pb.TagNumber(4)
  $core.String get method => $_getSZ(3);
  @$pb.TagNumber(4)
  set method($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMethod() => $_has(3);
  @$pb.TagNumber(4)
  void clearMethod() => $_clearField(4);

  /// Predicate of a partial index (SQL expression, or canonical EJSON filter for Mongo); empty if none.
  @$pb.TagNumber(5)
  $core.String get partialPredicate => $_getSZ(4);
  @$pb.TagNumber(5)
  set partialPredicate($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPartialPredicate() => $_has(4);
  @$pb.TagNumber(5)
  void clearPartialPredicate() => $_clearField(5);

  /// Non-key columns stored in the index (INCLUDE). SQL only.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get includeColumns => $_getList(5);

  /// Engine-specific options, such as Mongo "expireAfterSeconds", "sparse", "collation" (EJSON value text).
  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get options => $_getMap(6);
}

/// IndexInfo is an existing index with its size and usage.
class IndexInfo extends $pb.GeneratedMessage {
  factory IndexInfo({
    IndexSpec? spec,
    $core.bool? isPrimary,
    $fixnum.Int64? sizeBytes,
    IndexUsage? usage,
  }) {
    final result = create();
    if (spec != null) result.spec = spec;
    if (isPrimary != null) result.isPrimary = isPrimary;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (usage != null) result.usage = usage;
    return result;
  }

  IndexInfo._();

  factory IndexInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IndexInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<IndexSpec>(1, _omitFieldNames ? '' : 'spec',
        subBuilder: IndexSpec.create)
    ..aOB(2, _omitFieldNames ? '' : 'isPrimary')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sizeBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<IndexUsage>(4, _omitFieldNames ? '' : 'usage',
        subBuilder: IndexUsage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexInfo copyWith(void Function(IndexInfo) updates) =>
      super.copyWith((message) => updates(message as IndexInfo)) as IndexInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexInfo create() => IndexInfo._();
  @$core.override
  IndexInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IndexInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexInfo>(create);
  static IndexInfo? _defaultInstance;

  /// Definition as the server reports it.
  @$pb.TagNumber(1)
  IndexSpec get spec => $_getN(0);
  @$pb.TagNumber(1)
  set spec(IndexSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSpec() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpec() => $_clearField(1);
  @$pb.TagNumber(1)
  IndexSpec ensureSpec() => $_ensure(0);

  /// True for the index that backs the primary key (or Mongo's _id index).
  @$pb.TagNumber(2)
  $core.bool get isPrimary => $_getBF(1);
  @$pb.TagNumber(2)
  set isPrimary($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsPrimary() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsPrimary() => $_clearField(2);

  /// Size on disk in bytes, when the server reports it.
  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  /// Usage statistics.
  @$pb.TagNumber(4)
  IndexUsage get usage => $_getN(3);
  @$pb.TagNumber(4)
  set usage(IndexUsage value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUsage() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsage() => $_clearField(4);
  @$pb.TagNumber(4)
  IndexUsage ensureUsage() => $_ensure(3);
}

/// ListIndexesRequest selects the table or collection to inspect.
class ListIndexesRequest extends $pb.GeneratedMessage {
  factory ListIndexesRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    return result;
  }

  ListIndexesRequest._();

  factory ListIndexesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListIndexesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListIndexesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListIndexesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListIndexesRequest copyWith(void Function(ListIndexesRequest) updates) =>
      super.copyWith((message) => updates(message as ListIndexesRequest))
          as ListIndexesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListIndexesRequest create() => ListIndexesRequest._();
  @$core.override
  ListIndexesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListIndexesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListIndexesRequest>(create);
  static ListIndexesRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table or collection.
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

/// ListIndexesResponse carries the indexes or an error.
class ListIndexesResponse extends $pb.GeneratedMessage {
  factory ListIndexesResponse({
    $core.Iterable<IndexInfo>? indexes,
    $2.AdminError? error,
  }) {
    final result = create();
    if (indexes != null) result.indexes.addAll(indexes);
    if (error != null) result.error = error;
    return result;
  }

  ListIndexesResponse._();

  factory ListIndexesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListIndexesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListIndexesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<IndexInfo>(1, _omitFieldNames ? '' : 'indexes',
        subBuilder: IndexInfo.create)
    ..aOM<$2.AdminError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListIndexesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListIndexesResponse copyWith(void Function(ListIndexesResponse) updates) =>
      super.copyWith((message) => updates(message as ListIndexesResponse))
          as ListIndexesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListIndexesResponse create() => ListIndexesResponse._();
  @$core.override
  ListIndexesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListIndexesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListIndexesResponse>(create);
  static ListIndexesResponse? _defaultInstance;

  /// Indexes, primary first.
  @$pb.TagNumber(1)
  $pb.PbList<IndexInfo> get indexes => $_getList(0);

  /// Set when listing failed.
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

/// CreateIndexRequest asks for a new index.
class CreateIndexRequest extends $pb.GeneratedMessage {
  factory CreateIndexRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
    IndexSpec? spec,
    $core.bool? dryRun,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (spec != null) result.spec = spec;
    if (dryRun != null) result.dryRun = dryRun;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  CreateIndexRequest._();

  factory CreateIndexRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateIndexRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateIndexRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..aOM<IndexSpec>(3, _omitFieldNames ? '' : 'spec',
        subBuilder: IndexSpec.create)
    ..aOB(4, _omitFieldNames ? '' : 'dryRun')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateIndexRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateIndexRequest copyWith(void Function(CreateIndexRequest) updates) =>
      super.copyWith((message) => updates(message as CreateIndexRequest))
          as CreateIndexRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateIndexRequest create() => CreateIndexRequest._();
  @$core.override
  CreateIndexRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateIndexRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateIndexRequest>(create);
  static CreateIndexRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table or collection.
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

  /// Index to build.
  @$pb.TagNumber(3)
  IndexSpec get spec => $_getN(2);
  @$pb.TagNumber(3)
  set spec(IndexSpec value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSpec() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpec() => $_clearField(3);
  @$pb.TagNumber(3)
  IndexSpec ensureSpec() => $_ensure(2);

  /// If true, returns the statement without running it.
  @$pb.TagNumber(4)
  $core.bool get dryRun => $_getBF(3);
  @$pb.TagNumber(4)
  set dryRun($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDryRun() => $_has(3);
  @$pb.TagNumber(4)
  void clearDryRun() => $_clearField(4);

  /// Required on connections flagged production; the core refuses without it.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// CreateIndexResponse reports the statement and outcome of a create.
class CreateIndexResponse extends $pb.GeneratedMessage {
  factory CreateIndexResponse({
    $core.String? statement,
    $core.bool? dryRun,
    $core.String? indexName,
    $2.AdminError? error,
  }) {
    final result = create();
    if (statement != null) result.statement = statement;
    if (dryRun != null) result.dryRun = dryRun;
    if (indexName != null) result.indexName = indexName;
    if (error != null) result.error = error;
    return result;
  }

  CreateIndexResponse._();

  factory CreateIndexResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateIndexResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateIndexResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'statement')
    ..aOB(2, _omitFieldNames ? '' : 'dryRun')
    ..aOS(3, _omitFieldNames ? '' : 'indexName')
    ..aOM<$2.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateIndexResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateIndexResponse copyWith(void Function(CreateIndexResponse) updates) =>
      super.copyWith((message) => updates(message as CreateIndexResponse))
          as CreateIndexResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateIndexResponse create() => CreateIndexResponse._();
  @$core.override
  CreateIndexResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateIndexResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateIndexResponse>(create);
  static CreateIndexResponse? _defaultInstance;

  /// The statement that ran (or would run on dry_run): SQL DDL or Mongo shell text.
  @$pb.TagNumber(1)
  $core.String get statement => $_getSZ(0);
  @$pb.TagNumber(1)
  set statement($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatement() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatement() => $_clearField(1);

  /// True if nothing was executed.
  @$pb.TagNumber(2)
  $core.bool get dryRun => $_getBF(1);
  @$pb.TagNumber(2)
  set dryRun($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDryRun() => $_has(1);
  @$pb.TagNumber(2)
  void clearDryRun() => $_clearField(2);

  /// Name the server gave the index; set after a real create.
  @$pb.TagNumber(3)
  $core.String get indexName => $_getSZ(2);
  @$pb.TagNumber(3)
  set indexName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIndexName() => $_has(2);
  @$pb.TagNumber(3)
  void clearIndexName() => $_clearField(3);

  /// Set when the call failed or was refused.
  @$pb.TagNumber(4)
  $2.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($2.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.AdminError ensureError() => $_ensure(3);
}

/// DropIndexRequest asks to remove an index.
class DropIndexRequest extends $pb.GeneratedMessage {
  factory DropIndexRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
    $core.String? indexName,
    $core.bool? dryRun,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (indexName != null) result.indexName = indexName;
    if (dryRun != null) result.dryRun = dryRun;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  DropIndexRequest._();

  factory DropIndexRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropIndexRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropIndexRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'indexName')
    ..aOB(4, _omitFieldNames ? '' : 'dryRun')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexRequest copyWith(void Function(DropIndexRequest) updates) =>
      super.copyWith((message) => updates(message as DropIndexRequest))
          as DropIndexRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropIndexRequest create() => DropIndexRequest._();
  @$core.override
  DropIndexRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropIndexRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropIndexRequest>(create);
  static DropIndexRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table or collection.
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

  /// Name of the index to drop.
  @$pb.TagNumber(3)
  $core.String get indexName => $_getSZ(2);
  @$pb.TagNumber(3)
  set indexName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIndexName() => $_has(2);
  @$pb.TagNumber(3)
  void clearIndexName() => $_clearField(3);

  /// If true, returns the statement without running it.
  @$pb.TagNumber(4)
  $core.bool get dryRun => $_getBF(3);
  @$pb.TagNumber(4)
  set dryRun($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDryRun() => $_has(3);
  @$pb.TagNumber(4)
  void clearDryRun() => $_clearField(4);

  /// Required on every connection: dropping an index can make queries slow until it is rebuilt.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// DropIndexResponse reports the statement and outcome of a drop.
class DropIndexResponse extends $pb.GeneratedMessage {
  factory DropIndexResponse({
    $core.String? statement,
    $core.bool? dryRun,
    $2.AdminError? error,
  }) {
    final result = create();
    if (statement != null) result.statement = statement;
    if (dryRun != null) result.dryRun = dryRun;
    if (error != null) result.error = error;
    return result;
  }

  DropIndexResponse._();

  factory DropIndexResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropIndexResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropIndexResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'statement')
    ..aOB(2, _omitFieldNames ? '' : 'dryRun')
    ..aOM<$2.AdminError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexResponse copyWith(void Function(DropIndexResponse) updates) =>
      super.copyWith((message) => updates(message as DropIndexResponse))
          as DropIndexResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropIndexResponse create() => DropIndexResponse._();
  @$core.override
  DropIndexResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropIndexResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropIndexResponse>(create);
  static DropIndexResponse? _defaultInstance;

  /// The statement that ran (or would run on dry_run).
  @$pb.TagNumber(1)
  $core.String get statement => $_getSZ(0);
  @$pb.TagNumber(1)
  set statement($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatement() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatement() => $_clearField(1);

  /// True if nothing was executed.
  @$pb.TagNumber(2)
  $core.bool get dryRun => $_getBF(1);
  @$pb.TagNumber(2)
  set dryRun($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDryRun() => $_has(1);
  @$pb.TagNumber(2)
  void clearDryRun() => $_clearField(2);

  /// Set when the call failed or was refused.
  @$pb.TagNumber(3)
  $2.AdminError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error($2.AdminError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.AdminError ensureError() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
