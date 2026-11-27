// This is a generated file - do not edit.
//
// Generated from queravue/v1/transfer.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'query.pb.dart' as $3;
import 'schema.pb.dart' as $1;
import 'table.pb.dart' as $2;
import 'transfer.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'transfer.pbenum.dart';

/// TransferError is a typed failure. The message never contains secrets or
/// row data.
class TransferError extends $pb.GeneratedMessage {
  factory TransferError({
    TransferErrorKind? kind,
    $core.String? message,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    return result;
  }

  TransferError._();

  factory TransferError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TransferError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<TransferErrorKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: TransferErrorKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferError copyWith(void Function(TransferError) updates) =>
      super.copyWith((message) => updates(message as TransferError))
          as TransferError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransferError create() => TransferError._();
  @$core.override
  TransferError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TransferError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TransferError>(create);
  static TransferError? _defaultInstance;

  /// Failure class.
  @$pb.TagNumber(1)
  TransferErrorKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(TransferErrorKind value) => $_setField(1, value);
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
}

/// TransferFormatOptions tunes a format. Fields that do not apply to the
/// chosen format are ignored.
class TransferFormatOptions extends $pb.GeneratedMessage {
  factory TransferFormatOptions({
    $core.String? delimiter,
    $core.String? quote,
    $core.bool? header,
    $core.String? nullText,
    JsonFlavor? jsonFlavor,
    $core.bool? sqlIncludeDdl,
    $core.String? sqlTargetTable,
  }) {
    final result = create();
    if (delimiter != null) result.delimiter = delimiter;
    if (quote != null) result.quote = quote;
    if (header != null) result.header = header;
    if (nullText != null) result.nullText = nullText;
    if (jsonFlavor != null) result.jsonFlavor = jsonFlavor;
    if (sqlIncludeDdl != null) result.sqlIncludeDdl = sqlIncludeDdl;
    if (sqlTargetTable != null) result.sqlTargetTable = sqlTargetTable;
    return result;
  }

  TransferFormatOptions._();

  factory TransferFormatOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TransferFormatOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferFormatOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'delimiter')
    ..aOS(2, _omitFieldNames ? '' : 'quote')
    ..aOB(3, _omitFieldNames ? '' : 'header')
    ..aOS(4, _omitFieldNames ? '' : 'nullText')
    ..aE<JsonFlavor>(5, _omitFieldNames ? '' : 'jsonFlavor',
        enumValues: JsonFlavor.values)
    ..aOB(6, _omitFieldNames ? '' : 'sqlIncludeDdl')
    ..aOS(7, _omitFieldNames ? '' : 'sqlTargetTable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferFormatOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferFormatOptions copyWith(
          void Function(TransferFormatOptions) updates) =>
      super.copyWith((message) => updates(message as TransferFormatOptions))
          as TransferFormatOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransferFormatOptions create() => TransferFormatOptions._();
  @$core.override
  TransferFormatOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TransferFormatOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TransferFormatOptions>(create);
  static TransferFormatOptions? _defaultInstance;

