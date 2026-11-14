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

import 'package:protobuf/protobuf.dart' as $pb;

/// KeyValueErrorKind classifies a failed key-value call.
class KeyValueErrorKind extends $pb.ProtobufEnum {
  /// Unspecified. Never sent.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_UNSPECIFIED =
      KeyValueErrorKind._(
          0, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_UNSPECIFIED');

  /// Refused and nothing changed. Repeat with confirmed=true after the user
  /// agrees; `operation` says what to confirm.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED =
      KeyValueErrorKind._(1,
          _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// The command or module is not available on this server.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_UNSUPPORTED =
      KeyValueErrorKind._(
          2, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_UNSUPPORTED');

  /// The request is malformed.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_INVALID =
      KeyValueErrorKind._(
          3, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_INVALID');

  /// The key does not exist.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_NOT_FOUND =
      KeyValueErrorKind._(
          4, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_NOT_FOUND');

  /// The server rejected the command; message carries its explanation.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_SERVER =
      KeyValueErrorKind._(
          5, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_SERVER');

  /// The operation was cancelled.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_CANCELED =
      KeyValueErrorKind._(
          6, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_CANCELED');

  /// KEYS was used; message points to ScanKeys.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_KEYS_REFUSED =
      KeyValueErrorKind._(
          7, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_KEYS_REFUSED');

  /// A blocking command was used; message points to Subscribe.
  static const KeyValueErrorKind KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED =
      KeyValueErrorKind._(
          8, _omitEnumNames ? '' : 'KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED');

  static const $core.List<KeyValueErrorKind> values = <KeyValueErrorKind>[
    KEY_VALUE_ERROR_KIND_UNSPECIFIED,
    KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED,
    KEY_VALUE_ERROR_KIND_UNSUPPORTED,
    KEY_VALUE_ERROR_KIND_INVALID,
    KEY_VALUE_ERROR_KIND_NOT_FOUND,
    KEY_VALUE_ERROR_KIND_SERVER,
    KEY_VALUE_ERROR_KIND_CANCELED,
    KEY_VALUE_ERROR_KIND_KEYS_REFUSED,
    KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED,
  ];

  static final $core.List<KeyValueErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static KeyValueErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KeyValueErrorKind._(super.value, super.name);
}

/// KeyType is the Redis data type of a key.
class KeyType extends $pb.ProtobufEnum {
  /// Unknown or not loaded yet.
  static const KeyType KEY_TYPE_UNSPECIFIED =
      KeyType._(0, _omitEnumNames ? '' : 'KEY_TYPE_UNSPECIFIED');

  /// String.
  static const KeyType KEY_TYPE_STRING =
      KeyType._(1, _omitEnumNames ? '' : 'KEY_TYPE_STRING');

  /// Hash.
  static const KeyType KEY_TYPE_HASH =
      KeyType._(2, _omitEnumNames ? '' : 'KEY_TYPE_HASH');

  /// List.
  static const KeyType KEY_TYPE_LIST =
      KeyType._(3, _omitEnumNames ? '' : 'KEY_TYPE_LIST');

  /// Set.
  static const KeyType KEY_TYPE_SET =
      KeyType._(4, _omitEnumNames ? '' : 'KEY_TYPE_SET');

  /// Sorted set.
  static const KeyType KEY_TYPE_ZSET =
      KeyType._(5, _omitEnumNames ? '' : 'KEY_TYPE_ZSET');

  /// Stream.
  static const KeyType KEY_TYPE_STREAM =
      KeyType._(6, _omitEnumNames ? '' : 'KEY_TYPE_STREAM');

  /// ReJSON document.
  static const KeyType KEY_TYPE_JSON =
      KeyType._(7, _omitEnumNames ? '' : 'KEY_TYPE_JSON');

  /// HyperLogLog (a string with a count; no element access).
  static const KeyType KEY_TYPE_HYPERLOGLOG =
      KeyType._(8, _omitEnumNames ? '' : 'KEY_TYPE_HYPERLOGLOG');

  static const $core.List<KeyType> values = <KeyType>[
    KEY_TYPE_UNSPECIFIED,
    KEY_TYPE_STRING,
    KEY_TYPE_HASH,
    KEY_TYPE_LIST,
    KEY_TYPE_SET,
    KEY_TYPE_ZSET,
    KEY_TYPE_STREAM,
    KEY_TYPE_JSON,
    KEY_TYPE_HYPERLOGLOG,
  ];

  static final $core.List<KeyType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static KeyType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KeyType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
