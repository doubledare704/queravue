import 'package:flutter/foundation.dart';

import '../../schema/domain/schema_models.dart';

@immutable
class DiagramColumn {
  const DiagramColumn({
    required this.name,
    this.typeName = '',
    this.nullable = true,
    this.primaryKeyOrder = 0,
    this.draft = false,
  });

  final String name;
  final String typeName;
  final bool nullable;

  /// Designed on the diagram and not in the database yet.
  final bool draft;

  /// 1-based position in the primary key; 0 when not part of it.
  final int primaryKeyOrder;

  bool get isPrimaryKey => primaryKeyOrder > 0;
}

@immutable
class DiagramRelation {
  const DiagramRelation({
    required this.columns,
    required this.referencedTable,
    this.name = '',
    this.referencedSchema = '',
    this.referencedColumns = const [],
    this.inferred = false,
    this.confidence = 0,
    this.draft = false,
  });

  final String name;
  final List<String> columns;
  final String referencedSchema;
  final String referencedTable;
  final List<String> referencedColumns;

  /// Guessed by core from sampled documents; no constraint backs it.
  final bool inferred;

  /// How sure the guess of an [inferred] relation is, in (0, 1].
  final double confidence;
  final bool draft;
}

@immutable
class DiagramTable {
  const DiagramTable({
    required this.name,
    this.type = SchemaObjectType.table,
    this.rowEstimate = -1,
    this.columns = const [],
    this.relations = const [],
    this.columnsTruncated = false,
    this.draft = false,
  });

  final String name;
  final SchemaObjectType type;
  final int rowEstimate;
  final List<DiagramColumn> columns;
  final List<DiagramRelation> relations;
  final bool columnsTruncated;
  final bool draft;

  bool get isView =>
      type == SchemaObjectType.view ||
      type == SchemaObjectType.materializedView;

  DiagramColumn? column(String name) =>
      columns.where((c) => c.name == name).firstOrNull;

  List<DiagramColumn> get primaryKey =>
      columns.where((c) => c.isPrimaryKey).toList()
        ..sort((a, b) => a.primaryKeyOrder.compareTo(b.primaryKeyOrder));

  bool isForeignKeyColumn(String column) =>
      relations.any((r) => r.columns.contains(column));
}

@immutable
class SchemaGraph {
  const SchemaGraph(this.tables);

  final List<DiagramTable> tables;

  int get relationCount =>
      tables.fold(0, (sum, table) => sum + table.relations.length);

  int get inferredRelationCount => tables.fold(
    0,
    (sum, table) => sum + table.relations.where((r) => r.inferred).length,
  );

  SchemaGraph withoutInferredRelations() => SchemaGraph([
    for (final t in tables)
      t.relations.any((r) => r.inferred)
          ? DiagramTable(
              name: t.name,
              type: t.type,
              rowEstimate: t.rowEstimate,
              columns: t.columns,
              relations: [
                for (final r in t.relations)
                  if (!r.inferred) r,
              ],
              columnsTruncated: t.columnsTruncated,
              draft: t.draft,
            )
          : t,
  ]);
}

/// One message of a graph being loaded.
@immutable
class GraphBatch {
  const GraphBatch({
    this.tables = const [],
    this.tablesDone = 0,
    this.tablesTotal = 0,
  });

  final List<DiagramTable> tables;
  final int tablesDone;
  final int tablesTotal;
}

/// Why a graph could not be loaded, in words for the user.
class DiagramFailure implements Exception {
  const DiagramFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
