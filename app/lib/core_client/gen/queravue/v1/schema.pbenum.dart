// This is a generated file - do not edit.
//
// Generated from queravue/v1/schema.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// SchemaObjectType classifies an object in the database schema.
class SchemaObjectType extends $pb.ProtobufEnum {
  /// Unknown or unspecified object type.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_UNSPECIFIED =
      SchemaObjectType._(
          0, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_UNSPECIFIED');

  /// Standard relational table.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_TABLE =
      SchemaObjectType._(1, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_TABLE');

  /// Standard SQL view.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_VIEW =
      SchemaObjectType._(2, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_VIEW');

  /// Materialized view with cached data.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW =
      SchemaObjectType._(
          3, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW');

  /// Document collection (MongoDB and compatible). Views use
  /// SCHEMA_OBJECT_TYPE_VIEW.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_COLLECTION =
      SchemaObjectType._(
          4, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_COLLECTION');

  /// Time series collection.
  static const SchemaObjectType SCHEMA_OBJECT_TYPE_TIME_SERIES =
      SchemaObjectType._(
          5, _omitEnumNames ? '' : 'SCHEMA_OBJECT_TYPE_TIME_SERIES');

  static const $core.List<SchemaObjectType> values = <SchemaObjectType>[
    SCHEMA_OBJECT_TYPE_UNSPECIFIED,
    SCHEMA_OBJECT_TYPE_TABLE,
    SCHEMA_OBJECT_TYPE_VIEW,
    SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW,
    SCHEMA_OBJECT_TYPE_COLLECTION,
    SCHEMA_OBJECT_TYPE_TIME_SERIES,
  ];

  static final $core.List<SchemaObjectType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static SchemaObjectType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SchemaObjectType._(super.value, super.name);
}

/// ReferentialAction is what a foreign key does when the referenced row changes.
class ReferentialAction extends $pb.ProtobufEnum {
  /// Unknown or the engine default.
  static const ReferentialAction REFERENTIAL_ACTION_UNSPECIFIED =
      ReferentialAction._(
          0, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_UNSPECIFIED');

  /// Reject the change at the end of the statement.
  static const ReferentialAction REFERENTIAL_ACTION_NO_ACTION =
      ReferentialAction._(
          1, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_NO_ACTION');

  /// Reject the change immediately.
  static const ReferentialAction REFERENTIAL_ACTION_RESTRICT =
      ReferentialAction._(
          2, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_RESTRICT');

  /// Apply the same change to the referencing rows.
  static const ReferentialAction REFERENTIAL_ACTION_CASCADE =
      ReferentialAction._(
          3, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_CASCADE');

  /// Set the referencing columns to NULL.
  static const ReferentialAction REFERENTIAL_ACTION_SET_NULL =
      ReferentialAction._(
          4, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_SET_NULL');

  /// Set the referencing columns to their defaults.
  static const ReferentialAction REFERENTIAL_ACTION_SET_DEFAULT =
      ReferentialAction._(
          5, _omitEnumNames ? '' : 'REFERENTIAL_ACTION_SET_DEFAULT');

  static const $core.List<ReferentialAction> values = <ReferentialAction>[
    REFERENTIAL_ACTION_UNSPECIFIED,
    REFERENTIAL_ACTION_NO_ACTION,
    REFERENTIAL_ACTION_RESTRICT,
    REFERENTIAL_ACTION_CASCADE,
    REFERENTIAL_ACTION_SET_NULL,
    REFERENTIAL_ACTION_SET_DEFAULT,
  ];

  static final $core.List<ReferentialAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ReferentialAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReferentialAction._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
