// This is a generated file - do not edit.
//
// Generated from queravue/v1/diagram.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $1;
import 'design.pb.dart' as $3;
import 'schema.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// GetSchemaGraphRequest selects the schema to draw.
class GetSchemaGraphRequest extends $pb.GeneratedMessage {
  factory GetSchemaGraphRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? schema,
    $core.bool? refresh,
    $core.int? sampleSize,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (refresh != null) result.refresh = refresh;
    if (sampleSize != null) result.sampleSize = sampleSize;
    return result;
  }

  GetSchemaGraphRequest._();

  factory GetSchemaGraphRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSchemaGraphRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSchemaGraphRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..aOB(4, _omitFieldNames ? '' : 'refresh')
    ..aI(5, _omitFieldNames ? '' : 'sampleSize', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaGraphRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaGraphRequest copyWith(
          void Function(GetSchemaGraphRequest) updates) =>
      super.copyWith((message) => updates(message as GetSchemaGraphRequest))
          as GetSchemaGraphRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSchemaGraphRequest create() => GetSchemaGraphRequest._();
  @$core.override
  GetSchemaGraphRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSchemaGraphRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSchemaGraphRequest>(create);
  static GetSchemaGraphRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name; empty means the session default.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// Schema name; empty means the engine's default schema. Ignored by
  /// document stores.
  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);

  /// Skip the cache and read the schema again.
  @$pb.TagNumber(4)
  $core.bool get refresh => $_getBF(3);
  @$pb.TagNumber(4)
  set refresh($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRefresh() => $_has(3);
  @$pb.TagNumber(4)
  void clearRefresh() => $_clearField(4);

  /// Document stores only: documents to sample per collection. 0 means 100;
  /// the core clamps it to [1, 1000].
  @$pb.TagNumber(5)
  $core.int get sampleSize => $_getIZ(4);
  @$pb.TagNumber(5)
  set sampleSize($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSampleSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSampleSize() => $_clearField(5);
}

/// GraphColumn is one column or sampled field of a diagram table.
class GraphColumn extends $pb.GeneratedMessage {
  factory GraphColumn({
    $core.String? name,
    $core.String? typeName,
    $core.bool? nullable,
    $core.int? primaryKeyOrder,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (typeName != null) result.typeName = typeName;
    if (nullable != null) result.nullable = nullable;
    if (primaryKeyOrder != null) result.primaryKeyOrder = primaryKeyOrder;
    return result;
  }

  GraphColumn._();

  factory GraphColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GraphColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GraphColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'typeName')
    ..aOB(3, _omitFieldNames ? '' : 'nullable')
    ..aI(4, _omitFieldNames ? '' : 'primaryKeyOrder',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphColumn copyWith(void Function(GraphColumn) updates) =>
      super.copyWith((message) => updates(message as GraphColumn))
          as GraphColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphColumn create() => GraphColumn._();
  @$core.override
  GraphColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GraphColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GraphColumn>(create);
  static GraphColumn? _defaultInstance;

  /// Column name, or dotted field path on document stores.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Native type name, or the most frequent sampled type.
  @$pb.TagNumber(2)
  $core.String get typeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set typeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTypeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearTypeName() => $_clearField(2);

  /// True if the column allows NULL, or the field is missing in some sampled documents.
  @$pb.TagNumber(3)
  $core.bool get nullable => $_getBF(2);
  @$pb.TagNumber(3)
  set nullable($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNullable() => $_has(2);
  @$pb.TagNumber(3)
  void clearNullable() => $_clearField(3);

  /// 1-based order within the primary key; 0 if not part of it.
  @$pb.TagNumber(4)
  $core.int get primaryKeyOrder => $_getIZ(3);
  @$pb.TagNumber(4)
  set primaryKeyOrder($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrimaryKeyOrder() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrimaryKeyOrder() => $_clearField(4);
}

/// GraphRelation is a reference from one table to another.
class GraphRelation extends $pb.GeneratedMessage {
  factory GraphRelation({
    $core.String? name,
    $core.Iterable<$core.String>? columns,
    $core.String? referencedSchema,
    $core.String? referencedTable,
    $core.Iterable<$core.String>? referencedColumns,
    $2.ReferentialAction? onDelete,
    $2.ReferentialAction? onUpdate,
    $core.bool? inferred,
    $core.double? confidence,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (columns != null) result.columns.addAll(columns);
    if (referencedSchema != null) result.referencedSchema = referencedSchema;
    if (referencedTable != null) result.referencedTable = referencedTable;
    if (referencedColumns != null)
      result.referencedColumns.addAll(referencedColumns);
    if (onDelete != null) result.onDelete = onDelete;
    if (onUpdate != null) result.onUpdate = onUpdate;
    if (inferred != null) result.inferred = inferred;
    if (confidence != null) result.confidence = confidence;
    return result;
  }

  GraphRelation._();

  factory GraphRelation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GraphRelation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GraphRelation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..aOS(3, _omitFieldNames ? '' : 'referencedSchema')
    ..aOS(4, _omitFieldNames ? '' : 'referencedTable')
    ..pPS(5, _omitFieldNames ? '' : 'referencedColumns')
    ..aE<$2.ReferentialAction>(6, _omitFieldNames ? '' : 'onDelete',
        enumValues: $2.ReferentialAction.values)
    ..aE<$2.ReferentialAction>(7, _omitFieldNames ? '' : 'onUpdate',
        enumValues: $2.ReferentialAction.values)
    ..aOB(8, _omitFieldNames ? '' : 'inferred')
    ..aD(9, _omitFieldNames ? '' : 'confidence')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphRelation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphRelation copyWith(void Function(GraphRelation) updates) =>
      super.copyWith((message) => updates(message as GraphRelation))
          as GraphRelation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphRelation create() => GraphRelation._();
  @$core.override
  GraphRelation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GraphRelation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GraphRelation>(create);
  static GraphRelation? _defaultInstance;

  /// Constraint name; empty for inferred relations.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Referencing columns of the owning table, in order.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);

  /// Referenced schema; empty means the same schema.
  @$pb.TagNumber(3)
  $core.String get referencedSchema => $_getSZ(2);
  @$pb.TagNumber(3)
  set referencedSchema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReferencedSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearReferencedSchema() => $_clearField(3);

  /// Referenced table or collection.
  @$pb.TagNumber(4)
  $core.String get referencedTable => $_getSZ(3);
  @$pb.TagNumber(4)
  set referencedTable($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReferencedTable() => $_has(3);
  @$pb.TagNumber(4)
  void clearReferencedTable() => $_clearField(4);

  /// Referenced columns, matching columns by position.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get referencedColumns => $_getList(4);

  /// Action when a referenced row is deleted.
  @$pb.TagNumber(6)
  $2.ReferentialAction get onDelete => $_getN(5);
  @$pb.TagNumber(6)
  set onDelete($2.ReferentialAction value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOnDelete() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnDelete() => $_clearField(6);

  /// Action when a referenced key is updated.
  @$pb.TagNumber(7)
  $2.ReferentialAction get onUpdate => $_getN(6);
  @$pb.TagNumber(7)
  set onUpdate($2.ReferentialAction value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOnUpdate() => $_has(6);
  @$pb.TagNumber(7)
  void clearOnUpdate() => $_clearField(7);

  /// True if no constraint backs the relation and the core guessed it from
  /// names and types.
  @$pb.TagNumber(8)
  $core.bool get inferred => $_getBF(7);
  @$pb.TagNumber(8)
  set inferred($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasInferred() => $_has(7);
  @$pb.TagNumber(8)
  void clearInferred() => $_clearField(8);

  /// For inferred relations: how sure the guess is, in (0, 1]. 0 otherwise.
  @$pb.TagNumber(9)
  $core.double get confidence => $_getN(8);
  @$pb.TagNumber(9)
  set confidence($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConfidence() => $_has(8);
  @$pb.TagNumber(9)
  void clearConfidence() => $_clearField(9);
}

/// GraphTable is one node of the diagram.
class GraphTable extends $pb.GeneratedMessage {
  factory GraphTable({
    $core.String? name,
    $2.SchemaObjectType? type,
    $fixnum.Int64? rowCountEstimate,
    $core.Iterable<GraphColumn>? columns,
    $core.Iterable<GraphRelation>? relations,
    $core.bool? columnsTruncated,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (rowCountEstimate != null) result.rowCountEstimate = rowCountEstimate;
    if (columns != null) result.columns.addAll(columns);
    if (relations != null) result.relations.addAll(relations);
    if (columnsTruncated != null) result.columnsTruncated = columnsTruncated;
    return result;
  }

  GraphTable._();

  factory GraphTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GraphTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GraphTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<$2.SchemaObjectType>(2, _omitFieldNames ? '' : 'type',
        enumValues: $2.SchemaObjectType.values)
    ..aInt64(3, _omitFieldNames ? '' : 'rowCountEstimate')
    ..pPM<GraphColumn>(4, _omitFieldNames ? '' : 'columns',
        subBuilder: GraphColumn.create)
    ..pPM<GraphRelation>(5, _omitFieldNames ? '' : 'relations',
        subBuilder: GraphRelation.create)
    ..aOB(6, _omitFieldNames ? '' : 'columnsTruncated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GraphTable copyWith(void Function(GraphTable) updates) =>
      super.copyWith((message) => updates(message as GraphTable)) as GraphTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphTable create() => GraphTable._();
  @$core.override
  GraphTable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GraphTable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GraphTable>(create);
  static GraphTable? _defaultInstance;

  /// Table, view or collection name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Kind of object.
  @$pb.TagNumber(2)
  $2.SchemaObjectType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type($2.SchemaObjectType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// Estimated row count, or -1 if unknown.
  @$pb.TagNumber(3)
  $fixnum.Int64 get rowCountEstimate => $_getI64(2);
  @$pb.TagNumber(3)
  set rowCountEstimate($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRowCountEstimate() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowCountEstimate() => $_clearField(3);

  /// Columns in ordinal order, or sampled fields by frequency.
  @$pb.TagNumber(4)
  $pb.PbList<GraphColumn> get columns => $_getList(3);

  /// Relations this table owns.
  @$pb.TagNumber(5)
  $pb.PbList<GraphRelation> get relations => $_getList(4);

  /// True if the column list was cut at the core's per-table limit.
  @$pb.TagNumber(6)
  $core.bool get columnsTruncated => $_getBF(5);
  @$pb.TagNumber(6)
  set columnsTruncated($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasColumnsTruncated() => $_has(5);
  @$pb.TagNumber(6)
  void clearColumnsTruncated() => $_clearField(6);
}

/// GetSchemaGraphResponse is one batch of the graph, or the final message.
class GetSchemaGraphResponse extends $pb.GeneratedMessage {
  factory GetSchemaGraphResponse({
    $core.Iterable<GraphTable>? tables,
    $core.int? tablesTotal,
    $core.int? tablesDone,
    $core.bool? done,
    $1.AdminError? error,
    $core.int? collectionsSampled,
  }) {
    final result = create();
    if (tables != null) result.tables.addAll(tables);
    if (tablesTotal != null) result.tablesTotal = tablesTotal;
    if (tablesDone != null) result.tablesDone = tablesDone;
    if (done != null) result.done = done;
    if (error != null) result.error = error;
    if (collectionsSampled != null)
      result.collectionsSampled = collectionsSampled;
    return result;
  }

  GetSchemaGraphResponse._();

  factory GetSchemaGraphResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSchemaGraphResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSchemaGraphResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<GraphTable>(1, _omitFieldNames ? '' : 'tables',
        subBuilder: GraphTable.create)
    ..aI(2, _omitFieldNames ? '' : 'tablesTotal',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'tablesDone', fieldType: $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'done')
    ..aOM<$1.AdminError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: $1.AdminError.create)
    ..aI(6, _omitFieldNames ? '' : 'collectionsSampled',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaGraphResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaGraphResponse copyWith(
          void Function(GetSchemaGraphResponse) updates) =>
      super.copyWith((message) => updates(message as GetSchemaGraphResponse))
          as GetSchemaGraphResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSchemaGraphResponse create() => GetSchemaGraphResponse._();
  @$core.override
  GetSchemaGraphResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSchemaGraphResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSchemaGraphResponse>(create);
  static GetSchemaGraphResponse? _defaultInstance;

  /// Tables of this batch.
  @$pb.TagNumber(1)
  $pb.PbList<GraphTable> get tables => $_getList(0);

  /// Tables the schema has, once known.
  @$pb.TagNumber(2)
  $core.int get tablesTotal => $_getIZ(1);
  @$pb.TagNumber(2)
  set tablesTotal($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTablesTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTablesTotal() => $_clearField(2);

  /// Tables sent so far, including this batch.
  @$pb.TagNumber(3)
  $core.int get tablesDone => $_getIZ(2);
  @$pb.TagNumber(3)
  set tablesDone($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTablesDone() => $_has(2);
  @$pb.TagNumber(3)
  void clearTablesDone() => $_clearField(3);

  /// True on the last message.
  @$pb.TagNumber(4)
  $core.bool get done => $_getBF(3);
  @$pb.TagNumber(4)
  set done($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDone() => $_has(3);
  @$pb.TagNumber(4)
  void clearDone() => $_clearField(4);

  /// Set on the last message if loading failed, was cancelled or is unsupported.
  @$pb.TagNumber(5)
  $1.AdminError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error($1.AdminError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.AdminError ensureError() => $_ensure(4);

  /// Document stores: collections sampled so far, out of tables_total. Progress
  /// messages carry no tables and arrive before the first batch.
  @$pb.TagNumber(6)
  $core.int get collectionsSampled => $_getIZ(5);
  @$pb.TagNumber(6)
  set collectionsSampled($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCollectionsSampled() => $_has(5);
  @$pb.TagNumber(6)
  void clearCollectionsSampled() => $_clearField(6);
}

/// TableChanges is the ordered list of changes to one table.
class TableChanges extends $pb.GeneratedMessage {
  factory TableChanges({
    $2.TableRef? tableRef,
    $core.Iterable<$3.SchemaChange>? changes,
  }) {
    final result = create();
    if (tableRef != null) result.tableRef = tableRef;
    if (changes != null) result.changes.addAll(changes);
    return result;
  }

  TableChanges._();

  factory TableChanges.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableChanges.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableChanges',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$2.TableRef>(1, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $2.TableRef.create)
    ..pPM<$3.SchemaChange>(2, _omitFieldNames ? '' : 'changes',
        subBuilder: $3.SchemaChange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableChanges clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableChanges copyWith(void Function(TableChanges) updates) =>
      super.copyWith((message) => updates(message as TableChanges))
          as TableChanges;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableChanges create() => TableChanges._();
  @$core.override
  TableChanges createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableChanges getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableChanges>(create);
  static TableChanges? _defaultInstance;

  /// Target table (the new table's name for CreateTable).
  @$pb.TagNumber(1)
  $2.TableRef get tableRef => $_getN(0);
  @$pb.TagNumber(1)
  set tableRef($2.TableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTableRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearTableRef() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.TableRef ensureTableRef() => $_ensure(0);

  /// Steps in order.
  @$pb.TagNumber(2)
  $pb.PbList<$3.SchemaChange> get changes => $_getList(1);
}

/// PreviewDiagramDDLRequest asks what DDL a set of table changes produces.
class PreviewDiagramDDLRequest extends $pb.GeneratedMessage {
  factory PreviewDiagramDDLRequest({
    $core.String? sessionId,
    $core.Iterable<TableChanges>? tables,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tables != null) result.tables.addAll(tables);
    return result;
  }

  PreviewDiagramDDLRequest._();

  factory PreviewDiagramDDLRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewDiagramDDLRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewDiagramDDLRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..pPM<TableChanges>(2, _omitFieldNames ? '' : 'tables',
        subBuilder: TableChanges.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDiagramDDLRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDiagramDDLRequest copyWith(
          void Function(PreviewDiagramDDLRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewDiagramDDLRequest))
          as PreviewDiagramDDLRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewDiagramDDLRequest create() => PreviewDiagramDDLRequest._();
  @$core.override
  PreviewDiagramDDLRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewDiagramDDLRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewDiagramDDLRequest>(create);
  static PreviewDiagramDDLRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Changes per table. The core chooses the statement order.
  @$pb.TagNumber(2)
  $pb.PbList<TableChanges> get tables => $_getList(1);
}

/// PreviewDiagramDDLResponse lists the statements and warnings.
class PreviewDiagramDDLResponse extends $pb.GeneratedMessage {
  factory PreviewDiagramDDLResponse({
    $core.Iterable<$3.DdlStatement>? statements,
    $core.Iterable<$core.String>? warnings,
    $core.bool? transactional,
    $1.AdminError? error,
  }) {
    final result = create();
    if (statements != null) result.statements.addAll(statements);
    if (warnings != null) result.warnings.addAll(warnings);
    if (transactional != null) result.transactional = transactional;
    if (error != null) result.error = error;
    return result;
  }

  PreviewDiagramDDLResponse._();

  factory PreviewDiagramDDLResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewDiagramDDLResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewDiagramDDLResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<$3.DdlStatement>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: $3.DdlStatement.create)
    ..pPS(2, _omitFieldNames ? '' : 'warnings')
    ..aOB(3, _omitFieldNames ? '' : 'transactional')
    ..aOM<$1.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $1.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDiagramDDLResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDiagramDDLResponse copyWith(
          void Function(PreviewDiagramDDLResponse) updates) =>
      super.copyWith((message) => updates(message as PreviewDiagramDDLResponse))
          as PreviewDiagramDDLResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewDiagramDDLResponse create() => PreviewDiagramDDLResponse._();
  @$core.override
  PreviewDiagramDDLResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewDiagramDDLResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewDiagramDDLResponse>(create);
  static PreviewDiagramDDLResponse? _defaultInstance;

  /// Statements in execution order.
  @$pb.TagNumber(1)
  $pb.PbList<$3.DdlStatement> get statements => $_getList(0);

  /// Cautions, for example that the engine commits DDL implicitly.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get warnings => $_getList(1);

  /// True if the engine runs these statements in one rollback-able transaction.
  @$pb.TagNumber(3)
  $core.bool get transactional => $_getBF(2);
  @$pb.TagNumber(3)
  set transactional($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTransactional() => $_has(2);
  @$pb.TagNumber(3)
  void clearTransactional() => $_clearField(3);

  /// Set when the changes cannot be turned into DDL for this engine.
  @$pb.TagNumber(4)
  $1.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($1.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.AdminError ensureError() => $_ensure(3);
}

/// ApplyDiagramDDLRequest asks to run the DDL for a set of table changes.
class ApplyDiagramDDLRequest extends $pb.GeneratedMessage {
  factory ApplyDiagramDDLRequest({
    $core.String? sessionId,
    $core.Iterable<TableChanges>? tables,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tables != null) result.tables.addAll(tables);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  ApplyDiagramDDLRequest._();

  factory ApplyDiagramDDLRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyDiagramDDLRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyDiagramDDLRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..pPM<TableChanges>(2, _omitFieldNames ? '' : 'tables',
        subBuilder: TableChanges.create)
    ..aOB(3, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDiagramDDLRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDiagramDDLRequest copyWith(
          void Function(ApplyDiagramDDLRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyDiagramDDLRequest))
          as ApplyDiagramDDLRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyDiagramDDLRequest create() => ApplyDiagramDDLRequest._();
  @$core.override
  ApplyDiagramDDLRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyDiagramDDLRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyDiagramDDLRequest>(create);
  static ApplyDiagramDDLRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Changes per table. The core chooses the statement order.
  @$pb.TagNumber(2)
  $pb.PbList<TableChanges> get tables => $_getList(1);

  /// Required when any statement is destructive, and always on connections
  /// flagged production.
  @$pb.TagNumber(3)
  $core.bool get confirmed => $_getBF(2);
  @$pb.TagNumber(3)
  set confirmed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConfirmed() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfirmed() => $_clearField(3);
}

/// ApplyDiagramDDLResponse reports what ran.
class ApplyDiagramDDLResponse extends $pb.GeneratedMessage {
  factory ApplyDiagramDDLResponse({
    $core.Iterable<$3.DdlStatement>? statements,
    $core.int? executedStatements,
    $core.bool? transactional,
    $1.AdminError? error,
  }) {
    final result = create();
    if (statements != null) result.statements.addAll(statements);
    if (executedStatements != null)
      result.executedStatements = executedStatements;
    if (transactional != null) result.transactional = transactional;
    if (error != null) result.error = error;
    return result;
  }

  ApplyDiagramDDLResponse._();

  factory ApplyDiagramDDLResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyDiagramDDLResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyDiagramDDLResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<$3.DdlStatement>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: $3.DdlStatement.create)
    ..aI(2, _omitFieldNames ? '' : 'executedStatements',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'transactional')
    ..aOM<$1.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $1.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDiagramDDLResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDiagramDDLResponse copyWith(
          void Function(ApplyDiagramDDLResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyDiagramDDLResponse))
          as ApplyDiagramDDLResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyDiagramDDLResponse create() => ApplyDiagramDDLResponse._();
  @$core.override
  ApplyDiagramDDLResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyDiagramDDLResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyDiagramDDLResponse>(create);
  static ApplyDiagramDDLResponse? _defaultInstance;

  /// The statements that were run, in order.
  @$pb.TagNumber(1)
  $pb.PbList<$3.DdlStatement> get statements => $_getList(0);

  /// How many statements completed. Less than the list length means the run
  /// stopped on error; on engines that commit DDL implicitly those statements
  /// stay applied.
  @$pb.TagNumber(2)
  $core.int get executedStatements => $_getIZ(1);
  @$pb.TagNumber(2)
  set executedStatements($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExecutedStatements() => $_has(1);
  @$pb.TagNumber(2)
  void clearExecutedStatements() => $_clearField(2);

  /// True if the run was one rollback-able transaction.
  @$pb.TagNumber(3)
  $core.bool get transactional => $_getBF(2);
  @$pb.TagNumber(3)
  set transactional($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTransactional() => $_has(2);
  @$pb.TagNumber(3)
  void clearTransactional() => $_clearField(3);

  /// Set when the call failed or was refused.
  @$pb.TagNumber(4)
  $1.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($1.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.AdminError ensureError() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
