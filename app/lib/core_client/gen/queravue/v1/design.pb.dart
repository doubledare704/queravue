// This is a generated file - do not edit.
//
// Generated from queravue/v1/design.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $3;
import 'index.pb.dart' as $2;
import 'schema.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// ColumnSpec defines a column.
class ColumnSpec extends $pb.GeneratedMessage {
  factory ColumnSpec({
    $core.String? name,
    $core.String? typeName,
    $core.bool? nullable,
    $core.String? defaultExpression,
    $core.bool? identity,
    $core.String? collation,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (typeName != null) result.typeName = typeName;
    if (nullable != null) result.nullable = nullable;
    if (defaultExpression != null) result.defaultExpression = defaultExpression;
    if (identity != null) result.identity = identity;
    if (collation != null) result.collation = collation;
    return result;
  }

  ColumnSpec._();

  factory ColumnSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColumnSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColumnSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'typeName')
    ..aOB(3, _omitFieldNames ? '' : 'nullable')
    ..aOS(4, _omitFieldNames ? '' : 'defaultExpression')
    ..aOB(5, _omitFieldNames ? '' : 'identity')
    ..aOS(6, _omitFieldNames ? '' : 'collation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColumnSpec copyWith(void Function(ColumnSpec) updates) =>
      super.copyWith((message) => updates(message as ColumnSpec)) as ColumnSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColumnSpec create() => ColumnSpec._();
  @$core.override
  ColumnSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColumnSpec getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColumnSpec>(create);
  static ColumnSpec? _defaultInstance;

  /// Column name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Native type including length or precision, for example "varchar(255)" or "numeric(10,2)".
  @$pb.TagNumber(2)
  $core.String get typeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set typeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTypeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearTypeName() => $_clearField(2);

  /// True if the column allows NULL.
  @$pb.TagNumber(3)
  $core.bool get nullable => $_getBF(2);
  @$pb.TagNumber(3)
  set nullable($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNullable() => $_has(2);
  @$pb.TagNumber(3)
  void clearNullable() => $_clearField(3);

  /// Default expression as SQL text; unset for none.
  @$pb.TagNumber(4)
  $core.String get defaultExpression => $_getSZ(3);
  @$pb.TagNumber(4)
  set defaultExpression($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefaultExpression() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultExpression() => $_clearField(4);

  /// True for an auto-generated value (identity, serial, auto_increment).
  @$pb.TagNumber(5)
  $core.bool get identity => $_getBF(4);
  @$pb.TagNumber(5)
  set identity($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIdentity() => $_has(4);
  @$pb.TagNumber(5)
  void clearIdentity() => $_clearField(5);

  /// Collation name; unset for the server default.
  @$pb.TagNumber(6)
  $core.String get collation => $_getSZ(5);
  @$pb.TagNumber(6)
  set collation($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCollation() => $_has(5);
  @$pb.TagNumber(6)
  void clearCollation() => $_clearField(6);
}

/// ForeignKeySpec defines a foreign key.
class ForeignKeySpec extends $pb.GeneratedMessage {
  factory ForeignKeySpec({
    $core.String? name,
    $core.Iterable<$core.String>? columns,
    $1.TableRef? referencedTable,
    $core.Iterable<$core.String>? referencedColumns,
    $1.ReferentialAction? onDelete,
    $1.ReferentialAction? onUpdate,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (columns != null) result.columns.addAll(columns);
    if (referencedTable != null) result.referencedTable = referencedTable;
    if (referencedColumns != null)
      result.referencedColumns.addAll(referencedColumns);
    if (onDelete != null) result.onDelete = onDelete;
    if (onUpdate != null) result.onUpdate = onUpdate;
    return result;
  }

  ForeignKeySpec._();

  factory ForeignKeySpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForeignKeySpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForeignKeySpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..aOM<$1.TableRef>(3, _omitFieldNames ? '' : 'referencedTable',
        subBuilder: $1.TableRef.create)
    ..pPS(4, _omitFieldNames ? '' : 'referencedColumns')
    ..aE<$1.ReferentialAction>(5, _omitFieldNames ? '' : 'onDelete',
        enumValues: $1.ReferentialAction.values)
    ..aE<$1.ReferentialAction>(6, _omitFieldNames ? '' : 'onUpdate',
        enumValues: $1.ReferentialAction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeySpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForeignKeySpec copyWith(void Function(ForeignKeySpec) updates) =>
      super.copyWith((message) => updates(message as ForeignKeySpec))
          as ForeignKeySpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForeignKeySpec create() => ForeignKeySpec._();
  @$core.override
  ForeignKeySpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForeignKeySpec getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForeignKeySpec>(create);
  static ForeignKeySpec? _defaultInstance;

  /// Constraint name; empty lets the server choose.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Columns in this table.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);

  /// Referenced table.
  @$pb.TagNumber(3)
  $1.TableRef get referencedTable => $_getN(2);
  @$pb.TagNumber(3)
  set referencedTable($1.TableRef value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReferencedTable() => $_has(2);
  @$pb.TagNumber(3)
  void clearReferencedTable() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.TableRef ensureReferencedTable() => $_ensure(2);

  /// Columns in the referenced table.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get referencedColumns => $_getList(3);

  /// Action when a referenced row is deleted.
  @$pb.TagNumber(5)
  $1.ReferentialAction get onDelete => $_getN(4);
  @$pb.TagNumber(5)
  set onDelete($1.ReferentialAction value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOnDelete() => $_has(4);
  @$pb.TagNumber(5)
  void clearOnDelete() => $_clearField(5);

  /// Action when a referenced key is updated.
  @$pb.TagNumber(6)
  $1.ReferentialAction get onUpdate => $_getN(5);
  @$pb.TagNumber(6)
  set onUpdate($1.ReferentialAction value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOnUpdate() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnUpdate() => $_clearField(6);
}

/// UniqueSpec defines a unique constraint.
class UniqueSpec extends $pb.GeneratedMessage {
  factory UniqueSpec({
    $core.String? name,
    $core.Iterable<$core.String>? columns,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (columns != null) result.columns.addAll(columns);
    return result;
  }

  UniqueSpec._();

  factory UniqueSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UniqueSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UniqueSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'columns')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UniqueSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UniqueSpec copyWith(void Function(UniqueSpec) updates) =>
      super.copyWith((message) => updates(message as UniqueSpec)) as UniqueSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UniqueSpec create() => UniqueSpec._();
  @$core.override
  UniqueSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UniqueSpec getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UniqueSpec>(create);
  static UniqueSpec? _defaultInstance;

  /// Constraint name; empty lets the server choose.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Columns in order.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get columns => $_getList(1);
}

/// CheckSpec defines a check constraint.
class CheckSpec extends $pb.GeneratedMessage {
  factory CheckSpec({
    $core.String? name,
    $core.String? expression,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (expression != null) result.expression = expression;
    return result;
  }

  CheckSpec._();

  factory CheckSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'expression')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckSpec copyWith(void Function(CheckSpec) updates) =>
      super.copyWith((message) => updates(message as CheckSpec)) as CheckSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckSpec create() => CheckSpec._();
  @$core.override
  CheckSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckSpec>(create);
  static CheckSpec? _defaultInstance;

  /// Constraint name; empty lets the server choose.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Boolean SQL expression.
  @$pb.TagNumber(2)
  $core.String get expression => $_getSZ(1);
  @$pb.TagNumber(2)
  set expression($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpression() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpression() => $_clearField(2);
}

/// TableDesign is the full definition of a new table. Its name comes from the request's table_ref.
class TableDesign extends $pb.GeneratedMessage {
  factory TableDesign({
    $core.Iterable<ColumnSpec>? columns,
    $core.String? primaryKeyName,
    $core.Iterable<$core.String>? primaryKeyColumns,
    $core.Iterable<UniqueSpec>? uniques,
    $core.Iterable<CheckSpec>? checks,
    $core.Iterable<ForeignKeySpec>? foreignKeys,
    $core.Iterable<$2.IndexSpec>? indexes,
  }) {
    final result = create();
    if (columns != null) result.columns.addAll(columns);
    if (primaryKeyName != null) result.primaryKeyName = primaryKeyName;
    if (primaryKeyColumns != null)
      result.primaryKeyColumns.addAll(primaryKeyColumns);
    if (uniques != null) result.uniques.addAll(uniques);
    if (checks != null) result.checks.addAll(checks);
    if (foreignKeys != null) result.foreignKeys.addAll(foreignKeys);
    if (indexes != null) result.indexes.addAll(indexes);
    return result;
  }

  TableDesign._();

  factory TableDesign.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableDesign.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableDesign',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<ColumnSpec>(1, _omitFieldNames ? '' : 'columns',
        subBuilder: ColumnSpec.create)
    ..aOS(2, _omitFieldNames ? '' : 'primaryKeyName')
    ..pPS(3, _omitFieldNames ? '' : 'primaryKeyColumns')
    ..pPM<UniqueSpec>(4, _omitFieldNames ? '' : 'uniques',
        subBuilder: UniqueSpec.create)
    ..pPM<CheckSpec>(5, _omitFieldNames ? '' : 'checks',
        subBuilder: CheckSpec.create)
    ..pPM<ForeignKeySpec>(6, _omitFieldNames ? '' : 'foreignKeys',
        subBuilder: ForeignKeySpec.create)
    ..pPM<$2.IndexSpec>(7, _omitFieldNames ? '' : 'indexes',
        subBuilder: $2.IndexSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableDesign clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableDesign copyWith(void Function(TableDesign) updates) =>
      super.copyWith((message) => updates(message as TableDesign))
          as TableDesign;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableDesign create() => TableDesign._();
  @$core.override
  TableDesign createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableDesign getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableDesign>(create);
  static TableDesign? _defaultInstance;

  /// Columns in order.
  @$pb.TagNumber(1)
  $pb.PbList<ColumnSpec> get columns => $_getList(0);

  /// Primary key constraint name; empty lets the server choose.
  @$pb.TagNumber(2)
  $core.String get primaryKeyName => $_getSZ(1);
  @$pb.TagNumber(2)
  set primaryKeyName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrimaryKeyName() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrimaryKeyName() => $_clearField(2);

  /// Primary key columns in order; empty for none.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get primaryKeyColumns => $_getList(2);

  /// Unique constraints.
  @$pb.TagNumber(4)
  $pb.PbList<UniqueSpec> get uniques => $_getList(3);

  /// Check constraints.
  @$pb.TagNumber(5)
  $pb.PbList<CheckSpec> get checks => $_getList(4);

  /// Foreign keys.
  @$pb.TagNumber(6)
  $pb.PbList<ForeignKeySpec> get foreignKeys => $_getList(5);

  /// Secondary indexes, created after the table.
  @$pb.TagNumber(7)
  $pb.PbList<$2.IndexSpec> get indexes => $_getList(6);
}

/// CreateTable creates the table named by the request's table_ref.
class CreateTable extends $pb.GeneratedMessage {
  factory CreateTable({
    TableDesign? design,
  }) {
    final result = create();
    if (design != null) result.design = design;
    return result;
  }

  CreateTable._();

  factory CreateTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<TableDesign>(1, _omitFieldNames ? '' : 'design',
        subBuilder: TableDesign.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTable copyWith(void Function(CreateTable) updates) =>
      super.copyWith((message) => updates(message as CreateTable))
          as CreateTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateTable create() => CreateTable._();
  @$core.override
  CreateTable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateTable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateTable>(create);
  static CreateTable? _defaultInstance;

  /// Definition.
  @$pb.TagNumber(1)
  TableDesign get design => $_getN(0);
  @$pb.TagNumber(1)
  set design(TableDesign value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDesign() => $_has(0);
  @$pb.TagNumber(1)
  void clearDesign() => $_clearField(1);
  @$pb.TagNumber(1)
  TableDesign ensureDesign() => $_ensure(0);
}

/// DropTable drops the table named by the request's table_ref.
class DropTable extends $pb.GeneratedMessage {
  factory DropTable() => create();

  DropTable._();

  factory DropTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropTable copyWith(void Function(DropTable) updates) =>
      super.copyWith((message) => updates(message as DropTable)) as DropTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropTable create() => DropTable._();
  @$core.override
  DropTable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropTable getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DropTable>(create);
  static DropTable? _defaultInstance;
}

/// RenameTable renames the table.
class RenameTable extends $pb.GeneratedMessage {
  factory RenameTable({
    $core.String? newName,
  }) {
    final result = create();
    if (newName != null) result.newName = newName;
    return result;
  }

  RenameTable._();

  factory RenameTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'newName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameTable copyWith(void Function(RenameTable) updates) =>
      super.copyWith((message) => updates(message as RenameTable))
          as RenameTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameTable create() => RenameTable._();
  @$core.override
  RenameTable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameTable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameTable>(create);
  static RenameTable? _defaultInstance;

  /// New table name, in the same schema.
  @$pb.TagNumber(1)
  $core.String get newName => $_getSZ(0);
  @$pb.TagNumber(1)
  set newName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNewName() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewName() => $_clearField(1);
}

/// AddColumn adds a column.
class AddColumn extends $pb.GeneratedMessage {
  factory AddColumn({
    ColumnSpec? column,
  }) {
    final result = create();
    if (column != null) result.column = column;
    return result;
  }

  AddColumn._();

  factory AddColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ColumnSpec>(1, _omitFieldNames ? '' : 'column',
        subBuilder: ColumnSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddColumn copyWith(void Function(AddColumn) updates) =>
      super.copyWith((message) => updates(message as AddColumn)) as AddColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddColumn create() => AddColumn._();
  @$core.override
  AddColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddColumn getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddColumn>(create);
  static AddColumn? _defaultInstance;

  /// Column definition.
  @$pb.TagNumber(1)
  ColumnSpec get column => $_getN(0);
  @$pb.TagNumber(1)
  set column(ColumnSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);
  @$pb.TagNumber(1)
  ColumnSpec ensureColumn() => $_ensure(0);
}

/// DropColumn drops a column.
class DropColumn extends $pb.GeneratedMessage {
  factory DropColumn({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  DropColumn._();

  factory DropColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropColumn copyWith(void Function(DropColumn) updates) =>
      super.copyWith((message) => updates(message as DropColumn)) as DropColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropColumn create() => DropColumn._();
  @$core.override
  DropColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropColumn>(create);
  static DropColumn? _defaultInstance;

  /// Column name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// RenameColumn renames a column.
class RenameColumn extends $pb.GeneratedMessage {
  factory RenameColumn({
    $core.String? from,
    $core.String? to,
  }) {
    final result = create();
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    return result;
  }

  RenameColumn._();

  factory RenameColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'from')
    ..aOS(2, _omitFieldNames ? '' : 'to')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameColumn copyWith(void Function(RenameColumn) updates) =>
      super.copyWith((message) => updates(message as RenameColumn))
          as RenameColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameColumn create() => RenameColumn._();
  @$core.override
  RenameColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameColumn>(create);
  static RenameColumn? _defaultInstance;

  /// Current name.
  @$pb.TagNumber(1)
  $core.String get from => $_getSZ(0);
  @$pb.TagNumber(1)
  set from($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);

  /// New name.
  @$pb.TagNumber(2)
  $core.String get to => $_getSZ(1);
  @$pb.TagNumber(2)
  set to($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);
}

/// AlterColumn changes a column's type, nullability, default or collation.
class AlterColumn extends $pb.GeneratedMessage {
  factory AlterColumn({
    ColumnSpec? before,
    ColumnSpec? after,
  }) {
    final result = create();
    if (before != null) result.before = before;
    if (after != null) result.after = after;
    return result;
  }

  AlterColumn._();

  factory AlterColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AlterColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AlterColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ColumnSpec>(1, _omitFieldNames ? '' : 'before',
        subBuilder: ColumnSpec.create)
    ..aOM<ColumnSpec>(2, _omitFieldNames ? '' : 'after',
        subBuilder: ColumnSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlterColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlterColumn copyWith(void Function(AlterColumn) updates) =>
      super.copyWith((message) => updates(message as AlterColumn))
          as AlterColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AlterColumn create() => AlterColumn._();
  @$core.override
  AlterColumn createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AlterColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AlterColumn>(create);
  static AlterColumn? _defaultInstance;

  /// Definition as it is now.
  @$pb.TagNumber(1)
  ColumnSpec get before => $_getN(0);
  @$pb.TagNumber(1)
  set before(ColumnSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBefore() => $_has(0);
  @$pb.TagNumber(1)
  void clearBefore() => $_clearField(1);
  @$pb.TagNumber(1)
  ColumnSpec ensureBefore() => $_ensure(0);

  /// Definition wanted; the builder emits only what differs.
  @$pb.TagNumber(2)
  ColumnSpec get after => $_getN(1);
  @$pb.TagNumber(2)
  set after(ColumnSpec value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAfter() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfter() => $_clearField(2);
  @$pb.TagNumber(2)
  ColumnSpec ensureAfter() => $_ensure(1);
}

/// AddForeignKey adds a foreign key.
class AddForeignKey extends $pb.GeneratedMessage {
  factory AddForeignKey({
    ForeignKeySpec? foreignKey,
  }) {
    final result = create();
    if (foreignKey != null) result.foreignKey = foreignKey;
    return result;
  }

  AddForeignKey._();

  factory AddForeignKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddForeignKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddForeignKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<ForeignKeySpec>(1, _omitFieldNames ? '' : 'foreignKey',
        subBuilder: ForeignKeySpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddForeignKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddForeignKey copyWith(void Function(AddForeignKey) updates) =>
      super.copyWith((message) => updates(message as AddForeignKey))
          as AddForeignKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddForeignKey create() => AddForeignKey._();
  @$core.override
  AddForeignKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddForeignKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddForeignKey>(create);
  static AddForeignKey? _defaultInstance;

  /// Definition.
  @$pb.TagNumber(1)
  ForeignKeySpec get foreignKey => $_getN(0);
  @$pb.TagNumber(1)
  set foreignKey(ForeignKeySpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasForeignKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearForeignKey() => $_clearField(1);
  @$pb.TagNumber(1)
  ForeignKeySpec ensureForeignKey() => $_ensure(0);
}

/// AddUnique adds a unique constraint.
class AddUnique extends $pb.GeneratedMessage {
  factory AddUnique({
    UniqueSpec? unique,
  }) {
    final result = create();
    if (unique != null) result.unique = unique;
    return result;
  }

  AddUnique._();

  factory AddUnique.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddUnique.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddUnique',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<UniqueSpec>(1, _omitFieldNames ? '' : 'unique',
        subBuilder: UniqueSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddUnique clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddUnique copyWith(void Function(AddUnique) updates) =>
      super.copyWith((message) => updates(message as AddUnique)) as AddUnique;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddUnique create() => AddUnique._();
  @$core.override
  AddUnique createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddUnique getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddUnique>(create);
  static AddUnique? _defaultInstance;

  /// Definition.
  @$pb.TagNumber(1)
  UniqueSpec get unique => $_getN(0);
  @$pb.TagNumber(1)
  set unique(UniqueSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUnique() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnique() => $_clearField(1);
  @$pb.TagNumber(1)
  UniqueSpec ensureUnique() => $_ensure(0);
}

/// AddCheck adds a check constraint.
class AddCheck extends $pb.GeneratedMessage {
  factory AddCheck({
    CheckSpec? check_1,
  }) {
    final result = create();
    if (check_1 != null) result.check_1 = check_1;
    return result;
  }

  AddCheck._();

  factory AddCheck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddCheck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddCheck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<CheckSpec>(1, _omitFieldNames ? '' : 'check',
        subBuilder: CheckSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddCheck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddCheck copyWith(void Function(AddCheck) updates) =>
      super.copyWith((message) => updates(message as AddCheck)) as AddCheck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddCheck create() => AddCheck._();
  @$core.override
  AddCheck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddCheck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddCheck>(create);
  static AddCheck? _defaultInstance;

  /// Definition.
  @$pb.TagNumber(1)
  CheckSpec get check_1 => $_getN(0);
  @$pb.TagNumber(1)
  set check_1(CheckSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCheck_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearCheck_1() => $_clearField(1);
  @$pb.TagNumber(1)
  CheckSpec ensureCheck_1() => $_ensure(0);
}

/// DropConstraint drops a foreign key, unique or check constraint by name.
class DropConstraint extends $pb.GeneratedMessage {
  factory DropConstraint({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  DropConstraint._();

  factory DropConstraint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropConstraint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropConstraint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropConstraint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropConstraint copyWith(void Function(DropConstraint) updates) =>
      super.copyWith((message) => updates(message as DropConstraint))
          as DropConstraint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropConstraint create() => DropConstraint._();
  @$core.override
  DropConstraint createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropConstraint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropConstraint>(create);
  static DropConstraint? _defaultInstance;

  /// Constraint name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// AddIndex adds a secondary index.
class AddIndex extends $pb.GeneratedMessage {
  factory AddIndex({
    $2.IndexSpec? index,
  }) {
    final result = create();
    if (index != null) result.index = index;
    return result;
  }

  AddIndex._();

  factory AddIndex.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddIndex.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddIndex',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOM<$2.IndexSpec>(1, _omitFieldNames ? '' : 'index',
        subBuilder: $2.IndexSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddIndex clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddIndex copyWith(void Function(AddIndex) updates) =>
      super.copyWith((message) => updates(message as AddIndex)) as AddIndex;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddIndex create() => AddIndex._();
  @$core.override
  AddIndex createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddIndex getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddIndex>(create);
  static AddIndex? _defaultInstance;

  /// Definition.
  @$pb.TagNumber(1)
  $2.IndexSpec get index => $_getN(0);
  @$pb.TagNumber(1)
  set index($2.IndexSpec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.IndexSpec ensureIndex() => $_ensure(0);
}

/// DropIndexChange drops a secondary index.
class DropIndexChange extends $pb.GeneratedMessage {
  factory DropIndexChange({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  DropIndexChange._();

  factory DropIndexChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropIndexChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropIndexChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropIndexChange copyWith(void Function(DropIndexChange) updates) =>
      super.copyWith((message) => updates(message as DropIndexChange))
          as DropIndexChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropIndexChange create() => DropIndexChange._();
  @$core.override
  DropIndexChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropIndexChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropIndexChange>(create);
  static DropIndexChange? _defaultInstance;

  /// Index name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

enum SchemaChange_Change {
  createTable,
  dropTable,
  renameTable,
  addColumn,
  dropColumn,
  renameColumn,
  alterColumn,
  addForeignKey,
  addUnique,
  addCheck,
  dropConstraint,
  addIndex,
  dropIndex,
  notSet
}

/// SchemaChange is one step of a design, applied in the order sent.
class SchemaChange extends $pb.GeneratedMessage {
  factory SchemaChange({
    CreateTable? createTable,
    DropTable? dropTable,
    RenameTable? renameTable,
    AddColumn? addColumn,
    DropColumn? dropColumn,
    RenameColumn? renameColumn,
    AlterColumn? alterColumn,
    AddForeignKey? addForeignKey,
    AddUnique? addUnique,
    AddCheck? addCheck,
    DropConstraint? dropConstraint,
    AddIndex? addIndex,
    DropIndexChange? dropIndex,
  }) {
    final result = create();
    if (createTable != null) result.createTable = createTable;
    if (dropTable != null) result.dropTable = dropTable;
    if (renameTable != null) result.renameTable = renameTable;
    if (addColumn != null) result.addColumn = addColumn;
    if (dropColumn != null) result.dropColumn = dropColumn;
    if (renameColumn != null) result.renameColumn = renameColumn;
    if (alterColumn != null) result.alterColumn = alterColumn;
    if (addForeignKey != null) result.addForeignKey = addForeignKey;
    if (addUnique != null) result.addUnique = addUnique;
    if (addCheck != null) result.addCheck = addCheck;
    if (dropConstraint != null) result.dropConstraint = dropConstraint;
    if (addIndex != null) result.addIndex = addIndex;
    if (dropIndex != null) result.dropIndex = dropIndex;
    return result;
  }

  SchemaChange._();

  factory SchemaChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SchemaChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SchemaChange_Change>
      _SchemaChange_ChangeByTag = {
    1: SchemaChange_Change.createTable,
    2: SchemaChange_Change.dropTable,
    3: SchemaChange_Change.renameTable,
    4: SchemaChange_Change.addColumn,
    5: SchemaChange_Change.dropColumn,
    6: SchemaChange_Change.renameColumn,
    7: SchemaChange_Change.alterColumn,
    8: SchemaChange_Change.addForeignKey,
    9: SchemaChange_Change.addUnique,
    10: SchemaChange_Change.addCheck,
    11: SchemaChange_Change.dropConstraint,
    12: SchemaChange_Change.addIndex,
    13: SchemaChange_Change.dropIndex,
    0: SchemaChange_Change.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SchemaChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ..aOM<CreateTable>(1, _omitFieldNames ? '' : 'createTable',
        subBuilder: CreateTable.create)
    ..aOM<DropTable>(2, _omitFieldNames ? '' : 'dropTable',
        subBuilder: DropTable.create)
    ..aOM<RenameTable>(3, _omitFieldNames ? '' : 'renameTable',
        subBuilder: RenameTable.create)
    ..aOM<AddColumn>(4, _omitFieldNames ? '' : 'addColumn',
        subBuilder: AddColumn.create)
    ..aOM<DropColumn>(5, _omitFieldNames ? '' : 'dropColumn',
        subBuilder: DropColumn.create)
    ..aOM<RenameColumn>(6, _omitFieldNames ? '' : 'renameColumn',
        subBuilder: RenameColumn.create)
    ..aOM<AlterColumn>(7, _omitFieldNames ? '' : 'alterColumn',
        subBuilder: AlterColumn.create)
    ..aOM<AddForeignKey>(8, _omitFieldNames ? '' : 'addForeignKey',
        subBuilder: AddForeignKey.create)
    ..aOM<AddUnique>(9, _omitFieldNames ? '' : 'addUnique',
        subBuilder: AddUnique.create)
    ..aOM<AddCheck>(10, _omitFieldNames ? '' : 'addCheck',
        subBuilder: AddCheck.create)
    ..aOM<DropConstraint>(11, _omitFieldNames ? '' : 'dropConstraint',
        subBuilder: DropConstraint.create)
    ..aOM<AddIndex>(12, _omitFieldNames ? '' : 'addIndex',
        subBuilder: AddIndex.create)
    ..aOM<DropIndexChange>(13, _omitFieldNames ? '' : 'dropIndex',
        subBuilder: DropIndexChange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaChange copyWith(void Function(SchemaChange) updates) =>
      super.copyWith((message) => updates(message as SchemaChange))
          as SchemaChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchemaChange create() => SchemaChange._();
  @$core.override
  SchemaChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SchemaChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SchemaChange>(create);
  static SchemaChange? _defaultInstance;

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
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  SchemaChange_Change whichChange() =>
      _SchemaChange_ChangeByTag[$_whichOneof(0)]!;
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
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  void clearChange() => $_clearField($_whichOneof(0));

  /// Create the table.
  @$pb.TagNumber(1)
  CreateTable get createTable => $_getN(0);
  @$pb.TagNumber(1)
  set createTable(CreateTable value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCreateTable() => $_has(0);
  @$pb.TagNumber(1)
  void clearCreateTable() => $_clearField(1);
  @$pb.TagNumber(1)
  CreateTable ensureCreateTable() => $_ensure(0);

  /// Drop the table.
  @$pb.TagNumber(2)
  DropTable get dropTable => $_getN(1);
  @$pb.TagNumber(2)
  set dropTable(DropTable value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDropTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearDropTable() => $_clearField(2);
  @$pb.TagNumber(2)
  DropTable ensureDropTable() => $_ensure(1);

  /// Rename the table.
  @$pb.TagNumber(3)
  RenameTable get renameTable => $_getN(2);
  @$pb.TagNumber(3)
  set renameTable(RenameTable value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRenameTable() => $_has(2);
  @$pb.TagNumber(3)
  void clearRenameTable() => $_clearField(3);
  @$pb.TagNumber(3)
  RenameTable ensureRenameTable() => $_ensure(2);

  /// Add a column.
  @$pb.TagNumber(4)
  AddColumn get addColumn => $_getN(3);
  @$pb.TagNumber(4)
  set addColumn(AddColumn value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAddColumn() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddColumn() => $_clearField(4);
  @$pb.TagNumber(4)
  AddColumn ensureAddColumn() => $_ensure(3);

  /// Drop a column.
  @$pb.TagNumber(5)
  DropColumn get dropColumn => $_getN(4);
  @$pb.TagNumber(5)
  set dropColumn(DropColumn value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDropColumn() => $_has(4);
  @$pb.TagNumber(5)
  void clearDropColumn() => $_clearField(5);
  @$pb.TagNumber(5)
  DropColumn ensureDropColumn() => $_ensure(4);

  /// Rename a column.
  @$pb.TagNumber(6)
  RenameColumn get renameColumn => $_getN(5);
  @$pb.TagNumber(6)
  set renameColumn(RenameColumn value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRenameColumn() => $_has(5);
  @$pb.TagNumber(6)
  void clearRenameColumn() => $_clearField(6);
  @$pb.TagNumber(6)
  RenameColumn ensureRenameColumn() => $_ensure(5);

  /// Alter a column.
  @$pb.TagNumber(7)
  AlterColumn get alterColumn => $_getN(6);
  @$pb.TagNumber(7)
  set alterColumn(AlterColumn value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAlterColumn() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlterColumn() => $_clearField(7);
  @$pb.TagNumber(7)
  AlterColumn ensureAlterColumn() => $_ensure(6);

  /// Add a foreign key.
  @$pb.TagNumber(8)
  AddForeignKey get addForeignKey => $_getN(7);
  @$pb.TagNumber(8)
  set addForeignKey(AddForeignKey value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAddForeignKey() => $_has(7);
  @$pb.TagNumber(8)
  void clearAddForeignKey() => $_clearField(8);
  @$pb.TagNumber(8)
  AddForeignKey ensureAddForeignKey() => $_ensure(7);

  /// Add a unique constraint.
  @$pb.TagNumber(9)
  AddUnique get addUnique => $_getN(8);
  @$pb.TagNumber(9)
  set addUnique(AddUnique value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAddUnique() => $_has(8);
  @$pb.TagNumber(9)
  void clearAddUnique() => $_clearField(9);
  @$pb.TagNumber(9)
  AddUnique ensureAddUnique() => $_ensure(8);

  /// Add a check constraint.
  @$pb.TagNumber(10)
  AddCheck get addCheck => $_getN(9);
  @$pb.TagNumber(10)
  set addCheck(AddCheck value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAddCheck() => $_has(9);
  @$pb.TagNumber(10)
  void clearAddCheck() => $_clearField(10);
  @$pb.TagNumber(10)
  AddCheck ensureAddCheck() => $_ensure(9);

  /// Drop a constraint by name.
  @$pb.TagNumber(11)
  DropConstraint get dropConstraint => $_getN(10);
  @$pb.TagNumber(11)
  set dropConstraint(DropConstraint value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasDropConstraint() => $_has(10);
  @$pb.TagNumber(11)
  void clearDropConstraint() => $_clearField(11);
  @$pb.TagNumber(11)
  DropConstraint ensureDropConstraint() => $_ensure(10);

  /// Add an index.
  @$pb.TagNumber(12)
  AddIndex get addIndex => $_getN(11);
  @$pb.TagNumber(12)
  set addIndex(AddIndex value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAddIndex() => $_has(11);
  @$pb.TagNumber(12)
  void clearAddIndex() => $_clearField(12);
  @$pb.TagNumber(12)
  AddIndex ensureAddIndex() => $_ensure(11);

  /// Drop an index.
  @$pb.TagNumber(13)
  DropIndexChange get dropIndex => $_getN(12);
  @$pb.TagNumber(13)
  set dropIndex(DropIndexChange value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasDropIndex() => $_has(12);
  @$pb.TagNumber(13)
  void clearDropIndex() => $_clearField(13);
  @$pb.TagNumber(13)
  DropIndexChange ensureDropIndex() => $_ensure(12);
}

/// DdlStatement is one statement of the generated script.
class DdlStatement extends $pb.GeneratedMessage {
  factory DdlStatement({
    $core.String? sql,
    $core.bool? destructive,
    $core.String? summary,
  }) {
    final result = create();
    if (sql != null) result.sql = sql;
    if (destructive != null) result.destructive = destructive;
    if (summary != null) result.summary = summary;
    return result;
  }

  DdlStatement._();

  factory DdlStatement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DdlStatement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DdlStatement',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sql')
    ..aOB(2, _omitFieldNames ? '' : 'destructive')
    ..aOS(3, _omitFieldNames ? '' : 'summary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DdlStatement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DdlStatement copyWith(void Function(DdlStatement) updates) =>
      super.copyWith((message) => updates(message as DdlStatement))
          as DdlStatement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DdlStatement create() => DdlStatement._();
  @$core.override
  DdlStatement createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DdlStatement getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DdlStatement>(create);
  static DdlStatement? _defaultInstance;

  /// SQL text, ending with a semicolon.
  @$pb.TagNumber(1)
  $core.String get sql => $_getSZ(0);
  @$pb.TagNumber(1)
  set sql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearSql() => $_clearField(1);

  /// True if the statement can lose data or structure (drop, type narrowing); needs confirmed=true.
  @$pb.TagNumber(2)
  $core.bool get destructive => $_getBF(1);
  @$pb.TagNumber(2)
  set destructive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestructive() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestructive() => $_clearField(2);

  /// Short description for the preview list, for example "Add column email".
  @$pb.TagNumber(3)
  $core.String get summary => $_getSZ(2);
  @$pb.TagNumber(3)
  set summary($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummary() => $_clearField(3);
}

/// PreviewDDLRequest asks what DDL the changes produce.
class PreviewDDLRequest extends $pb.GeneratedMessage {
  factory PreviewDDLRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
    $core.Iterable<SchemaChange>? changes,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (changes != null) result.changes.addAll(changes);
    return result;
  }

  PreviewDDLRequest._();

  factory PreviewDDLRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewDDLRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewDDLRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..pPM<SchemaChange>(3, _omitFieldNames ? '' : 'changes',
        subBuilder: SchemaChange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDDLRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDDLRequest copyWith(void Function(PreviewDDLRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewDDLRequest))
          as PreviewDDLRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewDDLRequest create() => PreviewDDLRequest._();
  @$core.override
  PreviewDDLRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewDDLRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewDDLRequest>(create);
  static PreviewDDLRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Target table (the new table's name for CreateTable).
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

  /// Steps in order.
  @$pb.TagNumber(3)
  $pb.PbList<SchemaChange> get changes => $_getList(2);
}

/// PreviewDDLResponse lists the statements and warnings.
class PreviewDDLResponse extends $pb.GeneratedMessage {
  factory PreviewDDLResponse({
    $core.Iterable<DdlStatement>? statements,
    $core.Iterable<$core.String>? warnings,
    $core.bool? transactional,
    $3.AdminError? error,
  }) {
    final result = create();
    if (statements != null) result.statements.addAll(statements);
    if (warnings != null) result.warnings.addAll(warnings);
    if (transactional != null) result.transactional = transactional;
    if (error != null) result.error = error;
    return result;
  }

  PreviewDDLResponse._();

  factory PreviewDDLResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewDDLResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewDDLResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<DdlStatement>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: DdlStatement.create)
    ..pPS(2, _omitFieldNames ? '' : 'warnings')
    ..aOB(3, _omitFieldNames ? '' : 'transactional')
    ..aOM<$3.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $3.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDDLResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewDDLResponse copyWith(void Function(PreviewDDLResponse) updates) =>
      super.copyWith((message) => updates(message as PreviewDDLResponse))
          as PreviewDDLResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewDDLResponse create() => PreviewDDLResponse._();
  @$core.override
  PreviewDDLResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewDDLResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewDDLResponse>(create);
  static PreviewDDLResponse? _defaultInstance;

  /// Statements in execution order.
  @$pb.TagNumber(1)
  $pb.PbList<DdlStatement> get statements => $_getList(0);

  /// Cautions, for example that the engine commits DDL implicitly or that an alter needs a table rebuild.
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
  $3.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($3.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.AdminError ensureError() => $_ensure(3);
}

/// ApplyDDLRequest asks to run the DDL for the changes.
class ApplyDDLRequest extends $pb.GeneratedMessage {
  factory ApplyDDLRequest({
    $core.String? sessionId,
    $1.TableRef? tableRef,
    $core.Iterable<SchemaChange>? changes,
    $core.bool? confirmed,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (tableRef != null) result.tableRef = tableRef;
    if (changes != null) result.changes.addAll(changes);
    if (confirmed != null) result.confirmed = confirmed;
    return result;
  }

  ApplyDDLRequest._();

  factory ApplyDDLRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyDDLRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyDDLRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.TableRef>(2, _omitFieldNames ? '' : 'tableRef',
        subBuilder: $1.TableRef.create)
    ..pPM<SchemaChange>(3, _omitFieldNames ? '' : 'changes',
        subBuilder: SchemaChange.create)
    ..aOB(4, _omitFieldNames ? '' : 'confirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDDLRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDDLRequest copyWith(void Function(ApplyDDLRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyDDLRequest))
          as ApplyDDLRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyDDLRequest create() => ApplyDDLRequest._();
  @$core.override
  ApplyDDLRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyDDLRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyDDLRequest>(create);
  static ApplyDDLRequest? _defaultInstance;

  /// Session id from SessionService.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Target table.
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

  /// Steps in order.
  @$pb.TagNumber(3)
  $pb.PbList<SchemaChange> get changes => $_getList(2);

  /// Required when any statement is destructive, and always on connections flagged production.
  @$pb.TagNumber(4)
  $core.bool get confirmed => $_getBF(3);
  @$pb.TagNumber(4)
  set confirmed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfirmed() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfirmed() => $_clearField(4);
}

/// ApplyDDLResponse reports what ran.
class ApplyDDLResponse extends $pb.GeneratedMessage {
  factory ApplyDDLResponse({
    $core.Iterable<DdlStatement>? statements,
    $core.int? executedStatements,
    $core.bool? transactional,
    $3.AdminError? error,
  }) {
    final result = create();
    if (statements != null) result.statements.addAll(statements);
    if (executedStatements != null)
      result.executedStatements = executedStatements;
    if (transactional != null) result.transactional = transactional;
    if (error != null) result.error = error;
    return result;
  }

  ApplyDDLResponse._();

  factory ApplyDDLResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyDDLResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyDDLResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'queravue.v1'),
      createEmptyInstance: create)
    ..pPM<DdlStatement>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: DdlStatement.create)
    ..aI(2, _omitFieldNames ? '' : 'executedStatements',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'transactional')
    ..aOM<$3.AdminError>(4, _omitFieldNames ? '' : 'error',
        subBuilder: $3.AdminError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDDLResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyDDLResponse copyWith(void Function(ApplyDDLResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyDDLResponse))
          as ApplyDDLResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyDDLResponse create() => ApplyDDLResponse._();
  @$core.override
  ApplyDDLResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyDDLResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyDDLResponse>(create);
  static ApplyDDLResponse? _defaultInstance;

  /// The statements that were run, in order.
  @$pb.TagNumber(1)
  $pb.PbList<DdlStatement> get statements => $_getList(0);

  /// How many statements completed. Less than the list length means the run stopped on error; on engines that commit DDL implicitly those statements stay applied.
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
  $3.AdminError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error($3.AdminError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.AdminError ensureError() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
