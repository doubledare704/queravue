import 'dart:async';

import 'package:queravue/features/diagram/data/diagram_repository.dart';
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
