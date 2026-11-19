// This is a generated file - do not edit.
//
// Generated from queravue/v1/gridfs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// GridFsErrorKind classifies a GridFS operation failure.
class GridFsErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_UNSPECIFIED =
      GridFsErrorKind._(
          0, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_UNSPECIFIED');

  /// The filter, sort, id or metadata is not valid EJSON.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_PARSE =
      GridFsErrorKind._(1, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_PARSE');

  /// The bucket or file does not exist.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_NOT_FOUND = GridFsErrorKind._(
      2, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_NOT_FOUND');

  /// The connection is flagged production and the request did not set
  /// confirmed. Nothing was changed.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED =
      GridFsErrorKind._(
          3, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// Bad credentials or not permitted.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_AUTH =
      GridFsErrorKind._(4, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_AUTH');

  /// Server unreachable or connection lost.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_NETWORK =
      GridFsErrorKind._(5, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_NETWORK');

  /// The operation exceeded max_time_ms or the server selection timeout.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_TIMEOUT =
      GridFsErrorKind._(6, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_TIMEOUT');

  /// The operation was cancelled.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_CANCELED =
      GridFsErrorKind._(7, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_CANCELED');

  /// The server does not support the operation.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_UNSUPPORTED =
      GridFsErrorKind._(
          8, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_UNSUPPORTED');

  /// The server rejected the operation.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_SERVER =
      GridFsErrorKind._(9, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_SERVER');

  /// The file's chunks are missing or shorter than its length.
  static const GridFsErrorKind GRID_FS_ERROR_KIND_CORRUPT =
      GridFsErrorKind._(10, _omitEnumNames ? '' : 'GRID_FS_ERROR_KIND_CORRUPT');

  static const $core.List<GridFsErrorKind> values = <GridFsErrorKind>[
    GRID_FS_ERROR_KIND_UNSPECIFIED,
    GRID_FS_ERROR_KIND_PARSE,
    GRID_FS_ERROR_KIND_NOT_FOUND,
    GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED,
    GRID_FS_ERROR_KIND_AUTH,
    GRID_FS_ERROR_KIND_NETWORK,
    GRID_FS_ERROR_KIND_TIMEOUT,
    GRID_FS_ERROR_KIND_CANCELED,
    GRID_FS_ERROR_KIND_UNSUPPORTED,
    GRID_FS_ERROR_KIND_SERVER,
    GRID_FS_ERROR_KIND_CORRUPT,
  ];

  static final $core.List<GridFsErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static GridFsErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GridFsErrorKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
