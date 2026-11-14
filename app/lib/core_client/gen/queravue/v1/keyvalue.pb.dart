// This is a generated file - do not edit.
//
// Generated from queravue/v1/keyvalue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'keyvalue.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'keyvalue.pbenum.dart';

/// KeyValueError describes why a call did nothing or stopped early.
class KeyValueError extends $pb.GeneratedMessage {
  factory KeyValueError({
    KeyValueErrorKind? kind,
    $core.String? message,
    $core.String? operation,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (operation != null) result.operation = operation;
    return result;
  }

  KeyValueError._();

  factory KeyValueError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KeyValueError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyValueError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<KeyValueErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: KeyValueErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'operation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyValueError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyValueError copyWith(void Function(KeyValueError) updates) =>
      super.copyWith((message) => updates(message as KeyValueError))
          as KeyValueError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KeyValueError create() => KeyValueError._();
  @$core.override
  KeyValueError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KeyValueError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyValueError>(create);
  static KeyValueError? _defaultInstance;

  /// Failure category.
  @$pb.TagNumber(1)
  KeyValueErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(KeyValueErrorKind value) => $_setField(1, value);
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

  /// For CONFIRMATION_REQUIRED: what needs confirming, for example
  /// "FLUSHDB on db 0" or "delete 120 keys".
  @$pb.TagNumber(3)
  $core.String get operation => $_getSZ(2);
  @$pb.TagNumber(3)
  set operation($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOperation() => $_has(2);
  @$pb.TagNumber(3)
  void clearOperation() => $_clearField(3);
}

/// KvDatabase is one logical database.
class KvDatabase extends $pb.GeneratedMessage {
  factory KvDatabase({
    $core.int? index,
    $fixnum.Int64? keyCount,
    $fixnum.Int64? expiringCount,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (keyCount != null) result.keyCount = keyCount;
    if (expiringCount != null) result.expiringCount = expiringCount;
    return result;
  }

  KvDatabase._();

  factory KvDatabase.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KvDatabase.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KvDatabase',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'keyCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expiringCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KvDatabase clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KvDatabase copyWith(void Function(KvDatabase) updates) =>
      super.copyWith((message) => updates(message as KvDatabase)) as KvDatabase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KvDatabase create() => KvDatabase._();
  @$core.override
  KvDatabase createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KvDatabase getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KvDatabase>(create);
  static KvDatabase? _defaultInstance;

  /// Database index.
  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  /// Number of keys from INFO keyspace.
  @$pb.TagNumber(2)
  $fixnum.Int64 get keyCount => $_getI64(1);
  @$pb.TagNumber(2)
  set keyCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKeyCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearKeyCount() => $_clearField(2);

  /// Number of keys with a TTL.
  @$pb.TagNumber(3)
  $fixnum.Int64 get expiringCount => $_getI64(2);
  @$pb.TagNumber(3)
  set expiringCount($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiringCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiringCount() => $_clearField(3);
}

/// ListKvDatabasesRequest names the session.
class ListKvDatabasesRequest extends $pb.GeneratedMessage {
  factory ListKvDatabasesRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ListKvDatabasesRequest._();

  factory ListKvDatabasesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKvDatabasesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKvDatabasesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKvDatabasesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKvDatabasesRequest copyWith(
          void Function(ListKvDatabasesRequest) updates) =>
      super.copyWith((message) => updates(message as ListKvDatabasesRequest))
          as ListKvDatabasesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKvDatabasesRequest create() => ListKvDatabasesRequest._();
  @$core.override
  ListKvDatabasesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKvDatabasesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKvDatabasesRequest>(create);
  static ListKvDatabasesRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

/// ListKvDatabasesResponse lists databases that hold keys, plus db 0.
class ListKvDatabasesResponse extends $pb.GeneratedMessage {
  factory ListKvDatabasesResponse({
    $core.Iterable<KvDatabase>? databases,
    $core.int? databaseLimit,
    KeyValueError? error,
  }) {
    final result = create();
    if (databases != null) result.databases.addAll(databases);
    if (databaseLimit != null) result.databaseLimit = databaseLimit;
    if (error != null) result.error = error;
    return result;
  }

  ListKvDatabasesResponse._();

  factory ListKvDatabasesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListKvDatabasesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListKvDatabasesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<KvDatabase>(1, _omitFieldNames ? '' : 'databases',
        subBuilder: KvDatabase.create)
    ..aI(2, _omitFieldNames ? '' : 'databaseLimit',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<KeyValueError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKvDatabasesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListKvDatabasesResponse copyWith(
          void Function(ListKvDatabasesResponse) updates) =>
      super.copyWith((message) => updates(message as ListKvDatabasesResponse))
          as ListKvDatabasesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListKvDatabasesResponse create() => ListKvDatabasesResponse._();
  @$core.override
  ListKvDatabasesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListKvDatabasesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListKvDatabasesResponse>(create);
  static ListKvDatabasesResponse? _defaultInstance;

  /// Databases.
  @$pb.TagNumber(1)
  $pb.PbList<KvDatabase> get databases => $_getList(0);

  /// Number of databases the server allows. 1 on a cluster.
  @$pb.TagNumber(2)
  $core.int get databaseLimit => $_getIZ(1);
  @$pb.TagNumber(2)
  set databaseLimit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabaseLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabaseLimit() => $_clearField(2);

  /// Set when the call failed.
  @$pb.TagNumber(3)
  KeyValueError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(KeyValueError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  KeyValueError ensureError() => $_ensure(2);
}

/// ScanKeysRequest starts a scan.
class ScanKeysRequest extends $pb.GeneratedMessage {
  factory ScanKeysRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.String? pattern,
    KeyType? typeFilter,
    $core.int? pageSize,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (pattern != null) result.pattern = pattern;
    if (typeFilter != null) result.typeFilter = typeFilter;
    if (pageSize != null) result.pageSize = pageSize;
    return result;
  }

  ScanKeysRequest._();

  factory ScanKeysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanKeysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanKeysRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'pattern')
    ..aE<KeyType>(4, _omitFieldNames ? '' : 'typeFilter',
        enumValues: KeyType.values)
    ..aI(5, _omitFieldNames ? '' : 'pageSize', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanKeysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanKeysRequest copyWith(void Function(ScanKeysRequest) updates) =>
      super.copyWith((message) => updates(message as ScanKeysRequest))
          as ScanKeysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanKeysRequest create() => ScanKeysRequest._();
  @$core.override
  ScanKeysRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanKeysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanKeysRequest>(create);
  static ScanKeysRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// MATCH pattern. Empty means "*".
  @$pb.TagNumber(3)
  $core.String get pattern => $_getSZ(2);
  @$pb.TagNumber(3)
  set pattern($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPattern() => $_has(2);
  @$pb.TagNumber(3)
  void clearPattern() => $_clearField(3);

  /// Only keys of this type. Unspecified means any.
  @$pb.TagNumber(4)
  KeyType get typeFilter => $_getN(3);
  @$pb.TagNumber(4)
  set typeFilter(KeyType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTypeFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearTypeFilter() => $_clearField(4);

  /// COUNT hint and page size. 0 means 500.
  @$pb.TagNumber(5)
  $core.int get pageSize => $_getIZ(4);
  @$pb.TagNumber(5)
  set pageSize($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPageSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearPageSize() => $_clearField(5);
}

/// KeySummary is one scanned key.
class KeySummary extends $pb.GeneratedMessage {
  factory KeySummary({
    $core.List<$core.int>? key,
    KeyType? type,
    $fixnum.Int64? ttlMs,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (type != null) result.type = type;
    if (ttlMs != null) result.ttlMs = ttlMs;
    return result;
  }

  KeySummary._();

  factory KeySummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KeySummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeySummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aE<KeyType>(2, _omitFieldNames ? '' : 'type', enumValues: KeyType.values)
    ..aInt64(3, _omitFieldNames ? '' : 'ttlMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeySummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeySummary copyWith(void Function(KeySummary) updates) =>
      super.copyWith((message) => updates(message as KeySummary)) as KeySummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KeySummary create() => KeySummary._();
  @$core.override
  KeySummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KeySummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeySummary>(create);
  static KeySummary? _defaultInstance;

  /// Key bytes; binary keys are not valid UTF-8.
  @$pb.TagNumber(1)
  $core.List<$core.int> get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  /// Type if the scan asked the server for it.
  @$pb.TagNumber(2)
  KeyType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(KeyType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// Remaining time to live in milliseconds. -1 means none, -2 unknown.
  @$pb.TagNumber(3)
  $fixnum.Int64 get ttlMs => $_getI64(2);
  @$pb.TagNumber(3)
  set ttlMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTtlMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearTtlMs() => $_clearField(3);
}

/// ScanKeysResponse is one page of keys.
class ScanKeysResponse extends $pb.GeneratedMessage {
  factory ScanKeysResponse({
    $core.Iterable<KeySummary>? keys,
    $fixnum.Int64? scanned,
    $core.bool? done,
    KeyValueError? error,
  }) {
    final result = create();
    if (keys != null) result.keys.addAll(keys);
    if (scanned != null) result.scanned = scanned;
    if (done != null) result.done = done;
    if (error != null) result.error = error;
    return result;
  }

  ScanKeysResponse._();

  factory ScanKeysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanKeysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanKeysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<KeySummary>(1, _omitFieldNames ? '' : 'keys',
        subBuilder: KeySummary.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'scanned', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'done')
    ..aOM<KeyValueError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanKeysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanKeysResponse copyWith(void Function(ScanKeysResponse) updates) =>
      super.copyWith((message) => updates(message as ScanKeysResponse))
          as ScanKeysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanKeysResponse create() => ScanKeysResponse._();
  @$core.override
  ScanKeysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanKeysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanKeysResponse>(create);
  static ScanKeysResponse? _defaultInstance;

  /// Keys of this page.
  @$pb.TagNumber(1)
  $pb.PbList<KeySummary> get keys => $_getList(0);

  /// Keys scanned so far.
  @$pb.TagNumber(2)
  $fixnum.Int64 get scanned => $_getI64(1);
  @$pb.TagNumber(2)
  set scanned($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScanned() => $_has(1);
  @$pb.TagNumber(2)
  void clearScanned() => $_clearField(2);

  /// Set on the last message.
  @$pb.TagNumber(3)
  $core.bool get done => $_getBF(2);
  @$pb.TagNumber(3)
  set done($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDone() => $_has(2);
  @$pb.TagNumber(3)
  void clearDone() => $_clearField(3);

  /// Set when the scan failed.
  @$pb.TagNumber(4)
  KeyValueError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(KeyValueError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  KeyValueError ensureError() => $_ensure(3);
}

/// GetKeyInfoRequest selects a key.
class GetKeyInfoRequest extends $pb.GeneratedMessage {
  factory GetKeyInfoRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.List<$core.int>? key,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (key != null) result.key = key;
    return result;
  }

  GetKeyInfoRequest._();

  factory GetKeyInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetKeyInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyInfoRequest copyWith(void Function(GetKeyInfoRequest) updates) =>
      super.copyWith((message) => updates(message as GetKeyInfoRequest))
          as GetKeyInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetKeyInfoRequest create() => GetKeyInfoRequest._();
  @$core.override
  GetKeyInfoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetKeyInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyInfoRequest>(create);
  static GetKeyInfoRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Key bytes.
  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);
}

/// GetKeyInfoResponse describes a key.
class GetKeyInfoResponse extends $pb.GeneratedMessage {
  factory GetKeyInfoResponse({
    KeyType? type,
    $fixnum.Int64? ttlMs,
    $core.String? encoding,
    $fixnum.Int64? length,
    $fixnum.Int64? memoryBytes,
    $core.bool? bigKey,
    KeyValueError? error,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (ttlMs != null) result.ttlMs = ttlMs;
    if (encoding != null) result.encoding = encoding;
    if (length != null) result.length = length;
    if (memoryBytes != null) result.memoryBytes = memoryBytes;
    if (bigKey != null) result.bigKey = bigKey;
    if (error != null) result.error = error;
    return result;
  }

  GetKeyInfoResponse._();

  factory GetKeyInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetKeyInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<KeyType>(1, _omitFieldNames ? '' : 'type', enumValues: KeyType.values)
    ..aInt64(2, _omitFieldNames ? '' : 'ttlMs')
    ..aOS(3, _omitFieldNames ? '' : 'encoding')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'memoryBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(6, _omitFieldNames ? '' : 'bigKey')
    ..aOM<KeyValueError>(7, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyInfoResponse copyWith(void Function(GetKeyInfoResponse) updates) =>
      super.copyWith((message) => updates(message as GetKeyInfoResponse))
          as GetKeyInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetKeyInfoResponse create() => GetKeyInfoResponse._();
  @$core.override
  GetKeyInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetKeyInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyInfoResponse>(create);
  static GetKeyInfoResponse? _defaultInstance;

  /// Type.
  @$pb.TagNumber(1)
  KeyType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(KeyType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// Remaining time to live in milliseconds. -1 means none.
  @$pb.TagNumber(2)
  $fixnum.Int64 get ttlMs => $_getI64(1);
  @$pb.TagNumber(2)
  set ttlMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTtlMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTtlMs() => $_clearField(2);

  /// Internal encoding, e.g. "listpack".
  @$pb.TagNumber(3)
  $core.String get encoding => $_getSZ(2);
  @$pb.TagNumber(3)
  set encoding($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoding() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoding() => $_clearField(3);

  /// Element count, or byte length for strings.
  @$pb.TagNumber(4)
  $fixnum.Int64 get length => $_getI64(3);
  @$pb.TagNumber(4)
  set length($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearLength() => $_clearField(4);

  /// MEMORY USAGE in bytes. Unset where not allowed.
  @$pb.TagNumber(5)
  $fixnum.Int64 get memoryBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set memoryBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMemoryBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemoryBytes() => $_clearField(5);

  /// Whether the key is large enough that reading it whole would be unsafe.
  @$pb.TagNumber(6)
  $core.bool get bigKey => $_getBF(5);
  @$pb.TagNumber(6)
  set bigKey($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBigKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearBigKey() => $_clearField(6);

  /// Set when the call failed.
  @$pb.TagNumber(7)
  KeyValueError get error => $_getN(6);
  @$pb.TagNumber(7)
  set error(KeyValueError value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
  @$pb.TagNumber(7)
  KeyValueError ensureError() => $_ensure(6);
}

/// ReadValueRequest asks for one page of a value.
class ReadValueRequest extends $pb.GeneratedMessage {
  factory ReadValueRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.List<$core.int>? key,
    $core.String? cursor,
    $core.int? pageSize,
    $core.int? maxBytes,
    $core.bool? reverse,
    $core.bool? orderByScore,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (key != null) result.key = key;
    if (cursor != null) result.cursor = cursor;
    if (pageSize != null) result.pageSize = pageSize;
    if (maxBytes != null) result.maxBytes = maxBytes;
    if (reverse != null) result.reverse = reverse;
    if (orderByScore != null) result.orderByScore = orderByScore;
    return result;
  }

  ReadValueRequest._();

  factory ReadValueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadValueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadValueRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'cursor')
    ..aI(5, _omitFieldNames ? '' : 'pageSize', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'maxBytes', fieldType: $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'reverse')
    ..aOB(8, _omitFieldNames ? '' : 'orderByScore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadValueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadValueRequest copyWith(void Function(ReadValueRequest) updates) =>
      super.copyWith((message) => updates(message as ReadValueRequest))
          as ReadValueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadValueRequest create() => ReadValueRequest._();
  @$core.override
  ReadValueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadValueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadValueRequest>(create);
  static ReadValueRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Key bytes.
  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);

  /// Opaque cursor from the previous page. Empty starts at the beginning
  /// (for streams: the range start).
  @$pb.TagNumber(4)
  $core.String get cursor => $_getSZ(3);
  @$pb.TagNumber(4)
  set cursor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearCursor() => $_clearField(4);

  /// Page size. 0 means 200.
  @$pb.TagNumber(5)
  $core.int get pageSize => $_getIZ(4);
  @$pb.TagNumber(5)
  set pageSize($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPageSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearPageSize() => $_clearField(5);

  /// Strings: bytes to read at most. 0 means 1 MiB.
  @$pb.TagNumber(6)
  $core.int get maxBytes => $_getIZ(5);
  @$pb.TagNumber(6)
  set maxBytes($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxBytes() => $_clearField(6);

  /// Lists and sorted sets: read from the end.
  @$pb.TagNumber(7)
  $core.bool get reverse => $_getBF(6);
  @$pb.TagNumber(7)
  set reverse($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReverse() => $_has(6);
  @$pb.TagNumber(7)
  void clearReverse() => $_clearField(7);

  /// Sorted sets: order by score (otherwise ZSCAN order).
  @$pb.TagNumber(8)
  $core.bool get orderByScore => $_getBF(7);
  @$pb.TagNumber(8)
  set orderByScore($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOrderByScore() => $_has(7);
  @$pb.TagNumber(8)
  void clearOrderByScore() => $_clearField(8);
}

/// HashEntry is a field and its value.
class HashEntry extends $pb.GeneratedMessage {
  factory HashEntry({
    $core.List<$core.int>? field_1,
    $core.List<$core.int>? value,
  }) {
    final result = create();
    if (field_1 != null) result.field_1 = field_1;
    if (value != null) result.value = value;
    return result;
  }

  HashEntry._();

  factory HashEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HashEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HashEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'field', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HashEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HashEntry copyWith(void Function(HashEntry) updates) =>
      super.copyWith((message) => updates(message as HashEntry)) as HashEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HashEntry create() => HashEntry._();
  @$core.override
  HashEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HashEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HashEntry>(create);
  static HashEntry? _defaultInstance;

  /// Field name.
  @$pb.TagNumber(1)
  $core.List<$core.int> get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => $_clearField(1);

  /// Value.
  @$pb.TagNumber(2)
  $core.List<$core.int> get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// ZsetEntry is a member with its score.
class ZsetEntry extends $pb.GeneratedMessage {
  factory ZsetEntry({
    $core.List<$core.int>? member,
    $core.double? score,
  }) {
    final result = create();
    if (member != null) result.member = member;
    if (score != null) result.score = score;
    return result;
  }

  ZsetEntry._();

  factory ZsetEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ZsetEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ZsetEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'member', $pb.PbFieldType.OY)
    ..aD(2, _omitFieldNames ? '' : 'score')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZsetEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZsetEntry copyWith(void Function(ZsetEntry) updates) =>
      super.copyWith((message) => updates(message as ZsetEntry)) as ZsetEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ZsetEntry create() => ZsetEntry._();
  @$core.override
  ZsetEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ZsetEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ZsetEntry>(create);
  static ZsetEntry? _defaultInstance;

  /// Member.
  @$pb.TagNumber(1)
  $core.List<$core.int> get member => $_getN(0);
  @$pb.TagNumber(1)
  set member($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMember() => $_has(0);
  @$pb.TagNumber(1)
  void clearMember() => $_clearField(1);

  /// Score.
  @$pb.TagNumber(2)
  $core.double get score => $_getN(1);
  @$pb.TagNumber(2)
  set score($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearScore() => $_clearField(2);
}

/// StreamEntry is one stream entry.
class StreamEntry extends $pb.GeneratedMessage {
  factory StreamEntry({
    $core.String? id,
    $core.Iterable<HashEntry>? fields,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (fields != null) result.fields.addAll(fields);
    return result;
  }

  StreamEntry._();

  factory StreamEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPM<HashEntry>(2, _omitFieldNames ? '' : 'fields',
        subBuilder: HashEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamEntry copyWith(void Function(StreamEntry) updates) =>
      super.copyWith((message) => updates(message as StreamEntry))
          as StreamEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamEntry create() => StreamEntry._();
  @$core.override
  StreamEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamEntry>(create);
  static StreamEntry? _defaultInstance;

  /// Entry id, e.g. "1700000000000-0".
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Field/value pairs in order.
  @$pb.TagNumber(2)
  $pb.PbList<HashEntry> get fields => $_getList(1);
}

/// ListValues is a page of list elements.
class ListValues extends $pb.GeneratedMessage {
  factory ListValues({
    $core.Iterable<$core.List<$core.int>>? items,
    $fixnum.Int64? startIndex,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    if (startIndex != null) result.startIndex = startIndex;
    return result;
  }

  ListValues._();

  factory ListValues.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListValues.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListValues',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'startIndex', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListValues clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListValues copyWith(void Function(ListValues) updates) =>
      super.copyWith((message) => updates(message as ListValues)) as ListValues;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListValues create() => ListValues._();
  @$core.override
  ListValues createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListValues getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListValues>(create);
  static ListValues? _defaultInstance;

  /// Elements.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get items => $_getList(0);

  /// Index of the first element of the page.
  @$pb.TagNumber(2)
  $fixnum.Int64 get startIndex => $_getI64(1);
  @$pb.TagNumber(2)
  set startIndex($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartIndex() => $_clearField(2);
}

/// SetValues is a page of set members.
class SetValues extends $pb.GeneratedMessage {
  factory SetValues({
    $core.Iterable<$core.List<$core.int>>? members,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    return result;
  }

  SetValues._();

  factory SetValues.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetValues.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetValues',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValues clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValues copyWith(void Function(SetValues) updates) =>
      super.copyWith((message) => updates(message as SetValues)) as SetValues;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetValues create() => SetValues._();
  @$core.override
  SetValues createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetValues getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetValues>(create);
  static SetValues? _defaultInstance;

  /// Members.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get members => $_getList(0);
}

/// HashValues is a page of hash entries.
class HashValues extends $pb.GeneratedMessage {
  factory HashValues({
    $core.Iterable<HashEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  HashValues._();

  factory HashValues.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HashValues.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HashValues',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<HashEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: HashEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HashValues clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HashValues copyWith(void Function(HashValues) updates) =>
      super.copyWith((message) => updates(message as HashValues)) as HashValues;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HashValues create() => HashValues._();
  @$core.override
  HashValues createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HashValues getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HashValues>(create);
  static HashValues? _defaultInstance;

  /// Entries.
  @$pb.TagNumber(1)
  $pb.PbList<HashEntry> get entries => $_getList(0);
}

/// ZsetValues is a page of sorted set entries.
class ZsetValues extends $pb.GeneratedMessage {
  factory ZsetValues({
    $core.Iterable<ZsetEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  ZsetValues._();

  factory ZsetValues.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ZsetValues.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ZsetValues',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<ZsetEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ZsetEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZsetValues clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZsetValues copyWith(void Function(ZsetValues) updates) =>
      super.copyWith((message) => updates(message as ZsetValues)) as ZsetValues;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ZsetValues create() => ZsetValues._();
  @$core.override
  ZsetValues createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ZsetValues getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ZsetValues>(create);
  static ZsetValues? _defaultInstance;

  /// Entries.
  @$pb.TagNumber(1)
  $pb.PbList<ZsetEntry> get entries => $_getList(0);
}

/// StreamValues is a page of stream entries.
class StreamValues extends $pb.GeneratedMessage {
  factory StreamValues({
    $core.Iterable<StreamEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  StreamValues._();

  factory StreamValues.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamValues.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamValues',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<StreamEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: StreamEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamValues clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamValues copyWith(void Function(StreamValues) updates) =>
      super.copyWith((message) => updates(message as StreamValues))
          as StreamValues;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamValues create() => StreamValues._();
  @$core.override
  StreamValues createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamValues getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamValues>(create);
  static StreamValues? _defaultInstance;

  /// Entries.
  @$pb.TagNumber(1)
  $pb.PbList<StreamEntry> get entries => $_getList(0);
}

/// StringValue is a string value, possibly truncated.
class StringValue extends $pb.GeneratedMessage {
  factory StringValue({
    $core.List<$core.int>? data,
    $fixnum.Int64? totalBytes,
    $core.bool? binary,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (binary != null) result.binary = binary;
    return result;
  }

  StringValue._();

  factory StringValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StringValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StringValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'binary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StringValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StringValue copyWith(void Function(StringValue) updates) =>
      super.copyWith((message) => updates(message as StringValue))
          as StringValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringValue create() => StringValue._();
  @$core.override
  StringValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StringValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StringValue>(create);
  static StringValue? _defaultInstance;

  /// Bytes read, at most max_bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  /// Total size of the value.
  @$pb.TagNumber(2)
  $fixnum.Int64 get totalBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set totalBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalBytes() => $_clearField(2);

  /// Whether the value is not valid UTF-8.
  @$pb.TagNumber(3)
  $core.bool get binary => $_getBF(2);
  @$pb.TagNumber(3)
  set binary($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBinary() => $_has(2);
  @$pb.TagNumber(3)
  void clearBinary() => $_clearField(3);
}

/// JsonValue is a ReJSON document.
class JsonValue extends $pb.GeneratedMessage {
  factory JsonValue({
    $core.String? json,
  }) {
    final result = create();
    if (json != null) result.json = json;
    return result;
  }

  JsonValue._();

  factory JsonValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JsonValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JsonValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'json')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JsonValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JsonValue copyWith(void Function(JsonValue) updates) =>
      super.copyWith((message) => updates(message as JsonValue)) as JsonValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JsonValue create() => JsonValue._();
  @$core.override
  JsonValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JsonValue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JsonValue>(create);
  static JsonValue? _defaultInstance;

  /// Document as JSON text.
  @$pb.TagNumber(1)
  $core.String get json => $_getSZ(0);
  @$pb.TagNumber(1)
  set json($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearJson() => $_clearField(1);
}

/// HyperLogLogValue is the cardinality estimate.
class HyperLogLogValue extends $pb.GeneratedMessage {
  factory HyperLogLogValue({
    $fixnum.Int64? count,
  }) {
    final result = create();
    if (count != null) result.count = count;
    return result;
  }

  HyperLogLogValue._();

  factory HyperLogLogValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HyperLogLogValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HyperLogLogValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HyperLogLogValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HyperLogLogValue copyWith(void Function(HyperLogLogValue) updates) =>
      super.copyWith((message) => updates(message as HyperLogLogValue))
          as HyperLogLogValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HyperLogLogValue create() => HyperLogLogValue._();
  @$core.override
  HyperLogLogValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HyperLogLogValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HyperLogLogValue>(create);
  static HyperLogLogValue? _defaultInstance;

  /// PFCOUNT result.
  @$pb.TagNumber(1)
  $fixnum.Int64 get count => $_getI64(0);
  @$pb.TagNumber(1)
  set count($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);
}

enum ReadValueResponse_Value {
  stringValue,
  hash,
  list,
  set,
  zset,
  stream,
  json,
  hyperloglog,
  notSet
}

/// ReadValueResponse is one page of a value.
class ReadValueResponse extends $pb.GeneratedMessage {
  factory ReadValueResponse({
    KeyType? type,
    StringValue? stringValue,
    HashValues? hash,
    ListValues? list,
    SetValues? set,
    ZsetValues? zset,
    StreamValues? stream,
    JsonValue? json,
    HyperLogLogValue? hyperloglog,
    $core.String? nextCursor,
    KeyValueError? error,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (stringValue != null) result.stringValue = stringValue;
    if (hash != null) result.hash = hash;
    if (list != null) result.list = list;
    if (set != null) result.set = set;
    if (zset != null) result.zset = zset;
    if (stream != null) result.stream = stream;
    if (json != null) result.json = json;
    if (hyperloglog != null) result.hyperloglog = hyperloglog;
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (error != null) result.error = error;
    return result;
  }

  ReadValueResponse._();

  factory ReadValueResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadValueResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ReadValueResponse_Value>
      _ReadValueResponse_ValueByTag = {
    2: ReadValueResponse_Value.stringValue,
    3: ReadValueResponse_Value.hash,
    4: ReadValueResponse_Value.list,
    5: ReadValueResponse_Value.set,
    6: ReadValueResponse_Value.zset,
    7: ReadValueResponse_Value.stream,
    8: ReadValueResponse_Value.json,
    9: ReadValueResponse_Value.hyperloglog,
    0: ReadValueResponse_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadValueResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8, 9])
    ..aE<KeyType>(1, _omitFieldNames ? '' : 'type', enumValues: KeyType.values)
    ..aOM<StringValue>(2, _omitFieldNames ? '' : 'stringValue',
        subBuilder: StringValue.create)
    ..aOM<HashValues>(3, _omitFieldNames ? '' : 'hash',
        subBuilder: HashValues.create)
    ..aOM<ListValues>(4, _omitFieldNames ? '' : 'list',
        subBuilder: ListValues.create)
    ..aOM<SetValues>(5, _omitFieldNames ? '' : 'set',
        subBuilder: SetValues.create)
    ..aOM<ZsetValues>(6, _omitFieldNames ? '' : 'zset',
        subBuilder: ZsetValues.create)
    ..aOM<StreamValues>(7, _omitFieldNames ? '' : 'stream',
        subBuilder: StreamValues.create)
    ..aOM<JsonValue>(8, _omitFieldNames ? '' : 'json',
        subBuilder: JsonValue.create)
    ..aOM<HyperLogLogValue>(9, _omitFieldNames ? '' : 'hyperloglog',
        subBuilder: HyperLogLogValue.create)
    ..aOS(10, _omitFieldNames ? '' : 'nextCursor')
    ..aOM<KeyValueError>(11, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadValueResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadValueResponse copyWith(void Function(ReadValueResponse) updates) =>
      super.copyWith((message) => updates(message as ReadValueResponse))
          as ReadValueResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadValueResponse create() => ReadValueResponse._();
  @$core.override
  ReadValueResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadValueResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadValueResponse>(create);
  static ReadValueResponse? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  ReadValueResponse_Value whichValue() =>
      _ReadValueResponse_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  void clearValue() => $_clearField($_whichOneof(0));

  /// Type of the key.
  @$pb.TagNumber(1)
  KeyType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(KeyType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// String.
  @$pb.TagNumber(2)
  StringValue get stringValue => $_getN(1);
  @$pb.TagNumber(2)
  set stringValue(StringValue value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStringValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearStringValue() => $_clearField(2);
  @$pb.TagNumber(2)
  StringValue ensureStringValue() => $_ensure(1);

  /// Hash.
  @$pb.TagNumber(3)
  HashValues get hash => $_getN(2);
  @$pb.TagNumber(3)
  set hash(HashValues value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearHash() => $_clearField(3);
  @$pb.TagNumber(3)
  HashValues ensureHash() => $_ensure(2);

  /// List.
  @$pb.TagNumber(4)
  ListValues get list => $_getN(3);
  @$pb.TagNumber(4)
  set list(ListValues value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasList() => $_has(3);
  @$pb.TagNumber(4)
  void clearList() => $_clearField(4);
  @$pb.TagNumber(4)
  ListValues ensureList() => $_ensure(3);

  /// Set.
  @$pb.TagNumber(5)
  SetValues get set => $_getN(4);
  @$pb.TagNumber(5)
  set set(SetValues value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSet() => $_has(4);
  @$pb.TagNumber(5)
  void clearSet() => $_clearField(5);
  @$pb.TagNumber(5)
  SetValues ensureSet() => $_ensure(4);

  /// Sorted set.
  @$pb.TagNumber(6)
  ZsetValues get zset => $_getN(5);
  @$pb.TagNumber(6)
  set zset(ZsetValues value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasZset() => $_has(5);
  @$pb.TagNumber(6)
  void clearZset() => $_clearField(6);
  @$pb.TagNumber(6)
  ZsetValues ensureZset() => $_ensure(5);

  /// Stream.
  @$pb.TagNumber(7)
  StreamValues get stream => $_getN(6);
  @$pb.TagNumber(7)
  set stream(StreamValues value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStream() => $_has(6);
  @$pb.TagNumber(7)
  void clearStream() => $_clearField(7);
  @$pb.TagNumber(7)
  StreamValues ensureStream() => $_ensure(6);

  /// ReJSON.
  @$pb.TagNumber(8)
  JsonValue get json => $_getN(7);
  @$pb.TagNumber(8)
  set json(JsonValue value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearJson() => $_clearField(8);
  @$pb.TagNumber(8)
  JsonValue ensureJson() => $_ensure(7);

  /// HyperLogLog.
  @$pb.TagNumber(9)
  HyperLogLogValue get hyperloglog => $_getN(8);
  @$pb.TagNumber(9)
  set hyperloglog(HyperLogLogValue value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasHyperloglog() => $_has(8);
  @$pb.TagNumber(9)
  void clearHyperloglog() => $_clearField(9);
  @$pb.TagNumber(9)
  HyperLogLogValue ensureHyperloglog() => $_ensure(8);

  /// Cursor for the next page. Empty when there is none.
  @$pb.TagNumber(10)
  $core.String get nextCursor => $_getSZ(9);
  @$pb.TagNumber(10)
  set nextCursor($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasNextCursor() => $_has(9);
  @$pb.TagNumber(10)
  void clearNextCursor() => $_clearField(10);

  /// Set when the call failed.
  @$pb.TagNumber(11)
  KeyValueError get error => $_getN(10);
  @$pb.TagNumber(11)
  set error(KeyValueError value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasError() => $_has(10);
  @$pb.TagNumber(11)
  void clearError() => $_clearField(11);
  @$pb.TagNumber(11)
  KeyValueError ensureError() => $_ensure(10);
}

/// SET key value.
class WriteOp_SetString extends $pb.GeneratedMessage {
  factory WriteOp_SetString({
    $core.List<$core.int>? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  WriteOp_SetString._();

  factory WriteOp_SetString.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_SetString.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.SetString',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetString clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetString copyWith(void Function(WriteOp_SetString) updates) =>
      super.copyWith((message) => updates(message as WriteOp_SetString))
          as WriteOp_SetString;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_SetString create() => WriteOp_SetString._();
  @$core.override
  WriteOp_SetString createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_SetString getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_SetString>(create);
  static WriteOp_SetString? _defaultInstance;

  /// New value.
  @$pb.TagNumber(1)
  $core.List<$core.int> get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// HSET field value.
class WriteOp_HashSet extends $pb.GeneratedMessage {
  factory WriteOp_HashSet({
    $core.List<$core.int>? field_1,
    $core.List<$core.int>? value,
  }) {
    final result = create();
    if (field_1 != null) result.field_1 = field_1;
    if (value != null) result.value = value;
    return result;
  }

  WriteOp_HashSet._();

  factory WriteOp_HashSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_HashSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.HashSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'field', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_HashSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_HashSet copyWith(void Function(WriteOp_HashSet) updates) =>
      super.copyWith((message) => updates(message as WriteOp_HashSet))
          as WriteOp_HashSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_HashSet create() => WriteOp_HashSet._();
  @$core.override
  WriteOp_HashSet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_HashSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_HashSet>(create);
  static WriteOp_HashSet? _defaultInstance;

  /// Field.
  @$pb.TagNumber(1)
  $core.List<$core.int> get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => $_clearField(1);

  /// Value.
  @$pb.TagNumber(2)
  $core.List<$core.int> get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// HDEL field.
class WriteOp_HashDelete extends $pb.GeneratedMessage {
  factory WriteOp_HashDelete({
    $core.List<$core.int>? field_1,
  }) {
    final result = create();
    if (field_1 != null) result.field_1 = field_1;
    return result;
  }

  WriteOp_HashDelete._();

  factory WriteOp_HashDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_HashDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.HashDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'field', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_HashDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_HashDelete copyWith(void Function(WriteOp_HashDelete) updates) =>
      super.copyWith((message) => updates(message as WriteOp_HashDelete))
          as WriteOp_HashDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_HashDelete create() => WriteOp_HashDelete._();
  @$core.override
  WriteOp_HashDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_HashDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_HashDelete>(create);
  static WriteOp_HashDelete? _defaultInstance;

  /// Field.
  @$pb.TagNumber(1)
  $core.List<$core.int> get field_1 => $_getN(0);
  @$pb.TagNumber(1)
  set field_1($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasField_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearField_1() => $_clearField(1);
}

/// LPUSH or RPUSH.
class WriteOp_ListPush extends $pb.GeneratedMessage {
  factory WriteOp_ListPush({
    $core.Iterable<$core.List<$core.int>>? values,
    $core.bool? atHead,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    if (atHead != null) result.atHead = atHead;
    return result;
  }

  WriteOp_ListPush._();

  factory WriteOp_ListPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_ListPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.ListPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'values', $pb.PbFieldType.PY)
    ..aOB(2, _omitFieldNames ? '' : 'atHead')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListPush copyWith(void Function(WriteOp_ListPush) updates) =>
      super.copyWith((message) => updates(message as WriteOp_ListPush))
          as WriteOp_ListPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_ListPush create() => WriteOp_ListPush._();
  @$core.override
  WriteOp_ListPush createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_ListPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_ListPush>(create);
  static WriteOp_ListPush? _defaultInstance;

  /// Values.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get values => $_getList(0);

  /// Push at the head instead of the tail.
  @$pb.TagNumber(2)
  $core.bool get atHead => $_getBF(1);
  @$pb.TagNumber(2)
  set atHead($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAtHead() => $_has(1);
  @$pb.TagNumber(2)
  void clearAtHead() => $_clearField(2);
}

/// LSET index value.
class WriteOp_ListSet extends $pb.GeneratedMessage {
  factory WriteOp_ListSet({
    $fixnum.Int64? index,
    $core.List<$core.int>? value,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (value != null) result.value = value;
    return result;
  }

  WriteOp_ListSet._();

  factory WriteOp_ListSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_ListSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.ListSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'index')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListSet copyWith(void Function(WriteOp_ListSet) updates) =>
      super.copyWith((message) => updates(message as WriteOp_ListSet))
          as WriteOp_ListSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_ListSet create() => WriteOp_ListSet._();
  @$core.override
  WriteOp_ListSet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_ListSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_ListSet>(create);
  static WriteOp_ListSet? _defaultInstance;

  /// Index.
  @$pb.TagNumber(1)
  $fixnum.Int64 get index => $_getI64(0);
  @$pb.TagNumber(1)
  set index($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  /// Value.
  @$pb.TagNumber(2)
  $core.List<$core.int> get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// LREM count value.
class WriteOp_ListRemove extends $pb.GeneratedMessage {
  factory WriteOp_ListRemove({
    $core.List<$core.int>? value,
    $fixnum.Int64? count,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (count != null) result.count = count;
    return result;
  }

  WriteOp_ListRemove._();

  factory WriteOp_ListRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_ListRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.ListRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ListRemove copyWith(void Function(WriteOp_ListRemove) updates) =>
      super.copyWith((message) => updates(message as WriteOp_ListRemove))
          as WriteOp_ListRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_ListRemove create() => WriteOp_ListRemove._();
  @$core.override
  WriteOp_ListRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_ListRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_ListRemove>(create);
  static WriteOp_ListRemove? _defaultInstance;

  /// Value to remove.
  @$pb.TagNumber(1)
  $core.List<$core.int> get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  /// Occurrences to remove; 0 removes all.
  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

/// SADD.
class WriteOp_SetAdd extends $pb.GeneratedMessage {
  factory WriteOp_SetAdd({
    $core.Iterable<$core.List<$core.int>>? members,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    return result;
  }

  WriteOp_SetAdd._();

  factory WriteOp_SetAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_SetAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.SetAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetAdd copyWith(void Function(WriteOp_SetAdd) updates) =>
      super.copyWith((message) => updates(message as WriteOp_SetAdd))
          as WriteOp_SetAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_SetAdd create() => WriteOp_SetAdd._();
  @$core.override
  WriteOp_SetAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_SetAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_SetAdd>(create);
  static WriteOp_SetAdd? _defaultInstance;

  /// Members.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get members => $_getList(0);
}

/// SREM.
class WriteOp_SetRemove extends $pb.GeneratedMessage {
  factory WriteOp_SetRemove({
    $core.Iterable<$core.List<$core.int>>? members,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    return result;
  }

  WriteOp_SetRemove._();

  factory WriteOp_SetRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_SetRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.SetRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_SetRemove copyWith(void Function(WriteOp_SetRemove) updates) =>
      super.copyWith((message) => updates(message as WriteOp_SetRemove))
          as WriteOp_SetRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_SetRemove create() => WriteOp_SetRemove._();
  @$core.override
  WriteOp_SetRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_SetRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_SetRemove>(create);
  static WriteOp_SetRemove? _defaultInstance;

  /// Members.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get members => $_getList(0);
}

/// ZADD.
class WriteOp_ZsetAdd extends $pb.GeneratedMessage {
  factory WriteOp_ZsetAdd({
    $core.Iterable<ZsetEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  WriteOp_ZsetAdd._();

  factory WriteOp_ZsetAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_ZsetAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.ZsetAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<ZsetEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ZsetEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ZsetAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ZsetAdd copyWith(void Function(WriteOp_ZsetAdd) updates) =>
      super.copyWith((message) => updates(message as WriteOp_ZsetAdd))
          as WriteOp_ZsetAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_ZsetAdd create() => WriteOp_ZsetAdd._();
  @$core.override
  WriteOp_ZsetAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_ZsetAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_ZsetAdd>(create);
  static WriteOp_ZsetAdd? _defaultInstance;

  /// Entries.
  @$pb.TagNumber(1)
  $pb.PbList<ZsetEntry> get entries => $_getList(0);
}

/// ZREM.
class WriteOp_ZsetRemove extends $pb.GeneratedMessage {
  factory WriteOp_ZsetRemove({
    $core.Iterable<$core.List<$core.int>>? members,
  }) {
    final result = create();
    if (members != null) result.members.addAll(members);
    return result;
  }

  WriteOp_ZsetRemove._();

  factory WriteOp_ZsetRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_ZsetRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.ZsetRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ZsetRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_ZsetRemove copyWith(void Function(WriteOp_ZsetRemove) updates) =>
      super.copyWith((message) => updates(message as WriteOp_ZsetRemove))
          as WriteOp_ZsetRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_ZsetRemove create() => WriteOp_ZsetRemove._();
  @$core.override
  WriteOp_ZsetRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_ZsetRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_ZsetRemove>(create);
  static WriteOp_ZsetRemove? _defaultInstance;

  /// Members.
  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get members => $_getList(0);
}

/// XADD.
class WriteOp_StreamAdd extends $pb.GeneratedMessage {
  factory WriteOp_StreamAdd({
    $core.String? id,
    $core.Iterable<HashEntry>? fields,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (fields != null) result.fields.addAll(fields);
    return result;
  }

  WriteOp_StreamAdd._();

  factory WriteOp_StreamAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_StreamAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.StreamAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPM<HashEntry>(2, _omitFieldNames ? '' : 'fields',
        subBuilder: HashEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_StreamAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_StreamAdd copyWith(void Function(WriteOp_StreamAdd) updates) =>
      super.copyWith((message) => updates(message as WriteOp_StreamAdd))
          as WriteOp_StreamAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_StreamAdd create() => WriteOp_StreamAdd._();
  @$core.override
  WriteOp_StreamAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_StreamAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_StreamAdd>(create);
  static WriteOp_StreamAdd? _defaultInstance;

  /// Entry id; "*" lets the server assign one.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Fields.
  @$pb.TagNumber(2)
  $pb.PbList<HashEntry> get fields => $_getList(1);
}

/// XDEL.
class WriteOp_StreamDelete extends $pb.GeneratedMessage {
  factory WriteOp_StreamDelete({
    $core.Iterable<$core.String>? ids,
  }) {
    final result = create();
    if (ids != null) result.ids.addAll(ids);
    return result;
  }

  WriteOp_StreamDelete._();

  factory WriteOp_StreamDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_StreamDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.StreamDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'ids')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_StreamDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_StreamDelete copyWith(void Function(WriteOp_StreamDelete) updates) =>
      super.copyWith((message) => updates(message as WriteOp_StreamDelete))
          as WriteOp_StreamDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_StreamDelete create() => WriteOp_StreamDelete._();
  @$core.override
  WriteOp_StreamDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_StreamDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_StreamDelete>(create);
  static WriteOp_StreamDelete? _defaultInstance;

  /// Entry ids.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get ids => $_getList(0);
}

/// JSON.SET.
class WriteOp_JsonSet extends $pb.GeneratedMessage {
  factory WriteOp_JsonSet({
    $core.String? path,
    $core.String? json,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (json != null) result.json = json;
    return result;
  }

  WriteOp_JsonSet._();

  factory WriteOp_JsonSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp_JsonSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp.JsonSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'json')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_JsonSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp_JsonSet copyWith(void Function(WriteOp_JsonSet) updates) =>
      super.copyWith((message) => updates(message as WriteOp_JsonSet))
          as WriteOp_JsonSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp_JsonSet create() => WriteOp_JsonSet._();
  @$core.override
  WriteOp_JsonSet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp_JsonSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteOp_JsonSet>(create);
  static WriteOp_JsonSet? _defaultInstance;

  /// Path, e.g. "$".
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// JSON text.
  @$pb.TagNumber(2)
  $core.String get json => $_getSZ(1);
  @$pb.TagNumber(2)
  set json($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearJson() => $_clearField(2);
}

enum WriteOp_Op {
  setString,
  hashSet,
  hashDelete,
  listPush,
  listSet,
  listRemove,
  setAdd,
  setRemove,
  zsetAdd,
  zsetRemove,
  streamAdd,
  streamDelete,
  jsonSet,
  notSet
}

/// WriteOp is one typed edit.
class WriteOp extends $pb.GeneratedMessage {
  factory WriteOp({
    WriteOp_SetString? setString,
    WriteOp_HashSet? hashSet,
    WriteOp_HashDelete? hashDelete,
    WriteOp_ListPush? listPush,
    WriteOp_ListSet? listSet,
    WriteOp_ListRemove? listRemove,
    WriteOp_SetAdd? setAdd,
    WriteOp_SetRemove? setRemove,
    WriteOp_ZsetAdd? zsetAdd,
    WriteOp_ZsetRemove? zsetRemove,
    WriteOp_StreamAdd? streamAdd,
    WriteOp_StreamDelete? streamDelete,
    WriteOp_JsonSet? jsonSet,
  }) {
    final result = create();
    if (setString != null) result.setString = setString;
    if (hashSet != null) result.hashSet = hashSet;
    if (hashDelete != null) result.hashDelete = hashDelete;
    if (listPush != null) result.listPush = listPush;
    if (listSet != null) result.listSet = listSet;
    if (listRemove != null) result.listRemove = listRemove;
    if (setAdd != null) result.setAdd = setAdd;
    if (setRemove != null) result.setRemove = setRemove;
    if (zsetAdd != null) result.zsetAdd = zsetAdd;
    if (zsetRemove != null) result.zsetRemove = zsetRemove;
    if (streamAdd != null) result.streamAdd = streamAdd;
    if (streamDelete != null) result.streamDelete = streamDelete;
    if (jsonSet != null) result.jsonSet = jsonSet;
    return result;
  }

  WriteOp._();

  factory WriteOp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteOp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WriteOp_Op> _WriteOp_OpByTag = {
    1: WriteOp_Op.setString,
    2: WriteOp_Op.hashSet,
    3: WriteOp_Op.hashDelete,
    4: WriteOp_Op.listPush,
    5: WriteOp_Op.listSet,
    6: WriteOp_Op.listRemove,
    7: WriteOp_Op.setAdd,
    8: WriteOp_Op.setRemove,
    9: WriteOp_Op.zsetAdd,
    10: WriteOp_Op.zsetRemove,
    11: WriteOp_Op.streamAdd,
    12: WriteOp_Op.streamDelete,
    13: WriteOp_Op.jsonSet,
    0: WriteOp_Op.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteOp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ..aOM<WriteOp_SetString>(1, _omitFieldNames ? '' : 'setString',
        subBuilder: WriteOp_SetString.create)
    ..aOM<WriteOp_HashSet>(2, _omitFieldNames ? '' : 'hashSet',
        subBuilder: WriteOp_HashSet.create)
    ..aOM<WriteOp_HashDelete>(3, _omitFieldNames ? '' : 'hashDelete',
        subBuilder: WriteOp_HashDelete.create)
    ..aOM<WriteOp_ListPush>(4, _omitFieldNames ? '' : 'listPush',
        subBuilder: WriteOp_ListPush.create)
    ..aOM<WriteOp_ListSet>(5, _omitFieldNames ? '' : 'listSet',
        subBuilder: WriteOp_ListSet.create)
    ..aOM<WriteOp_ListRemove>(6, _omitFieldNames ? '' : 'listRemove',
        subBuilder: WriteOp_ListRemove.create)
    ..aOM<WriteOp_SetAdd>(7, _omitFieldNames ? '' : 'setAdd',
        subBuilder: WriteOp_SetAdd.create)
    ..aOM<WriteOp_SetRemove>(8, _omitFieldNames ? '' : 'setRemove',
        subBuilder: WriteOp_SetRemove.create)
    ..aOM<WriteOp_ZsetAdd>(9, _omitFieldNames ? '' : 'zsetAdd',
        subBuilder: WriteOp_ZsetAdd.create)
    ..aOM<WriteOp_ZsetRemove>(10, _omitFieldNames ? '' : 'zsetRemove',
        subBuilder: WriteOp_ZsetRemove.create)
    ..aOM<WriteOp_StreamAdd>(11, _omitFieldNames ? '' : 'streamAdd',
        subBuilder: WriteOp_StreamAdd.create)
    ..aOM<WriteOp_StreamDelete>(12, _omitFieldNames ? '' : 'streamDelete',
        subBuilder: WriteOp_StreamDelete.create)
    ..aOM<WriteOp_JsonSet>(13, _omitFieldNames ? '' : 'jsonSet',
        subBuilder: WriteOp_JsonSet.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteOp copyWith(void Function(WriteOp) updates) =>
      super.copyWith((message) => updates(message as WriteOp)) as WriteOp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteOp create() => WriteOp._();
  @$core.override
  WriteOp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteOp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WriteOp>(create);
  static WriteOp? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  WriteOp_Op whichOp() => _WriteOp_OpByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  void clearOp() => $_clearField($_whichOneof(0));

  /// SET.
  @$pb.TagNumber(1)
  WriteOp_SetString get setString => $_getN(0);
  @$pb.TagNumber(1)
  set setString(WriteOp_SetString value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSetString() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetString() => $_clearField(1);
  @$pb.TagNumber(1)
  WriteOp_SetString ensureSetString() => $_ensure(0);

  /// HSET.
  @$pb.TagNumber(2)
  WriteOp_HashSet get hashSet => $_getN(1);
  @$pb.TagNumber(2)
  set hashSet(WriteOp_HashSet value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHashSet() => $_has(1);
  @$pb.TagNumber(2)
  void clearHashSet() => $_clearField(2);
  @$pb.TagNumber(2)
  WriteOp_HashSet ensureHashSet() => $_ensure(1);

  /// HDEL.
  @$pb.TagNumber(3)
  WriteOp_HashDelete get hashDelete => $_getN(2);
  @$pb.TagNumber(3)
  set hashDelete(WriteOp_HashDelete value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHashDelete() => $_has(2);
  @$pb.TagNumber(3)
  void clearHashDelete() => $_clearField(3);
  @$pb.TagNumber(3)
  WriteOp_HashDelete ensureHashDelete() => $_ensure(2);

  /// LPUSH / RPUSH.
  @$pb.TagNumber(4)
  WriteOp_ListPush get listPush => $_getN(3);
  @$pb.TagNumber(4)
  set listPush(WriteOp_ListPush value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasListPush() => $_has(3);
  @$pb.TagNumber(4)
  void clearListPush() => $_clearField(4);
  @$pb.TagNumber(4)
  WriteOp_ListPush ensureListPush() => $_ensure(3);

  /// LSET.
  @$pb.TagNumber(5)
  WriteOp_ListSet get listSet => $_getN(4);
  @$pb.TagNumber(5)
  set listSet(WriteOp_ListSet value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasListSet() => $_has(4);
  @$pb.TagNumber(5)
  void clearListSet() => $_clearField(5);
  @$pb.TagNumber(5)
  WriteOp_ListSet ensureListSet() => $_ensure(4);

  /// LREM.
  @$pb.TagNumber(6)
  WriteOp_ListRemove get listRemove => $_getN(5);
  @$pb.TagNumber(6)
  set listRemove(WriteOp_ListRemove value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasListRemove() => $_has(5);
  @$pb.TagNumber(6)
  void clearListRemove() => $_clearField(6);
  @$pb.TagNumber(6)
  WriteOp_ListRemove ensureListRemove() => $_ensure(5);

  /// SADD.
  @$pb.TagNumber(7)
  WriteOp_SetAdd get setAdd => $_getN(6);
  @$pb.TagNumber(7)
  set setAdd(WriteOp_SetAdd value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSetAdd() => $_has(6);
  @$pb.TagNumber(7)
  void clearSetAdd() => $_clearField(7);
  @$pb.TagNumber(7)
  WriteOp_SetAdd ensureSetAdd() => $_ensure(6);

  /// SREM.
  @$pb.TagNumber(8)
  WriteOp_SetRemove get setRemove => $_getN(7);
  @$pb.TagNumber(8)
  set setRemove(WriteOp_SetRemove value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSetRemove() => $_has(7);
  @$pb.TagNumber(8)
  void clearSetRemove() => $_clearField(8);
  @$pb.TagNumber(8)
  WriteOp_SetRemove ensureSetRemove() => $_ensure(7);

  /// ZADD.
  @$pb.TagNumber(9)
  WriteOp_ZsetAdd get zsetAdd => $_getN(8);
  @$pb.TagNumber(9)
  set zsetAdd(WriteOp_ZsetAdd value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasZsetAdd() => $_has(8);
  @$pb.TagNumber(9)
  void clearZsetAdd() => $_clearField(9);
  @$pb.TagNumber(9)
  WriteOp_ZsetAdd ensureZsetAdd() => $_ensure(8);

  /// ZREM.
  @$pb.TagNumber(10)
  WriteOp_ZsetRemove get zsetRemove => $_getN(9);
  @$pb.TagNumber(10)
  set zsetRemove(WriteOp_ZsetRemove value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasZsetRemove() => $_has(9);
  @$pb.TagNumber(10)
  void clearZsetRemove() => $_clearField(10);
  @$pb.TagNumber(10)
  WriteOp_ZsetRemove ensureZsetRemove() => $_ensure(9);

  /// XADD.
  @$pb.TagNumber(11)
  WriteOp_StreamAdd get streamAdd => $_getN(10);
  @$pb.TagNumber(11)
  set streamAdd(WriteOp_StreamAdd value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasStreamAdd() => $_has(10);
  @$pb.TagNumber(11)
  void clearStreamAdd() => $_clearField(11);
  @$pb.TagNumber(11)
  WriteOp_StreamAdd ensureStreamAdd() => $_ensure(10);

  /// XDEL.
  @$pb.TagNumber(12)
  WriteOp_StreamDelete get streamDelete => $_getN(11);
  @$pb.TagNumber(12)
  set streamDelete(WriteOp_StreamDelete value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasStreamDelete() => $_has(11);
  @$pb.TagNumber(12)
  void clearStreamDelete() => $_clearField(12);
  @$pb.TagNumber(12)
  WriteOp_StreamDelete ensureStreamDelete() => $_ensure(11);

  /// JSON.SET.
  @$pb.TagNumber(13)
  WriteOp_JsonSet get jsonSet => $_getN(12);
  @$pb.TagNumber(13)
  set jsonSet(WriteOp_JsonSet value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasJsonSet() => $_has(12);
  @$pb.TagNumber(13)
  void clearJsonSet() => $_clearField(13);
  @$pb.TagNumber(13)
  WriteOp_JsonSet ensureJsonSet() => $_ensure(12);
}

/// WriteValueRequest applies one edit.
class WriteValueRequest extends $pb.GeneratedMessage {
  factory WriteValueRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.List<$core.int>? key,
    WriteOp? op,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (key != null) result.key = key;
    if (op != null) result.op = op;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  WriteValueRequest._();

  factory WriteValueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteValueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteValueRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aOM<WriteOp>(4, _omitFieldNames ? '' : 'op', subBuilder: WriteOp.create)
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteValueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteValueRequest copyWith(void Function(WriteValueRequest) updates) =>
      super.copyWith((message) => updates(message as WriteValueRequest))
          as WriteValueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteValueRequest create() => WriteValueRequest._();
  @$core.override
  WriteValueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteValueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteValueRequest>(create);
  static WriteValueRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Key bytes.
  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);

  /// The edit.
  @$pb.TagNumber(4)
  WriteOp get op => $_getN(3);
  @$pb.TagNumber(4)
  set op(WriteOp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOp() => $_has(3);
  @$pb.TagNumber(4)
  void clearOp() => $_clearField(4);
  @$pb.TagNumber(4)
  WriteOp ensureOp() => $_ensure(3);

  /// Set after the user confirmed a CONFIRMATION_REQUIRED failure.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// WriteValueResponse reports the outcome.
class WriteValueResponse extends $pb.GeneratedMessage {
  factory WriteValueResponse({
    KeyValueError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  WriteValueResponse._();

  factory WriteValueResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteValueResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteValueResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<KeyValueError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteValueResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteValueResponse copyWith(void Function(WriteValueResponse) updates) =>
      super.copyWith((message) => updates(message as WriteValueResponse))
          as WriteValueResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteValueResponse create() => WriteValueResponse._();
  @$core.override
  WriteValueResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteValueResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteValueResponse>(create);
  static WriteValueResponse? _defaultInstance;

  /// Set when the edit was refused or failed.
  @$pb.TagNumber(1)
  KeyValueError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(KeyValueError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyValueError ensureError() => $_ensure(0);
}

/// RenameKeyRequest renames a key.
class RenameKeyRequest extends $pb.GeneratedMessage {
  factory RenameKeyRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.List<$core.int>? key,
    $core.List<$core.int>? newKey,
    $core.bool? overwrite,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (key != null) result.key = key;
    if (newKey != null) result.newKey = newKey;
    if (overwrite != null) result.overwrite = overwrite;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  RenameKeyRequest._();

  factory RenameKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameKeyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'newKey', $pb.PbFieldType.OY)
    ..aOB(5, _omitFieldNames ? '' : 'overwrite')
    ..aOB(6, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameKeyRequest copyWith(void Function(RenameKeyRequest) updates) =>
      super.copyWith((message) => updates(message as RenameKeyRequest))
          as RenameKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameKeyRequest create() => RenameKeyRequest._();
  @$core.override
  RenameKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameKeyRequest>(create);
  static RenameKeyRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Current key.
  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);

  /// New key.
  @$pb.TagNumber(4)
  $core.List<$core.int> get newKey => $_getN(3);
  @$pb.TagNumber(4)
  set newKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNewKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearNewKey() => $_clearField(4);

  /// Overwrite an existing new_key (RENAME instead of RENAMENX).
  @$pb.TagNumber(5)
  $core.bool get overwrite => $_getBF(4);
  @$pb.TagNumber(5)
  set overwrite($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOverwrite() => $_has(4);
  @$pb.TagNumber(5)
  void clearOverwrite() => $_clearField(5);

  /// Set after the user confirmed a CONFIRMATION_REQUIRED failure.
  @$pb.TagNumber(6)
  $core.bool get confirmed => $_getBF(5);
  @$pb.TagNumber(6)
  set confirmed($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasConfirmed() => $_has(5);
  @$pb.TagNumber(6)
  void clearConfirmed() => $_clearField(6);
}

/// RenameKeyResponse reports the outcome.
class RenameKeyResponse extends $pb.GeneratedMessage {
  factory RenameKeyResponse({
    KeyValueError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  RenameKeyResponse._();

  factory RenameKeyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameKeyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameKeyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<KeyValueError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameKeyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameKeyResponse copyWith(void Function(RenameKeyResponse) updates) =>
      super.copyWith((message) => updates(message as RenameKeyResponse))
          as RenameKeyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameKeyResponse create() => RenameKeyResponse._();
  @$core.override
  RenameKeyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameKeyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameKeyResponse>(create);
  static RenameKeyResponse? _defaultInstance;

  /// Set when the rename was refused or failed.
  @$pb.TagNumber(1)
  KeyValueError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(KeyValueError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyValueError ensureError() => $_ensure(0);
}

/// SetExpiryRequest sets or removes a TTL.
class SetExpiryRequest extends $pb.GeneratedMessage {
  factory SetExpiryRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.List<$core.int>? key,
    $fixnum.Int64? ttlMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (key != null) result.key = key;
    if (ttlMs != null) result.ttlMs = ttlMs;
    return result;
  }

  SetExpiryRequest._();

  factory SetExpiryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetExpiryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetExpiryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'ttlMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExpiryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExpiryRequest copyWith(void Function(SetExpiryRequest) updates) =>
      super.copyWith((message) => updates(message as SetExpiryRequest))
          as SetExpiryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetExpiryRequest create() => SetExpiryRequest._();
  @$core.override
  SetExpiryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetExpiryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetExpiryRequest>(create);
  static SetExpiryRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Key bytes.
  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);

  /// New TTL in milliseconds. Unset removes the TTL (PERSIST).
  @$pb.TagNumber(4)
  $fixnum.Int64 get ttlMs => $_getI64(3);
  @$pb.TagNumber(4)
  set ttlMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTtlMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTtlMs() => $_clearField(4);
}

/// SetExpiryResponse reports the outcome.
class SetExpiryResponse extends $pb.GeneratedMessage {
  factory SetExpiryResponse({
    KeyValueError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  SetExpiryResponse._();

  factory SetExpiryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetExpiryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetExpiryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<KeyValueError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExpiryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExpiryResponse copyWith(void Function(SetExpiryResponse) updates) =>
      super.copyWith((message) => updates(message as SetExpiryResponse))
          as SetExpiryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetExpiryResponse create() => SetExpiryResponse._();
  @$core.override
  SetExpiryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetExpiryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetExpiryResponse>(create);
  static SetExpiryResponse? _defaultInstance;

  /// Set when the call failed.
  @$pb.TagNumber(1)
  KeyValueError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(KeyValueError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  KeyValueError ensureError() => $_ensure(0);
}

/// DeleteKeysRequest deletes keys.
class DeleteKeysRequest extends $pb.GeneratedMessage {
  factory DeleteKeysRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.Iterable<$core.List<$core.int>>? keys,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (keys != null) result.keys.addAll(keys);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  DeleteKeysRequest._();

  factory DeleteKeysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteKeysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteKeysRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..p<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'keys', $pb.PbFieldType.PY)
    ..aOB(4, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeysRequest copyWith(void Function(DeleteKeysRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteKeysRequest))
          as DeleteKeysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteKeysRequest create() => DeleteKeysRequest._();
  @$core.override
  DeleteKeysRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteKeysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteKeysRequest>(create);
  static DeleteKeysRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Keys to delete.
  @$pb.TagNumber(3)
  $pb.PbList<$core.List<$core.int>> get keys => $_getList(2);

  /// Set after the user confirmed a CONFIRMATION_REQUIRED failure. More than
  /// one key always needs confirmation on production connections.
  @$pb.TagNumber(4)
  $core.bool get confirmed => $_getBF(3);
  @$pb.TagNumber(4)
  set confirmed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfirmed() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfirmed() => $_clearField(4);
}

/// DeleteKeysResponse reports the outcome.
class DeleteKeysResponse extends $pb.GeneratedMessage {
  factory DeleteKeysResponse({
    $fixnum.Int64? deleted,
    KeyValueError? error,
  }) {
    final result = create();
    if (deleted != null) result.deleted = deleted;
    if (error != null) result.error = error;
    return result;
  }

  DeleteKeysResponse._();

  factory DeleteKeysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteKeysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteKeysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'deleted', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<KeyValueError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteKeysResponse copyWith(void Function(DeleteKeysResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteKeysResponse))
          as DeleteKeysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteKeysResponse create() => DeleteKeysResponse._();
  @$core.override
  DeleteKeysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteKeysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteKeysResponse>(create);
  static DeleteKeysResponse? _defaultInstance;

  /// Keys actually removed.
  @$pb.TagNumber(1)
  $fixnum.Int64 get deleted => $_getI64(0);
  @$pb.TagNumber(1)
  set deleted($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeleted() => $_clearField(1);

  /// Set when the call was refused or failed.
  @$pb.TagNumber(2)
  KeyValueError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(KeyValueError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  KeyValueError ensureError() => $_ensure(1);
}

/// ExecuteCommandRequest runs one command.
class ExecuteCommandRequest extends $pb.GeneratedMessage {
  factory ExecuteCommandRequest({
    $core.String? sessionId,
    $core.int? database,
    $core.Iterable<$core.List<$core.int>>? args,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (args != null) result.args.addAll(args);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  ExecuteCommandRequest._();

  factory ExecuteCommandRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecuteCommandRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteCommandRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'database', fieldType: $pb.PbFieldType.OU3)
    ..p<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'args', $pb.PbFieldType.PY)
    ..aOB(4, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteCommandRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteCommandRequest copyWith(
          void Function(ExecuteCommandRequest) updates) =>
      super.copyWith((message) => updates(message as ExecuteCommandRequest))
          as ExecuteCommandRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecuteCommandRequest create() => ExecuteCommandRequest._();
  @$core.override
  ExecuteCommandRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecuteCommandRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteCommandRequest>(create);
  static ExecuteCommandRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database index.
  @$pb.TagNumber(2)
  $core.int get database => $_getIZ(1);
  @$pb.TagNumber(2)
  set database($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Command name and arguments, already split.
  @$pb.TagNumber(3)
  $pb.PbList<$core.List<$core.int>> get args => $_getList(2);

  /// Set after the user confirmed a CONFIRMATION_REQUIRED failure. FLUSHALL,
  /// FLUSHDB, multi-key DEL, CONFIG SET, SHUTDOWN and DEBUG need it on
  /// production connections.
  @$pb.TagNumber(4)
  $core.bool get confirmed => $_getBF(3);
  @$pb.TagNumber(4)
  set confirmed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfirmed() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfirmed() => $_clearField(4);
}

/// Key and value of a map reply.
class RespValue_MapEntry extends $pb.GeneratedMessage {
  factory RespValue_MapEntry({
    RespValue? key,
    RespValue? value,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  RespValue_MapEntry._();

  factory RespValue_MapEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespValue_MapEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespValue.MapEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<RespValue>(1, _omitFieldNames ? '' : 'key',
        subBuilder: RespValue.create)
    ..aOM<RespValue>(2, _omitFieldNames ? '' : 'value',
        subBuilder: RespValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_MapEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_MapEntry copyWith(void Function(RespValue_MapEntry) updates) =>
      super.copyWith((message) => updates(message as RespValue_MapEntry))
          as RespValue_MapEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespValue_MapEntry create() => RespValue_MapEntry._();
  @$core.override
  RespValue_MapEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespValue_MapEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespValue_MapEntry>(create);
  static RespValue_MapEntry? _defaultInstance;

  /// Key.
  @$pb.TagNumber(1)
  RespValue get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(RespValue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
  @$pb.TagNumber(1)
  RespValue ensureKey() => $_ensure(0);

  /// Value.
  @$pb.TagNumber(2)
  RespValue get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(RespValue value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  RespValue ensureValue() => $_ensure(1);
}

/// Elements of an array or set reply.
class RespValue_Items extends $pb.GeneratedMessage {
  factory RespValue_Items({
    $core.Iterable<RespValue>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  RespValue_Items._();

  factory RespValue_Items.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespValue_Items.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespValue.Items',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<RespValue>(1, _omitFieldNames ? '' : 'items',
        subBuilder: RespValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Items clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Items copyWith(void Function(RespValue_Items) updates) =>
      super.copyWith((message) => updates(message as RespValue_Items))
          as RespValue_Items;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespValue_Items create() => RespValue_Items._();
  @$core.override
  RespValue_Items createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespValue_Items getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespValue_Items>(create);
  static RespValue_Items? _defaultInstance;

  /// Elements.
  @$pb.TagNumber(1)
  $pb.PbList<RespValue> get items => $_getList(0);
}

/// Entries of a map reply.
class RespValue_Entries extends $pb.GeneratedMessage {
  factory RespValue_Entries({
    $core.Iterable<RespValue_MapEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  RespValue_Entries._();

  factory RespValue_Entries.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespValue_Entries.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespValue.Entries',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<RespValue_MapEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: RespValue_MapEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Entries clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Entries copyWith(void Function(RespValue_Entries) updates) =>
      super.copyWith((message) => updates(message as RespValue_Entries))
          as RespValue_Entries;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespValue_Entries create() => RespValue_Entries._();
  @$core.override
  RespValue_Entries createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespValue_Entries getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespValue_Entries>(create);
  static RespValue_Entries? _defaultInstance;

  /// Entries in server order.
  @$pb.TagNumber(1)
  $pb.PbList<RespValue_MapEntry> get entries => $_getList(0);
}

/// Verbatim string with its format.
class RespValue_Verbatim extends $pb.GeneratedMessage {
  factory RespValue_Verbatim({
    $core.String? format,
    $core.String? text,
  }) {
    final result = create();
    if (format != null) result.format = format;
    if (text != null) result.text = text;
    return result;
  }

  RespValue_Verbatim._();

  factory RespValue_Verbatim.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespValue_Verbatim.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespValue.Verbatim',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'format')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Verbatim clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue_Verbatim copyWith(void Function(RespValue_Verbatim) updates) =>
      super.copyWith((message) => updates(message as RespValue_Verbatim))
          as RespValue_Verbatim;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespValue_Verbatim create() => RespValue_Verbatim._();
  @$core.override
  RespValue_Verbatim createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespValue_Verbatim getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespValue_Verbatim>(create);
  static RespValue_Verbatim? _defaultInstance;

  /// Format, e.g. "txt".
  @$pb.TagNumber(1)
  $core.String get format => $_getSZ(0);
  @$pb.TagNumber(1)
  set format($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);

  /// Text.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

enum RespValue_Kind {
  stringValue,
  integer,
  doubleValue,
  boolean,
  nil,
  array,
  map,
  set,
  verbatim,
  error,
  notSet
}

/// RespValue is a typed RESP3 reply.
class RespValue extends $pb.GeneratedMessage {
  factory RespValue({
    $core.List<$core.int>? stringValue,
    $fixnum.Int64? integer,
    $core.double? doubleValue,
    $core.bool? boolean,
    $core.bool? nil,
    RespValue_Items? array,
    RespValue_Entries? map,
    RespValue_Items? set,
    RespValue_Verbatim? verbatim,
    $core.String? error,
  }) {
    final result = create();
    if (stringValue != null) result.stringValue = stringValue;
    if (integer != null) result.integer = integer;
    if (doubleValue != null) result.doubleValue = doubleValue;
    if (boolean != null) result.boolean = boolean;
    if (nil != null) result.nil = nil;
    if (array != null) result.array = array;
    if (map != null) result.map = map;
    if (set != null) result.set = set;
    if (verbatim != null) result.verbatim = verbatim;
    if (error != null) result.error = error;
    return result;
  }

  RespValue._();

  factory RespValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RespValue_Kind> _RespValue_KindByTag = {
    1: RespValue_Kind.stringValue,
    2: RespValue_Kind.integer,
    3: RespValue_Kind.doubleValue,
    4: RespValue_Kind.boolean,
    5: RespValue_Kind.nil,
    6: RespValue_Kind.array,
    7: RespValue_Kind.map,
    8: RespValue_Kind.set,
    9: RespValue_Kind.verbatim,
    10: RespValue_Kind.error,
    0: RespValue_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'stringValue', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'integer')
    ..aD(3, _omitFieldNames ? '' : 'doubleValue')
    ..aOB(4, _omitFieldNames ? '' : 'boolean')
    ..aOB(5, _omitFieldNames ? '' : 'nil')
    ..aOM<RespValue_Items>(6, _omitFieldNames ? '' : 'array',
        subBuilder: RespValue_Items.create)
    ..aOM<RespValue_Entries>(7, _omitFieldNames ? '' : 'map',
        subBuilder: RespValue_Entries.create)
    ..aOM<RespValue_Items>(8, _omitFieldNames ? '' : 'set',
        subBuilder: RespValue_Items.create)
    ..aOM<RespValue_Verbatim>(9, _omitFieldNames ? '' : 'verbatim',
        subBuilder: RespValue_Verbatim.create)
    ..aOS(10, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespValue copyWith(void Function(RespValue) updates) =>
      super.copyWith((message) => updates(message as RespValue)) as RespValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespValue create() => RespValue._();
  @$core.override
  RespValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespValue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RespValue>(create);
  static RespValue? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  RespValue_Kind whichKind() => _RespValue_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  void clearKind() => $_clearField($_whichOneof(0));

  /// Simple or bulk string.
  @$pb.TagNumber(1)
  $core.List<$core.int> get stringValue => $_getN(0);
  @$pb.TagNumber(1)
  set stringValue($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStringValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearStringValue() => $_clearField(1);

  /// Integer.
  @$pb.TagNumber(2)
  $fixnum.Int64 get integer => $_getI64(1);
  @$pb.TagNumber(2)
  set integer($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInteger() => $_has(1);
  @$pb.TagNumber(2)
  void clearInteger() => $_clearField(2);

  /// Double.
  @$pb.TagNumber(3)
  $core.double get doubleValue => $_getN(2);
  @$pb.TagNumber(3)
  set doubleValue($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDoubleValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoubleValue() => $_clearField(3);

  /// Boolean.
  @$pb.TagNumber(4)
  $core.bool get boolean => $_getBF(3);
  @$pb.TagNumber(4)
  set boolean($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBoolean() => $_has(3);
  @$pb.TagNumber(4)
  void clearBoolean() => $_clearField(4);

  /// Nil reply.
  @$pb.TagNumber(5)
  $core.bool get nil => $_getBF(4);
  @$pb.TagNumber(5)
  set nil($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNil() => $_has(4);
  @$pb.TagNumber(5)
  void clearNil() => $_clearField(5);

  /// Array.
  @$pb.TagNumber(6)
  RespValue_Items get array => $_getN(5);
  @$pb.TagNumber(6)
  set array(RespValue_Items value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasArray() => $_has(5);
  @$pb.TagNumber(6)
  void clearArray() => $_clearField(6);
  @$pb.TagNumber(6)
  RespValue_Items ensureArray() => $_ensure(5);

  /// Map.
  @$pb.TagNumber(7)
  RespValue_Entries get map => $_getN(6);
  @$pb.TagNumber(7)
  set map(RespValue_Entries value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMap() => $_has(6);
  @$pb.TagNumber(7)
  void clearMap() => $_clearField(7);
  @$pb.TagNumber(7)
  RespValue_Entries ensureMap() => $_ensure(6);

  /// Set.
  @$pb.TagNumber(8)
  RespValue_Items get set => $_getN(7);
  @$pb.TagNumber(8)
  set set(RespValue_Items value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSet() => $_has(7);
  @$pb.TagNumber(8)
  void clearSet() => $_clearField(8);
  @$pb.TagNumber(8)
  RespValue_Items ensureSet() => $_ensure(7);

  /// Verbatim string.
  @$pb.TagNumber(9)
  RespValue_Verbatim get verbatim => $_getN(8);
  @$pb.TagNumber(9)
  set verbatim(RespValue_Verbatim value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasVerbatim() => $_has(8);
  @$pb.TagNumber(9)
  void clearVerbatim() => $_clearField(9);
  @$pb.TagNumber(9)
  RespValue_Verbatim ensureVerbatim() => $_ensure(8);

  /// Error reply text from the server.
  @$pb.TagNumber(10)
  $core.String get error => $_getSZ(9);
  @$pb.TagNumber(10)
  set error($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasError() => $_has(9);
  @$pb.TagNumber(10)
  void clearError() => $_clearField(10);
}

/// ExecuteCommandResponse holds the reply.
class ExecuteCommandResponse extends $pb.GeneratedMessage {
  factory ExecuteCommandResponse({
    RespValue? reply,
    KeyValueError? error,
    $core.int? elapsedMs,
  }) {
    final result = create();
    if (reply != null) result.reply = reply;
    if (error != null) result.error = error;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    return result;
  }

  ExecuteCommandResponse._();

  factory ExecuteCommandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecuteCommandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteCommandResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<RespValue>(1, _omitFieldNames ? '' : 'reply',
        subBuilder: RespValue.create)
    ..aOM<KeyValueError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..aI(3, _omitFieldNames ? '' : 'elapsedMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteCommandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteCommandResponse copyWith(
          void Function(ExecuteCommandResponse) updates) =>
      super.copyWith((message) => updates(message as ExecuteCommandResponse))
          as ExecuteCommandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecuteCommandResponse create() => ExecuteCommandResponse._();
  @$core.override
  ExecuteCommandResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecuteCommandResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteCommandResponse>(create);
  static ExecuteCommandResponse? _defaultInstance;

  /// The server's reply. Unset when `error` is set.
  @$pb.TagNumber(1)
  RespValue get reply => $_getN(0);
  @$pb.TagNumber(1)
  set reply(RespValue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReply() => $_has(0);
  @$pb.TagNumber(1)
  void clearReply() => $_clearField(1);
  @$pb.TagNumber(1)
  RespValue ensureReply() => $_ensure(0);

  /// Set when the command was refused before it ran.
  @$pb.TagNumber(2)
  KeyValueError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(KeyValueError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  KeyValueError ensureError() => $_ensure(1);

  /// Time the command took, in milliseconds.
  @$pb.TagNumber(3)
  $core.int get elapsedMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set elapsedMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasElapsedMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearElapsedMs() => $_clearField(3);
}

/// SubscribeRequest starts a subscription.
class SubscribeRequest extends $pb.GeneratedMessage {
  factory SubscribeRequest({
    $core.String? sessionId,
    $core.Iterable<$core.String>? channels,
    $core.Iterable<$core.String>? patterns,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (channels != null) result.channels.addAll(channels);
    if (patterns != null) result.patterns.addAll(patterns);
    return result;
  }

  SubscribeRequest._();

  factory SubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..pPS(2, _omitFieldNames ? '' : 'channels')
    ..pPS(3, _omitFieldNames ? '' : 'patterns')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest copyWith(void Function(SubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeRequest))
          as SubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeRequest create() => SubscribeRequest._();
  @$core.override
  SubscribeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeRequest>(create);
  static SubscribeRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Exact channels.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get channels => $_getList(1);

  /// Glob patterns.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get patterns => $_getList(2);
}

/// SubscribeResponse is one delivered message or the end of the stream.
class SubscribeResponse extends $pb.GeneratedMessage {
  factory SubscribeResponse({
    $core.String? channel,
    $core.String? pattern,
    $core.List<$core.int>? payload,
    $fixnum.Int64? receivedUnixMs,
    KeyValueError? error,
  }) {
    final result = create();
    if (channel != null) result.channel = channel;
    if (pattern != null) result.pattern = pattern;
    if (payload != null) result.payload = payload;
    if (receivedUnixMs != null) result.receivedUnixMs = receivedUnixMs;
    if (error != null) result.error = error;
    return result;
  }

  SubscribeResponse._();

  factory SubscribeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channel')
    ..aOS(2, _omitFieldNames ? '' : 'pattern')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..aInt64(4, _omitFieldNames ? '' : 'receivedUnixMs')
    ..aOM<KeyValueError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeResponse copyWith(void Function(SubscribeResponse) updates) =>
      super.copyWith((message) => updates(message as SubscribeResponse))
          as SubscribeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeResponse create() => SubscribeResponse._();
  @$core.override
  SubscribeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeResponse>(create);
  static SubscribeResponse? _defaultInstance;

  /// Channel the message arrived on.
  @$pb.TagNumber(1)
  $core.String get channel => $_getSZ(0);
  @$pb.TagNumber(1)
  set channel($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannel() => $_clearField(1);

  /// Pattern that matched, for pattern subscriptions.
  @$pb.TagNumber(2)
  $core.String get pattern => $_getSZ(1);
  @$pb.TagNumber(2)
  set pattern($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPattern() => $_has(1);
  @$pb.TagNumber(2)
  void clearPattern() => $_clearField(2);

  /// Payload.
  @$pb.TagNumber(3)
  $core.List<$core.int> get payload => $_getN(2);
  @$pb.TagNumber(3)
  set payload($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField(3);

  /// Receive time in milliseconds since the Unix epoch.
  @$pb.TagNumber(4)
  $fixnum.Int64 get receivedUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set receivedUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReceivedUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearReceivedUnixMs() => $_clearField(4);

  /// Set when the subscription failed.
  @$pb.TagNumber(5)
  KeyValueError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(KeyValueError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  KeyValueError ensureError() => $_ensure(4);
}

/// PublishRequest publishes a message.
class PublishRequest extends $pb.GeneratedMessage {
  factory PublishRequest({
    $core.String? sessionId,
    $core.String? channel,
    $core.List<$core.int>? payload,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (channel != null) result.channel = channel;
    if (payload != null) result.payload = payload;
    return result;
  }

  PublishRequest._();

  factory PublishRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'channel')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishRequest copyWith(void Function(PublishRequest) updates) =>
      super.copyWith((message) => updates(message as PublishRequest))
          as PublishRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishRequest create() => PublishRequest._();
  @$core.override
  PublishRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublishRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishRequest>(create);
  static PublishRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Channel.
  @$pb.TagNumber(2)
  $core.String get channel => $_getSZ(1);
  @$pb.TagNumber(2)
  set channel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => $_clearField(2);

  /// Payload.
  @$pb.TagNumber(3)
  $core.List<$core.int> get payload => $_getN(2);
  @$pb.TagNumber(3)
  set payload($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField(3);
}

/// PublishResponse reports the outcome.
class PublishResponse extends $pb.GeneratedMessage {
  factory PublishResponse({
    $fixnum.Int64? receivers,
    KeyValueError? error,
  }) {
    final result = create();
    if (receivers != null) result.receivers = receivers;
    if (error != null) result.error = error;
    return result;
  }

  PublishResponse._();

  factory PublishResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'receivers', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<KeyValueError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: KeyValueError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishResponse copyWith(void Function(PublishResponse) updates) =>
      super.copyWith((message) => updates(message as PublishResponse))
          as PublishResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishResponse create() => PublishResponse._();
  @$core.override
  PublishResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublishResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishResponse>(create);
  static PublishResponse? _defaultInstance;

  /// Clients that received the message.
  @$pb.TagNumber(1)
  $fixnum.Int64 get receivers => $_getI64(0);
  @$pb.TagNumber(1)
  set receivers($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceivers() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceivers() => $_clearField(1);

  /// Set when the call failed.
  @$pb.TagNumber(2)
  KeyValueError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(KeyValueError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  KeyValueError ensureError() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
