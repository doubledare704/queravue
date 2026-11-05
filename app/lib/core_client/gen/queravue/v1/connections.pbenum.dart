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

/// ColorTag is the color dot shown next to a connection, e.g. red for prod.
class ColorTag extends $pb.ProtobufEnum {
  /// No color.
  static const ColorTag COLOR_TAG_UNSPECIFIED =
      ColorTag._(0, _omitEnumNames ? '' : 'COLOR_TAG_UNSPECIFIED');

  /// Red.
  static const ColorTag COLOR_TAG_RED =
      ColorTag._(1, _omitEnumNames ? '' : 'COLOR_TAG_RED');

  /// Orange.
  static const ColorTag COLOR_TAG_ORANGE =
      ColorTag._(2, _omitEnumNames ? '' : 'COLOR_TAG_ORANGE');

  /// Yellow.
  static const ColorTag COLOR_TAG_YELLOW =
      ColorTag._(3, _omitEnumNames ? '' : 'COLOR_TAG_YELLOW');

  /// Green.
  static const ColorTag COLOR_TAG_GREEN =
      ColorTag._(4, _omitEnumNames ? '' : 'COLOR_TAG_GREEN');

  /// Blue.
  static const ColorTag COLOR_TAG_BLUE =
      ColorTag._(5, _omitEnumNames ? '' : 'COLOR_TAG_BLUE');

  /// Purple.
  static const ColorTag COLOR_TAG_PURPLE =
      ColorTag._(6, _omitEnumNames ? '' : 'COLOR_TAG_PURPLE');

  /// Gray.
  static const ColorTag COLOR_TAG_GRAY =
      ColorTag._(7, _omitEnumNames ? '' : 'COLOR_TAG_GRAY');

  static const $core.List<ColorTag> values = <ColorTag>[
    COLOR_TAG_UNSPECIFIED,
    COLOR_TAG_RED,
    COLOR_TAG_ORANGE,
    COLOR_TAG_YELLOW,
    COLOR_TAG_GREEN,
    COLOR_TAG_BLUE,
    COLOR_TAG_PURPLE,
    COLOR_TAG_GRAY,
  ];

  static final $core.List<ColorTag?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ColorTag? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColorTag._(super.value, super.name);
}

/// FieldKind tells the UI which input widget to render.
class FieldKind extends $pb.ProtobufEnum {
  /// Not set; render as text.
  static const FieldKind FIELD_KIND_UNSPECIFIED =
      FieldKind._(0, _omitEnumNames ? '' : 'FIELD_KIND_UNSPECIFIED');

  /// Single-line text.
  static const FieldKind FIELD_KIND_TEXT =
      FieldKind._(1, _omitEnumNames ? '' : 'FIELD_KIND_TEXT');

  /// Integer, e.g. a port.
  static const FieldKind FIELD_KIND_INTEGER =
      FieldKind._(2, _omitEnumNames ? '' : 'FIELD_KIND_INTEGER');

  /// Secret; stored in the keychain, sent only in the password fields of
  /// requests, never in params.
  static const FieldKind FIELD_KIND_PASSWORD =
      FieldKind._(3, _omitEnumNames ? '' : 'FIELD_KIND_PASSWORD');

  /// Local file path with a file picker.
  static const FieldKind FIELD_KIND_FILE =
      FieldKind._(4, _omitEnumNames ? '' : 'FIELD_KIND_FILE');

  /// Checkbox; value "true" or "false".
  static const FieldKind FIELD_KIND_BOOLEAN =
      FieldKind._(5, _omitEnumNames ? '' : 'FIELD_KIND_BOOLEAN');

  /// One of FieldSpec.options.
  static const FieldKind FIELD_KIND_SELECT =
      FieldKind._(6, _omitEnumNames ? '' : 'FIELD_KIND_SELECT');

  static const $core.List<FieldKind> values = <FieldKind>[
    FIELD_KIND_UNSPECIFIED,
    FIELD_KIND_TEXT,
    FIELD_KIND_INTEGER,
    FIELD_KIND_PASSWORD,
    FIELD_KIND_FILE,
    FIELD_KIND_BOOLEAN,
    FIELD_KIND_SELECT,
  ];

  static final $core.List<FieldKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static FieldKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FieldKind._(super.value, super.name);
}

/// ErrorKind classifies a connection failure.
class ErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const ErrorKind ERROR_KIND_UNSPECIFIED =
      ErrorKind._(0, _omitEnumNames ? '' : 'ERROR_KIND_UNSPECIFIED');

  /// Bad credentials or not permitted.
  static const ErrorKind ERROR_KIND_AUTH =
      ErrorKind._(1, _omitEnumNames ? '' : 'ERROR_KIND_AUTH');

  /// Host unreachable, refused, DNS failure.
  static const ErrorKind ERROR_KIND_NETWORK =
      ErrorKind._(2, _omitEnumNames ? '' : 'ERROR_KIND_NETWORK');

  /// TLS handshake or certificate problem.
  static const ErrorKind ERROR_KIND_TLS =
      ErrorKind._(3, _omitEnumNames ? '' : 'ERROR_KIND_TLS');

  /// Database, file or other target does not exist.
  static const ErrorKind ERROR_KIND_NOT_FOUND =
      ErrorKind._(4, _omitEnumNames ? '' : 'ERROR_KIND_NOT_FOUND');

  /// The operation exceeded its timeout.
  static const ErrorKind ERROR_KIND_TIMEOUT =
      ErrorKind._(5, _omitEnumNames ? '' : 'ERROR_KIND_TIMEOUT');

  /// The settings are invalid (missing field, bad port...).
  static const ErrorKind ERROR_KIND_INVALID_CONFIG =
      ErrorKind._(6, _omitEnumNames ? '' : 'ERROR_KIND_INVALID_CONFIG');

  static const $core.List<ErrorKind> values = <ErrorKind>[
    ERROR_KIND_UNSPECIFIED,
    ERROR_KIND_AUTH,
    ERROR_KIND_NETWORK,
    ERROR_KIND_TLS,
    ERROR_KIND_NOT_FOUND,
    ERROR_KIND_TIMEOUT,
    ERROR_KIND_INVALID_CONFIG,
  ];

  static final $core.List<ErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
