import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/admin.pb.dart' as apb;
import '../../../core_client/gen/queravue/v1/index.pb.dart' as ipb;
import '../../../core_client/gen/queravue/v1/schema.pb.dart' as spb;
import '../../../core_client/gen/queravue/v1/stats.pb.dart' as stpb;
import '../../../core_client/gen/queravue/v1/validation.pb.dart' as vpb;
import '../../schema/domain/schema_models.dart';
import '../domain/admin_models.dart';

abstract interface class AdminRepository {
  Future<AdminResult<List<IndexEntry>>> listIndexes(
    String sessionId,
    TableRef ref,
  );

  Future<AdminResult<IndexStatement>> createIndex(
    String sessionId,
    TableRef ref,
    IndexDraft draft, {
    bool dryRun = false,
    bool confirmed = false,
  });

  Future<AdminResult<IndexStatement>> dropIndex(
    String sessionId,
    TableRef ref,
    String name, {
    bool dryRun = false,
    bool confirmed = false,
  });

  Future<AdminResult<StatsModel>> getStats(String sessionId, TableRef ref);

  Future<AdminResult<ValidationModel>> getValidation(
    String sessionId,
    TableRef ref,
  );

  /// Returns the command that ran, or would run on a dry run.
  Future<AdminResult<String>> setValidation(
    String sessionId,
    TableRef ref,
    ValidationModel rule, {
    bool dryRun = false,
    bool confirmed = false,
  });
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcAdminRepository(() => supervisor.connection);
});

class GrpcAdminRepository implements AdminRepository {
  GrpcAdminRepository(this._connection);

  final CoreConnection? Function() _connection;

  static final _options = CallOptions(timeout: const Duration(seconds: 60));

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  spb.TableRef _ref(TableRef r) =>
      spb.TableRef(database: r.database, schema: r.schema, table: r.table);

