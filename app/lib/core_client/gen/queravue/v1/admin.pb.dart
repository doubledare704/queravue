// This is a generated file - do not edit.
//
// Generated from queravue/v1/admin.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'admin.pbenum.dart';

/// AdminError describes why a schema-administration call did nothing or stopped early.
class AdminError extends $pb.GeneratedMessage {
  factory AdminError({
    AdminErrorKind? kind,
    $core.String? message,
    $core.String? operation,
    $core.int? position,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (operation != null) result.operation = operation;
    if (position != null) result.position = position;
    return result;
  }

  AdminError._();

  factory AdminError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdminError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<AdminErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: AdminErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'operation')
    ..aI(4, _omitFieldNames ? '' : 'position', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminError copyWith(void Function(AdminError) updates) =>
      super.copyWith((message) => updates(message as AdminError)) as AdminError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdminError create() => AdminError._();
  @$core.override
  AdminError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdminError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminError>(create);
  static AdminError? _defaultInstance;

  /// Failure category.
  @$pb.TagNumber(1)
  AdminErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(AdminErrorKind value) => $_setField(1, value);
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
  /// "drop index orders_status_idx" or "write to a production connection".
  @$pb.TagNumber(3)
  $core.String get operation => $_getSZ(2);
  @$pb.TagNumber(3)
  set operation($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOperation() => $_has(2);
  @$pb.TagNumber(3)
  void clearOperation() => $_clearField(3);

  /// For INVALID input that is text: 0-based UTF-16 offset of the failing character.
  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
