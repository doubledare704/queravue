// This is a generated file - do not edit.
//
// Generated from queravue/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'connections.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// OpenRequest selects the saved connection to open.
class OpenRequest extends $pb.GeneratedMessage {
  factory OpenRequest({
    $core.String? connectionId,
  }) {
    final result = create();
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  OpenRequest._();

  factory OpenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenRequest copyWith(void Function(OpenRequest) updates) =>
      super.copyWith((message) => updates(message as OpenRequest))
          as OpenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenRequest create() => OpenRequest._();
  @$core.override
  OpenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenRequest>(create);
  static OpenRequest? _defaultInstance;

  /// Id of a saved connection (see ConnectionService).
  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);
}

/// OpenResponse carries the new session or the reason it could not be opened.
class OpenResponse extends $pb.GeneratedMessage {
  factory OpenResponse({
    $core.String? sessionId,
    $1.ServerInfo? serverInfo,
    $core.Iterable<$core.String>? capabilities,
    $1.ConnectionError? error,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (serverInfo != null) result.serverInfo = serverInfo;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    if (error != null) result.error = error;
    return result;
  }

  OpenResponse._();

  factory OpenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.ServerInfo>(2, _omitFieldNames ? '' : 'serverInfo',
        subBuilder: $1.ServerInfo.create)
    ..pPS(3, _omitFieldNames ? '' : 'capabilities')
    ..aOM<$1.ConnectionError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ConnectionError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenResponse copyWith(void Function(OpenResponse) updates) =>
      super.copyWith((message) => updates(message as OpenResponse))
          as OpenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenResponse create() => OpenResponse._();
  @$core.override
  OpenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenResponse>(create);
  static OpenResponse? _defaultInstance;

  /// Id of the new session. Empty if `error` is set.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Server product and version the session is connected to.
  @$pb.TagNumber(2)
  $1.ServerInfo get serverInfo => $_getN(1);
  @$pb.TagNumber(2)
  set serverInfo($1.ServerInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServerInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ServerInfo ensureServerInfo() => $_ensure(1);

  /// Capability names of the session's engine, e.g. "execute". The UI enables
  /// features from these names, never from engine ids. Unknown names must be
  /// ignored.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get capabilities => $_getList(2);

  /// Set when the connection could not be opened.
  @$pb.TagNumber(4)
  $1.ConnectionError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($1.ConnectionError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.ConnectionError ensureError() => $_ensure(3);
}

/// CloseRequest names the session to close.
class CloseRequest extends $pb.GeneratedMessage {
  factory CloseRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  CloseRequest._();

  factory CloseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseRequest copyWith(void Function(CloseRequest) updates) =>
      super.copyWith((message) => updates(message as CloseRequest))
          as CloseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseRequest create() => CloseRequest._();
  @$core.override
  CloseRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseRequest>(create);
  static CloseRequest? _defaultInstance;

  /// Session id from Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

/// CloseResponse is empty.
class CloseResponse extends $pb.GeneratedMessage {
  factory CloseResponse() => create();

  CloseResponse._();

  factory CloseResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResponse copyWith(void Function(CloseResponse) updates) =>
      super.copyWith((message) => updates(message as CloseResponse))
          as CloseResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseResponse create() => CloseResponse._();
  @$core.override
  CloseResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseResponse>(create);
  static CloseResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
