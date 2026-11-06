// This is a generated file - do not edit.
//
// Generated from queravue/v1/shell.proto.

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
    as $1;

import 'document.pb.dart' as $2;
import 'shell.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'shell.pbenum.dart';

/// OpenShellRequest selects the session and starting database.
class OpenShellRequest extends $pb.GeneratedMessage {
  factory OpenShellRequest({
    $core.String? sessionId,
    $core.String? database,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    return result;
  }

  OpenShellRequest._();

  factory OpenShellRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenShellRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenShellRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenShellRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenShellRequest copyWith(void Function(OpenShellRequest) updates) =>
      super.copyWith((message) => updates(message as OpenShellRequest))
          as OpenShellRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenShellRequest create() => OpenShellRequest._();
  @$core.override
  OpenShellRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenShellRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenShellRequest>(create);
  static OpenShellRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database that `db` points to initially. Empty means the connection's
  /// default database.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);
}

/// OpenShellResponse carries the new shell.
class OpenShellResponse extends $pb.GeneratedMessage {
  factory OpenShellResponse({
    $core.String? shellId,
    $core.String? database,
  }) {
    final result = create();
    if (shellId != null) result.shellId = shellId;
    if (database != null) result.database = database;
    return result;
  }

  OpenShellResponse._();

  factory OpenShellResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenShellResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenShellResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shellId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenShellResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenShellResponse copyWith(void Function(OpenShellResponse) updates) =>
      super.copyWith((message) => updates(message as OpenShellResponse))
          as OpenShellResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenShellResponse create() => OpenShellResponse._();
  @$core.override
  OpenShellResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenShellResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenShellResponse>(create);
  static OpenShellResponse? _defaultInstance;

  /// Id of the new shell.
  @$pb.TagNumber(1)
  $core.String get shellId => $_getSZ(0);
  @$pb.TagNumber(1)
  set shellId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShellId() => $_has(0);
  @$pb.TagNumber(1)
  void clearShellId() => $_clearField(1);

