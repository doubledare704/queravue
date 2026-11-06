// This is a generated file - do not edit.
//
// Generated from queravue/v1/table.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// FilterOp defines comparison and matching operators for table filters.
class FilterOp extends $pb.ProtobufEnum {
  /// Unspecified operator.
  static const FilterOp FILTER_OP_UNSPECIFIED =
      FilterOp._(0, _omitEnumNames ? '' : 'FILTER_OP_UNSPECIFIED');

  /// Exact equality: column = value.
  static const FilterOp FILTER_OP_EQUALS =
      FilterOp._(1, _omitEnumNames ? '' : 'FILTER_OP_EQUALS');

  /// Inequality: column != value.
  static const FilterOp FILTER_OP_NOT_EQUALS =
      FilterOp._(2, _omitEnumNames ? '' : 'FILTER_OP_NOT_EQUALS');

  /// Less than: column < value.
  static const FilterOp FILTER_OP_LESS_THAN =
      FilterOp._(3, _omitEnumNames ? '' : 'FILTER_OP_LESS_THAN');

  /// Less than or equal: column <= value.
  static const FilterOp FILTER_OP_LESS_THAN_OR_EQUAL =
      FilterOp._(4, _omitEnumNames ? '' : 'FILTER_OP_LESS_THAN_OR_EQUAL');

  /// Greater than: column > value.
  static const FilterOp FILTER_OP_GREATER_THAN =
      FilterOp._(5, _omitEnumNames ? '' : 'FILTER_OP_GREATER_THAN');

  /// Greater than or equal: column >= value.
  static const FilterOp FILTER_OP_GREATER_THAN_OR_EQUAL =
      FilterOp._(6, _omitEnumNames ? '' : 'FILTER_OP_GREATER_THAN_OR_EQUAL');

  /// Pattern match (case-sensitive where supported): column LIKE value.
  static const FilterOp FILTER_OP_LIKE =
      FilterOp._(7, _omitEnumNames ? '' : 'FILTER_OP_LIKE');

  /// Case-insensitive pattern match: column ILIKE value.
  static const FilterOp FILTER_OP_ILIKE =
      FilterOp._(8, _omitEnumNames ? '' : 'FILTER_OP_ILIKE');

  /// Set membership: column IN (value1, value2, ...).
  static const FilterOp FILTER_OP_IN =
      FilterOp._(9, _omitEnumNames ? '' : 'FILTER_OP_IN');

  /// Null test: column IS NULL.
  static const FilterOp FILTER_OP_IS_NULL =
      FilterOp._(10, _omitEnumNames ? '' : 'FILTER_OP_IS_NULL');

  /// Not null test: column IS NOT NULL.
  static const FilterOp FILTER_OP_IS_NOT_NULL =
      FilterOp._(11, _omitEnumNames ? '' : 'FILTER_OP_IS_NOT_NULL');

  /// Range test: column BETWEEN min_value AND max_value.
  static const FilterOp FILTER_OP_BETWEEN =
      FilterOp._(12, _omitEnumNames ? '' : 'FILTER_OP_BETWEEN');

  static const $core.List<FilterOp> values = <FilterOp>[
    FILTER_OP_UNSPECIFIED,
    FILTER_OP_EQUALS,
    FILTER_OP_NOT_EQUALS,
    FILTER_OP_LESS_THAN,
    FILTER_OP_LESS_THAN_OR_EQUAL,
    FILTER_OP_GREATER_THAN,
    FILTER_OP_GREATER_THAN_OR_EQUAL,
    FILTER_OP_LIKE,
    FILTER_OP_ILIKE,
    FILTER_OP_IN,
    FILTER_OP_IS_NULL,
    FILTER_OP_IS_NOT_NULL,
    FILTER_OP_BETWEEN,
  ];

  static final $core.List<FilterOp?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static FilterOp? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FilterOp._(super.value, super.name);
}

/// LogicalOp connects conditions within a group.
class LogicalOp extends $pb.ProtobufEnum {
  /// Unspecified logical operator. Treated as AND.
  static const LogicalOp LOGICAL_OP_UNSPECIFIED =
      LogicalOp._(0, _omitEnumNames ? '' : 'LOGICAL_OP_UNSPECIFIED');

