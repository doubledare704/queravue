// This is a generated file - do not edit.
//
// Generated from queravue/v1/workspace.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'workspace.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'workspace.pbenum.dart';

/// WorkspaceError is a typed failure.
class WorkspaceError extends $pb.GeneratedMessage {
  factory WorkspaceError({
    WorkspaceErrorKind? kind,
    $core.String? message,
    FileContent? current,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (current != null) result.current = current;
    return result;
  }

  WorkspaceError._();

  factory WorkspaceError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspaceError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspaceError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<WorkspaceErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: WorkspaceErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FileContent>(3, _omitFieldNames ? '' : 'current',
        subBuilder: FileContent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceError copyWith(void Function(WorkspaceError) updates) =>
      super.copyWith((message) => updates(message as WorkspaceError))
          as WorkspaceError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspaceError create() => WorkspaceError._();
  @$core.override
  WorkspaceError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspaceError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspaceError>(create);
  static WorkspaceError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  WorkspaceErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(WorkspaceErrorKind value) => $_setField(1, value);
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

  /// For CONFLICT: the file as it is on disk now. Unset if it was deleted.
  @$pb.TagNumber(3)
  FileContent get current => $_getN(2);
  @$pb.TagNumber(3)
  set current(FileContent value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrent() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrent() => $_clearField(3);
  @$pb.TagNumber(3)
  FileContent ensureCurrent() => $_ensure(2);
}

/// WorkspaceRoot is a workspace folder.
class WorkspaceRoot extends $pb.GeneratedMessage {
  factory WorkspaceRoot({
    $core.String? id,
    $core.String? name,
    $core.String? path,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    return result;
  }

  WorkspaceRoot._();

  factory WorkspaceRoot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspaceRoot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspaceRoot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceRoot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceRoot copyWith(void Function(WorkspaceRoot) updates) =>
      super.copyWith((message) => updates(message as WorkspaceRoot))
          as WorkspaceRoot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspaceRoot create() => WorkspaceRoot._();
  @$core.override
  WorkspaceRoot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspaceRoot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspaceRoot>(create);
  static WorkspaceRoot? _defaultInstance;

  /// Stable id used in paths.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Display name.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Absolute folder path on the machine running core.
  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);
}

/// GetRootsRequest is empty.
class GetRootsRequest extends $pb.GeneratedMessage {
  factory GetRootsRequest() => create();

  GetRootsRequest._();

  factory GetRootsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRootsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRootsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRootsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRootsRequest copyWith(void Function(GetRootsRequest) updates) =>
      super.copyWith((message) => updates(message as GetRootsRequest))
          as GetRootsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRootsRequest create() => GetRootsRequest._();
  @$core.override
  GetRootsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRootsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRootsRequest>(create);
  static GetRootsRequest? _defaultInstance;
}

/// GetRootsResponse lists the roots.
class GetRootsResponse extends $pb.GeneratedMessage {
  factory GetRootsResponse({
    $core.Iterable<WorkspaceRoot>? roots,
  }) {
    final result = create();
    if (roots != null) result.roots.addAll(roots);
    return result;
  }

  GetRootsResponse._();

  factory GetRootsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRootsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRootsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<WorkspaceRoot>(1, _omitFieldNames ? '' : 'roots',
        subBuilder: WorkspaceRoot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRootsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRootsResponse copyWith(void Function(GetRootsResponse) updates) =>
      super.copyWith((message) => updates(message as GetRootsResponse))
          as GetRootsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRootsResponse create() => GetRootsResponse._();
  @$core.override
  GetRootsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRootsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRootsResponse>(create);
  static GetRootsResponse? _defaultInstance;

  /// Configured roots. On first use it holds the default root.
  @$pb.TagNumber(1)
  $pb.PbList<WorkspaceRoot> get roots => $_getList(0);
}

/// SetRootsRequest is the new list of roots.
class SetRootsRequest extends $pb.GeneratedMessage {
  factory SetRootsRequest({
    $core.Iterable<WorkspaceRoot>? roots,
  }) {
    final result = create();
    if (roots != null) result.roots.addAll(roots);
    return result;
  }

  SetRootsRequest._();

  factory SetRootsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetRootsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRootsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<WorkspaceRoot>(1, _omitFieldNames ? '' : 'roots',
        subBuilder: WorkspaceRoot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRootsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRootsRequest copyWith(void Function(SetRootsRequest) updates) =>
      super.copyWith((message) => updates(message as SetRootsRequest))
          as SetRootsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetRootsRequest create() => SetRootsRequest._();
  @$core.override
  SetRootsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetRootsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRootsRequest>(create);
  static SetRootsRequest? _defaultInstance;

  /// Roots to keep. Entries with an empty id get a new one.
  @$pb.TagNumber(1)
  $pb.PbList<WorkspaceRoot> get roots => $_getList(0);
}

/// SetRootsResponse returns the stored roots.
class SetRootsResponse extends $pb.GeneratedMessage {
  factory SetRootsResponse({
    $core.Iterable<WorkspaceRoot>? roots,
    WorkspaceError? error,
  }) {
    final result = create();
    if (roots != null) result.roots.addAll(roots);
    if (error != null) result.error = error;
    return result;
  }

  SetRootsResponse._();

  factory SetRootsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetRootsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRootsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<WorkspaceRoot>(1, _omitFieldNames ? '' : 'roots',
        subBuilder: WorkspaceRoot.create)
    ..aOM<WorkspaceError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRootsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRootsResponse copyWith(void Function(SetRootsResponse) updates) =>
      super.copyWith((message) => updates(message as SetRootsResponse))
          as SetRootsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetRootsResponse create() => SetRootsResponse._();
  @$core.override
  SetRootsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetRootsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRootsResponse>(create);
  static SetRootsResponse? _defaultInstance;

  /// The roots as stored, with ids filled in.
  @$pb.TagNumber(1)
  $pb.PbList<WorkspaceRoot> get roots => $_getList(0);

  /// Set when the roots could not be applied.
  @$pb.TagNumber(2)
  WorkspaceError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(WorkspaceError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  WorkspaceError ensureError() => $_ensure(1);
}

/// FileMeta is the header metadata of a script (ADR 0011).
class FileMeta extends $pb.GeneratedMessage {
  factory FileMeta({
    $core.String? title,
    $core.String? description,
    $core.String? connection,
    $core.Iterable<$core.String>? tags,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (connection != null) result.connection = connection;
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  FileMeta._();

  factory FileMeta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileMeta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileMeta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'connection')
    ..pPS(4, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileMeta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileMeta copyWith(void Function(FileMeta) updates) =>
      super.copyWith((message) => updates(message as FileMeta)) as FileMeta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileMeta create() => FileMeta._();
  @$core.override
  FileMeta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileMeta>(create);
  static FileMeta? _defaultInstance;

  /// Display title.
  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// Free-text description.
  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  /// Default connection id or name. Never credentials.
  @$pb.TagNumber(3)
  $core.String get connection => $_getSZ(2);
  @$pb.TagNumber(3)
  set connection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConnection() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnection() => $_clearField(3);

  /// Tags.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get tags => $_getList(3);
}

/// TreeEntry is one file or folder.
class TreeEntry extends $pb.GeneratedMessage {
  factory TreeEntry({
    $core.String? name,
    $core.bool? isDir,
    FileKind? kind,
    $fixnum.Int64? size,
    $1.Timestamp? mtime,
    FileMeta? meta,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (isDir != null) result.isDir = isDir;
    if (kind != null) result.kind = kind;
    if (size != null) result.size = size;
    if (mtime != null) result.mtime = mtime;
    if (meta != null) result.meta = meta;
    return result;
  }

  TreeEntry._();

  factory TreeEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TreeEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TreeEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'isDir')
    ..aE<FileKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: FileKind.values)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'mtime',
        subBuilder: $1.Timestamp.create)
    ..aOM<FileMeta>(6, _omitFieldNames ? '' : 'meta',
        subBuilder: FileMeta.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TreeEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TreeEntry copyWith(void Function(TreeEntry) updates) =>
      super.copyWith((message) => updates(message as TreeEntry)) as TreeEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TreeEntry create() => TreeEntry._();
  @$core.override
  TreeEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TreeEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TreeEntry>(create);
  static TreeEntry? _defaultInstance;

  /// Entry name, without path.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// True for a folder.
  @$pb.TagNumber(2)
  $core.bool get isDir => $_getBF(1);
  @$pb.TagNumber(2)
  set isDir($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsDir() => $_clearField(2);

  /// What a file is for. Unspecified for folders and other files.
  @$pb.TagNumber(3)
  FileKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(FileKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// File size in bytes.
  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  /// Last modification time.
  @$pb.TagNumber(5)
  $1.Timestamp get mtime => $_getN(4);
  @$pb.TagNumber(5)
  set mtime($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMtime() => $_has(4);
  @$pb.TagNumber(5)
  void clearMtime() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureMtime() => $_ensure(4);

  /// Header metadata of a script file.
  @$pb.TagNumber(6)
  FileMeta get meta => $_getN(5);
  @$pb.TagNumber(6)
  set meta(FileMeta value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMeta() => $_has(5);
  @$pb.TagNumber(6)
  void clearMeta() => $_clearField(6);
  @$pb.TagNumber(6)
  FileMeta ensureMeta() => $_ensure(5);
}

/// ListTreeRequest names the directory to list.
class ListTreeRequest extends $pb.GeneratedMessage {
  factory ListTreeRequest({
    $core.String? rootId,
    $core.String? path,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    return result;
  }

  ListTreeRequest._();

  factory ListTreeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTreeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTreeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTreeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTreeRequest copyWith(void Function(ListTreeRequest) updates) =>
      super.copyWith((message) => updates(message as ListTreeRequest))
          as ListTreeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTreeRequest create() => ListTreeRequest._();
  @$core.override
  ListTreeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTreeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTreeRequest>(create);
  static ListTreeRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// Directory relative to the root. Empty is the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

/// ListTreeResponse holds the entries, folders first, then by name.
class ListTreeResponse extends $pb.GeneratedMessage {
  factory ListTreeResponse({
    $core.Iterable<TreeEntry>? entries,
    WorkspaceError? error,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (error != null) result.error = error;
    return result;
  }

  ListTreeResponse._();

  factory ListTreeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTreeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTreeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<TreeEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: TreeEntry.create)
    ..aOM<WorkspaceError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTreeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTreeResponse copyWith(void Function(ListTreeResponse) updates) =>
      super.copyWith((message) => updates(message as ListTreeResponse))
          as ListTreeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTreeResponse create() => ListTreeResponse._();
  @$core.override
  ListTreeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTreeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTreeResponse>(create);
  static ListTreeResponse? _defaultInstance;

  /// Entries of the directory. `.git` is not listed.
  @$pb.TagNumber(1)
  $pb.PbList<TreeEntry> get entries => $_getList(0);

  /// Set when listing failed.
  @$pb.TagNumber(2)
  WorkspaceError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(WorkspaceError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  WorkspaceError ensureError() => $_ensure(1);
}

/// FileContent is a file read from disk.
class FileContent extends $pb.GeneratedMessage {
  factory FileContent({
    $core.String? content,
    $1.Timestamp? mtime,
    $core.String? hash,
    FileMeta? meta,
    FileKind? kind,
  }) {
    final result = create();
    if (content != null) result.content = content;
    if (mtime != null) result.mtime = mtime;
    if (hash != null) result.hash = hash;
    if (meta != null) result.meta = meta;
    if (kind != null) result.kind = kind;
    return result;
  }

  FileContent._();

  factory FileContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'content')
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'mtime',
        subBuilder: $1.Timestamp.create)
    ..aOS(3, _omitFieldNames ? '' : 'hash')
    ..aOM<FileMeta>(4, _omitFieldNames ? '' : 'meta',
        subBuilder: FileMeta.create)
    ..aE<FileKind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: FileKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileContent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileContent copyWith(void Function(FileContent) updates) =>
      super.copyWith((message) => updates(message as FileContent))
          as FileContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileContent create() => FileContent._();
  @$core.override
  FileContent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileContent>(create);
  static FileContent? _defaultInstance;

  /// File text, UTF-8.
  @$pb.TagNumber(1)
  $core.String get content => $_getSZ(0);
  @$pb.TagNumber(1)
  set content($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);

  /// Last modification time.
  @$pb.TagNumber(2)
  $1.Timestamp get mtime => $_getN(1);
  @$pb.TagNumber(2)
  set mtime($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMtime() => $_has(1);
  @$pb.TagNumber(2)
  void clearMtime() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureMtime() => $_ensure(1);

  /// SHA-256 of the content, hex.
  @$pb.TagNumber(3)
  $core.String get hash => $_getSZ(2);
  @$pb.TagNumber(3)
  set hash($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearHash() => $_clearField(3);

  /// Parsed header metadata.
  @$pb.TagNumber(4)
  FileMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(FileMeta value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => $_clearField(4);
  @$pb.TagNumber(4)
  FileMeta ensureMeta() => $_ensure(3);

  /// What the file is for.
  @$pb.TagNumber(5)
  FileKind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(FileKind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);
}

/// ReadRequest names the file to read.
class ReadRequest extends $pb.GeneratedMessage {
  factory ReadRequest({
    $core.String? rootId,
    $core.String? path,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    return result;
  }

  ReadRequest._();

  factory ReadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadRequest copyWith(void Function(ReadRequest) updates) =>
      super.copyWith((message) => updates(message as ReadRequest))
          as ReadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadRequest create() => ReadRequest._();
  @$core.override
  ReadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadRequest>(create);
  static ReadRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// File path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

/// ReadResponse holds the file or the failure.
class ReadResponse extends $pb.GeneratedMessage {
  factory ReadResponse({
    FileContent? file,
    WorkspaceError? error,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (error != null) result.error = error;
    return result;
  }

  ReadResponse._();

  factory ReadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<FileContent>(1, _omitFieldNames ? '' : 'file',
        subBuilder: FileContent.create)
    ..aOM<WorkspaceError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadResponse copyWith(void Function(ReadResponse) updates) =>
      super.copyWith((message) => updates(message as ReadResponse))
          as ReadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadResponse create() => ReadResponse._();
  @$core.override
  ReadResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadResponse>(create);
  static ReadResponse? _defaultInstance;

  /// The file.
  @$pb.TagNumber(1)
  FileContent get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(FileContent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  FileContent ensureFile() => $_ensure(0);

  /// Set when reading failed.
  @$pb.TagNumber(2)
  WorkspaceError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(WorkspaceError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  WorkspaceError ensureError() => $_ensure(1);
}

/// WriteRequest is the input of Write.
class WriteRequest extends $pb.GeneratedMessage {
  factory WriteRequest({
    $core.String? rootId,
    $core.String? path,
    $core.String? content,
    $1.Timestamp? expectedMtime,
    $core.String? expectedHash,
    $core.bool? force,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    if (content != null) result.content = content;
    if (expectedMtime != null) result.expectedMtime = expectedMtime;
    if (expectedHash != null) result.expectedHash = expectedHash;
    if (force != null) result.force = force;
    return result;
  }

  WriteRequest._();

  factory WriteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'content')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'expectedMtime',
        subBuilder: $1.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'expectedHash')
    ..aOB(6, _omitFieldNames ? '' : 'force')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteRequest copyWith(void Function(WriteRequest) updates) =>
      super.copyWith((message) => updates(message as WriteRequest))
          as WriteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteRequest create() => WriteRequest._();
  @$core.override
  WriteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteRequest>(create);
  static WriteRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// File path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  /// New file text.
  @$pb.TagNumber(3)
  $core.String get content => $_getSZ(2);
  @$pb.TagNumber(3)
  set content($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);

  /// mtime the client last read. Unset skips the check.
  @$pb.TagNumber(4)
  $1.Timestamp get expectedMtime => $_getN(3);
  @$pb.TagNumber(4)
  set expectedMtime($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExpectedMtime() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpectedMtime() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureExpectedMtime() => $_ensure(3);

  /// Hash the client last read. Empty skips the check.
  @$pb.TagNumber(5)
  $core.String get expectedHash => $_getSZ(4);
  @$pb.TagNumber(5)
  set expectedHash($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpectedHash() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpectedHash() => $_clearField(5);

  /// Overwrite without checking, after the user chose "keep mine".
  @$pb.TagNumber(6)
  $core.bool get force => $_getBF(5);
  @$pb.TagNumber(6)
  set force($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasForce() => $_has(5);
  @$pb.TagNumber(6)
  void clearForce() => $_clearField(6);
}

/// WriteResponse holds the written file's state or the failure.
class WriteResponse extends $pb.GeneratedMessage {
  factory WriteResponse({
    $1.Timestamp? mtime,
    $core.String? hash,
    WorkspaceError? error,
  }) {
    final result = create();
    if (mtime != null) result.mtime = mtime;
    if (hash != null) result.hash = hash;
    if (error != null) result.error = error;
    return result;
  }

  WriteResponse._();

  factory WriteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Timestamp>(1, _omitFieldNames ? '' : 'mtime',
        subBuilder: $1.Timestamp.create)
    ..aOS(2, _omitFieldNames ? '' : 'hash')
    ..aOM<WorkspaceError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteResponse copyWith(void Function(WriteResponse) updates) =>
      super.copyWith((message) => updates(message as WriteResponse))
          as WriteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteResponse create() => WriteResponse._();
  @$core.override
  WriteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteResponse>(create);
  static WriteResponse? _defaultInstance;

  /// New mtime.
  @$pb.TagNumber(1)
  $1.Timestamp get mtime => $_getN(0);
  @$pb.TagNumber(1)
  set mtime($1.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMtime() => $_has(0);
  @$pb.TagNumber(1)
  void clearMtime() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Timestamp ensureMtime() => $_ensure(0);

  /// New content hash.
  @$pb.TagNumber(2)
  $core.String get hash => $_getSZ(1);
  @$pb.TagNumber(2)
  set hash($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearHash() => $_clearField(2);

  /// Set when the write failed or conflicted.
  @$pb.TagNumber(3)
  WorkspaceError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(WorkspaceError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  WorkspaceError ensureError() => $_ensure(2);
}

/// CreateRequest is the input of Create.
class CreateRequest extends $pb.GeneratedMessage {
  factory CreateRequest({
    $core.String? rootId,
    $core.String? path,
    $core.bool? isDir,
    $core.String? content,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    if (isDir != null) result.isDir = isDir;
    if (content != null) result.content = content;
    return result;
  }

  CreateRequest._();

  factory CreateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'isDir')
    ..aOS(4, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRequest copyWith(void Function(CreateRequest) updates) =>
      super.copyWith((message) => updates(message as CreateRequest))
          as CreateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateRequest create() => CreateRequest._();
  @$core.override
  CreateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRequest>(create);
  static CreateRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// Path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  /// True to create a folder.
  @$pb.TagNumber(3)
  $core.bool get isDir => $_getBF(2);
  @$pb.TagNumber(3)
  set isDir($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDir() => $_clearField(3);

  /// Initial text of a new file.
  @$pb.TagNumber(4)
  $core.String get content => $_getSZ(3);
  @$pb.TagNumber(4)
  set content($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContent() => $_clearField(4);
}

/// CreateResponse holds the created file's state or the failure.
class CreateResponse extends $pb.GeneratedMessage {
  factory CreateResponse({
    $1.Timestamp? mtime,
    $core.String? hash,
    WorkspaceError? error,
  }) {
    final result = create();
    if (mtime != null) result.mtime = mtime;
    if (hash != null) result.hash = hash;
    if (error != null) result.error = error;
    return result;
  }

  CreateResponse._();

  factory CreateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Timestamp>(1, _omitFieldNames ? '' : 'mtime',
        subBuilder: $1.Timestamp.create)
    ..aOS(2, _omitFieldNames ? '' : 'hash')
    ..aOM<WorkspaceError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateResponse copyWith(void Function(CreateResponse) updates) =>
      super.copyWith((message) => updates(message as CreateResponse))
          as CreateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateResponse create() => CreateResponse._();
  @$core.override
  CreateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateResponse>(create);
  static CreateResponse? _defaultInstance;

  /// New mtime of a created file.
  @$pb.TagNumber(1)
  $1.Timestamp get mtime => $_getN(0);
  @$pb.TagNumber(1)
  set mtime($1.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMtime() => $_has(0);
  @$pb.TagNumber(1)
  void clearMtime() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Timestamp ensureMtime() => $_ensure(0);

  /// Content hash of a created file.
  @$pb.TagNumber(2)
  $core.String get hash => $_getSZ(1);
  @$pb.TagNumber(2)
  set hash($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearHash() => $_clearField(2);

  /// Set when creating failed.
  @$pb.TagNumber(3)
  WorkspaceError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(WorkspaceError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  WorkspaceError ensureError() => $_ensure(2);
}

/// RenameRequest is the input of Rename.
class RenameRequest extends $pb.GeneratedMessage {
  factory RenameRequest({
    $core.String? rootId,
    $core.String? fromPath,
    $core.String? toPath,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (fromPath != null) result.fromPath = fromPath;
    if (toPath != null) result.toPath = toPath;
    return result;
  }

  RenameRequest._();

  factory RenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'fromPath')
    ..aOS(3, _omitFieldNames ? '' : 'toPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest copyWith(void Function(RenameRequest) updates) =>
      super.copyWith((message) => updates(message as RenameRequest))
          as RenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameRequest create() => RenameRequest._();
  @$core.override
  RenameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameRequest>(create);
  static RenameRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// Existing path relative to the root.
  @$pb.TagNumber(2)
  $core.String get fromPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromPath() => $_clearField(2);

  /// New path relative to the root.
  @$pb.TagNumber(3)
  $core.String get toPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set toPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearToPath() => $_clearField(3);
}

/// RenameResponse is empty on success.
class RenameResponse extends $pb.GeneratedMessage {
  factory RenameResponse({
    WorkspaceError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  RenameResponse._();

  factory RenameResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<WorkspaceError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameResponse copyWith(void Function(RenameResponse) updates) =>
      super.copyWith((message) => updates(message as RenameResponse))
          as RenameResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameResponse create() => RenameResponse._();
  @$core.override
  RenameResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameResponse>(create);
  static RenameResponse? _defaultInstance;

  /// Set when renaming failed.
  @$pb.TagNumber(1)
  WorkspaceError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(WorkspaceError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  WorkspaceError ensureError() => $_ensure(0);
}

/// DeleteRequest names the entry to delete.
class DeleteRequest extends $pb.GeneratedMessage {
  factory DeleteRequest({
    $core.String? rootId,
    $core.String? path,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    return result;
  }

  DeleteRequest._();

  factory DeleteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRequest copyWith(void Function(DeleteRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteRequest))
          as DeleteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteRequest create() => DeleteRequest._();
  @$core.override
  DeleteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRequest>(create);
  static DeleteRequest? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// Path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

/// DeleteResponse is empty on success.
class DeleteResponse extends $pb.GeneratedMessage {
  factory DeleteResponse({
    WorkspaceError? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  DeleteResponse._();

  factory DeleteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<WorkspaceError>(1, _omitFieldNames ? '' : 'error',
        subBuilder: WorkspaceError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResponse copyWith(void Function(DeleteResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteResponse))
          as DeleteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResponse create() => DeleteResponse._();
  @$core.override
  DeleteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteResponse>(create);
  static DeleteResponse? _defaultInstance;

  /// Set when deleting failed.
  @$pb.TagNumber(1)
  WorkspaceError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(WorkspaceError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  WorkspaceError ensureError() => $_ensure(0);
}

/// SearchRequest is the input of Search.
class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? text,
    $core.Iterable<$core.String>? tags,
    $core.String? rootId,
    $core.int? limit,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (tags != null) result.tags.addAll(tags);
    if (rootId != null) result.rootId = rootId;
    if (limit != null) result.limit = limit;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..pPS(2, _omitFieldNames ? '' : 'tags')
    ..aOS(3, _omitFieldNames ? '' : 'rootId')
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  /// Case-insensitive text matched against file names, titles, tags and
  /// content. Empty matches every file.
  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  /// Only files that have all these tags.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get tags => $_getList(1);

  /// Limit the search to one root. Empty searches all roots.
  @$pb.TagNumber(3)
  $core.String get rootId => $_getSZ(2);
  @$pb.TagNumber(3)
  set rootId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRootId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRootId() => $_clearField(3);

  /// Maximum hits. 0 means 200.
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

/// SearchResponse is one matching file.
class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.String? rootId,
    $core.String? path,
    FileKind? kind,
    FileMeta? meta,
    $core.String? snippet,
    $core.int? line,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    if (kind != null) result.kind = kind;
    if (meta != null) result.meta = meta;
    if (snippet != null) result.snippet = snippet;
    if (line != null) result.line = line;
    return result;
  }

  SearchResponse._();

  factory SearchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aE<FileKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: FileKind.values)
    ..aOM<FileMeta>(4, _omitFieldNames ? '' : 'meta',
        subBuilder: FileMeta.create)
    ..aOS(5, _omitFieldNames ? '' : 'snippet')
    ..aI(6, _omitFieldNames ? '' : 'line', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse copyWith(void Function(SearchResponse) updates) =>
      super.copyWith((message) => updates(message as SearchResponse))
          as SearchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  @$core.override
  SearchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// File path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  /// What the file is for.
  @$pb.TagNumber(3)
  FileKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(FileKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// Header metadata.
  @$pb.TagNumber(4)
  FileMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(FileMeta value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => $_clearField(4);
  @$pb.TagNumber(4)
  FileMeta ensureMeta() => $_ensure(3);

  /// First matching line text, if the content matched.
  @$pb.TagNumber(5)
  $core.String get snippet => $_getSZ(4);
  @$pb.TagNumber(5)
  set snippet($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSnippet() => $_has(4);
  @$pb.TagNumber(5)
  void clearSnippet() => $_clearField(5);

  /// Line of the snippet, starting at 1. 0 if the match was not in content.
  @$pb.TagNumber(6)
  $core.int get line => $_getIZ(5);
  @$pb.TagNumber(6)
  set line($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLine() => $_has(5);
  @$pb.TagNumber(6)
  void clearLine() => $_clearField(6);
}

/// WatchRequest selects what to watch.
class WatchRequest extends $pb.GeneratedMessage {
  factory WatchRequest({
    $core.Iterable<$core.String>? rootIds,
  }) {
    final result = create();
    if (rootIds != null) result.rootIds.addAll(rootIds);
    return result;
  }

  WatchRequest._();

  factory WatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'rootIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest copyWith(void Function(WatchRequest) updates) =>
      super.copyWith((message) => updates(message as WatchRequest))
          as WatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchRequest create() => WatchRequest._();
  @$core.override
  WatchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchRequest>(create);
  static WatchRequest? _defaultInstance;

  /// Roots to watch. Empty watches all roots.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get rootIds => $_getList(0);
}

/// WatchResponse reports a change on disk.
class WatchResponse extends $pb.GeneratedMessage {
  factory WatchResponse({
    $core.String? rootId,
    $core.String? path,
    ChangeKind? kind,
    $core.String? oldPath,
    $1.Timestamp? mtime,
  }) {
    final result = create();
    if (rootId != null) result.rootId = rootId;
    if (path != null) result.path = path;
    if (kind != null) result.kind = kind;
    if (oldPath != null) result.oldPath = oldPath;
    if (mtime != null) result.mtime = mtime;
    return result;
  }

  WatchResponse._();

  factory WatchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aE<ChangeKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: ChangeKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'oldPath')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'mtime',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchResponse copyWith(void Function(WatchResponse) updates) =>
      super.copyWith((message) => updates(message as WatchResponse))
          as WatchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchResponse create() => WatchResponse._();
  @$core.override
  WatchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchResponse>(create);
  static WatchResponse? _defaultInstance;

  /// Root id.
  @$pb.TagNumber(1)
  $core.String get rootId => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  /// Path relative to the root.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  /// What happened.
  @$pb.TagNumber(3)
  ChangeKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(ChangeKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// For RENAMED: the old path.
  @$pb.TagNumber(4)
  $core.String get oldPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set oldPath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOldPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearOldPath() => $_clearField(4);

  /// Modification time after the change, unset for deletions.
  @$pb.TagNumber(5)
  $1.Timestamp get mtime => $_getN(4);
  @$pb.TagNumber(5)
  set mtime($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMtime() => $_has(4);
  @$pb.TagNumber(5)
  void clearMtime() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureMtime() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
