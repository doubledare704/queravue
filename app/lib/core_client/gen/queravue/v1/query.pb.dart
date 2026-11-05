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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $2;
import 'package:protobuf/well_known_types/google/protobuf/struct.pbenum.dart'
    as $3;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'query.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'query.pbenum.dart';

/// TextRange is a half-open range [start, end) of the editor text. All offsets
/// in this contract are UTF-16 code units, as used by Dart strings.
class TextRange extends $pb.GeneratedMessage {
  factory TextRange({
    $core.int? start,
    $core.int? end,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    return result;
  }

  TextRange._();

  factory TextRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'start', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'end', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextRange copyWith(void Function(TextRange) updates) =>
      super.copyWith((message) => updates(message as TextRange)) as TextRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextRange create() => TextRange._();
  @$core.override
  TextRange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TextRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextRange>(create);
  static TextRange? _defaultInstance;

  /// First code unit of the range.
  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);

  /// One past the last code unit of the range.
  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);
}

/// Column describes one result column.
class Column extends $pb.GeneratedMessage {
  factory Column({
    $core.String? name,
    $core.String? typeName,
    ValueKind? kind,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (typeName != null) result.typeName = typeName;
    if (kind != null) result.kind = kind;
    return result;
  }

  Column._();

  factory Column.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Column.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Column',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'typeName')
    ..aE<ValueKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: ValueKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Column clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Column copyWith(void Function(Column) updates) =>
      super.copyWith((message) => updates(message as Column)) as Column;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Column create() => Column._();
  @$core.override
  Column createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Column getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Column>(create);
  static Column? _defaultInstance;

  /// Column name as reported by the server.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Engine-native type name, e.g. "int4", "numeric", "TEXT".
  @$pb.TagNumber(2)
  $core.String get typeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set typeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTypeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearTypeName() => $_clearField(2);

  /// General kind of the values in this column.
  @$pb.TagNumber(3)
  ValueKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(ValueKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);
}

/// ArrayValue is a (possibly nested) array.
class ArrayValue extends $pb.GeneratedMessage {
  factory ArrayValue({
    $core.Iterable<Value>? values,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    return result;
  }

  ArrayValue._();

  factory ArrayValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArrayValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArrayValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<Value>(1, _omitFieldNames ? '' : 'values', subBuilder: Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayValue copyWith(void Function(ArrayValue) updates) =>
      super.copyWith((message) => updates(message as ArrayValue)) as ArrayValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArrayValue create() => ArrayValue._();
  @$core.override
  ArrayValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArrayValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArrayValue>(create);
  static ArrayValue? _defaultInstance;

  /// Elements in order.
  @$pb.TagNumber(1)
  $pb.PbList<Value> get values => $_getList(0);
}

enum Value_Kind {
  nullValue,
  boolValue,
  intValue,
  doubleValue,
  decimalValue,
  textValue,
  bytesValue,
  timestampValue,
  jsonValue,
  uuidValue,
  arrayValue,
  notSet
}

/// Value is one cell. Types without a dedicated case (dates without time
/// zone, intervals, ranges, geometry, unknown types...) arrive as text_value.
class Value extends $pb.GeneratedMessage {
  factory Value({
    $3.NullValue? nullValue,
    $core.bool? boolValue,
    $fixnum.Int64? intValue,
    $core.double? doubleValue,
    $core.String? decimalValue,
    $core.String? textValue,
    $core.List<$core.int>? bytesValue,
    $1.Timestamp? timestampValue,
    $core.String? jsonValue,
    $core.String? uuidValue,
    ArrayValue? arrayValue,
  }) {
    final result = create();
    if (nullValue != null) result.nullValue = nullValue;
    if (boolValue != null) result.boolValue = boolValue;
    if (intValue != null) result.intValue = intValue;
    if (doubleValue != null) result.doubleValue = doubleValue;
    if (decimalValue != null) result.decimalValue = decimalValue;
    if (textValue != null) result.textValue = textValue;
    if (bytesValue != null) result.bytesValue = bytesValue;
    if (timestampValue != null) result.timestampValue = timestampValue;
    if (jsonValue != null) result.jsonValue = jsonValue;
    if (uuidValue != null) result.uuidValue = uuidValue;
    if (arrayValue != null) result.arrayValue = arrayValue;
    return result;
  }

  Value._();

  factory Value.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Value.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Value_Kind> _Value_KindByTag = {
    1: Value_Kind.nullValue,
    2: Value_Kind.boolValue,
    3: Value_Kind.intValue,
    4: Value_Kind.doubleValue,
    5: Value_Kind.decimalValue,
    6: Value_Kind.textValue,
    7: Value_Kind.bytesValue,
    8: Value_Kind.timestampValue,
    9: Value_Kind.jsonValue,
    10: Value_Kind.uuidValue,
    11: Value_Kind.arrayValue,
    0: Value_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Value',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    ..aE<$3.NullValue>(1, _omitFieldNames ? '' : 'nullValue',
        enumValues: $3.NullValue.values)
    ..aOB(2, _omitFieldNames ? '' : 'boolValue')
    ..aInt64(3, _omitFieldNames ? '' : 'intValue')
    ..aD(4, _omitFieldNames ? '' : 'doubleValue')
    ..aOS(5, _omitFieldNames ? '' : 'decimalValue')
    ..aOS(6, _omitFieldNames ? '' : 'textValue')
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'bytesValue', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'timestampValue',
        subBuilder: $1.Timestamp.create)
    ..aOS(9, _omitFieldNames ? '' : 'jsonValue')
    ..aOS(10, _omitFieldNames ? '' : 'uuidValue')
    ..aOM<ArrayValue>(11, _omitFieldNames ? '' : 'arrayValue',
        subBuilder: ArrayValue.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Value clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Value copyWith(void Function(Value) updates) =>
      super.copyWith((message) => updates(message as Value)) as Value;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Value create() => Value._();
  @$core.override
  Value createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Value getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value>(create);
  static Value? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  Value_Kind whichKind() => _Value_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  void clearKind() => $_clearField($_whichOneof(0));

  /// SQL NULL.
  @$pb.TagNumber(1)
  $3.NullValue get nullValue => $_getN(0);
  @$pb.TagNumber(1)
  set nullValue($3.NullValue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNullValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearNullValue() => $_clearField(1);

  /// Boolean.
  @$pb.TagNumber(2)
  $core.bool get boolValue => $_getBF(1);
  @$pb.TagNumber(2)
  set boolValue($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBoolValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearBoolValue() => $_clearField(2);

  /// Integer.
  @$pb.TagNumber(3)
  $fixnum.Int64 get intValue => $_getI64(2);
  @$pb.TagNumber(3)
  set intValue($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntValue() => $_clearField(3);

  /// Floating point.
  @$pb.TagNumber(4)
  $core.double get doubleValue => $_getN(3);
  @$pb.TagNumber(4)
  set doubleValue($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDoubleValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearDoubleValue() => $_clearField(4);

  /// Exact decimal in its text form, e.g. "12345678901234567890.12".
  @$pb.TagNumber(5)
  $core.String get decimalValue => $_getSZ(4);
  @$pb.TagNumber(5)
  set decimalValue($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDecimalValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearDecimalValue() => $_clearField(5);

  /// Text, and the fallback for unknown types.
  @$pb.TagNumber(6)
  $core.String get textValue => $_getSZ(5);
  @$pb.TagNumber(6)
  set textValue($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTextValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearTextValue() => $_clearField(6);

  /// Binary data.
  @$pb.TagNumber(7)
  $core.List<$core.int> get bytesValue => $_getN(6);
  @$pb.TagNumber(7)
  set bytesValue($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBytesValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearBytesValue() => $_clearField(7);

  /// Timestamp with time zone. Infinite values arrive as text_value.
  @$pb.TagNumber(8)
  $1.Timestamp get timestampValue => $_getN(7);
  @$pb.TagNumber(8)
  set timestampValue($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasTimestampValue() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimestampValue() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureTimestampValue() => $_ensure(7);

  /// JSON text.
  @$pb.TagNumber(9)
  $core.String get jsonValue => $_getSZ(8);
  @$pb.TagNumber(9)
  set jsonValue($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasJsonValue() => $_has(8);
  @$pb.TagNumber(9)
  void clearJsonValue() => $_clearField(9);

  /// UUID in canonical form.
  @$pb.TagNumber(10)
  $core.String get uuidValue => $_getSZ(9);
  @$pb.TagNumber(10)
  set uuidValue($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUuidValue() => $_has(9);
  @$pb.TagNumber(10)
  void clearUuidValue() => $_clearField(10);

  /// Array.
  @$pb.TagNumber(11)
  ArrayValue get arrayValue => $_getN(10);
  @$pb.TagNumber(11)
  set arrayValue(ArrayValue value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasArrayValue() => $_has(10);
  @$pb.TagNumber(11)
  void clearArrayValue() => $_clearField(11);
  @$pb.TagNumber(11)
  ArrayValue ensureArrayValue() => $_ensure(10);
}

/// Row is one result row; values line up with the result's columns.
class Row extends $pb.GeneratedMessage {
  factory Row({
    $core.Iterable<Value>? values,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    return result;
  }

  Row._();

  factory Row.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Row.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Row',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<Value>(1, _omitFieldNames ? '' : 'values', subBuilder: Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row copyWith(void Function(Row) updates) =>
      super.copyWith((message) => updates(message as Row)) as Row;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Row create() => Row._();
  @$core.override
  Row createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Row getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Row>(create);
  static Row? _defaultInstance;

  /// One value per column.
  @$pb.TagNumber(1)
  $pb.PbList<Value> get values => $_getList(0);
}

/// RowBatch is a group of rows. The core uses it as the on-disk page format of
/// its result spool; it is part of the contract so UI test fixtures can build
/// pages with the same type.
class RowBatch extends $pb.GeneratedMessage {
  factory RowBatch({
    $core.Iterable<Row>? rows,
  }) {
    final result = create();
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  RowBatch._();

  factory RowBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RowBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RowBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<Row>(1, _omitFieldNames ? '' : 'rows', subBuilder: Row.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowBatch copyWith(void Function(RowBatch) updates) =>
      super.copyWith((message) => updates(message as RowBatch)) as RowBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RowBatch create() => RowBatch._();
  @$core.override
  RowBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RowBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowBatch>(create);
  static RowBatch? _defaultInstance;

  /// Rows in order.
  @$pb.TagNumber(1)
  $pb.PbList<Row> get rows => $_getList(0);
}

/// StatementRange locates one statement in the executed text.
class StatementRange extends $pb.GeneratedMessage {
  factory StatementRange({
    $core.int? index,
    TextRange? range,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (range != null) result.range = range;
    return result;
  }

  StatementRange._();

  factory StatementRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatementRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..aOM<TextRange>(2, _omitFieldNames ? '' : 'range',
        subBuilder: TextRange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementRange copyWith(void Function(StatementRange) updates) =>
      super.copyWith((message) => updates(message as StatementRange))
          as StatementRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatementRange create() => StatementRange._();
  @$core.override
  StatementRange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatementRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatementRange>(create);
  static StatementRange? _defaultInstance;

  /// Zero-based position of the statement among those that run.
  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  /// Where the statement sits in the request text.
  @$pb.TagNumber(2)
  TextRange get range => $_getN(1);
  @$pb.TagNumber(2)
  set range(TextRange value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRange() => $_has(1);
  @$pb.TagNumber(2)
  void clearRange() => $_clearField(2);
  @$pb.TagNumber(2)
  TextRange ensureRange() => $_ensure(1);
}

/// ExecuteRequest is the input of Execute.
class ExecuteRequest extends $pb.GeneratedMessage {
  factory ExecuteRequest({
    $core.String? sessionId,
    $core.String? text,
    $core.int? cursorOffset,
    ExecuteMode? mode,
    TextRange? selection,
    $core.Iterable<Value>? params,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (text != null) result.text = text;
    if (cursorOffset != null) result.cursorOffset = cursorOffset;
    if (mode != null) result.mode = mode;
    if (selection != null) result.selection = selection;
    if (params != null) result.params.addAll(params);
    return result;
  }

  ExecuteRequest._();

  factory ExecuteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecuteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aI(3, _omitFieldNames ? '' : 'cursorOffset',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<ExecuteMode>(4, _omitFieldNames ? '' : 'mode',
        enumValues: ExecuteMode.values)
    ..aOM<TextRange>(5, _omitFieldNames ? '' : 'selection',
        subBuilder: TextRange.create)
    ..pPM<Value>(6, _omitFieldNames ? '' : 'params', subBuilder: Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest copyWith(void Function(ExecuteRequest) updates) =>
      super.copyWith((message) => updates(message as ExecuteRequest))
          as ExecuteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecuteRequest create() => ExecuteRequest._();
  @$core.override
  ExecuteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecuteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteRequest>(create);
  static ExecuteRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Full editor text.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  /// Caret position in `text`, used by STATEMENT_AT_CURSOR.
  @$pb.TagNumber(3)
  $core.int get cursorOffset => $_getIZ(2);
  @$pb.TagNumber(3)
  set cursorOffset($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCursorOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursorOffset() => $_clearField(3);

  /// Which statements to run.
  @$pb.TagNumber(4)
  ExecuteMode get mode => $_getN(3);
  @$pb.TagNumber(4)
  set mode(ExecuteMode value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMode() => $_clearField(4);

  /// Selected range, used by SELECTION.
  @$pb.TagNumber(5)
  TextRange get selection => $_getN(4);
  @$pb.TagNumber(5)
  set selection(TextRange value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSelection() => $_has(4);
  @$pb.TagNumber(5)
  void clearSelection() => $_clearField(5);
  @$pb.TagNumber(5)
  TextRange ensureSelection() => $_ensure(4);

  /// Bind parameters for a single statement. Reserved for later use; the
  /// current UI sends none.
  @$pb.TagNumber(6)
  $pb.PbList<Value> get params => $_getList(5);
}

/// StatementPlan lists the statements an Execute call is about to run. It is
/// the first event, so the UI can highlight them.
class StatementPlan extends $pb.GeneratedMessage {
  factory StatementPlan({
    $core.Iterable<StatementRange>? statements,
  }) {
    final result = create();
    if (statements != null) result.statements.addAll(statements);
    return result;
  }

  StatementPlan._();

  factory StatementPlan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatementPlan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementPlan',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<StatementRange>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: StatementRange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementPlan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementPlan copyWith(void Function(StatementPlan) updates) =>
      super.copyWith((message) => updates(message as StatementPlan))
          as StatementPlan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatementPlan create() => StatementPlan._();
  @$core.override
  StatementPlan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatementPlan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatementPlan>(create);
  static StatementPlan? _defaultInstance;

  /// Statements in execution order. Empty if the text holds no statement.
  @$pb.TagNumber(1)
  $pb.PbList<StatementRange> get statements => $_getList(0);
}

/// StatementStarted announces a statement and its result id.
class StatementStarted extends $pb.GeneratedMessage {
  factory StatementStarted({
    $core.int? statementIndex,
    $core.String? resultId,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (resultId != null) result.resultId = resultId;
    return result;
  }

  StatementStarted._();

  factory StatementStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatementStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'resultId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementStarted copyWith(void Function(StatementStarted) updates) =>
      super.copyWith((message) => updates(message as StatementStarted))
          as StatementStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatementStarted create() => StatementStarted._();
  @$core.override
  StatementStarted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatementStarted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatementStarted>(create);
  static StatementStarted? _defaultInstance;

  /// Index into the plan.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Id of the (future) result; use it with FetchRows, CopyRange, CloseResult.
  @$pb.TagNumber(2)
  $core.String get resultId => $_getSZ(1);
  @$pb.TagNumber(2)
  set resultId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResultId() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultId() => $_clearField(2);
}

/// Columns carries the column metadata of a statement that returns rows.
class Columns extends $pb.GeneratedMessage {
  factory Columns({
    $core.int? statementIndex,
    $core.Iterable<Column>? columns,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (columns != null) result.columns.addAll(columns);
    return result;
  }

  Columns._();

  factory Columns.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Columns.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Columns',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..pPM<Column>(2, _omitFieldNames ? '' : 'columns',
        subBuilder: Column.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Columns clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Columns copyWith(void Function(Columns) updates) =>
      super.copyWith((message) => updates(message as Columns)) as Columns;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Columns create() => Columns._();
  @$core.override
  Columns createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Columns getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Columns>(create);
  static Columns? _defaultInstance;

  /// Index into the plan.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Result columns.
  @$pb.TagNumber(2)
  $pb.PbList<Column> get columns => $_getList(1);
}

/// RowsWindow carries the first window of rows of a result.
class RowsWindow extends $pb.GeneratedMessage {
  factory RowsWindow({
    $core.int? statementIndex,
    $fixnum.Int64? offset,
    $core.Iterable<Row>? rows,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (offset != null) result.offset = offset;
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  RowsWindow._();

  factory RowsWindow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RowsWindow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RowsWindow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<Row>(3, _omitFieldNames ? '' : 'rows', subBuilder: Row.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowsWindow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowsWindow copyWith(void Function(RowsWindow) updates) =>
      super.copyWith((message) => updates(message as RowsWindow)) as RowsWindow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RowsWindow create() => RowsWindow._();
  @$core.override
  RowsWindow createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RowsWindow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RowsWindow>(create);
  static RowsWindow? _defaultInstance;

  /// Index into the plan.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Row index of rows[0]; always 0 on this stream.
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  /// At most one page of rows.
  @$pb.TagNumber(3)
  $pb.PbList<Row> get rows => $_getList(2);
}

/// Progress reports spooling progress, at most about ten times per second.
class Progress extends $pb.GeneratedMessage {
  factory Progress({
    $core.int? statementIndex,
    $fixnum.Int64? rowsSpooled,
    $core.bool? done,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (rowsSpooled != null) result.rowsSpooled = rowsSpooled;
    if (done != null) result.done = done;
    return result;
  }

  Progress._();

  factory Progress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Progress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Progress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rowsSpooled', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress copyWith(void Function(Progress) updates) =>
      super.copyWith((message) => updates(message as Progress)) as Progress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Progress create() => Progress._();
  @$core.override
  Progress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Progress getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Progress>(create);
  static Progress? _defaultInstance;

  /// Index into the plan.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Rows written to the spool so far; rows below this can be fetched.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rowsSpooled => $_getI64(1);
  @$pb.TagNumber(2)
  set rowsSpooled($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowsSpooled() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowsSpooled() => $_clearField(2);

  /// True once the server has sent all rows or reading stopped (truncated).
  @$pb.TagNumber(3)
  $core.bool get done => $_getBF(2);
  @$pb.TagNumber(3)
  set done($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDone() => $_has(2);
  @$pb.TagNumber(3)
  void clearDone() => $_clearField(3);
}

/// Summary ends a statement.
class Summary extends $pb.GeneratedMessage {
  factory Summary({
    $core.int? statementIndex,
    $fixnum.Int64? rowsAffected,
    $fixnum.Int64? rowsSpooled,
    $2.Duration? duration,
    $core.Iterable<$core.String>? notices,
    $core.bool? truncated,
    $core.bool? hasRows,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (rowsAffected != null) result.rowsAffected = rowsAffected;
    if (rowsSpooled != null) result.rowsSpooled = rowsSpooled;
    if (duration != null) result.duration = duration;
    if (notices != null) result.notices.addAll(notices);
    if (truncated != null) result.truncated = truncated;
    if (hasRows != null) result.hasRows = hasRows;
    return result;
  }

  Summary._();

  factory Summary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Summary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Summary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rowsAffected', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'rowsSpooled', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Duration>(4, _omitFieldNames ? '' : 'duration',
        subBuilder: $2.Duration.create)
    ..pPS(5, _omitFieldNames ? '' : 'notices')
    ..aOB(6, _omitFieldNames ? '' : 'truncated')
    ..aOB(7, _omitFieldNames ? '' : 'hasRows')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Summary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Summary copyWith(void Function(Summary) updates) =>
      super.copyWith((message) => updates(message as Summary)) as Summary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Summary create() => Summary._();
  @$core.override
  Summary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Summary getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Summary>(create);
  static Summary? _defaultInstance;

  /// Index into the plan.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Rows affected by INSERT/UPDATE/DELETE; 0 for statements that return rows.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rowsAffected => $_getI64(1);
  @$pb.TagNumber(2)
  set rowsAffected($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowsAffected() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowsAffected() => $_clearField(2);

  /// Rows in the spool when the statement finished.
  @$pb.TagNumber(3)
  $fixnum.Int64 get rowsSpooled => $_getI64(2);
  @$pb.TagNumber(3)
  set rowsSpooled($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRowsSpooled() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowsSpooled() => $_clearField(3);

  /// Wall time of the statement.
  @$pb.TagNumber(4)
  $2.Duration get duration => $_getN(3);
  @$pb.TagNumber(4)
  set duration($2.Duration value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDuration() => $_has(3);
  @$pb.TagNumber(4)
  void clearDuration() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Duration ensureDuration() => $_ensure(3);

  /// Server notices and warnings raised by the statement.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get notices => $_getList(4);

  /// True if reading stopped at the spool size cap; rows_spooled is then
  /// less than the full result.
  @$pb.TagNumber(6)
  $core.bool get truncated => $_getBF(5);
  @$pb.TagNumber(6)
  set truncated($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTruncated() => $_has(5);
  @$pb.TagNumber(6)
  void clearTruncated() => $_clearField(6);

  /// True if the statement returned a result set (even an empty one).
  @$pb.TagNumber(7)
  $core.bool get hasRows => $_getBF(6);
  @$pb.TagNumber(7)
  set hasRows($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHasRows() => $_has(6);
  @$pb.TagNumber(7)
  void clearHasRows() => $_clearField(7);
}

/// ExecuteError ends an Execute call with a failed statement.
class ExecuteError extends $pb.GeneratedMessage {
  factory ExecuteError({
    $core.int? statementIndex,
    QueryErrorKind? kind,
    $core.String? message,
    $core.int? position,
    $2.Duration? duration,
  }) {
    final result = create();
    if (statementIndex != null) result.statementIndex = statementIndex;
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (position != null) result.position = position;
    if (duration != null) result.duration = duration;
    return result;
  }

  ExecuteError._();

  factory ExecuteError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecuteError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'statementIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<QueryErrorKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: QueryErrorKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aI(4, _omitFieldNames ? '' : 'position', fieldType: $pb.PbFieldType.OU3)
    ..aOM<$2.Duration>(5, _omitFieldNames ? '' : 'duration',
        subBuilder: $2.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteError copyWith(void Function(ExecuteError) updates) =>
      super.copyWith((message) => updates(message as ExecuteError))
          as ExecuteError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecuteError create() => ExecuteError._();
  @$core.override
  ExecuteError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecuteError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteError>(create);
  static ExecuteError? _defaultInstance;

  /// Index into the plan; unset values mean the failure was not tied to one
  /// statement.
  @$pb.TagNumber(1)
  $core.int get statementIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set statementIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatementIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatementIndex() => $_clearField(1);

  /// Failure class.
  @$pb.TagNumber(2)
  QueryErrorKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(QueryErrorKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Human-readable message. Never contains secrets.
  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  /// Offset of the error inside the request text, if the server reported one.
  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);

  /// Elapsed time until the failure.
  @$pb.TagNumber(5)
  $2.Duration get duration => $_getN(4);
  @$pb.TagNumber(5)
  set duration($2.Duration value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDuration() => $_has(4);
  @$pb.TagNumber(5)
  void clearDuration() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Duration ensureDuration() => $_ensure(4);
}

enum ExecuteResponse_Event {
  plan,
  started,
  columns,
  rows,
  progress,
  summary,
  error,
  notSet
}

/// ExecuteResponse is one event of an Execute stream.
class ExecuteResponse extends $pb.GeneratedMessage {
  factory ExecuteResponse({
    StatementPlan? plan,
    StatementStarted? started,
    Columns? columns,
    RowsWindow? rows,
    Progress? progress,
    Summary? summary,
    ExecuteError? error,
  }) {
    final result = create();
    if (plan != null) result.plan = plan;
    if (started != null) result.started = started;
    if (columns != null) result.columns = columns;
    if (rows != null) result.rows = rows;
    if (progress != null) result.progress = progress;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    return result;
  }

  ExecuteResponse._();

  factory ExecuteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecuteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ExecuteResponse_Event>
      _ExecuteResponse_EventByTag = {
    1: ExecuteResponse_Event.plan,
    2: ExecuteResponse_Event.started,
    3: ExecuteResponse_Event.columns,
    4: ExecuteResponse_Event.rows,
    5: ExecuteResponse_Event.progress,
    6: ExecuteResponse_Event.summary,
    7: ExecuteResponse_Event.error,
    0: ExecuteResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7])
    ..aOM<StatementPlan>(1, _omitFieldNames ? '' : 'plan',
        subBuilder: StatementPlan.create)
    ..aOM<StatementStarted>(2, _omitFieldNames ? '' : 'started',
        subBuilder: StatementStarted.create)
    ..aOM<Columns>(3, _omitFieldNames ? '' : 'columns',
        subBuilder: Columns.create)
    ..aOM<RowsWindow>(4, _omitFieldNames ? '' : 'rows',
        subBuilder: RowsWindow.create)
    ..aOM<Progress>(5, _omitFieldNames ? '' : 'progress',
        subBuilder: Progress.create)
    ..aOM<Summary>(6, _omitFieldNames ? '' : 'summary',
        subBuilder: Summary.create)
    ..aOM<ExecuteError>(7, _omitFieldNames ? '' : 'error',
        subBuilder: ExecuteError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteResponse copyWith(void Function(ExecuteResponse) updates) =>
      super.copyWith((message) => updates(message as ExecuteResponse))
          as ExecuteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecuteResponse create() => ExecuteResponse._();
  @$core.override
  ExecuteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecuteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteResponse>(create);
  static ExecuteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  ExecuteResponse_Event whichEvent() =>
      _ExecuteResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// First event: the statements that will run.
  @$pb.TagNumber(1)
  StatementPlan get plan => $_getN(0);
  @$pb.TagNumber(1)
  set plan(StatementPlan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlan() => $_clearField(1);
  @$pb.TagNumber(1)
  StatementPlan ensurePlan() => $_ensure(0);

  /// A statement starts.
  @$pb.TagNumber(2)
  StatementStarted get started => $_getN(1);
  @$pb.TagNumber(2)
  set started(StatementStarted value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStarted() => $_has(1);
  @$pb.TagNumber(2)
  void clearStarted() => $_clearField(2);
  @$pb.TagNumber(2)
  StatementStarted ensureStarted() => $_ensure(1);

  /// Column metadata.
  @$pb.TagNumber(3)
  Columns get columns => $_getN(2);
  @$pb.TagNumber(3)
  set columns(Columns value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasColumns() => $_has(2);
  @$pb.TagNumber(3)
  void clearColumns() => $_clearField(3);
  @$pb.TagNumber(3)
  Columns ensureColumns() => $_ensure(2);

  /// First window of rows.
  @$pb.TagNumber(4)
  RowsWindow get rows => $_getN(3);
  @$pb.TagNumber(4)
  set rows(RowsWindow value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasRows() => $_has(3);
  @$pb.TagNumber(4)
  void clearRows() => $_clearField(4);
  @$pb.TagNumber(4)
  RowsWindow ensureRows() => $_ensure(3);

  /// Spooling progress.
  @$pb.TagNumber(5)
  Progress get progress => $_getN(4);
  @$pb.TagNumber(5)
  set progress(Progress value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasProgress() => $_has(4);
  @$pb.TagNumber(5)
  void clearProgress() => $_clearField(5);
  @$pb.TagNumber(5)
  Progress ensureProgress() => $_ensure(4);

  /// A statement finished.
  @$pb.TagNumber(6)
  Summary get summary => $_getN(5);
  @$pb.TagNumber(6)
  set summary(Summary value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSummary() => $_has(5);
  @$pb.TagNumber(6)
  void clearSummary() => $_clearField(6);
  @$pb.TagNumber(6)
  Summary ensureSummary() => $_ensure(5);

  /// A statement failed; the stream ends after this event.
  @$pb.TagNumber(7)
  ExecuteError get error => $_getN(6);
  @$pb.TagNumber(7)
  set error(ExecuteError value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
  @$pb.TagNumber(7)
  ExecuteError ensureError() => $_ensure(6);
}

/// FetchRowsRequest selects a row range.
class FetchRowsRequest extends $pb.GeneratedMessage {
  factory FetchRowsRequest({
    $core.String? resultId,
    $fixnum.Int64? offset,
    $core.int? limit,
  }) {
    final result = create();
    if (resultId != null) result.resultId = resultId;
    if (offset != null) result.offset = offset;
    if (limit != null) result.limit = limit;
    return result;
  }

  FetchRowsRequest._();

  factory FetchRowsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchRowsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchRowsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resultId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRowsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRowsRequest copyWith(void Function(FetchRowsRequest) updates) =>
      super.copyWith((message) => updates(message as FetchRowsRequest))
          as FetchRowsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchRowsRequest create() => FetchRowsRequest._();
  @$core.override
  FetchRowsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchRowsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchRowsRequest>(create);
  static FetchRowsRequest? _defaultInstance;

  /// Result id from StatementStarted.
  @$pb.TagNumber(1)
  $core.String get resultId => $_getSZ(0);
  @$pb.TagNumber(1)
  set resultId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResultId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultId() => $_clearField(1);

  /// Index of the first row.
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  /// Maximum rows to return. The core clamps it to 5000; 0 means 500.
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

/// FetchRowsResponse holds the requested rows.
class FetchRowsResponse extends $pb.GeneratedMessage {
  factory FetchRowsResponse({
    $fixnum.Int64? offset,
    $core.Iterable<Row>? rows,
    $fixnum.Int64? rowsSpooled,
    $core.bool? done,
  }) {
    final result = create();
    if (offset != null) result.offset = offset;
    if (rows != null) result.rows.addAll(rows);
    if (rowsSpooled != null) result.rowsSpooled = rowsSpooled;
    if (done != null) result.done = done;
    return result;
  }

  FetchRowsResponse._();

  factory FetchRowsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchRowsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchRowsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<Row>(2, _omitFieldNames ? '' : 'rows', subBuilder: Row.create)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'rowsSpooled', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(4, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRowsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRowsResponse copyWith(void Function(FetchRowsResponse) updates) =>
      super.copyWith((message) => updates(message as FetchRowsResponse))
          as FetchRowsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchRowsResponse create() => FetchRowsResponse._();
  @$core.override
  FetchRowsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchRowsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchRowsResponse>(create);
  static FetchRowsResponse? _defaultInstance;

  /// Index of rows[0].
  @$pb.TagNumber(1)
  $fixnum.Int64 get offset => $_getI64(0);
  @$pb.TagNumber(1)
  set offset($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffset() => $_clearField(1);

  /// The rows; fewer than requested at the end of the result.
  @$pb.TagNumber(2)
  $pb.PbList<Row> get rows => $_getList(1);

  /// Rows spooled so far.
  @$pb.TagNumber(3)
  $fixnum.Int64 get rowsSpooled => $_getI64(2);
  @$pb.TagNumber(3)
  set rowsSpooled($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRowsSpooled() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowsSpooled() => $_clearField(3);

  /// True once the result is fully spooled.
  @$pb.TagNumber(4)
  $core.bool get done => $_getBF(3);
  @$pb.TagNumber(4)
  set done($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDone() => $_has(3);
  @$pb.TagNumber(4)
  void clearDone() => $_clearField(4);
}

/// CancelRequest names the session whose statement to cancel.
class CancelRequest extends $pb.GeneratedMessage {
  factory CancelRequest({
    $core.String? sessionId,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  CancelRequest._();

  factory CancelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelRequest copyWith(void Function(CancelRequest) updates) =>
      super.copyWith((message) => updates(message as CancelRequest))
          as CancelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelRequest create() => CancelRequest._();
  @$core.override
  CancelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelRequest>(create);
  static CancelRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

/// CancelResponse is empty.
class CancelResponse extends $pb.GeneratedMessage {
  factory CancelResponse() => create();

  CancelResponse._();

  factory CancelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelResponse copyWith(void Function(CancelResponse) updates) =>
      super.copyWith((message) => updates(message as CancelResponse))
          as CancelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelResponse create() => CancelResponse._();
  @$core.override
  CancelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelResponse>(create);
  static CancelResponse? _defaultInstance;
}

/// CloseResultRequest names the result to discard.
class CloseResultRequest extends $pb.GeneratedMessage {
  factory CloseResultRequest({
    $core.String? resultId,
  }) {
    final result = create();
    if (resultId != null) result.resultId = resultId;
    return result;
  }

  CloseResultRequest._();

  factory CloseResultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseResultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseResultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resultId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResultRequest copyWith(void Function(CloseResultRequest) updates) =>
      super.copyWith((message) => updates(message as CloseResultRequest))
          as CloseResultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseResultRequest create() => CloseResultRequest._();
  @$core.override
  CloseResultRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseResultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseResultRequest>(create);
  static CloseResultRequest? _defaultInstance;

  /// Result id.
  @$pb.TagNumber(1)
  $core.String get resultId => $_getSZ(0);
  @$pb.TagNumber(1)
  set resultId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResultId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultId() => $_clearField(1);
}

/// CloseResultResponse is empty.
class CloseResultResponse extends $pb.GeneratedMessage {
  factory CloseResultResponse() => create();

  CloseResultResponse._();

  factory CloseResultResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseResultResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseResultResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResultResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseResultResponse copyWith(void Function(CloseResultResponse) updates) =>
      super.copyWith((message) => updates(message as CloseResultResponse))
          as CloseResultResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseResultResponse create() => CloseResultResponse._();
  @$core.override
  CloseResultResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseResultResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseResultResponse>(create);
  static CloseResultResponse? _defaultInstance;
}

/// RowRange is a half-open range [start, end) of row indices.
class RowRange extends $pb.GeneratedMessage {
  factory RowRange({
    $fixnum.Int64? start,
    $fixnum.Int64? end,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    return result;
  }

  RowRange._();

  factory RowRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RowRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RowRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'start', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'end', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowRange copyWith(void Function(RowRange) updates) =>
      super.copyWith((message) => updates(message as RowRange)) as RowRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RowRange create() => RowRange._();
  @$core.override
  RowRange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RowRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowRange>(create);
  static RowRange? _defaultInstance;

  /// First row.
  @$pb.TagNumber(1)
  $fixnum.Int64 get start => $_getI64(0);
  @$pb.TagNumber(1)
  set start($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);

  /// One past the last row; 0 or beyond the result means to the end.
  @$pb.TagNumber(2)
  $fixnum.Int64 get end => $_getI64(1);
  @$pb.TagNumber(2)
  set end($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);
}

/// CopyRangeRequest selects what to copy.
class CopyRangeRequest extends $pb.GeneratedMessage {
  factory CopyRangeRequest({
    $core.String? resultId,
    RowRange? rowRange,
    $core.Iterable<$core.int>? columnIndices,
    CopyFormat? format,
    $core.bool? includeHeader,
  }) {
    final result = create();
    if (resultId != null) result.resultId = resultId;
    if (rowRange != null) result.rowRange = rowRange;
    if (columnIndices != null) result.columnIndices.addAll(columnIndices);
    if (format != null) result.format = format;
    if (includeHeader != null) result.includeHeader = includeHeader;
    return result;
  }

  CopyRangeRequest._();

  factory CopyRangeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopyRangeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopyRangeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resultId')
    ..aOM<RowRange>(2, _omitFieldNames ? '' : 'rowRange',
        subBuilder: RowRange.create)
    ..p<$core.int>(
        3, _omitFieldNames ? '' : 'columnIndices', $pb.PbFieldType.KU3)
    ..aE<CopyFormat>(4, _omitFieldNames ? '' : 'format',
        enumValues: CopyFormat.values)
    ..aOB(5, _omitFieldNames ? '' : 'includeHeader')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyRangeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyRangeRequest copyWith(void Function(CopyRangeRequest) updates) =>
      super.copyWith((message) => updates(message as CopyRangeRequest))
          as CopyRangeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopyRangeRequest create() => CopyRangeRequest._();
  @$core.override
  CopyRangeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopyRangeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopyRangeRequest>(create);
  static CopyRangeRequest? _defaultInstance;

  /// Result id.
  @$pb.TagNumber(1)
  $core.String get resultId => $_getSZ(0);
  @$pb.TagNumber(1)
  set resultId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResultId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultId() => $_clearField(1);

  /// Rows to copy.
  @$pb.TagNumber(2)
  RowRange get rowRange => $_getN(1);
  @$pb.TagNumber(2)
  set rowRange(RowRange value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRowRange() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowRange() => $_clearField(2);
  @$pb.TagNumber(2)
  RowRange ensureRowRange() => $_ensure(1);

  /// Columns to copy, in output order. Empty means all columns.
  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get columnIndices => $_getList(2);

  /// Output format.
  @$pb.TagNumber(4)
  CopyFormat get format => $_getN(3);
  @$pb.TagNumber(4)
  set format(CopyFormat value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => $_clearField(4);

  /// Write a header line (TSV/CSV). JSON always uses column names as keys.
  @$pb.TagNumber(5)
  $core.bool get includeHeader => $_getBF(4);
  @$pb.TagNumber(5)
  set includeHeader($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIncludeHeader() => $_has(4);
  @$pb.TagNumber(5)
  void clearIncludeHeader() => $_clearField(5);
}

/// CopyRangeResponse is one chunk of formatted text.
class CopyRangeResponse extends $pb.GeneratedMessage {
  factory CopyRangeResponse({
    $core.String? text,
    $fixnum.Int64? rowsWritten,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (rowsWritten != null) result.rowsWritten = rowsWritten;
    return result;
  }

  CopyRangeResponse._();

  factory CopyRangeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopyRangeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopyRangeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rowsWritten', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyRangeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyRangeResponse copyWith(void Function(CopyRangeResponse) updates) =>
      super.copyWith((message) => updates(message as CopyRangeResponse))
          as CopyRangeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopyRangeResponse create() => CopyRangeResponse._();
  @$core.override
  CopyRangeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopyRangeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopyRangeResponse>(create);
  static CopyRangeResponse? _defaultInstance;

  /// Text to append to the output. Chunks are about 64 KiB.
  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  /// Rows formatted so far, for progress display.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rowsWritten => $_getI64(1);
  @$pb.TagNumber(2)
  set rowsWritten($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowsWritten() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowsWritten() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
