import 'dart:async';

import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/designer/domain/design_models.dart';
import 'package:queravue/features/diagram/data/diagram_repository.dart';
import 'package:queravue/features/diagram/domain/diagram_draft.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';

DiagramTable table(
  String name, {
  List<String> columns = const ['id'],
  Map<String, String> references = const {},
}) => DiagramTable(
  name: name,
  columns: [
    for (final c in columns)
      DiagramColumn(
        name: c,
        typeName: 'int',
        nullable: c != 'id',
        primaryKeyOrder: c == 'id' ? 1 : 0,
      ),
  ],
  relations: [
    for (final e in references.entries)
      DiagramRelation(
        name: 'fk_${name}_${e.key}',
        columns: [e.key],
        referencedTable: e.value,
        referencedColumns: const ['id'],
      ),
  ],
);

/// Twenty base tables and children that each reference one of them, like the
/// large PostgreSQL seed.
SchemaGraph generatedGraph(int tables) => SchemaGraph([
  for (var i = 0; i < tables; i++)
    table(
      't${i.toString().padLeft(3, '0')}',
      columns: ['id', 'parent_id', for (var c = 0; c < 13; c++) 'column_$c'],
      references: i < 20
          ? const {}
          : {'parent_id': 't${(i % 20).toString().padLeft(3, '0')}'},
    ),
]);

class FakeDiagramRepository implements DiagramRepository {
  FakeDiagramRepository([this.graph = const SchemaGraph([])]);

  SchemaGraph graph;
  String? failure;
  int batchSize = 50;

  /// When set, the stream sends its batches and then waits for this.
  Completer<void>? hold;
  final requests = <({String database, String schema, bool refresh})>[];
  int cancelled = 0;

  /// Every DDL request: the tables and whether it was an apply.
  final ddl =
      <({List<TableChangesModel> tables, bool apply, bool confirmed})>[];
  AdminError? ddlError;

  List<DdlStatementModel> _statements(List<TableChangesModel> tables) => [
    for (final t in tables)
      for (final c in t.changes)
        DdlStatementModel(
          sql: '-- ${c.runtimeType} ${t.table.table}',
          destructive: false,
          summary: switch (c) {
            CreateTableChange() => 'Create table ${t.table.table}',
            AddColumnChange() =>
              'Add column ${c.column.name} on ${t.table.table}',
            AddForeignKeyChange() =>
              'Add foreign key ${c.foreignKey.name} on ${t.table.table}',
            _ => '${c.runtimeType} on ${t.table.table}',
          },
        ),
  ];

  @override
  Future<AdminResult<DdlPreview>> previewDdl(
    String sessionId,
    List<TableChangesModel> tables,
  ) async {
    ddl.add((tables: tables, apply: false, confirmed: false));
    if (ddlError != null) return AdminResult.failed(ddlError!);
    return AdminResult.ok(DdlPreview(statements: _statements(tables)));
  }

  /// Applies the changes to [graph], as the database would.
  @override
  Future<AdminResult<DdlApplied>> applyDdl(
    String sessionId,
    List<TableChangesModel> tables, {
    bool confirmed = false,
  }) async {
    ddl.add((tables: tables, apply: true, confirmed: confirmed));
    if (ddlError != null) return AdminResult.failed(ddlError!);
    final byName = {for (final t in graph.tables) t.name: t};
    for (final t in tables) {
      for (final c in t.changes) {
        final name = t.table.table;
        final current = byName[name];
        switch (c) {
          case CreateTableChange():
            var order = 0;
            byName[name] = DiagramTable(
              name: name,
              columns: [
                for (final col in c.columns)
                  DiagramColumn(
                    name: col.name,
                    typeName: col.typeName,
                    nullable: col.nullable,
                    primaryKeyOrder: col.primaryKey ? ++order : 0,
                  ),
              ],
              relations: [
                for (final f in c.constraints.foreignKeys) _relation(f),
              ],
            );
          case AddColumnChange() when current != null:
            byName[name] = DiagramTable(
              name: name,
              columns: [
                ...current.columns,
                DiagramColumn(name: c.column.name, typeName: c.column.typeName),
              ],
              relations: current.relations,
            );
          case AddForeignKeyChange() when current != null:
            byName[name] = DiagramTable(
              name: name,
              columns: current.columns,
              relations: [...current.relations, _relation(c.foreignKey)],
            );
          default:
        }
      }
    }
    graph = SchemaGraph(byName.values.toList());
    final statements = _statements(tables);
    return AdminResult.ok(
      DdlApplied(
        statements: statements,
        executed: statements.length,
        transactional: true,
      ),
    );
  }

  DiagramRelation _relation(ForeignKeyDraft f) => DiagramRelation(
    name: f.name,
    columns: f.columns,
    referencedTable: f.referencedTable,
    referencedColumns: f.referencedColumns,
  );

  @override
  Stream<GraphBatch> loadGraph({
    required String sessionId,
    String database = '',
    String schema = '',
    bool refresh = false,
  }) {
    requests.add((database: database, schema: schema, refresh: refresh));
    late final StreamController<GraphBatch> out;
    Future<void> run() async {
      if (failure != null) {
        out.addError(DiagramFailure(failure!));
        return out.close();
      }
      final all = graph.tables;
      for (var at = 0; at < all.length; at += batchSize) {
        final end = at + batchSize > all.length ? all.length : at + batchSize;
        out.add(
          GraphBatch(
            tables: all.sublist(at, end),
            tablesDone: end,
            tablesTotal: all.length,
          ),
        );
      }
      await hold?.future;
      if (!out.isClosed) await out.close();
    }

    out = StreamController<GraphBatch>(
      onListen: () => unawaited(run()),
      onCancel: () => cancelled++,
    );
    return out.stream;
  }
}
