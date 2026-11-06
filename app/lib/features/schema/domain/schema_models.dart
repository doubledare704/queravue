import 'package:flutter/foundation.dart';

import '../../editor/domain/query_models.dart';

/// Classifies a database object.
enum SchemaObjectType {
  table,
  view,
  materializedView,

  /// Document collection (MongoDB and compatible).
  collection,

  /// Time series collection.
  timeSeries;

  bool get isCollection =>
      this == SchemaObjectType.collection ||
      this == SchemaObjectType.timeSeries;
  bool get isTable => this == SchemaObjectType.table;
  bool get isView => this == SchemaObjectType.view;
  bool get isMaterializedView => this == SchemaObjectType.materializedView;
}

/// Identifies a table or view within a connection.
@immutable
class TableRef {
  const TableRef({this.database = '', this.schema = '', required this.table});

  final String database;
  final String schema;
  final String table;

  String get qualifiedName {
    if (schema.isNotEmpty && schema != 'main') {
      return '$schema.$table';
    }
    return table;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableRef &&
          database == other.database &&
          schema == other.schema &&
          table == other.table;

  @override
  int get hashCode => Object.hash(database, schema, table);

  @override
  String toString() => qualifiedName;
}

/// Represents an item in the schema objects list.
@immutable
class SchemaObject {
  const SchemaObject({
    required this.name,
    required this.type,
    this.rowCountEstimate = -1,
    this.capped = false,
  });

  final String name;
  final SchemaObjectType type;
  final int rowCountEstimate;

  /// True for capped collections.
  final bool capped;
}

/// Describes one column of a table.
@immutable
class ColumnDetails {
  const ColumnDetails({
    required this.name,
    required this.typeName,
    required this.kind,
    required this.nullable,
    this.defaultValue,
    required this.isPrimaryKey,
    this.primaryKeyOrder = 0,
  });

  final String name;
  final String typeName;
  final ColumnKind kind;
  final bool nullable;
  final String? defaultValue;
  final bool isPrimaryKey;
  final int primaryKeyOrder;
}

/// Describes an index on a table.
@immutable
class IndexDetails {
  const IndexDetails({
    required this.name,
    required this.columns,
    required this.isUnique,
    required this.isPrimary,
  });

  final String name;
  final List<String> columns;
  final bool isUnique;
  final bool isPrimary;
}

/// Describes a foreign key constraint.
@immutable
class ForeignKeyDetails {
  const ForeignKeyDetails({
    required this.name,
    required this.columns,
    required this.referencedSchema,
    required this.referencedTable,
    required this.referencedColumns,
  });

  final String name;
  final List<String> columns;
  final String referencedSchema;
  final String referencedTable;
  final List<String> referencedColumns;
}

/// Detailed schema metadata for a table or view.
@immutable
class TableDetails {
  const TableDetails({
    required this.tableRef,
    required this.type,
    this.columns = const [],
    this.indexes = const [],
    this.foreignKeys = const [],
    this.rowCountEstimate = -1,
    required this.canEdit,
    this.editDisabledReason,
  });

  final TableRef tableRef;
  final SchemaObjectType type;
  final List<ColumnDetails> columns;
  final List<IndexDetails> indexes;
  final List<ForeignKeyDetails> foreignKeys;
  final int rowCountEstimate;
  final bool canEdit;
  final String? editDisabledReason;

  List<ColumnDetails> get primaryKeyColumns =>
      columns.where((c) => c.isPrimaryKey).toList();
}
