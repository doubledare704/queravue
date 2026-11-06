// This is a generated file - do not edit.
//
// Generated from queravue/v1/document.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// DocumentErrorKind classifies a document operation failure.
class DocumentErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_UNSPECIFIED =
      DocumentErrorKind._(
          0, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_UNSPECIFIED');

  /// The filter, sort, projection or a document is not valid EJSON. See
  /// DocumentError.field and position.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_PARSE =
      DocumentErrorKind._(1, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_PARSE');

  /// The stored document no longer equals expected_document.
  /// DocumentError.current_document holds the stored document, or is unset if
  /// it was deleted.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_CONFLICT =
      DocumentErrorKind._(
          2, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_CONFLICT');

  /// The target document or collection does not exist.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_NOT_FOUND =
      DocumentErrorKind._(
          3, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_NOT_FOUND');

  /// The connection is flagged production and the request did not set
  /// confirmed. Nothing was changed.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED =
      DocumentErrorKind._(
          4, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// Bad credentials or not permitted.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_AUTH =
      DocumentErrorKind._(5, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_AUTH');

  /// Server unreachable or connection lost.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_NETWORK =
      DocumentErrorKind._(
          6, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_NETWORK');

  /// The operation exceeded max_time_ms or the server selection timeout.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_TIMEOUT =
      DocumentErrorKind._(
          7, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_TIMEOUT');

  /// The operation was cancelled.
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_CANCELED =
      DocumentErrorKind._(
          8, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_CANCELED');

  /// The server does not support the operation (e.g. $sample on a variant).
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_UNSUPPORTED =
      DocumentErrorKind._(
          9, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_UNSUPPORTED');

  /// The server rejected the operation (duplicate key, validation, ...).
  static const DocumentErrorKind DOCUMENT_ERROR_KIND_SERVER =
      DocumentErrorKind._(
          10, _omitEnumNames ? '' : 'DOCUMENT_ERROR_KIND_SERVER');

  static const $core.List<DocumentErrorKind> values = <DocumentErrorKind>[
    DOCUMENT_ERROR_KIND_UNSPECIFIED,
    DOCUMENT_ERROR_KIND_PARSE,
    DOCUMENT_ERROR_KIND_CONFLICT,
    DOCUMENT_ERROR_KIND_NOT_FOUND,
    DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED,
    DOCUMENT_ERROR_KIND_AUTH,
    DOCUMENT_ERROR_KIND_NETWORK,
    DOCUMENT_ERROR_KIND_TIMEOUT,
    DOCUMENT_ERROR_KIND_CANCELED,
    DOCUMENT_ERROR_KIND_UNSUPPORTED,
    DOCUMENT_ERROR_KIND_SERVER,
  ];

  static final $core.List<DocumentErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static DocumentErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DocumentErrorKind._(super.value, super.name);
}

/// DocumentInput names the request field a parse error refers to.
class DocumentInput extends $pb.ProtobufEnum {
  /// Not tied to an input.
  static const DocumentInput DOCUMENT_INPUT_UNSPECIFIED =
      DocumentInput._(0, _omitEnumNames ? '' : 'DOCUMENT_INPUT_UNSPECIFIED');

  /// The filter text.
  static const DocumentInput DOCUMENT_INPUT_FILTER =
      DocumentInput._(1, _omitEnumNames ? '' : 'DOCUMENT_INPUT_FILTER');

  /// The sort text.
  static const DocumentInput DOCUMENT_INPUT_SORT =
      DocumentInput._(2, _omitEnumNames ? '' : 'DOCUMENT_INPUT_SORT');

  /// The projection text.
  static const DocumentInput DOCUMENT_INPUT_PROJECTION =
      DocumentInput._(3, _omitEnumNames ? '' : 'DOCUMENT_INPUT_PROJECTION');

  /// A document, _id or update text.
  static const DocumentInput DOCUMENT_INPUT_DOCUMENT =
      DocumentInput._(4, _omitEnumNames ? '' : 'DOCUMENT_INPUT_DOCUMENT');

  static const $core.List<DocumentInput> values = <DocumentInput>[
    DOCUMENT_INPUT_UNSPECIFIED,
    DOCUMENT_INPUT_FILTER,
    DOCUMENT_INPUT_SORT,
    DOCUMENT_INPUT_PROJECTION,
    DOCUMENT_INPUT_DOCUMENT,
  ];

  static final $core.List<DocumentInput?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static DocumentInput? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DocumentInput._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
