// This is a generated file - do not edit.
//
// Generated from queravue/v1/schema.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'query.pbenum.dart' as $1;
import 'schema.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'schema.pbenum.dart';

/// TableRef uniquely identifies a table or view within a connection.
class TableRef extends $pb.GeneratedMessage {
  factory TableRef({
    $core.String? database,
    $core.String? schema,
    $core.String? table,
  }) {
    final result = create();
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (table != null) result.table = table;
    return result;
  }

  TableRef._();

  factory TableRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'database')
    ..aOS(2, _omitFieldNames ? '' : 'schema')
    ..aOS(3, _omitFieldNames ? '' : 'table')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableRef copyWith(void Function(TableRef) updates) =>
      super.copyWith((message) => updates(message as TableRef)) as TableRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableRef create() => TableRef._();
  @$core.override
  TableRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableRef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TableRef>(create);
  static TableRef? _defaultInstance;

  /// Database name. Empty for single-database engines like SQLite.
  @$pb.TagNumber(1)
  $core.String get database => $_getSZ(0);
  @$pb.TagNumber(1)
  set database($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDatabase() => $_has(0);
  @$pb.TagNumber(1)
  void clearDatabase() => $_clearField(1);

  /// Schema name, e.g. "public" in PostgreSQL or "main" in SQLite.
  @$pb.TagNumber(2)
  $core.String get schema => $_getSZ(1);
  @$pb.TagNumber(2)
  set schema($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchema() => $_clearField(2);

  /// Table or view name.
  @$pb.TagNumber(3)
  $core.String get table => $_getSZ(2);
  @$pb.TagNumber(3)
  set table($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTable() => $_has(2);
  @$pb.TagNumber(3)
  void clearTable() => $_clearField(3);
}

/// SchemaObject represents a table, view, or materialized view in a schema list.
class SchemaObject extends $pb.GeneratedMessage {
  factory SchemaObject({
    $core.String? name,
    SchemaObjectType? type,
    $fixnum.Int64? rowCountEstimate,
    $core.bool? capped,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (rowCountEstimate != null) result.rowCountEstimate = rowCountEstimate;
    if (capped != null) result.capped = capped;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  SchemaObject._();

  factory SchemaObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SchemaObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SchemaObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<SchemaObjectType>(2, _omitFieldNames ? '' : 'type',
        enumValues: SchemaObjectType.values)
    ..aInt64(3, _omitFieldNames ? '' : 'rowCountEstimate')
    ..aOB(4, _omitFieldNames ? '' : 'capped')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'sizeBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaObject copyWith(void Function(SchemaObject) updates) =>
      super.copyWith((message) => updates(message as SchemaObject))
          as SchemaObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchemaObject create() => SchemaObject._();
  @$core.override
  SchemaObject createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SchemaObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SchemaObject>(create);
  static SchemaObject? _defaultInstance;

  /// Object name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Type of object (table, view, materialized view).
  @$pb.TagNumber(2)
  SchemaObjectType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(SchemaObjectType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// Estimated row count from table statistics, or -1 if unknown or not applicable.
  @$pb.TagNumber(3)
  $fixnum.Int64 get rowCountEstimate => $_getI64(2);
  @$pb.TagNumber(3)
  set rowCountEstimate($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRowCountEstimate() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowCountEstimate() => $_clearField(3);

  /// True for capped collections.
  @$pb.TagNumber(4)
  $core.bool get capped => $_getBF(3);
  @$pb.TagNumber(4)
  set capped($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCapped() => $_has(3);
  @$pb.TagNumber(4)
  void clearCapped() => $_clearField(4);

  /// Storage size in bytes, or 0 if unknown.
  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);
}

/// ColumnDetails describes a single column in a table or view.
class ColumnDetails extends $pb.GeneratedMessage {
  factory ColumnDetails({
    $core.String? name,
    $core.String? typeName,
    $1.ValueKind? kind,
    $core.bool? nullable,
    $core.String? defaultValue,
    $core.bool? isPrimaryKey,
    $core.int? primaryKeyOrder,
    $core.bool? identity,
    $core.String? collation,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (typeName != null) result.typeName = typeName;
    if (kind != null) result.kind = kind;
    if (nullable != null) result.nullable = nullable;
    if (defaultValue != null) result.defaultValue = defaultValue;
    if (isPrimaryKey != null) result.isPrimaryKey = isPrimaryKey;
    if (primaryKeyOrder != null) result.primaryKeyOrder = primaryKeyOrder;
    if (identity != null) result.identity = identity;
    if (collation != null) result.collation = collation;
    return result;
  }

  ColumnDetails._();

  factory ColumnDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColumnDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColumnDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'typeName')
    ..aE<$1.ValueKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: $1.ValueKind.values)
    ..aOB(4, _omitFieldNames ? '' : 'nullable')
    ..aOS(5, _omitFieldNames ? '' : 'defaultValue')
    ..aOB(6, _omitFieldNames ? '' : 'isPrimaryKey')
    ..aI(7, _omitFieldNames ? '' : 'primaryKeyOrder',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'identity')
    ..aOS(9, _omitFieldNames ? '' : 'collation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnDetails copyWith(void Function(ColumnDetails) updates) =>
      super.copyWith((message) => updates(message as ColumnDetails))
          as ColumnDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColumnDetails create() => ColumnDetails._();
  @$core.override
  ColumnDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColumnDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColumnDetails>(create);
  static ColumnDetails? _defaultInstance;

  /// Column name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Native engine type name, e.g. "varchar(255)", "int4", "TEXT".
  @$pb.TagNumber(2)
  $core.String get typeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set typeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTypeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearTypeName() => $_clearField(2);

  /// General value kind for cell formatting and editing.
  @$pb.TagNumber(3)
  $1.ValueKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind($1.ValueKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// True if the column allows NULL values.
  @$pb.TagNumber(4)
  $core.bool get nullable => $_getBF(3);
  @$pb.TagNumber(4)
  set nullable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNullable() => $_has(3);
  @$pb.TagNumber(4)
  void clearNullable() => $_clearField(4);

  /// Default value expression as defined in the database, if any.
  @$pb.TagNumber(5)
  $core.String get defaultValue => $_getSZ(4);
  @$pb.TagNumber(5)
  set defaultValue($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultValue() => $_clearField(5);

  /// True if this column is part of the primary key.
  @$pb.TagNumber(6)
  $core.bool get isPrimaryKey => $_getBF(5);
  @$pb.TagNumber(6)
  set isPrimaryKey($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsPrimaryKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsPrimaryKey() => $_clearField(6);

  /// 1-based order within a composite primary key; 0 if not a primary key.
  @$pb.TagNumber(7)
  $core.int get primaryKeyOrder => $_getIZ(6);
  @$pb.TagNumber(7)
  set primaryKeyOrder($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPrimaryKeyOrder() => $_has(6);
  @$pb.TagNumber(7)
  void clearPrimaryKeyOrder() => $_clearField(7);

  /// True for an auto-generated value (identity, serial, auto_increment).
  @$pb.TagNumber(8)
  $core.bool get identity => $_getBF(7);
  @$pb.TagNumber(8)
  set identity($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIdentity() => $_has(7);
  @$pb.TagNumber(8)
  void clearIdentity() => $_clearField(8);

  /// Collation name, when the column has one that differs from the table default.
  @$pb.TagNumber(9)
  $core.String get collation => $_getSZ(8);
  @$pb.TagNumber(9)
  set collation($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCollation() => $_has(8);
  @$pb.TagNumber(9)
  void clearCollation() => $_clearField(9);
}

/// IndexDetails describes an index on a table.
class IndexDetails extends $pb.GeneratedMessage {
  factory IndexDetails({
    $core.String? name,
    $core.Iterable<$core.String>? columns,
    $core.bool? isUnique,
    $core.bool? isPrimary,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (columns != null) result.columns.addAll(columns);
    if (isUnique != null) result.isUnique = isUnique;
    if (isPrimary != null) result.isPrimary = isPrimary;
    return result;
  }

  IndexDetails._();

  factory IndexDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IndexDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..aOB(3, _omitFieldNames ? '' : 'isUnique')
    ..aOB(4, _omitFieldNames ? '' : 'isPrimary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexDetails copyWith(void Function(IndexDetails) updates) =>
      super.copyWith((message) => updates(message as IndexDetails))
          as IndexDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IndexDetails create() => IndexDetails._();
  @$core.override
  IndexDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IndexDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IndexDetails>(create);
  static IndexDetails? _defaultInstance;

  /// Name of the index.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Column names included in the index, in order.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);

  /// True if the index enforces uniqueness.
  @$pb.TagNumber(3)
  $core.bool get isUnique => $_getBF(2);
  @$pb.TagNumber(3)
  set isUnique($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsUnique() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsUnique() => $_clearField(3);

  /// True if this is the backing index for the primary key.
  @$pb.TagNumber(4)
  $core.bool get isPrimary => $_getBF(3);
  @$pb.TagNumber(4)
  set isPrimary($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsPrimary() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsPrimary() => $_clearField(4);
}

/// ForeignKeyDetails describes a foreign key constraint.
class ForeignKeyDetails extends $pb.GeneratedMessage {
  factory ForeignKeyDetails({
    $core.String? name,
    $core.Iterable<$core.String>? columns,
    $core.String? referencedSchema,
    $core.String? referencedTable,
    $core.Iterable<$core.String>? referencedColumns,
    ReferentialAction? onDelete,
    ReferentialAction? onUpdate,
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
    return result;
  }

  ForeignKeyDetails._();

  factory ForeignKeyDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForeignKeyDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForeignKeyDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..aOS(3, _omitFieldNames ? '' : 'referencedSchema')
    ..aOS(4, _omitFieldNames ? '' : 'referencedTable')
    ..pPS(5, _omitFieldNames ? '' : 'referencedColumns')
    ..aE<ReferentialAction>(6, _omitFieldNames ? '' : 'onDelete',
        enumValues: ReferentialAction.values)
    ..aE<ReferentialAction>(7, _omitFieldNames ? '' : 'onUpdate',
        enumValues: ReferentialAction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeyDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeyDetails copyWith(void Function(ForeignKeyDetails) updates) =>
      super.copyWith((message) => updates(message as ForeignKeyDetails))
          as ForeignKeyDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForeignKeyDetails create() => ForeignKeyDetails._();
  @$core.override
  ForeignKeyDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForeignKeyDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForeignKeyDetails>(create);
  static ForeignKeyDetails? _defaultInstance;

  /// Constraint name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Constrained column names in the source table.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);

  /// Referenced schema name.
  @$pb.TagNumber(3)
  $core.String get referencedSchema => $_getSZ(2);
  @$pb.TagNumber(3)
  set referencedSchema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReferencedSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearReferencedSchema() => $_clearField(3);

  /// Referenced table name.
  @$pb.TagNumber(4)
  $core.String get referencedTable => $_getSZ(3);
  @$pb.TagNumber(4)
  set referencedTable($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReferencedTable() => $_has(3);
  @$pb.TagNumber(4)
  void clearReferencedTable() => $_clearField(4);

  /// Referenced column names in the target table.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get referencedColumns => $_getList(4);

  /// Action when a referenced row is deleted.
  @$pb.TagNumber(6)
  ReferentialAction get onDelete => $_getN(5);
  @$pb.TagNumber(6)
  set onDelete(ReferentialAction value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOnDelete() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnDelete() => $_clearField(6);

  /// Action when a referenced key is updated.
  @$pb.TagNumber(7)
  ReferentialAction get onUpdate => $_getN(6);
  @$pb.TagNumber(7)
  set onUpdate(ReferentialAction value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOnUpdate() => $_has(6);
  @$pb.TagNumber(7)
  void clearOnUpdate() => $_clearField(7);
}

/// ListDatabasesRequest selects the session to inspect.
class ListDatabasesRequest extends $pb.GeneratedMessage {
  factory ListDatabasesRequest({
    $core.String? sessionId,
    $core.bool? refresh,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  ListDatabasesRequest._();

  factory ListDatabasesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDatabasesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDatabasesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOB(2, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDatabasesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDatabasesRequest copyWith(void Function(ListDatabasesRequest) updates) =>
      super.copyWith((message) => updates(message as ListDatabasesRequest))
          as ListDatabasesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDatabasesRequest create() => ListDatabasesRequest._();
  @$core.override
  ListDatabasesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDatabasesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDatabasesRequest>(create);
  static ListDatabasesRequest? _defaultInstance;

  /// Session id from SessionService.Open.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// True to bypass and invalidate cached databases.
  @$pb.TagNumber(2)
  $core.bool get refresh => $_getBF(1);
  @$pb.TagNumber(2)
  set refresh($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRefresh() => $_has(1);
  @$pb.TagNumber(2)
  void clearRefresh() => $_clearField(2);
}

/// ListDatabasesResponse returns database names.
class ListDatabasesResponse extends $pb.GeneratedMessage {
  factory ListDatabasesResponse({
    $core.Iterable<$core.String>? databases,
  }) {
    final result = create();
    if (databases != null) result.databases.addAll(databases);
    return result;
  }

  ListDatabasesResponse._();

  factory ListDatabasesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDatabasesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDatabasesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'databases')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDatabasesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDatabasesResponse copyWith(
          void Function(ListDatabasesResponse) updates) =>
      super.copyWith((message) => updates(message as ListDatabasesResponse))
          as ListDatabasesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDatabasesResponse create() => ListDatabasesResponse._();
  @$core.override
  ListDatabasesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDatabasesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDatabasesResponse>(create);
  static ListDatabasesResponse? _defaultInstance;

  /// Database names in alphabetical order.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get databases => $_getList(0);
}

/// ListSchemasRequest selects the session and database to inspect.
class ListSchemasRequest extends $pb.GeneratedMessage {
  factory ListSchemasRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.bool? refresh,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  ListSchemasRequest._();

  factory ListSchemasRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemasRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemasRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOB(3, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasRequest copyWith(void Function(ListSchemasRequest) updates) =>
      super.copyWith((message) => updates(message as ListSchemasRequest))
          as ListSchemasRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemasRequest create() => ListSchemasRequest._();
  @$core.override
  ListSchemasRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSchemasRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemasRequest>(create);
  static ListSchemasRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Database name. Optional if the engine has only one database.
  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  /// True to bypass and invalidate cached schemas.
  @$pb.TagNumber(3)
  $core.bool get refresh => $_getBF(2);
  @$pb.TagNumber(3)
  set refresh($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefresh() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefresh() => $_clearField(3);
}

/// ListSchemasResponse returns schema names.
class ListSchemasResponse extends $pb.GeneratedMessage {
  factory ListSchemasResponse({
    $core.Iterable<$core.String>? schemas,
  }) {
    final result = create();
    if (schemas != null) result.schemas.addAll(schemas);
    return result;
  }

  ListSchemasResponse._();

  factory ListSchemasResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemasResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemasResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'schemas')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasResponse copyWith(void Function(ListSchemasResponse) updates) =>
      super.copyWith((message) => updates(message as ListSchemasResponse))
          as ListSchemasResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemasResponse create() => ListSchemasResponse._();
  @$core.override
  ListSchemasResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSchemasResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemasResponse>(create);
  static ListSchemasResponse? _defaultInstance;

  /// Schema names in alphabetical order.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get schemas => $_getList(0);
}

/// ListObjectsRequest selects the session, database, and schema to inspect.
class ListObjectsRequest extends $pb.GeneratedMessage {
  factory ListObjectsRequest({
    $core.String? sessionId,
    $core.String? database,
    $core.String? schema,
    $core.bool? refresh,
    $core.bool? includeSystem,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (refresh != null) result.refresh = refresh;
    if (includeSystem != null) result.includeSystem = includeSystem;
    return result;
  }

  ListObjectsRequest._();

  factory ListObjectsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListObjectsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListObjectsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..aOB(4, _omitFieldNames ? '' : 'refresh')
    ..aOB(5, _omitFieldNames ? '' : 'includeSystem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListObjectsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListObjectsRequest copyWith(void Function(ListObjectsRequest) updates) =>
      super.copyWith((message) => updates(message as ListObjectsRequest))
          as ListObjectsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListObjectsRequest create() => ListObjectsRequest._();
  @$core.override
  ListObjectsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListObjectsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListObjectsRequest>(create);
  static ListObjectsRequest? _defaultInstance;

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

  /// Schema name.
  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);

  /// True to bypass and invalidate cached objects.
  @$pb.TagNumber(4)
  $core.bool get refresh => $_getBF(3);
  @$pb.TagNumber(4)
  set refresh($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRefresh() => $_has(3);
  @$pb.TagNumber(4)
  void clearRefresh() => $_clearField(4);

  /// Include system objects such as MongoDB's system.* collections.
  @$pb.TagNumber(5)
  $core.bool get includeSystem => $_getBF(4);
  @$pb.TagNumber(5)
  set includeSystem($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIncludeSystem() => $_has(4);
  @$pb.TagNumber(5)
  void clearIncludeSystem() => $_clearField(5);
}

/// ListObjectsResponse returns tables and views in the schema.
class ListObjectsResponse extends $pb.GeneratedMessage {
  factory ListObjectsResponse({
    $core.Iterable<SchemaObject>? objects,
  }) {
    final result = create();
    if (objects != null) result.objects.addAll(objects);
    return result;
  }

  ListObjectsResponse._();

  factory ListObjectsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListObjectsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListObjectsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<SchemaObject>(1, _omitFieldNames ? '' : 'objects',
        subBuilder: SchemaObject.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListObjectsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListObjectsResponse copyWith(void Function(ListObjectsResponse) updates) =>
      super.copyWith((message) => updates(message as ListObjectsResponse))
          as ListObjectsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListObjectsResponse create() => ListObjectsResponse._();
  @$core.override
  ListObjectsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListObjectsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListObjectsResponse>(create);
  static ListObjectsResponse? _defaultInstance;

  /// Schema objects ordered by name.
  @$pb.TagNumber(1)
  $pb.PbList<SchemaObject> get objects => $_getList(0);
}

/// GetTableDetailsRequest selects the table to inspect.
class GetTableDetailsRequest extends $pb.GeneratedMessage {
  factory GetTableDetailsRequest({
    $core.String? sessionId,
    TableRef? tableRef,
    $core.bool? refresh,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  GetTableDetailsRequest._();

  factory GetTableDetailsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTableDetailsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTableDetailsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: TableRef.create)
    ..aOB(3, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTableDetailsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTableDetailsRequest copyWith(
          void Function(GetTableDetailsRequest) updates) =>
      super.copyWith((message) => updates(message as GetTableDetailsRequest))
          as GetTableDetailsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTableDetailsRequest create() => GetTableDetailsRequest._();
  @$core.override
  GetTableDetailsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTableDetailsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTableDetailsRequest>(create);
  static GetTableDetailsRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Table reference.
  @$pb.TagNumber(2)
  TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef(TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  TableRef ensureTableRef() => $_ensure(1);

  /// True to bypass and invalidate cached table details.
  @$pb.TagNumber(3)
  $core.bool get refresh => $_getBF(2);
  @$pb.TagNumber(3)
  set refresh($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefresh() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefresh() => $_clearField(3);
}

/// GetTableDetailsResponse returns columns, indexes, and constraints of a table.
class GetTableDetailsResponse extends $pb.GeneratedMessage {
  factory GetTableDetailsResponse({
    TableRef? tableRef,
    SchemaObjectType? type,
    $core.Iterable<ColumnDetails>? columns,
    $core.Iterable<IndexDetails>? indexes,
    $core.Iterable<ForeignKeyDetails>? foreignKeys,
    $fixnum.Int64? rowCountEstimate,
    $core.bool? canEdit,
    $core.String? editDisabledReason,
  }) {
    final result = create();
    if (tableRef != null) result.tableRef = tableRef;
    if (type != null) result.type = type;
    if (columns != null) result.columns.addAll(columns);
    if (indexes != null) result.indexes.addAll(indexes);
    if (foreignKeys != null) result.foreignKeys.addAll(foreignKeys);
    if (rowCountEstimate != null) result.rowCountEstimate = rowCountEstimate;
    if (canEdit != null) result.canEdit = canEdit;
    if (editDisabledReason != null)
      result.editDisabledReason = editDisabledReason;
    return result;
  }

  GetTableDetailsResponse._();

  factory GetTableDetailsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTableDetailsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTableDetailsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<TableRef>(1, _omitFieldNames ? '' : 'tableRef',
        subBuilder: TableRef.create)
    ..aE<SchemaObjectType>(2, _omitFieldNames ? '' : 'type',
        enumValues: SchemaObjectType.values)
    ..pPM<ColumnDetails>(3, _omitFieldNames ? '' : 'columns',
        subBuilder: ColumnDetails.create)
    ..pPM<IndexDetails>(4, _omitFieldNames ? '' : 'indexes',
        subBuilder: IndexDetails.create)
    ..pPM<ForeignKeyDetails>(5, _omitFieldNames ? '' : 'foreignKeys',
        subBuilder: ForeignKeyDetails.create)
    ..aInt64(6, _omitFieldNames ? '' : 'rowCountEstimate')
    ..aOB(7, _omitFieldNames ? '' : 'canEdit')
    ..aOS(8, _omitFieldNames ? '' : 'editDisabledReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTableDetailsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTableDetailsResponse copyWith(
          void Function(GetTableDetailsResponse) updates) =>
      super.copyWith((message) => updates(message as GetTableDetailsResponse))
          as GetTableDetailsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTableDetailsResponse create() => GetTableDetailsResponse._();
  @$core.override
  GetTableDetailsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetTableDetailsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTableDetailsResponse>(create);
  static GetTableDetailsResponse? _defaultInstance;

  /// Table reference.
  @$pb.TagNumber(1)
  TableRef get tableRef => $_getN(0);
  @$pb.TagNumber(1)
  set tableRef(TableRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTableRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearTableRef() => $_clearField(1);
  @$pb.TagNumber(1)
  TableRef ensureTableRef() => $_ensure(0);

  /// Object type (table, view, materialized view).
  @$pb.TagNumber(2)
  SchemaObjectType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(SchemaObjectType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// Columns in physical order.
  @$pb.TagNumber(3)
  $pb.PbList<ColumnDetails> get columns => $_getList(2);

  /// Indexes defined on the table.
  @$pb.TagNumber(4)
  $pb.PbList<IndexDetails> get indexes => $_getList(3);

  /// Foreign keys originating from this table.
  @$pb.TagNumber(5)
  $pb.PbList<ForeignKeyDetails> get foreignKeys => $_getList(4);

  /// Estimated row count from stats, or -1 if unsupported.
  @$pb.TagNumber(6)
  $fixnum.Int64 get rowCountEstimate => $_getI64(5);
  @$pb.TagNumber(6)
  set rowCountEstimate($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRowCountEstimate() => $_has(5);
  @$pb.TagNumber(6)
  void clearRowCountEstimate() => $_clearField(6);

  /// True if the table has a primary key or unique NOT NULL column, allowing editing.
  @$pb.TagNumber(7)
  $core.bool get canEdit => $_getBF(6);
  @$pb.TagNumber(7)
  set canEdit($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanEdit() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanEdit() => $_clearField(7);

  /// Explanation when can_edit is false.
  @$pb.TagNumber(8)
  $core.String get editDisabledReason => $_getSZ(7);
  @$pb.TagNumber(8)
  set editDisabledReason($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEditDisabledReason() => $_has(7);
  @$pb.TagNumber(8)
  void clearEditDisabledReason() => $_clearField(8);
}

/// RefreshSchemaRequest selects what to invalidate.
class RefreshSchemaRequest extends $pb.GeneratedMessage {
  factory RefreshSchemaRequest({
    $core.String? sessionId,
    TableRef? tableRef,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    return result;
  }

  RefreshSchemaRequest._();

  factory RefreshSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshSchemaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: TableRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSchemaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSchemaRequest copyWith(void Function(RefreshSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshSchemaRequest))
          as RefreshSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshSchemaRequest create() => RefreshSchemaRequest._();
  @$core.override
  RefreshSchemaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshSchemaRequest>(create);
  static RefreshSchemaRequest? _defaultInstance;

  /// Session id.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Optional specific table to refresh. If unset, refreshes the whole session cache.
  @$pb.TagNumber(2)
  TableRef get tableRef => $_getN(1);
  @$pb.TagNumber(2)
  set tableRef(TableRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTableRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearTableRef() => $_clearField(2);
  @$pb.TagNumber(2)
  TableRef ensureTableRef() => $_ensure(1);
}

/// RefreshSchemaResponse is empty on success.
class RefreshSchemaResponse extends $pb.GeneratedMessage {
  factory RefreshSchemaResponse() => create();

  RefreshSchemaResponse._();

  factory RefreshSchemaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshSchemaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshSchemaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSchemaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSchemaResponse copyWith(
          void Function(RefreshSchemaResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshSchemaResponse))
          as RefreshSchemaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshSchemaResponse create() => RefreshSchemaResponse._();
  @$core.override
  RefreshSchemaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshSchemaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshSchemaResponse>(create);
  static RefreshSchemaResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
