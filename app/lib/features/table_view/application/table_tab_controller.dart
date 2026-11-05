import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/query_models.dart';
import '../../grid/application/result_window.dart';
import '../../schema/data/schema_repository.dart';
import '../../schema/domain/schema_models.dart';
import '../data/table_repository.dart';
import '../domain/table_models.dart';
import 'pending_changes_controller.dart';

@immutable
class TableTabState {
  const TableTabState({
    required this.tabId,
    required this.connectionId,
    required this.tableRef,
    this.tableDetails,
    this.filter = const TableFilter(),
    this.sorts = const [],
    this.pageSize = 500,
    this.resultId,
    this.generatedSql,
    this.isLoading = false,
    this.isApplying = false,
    this.errorMessage,
    this.rowsSpooled = 0,
    this.done = false,
  });

  final String tabId;
  final String connectionId;
  final TableRef tableRef;
  final TableDetails? tableDetails;
  final TableFilter filter;
  final List<SortClause> sorts;
  final int pageSize;
  final String? resultId;
  final String? generatedSql;
  final bool isLoading;
  final bool isApplying;
  final String? errorMessage;
  final int rowsSpooled;
  final bool done;

  bool get canEdit => tableDetails?.canEdit ?? false;
  String? get readOnlyReason => tableDetails?.editDisabledReason;

  TableTabState copyWith({
    String? tabId,
    String? connectionId,
    TableRef? tableRef,
    TableDetails? tableDetails,
    TableFilter? filter,
    List<SortClause>? sorts,
    int? pageSize,
    String? resultId,
    String? generatedSql,
    bool? isLoading,
    bool? isApplying,
    String? errorMessage,
    bool clearError = false,
    int? rowsSpooled,
    bool? done,
  }) => TableTabState(
    tabId: tabId ?? this.tabId,
    connectionId: connectionId ?? this.connectionId,
    tableRef: tableRef ?? this.tableRef,
    tableDetails: tableDetails ?? this.tableDetails,
    filter: filter ?? this.filter,
    sorts: sorts ?? this.sorts,
    pageSize: pageSize ?? this.pageSize,
    resultId: resultId ?? this.resultId,
    generatedSql: generatedSql ?? this.generatedSql,
    isLoading: isLoading ?? this.isLoading,
    isApplying: isApplying ?? this.isApplying,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    rowsSpooled: rowsSpooled ?? this.rowsSpooled,
    done: done ?? this.done,
  );
}

final tableTabProvider =
    NotifierProvider.family<TableTabController, TableTabState, String>(
      TableTabController.new,
    );

class TableTabController extends Notifier<TableTabState> {
  TableTabController(this.tabId);

  final String tabId;

  StreamSubscription<TableStreamEvent>? _streamSub;
  Completer<void>? _streamDone;
  bool _disposed = false;

  TableRepository get _tableRepo => ref.read(tableRepositoryProvider);
  SchemaRepository get _schemaRepo => ref.read(schemaRepositoryProvider);

