import 'package:queravue/features/admin/data/admin_repository.dart';
import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

class FakeAdminRepository implements AdminRepository {
  List<IndexEntry> indexes = [];
  StatsModel stats = const StatsModel();
  ValidationModel validation = const ValidationModel();
  AdminError? indexesError;
  AdminError? statsError;
  AdminError? validationError;
  AdminError? setValidationError;

  final calls = <String>[];
  final drafts = <IndexDraft>[];
  final confirmations = <bool>[];

  @override
  Future<AdminResult<List<IndexEntry>>> listIndexes(
    String sessionId,
    TableRef ref,
  ) async {
    calls.add('list');
    final e = indexesError;
    return e == null ? AdminResult.ok(List.of(indexes)) : AdminResult.failed(e);
  }

  @override
  Future<AdminResult<IndexStatement>> createIndex(
    String sessionId,
    TableRef ref,
    IndexDraft draft, {
    bool dryRun = false,
    bool confirmed = false,
  }) async {
    final statement =
        'CREATE INDEX ${draft.name.isEmpty ? 'auto' : draft.name} ON ${ref.table} (${draft.keys.map((k) => k.label).join(', ')});';
    calls.add(dryRun ? 'create-dry' : 'create');
    drafts.add(draft);
    if (!dryRun) {
      confirmations.add(confirmed);
      indexes = [
        ...indexes,
        IndexEntry(name: draft.name, keys: draft.keys, unique: draft.unique),
      ];
    }
    return AdminResult.ok(
      IndexStatement(statement: statement, warnings: const ['Blocks writes.']),
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
    calls.add(dryRun ? 'drop-dry' : 'drop');
    if (!dryRun) {
      indexes = indexes.where((i) => i.name != name).toList();
    }
    return AdminResult.ok(IndexStatement(statement: 'DROP INDEX $name;'));
  }

  @override
  Future<AdminResult<StatsModel>> getStats(
    String sessionId,
    TableRef ref,
  ) async {
    final e = statsError;
    return e == null ? AdminResult.ok(stats) : AdminResult.failed(e);
  }

  @override
  Future<AdminResult<ValidationModel>> getValidation(
    String sessionId,
    TableRef ref,
  ) async {
    final e = validationError;
    return e == null ? AdminResult.ok(validation) : AdminResult.failed(e);
  }

  @override
  Future<AdminResult<String>> setValidation(
    String sessionId,
    TableRef ref,
    ValidationModel rule, {
    bool dryRun = false,
    bool confirmed = false,
  }) async {
    calls.add(dryRun ? 'set-dry' : 'set');
    final e = setValidationError;
    if (e != null) return AdminResult.failed(e);
    if (!dryRun) {
      confirmations.add(confirmed);
      validation = rule;
    }
    return AdminResult.ok('collMod ${ref.table}');
  }
}
