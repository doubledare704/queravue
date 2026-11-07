// This is a generated file - do not edit.
//
// Generated from queravue/v1/index.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// IndexKeyKind says how a key part is ordered or hashed.
class IndexKeyKind extends $pb.ProtobufEnum {
  /// Unspecified. Treated as ascending.
  static const IndexKeyKind INDEX_KEY_KIND_UNSPECIFIED =
      IndexKeyKind._(0, _omitEnumNames ? '' : 'INDEX_KEY_KIND_UNSPECIFIED');

  /// Ascending order.
  static const IndexKeyKind INDEX_KEY_KIND_ASCENDING =
      IndexKeyKind._(1, _omitEnumNames ? '' : 'INDEX_KEY_KIND_ASCENDING');

  /// Descending order.
  static const IndexKeyKind INDEX_KEY_KIND_DESCENDING =
      IndexKeyKind._(2, _omitEnumNames ? '' : 'INDEX_KEY_KIND_DESCENDING');

  /// Hashed key (Mongo hashed, PostgreSQL hash method uses IndexSpec.method instead).
  static const IndexKeyKind INDEX_KEY_KIND_HASHED =
      IndexKeyKind._(3, _omitEnumNames ? '' : 'INDEX_KEY_KIND_HASHED');

  /// Full-text key (Mongo text index).
  static const IndexKeyKind INDEX_KEY_KIND_TEXT =
      IndexKeyKind._(4, _omitEnumNames ? '' : 'INDEX_KEY_KIND_TEXT');

  /// Spherical geo key (Mongo 2dsphere).
  static const IndexKeyKind INDEX_KEY_KIND_GEO_2DSPHERE =
      IndexKeyKind._(5, _omitEnumNames ? '' : 'INDEX_KEY_KIND_GEO_2DSPHERE');

  static const $core.List<IndexKeyKind> values = <IndexKeyKind>[
    INDEX_KEY_KIND_UNSPECIFIED,
    INDEX_KEY_KIND_ASCENDING,
    INDEX_KEY_KIND_DESCENDING,
    INDEX_KEY_KIND_HASHED,
    INDEX_KEY_KIND_TEXT,
    INDEX_KEY_KIND_GEO_2DSPHERE,
  ];

  static final $core.List<IndexKeyKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static IndexKeyKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IndexKeyKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
