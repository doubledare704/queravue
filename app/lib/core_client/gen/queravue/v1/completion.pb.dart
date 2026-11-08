// This is a generated file - do not edit.
//
// Generated from queravue/v1/completion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $2;
import 'completion.pbenum.dart';
import 'query.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'completion.pbenum.dart';

/// CompleteRequest is the input of Complete.
class CompleteRequest extends $pb.GeneratedMessage {
  factory CompleteRequest({
    $core.String? sessionId,
    CompletionContextKind? kind,
    $core.String? text,
    $core.int? cursorOffset,
    $core.int? maxItems,
    $core.String? database,
    $core.String? schema,
    $core.String? collection,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (kind != null) result.kind = kind;
    if (text != null) result.text = text;
    if (cursorOffset != null) result.cursorOffset = cursorOffset;
    if (maxItems != null) result.maxItems = maxItems;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (collection != null) result.collection = collection;
    return result;
  }

  CompleteRequest._();

  factory CompleteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompleteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aE<CompletionContextKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: CompletionContextKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aI(4, _omitFieldNames ? '' : 'cursorOffset',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'maxItems', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'database')
    ..aOS(7, _omitFieldNames ? '' : 'schema')
    ..aOS(8, _omitFieldNames ? '' : 'collection')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteRequest copyWith(void Function(CompleteRequest) updates) =>
      super.copyWith((message) => updates(message as CompleteRequest))
          as CompleteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteRequest create() => CompleteRequest._();
  @$core.override
  CompleteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompleteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteRequest>(create);
  static CompleteRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// What is being completed.
  @$pb.TagNumber(2)
  CompletionContextKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(CompletionContextKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Text window around the cursor: the current statement for SQL, the current
  /// chunk for the shell, the whole input for the query bar. Never the whole file.
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  /// Cursor position inside text, in UTF-16 code units.
  @$pb.TagNumber(4)
  $core.int get cursorOffset => $_getIZ(3);
  @$pb.TagNumber(4)
  set cursorOffset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCursorOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearCursorOffset() => $_clearField(4);

  /// Upper limit on returned items. 0 means 200; the core clamps it to [1, 1000].
  @$pb.TagNumber(5)
  $core.int get maxItems => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxItems($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxItems() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxItems() => $_clearField(5);

  /// Database in scope; empty means the session default.
  @$pb.TagNumber(6)
  $core.String get database => $_getSZ(5);
  @$pb.TagNumber(6)
  set database($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDatabase() => $_has(5);
  @$pb.TagNumber(6)
  void clearDatabase() => $_clearField(6);

  /// Schema in scope for unqualified SQL names; empty means the engine default.
  @$pb.TagNumber(7)
  $core.String get schema => $_getSZ(6);
  @$pb.TagNumber(7)
  set schema($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSchema() => $_has(6);
  @$pb.TagNumber(7)
  void clearSchema() => $_clearField(7);

  /// Collection in scope for SHELL (when known) and MONGO_QUERY.
  @$pb.TagNumber(8)
  $core.String get collection => $_getSZ(7);
  @$pb.TagNumber(8)
  set collection($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCollection() => $_has(7);
  @$pb.TagNumber(8)
  void clearCollection() => $_clearField(8);
}

/// CompletionItem is one candidate.
class CompletionItem extends $pb.GeneratedMessage {
  factory CompletionItem({
    $core.String? label,
    CompletionItemKind? kind,
    $core.String? detail,
    $core.String? insertText,
    $1.TextRange? replace,
    $core.String? sortKey,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    if (insertText != null) result.insertText = insertText;
    if (replace != null) result.replace = replace;
    if (sortKey != null) result.sortKey = sortKey;
    return result;
  }

  CompletionItem._();

  factory CompletionItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompletionItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompletionItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aE<CompletionItemKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: CompletionItemKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..aOS(4, _omitFieldNames ? '' : 'insertText')
    ..aOM<$1.TextRange>(5, _omitFieldNames ? '' : 'replace',
        subBuilder: $1.TextRange.create)
    ..aOS(6, _omitFieldNames ? '' : 'sortKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletionItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletionItem copyWith(void Function(CompletionItem) updates) =>
      super.copyWith((message) => updates(message as CompletionItem))
          as CompletionItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompletionItem create() => CompletionItem._();
  @$core.override
  CompletionItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompletionItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompletionItem>(create);
  static CompletionItem? _defaultInstance;

  /// Text shown in the list.
  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  /// What the item is.
  @$pb.TagNumber(2)
  CompletionItemKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(CompletionItemKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Secondary text, such as a column type and its table.
  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);

  /// Text to insert, already quoted for the dialect when needed.
  @$pb.TagNumber(4)
  $core.String get insertText => $_getSZ(3);
  @$pb.TagNumber(4)
  set insertText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInsertText() => $_has(3);
  @$pb.TagNumber(4)
  void clearInsertText() => $_clearField(4);

  /// Range of the request text that insert_text replaces.
  @$pb.TagNumber(5)
  $1.TextRange get replace => $_getN(4);
  @$pb.TagNumber(5)
  set replace($1.TextRange value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasReplace() => $_has(4);
  @$pb.TagNumber(5)
  void clearReplace() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.TextRange ensureReplace() => $_ensure(4);

  /// Fixed-width key; sorting items by it ascending gives the ranked order.
  @$pb.TagNumber(6)
  $core.String get sortKey => $_getSZ(5);
  @$pb.TagNumber(6)
  set sortKey($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSortKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearSortKey() => $_clearField(6);
}

/// CompleteResponse holds ranked candidates or the failure.
class CompleteResponse extends $pb.GeneratedMessage {
  factory CompleteResponse({
    $core.Iterable<CompletionItem>? items,
    $core.bool? isIncomplete,
    CatalogState? catalogState,
    $2.AdminError? error,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    if (isIncomplete != null) result.isIncomplete = isIncomplete;
    if (catalogState != null) result.catalogState = catalogState;
    if (error != null) result.error = error;
    return result;
  }

  CompleteResponse._();

  factory CompleteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompleteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<CompletionItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CompletionItem.create)
    ..aOB(2, _omitFieldNames ? '' : 'isIncomplete')
    ..aE<CatalogState>(3, _omitFieldNames ? '' : 'catalogState',
        enumValues: CatalogState.values)
    ..aOM<$2.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteResponse copyWith(void Function(CompleteResponse) updates) =>
      super.copyWith((message) => updates(message as CompleteResponse))
          as CompleteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteResponse create() => CompleteResponse._();
  @$core.override
  CompleteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompleteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteResponse>(create);
  static CompleteResponse? _defaultInstance;

  /// Candidates in ranked order.
  @$pb.TagNumber(1)
  $pb.PbList<CompletionItem> get items => $_getList(0);

  /// True if max_items cut the list, so the UI must not filter it locally.
  @$pb.TagNumber(2)
  $core.bool get isIncomplete => $_getBF(1);
  @$pb.TagNumber(2)
  set isIncomplete($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsIncomplete() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsIncomplete() => $_clearField(2);

  /// How much of the catalog was available for this answer.
  @$pb.TagNumber(3)
  CatalogState get catalogState => $_getN(2);
  @$pb.TagNumber(3)
  set catalogState(CatalogState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCatalogState() => $_has(2);
  @$pb.TagNumber(3)
  void clearCatalogState() => $_clearField(3);

  /// Set when the call failed.
  @$pb.TagNumber(4)
  $2.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($2.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.AdminError ensureError() => $_ensure(3);
}

/// WarmCatalogRequest selects what to load.
class WarmCatalogRequest extends $pb.GeneratedMessage {
  factory WarmCatalogRequest({
    $core.String? sessionId,
    $core.String? database,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    return result;
  }

  WarmCatalogRequest._();

  factory WarmCatalogRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WarmCatalogRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WarmCatalogRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarmCatalogRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarmCatalogRequest copyWith(void Function(WarmCatalogRequest) updates) =>
      super.copyWith((message) => updates(message as WarmCatalogRequest))
          as WarmCatalogRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarmCatalogRequest create() => WarmCatalogRequest._();
  @$core.override
  WarmCatalogRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WarmCatalogRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WarmCatalogRequest>(create);
  static WarmCatalogRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database to warm; empty means the session default.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);
}

/// WarmCatalogResponse reports loading counters.
class WarmCatalogResponse extends $pb.GeneratedMessage {
  factory WarmCatalogResponse({
    $core.int? schemasTotal,
    $core.int? schemasDone,
    $core.int? tablesLoaded,
    $core.int? columnsLoaded,
    $core.bool? done,
    $2.AdminError? error,
  }) {
    final result = create();
    if (schemasTotal != null) result.schemasTotal = schemasTotal;
    if (schemasDone != null) result.schemasDone = schemasDone;
    if (tablesLoaded != null) result.tablesLoaded = tablesLoaded;
    if (columnsLoaded != null) result.columnsLoaded = columnsLoaded;
    if (done != null) result.done = done;
    if (error != null) result.error = error;
    return result;
  }

  WarmCatalogResponse._();

  factory WarmCatalogResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WarmCatalogResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WarmCatalogResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'schemasTotal',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'schemasDone',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'tablesLoaded',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'columnsLoaded',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(5, _omitFieldNames ? '' : 'done')
    ..aOM<$2.AdminError>(6, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarmCatalogResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WarmCatalogResponse copyWith(void Function(WarmCatalogResponse) updates) =>
      super.copyWith((message) => updates(message as WarmCatalogResponse))
          as WarmCatalogResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WarmCatalogResponse create() => WarmCatalogResponse._();
  @$core.override
  WarmCatalogResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WarmCatalogResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WarmCatalogResponse>(create);
  static WarmCatalogResponse? _defaultInstance;

  /// Schemas to load, once known.
  @$pb.TagNumber(1)
  $core.int get schemasTotal => $_getIZ(0);
  @$pb.TagNumber(1)
  set schemasTotal($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSchemasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearSchemasTotal() => $_clearField(1);

  /// Schemas loaded so far.
  @$pb.TagNumber(2)
  $core.int get schemasDone => $_getIZ(1);
  @$pb.TagNumber(2)
  set schemasDone($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchemasDone() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemasDone() => $_clearField(2);

  /// Tables and views known so far.
  @$pb.TagNumber(3)
  $core.int get tablesLoaded => $_getIZ(2);
  @$pb.TagNumber(3)
  set tablesLoaded($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTablesLoaded() => $_has(2);
  @$pb.TagNumber(3)
  void clearTablesLoaded() => $_clearField(3);

  /// Columns cached so far.
  @$pb.TagNumber(4)
  $core.int get columnsLoaded => $_getIZ(3);
  @$pb.TagNumber(4)
  set columnsLoaded($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColumnsLoaded() => $_has(3);
  @$pb.TagNumber(4)
  void clearColumnsLoaded() => $_clearField(4);

  /// True on the last message.
  @$pb.TagNumber(5)
  $core.bool get done => $_getBF(4);
  @$pb.TagNumber(5)
  set done($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDone() => $_has(4);
  @$pb.TagNumber(5)
  void clearDone() => $_clearField(5);

  /// Set on the last message if loading failed or was unsupported.
  @$pb.TagNumber(6)
  $2.AdminError get error => $_getN(5);
  @$pb.TagNumber(6)
  set error($2.AdminError value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.AdminError ensureError() => $_ensure(5);
}

/// FormatOptions control the formatter.
class FormatOptions extends $pb.GeneratedMessage {
  factory FormatOptions({
    KeywordCase? keywordCase,
    $core.int? indentWidth,
    CommaStyle? commaStyle,
    $core.int? maxLineWidth,
  }) {
    final result = create();
    if (keywordCase != null) result.keywordCase = keywordCase;
    if (indentWidth != null) result.indentWidth = indentWidth;
    if (commaStyle != null) result.commaStyle = commaStyle;
    if (maxLineWidth != null) result.maxLineWidth = maxLineWidth;
    return result;
  }

  FormatOptions._();

  factory FormatOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormatOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<KeywordCase>(1, _omitFieldNames ? '' : 'keywordCase',
        enumValues: KeywordCase.values)
    ..aI(2, _omitFieldNames ? '' : 'indentWidth',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<CommaStyle>(3, _omitFieldNames ? '' : 'commaStyle',
        enumValues: CommaStyle.values)
    ..aI(4, _omitFieldNames ? '' : 'maxLineWidth',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatOptions copyWith(void Function(FormatOptions) updates) =>
      super.copyWith((message) => updates(message as FormatOptions))
          as FormatOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormatOptions create() => FormatOptions._();
  @$core.override
  FormatOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FormatOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatOptions>(create);
  static FormatOptions? _defaultInstance;

  /// Keyword case.
  @$pb.TagNumber(1)
  KeywordCase get keywordCase => $_getN(0);
  @$pb.TagNumber(1)
  set keywordCase(KeywordCase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKeywordCase() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeywordCase() => $_clearField(1);

  /// Spaces per indent level. 0 means 2; the core clamps it to [1, 8].
  @$pb.TagNumber(2)
  $core.int get indentWidth => $_getIZ(1);
  @$pb.TagNumber(2)
  set indentWidth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndentWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndentWidth() => $_clearField(2);

  /// Comma placement.
  @$pb.TagNumber(3)
  CommaStyle get commaStyle => $_getN(2);
  @$pb.TagNumber(3)
  set commaStyle(CommaStyle value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCommaStyle() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommaStyle() => $_clearField(3);

  /// Preferred maximum line width. 0 means 100; the core clamps it to [40, 400].
  @$pb.TagNumber(4)
  $core.int get maxLineWidth => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxLineWidth($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxLineWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxLineWidth() => $_clearField(4);
}

/// FormatSQLRequest is the input of FormatSQL.
class FormatSQLRequest extends $pb.GeneratedMessage {
  factory FormatSQLRequest({
    $core.String? sessionId,
    $core.String? dialect,
    $core.String? text,
    FormatOptions? options,
    $1.TextRange? range,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (dialect != null) result.dialect = dialect;
    if (text != null) result.text = text;
    if (options != null) result.options = options;
    if (range != null) result.range = range;
    return result;
  }

  FormatSQLRequest._();

  factory FormatSQLRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormatSQLRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatSQLRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'dialect')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOM<FormatOptions>(4, _omitFieldNames ? '' : 'options',
        subBuilder: FormatOptions.create)
    ..aOM<$1.TextRange>(5, _omitFieldNames ? '' : 'range',
        subBuilder: $1.TextRange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatSQLRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatSQLRequest copyWith(void Function(FormatSQLRequest) updates) =>
      super.copyWith((message) => updates(message as FormatSQLRequest))
          as FormatSQLRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormatSQLRequest create() => FormatSQLRequest._();
  @$core.override
  FormatSQLRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FormatSQLRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatSQLRequest>(create);
  static FormatSQLRequest? _defaultInstance;

  /// Session id; its dialect is used when set.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Dialect id such as "postgres", "mysql", "mssql" or "sqlite", used when
  /// session_id is empty.
  @$pb.TagNumber(2)
  $core.String get dialect => $_getSZ(1);
  @$pb.TagNumber(2)
  set dialect($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDialect() => $_has(1);
  @$pb.TagNumber(2)
  void clearDialect() => $_clearField(2);

  /// Text to format.
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  /// Formatter options.
  @$pb.TagNumber(4)
  FormatOptions get options => $_getN(3);
  @$pb.TagNumber(4)
  set options(FormatOptions value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearOptions() => $_clearField(4);
  @$pb.TagNumber(4)
  FormatOptions ensureOptions() => $_ensure(3);

  /// Range of text to format in UTF-16 code units. Unset means all of text.
  @$pb.TagNumber(5)
  $1.TextRange get range => $_getN(4);
  @$pb.TagNumber(5)
  set range($1.TextRange value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRange() => $_has(4);
  @$pb.TagNumber(5)
  void clearRange() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.TextRange ensureRange() => $_ensure(4);
}

/// FormatSQLResponse holds the formatted text or the failure.
class FormatSQLResponse extends $pb.GeneratedMessage {
  factory FormatSQLResponse({
    $core.String? formattedText,
    $1.TextRange? replacedRange,
    $2.AdminError? error,
  }) {
    final result = create();
    if (formattedText != null) result.formattedText = formattedText;
    if (replacedRange != null) result.replacedRange = replacedRange;
    if (error != null) result.error = error;
    return result;
  }

  FormatSQLResponse._();

  factory FormatSQLResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormatSQLResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatSQLResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formattedText')
    ..aOM<$1.TextRange>(2, _omitFieldNames ? '' : 'replacedRange',
        subBuilder: $1.TextRange.create)
    ..aOM<$2.AdminError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $2.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatSQLResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatSQLResponse copyWith(void Function(FormatSQLResponse) updates) =>
      super.copyWith((message) => updates(message as FormatSQLResponse))
          as FormatSQLResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormatSQLResponse create() => FormatSQLResponse._();
  @$core.override
  FormatSQLResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FormatSQLResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatSQLResponse>(create);
  static FormatSQLResponse? _defaultInstance;

  /// Replacement for the formatted range.
  @$pb.TagNumber(1)
  $core.String get formattedText => $_getSZ(0);
  @$pb.TagNumber(1)
  set formattedText($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormattedText() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormattedText() => $_clearField(1);

  /// Range of the request text that formatted_text replaces.
  @$pb.TagNumber(2)
  $1.TextRange get replacedRange => $_getN(1);
  @$pb.TagNumber(2)
  set replacedRange($1.TextRange value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReplacedRange() => $_has(1);
  @$pb.TagNumber(2)
  void clearReplacedRange() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TextRange ensureReplacedRange() => $_ensure(1);

  /// Set when formatting failed; AdminError.position points at the offending
  /// character for INVALID. The text is then unchanged.
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
