// This is a generated file - do not edit.
//
// Generated from queravue/v1/querybuilder.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// QueryBuilderErrorKind classifies a failed builder call.
class QueryBuilderErrorKind extends $pb.ProtobufEnum {
  /// Unspecified. Never sent.
  static const QueryBuilderErrorKind QUERY_BUILDER_ERROR_KIND_UNSPECIFIED =
      QueryBuilderErrorKind._(
          0, _omitEnumNames ? '' : 'QUERY_BUILDER_ERROR_KIND_UNSPECIFIED');

  /// The model is not valid, for example a join without a condition or an
  /// empty select list. `message` says which part.
  static const QueryBuilderErrorKind QUERY_BUILDER_ERROR_KIND_INVALID_MODEL =
      QueryBuilderErrorKind._(
          1, _omitEnumNames ? '' : 'QUERY_BUILDER_ERROR_KIND_INVALID_MODEL');

  /// The text is not valid SQL or EJSON. `offset` points at the problem.
  static const QueryBuilderErrorKind QUERY_BUILDER_ERROR_KIND_PARSE =
      QueryBuilderErrorKind._(
          2, _omitEnumNames ? '' : 'QUERY_BUILDER_ERROR_KIND_PARSE');

  /// The text is valid but outside the supported subset. The caller keeps the
  /// text in the editor. `offset` points at the first unsupported construct.
  static const QueryBuilderErrorKind
      QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT = QueryBuilderErrorKind._(
          3,
          _omitEnumNames
              ? ''
              : 'QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT');

  /// The session's engine has no SQL dialect.
  static const QueryBuilderErrorKind QUERY_BUILDER_ERROR_KIND_NOT_SQL =
      QueryBuilderErrorKind._(
          4, _omitEnumNames ? '' : 'QUERY_BUILDER_ERROR_KIND_NOT_SQL');

  static const $core.List<QueryBuilderErrorKind> values =
      <QueryBuilderErrorKind>[
    QUERY_BUILDER_ERROR_KIND_UNSPECIFIED,
    QUERY_BUILDER_ERROR_KIND_INVALID_MODEL,
    QUERY_BUILDER_ERROR_KIND_PARSE,
    QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT,
    QUERY_BUILDER_ERROR_KIND_NOT_SQL,
  ];

  static final $core.List<QueryBuilderErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static QueryBuilderErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const QueryBuilderErrorKind._(super.value, super.name);
}

/// SqlJoinKind is the type of a join.
class SqlJoinKind extends $pb.ProtobufEnum {
  /// Treated as INNER.
  static const SqlJoinKind SQL_JOIN_KIND_UNSPECIFIED =
      SqlJoinKind._(0, _omitEnumNames ? '' : 'SQL_JOIN_KIND_UNSPECIFIED');

  /// INNER JOIN.
  static const SqlJoinKind SQL_JOIN_KIND_INNER =
      SqlJoinKind._(1, _omitEnumNames ? '' : 'SQL_JOIN_KIND_INNER');

  /// LEFT JOIN.
  static const SqlJoinKind SQL_JOIN_KIND_LEFT =
      SqlJoinKind._(2, _omitEnumNames ? '' : 'SQL_JOIN_KIND_LEFT');

  /// RIGHT JOIN.
  static const SqlJoinKind SQL_JOIN_KIND_RIGHT =
      SqlJoinKind._(3, _omitEnumNames ? '' : 'SQL_JOIN_KIND_RIGHT');

  /// FULL JOIN.
  static const SqlJoinKind SQL_JOIN_KIND_FULL =
      SqlJoinKind._(4, _omitEnumNames ? '' : 'SQL_JOIN_KIND_FULL');

  static const $core.List<SqlJoinKind> values = <SqlJoinKind>[
    SQL_JOIN_KIND_UNSPECIFIED,
    SQL_JOIN_KIND_INNER,
    SQL_JOIN_KIND_LEFT,
    SQL_JOIN_KIND_RIGHT,
    SQL_JOIN_KIND_FULL,
  ];

  static final $core.List<SqlJoinKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SqlJoinKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SqlJoinKind._(super.value, super.name);
}

