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

/// AdminErrorKind classifies a failed schema-administration call (indexes, stats,
/// validation, table design). Failures are returned in-band so the stream and
/// transport stay healthy.
class AdminErrorKind extends $pb.ProtobufEnum {
  /// Unspecified. Never sent.
  static const AdminErrorKind ADMIN_ERROR_KIND_UNSPECIFIED =
      AdminErrorKind._(0, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_UNSPECIFIED');

  /// The change was refused and nothing was changed. Repeat the request with
  /// confirmed=true after the user agrees.
  static const AdminErrorKind ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED =
      AdminErrorKind._(
          1, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// The server or engine does not support the operation (for example
  /// collMod validators on a server that rejects them).
  static const AdminErrorKind ADMIN_ERROR_KIND_UNSUPPORTED =
      AdminErrorKind._(2, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_UNSUPPORTED');

  /// The request is malformed or names something that cannot be built, such as
  /// an index without keys or a validator that is not valid JSON.
  static const AdminErrorKind ADMIN_ERROR_KIND_INVALID =
      AdminErrorKind._(3, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_INVALID');

  /// The table, collection, index or column does not exist.
  static const AdminErrorKind ADMIN_ERROR_KIND_NOT_FOUND =
      AdminErrorKind._(4, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_NOT_FOUND');

  /// The index, column or table already exists.
  static const AdminErrorKind ADMIN_ERROR_KIND_ALREADY_EXISTS =
      AdminErrorKind._(
          5, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_ALREADY_EXISTS');

  /// The server rejected the operation; message carries its explanation.
  static const AdminErrorKind ADMIN_ERROR_KIND_SERVER =
      AdminErrorKind._(6, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_SERVER');

  /// The operation was cancelled before it finished.
  static const AdminErrorKind ADMIN_ERROR_KIND_CANCELED =
      AdminErrorKind._(7, _omitEnumNames ? '' : 'ADMIN_ERROR_KIND_CANCELED');

  static const $core.List<AdminErrorKind> values = <AdminErrorKind>[
    ADMIN_ERROR_KIND_UNSPECIFIED,
    ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED,
    ADMIN_ERROR_KIND_UNSUPPORTED,
    ADMIN_ERROR_KIND_INVALID,
    ADMIN_ERROR_KIND_NOT_FOUND,
    ADMIN_ERROR_KIND_ALREADY_EXISTS,
    ADMIN_ERROR_KIND_SERVER,
    ADMIN_ERROR_KIND_CANCELED,
  ];

  static final $core.List<AdminErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static AdminErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdminErrorKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
