import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/domain/admin_models.dart';
import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../../schema/application/schema_controller.dart';
import '../../schema/data/schema_repository.dart';
import '../../schema/domain/schema_models.dart';
import '../data/design_repository.dart';
import '../domain/design_models.dart';

class DesignerState {
  const DesignerState({
    required this.connectionId,
    required this.tableRef,
    required this.isNew,
    this.tableName = '',
    this.original,
    this.columns = const [],
    this.loading = true,
    this.error,
  });

  final String connectionId;
  final TableRef tableRef;
  final bool isNew;
  final String tableName;
  final TableDetails? original;
  final List<ColumnDraft> columns;
  final bool loading;
  final String? error;

  /// Where the changes apply: the existing table, or the new table's name.
  TableRef get target => isNew
      ? TableRef(
          database: tableRef.database,
          schema: tableRef.schema,
          table: tableName.trim(),
        )
      : tableRef;

  List<SchemaChangeModel> get changes =>
      diffDesign(original: original, columns: columns);

  bool get hasChanges => isNew ? columns.isNotEmpty : changes.isNotEmpty;

  DesignerState copyWith({
    String? tableName,
    TableDetails? original,
    List<ColumnDraft>? columns,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => DesignerState(
    connectionId: connectionId,
    tableRef: tableRef,
    isNew: isNew,
    tableName: tableName ?? this.tableName,
    original: original ?? this.original,
    columns: columns ?? this.columns,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

final designerProvider =
    NotifierProvider.family<DesignerController, DesignerState, String>(
      DesignerController.new,
    );

class DesignerController extends Notifier<DesignerState> {
  DesignerController(this.tabId);

  final String tabId;

  @override
  DesignerState build() {
    final tab = ref
        .read(editorTabsProvider)
        .tabs
        .firstWhere((t) => t.id == tabId);
    Future.microtask(load);
    return DesignerState(
      connectionId: tab.connectionId,
      tableRef: tab.tableRef ?? const TableRef(table: ''),
      isNew: tab.newTable,
      columns: tab.newTable
          ? const [
              ColumnDraft(
                name: 'id',
                typeName: 'integer',
                nullable: false,
                primaryKey: true,
              ),
            ]
          : const [],
      loading: !tab.newTable,
    );
  }

  Future<String?> _session() async =>
      (await ref
              .read(connectionSessionProvider(state.connectionId).notifier)
              .connect())
          ?.id;

  Future<void> load() async {
    if (state.isNew) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final sessionId = await _session();
      if (sessionId == null) {
        state = state.copyWith(
          loading: false,
          error: 'Cannot connect to database',
        );
        return;
      }
      final details = await ref
          .read(schemaRepositoryProvider)
          .getTableDetails(sessionId, state.tableRef, refresh: true);
      if (!ref.mounted) return;
      state = state.copyWith(
        original: details,
        columns: [for (final c in details.columns) ColumnDraft.fromDetails(c)],
        loading: false,
      );
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to inspect table: $e',
        );
      }
    }
  }

  void setTableName(String name) => state = state.copyWith(tableName: name);

  void addColumn() => state = state.copyWith(
    columns: [
      ...state.columns,
      const ColumnDraft(name: '', typeName: ''),
    ],
  );

  void updateColumn(int index, ColumnDraft column) {
    final columns = [...state.columns];
    columns[index] = column;
    state = state.copyWith(columns: columns);
  }

  void removeColumn(int index) {
    final columns = [...state.columns]..removeAt(index);
    state = state.copyWith(columns: columns);
  }

  String? validate() {
    if (state.isNew && state.tableName.trim().isEmpty) {
      return 'Enter a table name.';
    }
    final names = <String>{};
    for (final c in state.columns) {
      if (c.name.trim().isEmpty || c.typeName.trim().isEmpty) {
        return 'Every column needs a name and a type.';
      }
      if (!names.add(c.name.trim())) return 'Column "${c.name}" appears twice.';
    }
    if (state.isNew && state.columns.isEmpty) return 'Add at least one column.';
    return null;
  }

  Future<AdminResult<DdlPreview>> preview() =>
      _run((repo, id) => repo.preview(id, state.target, state.changes));

  Future<AdminResult<DdlApplied>> apply({required bool confirmed}) async {
    final result = await _run(
      (repo, id) =>
          repo.apply(id, state.target, state.changes, confirmed: confirmed),
    );
    if (result.isOk && result.value!.executed > 0) {
      await ref
          .read(schemaTreeProvider(state.connectionId).notifier)
          .refresh('root');
      if (!state.isNew) await load();
    }
    return result;
  }

  Future<AdminResult<T>> _run<T>(
    Future<AdminResult<T>> Function(DesignRepository repo, String sessionId)
    call,
  ) async {
    try {
      final sessionId = await _session();
      if (sessionId == null) {
        return const AdminResult.failed(
          AdminError(
            kind: AdminErrorKind.server,
            message: 'Not connected to the database.',
          ),
        );
      }
      return await call(ref.read(designRepositoryProvider), sessionId);
    } catch (e) {
      return AdminResult.failed(
        AdminError(kind: AdminErrorKind.server, message: '$e'),
      );
    }
  }
}