/// SqlAggregate is an aggregate function.
class SqlAggregate extends $pb.ProtobufEnum {
  /// No aggregate: the plain column.
  static const SqlAggregate SQL_AGGREGATE_UNSPECIFIED =
      SqlAggregate._(0, _omitEnumNames ? '' : 'SQL_AGGREGATE_UNSPECIFIED');

  /// COUNT.
  static const SqlAggregate SQL_AGGREGATE_COUNT =
      SqlAggregate._(1, _omitEnumNames ? '' : 'SQL_AGGREGATE_COUNT');

  /// SUM.
  static const SqlAggregate SQL_AGGREGATE_SUM =
      SqlAggregate._(2, _omitEnumNames ? '' : 'SQL_AGGREGATE_SUM');

  /// AVG.
  static const SqlAggregate SQL_AGGREGATE_AVG =
      SqlAggregate._(3, _omitEnumNames ? '' : 'SQL_AGGREGATE_AVG');

  /// MIN.
  static const SqlAggregate SQL_AGGREGATE_MIN =
      SqlAggregate._(4, _omitEnumNames ? '' : 'SQL_AGGREGATE_MIN');

  /// MAX.
  static const SqlAggregate SQL_AGGREGATE_MAX =
      SqlAggregate._(5, _omitEnumNames ? '' : 'SQL_AGGREGATE_MAX');

  static const $core.List<SqlAggregate> values = <SqlAggregate>[
    SQL_AGGREGATE_UNSPECIFIED,
    SQL_AGGREGATE_COUNT,
    SQL_AGGREGATE_SUM,
    SQL_AGGREGATE_AVG,
    SQL_AGGREGATE_MIN,
    SQL_AGGREGATE_MAX,
  ];

  static final $core.List<SqlAggregate?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static SqlAggregate? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SqlAggregate._(super.value, super.name);
}

/// SqlOperator is a comparison operator.
class SqlOperator extends $pb.ProtobufEnum {
  /// Treated as EQ.
  static const SqlOperator SQL_OPERATOR_UNSPECIFIED =
      SqlOperator._(0, _omitEnumNames ? '' : 'SQL_OPERATOR_UNSPECIFIED');

  /// =.
  static const SqlOperator SQL_OPERATOR_EQ =
      SqlOperator._(1, _omitEnumNames ? '' : 'SQL_OPERATOR_EQ');

  /// <>.
  static const SqlOperator SQL_OPERATOR_NE =
      SqlOperator._(2, _omitEnumNames ? '' : 'SQL_OPERATOR_NE');

  /// <.
  static const SqlOperator SQL_OPERATOR_LT =
      SqlOperator._(3, _omitEnumNames ? '' : 'SQL_OPERATOR_LT');

  /// <=.
  static const SqlOperator SQL_OPERATOR_LE =
      SqlOperator._(4, _omitEnumNames ? '' : 'SQL_OPERATOR_LE');

  /// >.
  static const SqlOperator SQL_OPERATOR_GT =
      SqlOperator._(5, _omitEnumNames ? '' : 'SQL_OPERATOR_GT');

  /// >=.
  static const SqlOperator SQL_OPERATOR_GE =
      SqlOperator._(6, _omitEnumNames ? '' : 'SQL_OPERATOR_GE');

  /// LIKE. One operand.
  static const SqlOperator SQL_OPERATOR_LIKE =
      SqlOperator._(7, _omitEnumNames ? '' : 'SQL_OPERATOR_LIKE');

  /// IN. One or more operands.
  static const SqlOperator SQL_OPERATOR_IN =
      SqlOperator._(8, _omitEnumNames ? '' : 'SQL_OPERATOR_IN');

  /// BETWEEN. Exactly two operands.
  static const SqlOperator SQL_OPERATOR_BETWEEN =
      SqlOperator._(9, _omitEnumNames ? '' : 'SQL_OPERATOR_BETWEEN');

  /// IS NULL. No operands.
  static const SqlOperator SQL_OPERATOR_IS_NULL =
      SqlOperator._(10, _omitEnumNames ? '' : 'SQL_OPERATOR_IS_NULL');

  static const $core.List<SqlOperator> values = <SqlOperator>[
    SQL_OPERATOR_UNSPECIFIED,
    SQL_OPERATOR_EQ,
    SQL_OPERATOR_NE,
    SQL_OPERATOR_LT,
    SQL_OPERATOR_LE,
    SQL_OPERATOR_GT,
    SQL_OPERATOR_GE,
    SQL_OPERATOR_LIKE,
    SQL_OPERATOR_IN,
    SQL_OPERATOR_BETWEEN,
    SQL_OPERATOR_IS_NULL,
  ];

