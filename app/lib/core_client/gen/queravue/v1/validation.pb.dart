// This is a generated file - do not edit.
//
// Generated from queravue/v1/validation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $2;
import 'schema.pb.dart' as $1;
import 'validation.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'validation.pbenum.dart';

/// ValidationRule is a collection's validation settings.
class ValidationRule extends $pb.GeneratedMessage {
  factory ValidationRule({
    $core.String? validator,
    ValidationLevel? level,
    ValidationAction? action,
  }) {
    final result = create();
    if (validator != null) result.validator = validator;
    if (level != null) result.level = level;
    if (action != null) result.action = action;
    return result;
  }

  ValidationRule._();

  factory ValidationRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidationRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidationRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'validator')
    ..aE<ValidationLevel>(2, _omitFieldNames ? '' : 'level',
        enumValues: ValidationLevel.values)
    ..aE<ValidationAction>(3, _omitFieldNames ? '' : 'action',
        enumValues: ValidationAction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidationRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidationRule copyWith(void Function(ValidationRule) updates) =>
      super.copyWith((message) => updates(message as ValidationRule))
          as ValidationRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidationRule create() => ValidationRule._();
  @$core.override
  ValidationRule createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidationRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidationRule>(create);
  static ValidationRule? _defaultInstance;

  /// Validator document as canonical Extended JSON, for example {"$jsonSchema": {...}}. Empty means none.
  @$pb.TagNumber(1)
  $core.String get validator => $_getSZ(0);
  @$pb.TagNumber(1)
  set validator($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValidator() => $_has(0);
  @$pb.TagNumber(1)
  void clearValidator() => $_clearField(1);

  /// Which writes are validated.
  @$pb.TagNumber(2)
  ValidationLevel get level => $_getN(1);
  @$pb.TagNumber(2)
  set level(ValidationLevel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => $_clearField(2);

  /// What happens on failure.
  @$pb.TagNumber(3)
  ValidationAction get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(ValidationAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);
}

/// GetValidationRequest selects the collection.
class GetValidationRequest extends $pb.GeneratedMessage {
  factory GetValidationRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    return result;
  }

  GetValidationRequest._();

  factory GetValidationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetValidationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetValidationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetValidationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetValidationRequest copyWith(void Function(GetValidationRequest) updates) =>
      super.copyWith((message) => updates(message as GetValidationRequest))
          as GetValidationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetValidationRequest create() => GetValidationRequest._();
  @$core.override
  GetValidationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetValidationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetValidationRequest>(create);
  static GetValidationRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Collection (database + table as collection, schema empty).
  @$pb.TagNumber(2)
  $1.TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureTableRef() => $_ensure(1);
}

/// GetValidationResponse carries the rule or an error.
class GetValidationResponse extends $pb.GeneratedMessage {
  factory GetValidationResponse({
    ValidationRule? rule,
    $2.AdminError? error,
  }) {
    final result = create();
    if (rule != null) result.rule = rule;
    if (error != null) result.error = error;
    return result;
  }

  GetValidationResponse._();

  factory GetValidationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetValidationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetValidationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ValidationRule>(1, _omitFieldNames ? '' : 'rule',
        subBuilder: ValidationRule.create)
    ..aOM<$2.AdminError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetValidationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetValidationResponse copyWith(
          void Function(GetValidationResponse) updates) =>
      super.copyWith((message) => updates(message as GetValidationResponse))
          as GetValidationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetValidationResponse create() => GetValidationResponse._();
  @$core.override
  GetValidationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetValidationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetValidationResponse>(create);
  static GetValidationResponse? _defaultInstance;

  /// Current rule; validator is empty when none is set.
  @$pb.TagNumber(1)
  ValidationRule get rule => $_getN(0);
  @$pb.TagNumber(1)
  set rule(ValidationRule value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRule() => $_has(0);
  @$pb.TagNumber(1)
  void clearRule() => $_clearField(1);
  @$pb.TagNumber(1)
  ValidationRule ensureRule() => $_ensure(0);

  /// Set when the call failed, for example UNSUPPORTED on a server without validators.
  @$pb.TagNumber(2)
  $2.AdminError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($2.AdminError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.AdminError ensureError() => $_ensure(1);
}

/// SetValidationRequest replaces the validation rule.
class SetValidationRequest extends $pb.GeneratedMessage {
  factory SetValidationRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
    ValidationRule? rule,
    $core.bool? dryRun,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (rule != null) result.rule = rule;
    if (dryRun != null) result.dryRun = dryRun;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  SetValidationRequest._();

  factory SetValidationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetValidationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetValidationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..aOM<ValidationRule>(3, _omitFieldNames ? '' : 'rule',
        subBuilder: ValidationRule.create)
    ..aOB(4, _omitFieldNames ? '' : 'dryRun')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValidationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValidationRequest copyWith(void Function(SetValidationRequest) updates) =>
      super.copyWith((message) => updates(message as SetValidationRequest))
          as SetValidationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetValidationRequest create() => SetValidationRequest._();
  @$core.override
  SetValidationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetValidationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetValidationRequest>(create);
  static SetValidationRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Collection.
  @$pb.TagNumber(2)
  $1.TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureTableRef() => $_ensure(1);

  /// New rule. An empty validator removes the current one.
  @$pb.TagNumber(3)
  ValidationRule get rule => $_getN(2);
  @$pb.TagNumber(3)
  set rule(ValidationRule value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRule() => $_has(2);
  @$pb.TagNumber(3)
  void clearRule() => $_clearField(3);
  @$pb.TagNumber(3)
  ValidationRule ensureRule() => $_ensure(2);

  /// If true, validates the rule and returns the command without running it.
  @$pb.TagNumber(4)
  $core.bool get dryRun => $_getBF(3);
  @$pb.TagNumber(4)
  set dryRun($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDryRun() => $_has(3);
  @$pb.TagNumber(4)
  void clearDryRun() => $_clearField(4);

  /// Required on connections flagged production.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// SetValidationResponse reports the command and outcome.
class SetValidationResponse extends $pb.GeneratedMessage {
  factory SetValidationResponse({
    $core.String? command,
    $core.bool? dryRun,
    $2.AdminError? error,
  }) {
    final result = create();
    if (command != null) result.command = command;
    if (dryRun != null) result.dryRun = dryRun;
    if (error != null) result.error = error;
    return result;
  }

  SetValidationResponse._();

  factory SetValidationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetValidationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetValidationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'command')
    ..aOB(2, _omitFieldNames ? '' : 'dryRun')
    ..aOM<$2.AdminError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValidationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetValidationResponse copyWith(
          void Function(SetValidationResponse) updates) =>
      super.copyWith((message) => updates(message as SetValidationResponse))
          as SetValidationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetValidationResponse create() => SetValidationResponse._();
  @$core.override
  SetValidationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetValidationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetValidationResponse>(create);
  static SetValidationResponse? _defaultInstance;

  /// The collMod command as shell text that ran (or would run on dry_run).
  @$pb.TagNumber(1)
  $core.String get command => $_getSZ(0);
  @$pb.TagNumber(1)
  set command($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommand() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommand() => $_clearField(1);

  /// True if nothing was executed.
  @$pb.TagNumber(2)
  $core.bool get dryRun => $_getBF(1);
  @$pb.TagNumber(2)
  set dryRun($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDryRun() => $_has(1);
  @$pb.TagNumber(2)
  void clearDryRun() => $_clearField(2);

  /// Set when the call failed or was refused; INVALID errors carry a position into rule.validator.
  @$pb.TagNumber(3)
  $2.AdminError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error($2.AdminError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.AdminError ensureError() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
