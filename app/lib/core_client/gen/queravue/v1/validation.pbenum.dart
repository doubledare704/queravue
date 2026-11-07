// This is a generated file - do not edit.
//
// Generated from queravue/v1/validation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ValidationLevel says which writes the validator applies to.
class ValidationLevel extends $pb.ProtobufEnum {
  /// Unspecified. On set, keeps the server default (strict).
  static const ValidationLevel VALIDATION_LEVEL_UNSPECIFIED = ValidationLevel._(
      0, _omitEnumNames ? '' : 'VALIDATION_LEVEL_UNSPECIFIED');

  /// Validation is off.
  static const ValidationLevel VALIDATION_LEVEL_OFF =
      ValidationLevel._(1, _omitEnumNames ? '' : 'VALIDATION_LEVEL_OFF');

  /// Applies to inserts and to updates of documents that already satisfy the validator.
  static const ValidationLevel VALIDATION_LEVEL_MODERATE =
      ValidationLevel._(2, _omitEnumNames ? '' : 'VALIDATION_LEVEL_MODERATE');

  /// Applies to all inserts and updates.
  static const ValidationLevel VALIDATION_LEVEL_STRICT =
      ValidationLevel._(3, _omitEnumNames ? '' : 'VALIDATION_LEVEL_STRICT');

  static const $core.List<ValidationLevel> values = <ValidationLevel>[
    VALIDATION_LEVEL_UNSPECIFIED,
    VALIDATION_LEVEL_OFF,
    VALIDATION_LEVEL_MODERATE,
    VALIDATION_LEVEL_STRICT,
  ];

  static final $core.List<ValidationLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ValidationLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ValidationLevel._(super.value, super.name);
}

/// ValidationAction says what happens to a document that fails validation.
class ValidationAction extends $pb.ProtobufEnum {
  /// Unspecified. On set, keeps the server default (error).
  static const ValidationAction VALIDATION_ACTION_UNSPECIFIED =
      ValidationAction._(
          0, _omitEnumNames ? '' : 'VALIDATION_ACTION_UNSPECIFIED');

  /// Reject the write.
  static const ValidationAction VALIDATION_ACTION_ERROR =
      ValidationAction._(1, _omitEnumNames ? '' : 'VALIDATION_ACTION_ERROR');

  /// Accept the write and log a warning on the server.
  static const ValidationAction VALIDATION_ACTION_WARN =
      ValidationAction._(2, _omitEnumNames ? '' : 'VALIDATION_ACTION_WARN');

  static const $core.List<ValidationAction> values = <ValidationAction>[
    VALIDATION_ACTION_UNSPECIFIED,
    VALIDATION_ACTION_ERROR,
    VALIDATION_ACTION_WARN,
  ];

  static final $core.List<ValidationAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ValidationAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ValidationAction._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