  /// Database that `db` points to.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);
}

/// EvalRequest is the input of Eval.
class EvalRequest extends $pb.GeneratedMessage {
  factory EvalRequest({
    $core.String? shellId,
    $core.String? code,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (shellId != null) result.shellId = shellId;
    if (code != null) result.code = code;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  EvalRequest._();

  factory EvalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EvalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shellId')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOB(3, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalRequest copyWith(void Function(EvalRequest) updates) =>
      super.copyWith((message) => updates(message as EvalRequest))
          as EvalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EvalRequest create() => EvalRequest._();
  @$core.override
  EvalRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EvalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EvalRequest>(create);
  static EvalRequest? _defaultInstance;

  /// Shell id from OpenShell.
  @$pb.TagNumber(1)
  $core.String get shellId => $_getSZ(0);
  @$pb.TagNumber(1)
  set shellId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShellId() => $_has(0);
  @$pb.TagNumber(1)
  void clearShellId() => $_clearField(1);

  /// JavaScript source, one or more statements.
  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  /// Set after the user confirmed a CONFIRMATION_REQUIRED error. Allows the
  /// gated operations of this call.
  @$pb.TagNumber(3)
  $core.bool get confirmed => $_getBF(2);
  @$pb.TagNumber(3)
  set confirmed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConfirmed() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfirmed() => $_clearField(3);
}

enum EvalResponse_Event { print, result, error, done, notSet }

/// EvalResponse is one event of an Eval stream.
class EvalResponse extends $pb.GeneratedMessage {
  factory EvalResponse({
    PrintLine? print,
    ResultItem? result,
    ShellError? error,
    EvalDone? done,
  }) {
    final result$ = create();
    if (print != null) result$.print = print;
    if (result != null) result$.result = result;
    if (error != null) result$.error = error;
    if (done != null) result$.done = done;
    return result$;
  }

  EvalResponse._();

  factory EvalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EvalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, EvalResponse_Event>
      _EvalResponse_EventByTag = {
    1: EvalResponse_Event.print,
    2: EvalResponse_Event.result,
    3: EvalResponse_Event.error,
    4: EvalResponse_Event.done,
    0: EvalResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<PrintLine>(1, _omitFieldNames ? '' : 'print',
        subBuilder: PrintLine.create)
    ..aOM<ResultItem>(2, _omitFieldNames ? '' : 'result',
        subBuilder: ResultItem.create)
    ..aOM<ShellError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: ShellError.create)
    ..aOM<EvalDone>(4, _omitFieldNames ? '' : 'done',
        subBuilder: EvalDone.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalResponse copyWith(void Function(EvalResponse) updates) =>
      super.copyWith((message) => updates(message as EvalResponse))
          as EvalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EvalResponse create() => EvalResponse._();
  @$core.override
  EvalResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EvalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EvalResponse>(create);
  static EvalResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  EvalResponse_Event whichEvent() => _EvalResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// Output of print, printjson or console.log.
  @$pb.TagNumber(1)
  PrintLine get print => $_getN(0);
  @$pb.TagNumber(1)
  set print(PrintLine value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrint() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrint() => $_clearField(1);
  @$pb.TagNumber(1)
  PrintLine ensurePrint() => $_ensure(0);

  /// A value the script produced.
  @$pb.TagNumber(2)
  ResultItem get result => $_getN(1);
  @$pb.TagNumber(2)
  set result(ResultItem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);
  @$pb.TagNumber(2)
  ResultItem ensureResult() => $_ensure(1);

  /// The script failed. This is the last event.
  @$pb.TagNumber(3)
  ShellError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(ShellError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  ShellError ensureError() => $_ensure(2);

  /// The script finished. This is the last event.
  @$pb.TagNumber(4)
  EvalDone get done => $_getN(3);
  @$pb.TagNumber(4)
  set done(EvalDone value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDone() => $_has(3);
  @$pb.TagNumber(4)
  void clearDone() => $_clearField(4);
  @$pb.TagNumber(4)
  EvalDone ensureDone() => $_ensure(3);
}

/// PrintLine is one line of script output.
class PrintLine extends $pb.GeneratedMessage {
  factory PrintLine({
    $core.String? text,
    PrintLevel? level,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (level != null) result.level = level;
    return result;
  }

  PrintLine._();

  factory PrintLine.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrintLine.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrintLine',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aE<PrintLevel>(2, _omitFieldNames ? '' : 'level',
        enumValues: PrintLevel.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrintLine clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrintLine copyWith(void Function(PrintLine) updates) =>
      super.copyWith((message) => updates(message as PrintLine)) as PrintLine;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrintLine create() => PrintLine._();
  @$core.override
  PrintLine createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrintLine getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PrintLine>(create);
  static PrintLine? _defaultInstance;

  /// Output text, without the trailing newline.
  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  /// Console method.
  @$pb.TagNumber(2)
  PrintLevel get level => $_getN(1);
  @$pb.TagNumber(2)
  set level(PrintLevel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => $_clearField(2);
}

enum ResultItem_Value { scalar, document, write, cursor, notSet }

/// ResultItem is a value produced by the script.
class ResultItem extends $pb.GeneratedMessage {
  factory ResultItem({
    $core.String? scalar,
    $core.String? document,
    WriteResult? write,
    CursorHandle? cursor,
  }) {
    final result = create();
    if (scalar != null) result.scalar = scalar;
    if (document != null) result.document = document;
    if (write != null) result.write = write;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  ResultItem._();

  factory ResultItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResultItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ResultItem_Value> _ResultItem_ValueByTag = {
    1: ResultItem_Value.scalar,
    2: ResultItem_Value.document,
    3: ResultItem_Value.write,
    4: ResultItem_Value.cursor,
    0: ResultItem_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResultItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'scalar')
    ..aOS(2, _omitFieldNames ? '' : 'document')
    ..aOM<WriteResult>(3, _omitFieldNames ? '' : 'write',
        subBuilder: WriteResult.create)
    ..aOM<CursorHandle>(4, _omitFieldNames ? '' : 'cursor',
        subBuilder: CursorHandle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultItem copyWith(void Function(ResultItem) updates) =>
      super.copyWith((message) => updates(message as ResultItem)) as ResultItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResultItem create() => ResultItem._();
  @$core.override
  ResultItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResultItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResultItem>(create);
  static ResultItem? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  ResultItem_Value whichValue() => _ResultItem_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearValue() => $_clearField($_whichOneof(0));

  /// A scalar as EJSON text, e.g. `5` or `"abc"`.
  @$pb.TagNumber(1)
  $core.String get scalar => $_getSZ(0);
  @$pb.TagNumber(1)
  set scalar($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasScalar() => $_has(0);
  @$pb.TagNumber(1)
  void clearScalar() => $_clearField(1);

  /// One document as canonical EJSON.
  @$pb.TagNumber(2)
  $core.String get document => $_getSZ(1);
  @$pb.TagNumber(2)
  set document($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDocument() => $_has(1);
  @$pb.TagNumber(2)
  void clearDocument() => $_clearField(2);

  /// The outcome of a write operation.
  @$pb.TagNumber(3)
  WriteResult get write => $_getN(2);
  @$pb.TagNumber(3)
  set write(WriteResult value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasWrite() => $_has(2);
  @$pb.TagNumber(3)
  void clearWrite() => $_clearField(3);
  @$pb.TagNumber(3)
  WriteResult ensureWrite() => $_ensure(2);

  /// A cursor the script did not consume.
  @$pb.TagNumber(4)
  CursorHandle get cursor => $_getN(3);
  @$pb.TagNumber(4)
  set cursor(CursorHandle value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearCursor() => $_clearField(4);
  @$pb.TagNumber(4)
  CursorHandle ensureCursor() => $_ensure(3);
}

/// WriteResult is a mongosh-shaped write outcome.
class WriteResult extends $pb.GeneratedMessage {
  factory WriteResult({
    $core.String? operation,
    $core.String? result,
  }) {
    final result$ = create();
    if (operation != null) result$.operation = operation;
    if (result != null) result$.result = result;
    return result$;
  }

  WriteResult._();

  factory WriteResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operation')
    ..aOS(2, _omitFieldNames ? '' : 'result')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteResult copyWith(void Function(WriteResult) updates) =>
      super.copyWith((message) => updates(message as WriteResult))
          as WriteResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteResult create() => WriteResult._();
  @$core.override
  WriteResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteResult>(create);
  static WriteResult? _defaultInstance;

  /// Operation name, e.g. "insertOne" or "updateMany".
  @$pb.TagNumber(1)
  $core.String get operation => $_getSZ(0);
  @$pb.TagNumber(1)
  set operation($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperation() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperation() => $_clearField(1);

  /// The result object as canonical EJSON, with the fields mongosh prints
  /// (acknowledged, insertedId, insertedIds, matchedCount, modifiedCount,
  /// deletedCount, upsertedId, upsertedCount).
  @$pb.TagNumber(2)
  $core.String get result => $_getSZ(1);
  @$pb.TagNumber(2)
  set result($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);
}

/// CursorHandle is a replayable query, not a server-held cursor. It stays valid
/// until the shell is closed.
class CursorHandle extends $pb.GeneratedMessage {
  factory CursorHandle({
    $core.String? cursorId,
    CursorKind? kind,
    $core.String? database,
    $core.String? collection,
    $core.String? filter,
    $core.String? sort,
    $core.String? projection,
    $fixnum.Int64? skip,
    $fixnum.Int64? limit,
    $core.String? pipeline,
  }) {
    final result = create();
    if (cursorId != null) result.cursorId = cursorId;
    if (kind != null) result.kind = kind;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (filter != null) result.filter = filter;
    if (sort != null) result.sort = sort;
    if (projection != null) result.projection = projection;
    if (skip != null) result.skip = skip;
    if (limit != null) result.limit = limit;
    if (pipeline != null) result.pipeline = pipeline;
    return result;
  }

  CursorHandle._();

  factory CursorHandle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CursorHandle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CursorHandle',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cursorId')
    ..aE<CursorKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: CursorKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'database')
    ..aOS(4, _omitFieldNames ? '' : 'collection')
    ..aOS(5, _omitFieldNames ? '' : 'filter')
    ..aOS(6, _omitFieldNames ? '' : 'sort')
    ..aOS(7, _omitFieldNames ? '' : 'projection')
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'skip', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'pipeline')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CursorHandle clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CursorHandle copyWith(void Function(CursorHandle) updates) =>
      super.copyWith((message) => updates(message as CursorHandle))
          as CursorHandle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CursorHandle create() => CursorHandle._();
  @$core.override
  CursorHandle createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CursorHandle getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CursorHandle>(create);
  static CursorHandle? _defaultInstance;

  /// Id to pass to FetchCursor.
  @$pb.TagNumber(1)
  $core.String get cursorId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cursorId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursorId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursorId() => $_clearField(1);

  /// Kind of query.
  @$pb.TagNumber(2)
  CursorKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(CursorKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Database name.
  @$pb.TagNumber(3)
  $core.String get database => $_getSZ(2);
  @$pb.TagNumber(3)
  set database($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDatabase() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatabase() => $_clearField(3);

  /// Collection or view name.
  @$pb.TagNumber(4)
  $core.String get collection => $_getSZ(3);
  @$pb.TagNumber(4)
  set collection($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCollection() => $_has(3);
  @$pb.TagNumber(4)
  void clearCollection() => $_clearField(4);

  /// For FIND: filter as EJSON text.
  @$pb.TagNumber(5)
  $core.String get filter => $_getSZ(4);
  @$pb.TagNumber(5)
  set filter($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearFilter() => $_clearField(5);

  /// For FIND: sort as EJSON text.
  @$pb.TagNumber(6)
  $core.String get sort => $_getSZ(5);
  @$pb.TagNumber(6)
  set sort($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSort() => $_has(5);
  @$pb.TagNumber(6)
  void clearSort() => $_clearField(6);

  /// For FIND: projection as EJSON text.
  @$pb.TagNumber(7)
  $core.String get projection => $_getSZ(6);
  @$pb.TagNumber(7)
  set projection($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProjection() => $_has(6);
  @$pb.TagNumber(7)
  void clearProjection() => $_clearField(7);

  /// For FIND: documents skipped by the script.
  @$pb.TagNumber(8)
  $fixnum.Int64 get skip => $_getI64(7);
  @$pb.TagNumber(8)
  set skip($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSkip() => $_has(7);
  @$pb.TagNumber(8)
  void clearSkip() => $_clearField(8);

  /// For FIND: limit set by the script. 0 means none.
  @$pb.TagNumber(9)
  $fixnum.Int64 get limit => $_getI64(8);
  @$pb.TagNumber(9)
  set limit($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLimit() => $_has(8);
  @$pb.TagNumber(9)
  void clearLimit() => $_clearField(9);

  /// For AGGREGATE: the pipeline as an EJSON array.
  @$pb.TagNumber(10)
  $core.String get pipeline => $_getSZ(9);
  @$pb.TagNumber(10)
  set pipeline($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPipeline() => $_has(9);
  @$pb.TagNumber(10)
  void clearPipeline() => $_clearField(10);
}

/// ShellError is a typed script failure. The message never contains secrets.
class ShellError extends $pb.GeneratedMessage {
  factory ShellError({
    ShellErrorKind? kind,
    $core.String? message,
    $core.String? jsStack,
    $core.int? line,
    $core.int? column,
    $core.String? operation,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (jsStack != null) result.jsStack = jsStack;
    if (line != null) result.line = line;
    if (column != null) result.column = column;
    if (operation != null) result.operation = operation;
    return result;
  }

  ShellError._();

  factory ShellError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShellError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<ShellErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: ShellErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'jsStack')
    ..aI(4, _omitFieldNames ? '' : 'line', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'column', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'operation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellError copyWith(void Function(ShellError) updates) =>
      super.copyWith((message) => updates(message as ShellError)) as ShellError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShellError create() => ShellError._();
  @$core.override
  ShellError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShellError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShellError>(create);
  static ShellError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  ShellErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(ShellErrorKind value) => $_setField(1, value);
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

  /// JavaScript stack trace, if any.
  @$pb.TagNumber(3)
  $core.String get jsStack => $_getSZ(2);
  @$pb.TagNumber(3)
  set jsStack($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasJsStack() => $_has(2);
  @$pb.TagNumber(3)
  void clearJsStack() => $_clearField(3);

  /// Line of the failure inside the submitted code, starting at 1. 0 if
  /// unknown.
  @$pb.TagNumber(4)
  $core.int get line => $_getIZ(3);
  @$pb.TagNumber(4)
  set line($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLine() => $_has(3);
  @$pb.TagNumber(4)
  void clearLine() => $_clearField(4);

  /// Column of the failure, starting at 1, in UTF-16 code units. 0 if unknown.
  @$pb.TagNumber(5)
  $core.int get column => $_getIZ(4);
  @$pb.TagNumber(5)
  set column($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasColumn() => $_has(4);
  @$pb.TagNumber(5)
  void clearColumn() => $_clearField(5);

  /// For CONFIRMATION_REQUIRED: the operation to confirm, e.g.
  /// "deleteMany({}) on shop.orders".
  @$pb.TagNumber(6)
  $core.String get operation => $_getSZ(5);
  @$pb.TagNumber(6)
  set operation($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOperation() => $_has(5);
  @$pb.TagNumber(6)
  void clearOperation() => $_clearField(6);
}

/// EvalDone ends a successful Eval.
class EvalDone extends $pb.GeneratedMessage {
  factory EvalDone({
    $1.Duration? duration,
  }) {
    final result = create();
    if (duration != null) result.duration = duration;
    return result;
  }

  EvalDone._();

  factory EvalDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EvalDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvalDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.Duration>(1, _omitFieldNames ? '' : 'duration',
        subBuilder: $1.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvalDone copyWith(void Function(EvalDone) updates) =>
      super.copyWith((message) => updates(message as EvalDone)) as EvalDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EvalDone create() => EvalDone._();
  @$core.override
  EvalDone createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EvalDone getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EvalDone>(create);
  static EvalDone? _defaultInstance;

  /// Time the script ran.
  @$pb.TagNumber(1)
  $1.Duration get duration => $_getN(0);
  @$pb.TagNumber(1)
  set duration($1.Duration value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDuration() => $_has(0);
  @$pb.TagNumber(1)
  void clearDuration() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Duration ensureDuration() => $_ensure(0);
}

/// FetchCursorResponse is one page chunk of a cursor.
class FetchCursorResponse extends $pb.GeneratedMessage {
  factory FetchCursorResponse({
    $2.DocumentBatch? batch,
  }) {
    final result = create();
    if (batch != null) result.batch = batch;
    return result;
  }

  FetchCursorResponse._();

  factory FetchCursorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchCursorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchCursorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$2.DocumentBatch>(1, _omitFieldNames ? '' : 'batch',
        subBuilder: $2.DocumentBatch.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchCursorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchCursorResponse copyWith(void Function(FetchCursorResponse) updates) =>
      super.copyWith((message) => updates(message as FetchCursorResponse))
          as FetchCursorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchCursorResponse create() => FetchCursorResponse._();
  @$core.override
  FetchCursorResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchCursorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchCursorResponse>(create);
  static FetchCursorResponse? _defaultInstance;

  /// Documents of this chunk, as in Find.
  @$pb.TagNumber(1)
  $2.DocumentBatch get batch => $_getN(0);
  @$pb.TagNumber(1)
  set batch($2.DocumentBatch value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBatch() => $_has(0);
  @$pb.TagNumber(1)
  void clearBatch() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.DocumentBatch ensureBatch() => $_ensure(0);
}

/// FetchCursorRequest names a page of a cursor handle.
class FetchCursorRequest extends $pb.GeneratedMessage {
  factory FetchCursorRequest({
    $core.String? shellId,
    $core.String? cursorId,
    $fixnum.Int64? skip,
    $core.int? limit,
  }) {
    final result = create();
    if (shellId != null) result.shellId = shellId;
    if (cursorId != null) result.cursorId = cursorId;
    if (skip != null) result.skip = skip;
    if (limit != null) result.limit = limit;
    return result;
  }

  FetchCursorRequest._();

  factory FetchCursorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchCursorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchCursorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shellId')
    ..aOS(2, _omitFieldNames ? '' : 'cursorId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'skip', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchCursorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchCursorRequest copyWith(void Function(FetchCursorRequest) updates) =>
      super.copyWith((message) => updates(message as FetchCursorRequest))
          as FetchCursorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchCursorRequest create() => FetchCursorRequest._();
  @$core.override
  FetchCursorRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchCursorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchCursorRequest>(create);
  static FetchCursorRequest? _defaultInstance;

  /// Shell id from OpenShell.
  @$pb.TagNumber(1)
  $core.String get shellId => $_getSZ(0);
  @$pb.TagNumber(1)
  set shellId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShellId() => $_has(0);
  @$pb.TagNumber(1)
  void clearShellId() => $_clearField(1);

  /// Cursor id from a CursorHandle.
  @$pb.TagNumber(2)
  $core.String get cursorId => $_getSZ(1);
  @$pb.TagNumber(2)
  set cursorId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCursorId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCursorId() => $_clearField(2);

  /// Documents to skip, added to the handle's own skip.
  @$pb.TagNumber(3)
  $fixnum.Int64 get skip => $_getI64(2);
  @$pb.TagNumber(3)
  set skip($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSkip() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkip() => $_clearField(3);

  /// Maximum documents to return. 0 means the default of 50.
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

/// ShellServiceCancelRequest names the shell to interrupt.
class ShellServiceCancelRequest extends $pb.GeneratedMessage {
  factory ShellServiceCancelRequest({
    $core.String? shellId,
  }) {
    final result = create();
    if (shellId != null) result.shellId = shellId;
    return result;
  }

  ShellServiceCancelRequest._();

  factory ShellServiceCancelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShellServiceCancelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellServiceCancelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shellId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellServiceCancelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellServiceCancelRequest copyWith(
          void Function(ShellServiceCancelRequest) updates) =>
      super.copyWith((message) => updates(message as ShellServiceCancelRequest))
          as ShellServiceCancelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShellServiceCancelRequest create() => ShellServiceCancelRequest._();
  @$core.override
  ShellServiceCancelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShellServiceCancelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShellServiceCancelRequest>(create);
  static ShellServiceCancelRequest? _defaultInstance;

  /// Shell id from OpenShell.
  @$pb.TagNumber(1)
  $core.String get shellId => $_getSZ(0);
  @$pb.TagNumber(1)
  set shellId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShellId() => $_has(0);
  @$pb.TagNumber(1)
  void clearShellId() => $_clearField(1);
}

/// ShellServiceCancelResponse is empty.
class ShellServiceCancelResponse extends $pb.GeneratedMessage {
  factory ShellServiceCancelResponse() => create();

  ShellServiceCancelResponse._();

  factory ShellServiceCancelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShellServiceCancelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellServiceCancelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellServiceCancelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellServiceCancelResponse copyWith(
          void Function(ShellServiceCancelResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ShellServiceCancelResponse))
          as ShellServiceCancelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShellServiceCancelResponse create() => ShellServiceCancelResponse._();
  @$core.override
  ShellServiceCancelResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShellServiceCancelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShellServiceCancelResponse>(create);
  static ShellServiceCancelResponse? _defaultInstance;
}

/// CloseShellRequest names the shell to close.
class CloseShellRequest extends $pb.GeneratedMessage {
  factory CloseShellRequest({
    $core.String? shellId,
  }) {
    final result = create();
    if (shellId != null) result.shellId = shellId;
    return result;
  }

  CloseShellRequest._();

  factory CloseShellRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseShellRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseShellRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shellId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseShellRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseShellRequest copyWith(void Function(CloseShellRequest) updates) =>
      super.copyWith((message) => updates(message as CloseShellRequest))
          as CloseShellRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseShellRequest create() => CloseShellRequest._();
  @$core.override
  CloseShellRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseShellRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseShellRequest>(create);
  static CloseShellRequest? _defaultInstance;

  /// Shell id from OpenShell.
  @$pb.TagNumber(1)
  $core.String get shellId => $_getSZ(0);
  @$pb.TagNumber(1)
  set shellId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShellId() => $_has(0);
  @$pb.TagNumber(1)
  void clearShellId() => $_clearField(1);
}

/// CloseShellResponse is empty.
class CloseShellResponse extends $pb.GeneratedMessage {
  factory CloseShellResponse() => create();

  CloseShellResponse._();

  factory CloseShellResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseShellResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseShellResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseShellResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseShellResponse copyWith(void Function(CloseShellResponse) updates) =>
      super.copyWith((message) => updates(message as CloseShellResponse))
          as CloseShellResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseShellResponse create() => CloseShellResponse._();
  @$core.override
  CloseShellResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseShellResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseShellResponse>(create);
  static CloseShellResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
