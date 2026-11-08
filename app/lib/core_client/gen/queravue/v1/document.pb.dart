// This is a generated file - do not edit.
//
// Generated from queravue/v1/document.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'document.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'document.pbenum.dart';

/// DocumentError is a typed failure. The message never contains secrets.
class DocumentError extends $pb.GeneratedMessage {
  factory DocumentError({
    DocumentErrorKind? kind,
    $core.String? message,
    DocumentInput? input,
    $core.int? position,
    $core.int? documentIndex,
    $core.String? currentDocument,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    if (input != null) result.input = input;
    if (position != null) result.position = position;
    if (documentIndex != null) result.documentIndex = documentIndex;
    if (currentDocument != null) result.currentDocument = currentDocument;
    return result;
  }

  DocumentError._();

  factory DocumentError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DocumentError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DocumentError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<DocumentErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: DocumentErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aE<DocumentInput>(3, _omitFieldNames ? '' : 'input',
        enumValues: DocumentInput.values)
    ..aI(4, _omitFieldNames ? '' : 'position', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'documentIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'currentDocument')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentError copyWith(void Function(DocumentError) updates) =>
      super.copyWith((message) => updates(message as DocumentError))
          as DocumentError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DocumentError create() => DocumentError._();
  @$core.override
  DocumentError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DocumentError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DocumentError>(create);
  static DocumentError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  DocumentErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(DocumentErrorKind value) => $_setField(1, value);
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

  /// For PARSE: the input that failed.
  @$pb.TagNumber(3)
  DocumentInput get input => $_getN(2);
  @$pb.TagNumber(3)
  set input(DocumentInput value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInput() => $_has(2);
  @$pb.TagNumber(3)
  void clearInput() => $_clearField(3);

  /// For PARSE: offset of the error inside that input, in UTF-16 code units.
  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);

  /// For PARSE in a multi-document request: index of the failing document.
  @$pb.TagNumber(5)
  $core.int get documentIndex => $_getIZ(4);
  @$pb.TagNumber(5)
  set documentIndex($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDocumentIndex() => $_has(4);
  @$pb.TagNumber(5)
  void clearDocumentIndex() => $_clearField(5);

  /// For CONFLICT: the stored canonical EJSON document. Unset if deleted.
  @$pb.TagNumber(6)
  $core.String get currentDocument => $_getSZ(5);
  @$pb.TagNumber(6)
  set currentDocument($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrentDocument() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrentDocument() => $_clearField(6);
}

/// FindRequest is the input of Find.
class FindRequest extends $pb.GeneratedMessage {
  factory FindRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.String? filter,
    $core.String? sort,
    $core.String? projection,
    $fixnum.Int64? skip,
    $fixnum.Int64? limit,
    $core.int? batchSize,
    $core.int? maxTimeMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (filter != null) result.filter = filter;
    if (sort != null) result.sort = sort;
    if (projection != null) result.projection = projection;
    if (skip != null) result.skip = skip;
    if (limit != null) result.limit = limit;
    if (batchSize != null) result.batchSize = batchSize;
    if (maxTimeMs != null) result.maxTimeMs = maxTimeMs;
    return result;
  }

  FindRequest._();

  factory FindRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FindRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FindRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aOS(4, _omitFieldNames ? '' : 'filter')
    ..aOS(5, _omitFieldNames ? '' : 'sort')
    ..aOS(6, _omitFieldNames ? '' : 'projection')
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'skip', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(9, _omitFieldNames ? '' : 'batchSize', fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'maxTimeMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindRequest copyWith(void Function(FindRequest) updates) =>
      super.copyWith((message) => updates(message as FindRequest))
          as FindRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FindRequest create() => FindRequest._();
  @$core.override
  FindRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FindRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FindRequest>(create);
  static FindRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection or view name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Filter as EJSON text. Empty means {}.
  @$pb.TagNumber(4)
  $core.String get filter => $_getSZ(3);
  @$pb.TagNumber(4)
  set filter($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilter() => $_clearField(4);

  /// Sort as EJSON text, e.g. {"name": 1}. Empty means natural order.
  @$pb.TagNumber(5)
  $core.String get sort => $_getSZ(4);
  @$pb.TagNumber(5)
  set sort($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSort() => $_has(4);
  @$pb.TagNumber(5)
  void clearSort() => $_clearField(5);

  /// Projection as EJSON text. Empty means all fields.
  @$pb.TagNumber(6)
  $core.String get projection => $_getSZ(5);
  @$pb.TagNumber(6)
  set projection($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProjection() => $_has(5);
  @$pb.TagNumber(6)
  void clearProjection() => $_clearField(6);

  /// Documents to skip.
  @$pb.TagNumber(7)
  $fixnum.Int64 get skip => $_getI64(6);
  @$pb.TagNumber(7)
  set skip($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSkip() => $_has(6);
  @$pb.TagNumber(7)
  void clearSkip() => $_clearField(7);

  /// Maximum documents to return. 0 means no limit.
  @$pb.TagNumber(8)
  $fixnum.Int64 get limit => $_getI64(7);
  @$pb.TagNumber(8)
  set limit($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearLimit() => $_clearField(8);

  /// Documents per batch. 0 means 500; the core clamps it to [1, 5000].
  @$pb.TagNumber(9)
  $core.int get batchSize => $_getIZ(8);
  @$pb.TagNumber(9)
  set batchSize($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBatchSize() => $_has(8);
  @$pb.TagNumber(9)
  void clearBatchSize() => $_clearField(9);

  /// Server-side time limit (maxTimeMS). 0 means the core default (30000).
  @$pb.TagNumber(10)
  $core.int get maxTimeMs => $_getIZ(9);
  @$pb.TagNumber(10)
  set maxTimeMs($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMaxTimeMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearMaxTimeMs() => $_clearField(10);
}

/// DocumentBatch is a group of documents.
class DocumentBatch extends $pb.GeneratedMessage {
  factory DocumentBatch({
    $fixnum.Int64? offset,
    $core.Iterable<$core.String>? documents,
    $core.bool? done,
  }) {
    final result = create();
    if (offset != null) result.offset = offset;
    if (documents != null) result.documents.addAll(documents);
    if (done != null) result.done = done;
    return result;
  }

  DocumentBatch._();

  factory DocumentBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DocumentBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DocumentBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(2, _omitFieldNames ? '' : 'documents')
    ..aOB(3, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DocumentBatch copyWith(void Function(DocumentBatch) updates) =>
      super.copyWith((message) => updates(message as DocumentBatch))
          as DocumentBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DocumentBatch create() => DocumentBatch._();
  @$core.override
  DocumentBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DocumentBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DocumentBatch>(create);
  static DocumentBatch? _defaultInstance;

  /// Index of documents[0] among the documents of this Find, starting at 0.
  @$pb.TagNumber(1)
  $fixnum.Int64 get offset => $_getI64(0);
  @$pb.TagNumber(1)
  set offset($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffset() => $_clearField(1);

  /// Canonical EJSON documents, one per entry. At most batch_size entries and
  /// about 2 MiB, except that a single large document travels alone.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get documents => $_getList(1);

  /// True on the last batch.
  @$pb.TagNumber(3)
  $core.bool get done => $_getBF(2);
  @$pb.TagNumber(3)
  set done($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDone() => $_has(2);
  @$pb.TagNumber(3)
  void clearDone() => $_clearField(3);
}

enum FindResponse_Event { batch, error, notSet }

/// FindResponse is one event of a Find stream.
class FindResponse extends $pb.GeneratedMessage {
  factory FindResponse({
    DocumentBatch? batch,
    DocumentError? error,
  }) {
    final result = create();
    if (batch != null) result.batch = batch;
    if (error != null) result.error = error;
    return result;
  }

  FindResponse._();

  factory FindResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FindResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FindResponse_Event>
      _FindResponse_EventByTag = {
    1: FindResponse_Event.batch,
    2: FindResponse_Event.error,
    0: FindResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FindResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DocumentBatch>(1, _omitFieldNames ? '' : 'batch',
        subBuilder: DocumentBatch.create)
    ..aOM<DocumentError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindResponse copyWith(void Function(FindResponse) updates) =>
      super.copyWith((message) => updates(message as FindResponse))
          as FindResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FindResponse create() => FindResponse._();
  @$core.override
  FindResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FindResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FindResponse>(create);
  static FindResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FindResponse_Event whichEvent() => _FindResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// Next group of documents.
  @$pb.TagNumber(1)
  DocumentBatch get batch => $_getN(0);
  @$pb.TagNumber(1)
  set batch(DocumentBatch value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBatch() => $_has(0);
  @$pb.TagNumber(1)
  void clearBatch() => $_clearField(1);
  @$pb.TagNumber(1)
  DocumentBatch ensureBatch() => $_ensure(0);

  /// The find failed; the stream ends after this event.
  @$pb.TagNumber(2)
  DocumentError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DocumentError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  DocumentError ensureError() => $_ensure(1);
}

/// CountRequest is the input of Count.
class CountRequest extends $pb.GeneratedMessage {
  factory CountRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.String? filter,
    $core.int? maxTimeMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (filter != null) result.filter = filter;
    if (maxTimeMs != null) result.maxTimeMs = maxTimeMs;
    return result;
  }

  CountRequest._();

  factory CountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CountRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aOS(4, _omitFieldNames ? '' : 'filter')
    ..aI(5, _omitFieldNames ? '' : 'maxTimeMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CountRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CountRequest copyWith(void Function(CountRequest) updates) =>
      super.copyWith((message) => updates(message as CountRequest))
          as CountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CountRequest create() => CountRequest._();
  @$core.override
  CountRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CountRequest>(create);
  static CountRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection or view name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Filter as EJSON text. Empty means {} (estimated count).
  @$pb.TagNumber(4)
  $core.String get filter => $_getSZ(3);
  @$pb.TagNumber(4)
  set filter($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFilter() => $_has(3);
  @$pb.TagNumber(4)
  void clearFilter() => $_clearField(4);

  /// Server-side time limit. 0 means the core default (10000).
  @$pb.TagNumber(5)
  $core.int get maxTimeMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxTimeMs($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxTimeMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxTimeMs() => $_clearField(5);
}

/// CountResponse holds the count or the failure.
class CountResponse extends $pb.GeneratedMessage {
  factory CountResponse({
    $fixnum.Int64? count,
    $core.bool? exact,
    DocumentError? error,
  }) {
    final result = create();
    if (count != null) result.count = count;
    if (exact != null) result.exact = exact;
    if (error != null) result.error = error;
    return result;
  }

  CountResponse._();

  factory CountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CountResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(2, _omitFieldNames ? '' : 'exact')
    ..aOM<DocumentError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CountResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CountResponse copyWith(void Function(CountResponse) updates) =>
      super.copyWith((message) => updates(message as CountResponse))
          as CountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CountResponse create() => CountResponse._();
  @$core.override
  CountResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CountResponse>(create);
  static CountResponse? _defaultInstance;

  /// Number of documents.
  @$pb.TagNumber(1)
  $fixnum.Int64 get count => $_getI64(0);
  @$pb.TagNumber(1)
  set count($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);

  /// True if the count is exact, false if estimated from metadata.
  @$pb.TagNumber(2)
  $core.bool get exact => $_getBF(1);
  @$pb.TagNumber(2)
  set exact($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExact() => $_has(1);
  @$pb.TagNumber(2)
  void clearExact() => $_clearField(2);

  /// Set when counting failed; count is then 0.
  @$pb.TagNumber(3)
  DocumentError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(DocumentError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  DocumentError ensureError() => $_ensure(2);
}

/// InsertDocumentsRequest is the input of InsertDocuments.
class InsertDocumentsRequest extends $pb.GeneratedMessage {
  factory InsertDocumentsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.Iterable<$core.String>? documents,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (documents != null) result.documents.addAll(documents);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  InsertDocumentsRequest._();

  factory InsertDocumentsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InsertDocumentsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InsertDocumentsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..pPS(4, _omitFieldNames ? '' : 'documents')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsertDocumentsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsertDocumentsRequest copyWith(
          void Function(InsertDocumentsRequest) updates) =>
      super.copyWith((message) => updates(message as InsertDocumentsRequest))
          as InsertDocumentsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InsertDocumentsRequest create() => InsertDocumentsRequest._();
  @$core.override
  InsertDocumentsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InsertDocumentsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InsertDocumentsRequest>(create);
  static InsertDocumentsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Canonical EJSON documents.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get documents => $_getList(3);

  /// Set after the user confirmed on a production connection.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// InsertDocumentsResponse holds the inserted ids or the failure.
class InsertDocumentsResponse extends $pb.GeneratedMessage {
  factory InsertDocumentsResponse({
    $core.Iterable<$core.String>? insertedIds,
    DocumentError? error,
  }) {
    final result = create();
    if (insertedIds != null) result.insertedIds.addAll(insertedIds);
    if (error != null) result.error = error;
    return result;
  }

  InsertDocumentsResponse._();

  factory InsertDocumentsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InsertDocumentsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InsertDocumentsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'insertedIds')
    ..aOM<DocumentError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsertDocumentsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsertDocumentsResponse copyWith(
          void Function(InsertDocumentsResponse) updates) =>
      super.copyWith((message) => updates(message as InsertDocumentsResponse))
          as InsertDocumentsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InsertDocumentsResponse create() => InsertDocumentsResponse._();
  @$core.override
  InsertDocumentsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InsertDocumentsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InsertDocumentsResponse>(create);
  static InsertDocumentsResponse? _defaultInstance;

  /// Canonical EJSON _id of every inserted document, in request order.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get insertedIds => $_getList(0);

  /// Set when the insert failed; inserted_ids then lists what was written
  /// before the failure.
  @$pb.TagNumber(2)
  DocumentError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DocumentError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  DocumentError ensureError() => $_ensure(1);
}

/// ReplaceDocumentRequest is the input of ReplaceDocument.
class ReplaceDocumentRequest extends $pb.GeneratedMessage {
  factory ReplaceDocumentRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.String? id,
    $core.String? document,
    $core.String? expectedDocument,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (id != null) result.id = id;
    if (document != null) result.document = document;
    if (expectedDocument != null) result.expectedDocument = expectedDocument;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  ReplaceDocumentRequest._();

  factory ReplaceDocumentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplaceDocumentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplaceDocumentRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aOS(4, _omitFieldNames ? '' : 'id')
    ..aOS(5, _omitFieldNames ? '' : 'document')
    ..aOS(6, _omitFieldNames ? '' : 'expectedDocument')
    ..aOB(7, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplaceDocumentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplaceDocumentRequest copyWith(
          void Function(ReplaceDocumentRequest) updates) =>
      super.copyWith((message) => updates(message as ReplaceDocumentRequest))
          as ReplaceDocumentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplaceDocumentRequest create() => ReplaceDocumentRequest._();
  @$core.override
  ReplaceDocumentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplaceDocumentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceDocumentRequest>(create);
  static ReplaceDocumentRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Canonical EJSON value of the _id to replace.
  @$pb.TagNumber(4)
  $core.String get id => $_getSZ(3);
  @$pb.TagNumber(4)
  set id($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasId() => $_has(3);
  @$pb.TagNumber(4)
  void clearId() => $_clearField(4);

  /// Canonical EJSON replacement document. Its _id, if present, must equal id.
  @$pb.TagNumber(5)
  $core.String get document => $_getSZ(4);
  @$pb.TagNumber(5)
  set document($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDocument() => $_has(4);
  @$pb.TagNumber(5)
  void clearDocument() => $_clearField(5);

  /// Document as the editor loaded it. If set, the write is rejected with
  /// CONFLICT when the stored document differs. Unset overwrites.
  @$pb.TagNumber(6)
  $core.String get expectedDocument => $_getSZ(5);
  @$pb.TagNumber(6)
  set expectedDocument($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExpectedDocument() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpectedDocument() => $_clearField(6);

  /// Set after the user confirmed on a production connection.
  @$pb.TagNumber(7)
  $core.bool get confirmed => $_getBF(6);
  @$pb.TagNumber(7)
  set confirmed($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfirmed() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfirmed() => $_clearField(7);
}

/// ReplaceDocumentResponse holds the stored document or the failure.
class ReplaceDocumentResponse extends $pb.GeneratedMessage {
  factory ReplaceDocumentResponse({
    $core.String? document,
    DocumentError? error,
  }) {
    final result = create();
    if (document != null) result.document = document;
    if (error != null) result.error = error;
    return result;
  }

  ReplaceDocumentResponse._();

  factory ReplaceDocumentResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplaceDocumentResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplaceDocumentResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'document')
    ..aOM<DocumentError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplaceDocumentResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplaceDocumentResponse copyWith(
          void Function(ReplaceDocumentResponse) updates) =>
      super.copyWith((message) => updates(message as ReplaceDocumentResponse))
          as ReplaceDocumentResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplaceDocumentResponse create() => ReplaceDocumentResponse._();
  @$core.override
  ReplaceDocumentResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplaceDocumentResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceDocumentResponse>(create);
  static ReplaceDocumentResponse? _defaultInstance;

  /// Canonical EJSON of the document as stored.
  @$pb.TagNumber(1)
  $core.String get document => $_getSZ(0);
  @$pb.TagNumber(1)
  set document($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDocument() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocument() => $_clearField(1);

  /// Set when the replace failed.
  @$pb.TagNumber(2)
  DocumentError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DocumentError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  DocumentError ensureError() => $_ensure(1);
}

/// UpdateFieldsRequest is the input of UpdateFields.
class UpdateFieldsRequest extends $pb.GeneratedMessage {
  factory UpdateFieldsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.String? id,
    $core.String? set,
    $core.Iterable<$core.String>? unset,
    $core.String? expectedDocument,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (id != null) result.id = id;
    if (set != null) result.set = set;
    if (unset != null) result.unset.addAll(unset);
    if (expectedDocument != null) result.expectedDocument = expectedDocument;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  UpdateFieldsRequest._();

  factory UpdateFieldsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateFieldsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateFieldsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aOS(4, _omitFieldNames ? '' : 'id')
    ..aOS(5, _omitFieldNames ? '' : 'set')
    ..pPS(6, _omitFieldNames ? '' : 'unset')
    ..aOS(7, _omitFieldNames ? '' : 'expectedDocument')
    ..aOB(8, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateFieldsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateFieldsRequest copyWith(void Function(UpdateFieldsRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateFieldsRequest))
          as UpdateFieldsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateFieldsRequest create() => UpdateFieldsRequest._();
  @$core.override
  UpdateFieldsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateFieldsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateFieldsRequest>(create);
  static UpdateFieldsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Canonical EJSON value of the _id to update.
  @$pb.TagNumber(4)
  $core.String get id => $_getSZ(3);
  @$pb.TagNumber(4)
  set id($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasId() => $_has(3);
  @$pb.TagNumber(4)
  void clearId() => $_clearField(4);

  /// Canonical EJSON object of fields to $set; keys may be dotted paths.
  @$pb.TagNumber(5)
  $core.String get set => $_getSZ(4);
  @$pb.TagNumber(5)
  set set($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSet() => $_has(4);
  @$pb.TagNumber(5)
  void clearSet() => $_clearField(5);

  /// Field paths to $unset.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get unset => $_getList(5);

  /// Document as the editor loaded it; see ReplaceDocumentRequest.
  @$pb.TagNumber(7)
  $core.String get expectedDocument => $_getSZ(6);
  @$pb.TagNumber(7)
  set expectedDocument($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExpectedDocument() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpectedDocument() => $_clearField(7);

  /// Set after the user confirmed on a production connection.
  @$pb.TagNumber(8)
  $core.bool get confirmed => $_getBF(7);
  @$pb.TagNumber(8)
  set confirmed($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConfirmed() => $_has(7);
  @$pb.TagNumber(8)
  void clearConfirmed() => $_clearField(8);
}

/// UpdateFieldsResponse holds the stored document or the failure.
class UpdateFieldsResponse extends $pb.GeneratedMessage {
  factory UpdateFieldsResponse({
    $core.String? document,
    DocumentError? error,
  }) {
    final result = create();
    if (document != null) result.document = document;
    if (error != null) result.error = error;
    return result;
  }

  UpdateFieldsResponse._();

  factory UpdateFieldsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateFieldsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateFieldsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'document')
    ..aOM<DocumentError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateFieldsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateFieldsResponse copyWith(void Function(UpdateFieldsResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateFieldsResponse))
          as UpdateFieldsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateFieldsResponse create() => UpdateFieldsResponse._();
  @$core.override
  UpdateFieldsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateFieldsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateFieldsResponse>(create);
  static UpdateFieldsResponse? _defaultInstance;

  /// Canonical EJSON of the document after the update.
  @$pb.TagNumber(1)
  $core.String get document => $_getSZ(0);
  @$pb.TagNumber(1)
  set document($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDocument() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocument() => $_clearField(1);

  /// Set when the update failed.
  @$pb.TagNumber(2)
  DocumentError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DocumentError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  DocumentError ensureError() => $_ensure(1);
}

/// DeleteDocumentsRequest is the input of DeleteDocuments.
class DeleteDocumentsRequest extends $pb.GeneratedMessage {
  factory DeleteDocumentsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.Iterable<$core.String>? ids,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (ids != null) result.ids.addAll(ids);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  DeleteDocumentsRequest._();

  factory DeleteDocumentsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteDocumentsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteDocumentsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..pPS(4, _omitFieldNames ? '' : 'ids')
    ..aOB(5, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDocumentsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDocumentsRequest copyWith(
          void Function(DeleteDocumentsRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteDocumentsRequest))
          as DeleteDocumentsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteDocumentsRequest create() => DeleteDocumentsRequest._();
  @$core.override
  DeleteDocumentsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteDocumentsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteDocumentsRequest>(create);
  static DeleteDocumentsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Canonical EJSON _id values.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get ids => $_getList(3);

  /// Must be true on production connections, else CONFIRMATION_REQUIRED.
  @$pb.TagNumber(5)
  $core.bool get confirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set confirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfirmed() => $_clearField(5);
}

/// DeleteDocumentsResponse holds the delete count or the failure.
class DeleteDocumentsResponse extends $pb.GeneratedMessage {
  factory DeleteDocumentsResponse({
    $fixnum.Int64? deletedCount,
    DocumentError? error,
  }) {
    final result = create();
    if (deletedCount != null) result.deletedCount = deletedCount;
    if (error != null) result.error = error;
    return result;
  }

  DeleteDocumentsResponse._();

  factory DeleteDocumentsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteDocumentsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteDocumentsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'deletedCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<DocumentError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDocumentsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteDocumentsResponse copyWith(
          void Function(DeleteDocumentsResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteDocumentsResponse))
          as DeleteDocumentsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteDocumentsResponse create() => DeleteDocumentsResponse._();
  @$core.override
  DeleteDocumentsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteDocumentsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteDocumentsResponse>(create);
  static DeleteDocumentsResponse? _defaultInstance;

  /// Documents deleted.
  @$pb.TagNumber(1)
  $fixnum.Int64 get deletedCount => $_getI64(0);
  @$pb.TagNumber(1)
  set deletedCount($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeletedCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeletedCount() => $_clearField(1);

  /// Set when the delete failed or needs confirmation.
  @$pb.TagNumber(2)
  DocumentError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DocumentError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  DocumentError ensureError() => $_ensure(1);
}

/// SampleFieldsRequest is the input of SampleFields.
class SampleFieldsRequest extends $pb.GeneratedMessage {
  factory SampleFieldsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.int? sampleSize,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (sampleSize != null) result.sampleSize = sampleSize;
    return result;
  }

  SampleFieldsRequest._();

  factory SampleFieldsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SampleFieldsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SampleFieldsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aI(4, _omitFieldNames ? '' : 'sampleSize', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldsRequest copyWith(void Function(SampleFieldsRequest) updates) =>
      super.copyWith((message) => updates(message as SampleFieldsRequest))
          as SampleFieldsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SampleFieldsRequest create() => SampleFieldsRequest._();
  @$core.override
  SampleFieldsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SampleFieldsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SampleFieldsRequest>(create);
  static SampleFieldsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection or view name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Documents to sample. 0 means 100; the core clamps it to [1, 1000].
  @$pb.TagNumber(4)
  $core.int get sampleSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set sampleSize($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSampleSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSampleSize() => $_clearField(4);
}

/// TypeCount says how many sampled documents held a BSON type in a field.
class TypeCount extends $pb.GeneratedMessage {
  factory TypeCount({
    $core.String? type,
    $core.int? count,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (count != null) result.count = count;
    return result;
  }

  TypeCount._();

  factory TypeCount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TypeCount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypeCount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aI(2, _omitFieldNames ? '' : 'count', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypeCount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypeCount copyWith(void Function(TypeCount) updates) =>
      super.copyWith((message) => updates(message as TypeCount)) as TypeCount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TypeCount create() => TypeCount._();
  @$core.override
  TypeCount createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TypeCount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypeCount>(create);
  static TypeCount? _defaultInstance;

  /// BSON type alias as used by $type, e.g. "int", "long", "string", "date".
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// Number of sampled documents with this type for the field.
  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

/// FieldStat describes one top-level field in the sample.
class FieldStat extends $pb.GeneratedMessage {
  factory FieldStat({
    $core.String? name,
    $core.Iterable<TypeCount>? types,
    $core.double? frequency,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (types != null) result.types.addAll(types);
    if (frequency != null) result.frequency = frequency;
    return result;
  }

  FieldStat._();

  factory FieldStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FieldStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FieldStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPM<TypeCount>(2, _omitFieldNames ? '' : 'types',
        subBuilder: TypeCount.create)
    ..aD(3, _omitFieldNames ? '' : 'frequency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldStat copyWith(void Function(FieldStat) updates) =>
      super.copyWith((message) => updates(message as FieldStat)) as FieldStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldStat create() => FieldStat._();
  @$core.override
  FieldStat createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FieldStat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldStat>(create);
  static FieldStat? _defaultInstance;

  /// Field name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Types seen, most frequent first.
  @$pb.TagNumber(2)
  $pb.PbList<TypeCount> get types => $_getList(1);

  /// Share of sampled documents that have the field, in [0, 1].
  @$pb.TagNumber(3)
  $core.double get frequency => $_getN(2);
  @$pb.TagNumber(3)
  set frequency($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFrequency() => $_has(2);
  @$pb.TagNumber(3)
  void clearFrequency() => $_clearField(3);
}

/// SampleFieldsResponse holds the sampled fields or the failure.
class SampleFieldsResponse extends $pb.GeneratedMessage {
  factory SampleFieldsResponse({
    $core.Iterable<FieldStat>? fields,
    $core.int? sampled,
    $core.bool? usedFallback,
    DocumentError? error,
  }) {
    final result = create();
    if (fields != null) result.fields.addAll(fields);
    if (sampled != null) result.sampled = sampled;
    if (usedFallback != null) result.usedFallback = usedFallback;
    if (error != null) result.error = error;
    return result;
  }

  SampleFieldsResponse._();

  factory SampleFieldsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SampleFieldsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SampleFieldsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<FieldStat>(1, _omitFieldNames ? '' : 'fields',
        subBuilder: FieldStat.create)
    ..aI(2, _omitFieldNames ? '' : 'sampled', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'usedFallback')
    ..aOM<DocumentError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldsResponse copyWith(void Function(SampleFieldsResponse) updates) =>
      super.copyWith((message) => updates(message as SampleFieldsResponse))
          as SampleFieldsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SampleFieldsResponse create() => SampleFieldsResponse._();
  @$core.override
  SampleFieldsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SampleFieldsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SampleFieldsResponse>(create);
  static SampleFieldsResponse? _defaultInstance;

  /// Fields ordered by frequency, then name. _id comes first.
  @$pb.TagNumber(1)
  $pb.PbList<FieldStat> get fields => $_getList(0);

  /// Number of documents actually sampled.
  @$pb.TagNumber(2)
  $core.int get sampled => $_getIZ(1);
  @$pb.TagNumber(2)
  set sampled($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSampled() => $_has(1);
  @$pb.TagNumber(2)
  void clearSampled() => $_clearField(2);

  /// True if $sample was unavailable and the first documents were read
  /// instead.
  @$pb.TagNumber(3)
  $core.bool get usedFallback => $_getBF(2);
  @$pb.TagNumber(3)
  set usedFallback($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsedFallback() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsedFallback() => $_clearField(3);

  /// Set when sampling failed.
  @$pb.TagNumber(4)
  DocumentError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(DocumentError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  DocumentError ensureError() => $_ensure(3);
}

/// SampleFieldPathsRequest is the input of SampleFieldPaths.
class SampleFieldPathsRequest extends $pb.GeneratedMessage {
  factory SampleFieldPathsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? collection,
    $core.int? sampleSize,
    $core.int? maxDepth,
    $core.bool? refresh,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    if (sampleSize != null) result.sampleSize = sampleSize;
    if (maxDepth != null) result.maxDepth = maxDepth;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  SampleFieldPathsRequest._();

  factory SampleFieldPathsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SampleFieldPathsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SampleFieldPathsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'collection')
    ..aI(4, _omitFieldNames ? '' : 'sampleSize', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'maxDepth', fieldType: $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldPathsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldPathsRequest copyWith(
          void Function(SampleFieldPathsRequest) updates) =>
      super.copyWith((message) => updates(message as SampleFieldPathsRequest))
          as SampleFieldPathsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SampleFieldPathsRequest create() => SampleFieldPathsRequest._();
  @$core.override
  SampleFieldPathsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SampleFieldPathsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SampleFieldPathsRequest>(create);
  static SampleFieldPathsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Collection or view name.
  @$pb.TagNumber(3)
  $core.String get collection => $_getSZ(2);
  @$pb.TagNumber(3)
  set collection($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearCollection() => $_clearField(3);

  /// Documents to sample. 0 means 100; the core clamps it to [1, 1000].
  @$pb.TagNumber(4)
  $core.int get sampleSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set sampleSize($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSampleSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSampleSize() => $_clearField(4);

  /// Deepest path to report. 0 means 6; the core clamps it to [1, 12].
  @$pb.TagNumber(5)
  $core.int get maxDepth => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxDepth($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxDepth() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxDepth() => $_clearField(5);

  /// Skip the cache and sample again.
  @$pb.TagNumber(6)
  $core.bool get refresh => $_getBF(5);
  @$pb.TagNumber(6)
  set refresh($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRefresh() => $_has(5);
  @$pb.TagNumber(6)
  void clearRefresh() => $_clearField(6);
}

/// FieldPathStat describes one field path in the sample.
class FieldPathStat extends $pb.GeneratedMessage {
  factory FieldPathStat({
    $core.String? path,
    $core.Iterable<TypeCount>? types,
    $core.double? frequency,
    $core.int? depth,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (types != null) result.types.addAll(types);
    if (frequency != null) result.frequency = frequency;
    if (depth != null) result.depth = depth;
    return result;
  }

  FieldPathStat._();

  factory FieldPathStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FieldPathStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FieldPathStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..pPM<TypeCount>(2, _omitFieldNames ? '' : 'types',
        subBuilder: TypeCount.create)
    ..aD(3, _omitFieldNames ? '' : 'frequency')
    ..aI(4, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldPathStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FieldPathStat copyWith(void Function(FieldPathStat) updates) =>
      super.copyWith((message) => updates(message as FieldPathStat))
          as FieldPathStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldPathStat create() => FieldPathStat._();
  @$core.override
  FieldPathStat createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FieldPathStat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FieldPathStat>(create);
  static FieldPathStat? _defaultInstance;

  /// Dotted path; array elements use the segment [].
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// Types seen, most frequent first.
  @$pb.TagNumber(2)
  $pb.PbList<TypeCount> get types => $_getList(1);

  /// Share of sampled documents that have the path, in [0, 1].
  @$pb.TagNumber(3)
  $core.double get frequency => $_getN(2);
  @$pb.TagNumber(3)
  set frequency($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFrequency() => $_has(2);
  @$pb.TagNumber(3)
  void clearFrequency() => $_clearField(3);

  /// Number of segments in the path.
  @$pb.TagNumber(4)
  $core.int get depth => $_getIZ(3);
  @$pb.TagNumber(4)
  set depth($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDepth() => $_has(3);
  @$pb.TagNumber(4)
  void clearDepth() => $_clearField(4);
}

/// SampleFieldPathsResponse holds the sampled paths or the failure.
class SampleFieldPathsResponse extends $pb.GeneratedMessage {
  factory SampleFieldPathsResponse({
    $core.Iterable<FieldPathStat>? paths,
    $core.int? sampled,
    $core.bool? usedFallback,
    $core.bool? truncated,
    DocumentError? error,
  }) {
    final result = create();
    if (paths != null) result.paths.addAll(paths);
    if (sampled != null) result.sampled = sampled;
    if (usedFallback != null) result.usedFallback = usedFallback;
    if (truncated != null) result.truncated = truncated;
    if (error != null) result.error = error;
    return result;
  }

  SampleFieldPathsResponse._();

  factory SampleFieldPathsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SampleFieldPathsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SampleFieldPathsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<FieldPathStat>(1, _omitFieldNames ? '' : 'paths',
        subBuilder: FieldPathStat.create)
    ..aI(2, _omitFieldNames ? '' : 'sampled', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'usedFallback')
    ..aOB(4, _omitFieldNames ? '' : 'truncated')
    ..aOM<DocumentError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: DocumentError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldPathsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SampleFieldPathsResponse copyWith(
          void Function(SampleFieldPathsResponse) updates) =>
      super.copyWith((message) => updates(message as SampleFieldPathsResponse))
          as SampleFieldPathsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SampleFieldPathsResponse create() => SampleFieldPathsResponse._();
  @$core.override
  SampleFieldPathsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SampleFieldPathsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SampleFieldPathsResponse>(create);
  static SampleFieldPathsResponse? _defaultInstance;

  /// Paths ordered by frequency, then path. _id comes first.
  @$pb.TagNumber(1)
  $pb.PbList<FieldPathStat> get paths => $_getList(0);

  /// Number of documents actually sampled.
  @$pb.TagNumber(2)
  $core.int get sampled => $_getIZ(1);
  @$pb.TagNumber(2)
  set sampled($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSampled() => $_has(1);
  @$pb.TagNumber(2)
  void clearSampled() => $_clearField(2);

  /// True if $sample was unavailable and the first documents were read instead.
  @$pb.TagNumber(3)
  $core.bool get usedFallback => $_getBF(2);
  @$pb.TagNumber(3)
  set usedFallback($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsedFallback() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsedFallback() => $_clearField(3);

  /// True if the path limit cut the list.
  @$pb.TagNumber(4)
  $core.bool get truncated => $_getBF(3);
  @$pb.TagNumber(4)
  set truncated($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTruncated() => $_has(3);
  @$pb.TagNumber(4)
  void clearTruncated() => $_clearField(4);

  /// Set when sampling failed.
  @$pb.TagNumber(5)
  DocumentError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(DocumentError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  DocumentError ensureError() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
