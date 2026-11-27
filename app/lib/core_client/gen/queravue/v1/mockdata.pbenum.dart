// This is a generated file - do not edit.
//
// Generated from queravue/v1/mockdata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// MockErrorKind classifies a mock data failure.
class MockErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const MockErrorKind MOCK_ERROR_KIND_UNSPECIFIED =
      MockErrorKind._(0, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_UNSPECIFIED');

  /// A rule is malformed, e.g. an empty range or an unknown faker kind.
  static const MockErrorKind MOCK_ERROR_KIND_PARSE =
      MockErrorKind._(1, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_PARSE');

  /// The targets' foreign keys form a cycle with no nullable edge set to null.
  static const MockErrorKind MOCK_ERROR_KIND_CYCLE =
      MockErrorKind._(2, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_CYCLE');

  /// A unique rule ran out of distinct values.
  static const MockErrorKind MOCK_ERROR_KIND_UNIQUE_EXHAUSTED = MockErrorKind._(
      3, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_UNIQUE_EXHAUSTED');

  /// The server rejected a row for a constraint.
  static const MockErrorKind MOCK_ERROR_KIND_CONSTRAINT =
      MockErrorKind._(4, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_CONSTRAINT');

  /// The connection is flagged production and the request did not set
  /// confirmed. Nothing was changed.
  static const MockErrorKind MOCK_ERROR_KIND_CONFIRMATION_REQUIRED =
      MockErrorKind._(
          5, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// Bad credentials or not permitted.
  static const MockErrorKind MOCK_ERROR_KIND_AUTH =
      MockErrorKind._(6, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_AUTH');

  /// Server unreachable or connection lost.
  static const MockErrorKind MOCK_ERROR_KIND_NETWORK =
      MockErrorKind._(7, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_NETWORK');

  /// The operation exceeded its time limit.
  static const MockErrorKind MOCK_ERROR_KIND_TIMEOUT =
      MockErrorKind._(8, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_TIMEOUT');

  /// The run was cancelled.
  static const MockErrorKind MOCK_ERROR_KIND_CANCELED =
      MockErrorKind._(9, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_CANCELED');

  /// The engine or a column type is not supported.
  static const MockErrorKind MOCK_ERROR_KIND_UNSUPPORTED =
      MockErrorKind._(10, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_UNSUPPORTED');

  /// The server rejected the operation.
  static const MockErrorKind MOCK_ERROR_KIND_SERVER =
      MockErrorKind._(11, _omitEnumNames ? '' : 'MOCK_ERROR_KIND_SERVER');

  static const $core.List<MockErrorKind> values = <MockErrorKind>[
    MOCK_ERROR_KIND_UNSPECIFIED,
    MOCK_ERROR_KIND_PARSE,
    MOCK_ERROR_KIND_CYCLE,
    MOCK_ERROR_KIND_UNIQUE_EXHAUSTED,
    MOCK_ERROR_KIND_CONSTRAINT,
    MOCK_ERROR_KIND_CONFIRMATION_REQUIRED,
    MOCK_ERROR_KIND_AUTH,
    MOCK_ERROR_KIND_NETWORK,
    MOCK_ERROR_KIND_TIMEOUT,
    MOCK_ERROR_KIND_CANCELED,
    MOCK_ERROR_KIND_UNSUPPORTED,
    MOCK_ERROR_KIND_SERVER,
  ];

  static final $core.List<MockErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static MockErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MockErrorKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
