// This is a generated file - do not edit.
//
// Generated from queravue/v1/connections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'connections.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'connections.pbenum.dart';

/// Connection is a saved connection profile. It never contains a password.
class Connection extends $pb.GeneratedMessage {
  factory Connection({
    $core.String? id,
    $core.String? name,
    $core.String? engineId,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
    $core.String? folder,
    ColorTag? color,
    $core.bool? production,
    $core.bool? hasPassword,
    $1.Timestamp? createdAt,
    $1.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (engineId != null) result.engineId = engineId;
    if (params != null) result.params.addEntries(params);
    if (folder != null) result.folder = folder;
    if (color != null) result.color = color;
    if (production != null) result.production = production;
    if (hasPassword != null) result.hasPassword = hasPassword;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Connection._();

  factory Connection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Connection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Connection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'engineId')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'params',
        entryClassName: 'Connection.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('queravue.v1'))
    ..aOS(5, _omitFieldNames ? '' : 'folder')
    ..aE<ColorTag>(6, _omitFieldNames ? '' : 'color',
        enumValues: ColorTag.values)
    ..aOB(7, _omitFieldNames ? '' : 'production')
    ..aOB(8, _omitFieldNames ? '' : 'hasPassword')
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection copyWith(void Function(Connection) updates) =>
      super.copyWith((message) => updates(message as Connection)) as Connection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Connection create() => Connection._();
  @$core.override
  Connection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Connection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Connection>(create);
  static Connection? _defaultInstance;

  /// Core-assigned id. Empty on create.
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

  /// Engine id from ListEngines, e.g. "postgres".
  @$pb.TagNumber(3)
  $core.String get engineId => $_getSZ(2);
  @$pb.TagNumber(3)
  set engineId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEngineId() => $_has(2);
  @$pb.TagNumber(3)
  void clearEngineId() => $_clearField(3);

  /// Engine-specific settings keyed by FieldSpec.key. Never holds secrets.
  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(3);

  /// Folder path in the sidebar tree, "/"-separated, e.g. "Work/Clients".
  /// Empty means the root.
  @$pb.TagNumber(5)
  $core.String get folder => $_getSZ(4);
  @$pb.TagNumber(5)
  set folder($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFolder() => $_has(4);
  @$pb.TagNumber(5)
  void clearFolder() => $_clearField(5);

  /// Color dot.
  @$pb.TagNumber(6)
  ColorTag get color => $_getN(5);
  @$pb.TagNumber(6)
  set color(ColorTag value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasColor() => $_has(5);
  @$pb.TagNumber(6)
  void clearColor() => $_clearField(6);

  /// Production connections get safety rails (read-only MCP, confirmations).
  @$pb.TagNumber(7)
  $core.bool get production => $_getBF(6);
  @$pb.TagNumber(7)
  set production($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProduction() => $_has(6);
  @$pb.TagNumber(7)
  void clearProduction() => $_clearField(7);

  /// Output only: whether a password is stored in the keychain.
  @$pb.TagNumber(8)
  $core.bool get hasPassword => $_getBF(7);
  @$pb.TagNumber(8)
  set hasPassword($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasPassword() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasPassword() => $_clearField(8);

  /// Output only: creation time.
  @$pb.TagNumber(9)
  $1.Timestamp get createdAt => $_getN(8);
  @$pb.TagNumber(9)
  set createdAt($1.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureCreatedAt() => $_ensure(8);

  /// Output only: last update time.
  @$pb.TagNumber(10)
  $1.Timestamp get updatedAt => $_getN(9);
  @$pb.TagNumber(10)
  set updatedAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureUpdatedAt() => $_ensure(9);
}

/// FieldSpec describes one connection form field.
class FieldSpec extends $pb.GeneratedMessage {
  factory FieldSpec({
    $core.String? key,
    $core.String? label,
    FieldKind? kind,
    $core.bool? required,
    $core.String? defaultValue,
    $core.String? placeholder,
    $core.Iterable<$core.String>? options,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (kind != null) result.kind = kind;
    if (required != null) result.required = required;
    if (defaultValue != null) result.defaultValue = defaultValue;
    if (placeholder != null) result.placeholder = placeholder;
    if (options != null) result.options.addAll(options);
    return result;
  }

  FieldSpec._();

  factory FieldSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FieldSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FieldSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aE<FieldKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: FieldKind.values)
    ..aOB(4, _omitFieldNames ? '' : 'required')
    ..aOS(5, _omitFieldNames ? '' : 'defaultValue')
    ..aOS(6, _omitFieldNames ? '' : 'placeholder')
    ..pPS(7, _omitFieldNames ? '' : 'options')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldSpec copyWith(void Function(FieldSpec) updates) =>
      super.copyWith((message) => updates(message as FieldSpec)) as FieldSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldSpec create() => FieldSpec._();
  @$core.override
  FieldSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FieldSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldSpec>(create);
  static FieldSpec? _defaultInstance;

  /// Params key, e.g. "host".
  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  /// Human label, e.g. "Host".
  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  /// Widget kind.
  @$pb.TagNumber(3)
  FieldKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(FieldKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// Whether the field must be non-empty to save.
  @$pb.TagNumber(4)
  $core.bool get required => $_getBF(3);
  @$pb.TagNumber(4)
  set required($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequired() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequired() => $_clearField(4);

  /// Default value for new connections.
  @$pb.TagNumber(5)
  $core.String get defaultValue => $_getSZ(4);
  @$pb.TagNumber(5)
  set defaultValue($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultValue() => $_clearField(5);

  /// Placeholder text.
  @$pb.TagNumber(6)
  $core.String get placeholder => $_getSZ(5);
  @$pb.TagNumber(6)
  set placeholder($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlaceholder() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlaceholder() => $_clearField(6);

  /// Allowed values for FIELD_KIND_SELECT.
  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get options => $_getList(6);
}

/// EngineInfo describes a supported engine.
class EngineInfo extends $pb.GeneratedMessage {
  factory EngineInfo({
    $core.String? id,
    $core.String? displayName,
    $core.String? family,
    $core.Iterable<FieldSpec>? fields,
    $core.bool? supportsUri,
    $core.Iterable<$core.String>? capabilities,
    $core.String? uriExample,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (displayName != null) result.displayName = displayName;
    if (family != null) result.family = family;
    if (fields != null) result.fields.addAll(fields);
    if (supportsUri != null) result.supportsUri = supportsUri;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    if (uriExample != null) result.uriExample = uriExample;
    return result;
  }

  EngineInfo._();

  factory EngineInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'family')
    ..pPM<FieldSpec>(4, _omitFieldNames ? '' : 'fields',
        subBuilder: FieldSpec.create)
    ..aOB(5, _omitFieldNames ? '' : 'supportsUri')
    ..pPS(6, _omitFieldNames ? '' : 'capabilities')
    ..aOS(7, _omitFieldNames ? '' : 'uriExample')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineInfo copyWith(void Function(EngineInfo) updates) =>
      super.copyWith((message) => updates(message as EngineInfo)) as EngineInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineInfo create() => EngineInfo._();
  @$core.override
  EngineInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineInfo>(create);
  static EngineInfo? _defaultInstance;

  /// Stable id, e.g. "postgres", "cockroachdb", "sqlite".
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Display name, e.g. "PostgreSQL".
  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  /// Wire-compatible family, e.g. "postgres" for CockroachDB. Equals id for
  /// primary engines.
  @$pb.TagNumber(3)
  $core.String get family => $_getSZ(2);
  @$pb.TagNumber(3)
  set family($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFamily() => $_has(2);
  @$pb.TagNumber(3)
  void clearFamily() => $_clearField(3);

  /// Form fields in display order.
  @$pb.TagNumber(4)
  $pb.PbList<FieldSpec> get fields => $_getList(3);

  /// Whether ParseConnectionString accepts URIs for this engine.
  @$pb.TagNumber(5)
  $core.bool get supportsUri => $_getBF(4);
  @$pb.TagNumber(5)
  set supportsUri($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSupportsUri() => $_has(4);
  @$pb.TagNumber(5)
  void clearSupportsUri() => $_clearField(5);

  /// Engine capability names, e.g. "connect". Unknown names must be ignored.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get capabilities => $_getList(5);

  /// Example URI shown as a placeholder, e.g. "postgres://user@host:5432/db".
  @$pb.TagNumber(7)
  $core.String get uriExample => $_getSZ(6);
  @$pb.TagNumber(7)
  set uriExample($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUriExample() => $_has(6);
  @$pb.TagNumber(7)
  void clearUriExample() => $_clearField(7);
}

/// ServerInfo is what a successful test learned about the server.
class ServerInfo extends $pb.GeneratedMessage {
  factory ServerInfo({
    $core.String? product,
    $core.String? version,
    $core.String? banner,
  }) {
    final result = create();
    if (product != null) result.product = product;
    if (version != null) result.version = version;
    if (banner != null) result.banner = banner;
    return result;
  }

  ServerInfo._();

  factory ServerInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'product')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'banner')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerInfo copyWith(void Function(ServerInfo) updates) =>
      super.copyWith((message) => updates(message as ServerInfo)) as ServerInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerInfo create() => ServerInfo._();
  @$core.override
  ServerInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerInfo>(create);
  static ServerInfo? _defaultInstance;

  /// Product name, e.g. "PostgreSQL", "CockroachDB", "SQLite".
  @$pb.TagNumber(1)
  $core.String get product => $_getSZ(0);
  @$pb.TagNumber(1)
  set product($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProduct() => $_has(0);
  @$pb.TagNumber(1)
  void clearProduct() => $_clearField(1);

  /// Version string, e.g. "17.11".
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  /// Full version banner if the server provides one.
  @$pb.TagNumber(3)
  $core.String get banner => $_getSZ(2);
  @$pb.TagNumber(3)
  set banner($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBanner() => $_has(2);
  @$pb.TagNumber(3)
  void clearBanner() => $_clearField(3);
}

/// ConnectionError is a typed failure. The message never contains secrets.
class ConnectionError extends $pb.GeneratedMessage {
  factory ConnectionError({
    ErrorKind? kind,
    $core.String? message,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    return result;
  }

  ConnectionError._();

  factory ConnectionError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectionError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<ErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: ErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionError copyWith(void Function(ConnectionError) updates) =>
      super.copyWith((message) => updates(message as ConnectionError))
          as ConnectionError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionError create() => ConnectionError._();
  @$core.override
  ConnectionError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectionError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionError>(create);
  static ConnectionError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  ErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(ErrorKind value) => $_setField(1, value);
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

/// ListEnginesRequest is empty.
class ListEnginesRequest extends $pb.GeneratedMessage {
  factory ListEnginesRequest() => create();

  ListEnginesRequest._();

  factory ListEnginesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEnginesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEnginesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesRequest copyWith(void Function(ListEnginesRequest) updates) =>
      super.copyWith((message) => updates(message as ListEnginesRequest))
          as ListEnginesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEnginesRequest create() => ListEnginesRequest._();
  @$core.override
  ListEnginesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEnginesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEnginesRequest>(create);
  static ListEnginesRequest? _defaultInstance;
}

/// ListEnginesResponse lists supported engines.
class ListEnginesResponse extends $pb.GeneratedMessage {
  factory ListEnginesResponse({
    $core.Iterable<EngineInfo>? engines,
  }) {
    final result = create();
    if (engines != null) result.engines.addAll(engines);
    return result;
  }

  ListEnginesResponse._();

  factory ListEnginesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEnginesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEnginesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<EngineInfo>(1, _omitFieldNames ? '' : 'engines',
        subBuilder: EngineInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEnginesResponse copyWith(void Function(ListEnginesResponse) updates) =>
      super.copyWith((message) => updates(message as ListEnginesResponse))
          as ListEnginesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEnginesResponse create() => ListEnginesResponse._();
  @$core.override
  ListEnginesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEnginesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEnginesResponse>(create);
  static ListEnginesResponse? _defaultInstance;

  /// Engines in display order.
  @$pb.TagNumber(1)
  $pb.PbList<EngineInfo> get engines => $_getList(0);
}

/// ListConnectionsRequest is empty.
class ListConnectionsRequest extends $pb.GeneratedMessage {
  factory ListConnectionsRequest() => create();

  ListConnectionsRequest._();

  factory ListConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest copyWith(
          void Function(ListConnectionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsRequest))
          as ListConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest create() => ListConnectionsRequest._();
  @$core.override
  ListConnectionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsRequest>(create);
  static ListConnectionsRequest? _defaultInstance;
}

/// ListConnectionsResponse lists saved connections.
class ListConnectionsResponse extends $pb.GeneratedMessage {
  factory ListConnectionsResponse({
    $core.Iterable<Connection>? connections,
  }) {
    final result = create();
    if (connections != null) result.connections.addAll(connections);
    return result;
  }

  ListConnectionsResponse._();

  factory ListConnectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListConnectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConnectionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<Connection>(1, _omitFieldNames ? '' : 'connections',
        subBuilder: Connection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse copyWith(
          void Function(ListConnectionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsResponse))
          as ListConnectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse create() => ListConnectionsResponse._();
  @$core.override
  ListConnectionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsResponse>(create);
  static ListConnectionsResponse? _defaultInstance;

  /// Saved connections.
  @$pb.TagNumber(1)
  $pb.PbList<Connection> get connections => $_getList(0);
}

/// GetConnectionRequest selects a connection.
class GetConnectionRequest extends $pb.GeneratedMessage {
  factory GetConnectionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetConnectionRequest._();

  factory GetConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionRequest copyWith(void Function(GetConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as GetConnectionRequest))
          as GetConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConnectionRequest create() => GetConnectionRequest._();
  @$core.override
  GetConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionRequest>(create);
  static GetConnectionRequest? _defaultInstance;

  /// Connection id.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// GetConnectionResponse holds one connection.
class GetConnectionResponse extends $pb.GeneratedMessage {
  factory GetConnectionResponse({
    Connection? connection,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    return result;
  }

  GetConnectionResponse._();

  factory GetConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<Connection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionResponse copyWith(
          void Function(GetConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as GetConnectionResponse))
          as GetConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConnectionResponse create() => GetConnectionResponse._();
  @$core.override
  GetConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionResponse>(create);
  static GetConnectionResponse? _defaultInstance;

  /// The connection.
  @$pb.TagNumber(1)
  Connection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(Connection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  Connection ensureConnection() => $_ensure(0);
}

/// CreateConnectionRequest saves a new connection.
class CreateConnectionRequest extends $pb.GeneratedMessage {
  factory CreateConnectionRequest({
    Connection? connection,
    $core.String? password,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    if (password != null) result.password = password;
    return result;
  }

  CreateConnectionRequest._();

  factory CreateConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<Connection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateConnectionRequest copyWith(
          void Function(CreateConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateConnectionRequest))
          as CreateConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateConnectionRequest create() => CreateConnectionRequest._();
  @$core.override
  CreateConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateConnectionRequest>(create);
  static CreateConnectionRequest? _defaultInstance;

  /// Settings; id and output-only fields are ignored.
  @$pb.TagNumber(1)
  Connection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(Connection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  Connection ensureConnection() => $_ensure(0);

  /// Password to store in the keychain. Unset or empty stores none.
  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

/// CreateConnectionResponse returns the saved connection.
class CreateConnectionResponse extends $pb.GeneratedMessage {
  factory CreateConnectionResponse({
    Connection? connection,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    return result;
  }

  CreateConnectionResponse._();

  factory CreateConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<Connection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateConnectionResponse copyWith(
          void Function(CreateConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as CreateConnectionResponse))
          as CreateConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateConnectionResponse create() => CreateConnectionResponse._();
  @$core.override
  CreateConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateConnectionResponse>(create);
  static CreateConnectionResponse? _defaultInstance;

  /// The saved connection with its new id.
  @$pb.TagNumber(1)
  Connection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(Connection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  Connection ensureConnection() => $_ensure(0);
}

/// UpdateConnectionRequest replaces a connection's settings.
class UpdateConnectionRequest extends $pb.GeneratedMessage {
  factory UpdateConnectionRequest({
    Connection? connection,
    $core.String? password,
    $core.bool? clearPassword_3,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    if (password != null) result.password = password;
    if (clearPassword_3 != null) result.clearPassword_3 = clearPassword_3;
    return result;
  }

  UpdateConnectionRequest._();

  factory UpdateConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<Connection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOB(3, _omitFieldNames ? '' : 'clearPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConnectionRequest copyWith(
          void Function(UpdateConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateConnectionRequest))
          as UpdateConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateConnectionRequest create() => UpdateConnectionRequest._();
  @$core.override
  UpdateConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateConnectionRequest>(create);
  static UpdateConnectionRequest? _defaultInstance;

  /// New settings; id selects the connection.
  @$pb.TagNumber(1)
  Connection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(Connection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  Connection ensureConnection() => $_ensure(0);

  /// New password. Unset keeps the stored one.
  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  /// Remove the stored password. Ignored if password is set.
  @$pb.TagNumber(3)
  $core.bool get clearPassword_3 => $_getBF(2);
  @$pb.TagNumber(3)
  set clearPassword_3($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClearPassword_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearClearPassword_3() => $_clearField(3);
}

/// UpdateConnectionResponse returns the updated connection.
class UpdateConnectionResponse extends $pb.GeneratedMessage {
  factory UpdateConnectionResponse({
    Connection? connection,
  }) {
    final result = create();
    if (connection != null) result.connection = connection;
    return result;
  }

  UpdateConnectionResponse._();

  factory UpdateConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<Connection>(1, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateConnectionResponse copyWith(
          void Function(UpdateConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateConnectionResponse))
          as UpdateConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateConnectionResponse create() => UpdateConnectionResponse._();
  @$core.override
  UpdateConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateConnectionResponse>(create);
  static UpdateConnectionResponse? _defaultInstance;

  /// The updated connection.
  @$pb.TagNumber(1)
  Connection get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(Connection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  Connection ensureConnection() => $_ensure(0);
}

/// DeleteConnectionRequest selects a connection to delete.
class DeleteConnectionRequest extends $pb.GeneratedMessage {
  factory DeleteConnectionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeleteConnectionRequest._();

  factory DeleteConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionRequest copyWith(
          void Function(DeleteConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteConnectionRequest))
          as DeleteConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteConnectionRequest create() => DeleteConnectionRequest._();
  @$core.override
  DeleteConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteConnectionRequest>(create);
  static DeleteConnectionRequest? _defaultInstance;

  /// Connection id.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// DeleteConnectionResponse is empty.
class DeleteConnectionResponse extends $pb.GeneratedMessage {
  factory DeleteConnectionResponse() => create();

  DeleteConnectionResponse._();

  factory DeleteConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteConnectionResponse copyWith(
          void Function(DeleteConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteConnectionResponse))
          as DeleteConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteConnectionResponse create() => DeleteConnectionResponse._();
  @$core.override
  DeleteConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteConnectionResponse>(create);
  static DeleteConnectionResponse? _defaultInstance;
}

/// TestConnectionRequest selects what to test. Either id, draft, or both:
/// with both, draft settings are tested and the password falls back to the
/// one stored for id (for testing while editing).
class TestConnectionRequest extends $pb.GeneratedMessage {
  factory TestConnectionRequest({
    $core.String? id,
    Connection? draft,
    $core.String? password,
    $core.int? timeoutMs,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (draft != null) result.draft = draft;
    if (password != null) result.password = password;
    if (timeoutMs != null) result.timeoutMs = timeoutMs;
    return result;
  }

  TestConnectionRequest._();

  factory TestConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<Connection>(2, _omitFieldNames ? '' : 'draft',
        subBuilder: Connection.create)
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aI(4, _omitFieldNames ? '' : 'timeoutMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionRequest copyWith(
          void Function(TestConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as TestConnectionRequest))
          as TestConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestConnectionRequest create() => TestConnectionRequest._();
  @$core.override
  TestConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestConnectionRequest>(create);
  static TestConnectionRequest? _defaultInstance;

  /// Saved connection id.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Unsaved settings to test.
  @$pb.TagNumber(2)
  Connection get draft => $_getN(1);
  @$pb.TagNumber(2)
  set draft(Connection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDraft() => $_has(1);
  @$pb.TagNumber(2)
  void clearDraft() => $_clearField(2);
  @$pb.TagNumber(2)
  Connection ensureDraft() => $_ensure(1);

  /// Password to use. Unset falls back to the keychain entry for id.
  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  /// Timeout in milliseconds. 0 means the default (10000). The core clamps
  /// values to [1000, 60000].
  @$pb.TagNumber(4)
  $core.int get timeoutMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set timeoutMs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimeoutMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimeoutMs() => $_clearField(4);
}

/// TestConnectionResponse reports the test result.
class TestConnectionResponse extends $pb.GeneratedMessage {
  factory TestConnectionResponse({
    $core.bool? ok,
    ServerInfo? server,
    $core.int? connectMs,
    $core.int? latencyMs,
    ConnectionError? error,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (server != null) result.server = server;
    if (connectMs != null) result.connectMs = connectMs;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (error != null) result.error = error;
    return result;
  }

  TestConnectionResponse._();

  factory TestConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOM<ServerInfo>(2, _omitFieldNames ? '' : 'server',
        subBuilder: ServerInfo.create)
    ..aI(3, _omitFieldNames ? '' : 'connectMs', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'latencyMs', fieldType: $pb.PbFieldType.OU3)
    ..aOM<ConnectionError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: ConnectionError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestConnectionResponse copyWith(
          void Function(TestConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as TestConnectionResponse))
          as TestConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestConnectionResponse create() => TestConnectionResponse._();
  @$core.override
  TestConnectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestConnectionResponse>(create);
  static TestConnectionResponse? _defaultInstance;

  /// Whether connect + ping succeeded.
  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  /// Server details when ok.
  @$pb.TagNumber(2)
  ServerInfo get server => $_getN(1);
  @$pb.TagNumber(2)
  set server(ServerInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);
  @$pb.TagNumber(2)
  ServerInfo ensureServer() => $_ensure(1);

  /// Time to establish the connection, in milliseconds.
  @$pb.TagNumber(3)
  $core.int get connectMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set connectMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConnectMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectMs() => $_clearField(3);

  /// Ping round-trip latency, in milliseconds.
  @$pb.TagNumber(4)
  $core.int get latencyMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set latencyMs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLatencyMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatencyMs() => $_clearField(4);

  /// Failure detail when not ok.
  @$pb.TagNumber(5)
  ConnectionError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(ConnectionError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  ConnectionError ensureError() => $_ensure(4);
}

/// ParseConnectionStringRequest asks the core to parse a URI or DSN.
class ParseConnectionStringRequest extends $pb.GeneratedMessage {
  factory ParseConnectionStringRequest({
    $core.String? engineId,
    $core.String? connectionString,
  }) {
    final result = create();
    if (engineId != null) result.engineId = engineId;
    if (connectionString != null) result.connectionString = connectionString;
    return result;
  }

  ParseConnectionStringRequest._();

  factory ParseConnectionStringRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseConnectionStringRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseConnectionStringRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'engineId')
    ..aOS(2, _omitFieldNames ? '' : 'connectionString')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseConnectionStringRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseConnectionStringRequest copyWith(
          void Function(ParseConnectionStringRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ParseConnectionStringRequest))
          as ParseConnectionStringRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseConnectionStringRequest create() =>
      ParseConnectionStringRequest._();
  @$core.override
  ParseConnectionStringRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseConnectionStringRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseConnectionStringRequest>(create);
  static ParseConnectionStringRequest? _defaultInstance;

  /// Engine id the string is for.
  @$pb.TagNumber(1)
  $core.String get engineId => $_getSZ(0);
  @$pb.TagNumber(1)
  set engineId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEngineId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEngineId() => $_clearField(1);

  /// The URI or DSN.
  @$pb.TagNumber(2)
  $core.String get connectionString => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectionString($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionString() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionString() => $_clearField(2);
}

/// ParseConnectionStringResponse holds the parsed fields.
class ParseConnectionStringResponse extends $pb.GeneratedMessage {
  factory ParseConnectionStringResponse({
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
    $core.String? password,
  }) {
    final result = create();
    if (params != null) result.params.addEntries(params);
    if (password != null) result.password = password;
    return result;
  }

  ParseConnectionStringResponse._();

  factory ParseConnectionStringResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParseConnectionStringResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParseConnectionStringResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'params',
        entryClassName: 'ParseConnectionStringResponse.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('queravue.v1'))
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseConnectionStringResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseConnectionStringResponse copyWith(
          void Function(ParseConnectionStringResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ParseConnectionStringResponse))
          as ParseConnectionStringResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseConnectionStringResponse create() =>
      ParseConnectionStringResponse._();
  @$core.override
  ParseConnectionStringResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParseConnectionStringResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParseConnectionStringResponse>(create);
  static ParseConnectionStringResponse? _defaultInstance;

  /// Params keyed by FieldSpec.key. Never holds the password.
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(0);

  /// Password found in the string, if any.
  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
