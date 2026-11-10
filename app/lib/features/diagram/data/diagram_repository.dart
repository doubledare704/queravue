import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/diagram.pbgrpc.dart' as pb;
import '../../../core_client/gen/queravue/v1/schema.pb.dart' as spb;
import '../../schema/domain/schema_models.dart';
import '../domain/diagram_models.dart';

/// Schema graphs through the core.
abstract interface class DiagramRepository {
  /// Streams the tables of a schema in batches. Cancelling the subscription
  /// stops the load in the core. Errors are [DiagramFailure]s.
  Stream<GraphBatch> loadGraph({
    required String sessionId,
    String database,
    String schema,
    bool refresh,
  });
}

final diagramRepositoryProvider = Provider<DiagramRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcDiagramRepository(() => supervisor.connection);
});

class GrpcDiagramRepository implements DiagramRepository {
  GrpcDiagramRepository(this._connection);

  final CoreConnection? Function() _connection;

  @override
  Stream<GraphBatch> loadGraph({
    required String sessionId,
    String database = '',
    String schema = '',
    bool refresh = false,
  }) async* {
    final conn = _connection();
    if (conn == null) throw const DiagramFailure('Core not connected');
    final responses = conn.diagramService.getSchemaGraph(
      pb.GetSchemaGraphRequest(
        sessionId: sessionId,
        database: database,
        schema: schema,
        refresh: refresh,
      ),
    );
    try {
      await for (final r in responses) {
        if (r.hasError()) throw DiagramFailure(r.error.message);
        yield GraphBatch(
          tables: [for (final t in r.tables) _table(t)],
          tablesDone: r.tablesDone,
          tablesTotal: r.tablesTotal,
        );
      }
    } on GrpcError catch (e) {
      if (e.code == StatusCode.cancelled) return;
      throw DiagramFailure(e.message ?? 'Loading the diagram failed');
    }
  }

  DiagramTable _table(pb.GraphTable t) => DiagramTable(
    name: t.name,
    type: switch (t.type) {
      spb.SchemaObjectType.SCHEMA_OBJECT_TYPE_VIEW => SchemaObjectType.view,
      spb.SchemaObjectType.SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW =>
        SchemaObjectType.materializedView,
      spb.SchemaObjectType.SCHEMA_OBJECT_TYPE_COLLECTION =>
        SchemaObjectType.collection,
      spb.SchemaObjectType.SCHEMA_OBJECT_TYPE_TIME_SERIES =>
        SchemaObjectType.timeSeries,
      _ => SchemaObjectType.table,
    },
    rowEstimate: t.rowCountEstimate.toInt(),
    columns: [
      for (final c in t.columns)
        DiagramColumn(
          name: c.name,
          typeName: c.typeName,
          nullable: c.nullable,
          primaryKeyOrder: c.primaryKeyOrder,
        ),
    ],
    relations: [
      for (final r in t.relations)
        DiagramRelation(
          name: r.name,
          columns: r.columns,
          referencedSchema: r.referencedSchema,
          referencedTable: r.referencedTable,
          referencedColumns: r.referencedColumns,
          inferred: r.inferred,
        ),
    ],
    columnsTruncated: t.columnsTruncated,
  );
}