  /// CSV/TSV field delimiter; empty means "," for CSV and a tab for TSV.
  @$pb.TagNumber(1)
  $core.String get delimiter => $_getSZ(0);
  @$pb.TagNumber(1)
  set delimiter($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDelimiter() => $_has(0);
  @$pb.TagNumber(1)
  void clearDelimiter() => $_clearField(1);

  /// CSV/TSV quote character; empty means a double quote.
  @$pb.TagNumber(2)
  $core.String get quote => $_getSZ(1);
  @$pb.TagNumber(2)
  set quote($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuote() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuote() => $_clearField(2);

  /// CSV/TSV: the first line holds column names.
  @$pb.TagNumber(3)
  $core.bool get header => $_getBF(2);
  @$pb.TagNumber(3)
  set header($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeader() => $_clearField(3);

  /// CSV/TSV text that stands for NULL; empty means an empty field is NULL.
  @$pb.TagNumber(4)
  $core.String get nullText => $_getSZ(3);
  @$pb.TagNumber(4)
  set nullText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNullText() => $_has(3);
  @$pb.TagNumber(4)
  void clearNullText() => $_clearField(4);

  /// JSON/NDJSON flavour for documents and typed values.
  @$pb.TagNumber(5)
  JsonFlavor get jsonFlavor => $_getN(4);
  @$pb.TagNumber(5)
  set jsonFlavor(JsonFlavor value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasJsonFlavor() => $_has(4);
  @$pb.TagNumber(5)
  void clearJsonFlavor() => $_clearField(5);

  /// SQL export: emit CREATE TABLE before the INSERTs.
  @$pb.TagNumber(6)
  $core.bool get sqlIncludeDdl => $_getBF(5);
  @$pb.TagNumber(6)
  set sqlIncludeDdl($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSqlIncludeDdl() => $_has(5);
  @$pb.TagNumber(6)
  void clearSqlIncludeDdl() => $_clearField(6);

  /// SQL export: table name used in the statements; empty means the source
  /// table, or "export" for a query result.
  @$pb.TagNumber(7)
  $core.String get sqlTargetTable => $_getSZ(6);
  @$pb.TagNumber(7)
  set sqlTargetTable($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSqlTargetTable() => $_has(6);
  @$pb.TagNumber(7)
  void clearSqlTargetTable() => $_clearField(7);
}

/// ExportOptions selects the output of an export.
class ExportOptions extends $pb.GeneratedMessage {
  factory ExportOptions({
    TransferFormat? format,
    TransferFormatOptions? formatOptions,
  }) {
    final result = create();
    if (format != null) result.format = format;
    if (formatOptions != null) result.formatOptions = formatOptions;
    return result;
  }

  ExportOptions._();

  factory ExportOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<TransferFormat>(1, _omitFieldNames ? '' : 'format',
        enumValues: TransferFormat.values)
    ..aOM<TransferFormatOptions>(2, _omitFieldNames ? '' : 'formatOptions',
        subBuilder: TransferFormatOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportOptions copyWith(void Function(ExportOptions) updates) =>
      super.copyWith((message) => updates(message as ExportOptions))
          as ExportOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportOptions create() => ExportOptions._();
  @$core.override
  ExportOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportOptions>(create);
  static ExportOptions? _defaultInstance;

  /// Output format.
  @$pb.TagNumber(1)
  TransferFormat get format => $_getN(0);
  @$pb.TagNumber(1)
  set format(TransferFormat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);

  /// Format details.
  @$pb.TagNumber(2)
  TransferFormatOptions get formatOptions => $_getN(1);
  @$pb.TagNumber(2)
  set formatOptions(TransferFormatOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormatOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormatOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  TransferFormatOptions ensureFormatOptions() => $_ensure(1);
}

/// CollectionRef names a collection.
class CollectionRef extends $pb.GeneratedMessage {
  factory CollectionRef({
    $core.String? database,
    $core.String? collection,
  }) {
    final result = create();
    if (database != null) result.database = database;
    if (collection != null) result.collection = collection;
    return result;
  }

  CollectionRef._();

  factory CollectionRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CollectionRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CollectionRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'database')
    ..aOS(2, _omitFieldNames ? '' : 'collection')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CollectionRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CollectionRef copyWith(void Function(CollectionRef) updates) =>
      super.copyWith((message) => updates(message as CollectionRef))
          as CollectionRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CollectionRef create() => CollectionRef._();
  @$core.override
  CollectionRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CollectionRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CollectionRef>(create);
  static CollectionRef? _defaultInstance;

  /// Database name.
  @$pb.TagNumber(1)
  $core.String get database => $_getSZ(0);
  @$pb.TagNumber(1)
  set database($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDatabase() => $_has(0);
  @$pb.TagNumber(1)
  void clearDatabase() => $_clearField(1);

  /// Collection name.
  @$pb.TagNumber(2)
  $core.String get collection => $_getSZ(1);
  @$pb.TagNumber(2)
  set collection($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCollection() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollection() => $_clearField(2);
}

/// ListFormatsRequest has no fields.
class ListFormatsRequest extends $pb.GeneratedMessage {
  factory ListFormatsRequest() => create();

  ListFormatsRequest._();

  factory ListFormatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFormatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFormatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatsRequest copyWith(void Function(ListFormatsRequest) updates) =>
      super.copyWith((message) => updates(message as ListFormatsRequest))
          as ListFormatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFormatsRequest create() => ListFormatsRequest._();
  @$core.override
  ListFormatsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFormatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFormatsRequest>(create);
  static ListFormatsRequest? _defaultInstance;
}

/// ListFormatsResponse lists supported formats.
class ListFormatsResponse extends $pb.GeneratedMessage {
  factory ListFormatsResponse({
    $core.Iterable<TransferFormat>? importFormats,
    $core.Iterable<TransferFormat>? exportFormats,
  }) {
    final result = create();
    if (importFormats != null) result.importFormats.addAll(importFormats);
    if (exportFormats != null) result.exportFormats.addAll(exportFormats);
    return result;
  }

  ListFormatsResponse._();

  factory ListFormatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFormatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFormatsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pc<TransferFormat>(
        1, _omitFieldNames ? '' : 'importFormats', $pb.PbFieldType.KE,
        valueOf: TransferFormat.valueOf,
        enumValues: TransferFormat.values,
        defaultEnumValue: TransferFormat.TRANSFER_FORMAT_UNSPECIFIED)
    ..pc<TransferFormat>(
        2, _omitFieldNames ? '' : 'exportFormats', $pb.PbFieldType.KE,
        valueOf: TransferFormat.valueOf,
        enumValues: TransferFormat.values,
        defaultEnumValue: TransferFormat.TRANSFER_FORMAT_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatsResponse copyWith(void Function(ListFormatsResponse) updates) =>
      super.copyWith((message) => updates(message as ListFormatsResponse))
          as ListFormatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFormatsResponse create() => ListFormatsResponse._();
  @$core.override
  ListFormatsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFormatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFormatsResponse>(create);
  static ListFormatsResponse? _defaultInstance;

  /// Formats Import accepts.
  @$pb.TagNumber(1)
  $pb.PbList<TransferFormat> get importFormats => $_getList(0);

  /// Formats the export calls produce.
  @$pb.TagNumber(2)
  $pb.PbList<TransferFormat> get exportFormats => $_getList(1);
}

/// ExportResultRequest selects a spooled result.
class ExportResultRequest extends $pb.GeneratedMessage {
  factory ExportResultRequest({
    $core.String? resultId,
    $core.Iterable<$core.int>? columnIndices,
    ExportOptions? options,
  }) {
    final result = create();
    if (resultId != null) result.resultId = resultId;
    if (columnIndices != null) result.columnIndices.addAll(columnIndices);
    if (options != null) result.options = options;
    return result;
  }

  ExportResultRequest._();

  factory ExportResultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportResultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportResultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resultId')
    ..p<$core.int>(
        2, _omitFieldNames ? '' : 'columnIndices', $pb.PbFieldType.KU3)
    ..aOM<ExportOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: ExportOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportResultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportResultRequest copyWith(void Function(ExportResultRequest) updates) =>
      super.copyWith((message) => updates(message as ExportResultRequest))
          as ExportResultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportResultRequest create() => ExportResultRequest._();
  @$core.override
  ExportResultRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportResultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportResultRequest>(create);
  static ExportResultRequest? _defaultInstance;

  /// Result id from QueryService.Execute.
  @$pb.TagNumber(1)
  $core.String get resultId => $_getSZ(0);
  @$pb.TagNumber(1)
  set resultId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResultId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultId() => $_clearField(1);

  /// Columns to export, in output order. Empty means all columns.
  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get columnIndices => $_getList(1);

  /// Output format.
  @$pb.TagNumber(3)
  ExportOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ExportOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  ExportOptions ensureOptions() => $_ensure(2);
}

/// ExportTableRequest selects a table.
class ExportTableRequest extends $pb.GeneratedMessage {
  factory ExportTableRequest({
    $core.String? sessionId,
    $1.TableRef? table,
    $2.TableFilter? filter,
    $core.Iterable<$2.SortClause>? sort,
    $core.Iterable<$core.String>? columns,
    ExportOptions? options,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (table != null) result.table = table;
    if (filter != null) result.filter = filter;
    if (sort != null) result.sort.addAll(sort);
    if (columns != null) result.columns.addAll(columns);
    if (options != null) result.options = options;
    return result;
  }

  ExportTableRequest._();

  factory ExportTableRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportTableRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportTableRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'table',
        subBuilder: $1.TableRef.create)
    ..aOM<$2.TableFilter>(3, _omitFieldNames ? '' : 'filter',
        subBuilder: $2.TableFilter.create)
    ..pPM<$2.SortClause>(4, _omitFieldNames ? '' : 'sort',
        subBuilder: $2.SortClause.create)
    ..pPS(5, _omitFieldNames ? '' : 'columns')
    ..aOM<ExportOptions>(6, _omitFieldNames ? '' : 'options',
        subBuilder: ExportOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportTableRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportTableRequest copyWith(void Function(ExportTableRequest) updates) =>
      super.copyWith((message) => updates(message as ExportTableRequest))
          as ExportTableRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportTableRequest create() => ExportTableRequest._();
  @$core.override
  ExportTableRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportTableRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportTableRequest>(create);
  static ExportTableRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table to export.
  @$pb.TagNumber(2)
  $1.TableRef get table => $_getN(1);
  @$pb.TagNumber(2)
  set table($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearTable() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureTable() => $_ensure(1);

  /// Optional filter, as in TableService.
  @$pb.TagNumber(3)
  $2.TableFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter($2.TableFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.TableFilter ensureFilter() => $_ensure(2);

  /// Optional sort, as in TableService.
  @$pb.TagNumber(4)
  $pb.PbList<$2.SortClause> get sort => $_getList(3);

  /// Columns to export, in output order. Empty means all columns.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get columns => $_getList(4);

  /// Output format.
  @$pb.TagNumber(6)
  ExportOptions get options => $_getN(5);
  @$pb.TagNumber(6)
  set options(ExportOptions value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOptions() => $_has(5);
  @$pb.TagNumber(6)
  void clearOptions() => $_clearField(6);
  @$pb.TagNumber(6)
  ExportOptions ensureOptions() => $_ensure(5);
}

/// ExportCollectionRequest selects documents.
class ExportCollectionRequest extends $pb.GeneratedMessage {
  factory ExportCollectionRequest({
    $core.String? sessionId,
    CollectionRef? collection,
    $core.String? filterEjson,
    $core.String? projectionEjson,
    $core.String? sortEjson,
    $core.Iterable<$core.String>? fieldPaths,
    ExportOptions? options,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (collection != null) result.collection = collection;
    if (filterEjson != null) result.filterEjson = filterEjson;
    if (projectionEjson != null) result.projectionEjson = projectionEjson;
    if (sortEjson != null) result.sortEjson = sortEjson;
    if (fieldPaths != null) result.fieldPaths.addAll(fieldPaths);
    if (options != null) result.options = options;
    return result;
  }

  ExportCollectionRequest._();

  factory ExportCollectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportCollectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportCollectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<CollectionRef>(2, _omitFieldNames ? '' : 'collection',
        subBuilder: CollectionRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'filterEjson')
    ..aOS(4, _omitFieldNames ? '' : 'projectionEjson')
    ..aOS(5, _omitFieldNames ? '' : 'sortEjson')
    ..pPS(6, _omitFieldNames ? '' : 'fieldPaths')
    ..aOM<ExportOptions>(7, _omitFieldNames ? '' : 'options',
        subBuilder: ExportOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportCollectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportCollectionRequest copyWith(
          void Function(ExportCollectionRequest) updates) =>
      super.copyWith((message) => updates(message as ExportCollectionRequest))
          as ExportCollectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportCollectionRequest create() => ExportCollectionRequest._();
  @$core.override
  ExportCollectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportCollectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportCollectionRequest>(create);
  static ExportCollectionRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Collection to export.
  @$pb.TagNumber(2)
  CollectionRef get collection => $_getN(1);
  @$pb.TagNumber(2)
  set collection(CollectionRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCollection() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollection() => $_clearField(2);
  @$pb.TagNumber(2)
  CollectionRef ensureCollection() => $_ensure(1);

  /// Filter as relaxed EJSON; empty means all documents.
  @$pb.TagNumber(3)
  $core.String get filterEjson => $_getSZ(2);
  @$pb.TagNumber(3)
  set filterEjson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilterEjson() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilterEjson() => $_clearField(3);

  /// Projection as relaxed EJSON; empty means whole documents.
  @$pb.TagNumber(4)
  $core.String get projectionEjson => $_getSZ(3);
  @$pb.TagNumber(4)
  set projectionEjson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProjectionEjson() => $_has(3);
  @$pb.TagNumber(4)
  void clearProjectionEjson() => $_clearField(4);

  /// Sort as relaxed EJSON; empty means natural order.
  @$pb.TagNumber(5)
  $core.String get sortEjson => $_getSZ(4);
  @$pb.TagNumber(5)
  set sortEjson($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSortEjson() => $_has(4);
  @$pb.TagNumber(5)
  void clearSortEjson() => $_clearField(5);

  /// CSV/TSV/Parquet: dotted field paths that become columns, in order.
  /// Ignored for JSON and NDJSON.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get fieldPaths => $_getList(5);

  /// Output format.
  @$pb.TagNumber(7)
  ExportOptions get options => $_getN(6);
  @$pb.TagNumber(7)
  set options(ExportOptions value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOptions() => $_has(6);
  @$pb.TagNumber(7)
  void clearOptions() => $_clearField(7);
  @$pb.TagNumber(7)
  ExportOptions ensureOptions() => $_ensure(6);
}

/// ExportHeader opens an export stream.
class ExportHeader extends $pb.GeneratedMessage {
  factory ExportHeader({
    TransferFormat? format,
    $core.String? suggestedFilename,
  }) {
    final result = create();
    if (format != null) result.format = format;
    if (suggestedFilename != null) result.suggestedFilename = suggestedFilename;
    return result;
  }

  ExportHeader._();

  factory ExportHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<TransferFormat>(1, _omitFieldNames ? '' : 'format',
        enumValues: TransferFormat.values)
    ..aOS(2, _omitFieldNames ? '' : 'suggestedFilename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportHeader copyWith(void Function(ExportHeader) updates) =>
      super.copyWith((message) => updates(message as ExportHeader))
          as ExportHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportHeader create() => ExportHeader._();
  @$core.override
  ExportHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportHeader>(create);
  static ExportHeader? _defaultInstance;

  /// Format of the bytes that follow.
  @$pb.TagNumber(1)
  TransferFormat get format => $_getN(0);
  @$pb.TagNumber(1)
  set format(TransferFormat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);

  /// File name the save dialog proposes, with extension.
  @$pb.TagNumber(2)
  $core.String get suggestedFilename => $_getSZ(1);
  @$pb.TagNumber(2)
  set suggestedFilename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSuggestedFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearSuggestedFilename() => $_clearField(2);
}

/// ExportProgress reports work done so far.
class ExportProgress extends $pb.GeneratedMessage {
  factory ExportProgress({
    $fixnum.Int64? rows,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (rows != null) result.rows = rows;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ExportProgress._();

  factory ExportProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportProgress copyWith(void Function(ExportProgress) updates) =>
      super.copyWith((message) => updates(message as ExportProgress))
          as ExportProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportProgress create() => ExportProgress._();
  @$core.override
  ExportProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportProgress>(create);
  static ExportProgress? _defaultInstance;

  /// Rows or documents encoded.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rows => $_getI64(0);
  @$pb.TagNumber(1)
  set rows($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearRows() => $_clearField(1);

  /// Bytes sent.
  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);
}

/// ExportSummary ends a successful export.
class ExportSummary extends $pb.GeneratedMessage {
  factory ExportSummary({
    $fixnum.Int64? rows,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (rows != null) result.rows = rows;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ExportSummary._();

  factory ExportSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportSummary copyWith(void Function(ExportSummary) updates) =>
      super.copyWith((message) => updates(message as ExportSummary))
          as ExportSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportSummary create() => ExportSummary._();
  @$core.override
  ExportSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportSummary>(create);
  static ExportSummary? _defaultInstance;

  /// Rows or documents encoded.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rows => $_getI64(0);
  @$pb.TagNumber(1)
  set rows($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearRows() => $_clearField(1);

  /// Bytes sent.
  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);
}

enum ExportEvent_Event { header, chunk, progress, summary, error, notSet }

/// ExportEvent is one event of an export stream: the header first, then
/// chunks interleaved with progress, then a summary or an error.
class ExportEvent extends $pb.GeneratedMessage {
  factory ExportEvent({
    ExportHeader? header,
    $core.List<$core.int>? chunk,
    ExportProgress? progress,
    ExportSummary? summary,
    TransferError? error,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (chunk != null) result.chunk = chunk;
    if (progress != null) result.progress = progress;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    return result;
  }

  ExportEvent._();

  factory ExportEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ExportEvent_Event> _ExportEvent_EventByTag =
      {
    1: ExportEvent_Event.header,
    2: ExportEvent_Event.chunk,
    3: ExportEvent_Event.progress,
    4: ExportEvent_Event.summary,
    5: ExportEvent_Event.error,
    0: ExportEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<ExportHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: ExportHeader.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..aOM<ExportProgress>(3, _omitFieldNames ? '' : 'progress',
        subBuilder: ExportProgress.create)
    ..aOM<ExportSummary>(4, _omitFieldNames ? '' : 'summary',
        subBuilder: ExportSummary.create)
    ..aOM<TransferError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: TransferError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportEvent copyWith(void Function(ExportEvent) updates) =>
      super.copyWith((message) => updates(message as ExportEvent))
          as ExportEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportEvent create() => ExportEvent._();
  @$core.override
  ExportEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportEvent>(create);
  static ExportEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  ExportEvent_Event whichEvent() => _ExportEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// First event.
  @$pb.TagNumber(1)
  ExportHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(ExportHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  ExportHeader ensureHeader() => $_ensure(0);

  /// File bytes to append, at most 1 MiB.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);

  /// Throttled progress.
  @$pb.TagNumber(3)
  ExportProgress get progress => $_getN(2);
  @$pb.TagNumber(3)
  set progress(ExportProgress value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProgress() => $_has(2);
  @$pb.TagNumber(3)
  void clearProgress() => $_clearField(3);
  @$pb.TagNumber(3)
  ExportProgress ensureProgress() => $_ensure(2);

  /// Last event of a successful export.
  @$pb.TagNumber(4)
  ExportSummary get summary => $_getN(3);
  @$pb.TagNumber(4)
  set summary(ExportSummary value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSummary() => $_has(3);
  @$pb.TagNumber(4)
  void clearSummary() => $_clearField(4);
  @$pb.TagNumber(4)
  ExportSummary ensureSummary() => $_ensure(3);

  /// Last event of a failed export.
  @$pb.TagNumber(5)
  TransferError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(TransferError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  TransferError ensureError() => $_ensure(4);
}

/// ExportResultResponse is one event of ExportResult.
class ExportResultResponse extends $pb.GeneratedMessage {
  factory ExportResultResponse({
    ExportEvent? event,
  }) {
    final result = create();
    if (event != null) result.event = event;
    return result;
  }

  ExportResultResponse._();

  factory ExportResultResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportResultResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportResultResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ExportEvent>(1, _omitFieldNames ? '' : 'event',
        subBuilder: ExportEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportResultResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportResultResponse copyWith(void Function(ExportResultResponse) updates) =>
      super.copyWith((message) => updates(message as ExportResultResponse))
          as ExportResultResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportResultResponse create() => ExportResultResponse._();
  @$core.override
  ExportResultResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportResultResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportResultResponse>(create);
  static ExportResultResponse? _defaultInstance;

  /// Event.
  @$pb.TagNumber(1)
  ExportEvent get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(ExportEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  ExportEvent ensureEvent() => $_ensure(0);
}

/// ExportTableResponse is one event of ExportTable.
class ExportTableResponse extends $pb.GeneratedMessage {
  factory ExportTableResponse({
    ExportEvent? event,
  }) {
    final result = create();
    if (event != null) result.event = event;
    return result;
  }

  ExportTableResponse._();

  factory ExportTableResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportTableResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportTableResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ExportEvent>(1, _omitFieldNames ? '' : 'event',
        subBuilder: ExportEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportTableResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportTableResponse copyWith(void Function(ExportTableResponse) updates) =>
      super.copyWith((message) => updates(message as ExportTableResponse))
          as ExportTableResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportTableResponse create() => ExportTableResponse._();
  @$core.override
  ExportTableResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportTableResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportTableResponse>(create);
  static ExportTableResponse? _defaultInstance;

  /// Event.
  @$pb.TagNumber(1)
  ExportEvent get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(ExportEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  ExportEvent ensureEvent() => $_ensure(0);
}

/// ExportCollectionResponse is one event of ExportCollection.
class ExportCollectionResponse extends $pb.GeneratedMessage {
  factory ExportCollectionResponse({
    ExportEvent? event,
  }) {
    final result = create();
    if (event != null) result.event = event;
    return result;
  }

  ExportCollectionResponse._();

  factory ExportCollectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportCollectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportCollectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ExportEvent>(1, _omitFieldNames ? '' : 'event',
        subBuilder: ExportEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportCollectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportCollectionResponse copyWith(
          void Function(ExportCollectionResponse) updates) =>
      super.copyWith((message) => updates(message as ExportCollectionResponse))
          as ExportCollectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportCollectionResponse create() => ExportCollectionResponse._();
  @$core.override
  ExportCollectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportCollectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportCollectionResponse>(create);
  static ExportCollectionResponse? _defaultInstance;

  /// Event.
  @$pb.TagNumber(1)
  ExportEvent get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(ExportEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  ExportEvent ensureEvent() => $_ensure(0);
}

/// InferImportHeader opens an InferImport stream.
class InferImportHeader extends $pb.GeneratedMessage {
  factory InferImportHeader({
    $core.String? sessionId,
    $core.String? filename,
    TransferFormat? format,
    TransferFormatOptions? formatOptions,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (filename != null) result.filename = filename;
    if (format != null) result.format = format;
    if (formatOptions != null) result.formatOptions = formatOptions;
    return result;
  }

  InferImportHeader._();

  factory InferImportHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InferImportHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InferImportHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..aE<TransferFormat>(3, _omitFieldNames ? '' : 'format',
        enumValues: TransferFormat.values)
    ..aOM<TransferFormatOptions>(4, _omitFieldNames ? '' : 'formatOptions',
        subBuilder: TransferFormatOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportHeader copyWith(void Function(InferImportHeader) updates) =>
      super.copyWith((message) => updates(message as InferImportHeader))
          as InferImportHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InferImportHeader create() => InferImportHeader._();
  @$core.override
  InferImportHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InferImportHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InferImportHeader>(create);
  static InferImportHeader? _defaultInstance;

  /// Session id; the target engine shapes the suggested column types.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// File name, used for the format guess by extension.
  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => $_clearField(2);

  /// Format to assume; unset means detect it.
  @$pb.TagNumber(3)
  TransferFormat get format => $_getN(2);
  @$pb.TagNumber(3)
  set format(TransferFormat value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFormat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormat() => $_clearField(3);

  /// Format details to assume; unset fields are detected.
  @$pb.TagNumber(4)
  TransferFormatOptions get formatOptions => $_getN(3);
  @$pb.TagNumber(4)
  set formatOptions(TransferFormatOptions value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFormatOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormatOptions() => $_clearField(4);
  @$pb.TagNumber(4)
  TransferFormatOptions ensureFormatOptions() => $_ensure(3);
}

enum InferImportRequest_Message { header, chunk, notSet }

/// InferImportRequest is one message of an InferImport stream.
class InferImportRequest extends $pb.GeneratedMessage {
  factory InferImportRequest({
    InferImportHeader? header,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  InferImportRequest._();

  factory InferImportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InferImportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InferImportRequest_Message>
      _InferImportRequest_MessageByTag = {
    1: InferImportRequest_Message.header,
    2: InferImportRequest_Message.chunk,
    0: InferImportRequest_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InferImportRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InferImportHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: InferImportHeader.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportRequest copyWith(void Function(InferImportRequest) updates) =>
      super.copyWith((message) => updates(message as InferImportRequest))
          as InferImportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InferImportRequest create() => InferImportRequest._();
  @$core.override
  InferImportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InferImportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InferImportRequest>(create);
  static InferImportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  InferImportRequest_Message whichMessage() =>
      _InferImportRequest_MessageByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField($_whichOneof(0));

  /// First message.
  @$pb.TagNumber(1)
  InferImportHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(InferImportHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  InferImportHeader ensureHeader() => $_ensure(0);

  /// File bytes in order, at most 1 MiB each.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
}

/// ImportColumn is one column found in a file.
class ImportColumn extends $pb.GeneratedMessage {
  factory ImportColumn({
    $core.String? name,
    $3.ValueKind? inferredKind,
    $core.String? suggestedTypeName,
    $core.bool? nullable,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (inferredKind != null) result.inferredKind = inferredKind;
    if (suggestedTypeName != null) result.suggestedTypeName = suggestedTypeName;
    if (nullable != null) result.nullable = nullable;
    return result;
  }

  ImportColumn._();

  factory ImportColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<$3.ValueKind>(2, _omitFieldNames ? '' : 'inferredKind',
        enumValues: $3.ValueKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'suggestedTypeName')
    ..aOB(4, _omitFieldNames ? '' : 'nullable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportColumn copyWith(void Function(ImportColumn) updates) =>
      super.copyWith((message) => updates(message as ImportColumn))
          as ImportColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportColumn create() => ImportColumn._();
  @$core.override
  ImportColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportColumn>(create);
  static ImportColumn? _defaultInstance;

  /// Name from the header, or "column_<n>" (1-based) without one.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Value kind inferred from the sample.
  @$pb.TagNumber(2)
  $3.ValueKind get inferredKind => $_getN(1);
  @$pb.TagNumber(2)
  set inferredKind($3.ValueKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInferredKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearInferredKind() => $_clearField(2);

  /// Native type the target engine would use for a new table.
  @$pb.TagNumber(3)
  $core.String get suggestedTypeName => $_getSZ(2);
  @$pb.TagNumber(3)
  set suggestedTypeName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSuggestedTypeName() => $_has(2);
  @$pb.TagNumber(3)
  void clearSuggestedTypeName() => $_clearField(3);

  /// True when the sample had empty or NULL values.
  @$pb.TagNumber(4)
  $core.bool get nullable => $_getBF(3);
  @$pb.TagNumber(4)
  set nullable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNullable() => $_has(3);
  @$pb.TagNumber(4)
  void clearNullable() => $_clearField(4);
}

/// InferImportResponse describes the file.
class InferImportResponse extends $pb.GeneratedMessage {
  factory InferImportResponse({
    TransferFormat? format,
    TransferFormatOptions? formatOptions,
    $core.Iterable<ImportColumn>? columns,
    $3.RowBatch? previewRows,
    $core.Iterable<$core.String>? previewDocumentsEjson,
    $core.Iterable<$core.String>? warnings,
    TransferError? error,
  }) {
    final result = create();
    if (format != null) result.format = format;
    if (formatOptions != null) result.formatOptions = formatOptions;
    if (columns != null) result.columns.addAll(columns);
    if (previewRows != null) result.previewRows = previewRows;
    if (previewDocumentsEjson != null)
      result.previewDocumentsEjson.addAll(previewDocumentsEjson);
    if (warnings != null) result.warnings.addAll(warnings);
    if (error != null) result.error = error;
    return result;
  }

  InferImportResponse._();

  factory InferImportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InferImportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InferImportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aE<TransferFormat>(1, _omitFieldNames ? '' : 'format',
        enumValues: TransferFormat.values)
    ..aOM<TransferFormatOptions>(2, _omitFieldNames ? '' : 'formatOptions',
        subBuilder: TransferFormatOptions.create)
    ..pPM<ImportColumn>(3, _omitFieldNames ? '' : 'columns',
        subBuilder: ImportColumn.create)
    ..aOM<$3.RowBatch>(4, _omitFieldNames ? '' : 'previewRows',
        subBuilder: $3.RowBatch.create)
    ..pPS(5, _omitFieldNames ? '' : 'previewDocumentsEjson')
    ..pPS(6, _omitFieldNames ? '' : 'warnings')
    ..aOM<TransferError>(7, _omitFieldNames ? '' : 'error',
        subBuilder: TransferError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InferImportResponse copyWith(void Function(InferImportResponse) updates) =>
      super.copyWith((message) => updates(message as InferImportResponse))
          as InferImportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InferImportResponse create() => InferImportResponse._();
  @$core.override
  InferImportResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InferImportResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InferImportResponse>(create);
  static InferImportResponse? _defaultInstance;

  /// Detected or assumed format.
  @$pb.TagNumber(1)
  TransferFormat get format => $_getN(0);
  @$pb.TagNumber(1)
  set format(TransferFormat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);

  /// Detected or assumed format details.
  @$pb.TagNumber(2)
  TransferFormatOptions get formatOptions => $_getN(1);
  @$pb.TagNumber(2)
  set formatOptions(TransferFormatOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormatOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormatOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  TransferFormatOptions ensureFormatOptions() => $_ensure(1);

  /// Columns for tabular formats; empty for JSON and NDJSON documents.
  @$pb.TagNumber(3)
  $pb.PbList<ImportColumn> get columns => $_getList(2);

  /// First rows as typed values, for tabular formats.
  @$pb.TagNumber(4)
  $3.RowBatch get previewRows => $_getN(3);
  @$pb.TagNumber(4)
  set previewRows($3.RowBatch value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPreviewRows() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreviewRows() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.RowBatch ensurePreviewRows() => $_ensure(3);

  /// First documents as canonical EJSON, for JSON and NDJSON.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get previewDocumentsEjson => $_getList(4);

  /// Notes on the guess, e.g. mixed types in a column.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get warnings => $_getList(5);

  /// Set when the bytes could not be read in any supported format.
  @$pb.TagNumber(7)
  TransferError get error => $_getN(6);
  @$pb.TagNumber(7)
  set error(TransferError value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
  @$pb.TagNumber(7)
  TransferError ensureError() => $_ensure(6);
}

/// NewTable is a table the import creates first.
class NewTable extends $pb.GeneratedMessage {
  factory NewTable({
    $1.TableRef? table,
    $core.Iterable<$1.ColumnDetails>? columns,
  }) {
    final result = create();
    if (table != null) result.table = table;
    if (columns != null) result.columns.addAll(columns);
    return result;
  }

  NewTable._();

  factory NewTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$1.TableRef>(1, _omitFieldNames ? '' : 'table',
        subBuilder: $1.TableRef.create)
    ..pPM<$1.ColumnDetails>(2, _omitFieldNames ? '' : 'columns',
        subBuilder: $1.ColumnDetails.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewTable copyWith(void Function(NewTable) updates) =>
      super.copyWith((message) => updates(message as NewTable)) as NewTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewTable create() => NewTable._();
  @$core.override
  NewTable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NewTable getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewTable>(create);
  static NewTable? _defaultInstance;

  /// Where to create it.
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

  /// Columns, in order. type_name is the native type.
  @$pb.TagNumber(2)
  $pb.PbList<$1.ColumnDetails> get columns => $_getList(1);
}

/// ColumnMapping sends one source column to one target column.
class ColumnMapping extends $pb.GeneratedMessage {
  factory ColumnMapping({
    $core.int? sourceIndex,
    $core.String? targetColumn,
  }) {
    final result = create();
    if (sourceIndex != null) result.sourceIndex = sourceIndex;
    if (targetColumn != null) result.targetColumn = targetColumn;
    return result;
  }

  ColumnMapping._();

  factory ColumnMapping.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColumnMapping.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColumnMapping',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'sourceIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'targetColumn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnMapping clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnMapping copyWith(void Function(ColumnMapping) updates) =>
      super.copyWith((message) => updates(message as ColumnMapping))
          as ColumnMapping;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColumnMapping create() => ColumnMapping._();
  @$core.override
  ColumnMapping createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColumnMapping getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColumnMapping>(create);
  static ColumnMapping? _defaultInstance;

  /// 0-based column index in the file.
  @$pb.TagNumber(1)
  $core.int get sourceIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set sourceIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceIndex() => $_clearField(1);

  /// Target column name.
  @$pb.TagNumber(2)
  $core.String get targetColumn => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetColumn($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetColumn() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetColumn() => $_clearField(2);
}

enum ImportHeader_Target { existingTable, newTable, collection, notSet }

/// ImportHeader opens an Import stream.
class ImportHeader extends $pb.GeneratedMessage {
  factory ImportHeader({
    $core.String? sessionId,
    $1.TableRef? existingTable,
    NewTable? newTable,
    CollectionRef? collection,
    TransferFormat? format,
    TransferFormatOptions? formatOptions,
    $core.Iterable<ColumnMapping>? mappings,
    ImportErrorPolicy? errorPolicy,
    $core.int? maxRowErrors,
    $core.bool? singleTransaction,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (existingTable != null) result.existingTable = existingTable;
    if (newTable != null) result.newTable = newTable;
    if (collection != null) result.collection = collection;
    if (format != null) result.format = format;
    if (formatOptions != null) result.formatOptions = formatOptions;
    if (mappings != null) result.mappings.addAll(mappings);
    if (errorPolicy != null) result.errorPolicy = errorPolicy;
    if (maxRowErrors != null) result.maxRowErrors = maxRowErrors;
    if (singleTransaction != null) result.singleTransaction = singleTransaction;
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  ImportHeader._();

  factory ImportHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ImportHeader_Target>
      _ImportHeader_TargetByTag = {
    2: ImportHeader_Target.existingTable,
    3: ImportHeader_Target.newTable,
    4: ImportHeader_Target.collection,
    0: ImportHeader_Target.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'existingTable',
        subBuilder: $1.TableRef.create)
    ..aOM<NewTable>(3, _omitFieldNames ? '' : 'newTable',
        subBuilder: NewTable.create)
    ..aOM<CollectionRef>(4, _omitFieldNames ? '' : 'collection',
        subBuilder: CollectionRef.create)
    ..aE<TransferFormat>(5, _omitFieldNames ? '' : 'format',
        enumValues: TransferFormat.values)
    ..aOM<TransferFormatOptions>(6, _omitFieldNames ? '' : 'formatOptions',
        subBuilder: TransferFormatOptions.create)
    ..pPM<ColumnMapping>(7, _omitFieldNames ? '' : 'mappings',
        subBuilder: ColumnMapping.create)
    ..aE<ImportErrorPolicy>(8, _omitFieldNames ? '' : 'errorPolicy',
        enumValues: ImportErrorPolicy.values)
    ..aI(9, _omitFieldNames ? '' : 'maxRowErrors',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(10, _omitFieldNames ? '' : 'singleTransaction')
    ..aOB(11, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportHeader copyWith(void Function(ImportHeader) updates) =>
      super.copyWith((message) => updates(message as ImportHeader))
          as ImportHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportHeader create() => ImportHeader._();
  @$core.override
  ImportHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportHeader>(create);
  static ImportHeader? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  ImportHeader_Target whichTarget() =>
      _ImportHeader_TargetByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearTarget() => $_clearField($_whichOneof(0));

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// An existing table.
  @$pb.TagNumber(2)
  $1.TableRef get existingTable => $_getN(1);
  @$pb.TagNumber(2)
  set existingTable($1.TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExistingTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearExistingTable() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.TableRef ensureExistingTable() => $_ensure(1);

  /// A table to create first.
  @$pb.TagNumber(3)
  NewTable get newTable => $_getN(2);
  @$pb.TagNumber(3)
  set newTable(NewTable value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNewTable() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewTable() => $_clearField(3);
  @$pb.TagNumber(3)
  NewTable ensureNewTable() => $_ensure(2);

  /// A collection, created on first insert if missing.
  @$pb.TagNumber(4)
  CollectionRef get collection => $_getN(3);
  @$pb.TagNumber(4)
  set collection(CollectionRef value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCollection() => $_has(3);
  @$pb.TagNumber(4)
  void clearCollection() => $_clearField(4);
  @$pb.TagNumber(4)
  CollectionRef ensureCollection() => $_ensure(3);

  /// File format.
  @$pb.TagNumber(5)
  TransferFormat get format => $_getN(4);
  @$pb.TagNumber(5)
  set format(TransferFormat value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFormat() => $_has(4);
  @$pb.TagNumber(5)
  void clearFormat() => $_clearField(5);

  /// Format details.
  @$pb.TagNumber(6)
  TransferFormatOptions get formatOptions => $_getN(5);
  @$pb.TagNumber(6)
  set formatOptions(TransferFormatOptions value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasFormatOptions() => $_has(5);
  @$pb.TagNumber(6)
  void clearFormatOptions() => $_clearField(6);
  @$pb.TagNumber(6)
  TransferFormatOptions ensureFormatOptions() => $_ensure(5);

  /// Tabular sources: columns to load. Empty means by position into all
  /// target columns.
  @$pb.TagNumber(7)
  $pb.PbList<ColumnMapping> get mappings => $_getList(6);

  /// What a bad row does.
  @$pb.TagNumber(8)
  ImportErrorPolicy get errorPolicy => $_getN(7);
  @$pb.TagNumber(8)
  set errorPolicy(ImportErrorPolicy value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasErrorPolicy() => $_has(7);
  @$pb.TagNumber(8)
  void clearErrorPolicy() => $_clearField(8);

  /// SKIP: stop after this many bad rows; 0 means 1000.
  @$pb.TagNumber(9)
  $core.int get maxRowErrors => $_getIZ(8);
  @$pb.TagNumber(9)
  set maxRowErrors($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMaxRowErrors() => $_has(8);
  @$pb.TagNumber(9)
  void clearMaxRowErrors() => $_clearField(9);

  /// Load everything in one transaction where the engine supports it.
  @$pb.TagNumber(10)
  $core.bool get singleTransaction => $_getBF(9);
  @$pb.TagNumber(10)
  set singleTransaction($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSingleTransaction() => $_has(9);
  @$pb.TagNumber(10)
  void clearSingleTransaction() => $_clearField(10);

  /// Required on connections flagged production.
  @$pb.TagNumber(11)
  $core.bool get confirmed => $_getBF(10);
  @$pb.TagNumber(11)
  set confirmed($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasConfirmed() => $_has(10);
  @$pb.TagNumber(11)
  void clearConfirmed() => $_clearField(11);
}

enum ImportRequest_Message { header, chunk, notSet }

/// ImportRequest is one message of an Import stream.
class ImportRequest extends $pb.GeneratedMessage {
  factory ImportRequest({
    ImportHeader? header,
    $core.List<$core.int>? chunk,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  ImportRequest._();

  factory ImportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ImportRequest_Message>
      _ImportRequest_MessageByTag = {
    1: ImportRequest_Message.header,
    2: ImportRequest_Message.chunk,
    0: ImportRequest_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ImportHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: ImportHeader.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportRequest copyWith(void Function(ImportRequest) updates) =>
      super.copyWith((message) => updates(message as ImportRequest))
          as ImportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportRequest create() => ImportRequest._();
  @$core.override
  ImportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportRequest>(create);
  static ImportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ImportRequest_Message whichMessage() =>
      _ImportRequest_MessageByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField($_whichOneof(0));

  /// First message.
  @$pb.TagNumber(1)
  ImportHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(ImportHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  ImportHeader ensureHeader() => $_ensure(0);

  /// File bytes in order, at most 1 MiB each.
  @$pb.TagNumber(2)
  $core.List<$core.int> get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
}

/// ImportProgress reports work done so far.
class ImportProgress extends $pb.GeneratedMessage {
  factory ImportProgress({
    $fixnum.Int64? rowsCommitted,
    $fixnum.Int64? bytesRead,
  }) {
    final result = create();
    if (rowsCommitted != null) result.rowsCommitted = rowsCommitted;
    if (bytesRead != null) result.bytesRead = bytesRead;
    return result;
  }

  ImportProgress._();

  factory ImportProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'rowsCommitted', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'bytesRead', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportProgress copyWith(void Function(ImportProgress) updates) =>
      super.copyWith((message) => updates(message as ImportProgress))
          as ImportProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportProgress create() => ImportProgress._();
  @$core.override
  ImportProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportProgress>(create);
  static ImportProgress? _defaultInstance;

  /// Rows or documents committed.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rowsCommitted => $_getI64(0);
  @$pb.TagNumber(1)
  set rowsCommitted($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRowsCommitted() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowsCommitted() => $_clearField(1);

  /// File bytes consumed.
  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesRead => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesRead($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytesRead() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesRead() => $_clearField(2);
}

/// ImportRowError is one rejected row.
class ImportRowError extends $pb.GeneratedMessage {
  factory ImportRowError({
    $fixnum.Int64? line,
    $core.String? column,
    $core.String? message,
  }) {
    final result = create();
    if (line != null) result.line = line;
    if (column != null) result.column = column;
    if (message != null) result.message = message;
    return result;
  }

  ImportRowError._();

  factory ImportRowError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportRowError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportRowError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'line', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'column')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportRowError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportRowError copyWith(void Function(ImportRowError) updates) =>
      super.copyWith((message) => updates(message as ImportRowError))
          as ImportRowError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportRowError create() => ImportRowError._();
  @$core.override
  ImportRowError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportRowError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportRowError>(create);
  static ImportRowError? _defaultInstance;

  /// 1-based line (CSV, TSV, NDJSON, SQL) or record number (JSON, Parquet).
  @$pb.TagNumber(1)
  $fixnum.Int64 get line => $_getI64(0);
  @$pb.TagNumber(1)
  set line($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLine() => $_has(0);
  @$pb.TagNumber(1)
  void clearLine() => $_clearField(1);

  /// Column name, when the error belongs to one.
  @$pb.TagNumber(2)
  $core.String get column => $_getSZ(1);
  @$pb.TagNumber(2)
  set column($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColumn() => $_has(1);
  @$pb.TagNumber(2)
  void clearColumn() => $_clearField(2);

  /// Human-readable detail without the row's values.
  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

/// ImportSummary ends an import that ran, completely or until it stopped.
class ImportSummary extends $pb.GeneratedMessage {
  factory ImportSummary({
    $fixnum.Int64? rowsCommitted,
    $fixnum.Int64? rowsSkipped,
    $core.Iterable<ImportRowError>? rowErrors,
    $core.String? ddl,
  }) {
    final result = create();
    if (rowsCommitted != null) result.rowsCommitted = rowsCommitted;
    if (rowsSkipped != null) result.rowsSkipped = rowsSkipped;
    if (rowErrors != null) result.rowErrors.addAll(rowErrors);
    if (ddl != null) result.ddl = ddl;
    return result;
  }

  ImportSummary._();

  factory ImportSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'rowsCommitted', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'rowsSkipped', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<ImportRowError>(3, _omitFieldNames ? '' : 'rowErrors',
        subBuilder: ImportRowError.create)
    ..aOS(4, _omitFieldNames ? '' : 'ddl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportSummary copyWith(void Function(ImportSummary) updates) =>
      super.copyWith((message) => updates(message as ImportSummary))
          as ImportSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportSummary create() => ImportSummary._();
  @$core.override
  ImportSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportSummary>(create);
  static ImportSummary? _defaultInstance;

  /// Rows or documents committed.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rowsCommitted => $_getI64(0);
  @$pb.TagNumber(1)
  set rowsCommitted($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRowsCommitted() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowsCommitted() => $_clearField(1);

  /// Rows skipped under the SKIP policy.
  @$pb.TagNumber(2)
  $fixnum.Int64 get rowsSkipped => $_getI64(1);
  @$pb.TagNumber(2)
  set rowsSkipped($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowsSkipped() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowsSkipped() => $_clearField(2);

  /// Rejected rows, at most max_row_errors.
  @$pb.TagNumber(3)
  $pb.PbList<ImportRowError> get rowErrors => $_getList(2);

  /// DDL that ran for a new table, for the history.
  @$pb.TagNumber(4)
  $core.String get ddl => $_getSZ(3);
  @$pb.TagNumber(4)
  set ddl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDdl() => $_has(3);
  @$pb.TagNumber(4)
  void clearDdl() => $_clearField(4);
}

enum ImportResponse_Event { progress, summary, error, notSet }

/// ImportResponse is one event of an Import stream: progress, then a summary,
/// or an error. A summary may follow an error to report committed rows.
class ImportResponse extends $pb.GeneratedMessage {
  factory ImportResponse({
    ImportProgress? progress,
    ImportSummary? summary,
    TransferError? error,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    return result;
  }

  ImportResponse._();

  factory ImportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ImportResponse_Event>
      _ImportResponse_EventByTag = {
    1: ImportResponse_Event.progress,
    2: ImportResponse_Event.summary,
    3: ImportResponse_Event.error,
    0: ImportResponse_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<ImportProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: ImportProgress.create)
    ..aOM<ImportSummary>(2, _omitFieldNames ? '' : 'summary',
        subBuilder: ImportSummary.create)
    ..aOM<TransferError>(3, _omitFieldNames ? '' : 'error',
        subBuilder: TransferError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportResponse copyWith(void Function(ImportResponse) updates) =>
      super.copyWith((message) => updates(message as ImportResponse))
          as ImportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportResponse create() => ImportResponse._();
  @$core.override
  ImportResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportResponse>(create);
  static ImportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ImportResponse_Event whichEvent() =>
      _ImportResponse_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  /// Throttled progress.
  @$pb.TagNumber(1)
  ImportProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(ImportProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  ImportProgress ensureProgress() => $_ensure(0);

  /// Last event, or the event after an error.
  @$pb.TagNumber(2)
  ImportSummary get summary => $_getN(1);
  @$pb.TagNumber(2)
  set summary(ImportSummary value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSummary() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummary() => $_clearField(2);
  @$pb.TagNumber(2)
  ImportSummary ensureSummary() => $_ensure(1);

  /// Failure that stopped the import.
  @$pb.TagNumber(3)
  TransferError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(TransferError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  TransferError ensureError() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
