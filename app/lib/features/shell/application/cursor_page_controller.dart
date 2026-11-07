import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/application/document_tab_controller.dart';
import '../../documents/domain/models.dart';
import '../data/shell_repository.dart';

/// Identifies one cursor handle of one shell.
@immutable
class CursorKey {
  const CursorKey(this.shellId, this.cursorId);
  final String shellId;
  final String cursorId;

  @override
  bool operator ==(Object other) =>
      other is CursorKey &&
      other.shellId == shellId &&
      other.cursorId == cursorId;

  @override
  int get hashCode => Object.hash(shellId, cursorId);
}

@immutable
class CursorPageState {
  const CursorPageState({
    this.view = DocView.table,
    this.pageSize = 20,
    this.page = 0,
    this.docs = const [],
    this.hasNext = false,
    this.isLoading = false,
    this.error,
    this.selected = const {},
    this.columns = const [],
  });

  final DocView view;
  final int pageSize;
  final int page;
  final List<DocItem> docs;
  final bool hasNext;
  final bool isLoading;
  final String? error;
  final Set<int> selected;
  final List<FieldStat> columns;

  int get firstIndex => page * pageSize;

  CursorPageState copyWith({
    DocView? view,
    int? pageSize,
    int? page,
    List<DocItem>? docs,
    bool? hasNext,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<int>? selected,
    List<FieldStat>? columns,
  }) => CursorPageState(
    view: view ?? this.view,
    pageSize: pageSize ?? this.pageSize,
    page: page ?? this.page,
    docs: docs ?? this.docs,
    hasNext: hasNext ?? this.hasNext,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    selected: selected ?? this.selected,
    columns: columns ?? this.columns,
  );
}

final cursorPageProvider =
    NotifierProvider.family<CursorPageController, CursorPageState, CursorKey>(
      CursorPageController.new,
    );

/// Pages the documents behind a shell cursor handle by re-running its query
/// with skip and limit (ADR 0009 §3, ADR 0010 §5).
class CursorPageController extends Notifier<CursorPageState> {
  CursorPageController(this.key);

  final CursorKey key;

  StreamSubscription<DocBatch>? _sub;
  int _epoch = 0;

  @override
  CursorPageState build() {
    ref.onDispose(() => unawaited(_sub?.cancel()));
    Future.microtask(_load);
    return const CursorPageState(isLoading: true);
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selected: const {},
    );
    unawaited(_sub?.cancel());
    final size = state.pageSize;
    final docs = <String>[];
    final done = Completer<void>();
    _sub = ref
        .read(shellRepositoryProvider)
        .fetchCursor(
          key.shellId,
          key.cursorId,
          skip: state.page * size,
          limit: size + 1,
        )
        .listen(
          (b) => docs.addAll(b.documents),
          onError: (Object e) {
            if (ref.mounted && epoch == _epoch) {
              state = state.copyWith(isLoading: false, error: '$e');
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
    if (!ref.mounted || epoch != _epoch || state.error != null) return;
    final page = docs.take(size).map(DocItem.new).toList();
    state = state.copyWith(
      isLoading: false,
      docs: page,
      hasNext: docs.length > size,
      columns: columnsOf(page),
    );
  }

  void setView(DocView v) => state = state.copyWith(view: v);

  void select(int row, {bool toggle = false}) {
    final s = toggle ? ({...state.selected}..toggle(row)) : {row};
    state = state.copyWith(selected: s);
  }

  void nextPage() {
    if (!state.hasNext || state.isLoading) return;
    state = state.copyWith(page: state.page + 1, isLoading: true);
    unawaited(_load());
  }

  void prevPage() {
    if (state.page == 0 || state.isLoading) return;
    state = state.copyWith(page: state.page - 1, isLoading: true);
    unawaited(_load());
  }

  void setPageSize(int n) {
    state = state.copyWith(pageSize: n, page: 0, isLoading: true);
    unawaited(_load());
  }

  void refresh() {
    state = state.copyWith(isLoading: true);
    unawaited(_load());
  }
}

extension on Set<int> {
  void toggle(int v) => contains(v) ? remove(v) : add(v);
}

/// Table columns of a result page: `_id` first, then the other top-level
/// fields in order of appearance. Aggregation results have no sample, so the
/// page itself decides.
List<FieldStat> columnsOf(List<DocItem> docs) {
  final names = <String>[];
  final seen = <String>{};
  for (final d in docs) {
    final v = d.value;
    if (v is! Map) continue;
    for (final k in v.keys) {
      if (seen.add(k as String)) names.add(k);
    }
  }
  if (names.remove('_id')) names.insert(0, '_id');
  return [for (final n in names) FieldStat(name: n)];
}
