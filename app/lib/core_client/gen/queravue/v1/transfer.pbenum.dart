// This is a generated file - do not edit.
//
// Generated from queravue/v1/transfer.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// TransferFormat is a file format.
class TransferFormat extends $pb.ProtobufEnum {
  /// Not set. Rejected where a format is required.
  static const TransferFormat TRANSFER_FORMAT_UNSPECIFIED =
      TransferFormat._(0, _omitEnumNames ? '' : 'TRANSFER_FORMAT_UNSPECIFIED');

  /// Comma-separated values with RFC 4180 quoting.
  static const TransferFormat TRANSFER_FORMAT_CSV =
      TransferFormat._(1, _omitEnumNames ? '' : 'TRANSFER_FORMAT_CSV');

  /// Tab-separated values.
  static const TransferFormat TRANSFER_FORMAT_TSV =
      TransferFormat._(2, _omitEnumNames ? '' : 'TRANSFER_FORMAT_TSV');

  /// One JSON array of objects or documents.
  static const TransferFormat TRANSFER_FORMAT_JSON =
      TransferFormat._(3, _omitEnumNames ? '' : 'TRANSFER_FORMAT_JSON');

  /// One JSON object or document per line.
  static const TransferFormat TRANSFER_FORMAT_NDJSON =
      TransferFormat._(4, _omitEnumNames ? '' : 'TRANSFER_FORMAT_NDJSON');

  /// SQL statements: INSERTs on export, a script on import.
  static const TransferFormat TRANSFER_FORMAT_SQL =
      TransferFormat._(5, _omitEnumNames ? '' : 'TRANSFER_FORMAT_SQL');

  /// Apache Parquet, through embedded DuckDB.
  static const TransferFormat TRANSFER_FORMAT_PARQUET =
      TransferFormat._(6, _omitEnumNames ? '' : 'TRANSFER_FORMAT_PARQUET');

  static const $core.List<TransferFormat> values = <TransferFormat>[
    TRANSFER_FORMAT_UNSPECIFIED,
    TRANSFER_FORMAT_CSV,
    TRANSFER_FORMAT_TSV,
    TRANSFER_FORMAT_JSON,
    TRANSFER_FORMAT_NDJSON,
    TRANSFER_FORMAT_SQL,
    TRANSFER_FORMAT_PARQUET,
  ];

  static final $core.List<TransferFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static TransferFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TransferFormat._(super.value, super.name);
}

/// JsonFlavor selects how documents are written as Extended JSON.
class JsonFlavor extends $pb.ProtobufEnum {
  /// Not set. Treated as RELAXED.
  static const JsonFlavor JSON_FLAVOR_UNSPECIFIED =
      JsonFlavor._(0, _omitEnumNames ? '' : 'JSON_FLAVOR_UNSPECIFIED');

  /// Relaxed Extended JSON v2: plain numbers and ISO dates where lossless.
  static const JsonFlavor JSON_FLAVOR_RELAXED =
      JsonFlavor._(1, _omitEnumNames ? '' : 'JSON_FLAVOR_RELAXED');

  /// Canonical Extended JSON v2: every type explicit.
  static const JsonFlavor JSON_FLAVOR_CANONICAL =
      JsonFlavor._(2, _omitEnumNames ? '' : 'JSON_FLAVOR_CANONICAL');

  static const $core.List<JsonFlavor> values = <JsonFlavor>[
    JSON_FLAVOR_UNSPECIFIED,
    JSON_FLAVOR_RELAXED,
    JSON_FLAVOR_CANONICAL,
  ];

  static final $core.List<JsonFlavor?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static JsonFlavor? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const JsonFlavor._(super.value, super.name);
}