  static final $core.List<SqlOperator?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static SqlOperator? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SqlOperator._(super.value, super.name);
}

/// SqlBoolOp combines the children of a condition group.
class SqlBoolOp extends $pb.ProtobufEnum {
  /// Treated as AND.
  static const SqlBoolOp SQL_BOOL_OP_UNSPECIFIED =
      SqlBoolOp._(0, _omitEnumNames ? '' : 'SQL_BOOL_OP_UNSPECIFIED');

  /// AND.
  static const SqlBoolOp SQL_BOOL_OP_AND =
      SqlBoolOp._(1, _omitEnumNames ? '' : 'SQL_BOOL_OP_AND');

  /// OR.
  static const SqlBoolOp SQL_BOOL_OP_OR =
      SqlBoolOp._(2, _omitEnumNames ? '' : 'SQL_BOOL_OP_OR');

  static const $core.List<SqlBoolOp> values = <SqlBoolOp>[
    SQL_BOOL_OP_UNSPECIFIED,
    SQL_BOOL_OP_AND,
    SQL_BOOL_OP_OR,
  ];

  static final $core.List<SqlBoolOp?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SqlBoolOp? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SqlBoolOp._(super.value, super.name);
}

/// SqlNulls places NULLs in an ordering.
class SqlNulls extends $pb.ProtobufEnum {
  /// The engine default.
  static const SqlNulls SQL_NULLS_UNSPECIFIED =
      SqlNulls._(0, _omitEnumNames ? '' : 'SQL_NULLS_UNSPECIFIED');

  /// NULLS FIRST, emulated where the engine lacks it.
  static const SqlNulls SQL_NULLS_FIRST =
      SqlNulls._(1, _omitEnumNames ? '' : 'SQL_NULLS_FIRST');

  /// NULLS LAST, emulated where the engine lacks it.
  static const SqlNulls SQL_NULLS_LAST =
      SqlNulls._(2, _omitEnumNames ? '' : 'SQL_NULLS_LAST');

  static const $core.List<SqlNulls> values = <SqlNulls>[
    SQL_NULLS_UNSPECIFIED,
    SQL_NULLS_FIRST,
    SQL_NULLS_LAST,
  ];

  static final $core.List<SqlNulls?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SqlNulls? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SqlNulls._(super.value, super.name);
}

/// MongoBoolOp combines the children of a condition group.
class MongoBoolOp extends $pb.ProtobufEnum {
  /// Treated as AND.
  static const MongoBoolOp MONGO_BOOL_OP_UNSPECIFIED =
      MongoBoolOp._(0, _omitEnumNames ? '' : 'MONGO_BOOL_OP_UNSPECIFIED');

  /// $and.
  static const MongoBoolOp MONGO_BOOL_OP_AND =
      MongoBoolOp._(1, _omitEnumNames ? '' : 'MONGO_BOOL_OP_AND');

  /// $or.
  static const MongoBoolOp MONGO_BOOL_OP_OR =
      MongoBoolOp._(2, _omitEnumNames ? '' : 'MONGO_BOOL_OP_OR');

  /// $nor.
  static const MongoBoolOp MONGO_BOOL_OP_NOR =
      MongoBoolOp._(3, _omitEnumNames ? '' : 'MONGO_BOOL_OP_NOR');

  static const $core.List<MongoBoolOp> values = <MongoBoolOp>[
    MONGO_BOOL_OP_UNSPECIFIED,
    MONGO_BOOL_OP_AND,
    MONGO_BOOL_OP_OR,
    MONGO_BOOL_OP_NOR,
  ];

  static final $core.List<MongoBoolOp?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MongoBoolOp? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MongoBoolOp._(super.value, super.name);
}

/// MongoOperator is a field-level comparison operator.
class MongoOperator extends $pb.ProtobufEnum {
  /// Treated as EQ.
  static const MongoOperator MONGO_OPERATOR_UNSPECIFIED =
      MongoOperator._(0, _omitEnumNames ? '' : 'MONGO_OPERATOR_UNSPECIFIED');