  /// Logical conjunction (all conditions must be true).
  static const LogicalOp LOGICAL_OP_AND =
      LogicalOp._(1, _omitEnumNames ? '' : 'LOGICAL_OP_AND');

  /// Logical disjunction (at least one condition must be true).
  static const LogicalOp LOGICAL_OP_OR =
      LogicalOp._(2, _omitEnumNames ? '' : 'LOGICAL_OP_OR');

  static const $core.List<LogicalOp> values = <LogicalOp>[
    LOGICAL_OP_UNSPECIFIED,
    LOGICAL_OP_AND,
    LOGICAL_OP_OR,
  ];

  static final $core.List<LogicalOp?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static LogicalOp? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LogicalOp._(super.value, super.name);
}

/// SortDirection defines ascending or descending sort order.
class SortDirection extends $pb.ProtobufEnum {
  /// Unspecified sort direction. Treated as ASC.
  static const SortDirection SORT_DIRECTION_UNSPECIFIED =
      SortDirection._(0, _omitEnumNames ? '' : 'SORT_DIRECTION_UNSPECIFIED');

  /// Ascending order.
  static const SortDirection SORT_DIRECTION_ASC =
      SortDirection._(1, _omitEnumNames ? '' : 'SORT_DIRECTION_ASC');

  /// Descending order.
  static const SortDirection SORT_DIRECTION_DESC =
      SortDirection._(2, _omitEnumNames ? '' : 'SORT_DIRECTION_DESC');

  static const $core.List<SortDirection> values = <SortDirection>[
    SORT_DIRECTION_UNSPECIFIED,
    SORT_DIRECTION_ASC,
    SORT_DIRECTION_DESC,
  ];

  static final $core.List<SortDirection?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SortDirection? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SortDirection._(super.value, super.name);
}

/// NullsOrder controls placement of NULL values in sorted results.
class NullsOrder extends $pb.ProtobufEnum {
  /// Default server placement.
  static const NullsOrder NULLS_ORDER_UNSPECIFIED =
      NullsOrder._(0, _omitEnumNames ? '' : 'NULLS_ORDER_UNSPECIFIED');

  /// NULL values appear first.
  static const NullsOrder NULLS_ORDER_FIRST =
      NullsOrder._(1, _omitEnumNames ? '' : 'NULLS_ORDER_FIRST');

  /// NULL values appear last.
  static const NullsOrder NULLS_ORDER_LAST =
      NullsOrder._(2, _omitEnumNames ? '' : 'NULLS_ORDER_LAST');

  static const $core.List<NullsOrder> values = <NullsOrder>[
    NULLS_ORDER_UNSPECIFIED,
    NULLS_ORDER_FIRST,
    NULLS_ORDER_LAST,
  ];

  static final $core.List<NullsOrder?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static NullsOrder? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NullsOrder._(super.value, super.name);
}

/// RowChangeType classifies a pending row mutation.
class RowChangeType extends $pb.ProtobufEnum {
  /// Unspecified change type.
  static const RowChangeType ROW_CHANGE_TYPE_UNSPECIFIED =
      RowChangeType._(0, _omitEnumNames ? '' : 'ROW_CHANGE_TYPE_UNSPECIFIED');

  /// Insert a new row.
  static const RowChangeType ROW_CHANGE_TYPE_INSERT =
      RowChangeType._(1, _omitEnumNames ? '' : 'ROW_CHANGE_TYPE_INSERT');

  /// Update an existing row identified by its primary key.
  static const RowChangeType ROW_CHANGE_TYPE_UPDATE =
      RowChangeType._(2, _omitEnumNames ? '' : 'ROW_CHANGE_TYPE_UPDATE');

  /// Delete an existing row identified by its primary key.
  static const RowChangeType ROW_CHANGE_TYPE_DELETE =
      RowChangeType._(3, _omitEnumNames ? '' : 'ROW_CHANGE_TYPE_DELETE');

  static const $core.List<RowChangeType> values = <RowChangeType>[
    ROW_CHANGE_TYPE_UNSPECIFIED,
    ROW_CHANGE_TYPE_INSERT,
    ROW_CHANGE_TYPE_UPDATE,
    ROW_CHANGE_TYPE_DELETE,
  ];

  static final $core.List<RowChangeType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RowChangeType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RowChangeType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
