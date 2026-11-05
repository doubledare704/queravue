// This is a generated file - do not edit.
//
// Generated from queravue/v1/query.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ExecuteMode selects which statements of the text run.
class ExecuteMode extends $pb.ProtobufEnum {
  /// Not set. Treated as STATEMENT_AT_CURSOR.
  static const ExecuteMode EXECUTE_MODE_UNSPECIFIED =
      ExecuteMode._(0, _omitEnumNames ? '' : 'EXECUTE_MODE_UNSPECIFIED');

  /// Run the statement containing cursor_offset.
  static const ExecuteMode EXECUTE_MODE_STATEMENT_AT_CURSOR = ExecuteMode._(
      1, _omitEnumNames ? '' : 'EXECUTE_MODE_STATEMENT_AT_CURSOR');

  /// Run every statement inside `selection`.
  static const ExecuteMode EXECUTE_MODE_SELECTION =
      ExecuteMode._(2, _omitEnumNames ? '' : 'EXECUTE_MODE_SELECTION');

  /// Run every statement in the text.
  static const ExecuteMode EXECUTE_MODE_ALL =
      ExecuteMode._(3, _omitEnumNames ? '' : 'EXECUTE_MODE_ALL');

  static const $core.List<ExecuteMode> values = <ExecuteMode>[
    EXECUTE_MODE_UNSPECIFIED,
    EXECUTE_MODE_STATEMENT_AT_CURSOR,
    EXECUTE_MODE_SELECTION,
    EXECUTE_MODE_ALL,
  ];

  static final $core.List<ExecuteMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ExecuteMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExecuteMode._(super.value, super.name);
}

/// ValueKind is the general kind of a column, for alignment and formatting.
class ValueKind extends $pb.ProtobufEnum {
  /// Unknown; values arrive as text.
  static const ValueKind VALUE_KIND_UNSPECIFIED =
      ValueKind._(0, _omitEnumNames ? '' : 'VALUE_KIND_UNSPECIFIED');

  /// Boolean.
  static const ValueKind VALUE_KIND_BOOL =
      ValueKind._(1, _omitEnumNames ? '' : 'VALUE_KIND_BOOL');

  /// 64-bit integer.
  static const ValueKind VALUE_KIND_INT =
      ValueKind._(2, _omitEnumNames ? '' : 'VALUE_KIND_INT');

  /// 64-bit floating point.
  static const ValueKind VALUE_KIND_FLOAT =
      ValueKind._(3, _omitEnumNames ? '' : 'VALUE_KIND_FLOAT');

  /// Exact decimal, carried as a string.
  static const ValueKind VALUE_KIND_DECIMAL =
      ValueKind._(4, _omitEnumNames ? '' : 'VALUE_KIND_DECIMAL');

  /// Text.
  static const ValueKind VALUE_KIND_TEXT =
      ValueKind._(5, _omitEnumNames ? '' : 'VALUE_KIND_TEXT');

  /// Binary data.
  static const ValueKind VALUE_KIND_BYTES =
      ValueKind._(6, _omitEnumNames ? '' : 'VALUE_KIND_BYTES');

  /// Timestamp with time zone.
  static const ValueKind VALUE_KIND_TIMESTAMPTZ =
      ValueKind._(7, _omitEnumNames ? '' : 'VALUE_KIND_TIMESTAMPTZ');

  /// JSON document, carried as text.
  static const ValueKind VALUE_KIND_JSON =
      ValueKind._(8, _omitEnumNames ? '' : 'VALUE_KIND_JSON');

  /// UUID, carried as its canonical text form.
  static const ValueKind VALUE_KIND_UUID =
      ValueKind._(9, _omitEnumNames ? '' : 'VALUE_KIND_UUID');

  /// Array of values.
  static const ValueKind VALUE_KIND_ARRAY =
      ValueKind._(10, _omitEnumNames ? '' : 'VALUE_KIND_ARRAY');

  static const $core.List<ValueKind> values = <ValueKind>[
    VALUE_KIND_UNSPECIFIED,
    VALUE_KIND_BOOL,
    VALUE_KIND_INT,
    VALUE_KIND_FLOAT,
    VALUE_KIND_DECIMAL,
    VALUE_KIND_TEXT,
    VALUE_KIND_BYTES,
    VALUE_KIND_TIMESTAMPTZ,
    VALUE_KIND_JSON,
    VALUE_KIND_UUID,
    VALUE_KIND_ARRAY,
  ];

  static final $core.List<ValueKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static ValueKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ValueKind._(super.value, super.name);
}

/// QueryErrorKind classifies a statement failure.
class QueryErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const QueryErrorKind QUERY_ERROR_KIND_UNSPECIFIED =
      QueryErrorKind._(0, _omitEnumNames ? '' : 'QUERY_ERROR_KIND_UNSPECIFIED');

  /// The server rejected the statement (syntax error, constraint, ...).
  static const QueryErrorKind QUERY_ERROR_KIND_SQL =
      QueryErrorKind._(1, _omitEnumNames ? '' : 'QUERY_ERROR_KIND_SQL');

  /// The statement was cancelled.
  static const QueryErrorKind QUERY_ERROR_KIND_CANCELED =
      QueryErrorKind._(2, _omitEnumNames ? '' : 'QUERY_ERROR_KIND_CANCELED');

  /// The connection was lost.
  static const QueryErrorKind QUERY_ERROR_KIND_CONNECTION =
      QueryErrorKind._(3, _omitEnumNames ? '' : 'QUERY_ERROR_KIND_CONNECTION');

  /// The session's engine cannot execute statements.
  static const QueryErrorKind QUERY_ERROR_KIND_UNSUPPORTED =
      QueryErrorKind._(4, _omitEnumNames ? '' : 'QUERY_ERROR_KIND_UNSUPPORTED');

  static const $core.List<QueryErrorKind> values = <QueryErrorKind>[
    QUERY_ERROR_KIND_UNSPECIFIED,
    QUERY_ERROR_KIND_SQL,
    QUERY_ERROR_KIND_CANCELED,
    QUERY_ERROR_KIND_CONNECTION,
    QUERY_ERROR_KIND_UNSUPPORTED,
  ];

  static final $core.List<QueryErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static QueryErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const QueryErrorKind._(super.value, super.name);
}

/// CopyFormat is the text format of CopyRange.
class CopyFormat extends $pb.ProtobufEnum {
  /// Not set. Treated as TSV.
  static const CopyFormat COPY_FORMAT_UNSPECIFIED =
      CopyFormat._(0, _omitEnumNames ? '' : 'COPY_FORMAT_UNSPECIFIED');

  /// Tab-separated values, newline per row. NULL is an empty field; fields with
  /// tabs, newlines or quotes are double-quoted.
  static const CopyFormat COPY_FORMAT_TSV =
      CopyFormat._(1, _omitEnumNames ? '' : 'COPY_FORMAT_TSV');

  /// Comma-separated values with RFC 4180 quoting. NULL is an empty field.
  static const CopyFormat COPY_FORMAT_CSV =
      CopyFormat._(2, _omitEnumNames ? '' : 'COPY_FORMAT_CSV');

  /// JSON array of objects keyed by column name.
  static const CopyFormat COPY_FORMAT_JSON =
      CopyFormat._(3, _omitEnumNames ? '' : 'COPY_FORMAT_JSON');

  static const $core.List<CopyFormat> values = <CopyFormat>[
    COPY_FORMAT_UNSPECIFIED,
    COPY_FORMAT_TSV,
    COPY_FORMAT_CSV,
    COPY_FORMAT_JSON,
  ];

  static final $core.List<CopyFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CopyFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CopyFormat._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