  /// Equality, written without an operator.
  static const MongoOperator MONGO_OPERATOR_EQ =
      MongoOperator._(1, _omitEnumNames ? '' : 'MONGO_OPERATOR_EQ');

  /// $ne.
  static const MongoOperator MONGO_OPERATOR_NE =
      MongoOperator._(2, _omitEnumNames ? '' : 'MONGO_OPERATOR_NE');

  /// $gt.
  static const MongoOperator MONGO_OPERATOR_GT =
      MongoOperator._(3, _omitEnumNames ? '' : 'MONGO_OPERATOR_GT');

  /// $gte.
  static const MongoOperator MONGO_OPERATOR_GTE =
      MongoOperator._(4, _omitEnumNames ? '' : 'MONGO_OPERATOR_GTE');

  /// $lt.
  static const MongoOperator MONGO_OPERATOR_LT =
      MongoOperator._(5, _omitEnumNames ? '' : 'MONGO_OPERATOR_LT');

  /// $lte.
  static const MongoOperator MONGO_OPERATOR_LTE =
      MongoOperator._(6, _omitEnumNames ? '' : 'MONGO_OPERATOR_LTE');

  /// $in. The value is an EJSON array.
  static const MongoOperator MONGO_OPERATOR_IN =
      MongoOperator._(7, _omitEnumNames ? '' : 'MONGO_OPERATOR_IN');

  /// $nin. The value is an EJSON array.
  static const MongoOperator MONGO_OPERATOR_NIN =
      MongoOperator._(8, _omitEnumNames ? '' : 'MONGO_OPERATOR_NIN');

  /// $exists. The value is an EJSON boolean.
  static const MongoOperator MONGO_OPERATOR_EXISTS =
      MongoOperator._(9, _omitEnumNames ? '' : 'MONGO_OPERATOR_EXISTS');

  /// $regex. The value is an EJSON string; options go in regex_options.
  static const MongoOperator MONGO_OPERATOR_REGEX =
      MongoOperator._(10, _omitEnumNames ? '' : 'MONGO_OPERATOR_REGEX');

  /// $type. The value is an EJSON string or number.
  static const MongoOperator MONGO_OPERATOR_TYPE =
      MongoOperator._(11, _omitEnumNames ? '' : 'MONGO_OPERATOR_TYPE');

  static const $core.List<MongoOperator> values = <MongoOperator>[
    MONGO_OPERATOR_UNSPECIFIED,
    MONGO_OPERATOR_EQ,
    MONGO_OPERATOR_NE,
    MONGO_OPERATOR_GT,
    MONGO_OPERATOR_GTE,
    MONGO_OPERATOR_LT,
    MONGO_OPERATOR_LTE,
    MONGO_OPERATOR_IN,
    MONGO_OPERATOR_NIN,
    MONGO_OPERATOR_EXISTS,
    MONGO_OPERATOR_REGEX,
    MONGO_OPERATOR_TYPE,
  ];

  static final $core.List<MongoOperator?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static MongoOperator? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MongoOperator._(super.value, super.name);
}

/// MongoProjectionMode says whether a field is kept or dropped.
class MongoProjectionMode extends $pb.ProtobufEnum {
  /// Treated as INCLUDE.
  static const MongoProjectionMode MONGO_PROJECTION_MODE_UNSPECIFIED =
      MongoProjectionMode._(
          0, _omitEnumNames ? '' : 'MONGO_PROJECTION_MODE_UNSPECIFIED');

  /// Keep the field.
  static const MongoProjectionMode MONGO_PROJECTION_MODE_INCLUDE =
      MongoProjectionMode._(
          1, _omitEnumNames ? '' : 'MONGO_PROJECTION_MODE_INCLUDE');

  /// Drop the field.
  static const MongoProjectionMode MONGO_PROJECTION_MODE_EXCLUDE =
      MongoProjectionMode._(
          2, _omitEnumNames ? '' : 'MONGO_PROJECTION_MODE_EXCLUDE');

  static const $core.List<MongoProjectionMode> values = <MongoProjectionMode>[
    MONGO_PROJECTION_MODE_UNSPECIFIED,
    MONGO_PROJECTION_MODE_INCLUDE,
    MONGO_PROJECTION_MODE_EXCLUDE,
  ];

  static final $core.List<MongoProjectionMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MongoProjectionMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MongoProjectionMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
