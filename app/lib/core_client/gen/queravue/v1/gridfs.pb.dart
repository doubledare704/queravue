// This is a generated file - do not edit.
//
// Generated from queravue/v1/gridfs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'gridfs.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'gridfs.pbenum.dart';

/// GridFsError is a typed failure. The message never contains secrets.
class GridFsError extends $pb.GeneratedMessage {
  factory GridFsError({
    GridFsErrorKind? kind,
    $core.String? message,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    return result;
  }

  GridFsError._();

  factory GridFsError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridFsError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridFsError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<GridFsErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: GridFsErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsError copyWith(void Function(GridFsError) updates) =>
      super.copyWith((message) => updates(message as GridFsError))
          as GridFsError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridFsError create() => GridFsError._();
  @$core.override
  GridFsError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridFsError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridFsError>(create);
  static GridFsError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  GridFsErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(GridFsErrorKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// Human-readable detail.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// GridFsBucket is one bucket of a database.
class GridFsBucket extends $pb.GeneratedMessage {
  factory GridFsBucket({
    $core.String? name,
    $fixnum.Int64? fileCountEstimate,
    $fixnum.Int64? totalBytes,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (fileCountEstimate != null) result.fileCountEstimate = fileCountEstimate;
    if (totalBytes != null) result.totalBytes = totalBytes;
    return result;
  }

  GridFsBucket._();

  factory GridFsBucket.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridFsBucket.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridFsBucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fileCountEstimate', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsBucket clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsBucket copyWith(void Function(GridFsBucket) updates) =>
      super.copyWith((message) => updates(message as GridFsBucket))
          as GridFsBucket;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridFsBucket create() => GridFsBucket._();
  @$core.override
  GridFsBucket createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridFsBucket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridFsBucket>(create);
  static GridFsBucket? _defaultInstance;

  /// Bucket name: the collection prefix before ".files" and ".chunks".
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Estimated number of files.
  @$pb.TagNumber(2)
  $fixnum.Int64 get fileCountEstimate => $_getI64(1);
  @$pb.TagNumber(2)
  set fileCountEstimate($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileCountEstimate() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileCountEstimate() => $_clearField(2);

  /// Sum of the files' lengths in bytes, when the server reports it cheaply.
  @$pb.TagNumber(3)
  $fixnum.Int64 get totalBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set totalBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalBytes() => $_clearField(3);
}

/// GridFsFile is one entry of a bucket's files collection.
class GridFsFile extends $pb.GeneratedMessage {
  factory GridFsFile({
    $core.String? idEjson,
    $core.String? filename,
    $fixnum.Int64? length,
    $core.int? chunkSize,
    $fixnum.Int64? uploadDateMs,
    $core.String? contentType,
    $core.String? metadataEjson,
  }) {
    final result = create();
    if (idEjson != null) result.idEjson = idEjson;
    if (filename != null) result.filename = filename;
    if (length != null) result.length = length;
    if (chunkSize != null) result.chunkSize = chunkSize;
    if (uploadDateMs != null) result.uploadDateMs = uploadDateMs;
    if (contentType != null) result.contentType = contentType;
    if (metadataEjson != null) result.metadataEjson = metadataEjson;
    return result;
  }

  GridFsFile._();

  factory GridFsFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridFsFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridFsFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idEjson')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'chunkSize', fieldType: $pb.PbFieldType.OU3)
    ..aInt64(5, _omitFieldNames ? '' : 'uploadDateMs')
    ..aOS(6, _omitFieldNames ? '' : 'contentType')
    ..aOS(7, _omitFieldNames ? '' : 'metadataEjson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsFile copyWith(void Function(GridFsFile) updates) =>
      super.copyWith((message) => updates(message as GridFsFile)) as GridFsFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridFsFile create() => GridFsFile._();
  @$core.override
  GridFsFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridFsFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridFsFile>(create);
  static GridFsFile? _defaultInstance;

  /// The file's _id as canonical EJSON.
  @$pb.TagNumber(1)
  $core.String get idEjson => $_getSZ(0);
  @$pb.TagNumber(1)
  set idEjson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdEjson() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdEjson() => $_clearField(1);

  /// Filename. Not unique: GridFS allows several files with one name.
  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => $_clearField(2);

  /// Length in bytes.
  @$pb.TagNumber(3)
  $fixnum.Int64 get length => $_getI64(2);
  @$pb.TagNumber(3)
  set length($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => $_clearField(3);

  /// Chunk size in bytes.
  @$pb.TagNumber(4)
  $core.int get chunkSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set chunkSize($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChunkSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearChunkSize() => $_clearField(4);

  /// Upload time in milliseconds since the Unix epoch.
  @$pb.TagNumber(5)
  $fixnum.Int64 get uploadDateMs => $_getI64(4);
  @$pb.TagNumber(5)
  set uploadDateMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUploadDateMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearUploadDateMs() => $_clearField(5);

  /// metadata.contentType, else the deprecated top-level contentType. Empty
  /// when neither is set.
  @$pb.TagNumber(6)
  $core.String get contentType => $_getSZ(5);
  @$pb.TagNumber(6)
  set contentType($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContentType() => $_has(5);
  @$pb.TagNumber(6)
  void clearContentType() => $_clearField(6);

  /// The metadata document as canonical EJSON, or empty when there is none.
  @$pb.TagNumber(7)
  $core.String get metadataEjson => $_getSZ(6);
  @$pb.TagNumber(7)
  set metadataEjson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMetadataEjson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetadataEjson() => $_clearField(7);
}

/// ListBucketsRequest is the input of ListBuckets.
class ListBucketsRequest extends $pb.GeneratedMessage {
  factory ListBucketsRequest({
    $core.String? sessionId,
    $core.String? database,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    return result;
  }

  ListBucketsRequest._();

  factory ListBucketsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBucketsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBucketsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBucketsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBucketsRequest copyWith(void Function(ListBucketsRequest) updates) =>
      super.copyWith((message) => updates(message as ListBucketsRequest))
          as ListBucketsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBucketsRequest create() => ListBucketsRequest._();
  @$core.override
  ListBucketsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBucketsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBucketsRequest>(create);
  static ListBucketsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);
}

/// ListBucketsResponse holds the buckets or the failure.
class ListBucketsResponse extends $pb.GeneratedMessage {
  factory ListBucketsResponse({
    $core.Iterable<GridFsBucket>? buckets,
    GridFsError? error,
  }) {
    final result = create();
    if (buckets != null) result.buckets.addAll(buckets);
    if (error != null) result.error = error;
    return result;
  }

  ListBucketsResponse._();

  factory ListBucketsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBucketsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBucketsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<GridFsBucket>(1, _omitFieldNames ? '' : 'buckets',
        subBuilder: GridFsBucket.create)
    ..aOM<GridFsError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBucketsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBucketsResponse copyWith(void Function(ListBucketsResponse) updates) =>
      super.copyWith((message) => updates(message as ListBucketsResponse))
          as ListBucketsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBucketsResponse create() => ListBucketsResponse._();
  @$core.override
  ListBucketsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBucketsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBucketsResponse>(create);
  static ListBucketsResponse? _defaultInstance;

  /// Buckets sorted by name.
  @$pb.TagNumber(1)
  $pb.PbList<GridFsBucket> get buckets => $_getList(0);

  /// Set when listing failed.
  @$pb.TagNumber(2)
  GridFsError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(GridFsError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  GridFsError ensureError() => $_ensure(1);
}

/// ListFilesRequest is the input of ListFiles.
class ListFilesRequest extends $pb.GeneratedMessage {
  factory ListFilesRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? bucket,
    $core.String? filter,
    $core.String? sort,
    $fixnum.Int64? skip,
    $fixnum.Int64? limit,
    $core.int? maxTimeMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (bucket != null) result.bucket = bucket;
    if (filter != null) result.filter = filter;
    if (sort != null) result.sort = sort;
    if (skip != null) result.skip = skip;
    if (limit != null) result.limit = limit;
    if (maxTimeMs != null) result.maxTimeMs = maxTimeMs;
    return result;
  }

  ListFilesRequest._();

  factory ListFilesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFilesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFilesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'bucket')
    ..aOS(4, _omitFieldNames ? '' : 'filter')
    ..aOS(5, _omitFieldNames ? '' : 'sort')
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'skip', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(8, _omitFieldNames ? '' : 'maxTimeMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFilesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFilesRequest copyWith(void Function(ListFilesRequest) updates) =>
      super.copyWith((message) => updates(message as ListFilesRequest))
          as ListFilesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFilesRequest create() => ListFilesRequest._();
  @$core.override
  ListFilesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFilesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFilesRequest>(create);
  static ListFilesRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Bucket name.
  @$pb.TagNumber(3)
  $core.String get bucket => $_getSZ(2);
  @$pb.TagNumber(3)
  set bucket($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBucket() => $_has(2);
  @$pb.TagNumber(3)
  void clearBucket() => $_clearField(3);

  /// Filter on the files collection as EJSON text. Empty means {}.
  @$pb.TagNumber(4)
  $core.String get filter => $_getSZ(3);
  @$pb.TagNumber(4)
  set filter($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilter() => $_clearField(4);

  /// Sort as EJSON text. Empty means natural order.
  @$pb.TagNumber(5)
  $core.String get sort => $_getSZ(4);
  @$pb.TagNumber(5)
  set sort($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSort() => $_has(4);
  @$pb.TagNumber(5)
  void clearSort() => $_clearField(5);

  /// Files to skip.
  @$pb.TagNumber(6)
  $fixnum.Int64 get skip => $_getI64(5);
  @$pb.TagNumber(6)
  set skip($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSkip() => $_has(5);
  @$pb.TagNumber(6)
  void clearSkip() => $_clearField(6);

  /// Maximum files to return. 0 means no limit.
  @$pb.TagNumber(7)
  $fixnum.Int64 get limit => $_getI64(6);
  @$pb.TagNumber(7)
  set limit($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearLimit() => $_clearField(7);

  /// Server-side time limit (maxTimeMS). 0 means the core default (30000).
  @$pb.TagNumber(8)
  $core.int get maxTimeMs => $_getIZ(7);
  @$pb.TagNumber(8)
  set maxTimeMs($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxTimeMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxTimeMs() => $_clearField(8);
}

/// GridFsFileBatch is a group of files.
class GridFsFileBatch extends $pb.GeneratedMessage {
  factory GridFsFileBatch({
    $fixnum.Int64? offset,
    $core.Iterable<GridFsFile>? files,
    $core.bool? done,
  }) {
    final result = create();
    if (offset != null) result.offset = offset;
    if (files != null) result.files.addAll(files);
    if (done != null) result.done = done;
    return result;
  }

  GridFsFileBatch._();

  factory GridFsFileBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GridFsFileBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GridFsFileBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<GridFsFile>(2, _omitFieldNames ? '' : 'files',
        subBuilder: GridFsFile.create)
    ..aOB(3, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsFileBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GridFsFileBatch copyWith(void Function(GridFsFileBatch) updates) =>
      super.copyWith((message) => updates(message as GridFsFileBatch))
          as GridFsFileBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GridFsFileBatch create() => GridFsFileBatch._();
  @$core.override
  GridFsFileBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GridFsFileBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GridFsFileBatch>(create);
  static GridFsFileBatch? _defaultInstance;

  /// Index of files[0] among the files of this call, starting at 0.
  @$pb.TagNumber(1)
  $fixnum.Int64 get offset => $_getI64(0);
  @$pb.TagNumber(1)
  set offset($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffset() => $_clearField(1);

  /// Files in this batch.
  @$pb.TagNumber(2)
  $pb.PbList<GridFsFile> get files => $_getList(1);

  /// True on the last batch.
  @$pb.TagNumber(3)
  $core.bool get done => $_getBF(2);
  @$pb.TagNumber(3)
  set done($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDone() => $_has(2);
  @$pb.TagNumber(3)
  void clearDone() => $_clearField(3);
}

enum ListFilesResponse_Event { batch, error, notSet }

/// ListFilesResponse is one event of a ListFiles stream.
class ListFilesResponse extends $pb.GeneratedMessage {
  factory ListFilesResponse({
    GridFsFileBatch? batch,
    GridFsError? error,
  }) {
    final result = create();
    if (batch != null) result.batch = batch;
    if (error != null) result.error = error;
    return result;
  }

  ListFilesResponse._();

  factory ListFilesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFilesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ListFilesResponse_Event>
      _ListFilesResponse_EventByTag = {
    1: ListFilesResponse_Event.batch,
    2: ListFilesResponse_Event.error,
    0: ListFilesResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFilesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<GridFsFileBatch>(1, _omitFieldNames ? '' : 'batch',
        subBuilder: GridFsFileBatch.create)
    ..aOM<GridFsError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFilesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFilesResponse copyWith(void Function(ListFilesResponse) updates) =>
      super.copyWith((message) => updates(message as ListFilesResponse))
          as ListFilesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFilesResponse create() => ListFilesResponse._();
  @$core.override
  ListFilesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFilesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFilesResponse>(create);
  static ListFilesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ListFilesResponse_Event whichEvent() =>
      _ListFilesResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// A batch of files.
  @$pb.TagNumber(1)
  GridFsFileBatch get batch => $_getN(0);
  @$pb.TagNumber(1)
  set batch(GridFsFileBatch value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBatch() => $_has(0);
  @$pb.TagNumber(1)
  void clearBatch() => $_clearField(1);
  @$pb.TagNumber(1)
  GridFsFileBatch ensureBatch() => $_ensure(0);

  /// The call failed. This is the last event.
  @$pb.TagNumber(2)
  GridFsError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(GridFsError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  GridFsError ensureError() => $_ensure(1);
}

/// DownloadRequest is the input of Download.
class DownloadRequest extends $pb.GeneratedMessage {
  factory DownloadRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? bucket,
    $core.String? idEjson,
    $fixnum.Int64? offset,
    $fixnum.Int64? length,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (bucket != null) result.bucket = bucket;
    if (idEjson != null) result.idEjson = idEjson;
    if (offset != null) result.offset = offset;
    if (length != null) result.length = length;
    return result;
  }

  DownloadRequest._();

  factory DownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'bucket')
    ..aOS(4, _omitFieldNames ? '' : 'idEjson')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest copyWith(void Function(DownloadRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadRequest))
          as DownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadRequest create() => DownloadRequest._();
  @$core.override
  DownloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadRequest>(create);
  static DownloadRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Bucket name.
  @$pb.TagNumber(3)
  $core.String get bucket => $_getSZ(2);
  @$pb.TagNumber(3)
  set bucket($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBucket() => $_has(2);
  @$pb.TagNumber(3)
  void clearBucket() => $_clearField(3);

  /// The file's _id as canonical EJSON.
  @$pb.TagNumber(4)
  $core.String get idEjson => $_getSZ(3);
  @$pb.TagNumber(4)
  set idEjson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIdEjson() => $_has(3);
  @$pb.TagNumber(4)
  void clearIdEjson() => $_clearField(4);

  /// First byte to send.
  @$pb.TagNumber(5)
  $fixnum.Int64 get offset => $_getI64(4);
  @$pb.TagNumber(5)
  set offset($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);

  /// Bytes to send from offset. Unset means up to the end of the file.
  @$pb.TagNumber(6)
  $fixnum.Int64 get length => $_getI64(5);
  @$pb.TagNumber(6)
  set length($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLength() => $_has(5);
  @$pb.TagNumber(6)
  void clearLength() => $_clearField(6);
}

enum DownloadResponse_Event { file, chunk, error, notSet }

/// DownloadResponse is one event of a Download stream.
class DownloadResponse extends $pb.GeneratedMessage {
  factory DownloadResponse({
    GridFsFile? file,
    $core.List<$core.int>? chunk,
    GridFsError? error,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (chunk != null) result.chunk = chunk;
    if (error != null) result.error = error;
    return result;
  }

  DownloadResponse._();

  factory DownloadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DownloadResponse_Event>
      _DownloadResponse_EventByTag = {
    1: DownloadResponse_Event.file,
    2: DownloadResponse_Event.chunk,
    3: DownloadResponse_Event.error,
    0: DownloadResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<GridFsFile>(1, _omitFieldNames ? '' : 'file',
        subBuilder: GridFsFile.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..aOM<GridFsError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadResponse copyWith(void Function(DownloadResponse) updates) =>
      super.copyWith((message) => updates(message as DownloadResponse))
          as DownloadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadResponse create() => DownloadResponse._();
  @$core.override
  DownloadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadResponse>(create);
  static DownloadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  DownloadResponse_Event whichEvent() =>
      _DownloadResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// The file. Always the first event of a successful download.
  @$pb.TagNumber(1)
  GridFsFile get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(GridFsFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  GridFsFile ensureFile() => $_ensure(0);

  /// The next bytes, at most 1 MiB.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);

  /// The download failed. This is the last event.
  @$pb.TagNumber(3)
  GridFsError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(GridFsError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  GridFsError ensureError() => $_ensure(2);
}

/// UploadHeader describes the file an Upload stores.
class UploadHeader extends $pb.GeneratedMessage {
  factory UploadHeader({
    $core.String? sessionId,
    $core.String? database,
    $core.String? bucket,
    $core.String? filename,
    $core.String? contentType,
    $core.String? metadataEjson,
    $core.int? chunkSizeBytes,
    $core.String? replaceIdEjson,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (bucket != null) result.bucket = bucket;
    if (filename != null) result.filename = filename;
    if (contentType != null) result.contentType = contentType;
    if (metadataEjson != null) result.metadataEjson = metadataEjson;
    if (chunkSizeBytes != null) result.chunkSizeBytes = chunkSizeBytes;
    if (replaceIdEjson != null) result.replaceIdEjson = replaceIdEjson;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  UploadHeader._();

  factory UploadHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'bucket')
    ..aOS(4, _omitFieldNames ? '' : 'filename')
    ..aOS(5, _omitFieldNames ? '' : 'contentType')
    ..aOS(6, _omitFieldNames ? '' : 'metadataEjson')
    ..aI(7, _omitFieldNames ? '' : 'chunkSizeBytes',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(8, _omitFieldNames ? '' : 'replaceIdEjson')
    ..aOB(9, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadHeader copyWith(void Function(UploadHeader) updates) =>
      super.copyWith((message) => updates(message as UploadHeader))
          as UploadHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadHeader create() => UploadHeader._();
  @$core.override
  UploadHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadHeader>(create);
  static UploadHeader? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Bucket name. Created on first upload if it does not exist.
  @$pb.TagNumber(3)
  $core.String get bucket => $_getSZ(2);
  @$pb.TagNumber(3)
  set bucket($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBucket() => $_has(2);
  @$pb.TagNumber(3)
  void clearBucket() => $_clearField(3);

  /// Filename.
  @$pb.TagNumber(4)
  $core.String get filename => $_getSZ(3);
  @$pb.TagNumber(4)
  set filename($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilename() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilename() => $_clearField(4);

  /// Stored as metadata.contentType. Empty means none.
  @$pb.TagNumber(5)
  $core.String get contentType => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContentType() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentType() => $_clearField(5);

  /// Metadata document as EJSON text. Empty means none.
  @$pb.TagNumber(6)
  $core.String get metadataEjson => $_getSZ(5);
  @$pb.TagNumber(6)
  set metadataEjson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadataEjson() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetadataEjson() => $_clearField(6);

  /// Chunk size in bytes. 0 means the GridFS default (255 KiB).
  @$pb.TagNumber(7)
  $core.int get chunkSizeBytes => $_getIZ(6);
  @$pb.TagNumber(7)
  set chunkSizeBytes($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChunkSizeBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearChunkSizeBytes() => $_clearField(7);

  /// When set, the file with this canonical EJSON _id is replaced after the
  /// new file is stored.
  @$pb.TagNumber(8)
  $core.String get replaceIdEjson => $_getSZ(7);
  @$pb.TagNumber(8)
  set replaceIdEjson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReplaceIdEjson() => $_has(7);
  @$pb.TagNumber(8)
  void clearReplaceIdEjson() => $_clearField(8);

  /// Must be true to replace a file on production connections, else
  /// CONFIRMATION_REQUIRED.
  @$pb.TagNumber(9)
  $core.bool get confirmed => $_getBF(8);
  @$pb.TagNumber(9)
  set confirmed($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConfirmed() => $_has(8);
  @$pb.TagNumber(9)
  void clearConfirmed() => $_clearField(9);
}

enum UploadRequest_Part { header, chunk, notSet }

/// UploadRequest is one message of an Upload stream.
class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    UploadHeader? header,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  UploadRequest._();

  factory UploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UploadRequest_Part>
      _UploadRequest_PartByTag = {
    1: UploadRequest_Part.header,
    2: UploadRequest_Part.chunk,
    0: UploadRequest_Part.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<UploadHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: UploadHeader.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest copyWith(void Function(UploadRequest) updates) =>
      super.copyWith((message) => updates(message as UploadRequest))
          as UploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadRequest create() => UploadRequest._();
  @$core.override
  UploadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadRequest>(create);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UploadRequest_Part whichPart() => _UploadRequest_PartByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPart() => $_clearField($_whichOneof(0));

  /// The first message.
  @$pb.TagNumber(1)
  UploadHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(UploadHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadHeader ensureHeader() => $_ensure(0);

  /// File bytes. Every message after the header.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
}

/// UploadResponse holds the stored file or the failure.
class UploadResponse extends $pb.GeneratedMessage {
  factory UploadResponse({
    GridFsFile? file,
    GridFsError? error,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (error != null) result.error = error;
    return result;
  }

  UploadResponse._();

  factory UploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<GridFsFile>(1, _omitFieldNames ? '' : 'file',
        subBuilder: GridFsFile.create)
    ..aOM<GridFsError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse copyWith(void Function(UploadResponse) updates) =>
      super.copyWith((message) => updates(message as UploadResponse))
          as UploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadResponse create() => UploadResponse._();
  @$core.override
  UploadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadResponse>(create);
  static UploadResponse? _defaultInstance;

  /// The stored file.
  @$pb.TagNumber(1)
  GridFsFile get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(GridFsFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  GridFsFile ensureFile() => $_ensure(0);

  /// Set when the upload failed or needs confirmation.
  @$pb.TagNumber(2)
  GridFsError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(GridFsError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  GridFsError ensureError() => $_ensure(1);
}

/// DeleteFileRequest is the input of DeleteFile.
class DeleteFileRequest extends $pb.GeneratedMessage {
  factory DeleteFileRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? bucket,
    $core.String? idEjson,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (bucket != null) result.bucket = bucket;
    if (idEjson != null) result.idEjson = idEjson;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  DeleteFileRequest._();

  factory DeleteFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'bucket')
    ..aOS(4, _omitFieldNames ? '' : 'idEjson')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileRequest copyWith(void Function(DeleteFileRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteFileRequest))
          as DeleteFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFileRequest create() => DeleteFileRequest._();
  @$core.override
  DeleteFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFileRequest>(create);
  static DeleteFileRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Bucket name.
  @$pb.TagNumber(3)
  $core.String get bucket => $_getSZ(2);
  @$pb.TagNumber(3)
  set bucket($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBucket() => $_has(2);
  @$pb.TagNumber(3)
  void clearBucket() => $_clearField(3);

  /// The file's _id as canonical EJSON.
  @$pb.TagNumber(4)
  $core.String get idEjson => $_getSZ(3);
  @$pb.TagNumber(4)
  set idEjson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIdEjson() => $_has(3);
  @$pb.TagNumber(4)
  void clearIdEjson() => $_clearField(4);

  /// Must be true on production connections, else CONFIRMATION_REQUIRED.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// DeleteFileResponse holds the failure, if any.
class DeleteFileResponse extends $pb.GeneratedMessage {
  factory DeleteFileResponse({
    GridFsError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  DeleteFileResponse._();

  factory DeleteFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<GridFsError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFileResponse copyWith(void Function(DeleteFileResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteFileResponse))
          as DeleteFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFileResponse create() => DeleteFileResponse._();
  @$core.override
  DeleteFileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFileResponse>(create);
  static DeleteFileResponse? _defaultInstance;

  /// Set when the delete failed or needs confirmation.
  @$pb.TagNumber(1)
  GridFsError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(GridFsError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  GridFsError ensureError() => $_ensure(0);
}

/// RenameFileRequest is the input of RenameFile.
class RenameFileRequest extends $pb.GeneratedMessage {
  factory RenameFileRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? bucket,
    $core.String? idEjson,
    $core.String? newFilename,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (bucket != null) result.bucket = bucket;
    if (idEjson != null) result.idEjson = idEjson;
    if (newFilename != null) result.newFilename = newFilename;
    return result;
  }

  RenameFileRequest._();

  factory RenameFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameFileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'bucket')
    ..aOS(4, _omitFieldNames ? '' : 'idEjson')
    ..aOS(5, _omitFieldNames ? '' : 'newFilename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameFileRequest copyWith(void Function(RenameFileRequest) updates) =>
      super.copyWith((message) => updates(message as RenameFileRequest))
          as RenameFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameFileRequest create() => RenameFileRequest._();
  @$core.override
  RenameFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameFileRequest>(create);
  static RenameFileRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Bucket name.
  @$pb.TagNumber(3)
  $core.String get bucket => $_getSZ(2);
  @$pb.TagNumber(3)
  set bucket($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBucket() => $_has(2);
  @$pb.TagNumber(3)
  void clearBucket() => $_clearField(3);

  /// The file's _id as canonical EJSON.
  @$pb.TagNumber(4)
  $core.String get idEjson => $_getSZ(3);
  @$pb.TagNumber(4)
  set idEjson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIdEjson() => $_has(3);
  @$pb.TagNumber(4)
  void clearIdEjson() => $_clearField(4);

  /// New filename.
  @$pb.TagNumber(5)
  $core.String get newFilename => $_getSZ(4);
  @$pb.TagNumber(5)
  set newFilename($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNewFilename() => $_has(4);
  @$pb.TagNumber(5)
  void clearNewFilename() => $_clearField(5);
}

/// RenameFileResponse holds the failure, if any.
class RenameFileResponse extends $pb.GeneratedMessage {
  factory RenameFileResponse({
    GridFsError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  RenameFileResponse._();

  factory RenameFileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameFileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameFileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<GridFsError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: GridFsError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameFileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameFileResponse copyWith(void Function(RenameFileResponse) updates) =>
      super.copyWith((message) => updates(message as RenameFileResponse))
          as RenameFileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameFileResponse create() => RenameFileResponse._();
  @$core.override
  RenameFileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameFileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameFileResponse>(create);
  static RenameFileResponse? _defaultInstance;

  /// Set when the rename failed.
  @$pb.TagNumber(1)
  GridFsError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(GridFsError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  GridFsError ensureError() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
