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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mockdata.pbenum.dart';
import 'query.pb.dart' as $3;
import 'schema.pb.dart' as $1;
import 'transfer.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mockdata.pbenum.dart';

/// MockError is a typed failure. The message never contains secrets or row
/// data.
class MockError extends $pb.GeneratedMessage {
  factory MockError({
    MockErrorKind? kind,
    $core.String? message,
    MockTargetRef? target,
    $core.String? column,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (target != null) result.target = target;
    if (column != null) result.column = column;
    return result;
  }

  MockError._();

  factory MockError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<MockErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: MockErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<MockTargetRef>(3, _omitFieldNames ? '' : 'target',
        subBuilder: MockTargetRef.create)
    ..aOS(4, _omitFieldNames ? '' : 'column')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockError copyWith(void Function(MockError) updates) =>
      super.copyWith((message) => updates(message as MockError)) as MockError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockError create() => MockError._();
  @$core.override
  MockError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MockError>(create);
  static MockError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  MockErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(MockErrorKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// Human-readable detail.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// Target the failure belongs to, when there is one.
  @$pb.TagNumber(3)
  MockTargetRef get target => $_getN(2);
  @$pb.TagNumber(3)
  set target(MockTargetRef value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTarget() => $_has(2);
  @$pb.TagNumber(3)
  void clearTarget() => $_clearField(3);
  @$pb.TagNumber(3)
  MockTargetRef ensureTarget() => $_ensure(2);

  /// Column or field path the failure belongs to, when there is one.
  @$pb.TagNumber(4)
  $core.String get column => $_getSZ(3);
  @$pb.TagNumber(4)
  set column($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColumn() => $_has(3);
  @$pb.TagNumber(4)
  void clearColumn() => $_clearField(4);
}

enum MockTargetRef_Target { table, collection, notSet }

/// MockTargetRef names a table or a collection.
class MockTargetRef extends $pb.GeneratedMessage {
  factory MockTargetRef({
    $1.TableRef? table,
    $2.CollectionRef? collection,
  }) {
    final result = create();
    if (table != null) result.table = table;
    if (collection != null) result.collection = collection;
    return result;
  }

  MockTargetRef._();

  factory MockTargetRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockTargetRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MockTargetRef_Target>
      _MockTargetRef_TargetByTag = {
    1: MockTargetRef_Target.table,
    2: MockTargetRef_Target.collection,
    0: MockTargetRef_Target.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockTargetRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.TableRef>(1, _omitFieldNames ? '' : 'table',
        subBuilder: $1.TableRef.create)
    ..aOM<$2.CollectionRef>(2, _omitFieldNames ? '' : 'collection',
        subBuilder: $2.CollectionRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTargetRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTargetRef copyWith(void Function(MockTargetRef) updates) =>
      super.copyWith((message) => updates(message as MockTargetRef))
          as MockTargetRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockTargetRef create() => MockTargetRef._();
  @$core.override
  MockTargetRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockTargetRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockTargetRef>(create);
  static MockTargetRef? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  MockTargetRef_Target whichTarget() =>
      _MockTargetRef_TargetByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField($_whichOneof(0));

  /// A table.
  @$pb.TagNumber(1)
  $1.TableRef get table => $_getN(0);
  @$pb.TagNumber(1)
  set table($1.TableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTable() => $_has(0);
  @$pb.TagNumber(1)
  void clearTable() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.TableRef ensureTable() => $_ensure(0);

  /// A collection.
  @$pb.TagNumber(2)
  $2.CollectionRef get collection => $_getN(1);
  @$pb.TagNumber(2)
  set collection($2.CollectionRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCollection() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollection() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.CollectionRef ensureCollection() => $_ensure(1);
}

/// FakerRule draws from a named faker kind, e.g. "email" or "city".
class FakerRule extends $pb.GeneratedMessage {
  factory FakerRule({
    $core.String? kind,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    return result;
  }

  FakerRule._();

  factory FakerRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FakerRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FakerRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FakerRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FakerRule copyWith(void Function(FakerRule) updates) =>
      super.copyWith((message) => updates(message as FakerRule)) as FakerRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FakerRule create() => FakerRule._();
  @$core.override
  FakerRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FakerRule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FakerRule>(create);
  static FakerRule? _defaultInstance;

  /// One of SuggestMockSpecResponse.faker_kinds.
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);
}

/// SequenceRule counts from start by step.
class SequenceRule extends $pb.GeneratedMessage {
  factory SequenceRule({
    $fixnum.Int64? start,
    $fixnum.Int64? step,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (step != null) result.step = step;
    return result;
  }

  SequenceRule._();

  factory SequenceRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SequenceRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SequenceRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'start')
    ..aInt64(2, _omitFieldNames ? '' : 'step')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SequenceRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SequenceRule copyWith(void Function(SequenceRule) updates) =>
      super.copyWith((message) => updates(message as SequenceRule))
          as SequenceRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SequenceRule create() => SequenceRule._();
  @$core.override
  SequenceRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SequenceRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SequenceRule>(create);
  static SequenceRule? _defaultInstance;

  /// First value.
  @$pb.TagNumber(1)
  $fixnum.Int64 get start => $_getI64(0);
  @$pb.TagNumber(1)
  set start($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);

  /// Increment; 0 means 1.
  @$pb.TagNumber(2)
  $fixnum.Int64 get step => $_getI64(1);
  @$pb.TagNumber(2)
  set step($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStep() => $_has(1);
  @$pb.TagNumber(2)
  void clearStep() => $_clearField(2);
}

/// IntRangeRule draws integers uniformly from [min, max].
class IntRangeRule extends $pb.GeneratedMessage {
  factory IntRangeRule({
    $fixnum.Int64? min,
    $fixnum.Int64? max,
  }) {
    final result = create();
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    return result;
  }

  IntRangeRule._();

  factory IntRangeRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntRangeRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntRangeRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'min')
    ..aInt64(2, _omitFieldNames ? '' : 'max')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntRangeRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntRangeRule copyWith(void Function(IntRangeRule) updates) =>
      super.copyWith((message) => updates(message as IntRangeRule))
          as IntRangeRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntRangeRule create() => IntRangeRule._();
  @$core.override
  IntRangeRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IntRangeRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IntRangeRule>(create);
  static IntRangeRule? _defaultInstance;

  /// Smallest value.
  @$pb.TagNumber(1)
  $fixnum.Int64 get min => $_getI64(0);
  @$pb.TagNumber(1)
  set min($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMin() => $_has(0);
  @$pb.TagNumber(1)
  void clearMin() => $_clearField(1);

  /// Largest value.
  @$pb.TagNumber(2)
  $fixnum.Int64 get max => $_getI64(1);
  @$pb.TagNumber(2)
  set max($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMax() => $_has(1);
  @$pb.TagNumber(2)
  void clearMax() => $_clearField(2);
}

/// FloatRangeRule draws floats uniformly from [min, max).
class FloatRangeRule extends $pb.GeneratedMessage {
  factory FloatRangeRule({
    $core.double? min,
    $core.double? max,
  }) {
    final result = create();
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    return result;
  }

  FloatRangeRule._();

  factory FloatRangeRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FloatRangeRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FloatRangeRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'min')
    ..aD(2, _omitFieldNames ? '' : 'max')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FloatRangeRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FloatRangeRule copyWith(void Function(FloatRangeRule) updates) =>
      super.copyWith((message) => updates(message as FloatRangeRule))
          as FloatRangeRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FloatRangeRule create() => FloatRangeRule._();
  @$core.override
  FloatRangeRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FloatRangeRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FloatRangeRule>(create);
  static FloatRangeRule? _defaultInstance;

  /// Smallest value.
  @$pb.TagNumber(1)
  $core.double get min => $_getN(0);
  @$pb.TagNumber(1)
  set min($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMin() => $_has(0);
  @$pb.TagNumber(1)
  void clearMin() => $_clearField(1);

  /// Upper bound, exclusive.
  @$pb.TagNumber(2)
  $core.double get max => $_getN(1);
  @$pb.TagNumber(2)
  set max($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMax() => $_has(1);
  @$pb.TagNumber(2)
  void clearMax() => $_clearField(2);
}

/// DecimalRangeRule draws exact decimals from [min, max] with a scale.
class DecimalRangeRule extends $pb.GeneratedMessage {
  factory DecimalRangeRule({
    $core.String? min,
    $core.String? max,
    $core.int? scale,
  }) {
    final result = create();
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    if (scale != null) result.scale = scale;
    return result;
  }

  DecimalRangeRule._();

  factory DecimalRangeRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DecimalRangeRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DecimalRangeRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'min')
    ..aOS(2, _omitFieldNames ? '' : 'max')
    ..aI(3, _omitFieldNames ? '' : 'scale', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DecimalRangeRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DecimalRangeRule copyWith(void Function(DecimalRangeRule) updates) =>
      super.copyWith((message) => updates(message as DecimalRangeRule))
          as DecimalRangeRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DecimalRangeRule create() => DecimalRangeRule._();
  @$core.override
  DecimalRangeRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DecimalRangeRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DecimalRangeRule>(create);
  static DecimalRangeRule? _defaultInstance;

  /// Smallest value as decimal text.
  @$pb.TagNumber(1)
  $core.String get min => $_getSZ(0);
  @$pb.TagNumber(1)
  set min($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMin() => $_has(0);
  @$pb.TagNumber(1)
  void clearMin() => $_clearField(1);

  /// Largest value as decimal text.
  @$pb.TagNumber(2)
  $core.String get max => $_getSZ(1);
  @$pb.TagNumber(2)
  set max($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMax() => $_has(1);
  @$pb.TagNumber(2)
  void clearMax() => $_clearField(2);

  /// Digits after the decimal point.
  @$pb.TagNumber(3)
  $core.int get scale => $_getIZ(2);
  @$pb.TagNumber(3)
  set scale($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasScale() => $_has(2);
  @$pb.TagNumber(3)
  void clearScale() => $_clearField(3);
}

/// TimeRangeRule draws instants uniformly from [from_ms, to_ms].
class TimeRangeRule extends $pb.GeneratedMessage {
  factory TimeRangeRule({
    $fixnum.Int64? fromMs,
    $fixnum.Int64? toMs,
    $core.bool? dateOnly,
  }) {
    final result = create();
    if (fromMs != null) result.fromMs = fromMs;
    if (toMs != null) result.toMs = toMs;
    if (dateOnly != null) result.dateOnly = dateOnly;
    return result;
  }

  TimeRangeRule._();

  factory TimeRangeRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TimeRangeRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimeRangeRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fromMs')
    ..aInt64(2, _omitFieldNames ? '' : 'toMs')
    ..aOB(3, _omitFieldNames ? '' : 'dateOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeRangeRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimeRangeRule copyWith(void Function(TimeRangeRule) updates) =>
      super.copyWith((message) => updates(message as TimeRangeRule))
          as TimeRangeRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeRangeRule create() => TimeRangeRule._();
  @$core.override
  TimeRangeRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TimeRangeRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimeRangeRule>(create);
  static TimeRangeRule? _defaultInstance;

  /// Earliest instant, Unix milliseconds.
  @$pb.TagNumber(1)
  $fixnum.Int64 get fromMs => $_getI64(0);
  @$pb.TagNumber(1)
  set fromMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromMs() => $_clearField(1);

  /// Latest instant, Unix milliseconds.
  @$pb.TagNumber(2)
  $fixnum.Int64 get toMs => $_getI64(1);
  @$pb.TagNumber(2)
  set toMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearToMs() => $_clearField(2);

  /// Truncate to whole days, for date columns.
  @$pb.TagNumber(3)
  $core.bool get dateOnly => $_getBF(2);
  @$pb.TagNumber(3)
  set dateOnly($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDateOnly() => $_has(2);
  @$pb.TagNumber(3)
  void clearDateOnly() => $_clearField(3);
}

/// WeightedValuesRule picks one of values with the given weights.
class WeightedValuesRule extends $pb.GeneratedMessage {
  factory WeightedValuesRule({
    $core.Iterable<$3.Value>? values,
    $core.Iterable<$core.double>? weights,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    if (weights != null) result.weights.addAll(weights);
    return result;
  }

  WeightedValuesRule._();

  factory WeightedValuesRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WeightedValuesRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WeightedValuesRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<$3.Value>(1, _omitFieldNames ? '' : 'values',
        subBuilder: $3.Value.create)
    ..p<$core.double>(2, _omitFieldNames ? '' : 'weights', $pb.PbFieldType.KD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WeightedValuesRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WeightedValuesRule copyWith(void Function(WeightedValuesRule) updates) =>
      super.copyWith((message) => updates(message as WeightedValuesRule))
          as WeightedValuesRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WeightedValuesRule create() => WeightedValuesRule._();
  @$core.override
  WeightedValuesRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WeightedValuesRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WeightedValuesRule>(create);
  static WeightedValuesRule? _defaultInstance;

  /// Candidate values.
  @$pb.TagNumber(1)
  $pb.PbList<$3.Value> get values => $_getList(0);

  /// One weight per value; empty means equal weights.
  @$pb.TagNumber(2)
  $pb.PbList<$core.double> get weights => $_getList(1);
}

/// ConstantRule always produces the same value.
class ConstantRule extends $pb.GeneratedMessage {
  factory ConstantRule({
    $3.Value? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ConstantRule._();

  factory ConstantRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConstantRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConstantRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$3.Value>(1, _omitFieldNames ? '' : 'value',
        subBuilder: $3.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConstantRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConstantRule copyWith(void Function(ConstantRule) updates) =>
      super.copyWith((message) => updates(message as ConstantRule))
          as ConstantRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConstantRule create() => ConstantRule._();
  @$core.override
  ConstantRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConstantRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConstantRule>(create);
  static ConstantRule? _defaultInstance;

  /// The value.
  @$pb.TagNumber(1)
  $3.Value get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($3.Value value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.Value ensureValue() => $_ensure(0);
}

/// PatternRule fills a pattern: "#" becomes a digit, "?" a letter, "\\"
/// escapes the next character.
class PatternRule extends $pb.GeneratedMessage {
  factory PatternRule({
    $core.String? pattern,
  }) {
    final result = create();
    if (pattern != null) result.pattern = pattern;
    return result;
  }

  PatternRule._();

  factory PatternRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PatternRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PatternRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pattern')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PatternRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PatternRule copyWith(void Function(PatternRule) updates) =>
      super.copyWith((message) => updates(message as PatternRule))
          as PatternRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PatternRule create() => PatternRule._();
  @$core.override
  PatternRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PatternRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PatternRule>(create);
  static PatternRule? _defaultInstance;

  /// Pattern text.
  @$pb.TagNumber(1)
  $core.String get pattern => $_getSZ(0);
  @$pb.TagNumber(1)
  set pattern($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPattern() => $_has(0);
  @$pb.TagNumber(1)
  void clearPattern() => $_clearField(1);
}

/// ForeignKeyRule draws values from a parent table's key column.
class ForeignKeyRule extends $pb.GeneratedMessage {
  factory ForeignKeyRule({
    $1.TableRef? parent,
    $core.String? parentColumn,
    $core.bool? fromExistingRows,
  }) {
    final result = create();
    if (parent != null) result.parent = parent;
    if (parentColumn != null) result.parentColumn = parentColumn;
    if (fromExistingRows != null) result.fromExistingRows = fromExistingRows;
    return result;
  }

  ForeignKeyRule._();

  factory ForeignKeyRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForeignKeyRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForeignKeyRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.TableRef>(1, _omitFieldNames ? '' : 'parent',
        subBuilder: $1.TableRef.create)
    ..aOS(2, _omitFieldNames ? '' : 'parentColumn')
    ..aOB(3, _omitFieldNames ? '' : 'fromExistingRows')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeyRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeyRule copyWith(void Function(ForeignKeyRule) updates) =>
      super.copyWith((message) => updates(message as ForeignKeyRule))
          as ForeignKeyRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForeignKeyRule create() => ForeignKeyRule._();
  @$core.override
  ForeignKeyRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForeignKeyRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForeignKeyRule>(create);
  static ForeignKeyRule? _defaultInstance;

  /// Parent table.
  @$pb.TagNumber(1)
  $1.TableRef get parent => $_getN(0);
  @$pb.TagNumber(1)
  set parent($1.TableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.TableRef ensureParent() => $_ensure(0);

  /// Parent column.
  @$pb.TagNumber(2)
  $core.String get parentColumn => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentColumn($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentColumn() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentColumn() => $_clearField(2);

  /// Draw from the parent's existing rows instead of the rows generated in
  /// this run.
  @$pb.TagNumber(3)
  $core.bool get fromExistingRows => $_getBF(2);
  @$pb.TagNumber(3)
  set fromExistingRows($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromExistingRows() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromExistingRows() => $_clearField(3);
}

/// DocumentRule builds an embedded document from rules for its fields.
class DocumentRule extends $pb.GeneratedMessage {
  factory DocumentRule({
    $core.Iterable<MockColumnRule>? fields,
  }) {
    final result = create();
    if (fields != null) result.fields.addAll(fields);
    return result;
  }

  DocumentRule._();

  factory DocumentRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DocumentRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DocumentRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<MockColumnRule>(1, _omitFieldNames ? '' : 'fields',
        subBuilder: MockColumnRule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentRule copyWith(void Function(DocumentRule) updates) =>
      super.copyWith((message) => updates(message as DocumentRule))
          as DocumentRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DocumentRule create() => DocumentRule._();
  @$core.override
  DocumentRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DocumentRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DocumentRule>(create);
  static DocumentRule? _defaultInstance;

  /// Rules for the fields; paths are relative to this document.
  @$pb.TagNumber(1)
  $pb.PbList<MockColumnRule> get fields => $_getList(0);
}

/// ArrayRule builds an array whose elements follow one rule.
class ArrayRule extends $pb.GeneratedMessage {
  factory ArrayRule({
    $core.int? minLength,
    $core.int? maxLength,
    MockColumnRule? element,
  }) {
    final result = create();
    if (minLength != null) result.minLength = minLength;
    if (maxLength != null) result.maxLength = maxLength;
    if (element != null) result.element = element;
    return result;
  }

  ArrayRule._();

  factory ArrayRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArrayRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArrayRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'minLength', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'maxLength', fieldType: $pb.PbFieldType.OU3)
    ..aOM<MockColumnRule>(3, _omitFieldNames ? '' : 'element',
        subBuilder: MockColumnRule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayRule copyWith(void Function(ArrayRule) updates) =>
      super.copyWith((message) => updates(message as ArrayRule)) as ArrayRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArrayRule create() => ArrayRule._();
  @$core.override
  ArrayRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArrayRule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArrayRule>(create);
  static ArrayRule? _defaultInstance;

  /// Fewest elements.
  @$pb.TagNumber(1)
  $core.int get minLength => $_getIZ(0);
  @$pb.TagNumber(1)
  set minLength($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMinLength() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinLength() => $_clearField(1);

  /// Most elements.
  @$pb.TagNumber(2)
  $core.int get maxLength => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxLength($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxLength() => $_clearField(2);

  /// Rule for each element; its column_or_path is ignored.
  @$pb.TagNumber(3)
  MockColumnRule get element => $_getN(2);
  @$pb.TagNumber(3)
  set element(MockColumnRule value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasElement() => $_has(2);
  @$pb.TagNumber(3)
  void clearElement() => $_clearField(3);
  @$pb.TagNumber(3)
  MockColumnRule ensureElement() => $_ensure(2);
}

/// SkipRule leaves the column to the server: a default or identity value.
class SkipRule extends $pb.GeneratedMessage {
  factory SkipRule() => create();

  SkipRule._();

  factory SkipRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkipRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkipRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipRule copyWith(void Function(SkipRule) updates) =>
      super.copyWith((message) => updates(message as SkipRule)) as SkipRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkipRule create() => SkipRule._();
  @$core.override
  SkipRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkipRule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkipRule>(create);
  static SkipRule? _defaultInstance;
}

enum MockColumnRule_Rule {
  faker,
  sequence,
  intRange,
  floatRange,
  decimalRange,
  timeRange,
  weightedValues,
  constant,
  pattern,
  foreignKey,
  document,
  array,
  skip,
  notSet
}

/// MockColumnRule says how one column or field path is generated.
class MockColumnRule extends $pb.GeneratedMessage {
  factory MockColumnRule({
    $core.String? columnOrPath,
    $core.double? nullRatio,
    $core.bool? unique,
    FakerRule? faker,
    SequenceRule? sequence,
    IntRangeRule? intRange,
    FloatRangeRule? floatRange,
    DecimalRangeRule? decimalRange,
    TimeRangeRule? timeRange,
    WeightedValuesRule? weightedValues,
    ConstantRule? constant,
    PatternRule? pattern,
    ForeignKeyRule? foreignKey,
    DocumentRule? document,
    ArrayRule? array,
    SkipRule? skip,
  }) {
    final result = create();
    if (columnOrPath != null) result.columnOrPath = columnOrPath;
    if (nullRatio != null) result.nullRatio = nullRatio;
    if (unique != null) result.unique = unique;
    if (faker != null) result.faker = faker;
    if (sequence != null) result.sequence = sequence;
    if (intRange != null) result.intRange = intRange;
    if (floatRange != null) result.floatRange = floatRange;
    if (decimalRange != null) result.decimalRange = decimalRange;
    if (timeRange != null) result.timeRange = timeRange;
    if (weightedValues != null) result.weightedValues = weightedValues;
    if (constant != null) result.constant = constant;
    if (pattern != null) result.pattern = pattern;
    if (foreignKey != null) result.foreignKey = foreignKey;
    if (document != null) result.document = document;
    if (array != null) result.array = array;
    if (skip != null) result.skip = skip;
    return result;
  }

  MockColumnRule._();

  factory MockColumnRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockColumnRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MockColumnRule_Rule>
      _MockColumnRule_RuleByTag = {
    4: MockColumnRule_Rule.faker,
    5: MockColumnRule_Rule.sequence,
    6: MockColumnRule_Rule.intRange,
    7: MockColumnRule_Rule.floatRange,
    8: MockColumnRule_Rule.decimalRange,
    9: MockColumnRule_Rule.timeRange,
    10: MockColumnRule_Rule.weightedValues,
    11: MockColumnRule_Rule.constant,
    12: MockColumnRule_Rule.pattern,
    13: MockColumnRule_Rule.foreignKey,
    14: MockColumnRule_Rule.document,
    15: MockColumnRule_Rule.array,
    16: MockColumnRule_Rule.skip,
    0: MockColumnRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockColumnRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
    ..aOS(1, _omitFieldNames ? '' : 'columnOrPath')
    ..aD(2, _omitFieldNames ? '' : 'nullRatio')
    ..aOB(3, _omitFieldNames ? '' : 'unique')
    ..aOM<FakerRule>(4, _omitFieldNames ? '' : 'faker',
        subBuilder: FakerRule.create)
    ..aOM<SequenceRule>(5, _omitFieldNames ? '' : 'sequence',
        subBuilder: SequenceRule.create)
    ..aOM<IntRangeRule>(6, _omitFieldNames ? '' : 'intRange',
        subBuilder: IntRangeRule.create)
    ..aOM<FloatRangeRule>(7, _omitFieldNames ? '' : 'floatRange',
        subBuilder: FloatRangeRule.create)
    ..aOM<DecimalRangeRule>(8, _omitFieldNames ? '' : 'decimalRange',
        subBuilder: DecimalRangeRule.create)
    ..aOM<TimeRangeRule>(9, _omitFieldNames ? '' : 'timeRange',
        subBuilder: TimeRangeRule.create)
    ..aOM<WeightedValuesRule>(10, _omitFieldNames ? '' : 'weightedValues',
        subBuilder: WeightedValuesRule.create)
    ..aOM<ConstantRule>(11, _omitFieldNames ? '' : 'constant',
        subBuilder: ConstantRule.create)
    ..aOM<PatternRule>(12, _omitFieldNames ? '' : 'pattern',
        subBuilder: PatternRule.create)
    ..aOM<ForeignKeyRule>(13, _omitFieldNames ? '' : 'foreignKey',
        subBuilder: ForeignKeyRule.create)
    ..aOM<DocumentRule>(14, _omitFieldNames ? '' : 'document',
        subBuilder: DocumentRule.create)
    ..aOM<ArrayRule>(15, _omitFieldNames ? '' : 'array',
        subBuilder: ArrayRule.create)
    ..aOM<SkipRule>(16, _omitFieldNames ? '' : 'skip',
        subBuilder: SkipRule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockColumnRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockColumnRule copyWith(void Function(MockColumnRule) updates) =>
      super.copyWith((message) => updates(message as MockColumnRule))
          as MockColumnRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockColumnRule create() => MockColumnRule._();
  @$core.override
  MockColumnRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockColumnRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockColumnRule>(create);
  static MockColumnRule? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  MockColumnRule_Rule whichRule() =>
      _MockColumnRule_RuleByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearRule() => $_clearField($_whichOneof(0));

  /// Column name, or dotted field path for documents.
  @$pb.TagNumber(1)
  $core.String get columnOrPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set columnOrPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumnOrPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumnOrPath() => $_clearField(1);

  /// Share of NULLs (or missing fields for documents), 0 to 1.
  @$pb.TagNumber(2)
  $core.double get nullRatio => $_getN(1);
  @$pb.TagNumber(2)
  set nullRatio($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNullRatio() => $_has(1);
  @$pb.TagNumber(2)
  void clearNullRatio() => $_clearField(2);

  /// Values must not repeat within the run.
  @$pb.TagNumber(3)
  $core.bool get unique => $_getBF(2);
  @$pb.TagNumber(3)
  set unique($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnique() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnique() => $_clearField(3);

  /// Faker kind.
  @$pb.TagNumber(4)
  FakerRule get faker => $_getN(3);
  @$pb.TagNumber(4)
  set faker(FakerRule value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFaker() => $_has(3);
  @$pb.TagNumber(4)
  void clearFaker() => $_clearField(4);
  @$pb.TagNumber(4)
  FakerRule ensureFaker() => $_ensure(3);

  /// Counter.
  @$pb.TagNumber(5)
  SequenceRule get sequence => $_getN(4);
  @$pb.TagNumber(5)
  set sequence(SequenceRule value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSequence() => $_has(4);
  @$pb.TagNumber(5)
  void clearSequence() => $_clearField(5);
  @$pb.TagNumber(5)
  SequenceRule ensureSequence() => $_ensure(4);

  /// Integer range.
  @$pb.TagNumber(6)
  IntRangeRule get intRange => $_getN(5);
  @$pb.TagNumber(6)
  set intRange(IntRangeRule value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasIntRange() => $_has(5);
  @$pb.TagNumber(6)
  void clearIntRange() => $_clearField(6);
  @$pb.TagNumber(6)
  IntRangeRule ensureIntRange() => $_ensure(5);

  /// Float range.
  @$pb.TagNumber(7)
  FloatRangeRule get floatRange => $_getN(6);
  @$pb.TagNumber(7)
  set floatRange(FloatRangeRule value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasFloatRange() => $_has(6);
  @$pb.TagNumber(7)
  void clearFloatRange() => $_clearField(7);
  @$pb.TagNumber(7)
  FloatRangeRule ensureFloatRange() => $_ensure(6);

  /// Decimal range.
  @$pb.TagNumber(8)
  DecimalRangeRule get decimalRange => $_getN(7);
  @$pb.TagNumber(8)
  set decimalRange(DecimalRangeRule value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasDecimalRange() => $_has(7);
  @$pb.TagNumber(8)
  void clearDecimalRange() => $_clearField(8);
  @$pb.TagNumber(8)
  DecimalRangeRule ensureDecimalRange() => $_ensure(7);

  /// Date or timestamp range.
  @$pb.TagNumber(9)
  TimeRangeRule get timeRange => $_getN(8);
  @$pb.TagNumber(9)
  set timeRange(TimeRangeRule value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasTimeRange() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimeRange() => $_clearField(9);
  @$pb.TagNumber(9)
  TimeRangeRule ensureTimeRange() => $_ensure(8);

  /// Weighted list.
  @$pb.TagNumber(10)
  WeightedValuesRule get weightedValues => $_getN(9);
  @$pb.TagNumber(10)
  set weightedValues(WeightedValuesRule value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasWeightedValues() => $_has(9);
  @$pb.TagNumber(10)
  void clearWeightedValues() => $_clearField(10);
  @$pb.TagNumber(10)
  WeightedValuesRule ensureWeightedValues() => $_ensure(9);

  /// Constant.
  @$pb.TagNumber(11)
  ConstantRule get constant => $_getN(10);
  @$pb.TagNumber(11)
  set constant(ConstantRule value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasConstant() => $_has(10);
  @$pb.TagNumber(11)
  void clearConstant() => $_clearField(11);
  @$pb.TagNumber(11)
  ConstantRule ensureConstant() => $_ensure(10);

  /// Pattern.
  @$pb.TagNumber(12)
  PatternRule get pattern => $_getN(11);
  @$pb.TagNumber(12)
  set pattern(PatternRule value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasPattern() => $_has(11);
  @$pb.TagNumber(12)
  void clearPattern() => $_clearField(12);
  @$pb.TagNumber(12)
  PatternRule ensurePattern() => $_ensure(11);

  /// Foreign key.
  @$pb.TagNumber(13)
  ForeignKeyRule get foreignKey => $_getN(12);
  @$pb.TagNumber(13)
  set foreignKey(ForeignKeyRule value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasForeignKey() => $_has(12);
  @$pb.TagNumber(13)
  void clearForeignKey() => $_clearField(13);
  @$pb.TagNumber(13)
  ForeignKeyRule ensureForeignKey() => $_ensure(12);

  /// Embedded document.
  @$pb.TagNumber(14)
  DocumentRule get document => $_getN(13);
  @$pb.TagNumber(14)
  set document(DocumentRule value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasDocument() => $_has(13);
  @$pb.TagNumber(14)
  void clearDocument() => $_clearField(14);
  @$pb.TagNumber(14)
  DocumentRule ensureDocument() => $_ensure(13);

  /// Array.
  @$pb.TagNumber(15)
  ArrayRule get array => $_getN(14);
  @$pb.TagNumber(15)
  set array(ArrayRule value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasArray() => $_has(14);
  @$pb.TagNumber(15)
  void clearArray() => $_clearField(15);
  @$pb.TagNumber(15)
  ArrayRule ensureArray() => $_ensure(14);

  /// Left to the server.
  @$pb.TagNumber(16)
  SkipRule get skip => $_getN(15);
  @$pb.TagNumber(16)
  set skip(SkipRule value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasSkip() => $_has(15);
  @$pb.TagNumber(16)
  void clearSkip() => $_clearField(16);
  @$pb.TagNumber(16)
  SkipRule ensureSkip() => $_ensure(15);
}

/// MockTarget is one table or collection to fill.
class MockTarget extends $pb.GeneratedMessage {
  factory MockTarget({
    MockTargetRef? target,
    $fixnum.Int64? rows,
    $core.Iterable<MockColumnRule>? rules,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (rows != null) result.rows = rows;
    if (rules != null) result.rules.addAll(rules);
    return result;
  }

  MockTarget._();

  factory MockTarget.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockTarget.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockTarget',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MockTargetRef>(1, _omitFieldNames ? '' : 'target',
        subBuilder: MockTargetRef.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<MockColumnRule>(3, _omitFieldNames ? '' : 'rules',
        subBuilder: MockColumnRule.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTarget clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTarget copyWith(void Function(MockTarget) updates) =>
      super.copyWith((message) => updates(message as MockTarget)) as MockTarget;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockTarget create() => MockTarget._();
  @$core.override
  MockTarget createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockTarget getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockTarget>(create);
  static MockTarget? _defaultInstance;

  /// Table or collection.
  @$pb.TagNumber(1)
  MockTargetRef get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(MockTargetRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  MockTargetRef ensureTarget() => $_ensure(0);

  /// Rows or documents to generate.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rows => $_getI64(1);
  @$pb.TagNumber(2)
  set rows($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRows() => $_has(1);
  @$pb.TagNumber(2)
  void clearRows() => $_clearField(2);

  /// Rules; columns without a rule are skipped.
  @$pb.TagNumber(3)
  $pb.PbList<MockColumnRule> get rules => $_getList(2);
}

/// MockSpec is a whole generation run.
class MockSpec extends $pb.GeneratedMessage {
  factory MockSpec({
    $fixnum.Int64? seed,
    $core.Iterable<MockTarget>? targets,
  }) {
    final result = create();
    if (seed != null) result.seed = seed;
    if (targets != null) result.targets.addAll(targets);
    return result;
  }

  MockSpec._();

  factory MockSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seed', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<MockTarget>(2, _omitFieldNames ? '' : 'targets',
        subBuilder: MockTarget.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockSpec copyWith(void Function(MockSpec) updates) =>
      super.copyWith((message) => updates(message as MockSpec)) as MockSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockSpec create() => MockSpec._();
  @$core.override
  MockSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MockSpec>(create);
  static MockSpec? _defaultInstance;

  /// Random seed; the same seed and spec give the same rows.
  @$pb.TagNumber(1)
  $fixnum.Int64 get seed => $_getI64(0);
  @$pb.TagNumber(1)
  set seed($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeed() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeed() => $_clearField(1);

  /// Targets in load order.
  @$pb.TagNumber(2)
  $pb.PbList<MockTarget> get targets => $_getList(1);
}

/// MockCycleEdge is one foreign key in a cycle.
class MockCycleEdge extends $pb.GeneratedMessage {
  factory MockCycleEdge({
    $1.TableRef? child,
    $1.TableRef? parent,
    $core.String? constraintName,
    $core.bool? nullable,
  }) {
    final result = create();
    if (child != null) result.child = child;
    if (parent != null) result.parent = parent;
    if (constraintName != null) result.constraintName = constraintName;
    if (nullable != null) result.nullable = nullable;
    return result;
  }

  MockCycleEdge._();

  factory MockCycleEdge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockCycleEdge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockCycleEdge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.TableRef>(1, _omitFieldNames ? '' : 'child',
        subBuilder: $1.TableRef.create)
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'parent',
        subBuilder: $1.TableRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'constraintName')
    ..aOB(4, _omitFieldNames ? '' : 'nullable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockCycleEdge clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockCycleEdge copyWith(void Function(MockCycleEdge) updates) =>
      super.copyWith((message) => updates(message as MockCycleEdge))
          as MockCycleEdge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockCycleEdge create() => MockCycleEdge._();
  @$core.override
  MockCycleEdge createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockCycleEdge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockCycleEdge>(create);
  static MockCycleEdge? _defaultInstance;

  /// Referencing table.
  @$pb.TagNumber(1)
  $1.TableRef get child => $_getN(0);
  @$pb.TagNumber(1)
  set child($1.TableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChild() => $_has(0);
  @$pb.TagNumber(1)
  void clearChild() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.TableRef ensureChild() => $_ensure(0);

  /// Referenced table.
  @$pb.TagNumber(2)
  $1.TableRef get parent => $_getN(1);
  @$pb.TagNumber(2)
  set parent($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearParent() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureParent() => $_ensure(1);

  /// Foreign key name.
  @$pb.TagNumber(3)
  $core.String get constraintName => $_getSZ(2);
  @$pb.TagNumber(3)
  set constraintName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConstraintName() => $_has(2);
  @$pb.TagNumber(3)
  void clearConstraintName() => $_clearField(3);

  /// True when every column of the key is nullable, so it can be set to NULL.
  @$pb.TagNumber(4)
  $core.bool get nullable => $_getBF(3);
  @$pb.TagNumber(4)
  set nullable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNullable() => $_has(3);
  @$pb.TagNumber(4)
  void clearNullable() => $_clearField(4);
}

/// MockCycle is a foreign-key cycle among the targets.
class MockCycle extends $pb.GeneratedMessage {
  factory MockCycle({
    $core.Iterable<MockCycleEdge>? edges,
  }) {
    final result = create();
    if (edges != null) result.edges.addAll(edges);
    return result;
  }

  MockCycle._();

  factory MockCycle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockCycle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockCycle',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<MockCycleEdge>(1, _omitFieldNames ? '' : 'edges',
        subBuilder: MockCycleEdge.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockCycle clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockCycle copyWith(void Function(MockCycle) updates) =>
      super.copyWith((message) => updates(message as MockCycle)) as MockCycle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockCycle create() => MockCycle._();
  @$core.override
  MockCycle createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockCycle getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MockCycle>(create);
  static MockCycle? _defaultInstance;

  /// Edges in cycle order.
  @$pb.TagNumber(1)
  $pb.PbList<MockCycleEdge> get edges => $_getList(0);
}

/// SuggestMockSpecRequest selects targets.
class SuggestMockSpecRequest extends $pb.GeneratedMessage {
  factory SuggestMockSpecRequest({
    $core.String? sessionId,
    $core.Iterable<$1.TableRef>? tables,
    $core.Iterable<$2.CollectionRef>? collections,
    $fixnum.Int64? rows,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tables != null) result.tables.addAll(tables);
    if (collections != null) result.collections.addAll(collections);
    if (rows != null) result.rows = rows;
    return result;
  }

  SuggestMockSpecRequest._();

  factory SuggestMockSpecRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestMockSpecRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestMockSpecRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..pPM<$1.TableRef>(2, _omitFieldNames ? '' : 'tables',
        subBuilder: $1.TableRef.create)
    ..pPM<$2.CollectionRef>(3, _omitFieldNames ? '' : 'collections',
        subBuilder: $2.CollectionRef.create)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestMockSpecRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestMockSpecRequest copyWith(
          void Function(SuggestMockSpecRequest) updates) =>
      super.copyWith((message) => updates(message as SuggestMockSpecRequest))
          as SuggestMockSpecRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestMockSpecRequest create() => SuggestMockSpecRequest._();
  @$core.override
  SuggestMockSpecRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestMockSpecRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestMockSpecRequest>(create);
  static SuggestMockSpecRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Tables to fill.
  @$pb.TagNumber(2)
  $pb.PbList<$1.TableRef> get tables => $_getList(1);

  /// Collections to fill.
  @$pb.TagNumber(3)
  $pb.PbList<$2.CollectionRef> get collections => $_getList(2);

  /// Rows per target in the suggestion; 0 means 1000.
  @$pb.TagNumber(4)
  $fixnum.Int64 get rows => $_getI64(3);
  @$pb.TagNumber(4)
  set rows($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRows() => $_has(3);
  @$pb.TagNumber(4)
  void clearRows() => $_clearField(4);
}

/// SuggestMockSpecResponse is a ready-to-run spec.
class SuggestMockSpecResponse extends $pb.GeneratedMessage {
  factory SuggestMockSpecResponse({
    MockSpec? spec,
    $core.Iterable<MockCycle>? cycles,
    $core.Iterable<$core.String>? fakerKinds,
    $core.Iterable<$core.String>? warnings,
    MockError? error,
  }) {
    final result = create();
    if (spec != null) result.spec = spec;
    if (cycles != null) result.cycles.addAll(cycles);
    if (fakerKinds != null) result.fakerKinds.addAll(fakerKinds);
    if (warnings != null) result.warnings.addAll(warnings);
    if (error != null) result.error = error;
    return result;
  }

  SuggestMockSpecResponse._();

  factory SuggestMockSpecResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestMockSpecResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestMockSpecResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MockSpec>(1, _omitFieldNames ? '' : 'spec',
        subBuilder: MockSpec.create)
    ..pPM<MockCycle>(2, _omitFieldNames ? '' : 'cycles',
        subBuilder: MockCycle.create)
    ..pPS(3, _omitFieldNames ? '' : 'fakerKinds')
    ..pPS(4, _omitFieldNames ? '' : 'warnings')
    ..aOM<MockError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: MockError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestMockSpecResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestMockSpecResponse copyWith(
          void Function(SuggestMockSpecResponse) updates) =>
      super.copyWith((message) => updates(message as SuggestMockSpecResponse))
          as SuggestMockSpecResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestMockSpecResponse create() => SuggestMockSpecResponse._();
  @$core.override
  SuggestMockSpecResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestMockSpecResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestMockSpecResponse>(create);
  static SuggestMockSpecResponse? _defaultInstance;

  /// Spec with default rules, targets in foreign-key order.
  @$pb.TagNumber(1)
  MockSpec get spec => $_getN(0);
  @$pb.TagNumber(1)
  set spec(MockSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSpec() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpec() => $_clearField(1);
  @$pb.TagNumber(1)
  MockSpec ensureSpec() => $_ensure(0);

  /// Cycles that block a run until broken.
  @$pb.TagNumber(2)
  $pb.PbList<MockCycle> get cycles => $_getList(1);

  /// Faker kinds this core supports.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get fakerKinds => $_getList(2);

  /// Notes, e.g. a column type without a default rule.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get warnings => $_getList(3);

  /// Set when the targets could not be described.
  @$pb.TagNumber(5)
  MockError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(MockError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  MockError ensureError() => $_ensure(4);
}

/// PreviewMockRequest asks for sample rows.
class PreviewMockRequest extends $pb.GeneratedMessage {
  factory PreviewMockRequest({
    $core.String? sessionId,
    MockSpec? spec,
    $core.int? rows,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (spec != null) result.spec = spec;
    if (rows != null) result.rows = rows;
    return result;
  }

  PreviewMockRequest._();

  factory PreviewMockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewMockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewMockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<MockSpec>(2, _omitFieldNames ? '' : 'spec',
        subBuilder: MockSpec.create)
    ..aI(3, _omitFieldNames ? '' : 'rows', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewMockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewMockRequest copyWith(void Function(PreviewMockRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewMockRequest))
          as PreviewMockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewMockRequest create() => PreviewMockRequest._();
  @$core.override
  PreviewMockRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewMockRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewMockRequest>(create);
  static PreviewMockRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Spec to preview.
  @$pb.TagNumber(2)
  MockSpec get spec => $_getN(1);
  @$pb.TagNumber(2)
  set spec(MockSpec value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSpec() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpec() => $_clearField(2);
  @$pb.TagNumber(2)
  MockSpec ensureSpec() => $_ensure(1);

  /// Rows per target; 0 means 20, at most 200.
  @$pb.TagNumber(3)
  $core.int get rows => $_getIZ(2);
  @$pb.TagNumber(3)
  set rows($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRows() => $_has(2);
  @$pb.TagNumber(3)
  void clearRows() => $_clearField(3);
}

/// MockPreview holds sample rows for one target.
class MockPreview extends $pb.GeneratedMessage {
  factory MockPreview({
    MockTargetRef? target,
    $core.Iterable<$core.String>? columns,
    $3.RowBatch? rows,
    $core.Iterable<$core.String>? documentsEjson,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (columns != null) result.columns.addAll(columns);
    if (rows != null) result.rows = rows;
    if (documentsEjson != null) result.documentsEjson.addAll(documentsEjson);
    return result;
  }

  MockPreview._();

  factory MockPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MockTargetRef>(1, _omitFieldNames ? '' : 'target',
        subBuilder: MockTargetRef.create)
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..aOM<$3.RowBatch>(3, _omitFieldNames ? '' : 'rows',
        subBuilder: $3.RowBatch.create)
    ..pPS(4, _omitFieldNames ? '' : 'documentsEjson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockPreview copyWith(void Function(MockPreview) updates) =>
      super.copyWith((message) => updates(message as MockPreview))
          as MockPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockPreview create() => MockPreview._();
  @$core.override
  MockPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockPreview>(create);
  static MockPreview? _defaultInstance;

  /// Target.
  @$pb.TagNumber(1)
  MockTargetRef get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(MockTargetRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  MockTargetRef ensureTarget() => $_ensure(0);

  /// Column names in the order of the rows' values, for tables.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);

  /// Rows, for tables.
  @$pb.TagNumber(3)
  $3.RowBatch get rows => $_getN(2);
  @$pb.TagNumber(3)
  set rows($3.RowBatch value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRows() => $_has(2);
  @$pb.TagNumber(3)
  void clearRows() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.RowBatch ensureRows() => $_ensure(2);

  /// Documents as canonical EJSON, for collections.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get documentsEjson => $_getList(3);
}

/// PreviewMockResponse holds one preview per target.
class PreviewMockResponse extends $pb.GeneratedMessage {
  factory PreviewMockResponse({
    $core.Iterable<MockPreview>? previews,
    MockError? error,
  }) {
    final result = create();
    if (previews != null) result.previews.addAll(previews);
    if (error != null) result.error = error;
    return result;
  }

  PreviewMockResponse._();

  factory PreviewMockResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewMockResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewMockResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<MockPreview>(1, _omitFieldNames ? '' : 'previews',
        subBuilder: MockPreview.create)
    ..aOM<MockError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: MockError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewMockResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewMockResponse copyWith(void Function(PreviewMockResponse) updates) =>
      super.copyWith((message) => updates(message as PreviewMockResponse))
          as PreviewMockResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewMockResponse create() => PreviewMockResponse._();
  @$core.override
  PreviewMockResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewMockResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewMockResponse>(create);
  static PreviewMockResponse? _defaultInstance;

  /// Previews in spec order.
  @$pb.TagNumber(1)
  $pb.PbList<MockPreview> get previews => $_getList(0);

  /// Set when the spec is invalid.
  @$pb.TagNumber(2)
  MockError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(MockError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  MockError ensureError() => $_ensure(1);
}

/// RunMockRequest starts a run.
class RunMockRequest extends $pb.GeneratedMessage {
  factory RunMockRequest({
    $core.String? sessionId,
    MockSpec? spec,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (spec != null) result.spec = spec;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  RunMockRequest._();

  factory RunMockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RunMockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunMockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<MockSpec>(2, _omitFieldNames ? '' : 'spec',
        subBuilder: MockSpec.create)
    ..aOB(3, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunMockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunMockRequest copyWith(void Function(RunMockRequest) updates) =>
      super.copyWith((message) => updates(message as RunMockRequest))
          as RunMockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunMockRequest create() => RunMockRequest._();
  @$core.override
  RunMockRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RunMockRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunMockRequest>(create);
  static RunMockRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Spec to run.
  @$pb.TagNumber(2)
  MockSpec get spec => $_getN(1);
  @$pb.TagNumber(2)
  set spec(MockSpec value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSpec() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpec() => $_clearField(2);
  @$pb.TagNumber(2)
  MockSpec ensureSpec() => $_ensure(1);

  /// Required on connections flagged production.
  @$pb.TagNumber(3)
  $core.bool get confirmed => $_getBF(2);
  @$pb.TagNumber(3)
  set confirmed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConfirmed() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfirmed() => $_clearField(3);
}

/// MockProgress reports one target's progress.
class MockProgress extends $pb.GeneratedMessage {
  factory MockProgress({
    MockTargetRef? target,
    $fixnum.Int64? rows,
    $core.double? rowsPerSecond,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (rows != null) result.rows = rows;
    if (rowsPerSecond != null) result.rowsPerSecond = rowsPerSecond;
    return result;
  }

  MockProgress._();

  factory MockProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MockTargetRef>(1, _omitFieldNames ? '' : 'target',
        subBuilder: MockTargetRef.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(3, _omitFieldNames ? '' : 'rowsPerSecond')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockProgress copyWith(void Function(MockProgress) updates) =>
      super.copyWith((message) => updates(message as MockProgress))
          as MockProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockProgress create() => MockProgress._();
  @$core.override
  MockProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockProgress>(create);
  static MockProgress? _defaultInstance;

  /// Target being loaded.
  @$pb.TagNumber(1)
  MockTargetRef get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(MockTargetRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  MockTargetRef ensureTarget() => $_ensure(0);

  /// Rows committed so far.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rows => $_getI64(1);
  @$pb.TagNumber(2)
  set rows($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRows() => $_has(1);
  @$pb.TagNumber(2)
  void clearRows() => $_clearField(2);

  /// Recent load rate.
  @$pb.TagNumber(3)
  $core.double get rowsPerSecond => $_getN(2);
  @$pb.TagNumber(3)
  set rowsPerSecond($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRowsPerSecond() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowsPerSecond() => $_clearField(3);
}

/// MockTargetDone reports a finished target.
class MockTargetDone extends $pb.GeneratedMessage {
  factory MockTargetDone({
    MockTargetRef? target,
    $fixnum.Int64? rows,
    $fixnum.Int64? elapsedMs,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (rows != null) result.rows = rows;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    return result;
  }

  MockTargetDone._();

  factory MockTargetDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockTargetDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockTargetDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<MockTargetRef>(1, _omitFieldNames ? '' : 'target',
        subBuilder: MockTargetRef.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'elapsedMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTargetDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockTargetDone copyWith(void Function(MockTargetDone) updates) =>
      super.copyWith((message) => updates(message as MockTargetDone))
          as MockTargetDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockTargetDone create() => MockTargetDone._();
  @$core.override
  MockTargetDone createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockTargetDone getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockTargetDone>(create);
  static MockTargetDone? _defaultInstance;

  /// Target.
  @$pb.TagNumber(1)
  MockTargetRef get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(MockTargetRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  MockTargetRef ensureTarget() => $_ensure(0);

  /// Rows committed.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rows => $_getI64(1);
  @$pb.TagNumber(2)
  set rows($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRows() => $_has(1);
  @$pb.TagNumber(2)
  void clearRows() => $_clearField(2);

  /// Time spent, milliseconds.
  @$pb.TagNumber(3)
  $fixnum.Int64 get elapsedMs => $_getI64(2);
  @$pb.TagNumber(3)
  set elapsedMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasElapsedMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearElapsedMs() => $_clearField(3);
}

/// MockSummary ends a run, completely or after a failure or cancel.
class MockSummary extends $pb.GeneratedMessage {
  factory MockSummary({
    $fixnum.Int64? rows,
    $fixnum.Int64? elapsedMs,
    $core.Iterable<MockTargetDone>? done,
  }) {
    final result = create();
    if (rows != null) result.rows = rows;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    if (done != null) result.done.addAll(done);
    return result;
  }

  MockSummary._();

  factory MockSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MockSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MockSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'elapsedMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<MockTargetDone>(3, _omitFieldNames ? '' : 'done',
        subBuilder: MockTargetDone.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MockSummary copyWith(void Function(MockSummary) updates) =>
      super.copyWith((message) => updates(message as MockSummary))
          as MockSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MockSummary create() => MockSummary._();
  @$core.override
  MockSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MockSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MockSummary>(create);
  static MockSummary? _defaultInstance;

  /// Rows committed across all targets.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rows => $_getI64(0);
  @$pb.TagNumber(1)
  set rows($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearRows() => $_clearField(1);

  /// Time spent, milliseconds.
  @$pb.TagNumber(2)
  $fixnum.Int64 get elapsedMs => $_getI64(1);
  @$pb.TagNumber(2)
  set elapsedMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasElapsedMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearElapsedMs() => $_clearField(2);

  /// Targets that finished, in order.
  @$pb.TagNumber(3)
  $pb.PbList<MockTargetDone> get done => $_getList(2);
}

enum RunMockResponse_Event { progress, targetDone, summary, error, notSet }

/// RunMockResponse is one event of a run: progress and finished targets, then
/// a summary, or an error followed by a summary.
class RunMockResponse extends $pb.GeneratedMessage {
  factory RunMockResponse({
    MockProgress? progress,
    MockTargetDone? targetDone,
    MockSummary? summary,
    MockError? error,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (targetDone != null) result.targetDone = targetDone;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    return result;
  }

  RunMockResponse._();

  factory RunMockResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RunMockResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RunMockResponse_Event>
      _RunMockResponse_EventByTag = {
    1: RunMockResponse_Event.progress,
    2: RunMockResponse_Event.targetDone,
    3: RunMockResponse_Event.summary,
    4: RunMockResponse_Event.error,
    0: RunMockResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunMockResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<MockProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: MockProgress.create)
    ..aOM<MockTargetDone>(2, _omitFieldNames ? '' : 'targetDone',
        subBuilder: MockTargetDone.create)
    ..aOM<MockSummary>(3, _omitFieldNames ? '' : 'summary',
        subBuilder: MockSummary.create)
    ..aOM<MockError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: MockError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunMockResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunMockResponse copyWith(void Function(RunMockResponse) updates) =>
      super.copyWith((message) => updates(message as RunMockResponse))
          as RunMockResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunMockResponse create() => RunMockResponse._();
  @$core.override
  RunMockResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RunMockResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunMockResponse>(create);
  static RunMockResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  RunMockResponse_Event whichEvent() =>
      _RunMockResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// Throttled progress.
  @$pb.TagNumber(1)
  MockProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(MockProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  MockProgress ensureProgress() => $_ensure(0);

  /// A target finished.
  @$pb.TagNumber(2)
  MockTargetDone get targetDone => $_getN(1);
  @$pb.TagNumber(2)
  set targetDone(MockTargetDone value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetDone() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetDone() => $_clearField(2);
  @$pb.TagNumber(2)
  MockTargetDone ensureTargetDone() => $_ensure(1);

  /// Last event.
  @$pb.TagNumber(3)
  MockSummary get summary => $_getN(2);
  @$pb.TagNumber(3)
  set summary(MockSummary value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummary() => $_clearField(3);
  @$pb.TagNumber(3)
  MockSummary ensureSummary() => $_ensure(2);

  /// Failure that stopped the run.
  @$pb.TagNumber(4)
  MockError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(MockError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  MockError ensureError() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