  @override
  TableTabState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _streamSub?.cancel();
    });

    final tab = ref.watch(
      editorTabsProvider.select(
        (s) => s.tabs.where((t) => t.id == tabId).firstOrNull,
      ),
    );
    final connId = tab?.connectionId ?? '';
    final ref_ = tab?.tableRef ?? const TableRef(table: '');

    final initial = TableTabState(
      tabId: tabId,
      connectionId: connId,
      tableRef: ref_,
      isLoading: true,
    );

    Future.microtask(load);
    return initial;
  }

  Future<void> load() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final connSession = ref.read(
      connectionSessionProvider(state.connectionId).notifier,
    );
    final session = await connSession.connect();
    if (session == null || _disposed) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cannot connect to database',
      );
      return;
    }

    try {
      final details = await _schemaRepo.getTableDetails(
        session.id,
        state.tableRef,
      );
      if (_disposed) return;
      state = state.copyWith(tableDetails: details);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to inspect table: $e',
      );
      return;
    }

    await _fetchData(session.id);
  }

  Future<void> _fetchData(String sessionId) async {
    await _streamSub?.cancel();
    _streamDone = Completer<void>();

    state = state.copyWith(isLoading: true, clearError: true, done: false);

    final stream = _tableRepo.openTable(
      sessionId: sessionId,
      tableRef: state.tableRef,
      filter: state.filter,
      sort: state.sorts,
      pageSize: state.pageSize,
    );

    _streamSub = stream.listen(
      (msg) {
        if (_disposed) return;
        if (msg.sql != null && msg.sql!.isNotEmpty) {
          state = state.copyWith(generatedSql: msg.sql);
        }
        final ev = msg.event;
        if (ev != null) {
          _handleExecuteEvent(ev);
        }
      },
      onError: (Object e) {
        if (_disposed) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
          done: true,
        );
        if (!(_streamDone?.isCompleted ?? true)) {
          _streamDone?.complete();
        }
      },
      onDone: () {
        if (_disposed) return;
        state = state.copyWith(isLoading: false, done: true);
        if (!(_streamDone?.isCompleted ?? true)) {
          _streamDone?.complete();
        }
      },
    );
  }

  void _handleExecuteEvent(ExecuteEvent ev) {
    switch (ev) {
      case StartedEvent():
        state = state.copyWith(resultId: ev.resultId);
      case ColumnsEvent():
        if (state.resultId != null) {
          ref
              .read(resultWindowProvider(state.resultId!).notifier)
              .onColumns(ev.columns);
        }
      case RowsEvent():
        if (state.resultId != null) {
          ref
              .read(resultWindowProvider(state.resultId!).notifier)
              .onFirstWindow(ev.rows);
          state = state.copyWith(rowsSpooled: ev.rows.length);
        }
      case ProgressEvent():
        if (state.resultId != null) {
          ref
              .read(resultWindowProvider(state.resultId!).notifier)
              .onProgress(ev.rowsSpooled, done: ev.done);
          state = state.copyWith(rowsSpooled: ev.rowsSpooled, done: ev.done);
        }
      case SummaryEvent():
        if (state.resultId != null) {
          ref
              .read(resultWindowProvider(state.resultId!).notifier)
              .onProgress(ev.rowsSpooled, done: true, truncated: ev.truncated);
          state = state.copyWith(
            rowsSpooled: ev.rowsSpooled,
            done: true,
            isLoading: false,
          );
        }
      case ErrorEvent():
        state = state.copyWith(
          errorMessage: ev.message,
          isLoading: false,
          done: true,
        );
      case PlanEvent():
        break;
    }
  }

  Future<void> setFilter(TableFilter filter) async {
    state = state.copyWith(filter: filter);
    final session = ref
        .read(connectionSessionProvider(state.connectionId))
        .session;
    if (session != null) {
      await _fetchData(session.id);
    }
  }

  Future<void> setPageSize(int pageSize) async {
    state = state.copyWith(pageSize: pageSize);
    final session = ref
        .read(connectionSessionProvider(state.connectionId))
        .session;
    if (session != null) {
      await _fetchData(session.id);
    }
  }

  Future<void> toggleSort(String column, {bool isMulti = false}) async {
    final existing = List<SortClause>.from(state.sorts);
    final idx = existing.indexWhere((s) => s.column == column);

    if (!isMulti) {
      if (idx >= 0) {
        final cur = existing[idx];
        if (cur.direction == SortDirection.asc) {
          state = state.copyWith(
            sorts: [cur.copyWith(direction: SortDirection.desc)],
          );
        } else {
          // Remove sort
          state = state.copyWith(sorts: const []);
        }
      } else {
        state = state.copyWith(
          sorts: [SortClause(column: column, direction: SortDirection.asc)],
        );
      }
    } else {
      if (idx >= 0) {
        final cur = existing[idx];
        if (cur.direction == SortDirection.asc) {
          existing[idx] = cur.copyWith(direction: SortDirection.desc);
        } else {
          existing.removeAt(idx);
        }
      } else {
        existing.add(SortClause(column: column, direction: SortDirection.asc));
      }
      state = state.copyWith(sorts: existing);
    }

    final session = ref
        .read(connectionSessionProvider(state.connectionId))
        .session;
    if (session != null) {
      await _fetchData(session.id);
    }
  }

  Future<ApplyChangesResult> applyChanges({
    bool dryRun = false,
    bool confirmProduction = false,
  }) async {
    final session = ref
        .read(connectionSessionProvider(state.connectionId))
        .session;
    if (session == null) {
      return const ApplyChangesResult(
        generatedSql: '',
        dryRun: false,
        success: false,
        errorMessage: 'Database session not found',
      );
    }

    final changes = ref
        .read(pendingChangesProvider(tabId).notifier)
        .toRowChanges();
    if (changes.isEmpty) {
      return const ApplyChangesResult(
        generatedSql: '-- No changes to commit',
        dryRun: true,
        success: true,
      );
    }

    state = state.copyWith(isApplying: true);

    try {
      final res = await _tableRepo.applyChanges(
        sessionId: session.id,
        tableRef: state.tableRef,
        changes: changes,
        dryRun: dryRun,
        confirmProduction: confirmProduction,
      );

      if (!dryRun && res.success) {
        ref.read(pendingChangesProvider(tabId).notifier).discard();
        // Refresh table data
        await _fetchData(session.id);
      }

      state = state.copyWith(isApplying: false);
      return res;
    } catch (e) {
      state = state.copyWith(isApplying: false);
      return ApplyChangesResult(
        generatedSql: '',
        dryRun: dryRun,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  void openInEditor() {
    final sql = state.generatedSql;
    if (sql == null || sql.isEmpty) return;
    ref
        .read(editorTabsProvider.notifier)
        .openQueryWithSql(state.connectionId, sql);
  }
}
