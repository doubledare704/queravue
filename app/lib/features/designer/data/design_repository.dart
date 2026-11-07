import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/admin.pb.dart' as apb;
import '../../../core_client/gen/queravue/v1/design.pb.dart' as dpb;
import '../../../core_client/gen/queravue/v1/schema.pb.dart' as spb;
import '../../admin/domain/admin_models.dart';
import '../../schema/domain/schema_models.dart';
import '../domain/design_models.dart';

abstract interface class DesignRepository {
  Future<AdminResult<DdlPreview>> preview(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes,
  );

  Future<AdminResult<DdlApplied>> apply(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes, {
    bool confirmed = false,
  });
}

final designRepositoryProvider = Provider<DesignRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcDesignRepository(() => supervisor.connection);
});

class GrpcDesignRepository implements DesignRepository {
  GrpcDesignRepository(this._connection);

  final CoreConnection? Function() _connection;

  static final _options = CallOptions(timeout: const Duration(minutes: 5));

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  spb.TableRef _ref(TableRef r) =>
      spb.TableRef(database: r.database, schema: r.schema, table: r.table);

  @override
  Future<AdminResult<DdlPreview>> preview(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes,
  ) async {
    final resp = await _conn.designService.previewDDL(
      dpb.PreviewDDLRequest(
        sessionId: sessionId,
        tableRef: _ref(ref),
        changes: changes.map(_change).toList(),
      ),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok(
      DdlPreview(
        statements: resp.statements.map(_statement).toList(),
        warnings: resp.warnings,
        transactional: resp.transactional,
      ),
    );
  }

  @override
  Future<AdminResult<DdlApplied>> apply(
    String sessionId,
    TableRef ref,
    List<SchemaChangeModel> changes, {
    bool confirmed = false,
  }) async {
    final resp = await _conn.designService.applyDDL(
      dpb.ApplyDDLRequest(
        sessionId: sessionId,
        tableRef: _ref(ref),
        changes: changes.map(_change).toList(),
        confirmed: confirmed,
      ),
      options: _options,
    );
    if (resp.hasError()) {
      final error = _error(resp.error);
      if (resp.executedStatements == 0) return AdminResult.failed(error);
      return AdminResult.failed(
        AdminError(
          kind: error.kind,
          message:
              '${error.message} (${resp.executedStatements} of ${resp.statements.length} statements were applied and stay applied.)',
        ),
      );
    }
    return AdminResult.ok(
      DdlApplied(
        statements: resp.statements.map(_statement).toList(),
        executed: resp.executedStatements,
        transactional: resp.transactional,
      ),
    );
  }
}

DdlStatementModel _statement(dpb.DdlStatement s) => DdlStatementModel(
  sql: s.sql,
  destructive: s.destructive,
  summary: s.summary,
);

dpb.ColumnSpec _column(ColumnDraft c) => dpb.ColumnSpec(
  name: c.name,
  typeName: c.typeName,
  nullable: c.nullable,
  defaultExpression: c.defaultExpression,
  identity: c.identity,
);

dpb.SchemaChange _change(SchemaChangeModel c) => switch (c) {
  CreateTableChange() => dpb.SchemaChange(
    createTable: dpb.CreateTable(
      design: dpb.TableDesign(
        columns: c.columns.map(_column).toList(),
        primaryKeyColumns: [
          for (final col in c.columns)
            if (col.primaryKey) col.name,
        ],
      ),
    ),
  ),
  AddColumnChange() => dpb.SchemaChange(
    addColumn: dpb.AddColumn(column: _column(c.column)),
  ),
  DropColumnChange() => dpb.SchemaChange(
    dropColumn: dpb.DropColumn(name: c.name),
  ),
  RenameColumnChange() => dpb.SchemaChange(
    renameColumn: dpb.RenameColumn(from: c.from, to: c.to),
  ),
  AlterColumnChange() => dpb.SchemaChange(
    alterColumn: dpb.AlterColumn(
      before: _column(c.before),
      after: _column(c.after),
    ),
  ),
};

AdminError _error(apb.AdminError e) => AdminError(
  kind: switch (e.kind) {
    apb.AdminErrorKind.ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED =>
      AdminErrorKind.confirmationRequired,
    apb.AdminErrorKind.ADMIN_ERROR_KIND_UNSUPPORTED =>
      AdminErrorKind.unsupported,
    apb.AdminErrorKind.ADMIN_ERROR_KIND_INVALID => AdminErrorKind.invalid,
    apb.AdminErrorKind.ADMIN_ERROR_KIND_NOT_FOUND => AdminErrorKind.notFound,
    apb.AdminErrorKind.ADMIN_ERROR_KIND_CANCELED => AdminErrorKind.canceled,
    _ => AdminErrorKind.server,
  },
  message: e.message,
  position: e.hasPosition() ? e.position : null,
);
