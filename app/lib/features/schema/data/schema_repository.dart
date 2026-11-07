import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/query.pbenum.dart' as qpb;
import '../../../core_client/gen/queravue/v1/schema.pbgrpc.dart' as pb;
import '../../editor/domain/query_models.dart';
import '../domain/schema_models.dart';

/// Access to schema inspection via core.
abstract interface class SchemaRepository {
  Future<List<String>> listDatabases(String sessionId, {bool refresh = false});

  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  });

  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  });

  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  });

  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]);
}

final schemaRepositoryProvider = Provider<SchemaRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcSchemaRepository(() => supervisor.connection);
});

class GrpcSchemaRepository implements SchemaRepository {
  GrpcSchemaRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _timeout = Duration(seconds: 15);

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  @override
  Future<List<String>> listDatabases(
    String sessionId, {
    bool refresh = false,
  }) async {
    final resp = await _conn.schemaService.listDatabases(
      pb.ListDatabasesRequest(sessionId: sessionId, refresh: refresh),
      options: CallOptions(timeout: _timeout),
    );
    return resp.databases;
  }

  @override
  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  }) async {
    final resp = await _conn.schemaService.listSchemas(
      pb.ListSchemasRequest(
        sessionId: sessionId,
        database: database ?? '',
        refresh: refresh,
      ),
      options: CallOptions(timeout: _timeout),
    );
    return resp.schemas;
  }

  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  }) async {
    final resp = await _conn.schemaService.listObjects(
      pb.ListObjectsRequest(
        sessionId: sessionId,
        database: database ?? '',
        schema: schema,
        refresh: refresh,
      ),
      options: CallOptions(timeout: _timeout),
    );

    return resp.objects.map((o) {
      final type = switch (o.type) {
        pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_VIEW => SchemaObjectType.view,
        pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW =>
          SchemaObjectType.materializedView,
        pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_COLLECTION =>
          SchemaObjectType.collection,
        pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_TIME_SERIES =>
          SchemaObjectType.timeSeries,
        _ => SchemaObjectType.table,
      };
      return SchemaObject(
        name: o.name,
        type: type,
        rowCountEstimate: o.rowCountEstimate.toInt(),
        capped: o.capped,
      );
    }).toList();
  }

  @override
  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  }) async {
    final resp = await _conn.schemaService.getTableDetails(
      pb.GetTableDetailsRequest(
        sessionId: sessionId,
        tableRef: pb.TableRef(
          database: tableRef.database,
          schema: tableRef.schema,
          table: tableRef.table,
        ),
        refresh: refresh,
      ),
      options: CallOptions(timeout: _timeout),
    );

    final type = switch (resp.type) {
      pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_VIEW => SchemaObjectType.view,
      pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW =>
        SchemaObjectType.materializedView,
      pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_COLLECTION =>
        SchemaObjectType.collection,
      pb.SchemaObjectType.SCHEMA_OBJECT_TYPE_TIME_SERIES =>
        SchemaObjectType.timeSeries,
      _ => SchemaObjectType.table,
    };

    final cols = resp.columns.map((c) {
      final kind = _mapKind(c.kind);
      return ColumnDetails(
        name: c.name,
        typeName: c.typeName,
        kind: kind,
        nullable: c.nullable,
        defaultValue: c.hasDefaultValue() ? c.defaultValue : null,
        isPrimaryKey: c.isPrimaryKey,
        primaryKeyOrder: c.primaryKeyOrder,
        identity: c.identity,
      );
    }).toList();

    final indexes = resp.indexes
        .map(
          (idx) => IndexDetails(
            name: idx.name,
            columns: idx.columns,
            isUnique: idx.isUnique,
            isPrimary: idx.isPrimary,
          ),
        )
        .toList();

    final fks = resp.foreignKeys
        .map(
          (fk) => ForeignKeyDetails(
            name: fk.name,
            columns: fk.columns,
            referencedSchema: fk.referencedSchema,
            referencedTable: fk.referencedTable,
            referencedColumns: fk.referencedColumns,
          ),
        )
        .toList();

    return TableDetails(
      tableRef: tableRef,
      type: type,
      columns: cols,
      indexes: indexes,
      foreignKeys: fks,
      rowCountEstimate: resp.rowCountEstimate.toInt(),
      canEdit: resp.canEdit,
      editDisabledReason: resp.hasEditDisabledReason()
          ? resp.editDisabledReason
          : null,
    );
  }

  @override
  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]) async {
    final req = pb.RefreshSchemaRequest(sessionId: sessionId);
    if (tableRef != null) {
      req.tableRef = pb.TableRef(
        database: tableRef.database,
        schema: tableRef.schema,
        table: tableRef.table,
      );
    }
    await _conn.schemaService.refreshSchema(
      req,
      options: CallOptions(timeout: _timeout),
    );
  }

  ColumnKind _mapKind(qpb.ValueKind kind) => switch (kind) {
    qpb.ValueKind.VALUE_KIND_BOOL => ColumnKind.boolean,
    qpb.ValueKind.VALUE_KIND_INT => ColumnKind.integer,
    qpb.ValueKind.VALUE_KIND_FLOAT => ColumnKind.float,
    qpb.ValueKind.VALUE_KIND_DECIMAL => ColumnKind.decimal,
    qpb.ValueKind.VALUE_KIND_TEXT => ColumnKind.text,
    qpb.ValueKind.VALUE_KIND_BYTES => ColumnKind.bytes,
    qpb.ValueKind.VALUE_KIND_TIMESTAMPTZ => ColumnKind.timestamptz,
    qpb.ValueKind.VALUE_KIND_JSON => ColumnKind.json,
    qpb.ValueKind.VALUE_KIND_UUID => ColumnKind.uuid,
    qpb.ValueKind.VALUE_KIND_ARRAY => ColumnKind.array,
    _ => ColumnKind.unknown,
  };
}
