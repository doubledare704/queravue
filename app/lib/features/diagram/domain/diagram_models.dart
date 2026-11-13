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
    this.externalSchema = '',
  });

  /// The table's name; `schema.table` for a table in another schema.
  final String name;
  final SchemaObjectType type;
  final int rowEstimate;
  final List<DiagramColumn> columns;
  final List<DiagramRelation> relations;
  final bool columnsTruncated;
  final bool draft;

  /// Set for a table of another schema that this schema references. Only
  /// the referenced columns are known.
  final String externalSchema;

  bool get isExternal => externalSchema.isNotEmpty;

  /// The name inside its own schema.
  String get localName =>
      isExternal ? name.substring(externalSchema.length + 1) : name;

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

  int get localTableCount => tables.where((t) => !t.isExternal).length;

  int get externalRelationCount => tables.fold(
    0,
    (sum, table) =>
        sum +
        table.relations.where((r) => r.referencedSchema.isNotEmpty).length,
  );

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
              externalSchema: t.externalSchema,
            )
          : t,
  ]);
}

/// [graph] with a box for every table of another schema it references, named
/// `schema.table`, and its relations pointing at those boxes. Core leaves
/// `referencedSchema` empty for the diagram's own schema.
SchemaGraph withExternalTables(SchemaGraph graph) {
  final referenced = <String, (String, Set<String>)>{};
  String keyOf(DiagramRelation r) =>
      '${r.referencedSchema}.${r.referencedTable}';
  final tables = [
    for (final t in graph.tables)
      t.relations.every((r) => r.referencedSchema.isEmpty)
          ? t
          : DiagramTable(
              name: t.name,
              type: t.type,
              rowEstimate: t.rowEstimate,
              columns: t.columns,
              relations: [
                for (final r in t.relations)
                  if (r.referencedSchema.isEmpty)
                    r
                  else
                    DiagramRelation(
                      name: r.name,
                      columns: r.columns,
                      referencedSchema: r.referencedSchema,
                      referencedTable: keyOf(r),
                      referencedColumns: r.referencedColumns,
                      inferred: r.inferred,
                      confidence: r.confidence,
                    ),
              ],
              columnsTruncated: t.columnsTruncated,
              draft: t.draft,
            ),
  ];
  for (final t in graph.tables) {
    for (final r in t.relations) {
      if (r.referencedSchema.isEmpty) continue;
      final (_, columns) = referenced.putIfAbsent(
        keyOf(r),
        () => (r.referencedSchema, <String>{}),
      );
      columns.addAll(r.referencedColumns);
    }
  }
  if (referenced.isEmpty) return graph;
  final local = {for (final t in graph.tables) t.name};
  final keys = referenced.keys.where((k) => !local.contains(k)).toList()
    ..sort();
  return SchemaGraph([
    ...tables,
    for (final key in keys)
      DiagramTable(
        name: key,
        externalSchema: referenced[key]!.$1,
        columns: [
          for (final c in referenced[key]!.$2)
            DiagramColumn(name: c, nullable: false),
        ],
      ),
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