/// TransferErrorKind classifies an import or export failure.
class TransferErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const TransferErrorKind TRANSFER_ERROR_KIND_UNSPECIFIED =
      TransferErrorKind._(
          0, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_UNSPECIFIED');

  /// The file or a filter is malformed for its format.
  static const TransferErrorKind TRANSFER_ERROR_KIND_PARSE =
      TransferErrorKind._(1, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_PARSE');

  /// The mapping names a missing column, or a value cannot be coerced to its
  /// target column.
  static const TransferErrorKind TRANSFER_ERROR_KIND_MAPPING =
      TransferErrorKind._(
          2, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_MAPPING');

  /// The server rejected a row for a constraint (unique, not null, foreign key,
  /// check).
  static const TransferErrorKind TRANSFER_ERROR_KIND_CONSTRAINT =
      TransferErrorKind._(
          3, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_CONSTRAINT');

  /// The connection is flagged production and the request did not set
  /// confirmed. Nothing was changed.
  static const TransferErrorKind TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED =
      TransferErrorKind._(
          4, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// Bad credentials or not permitted.
  static const TransferErrorKind TRANSFER_ERROR_KIND_AUTH =
      TransferErrorKind._(5, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_AUTH');

  /// Server unreachable or connection lost.
  static const TransferErrorKind TRANSFER_ERROR_KIND_NETWORK =
      TransferErrorKind._(
          6, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_NETWORK');

  /// The operation exceeded its time limit.
  static const TransferErrorKind TRANSFER_ERROR_KIND_TIMEOUT =
      TransferErrorKind._(
          7, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_TIMEOUT');

  /// The operation was cancelled.
  static const TransferErrorKind TRANSFER_ERROR_KIND_CANCELED =
      TransferErrorKind._(
          8, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_CANCELED');

  /// The format or target is not supported by this core build or engine.
  static const TransferErrorKind TRANSFER_ERROR_KIND_UNSUPPORTED =
      TransferErrorKind._(
          9, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_UNSUPPORTED');

  /// The server rejected the operation.
  static const TransferErrorKind TRANSFER_ERROR_KIND_SERVER =
      TransferErrorKind._(
          10, _omitEnumNames ? '' : 'TRANSFER_ERROR_KIND_SERVER');

  static const $core.List<TransferErrorKind> values = <TransferErrorKind>[
    TRANSFER_ERROR_KIND_UNSPECIFIED,
    TRANSFER_ERROR_KIND_PARSE,
    TRANSFER_ERROR_KIND_MAPPING,
    TRANSFER_ERROR_KIND_CONSTRAINT,
    TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED,
    TRANSFER_ERROR_KIND_AUTH,
    TRANSFER_ERROR_KIND_NETWORK,
    TRANSFER_ERROR_KIND_TIMEOUT,
    TRANSFER_ERROR_KIND_CANCELED,
    TRANSFER_ERROR_KIND_UNSUPPORTED,
    TRANSFER_ERROR_KIND_SERVER,
  ];

  static final $core.List<TransferErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static TransferErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TransferErrorKind._(super.value, super.name);
}

/// ImportErrorPolicy says what a bad row does.
class ImportErrorPolicy extends $pb.ProtobufEnum {
  /// Not set. Treated as STOP.
  static const ImportErrorPolicy IMPORT_ERROR_POLICY_UNSPECIFIED =
      ImportErrorPolicy._(
          0, _omitEnumNames ? '' : 'IMPORT_ERROR_POLICY_UNSPECIFIED');

  /// Stop at the first bad row; earlier batches stay committed.
  static const ImportErrorPolicy IMPORT_ERROR_POLICY_STOP =
      ImportErrorPolicy._(1, _omitEnumNames ? '' : 'IMPORT_ERROR_POLICY_STOP');

  /// Skip bad rows and report them, up to max_row_errors.
  static const ImportErrorPolicy IMPORT_ERROR_POLICY_SKIP =
      ImportErrorPolicy._(2, _omitEnumNames ? '' : 'IMPORT_ERROR_POLICY_SKIP');

  static const $core.List<ImportErrorPolicy> values = <ImportErrorPolicy>[
    IMPORT_ERROR_POLICY_UNSPECIFIED,
    IMPORT_ERROR_POLICY_STOP,
    IMPORT_ERROR_POLICY_SKIP,
  ];

  static final $core.List<ImportErrorPolicy?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ImportErrorPolicy? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ImportErrorPolicy._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
