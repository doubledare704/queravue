import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../schema/domain/schema_models.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

class AdminTarget {
  const AdminTarget(this.connectionId, this.ref);

  final String connectionId;
  final TableRef ref;

  @override
  bool operator ==(Object other) =>
      other is AdminTarget &&
      other.connectionId == connectionId &&
      other.ref.database == ref.database &&
      other.ref.schema == ref.schema &&
      other.ref.table == ref.table;

  @override
  int get hashCode =>
      Object.hash(connectionId, ref.database, ref.schema, ref.table);
}

class AdminLoad<T> {
  const AdminLoad({this.loading = false, this.value, this.error});

  final bool loading;
  final T? value;
  final AdminError? error;
}

/// The live session id for a connection, opening one if needed. Null when
/// the connection cannot be opened.
final adminSessionIdProvider = Provider.family<Future<String?>, String>((
  ref,
  connectionId,
) async {
  final session = await ref
      .read(connectionSessionProvider(connectionId).notifier)
      .connect();
  return session?.id;
});

const _noSession = AdminError(
  kind: AdminErrorKind.server,
  message: 'Not connected to the database.',
);

abstract class _AdminLoader<T> extends Notifier<AdminLoad<T>> {
  _AdminLoader(this.target);

  final AdminTarget target;

  Future<AdminResult<T>> fetch(AdminRepository repo, String sessionId);

  @override
  AdminLoad<T> build() {
    Future.microtask(reload);
    return const AdminLoad(loading: true);
  }

  Future<void> reload() async {
    if (!ref.mounted) return;
    state = AdminLoad(loading: true, value: state.value);
    try {
      final sessionId = await ref.read(
        adminSessionIdProvider(target.connectionId),
      );
      if (sessionId == null) {
        if (ref.mounted) state = const AdminLoad(error: _noSession);
        return;
      }
      final result = await fetch(ref.read(adminRepositoryProvider), sessionId);
      if (ref.mounted) {
        state = AdminLoad(value: result.value, error: result.error);
      }
    } catch (e) {
      if (ref.mounted) {
        state = AdminLoad(
          error: AdminError(kind: AdminErrorKind.server, message: '$e'),
        );
      }
    }
  }

  Future<AdminResult<R>> run<R>(
    Future<AdminResult<R>> Function(AdminRepository repo, String sessionId)
    call,
  ) async {
    try {
      final sessionId = await ref.read(
        adminSessionIdProvider(target.connectionId),
      );
      if (sessionId == null) return const AdminResult.failed(_noSession);
      return await call(ref.read(adminRepositoryProvider), sessionId);
    } catch (e) {
      return AdminResult.failed(
        AdminError(kind: AdminErrorKind.server, message: '$e'),
      );
    }
  }
}

class IndexesController extends _AdminLoader<List<IndexEntry>> {
  IndexesController(super.target);

  @override
  Future<AdminResult<List<IndexEntry>>> fetch(
    AdminRepository repo,
    String sessionId,
  ) => repo.listIndexes(sessionId, target.ref);

  Future<AdminResult<IndexStatement>> preview(IndexDraft draft) =>
      run((repo, id) => repo.createIndex(id, target.ref, draft, dryRun: true));

  Future<AdminResult<IndexStatement>> create(
    IndexDraft draft, {
    bool confirmed = false,
  }) async {
    final result = await run(
      (repo, id) =>
          repo.createIndex(id, target.ref, draft, confirmed: confirmed),
    );
    if (result.isOk) await reload();
    return result;
  }

  Future<AdminResult<IndexStatement>> previewDrop(String name) =>
      run((repo, id) => repo.dropIndex(id, target.ref, name, dryRun: true));

  Future<AdminResult<IndexStatement>> drop(String name) async {
    final result = await run(
      (repo, id) => repo.dropIndex(id, target.ref, name, confirmed: true),
    );
    if (result.isOk) await reload();
    return result;
  }
}

class StatsController extends _AdminLoader<StatsModel> {
  StatsController(super.target);

  @override
  Future<AdminResult<StatsModel>> fetch(
    AdminRepository repo,
    String sessionId,
  ) => repo.getStats(sessionId, target.ref);
}

class ValidationController extends _AdminLoader<ValidationModel> {
  ValidationController(super.target);

  @override
  Future<AdminResult<ValidationModel>> fetch(
    AdminRepository repo,
    String sessionId,
  ) => repo.getValidation(sessionId, target.ref);

  Future<AdminResult<String>> preview(ValidationModel rule) =>
      run((repo, id) => repo.setValidation(id, target.ref, rule, dryRun: true));

  Future<AdminResult<String>> apply(
    ValidationModel rule, {
    bool confirmed = false,
  }) async {
    final result = await run(
      (repo, id) =>
          repo.setValidation(id, target.ref, rule, confirmed: confirmed),
    );
    if (result.isOk) await reload();
    return result;
  }
}

final indexesProvider =
    NotifierProvider.family<
      IndexesController,
      AdminLoad<List<IndexEntry>>,
      AdminTarget
    >(IndexesController.new);

final statsProvider =
    NotifierProvider.family<
      StatsController,
      AdminLoad<StatsModel>,
      AdminTarget
    >(StatsController.new);

final validationProvider =
    NotifierProvider.family<
      ValidationController,
      AdminLoad<ValidationModel>,
      AdminTarget
    >(ValidationController.new);

final adminIsProductionProvider = Provider.family<bool, String>(
  (ref, connectionId) => ref.watch(
    connectionsControllerProvider.select(
      (v) =>
          v.value?.where((p) => p.id == connectionId).firstOrNull?.production ??
          false,
    ),
  ),
);