  @override
  Future<AdminResult<List<IndexEntry>>> listIndexes(
    String sessionId,
    TableRef ref,
  ) async {
    final resp = await _conn.indexService.listIndexes(
      ipb.ListIndexesRequest(sessionId: sessionId, tableRef: _ref(ref)),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok([for (final i in resp.indexes) _entry(i)]);
  }

  @override
  Future<AdminResult<IndexStatement>> createIndex(
    String sessionId,
    TableRef ref,
    IndexDraft draft, {
    bool dryRun = false,
    bool confirmed = false,
  }) async {
    final resp = await _conn.indexService.createIndex(
      ipb.CreateIndexRequest(
        sessionId: sessionId,
        tableRef: _ref(ref),
        spec: ipb.IndexSpec(
          name: draft.name,
          unique: draft.unique,
          method: draft.method,
          partialPredicate: draft.partialPredicate,
          options: [if (draft.online) const MapEntry('online', 'true')],
          keys: [
            for (final k in draft.keys)
              ipb.IndexKey(
                name: k.name,
                isExpression: k.isExpression,
                kind: k.descending
                    ? ipb.IndexKeyKind.INDEX_KEY_KIND_DESCENDING
                    : ipb.IndexKeyKind.INDEX_KEY_KIND_ASCENDING,
              ),
          ],
        ),
        dryRun: dryRun,
        confirmed: confirmed,
      ),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok(
      IndexStatement(statement: resp.statement, warnings: resp.warnings),
    );
  }

  @override
  Future<AdminResult<IndexStatement>> dropIndex(
    String sessionId,
    TableRef ref,
    String name, {
    bool dryRun = false,
    bool confirmed = false,
  }) async {
    final resp = await _conn.indexService.dropIndex(
      ipb.DropIndexRequest(
        sessionId: sessionId,
        tableRef: _ref(ref),
        indexName: name,
        dryRun: dryRun,
        confirmed: confirmed,
      ),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok(IndexStatement(statement: resp.statement));
  }

  @override
  Future<AdminResult<StatsModel>> getStats(
    String sessionId,
    TableRef ref,
  ) async {
    final resp = await _conn.statsService.getStats(
      stpb.GetStatsRequest(sessionId: sessionId, tableRef: _ref(ref)),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    final s = resp.stats;
    return AdminResult.ok(
      StatsModel(
        estimatedRows: s.hasEstimatedRows() ? s.estimatedRows.toInt() : null,
        dataBytes: s.hasDataBytes() ? s.dataBytes.toInt() : null,
        indexBytes: s.hasIndexBytes() ? s.indexBytes.toInt() : null,
        totalBytes: s.hasTotalBytes() ? s.totalBytes.toInt() : null,
        extras: [for (final e in s.extras) (label: e.label, value: e.value)],
      ),
    );
  }

  @override
  Future<AdminResult<ValidationModel>> getValidation(
    String sessionId,
    TableRef ref,
  ) async {
    final resp = await _conn.validationService.getValidation(
      vpb.GetValidationRequest(sessionId: sessionId, tableRef: _ref(ref)),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok(
      ValidationModel(
        validator: resp.rule.validator,
        level: _levelName(resp.rule.level),
        action: _actionName(resp.rule.action),
      ),
    );
  }

  @override
  Future<AdminResult<String>> setValidation(
    String sessionId,
    TableRef ref,
    ValidationModel rule, {
    bool dryRun = false,
    bool confirmed = false,
  }) async {
    final resp = await _conn.validationService.setValidation(
      vpb.SetValidationRequest(
        sessionId: sessionId,
        tableRef: _ref(ref),
        rule: vpb.ValidationRule(
          validator: rule.validator,
          level: _levelValue(rule.level),
          action: _actionValue(rule.action),
        ),
        dryRun: dryRun,
        confirmed: confirmed,
      ),
      options: _options,
    );
    if (resp.hasError()) return AdminResult.failed(_error(resp.error));
    return AdminResult.ok(resp.command);
  }
}

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

IndexEntry _entry(ipb.IndexInfo i) {
  final usage = i.usage;
  return IndexEntry(
    name: i.spec.name,
    keys: [
      for (final k in i.spec.keys)
        IndexKeyModel(
          k.name,
          descending: k.kind == ipb.IndexKeyKind.INDEX_KEY_KIND_DESCENDING,
          isExpression: k.isExpression,
        ),
    ],
    unique: i.spec.unique,
    primary: i.isPrimary,
    method: i.spec.method,
    partialPredicate: i.spec.partialPredicate,
    includeColumns: i.spec.includeColumns,
    sizeBytes: i.hasSizeBytes() ? i.sizeBytes.toInt() : null,
    usageAvailable: usage.available,
    scans: usage.hasScans() ? usage.scans.toInt() : null,
    lastUsed: usage.hasLastUsedUnixMs()
        ? DateTime.fromMillisecondsSinceEpoch(usage.lastUsedUnixMs.toInt())
        : null,
  );
}

String _levelName(vpb.ValidationLevel l) => switch (l) {
  vpb.ValidationLevel.VALIDATION_LEVEL_OFF => 'off',
  vpb.ValidationLevel.VALIDATION_LEVEL_MODERATE => 'moderate',
  vpb.ValidationLevel.VALIDATION_LEVEL_STRICT => 'strict',
  _ => '',
};

vpb.ValidationLevel _levelValue(String l) => switch (l) {
  'off' => vpb.ValidationLevel.VALIDATION_LEVEL_OFF,
  'moderate' => vpb.ValidationLevel.VALIDATION_LEVEL_MODERATE,
  'strict' => vpb.ValidationLevel.VALIDATION_LEVEL_STRICT,
  _ => vpb.ValidationLevel.VALIDATION_LEVEL_UNSPECIFIED,
};

String _actionName(vpb.ValidationAction a) => switch (a) {
  vpb.ValidationAction.VALIDATION_ACTION_ERROR => 'error',
  vpb.ValidationAction.VALIDATION_ACTION_WARN => 'warn',
  _ => '',
};

vpb.ValidationAction _actionValue(String a) => switch (a) {
  'error' => vpb.ValidationAction.VALIDATION_ACTION_ERROR,
  'warn' => vpb.ValidationAction.VALIDATION_ACTION_WARN,
  _ => vpb.ValidationAction.VALIDATION_ACTION_UNSPECIFIED,
};
