import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/application/document_tab_controller.dart';
import '../../documents/domain/models.dart';
import '../data/shell_repository.dart';

/// Identifies one cursor handle of one shell.
@immutable
class CursorKey {
  const CursorKey(this.shellId, this.cursorId, {this.transient = false});
  final String shellId;
  final String cursorId;
  final bool transient;

  @override
  bool operator ==(Object other) =>
      other is CursorKey &&
      other.shellId == shellId &&
      other.cursorId == cursorId &&
      other.transient == transient;

  @override
  int get hashCode => Object.hash(shellId, cursorId, transient);
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
    this.showCancel = false,
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
  final bool showCancel;
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
    bool? showCancel,
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
    showCancel: showCancel ?? this.showCancel,
    error: clearError ? null : (error ?? this.error),
    selected: selected ?? this.selected,
    columns: columns ?? this.columns,
  );
}

final cursorPageProvider = NotifierProvider.autoDispose
    .family<CursorPageController, CursorPageState, CursorKey>(
      CursorPageController.new,
    );

/// Pages the documents behind a shell cursor handle by re-running its query
/// with skip and limit (ADR 0009 §3, ADR 0010 §5).
class CursorPageController extends Notifier<CursorPageState> {
  CursorPageController(this.key);

  final CursorKey key;

  StreamIterator<DocBatch>? _stream;
  Timer? _cancelTimer;

  @override
  CursorPageState build() {
    if (!key.transient) ref.keepAlive();
    ref.onDispose(_stop);
    Future.microtask(() {
      if (ref.mounted && state.isLoading && _stream == null) {
        unawaited(_load(0));
      }
    });
    return const CursorPageState(isLoading: true);
  }

  void _stop() {
    _cancelTimer?.cancel();
    unawaited(_stream?.cancel());
    _stream = null;
  }

  Future<void> _load(int pageIndex) async {
    _stop();
    state = state.copyWith(
      isLoading: true,
      showCancel: false,
      clearError: true,
      selected: const {},
    );
    final size = state.pageSize;
    final docs = <String>[];
    final iterator = _stream = StreamIterator(
      ref
          .read(shellRepositoryProvider)
          .fetchCursor(
            key.shellId,
            key.cursorId,
            skip: pageIndex * size,
            limit: size + 1,
          ),
    );
    _cancelTimer = Timer(kCancelDelay, () {
      state = state.copyWith(showCancel: true);
    });
    try {
      while (docs.length <= size && await iterator.moveNext()) {
        docs.addAll(iterator.current.documents.take(size + 1 - docs.length));
      }
      if (iterator != _stream) return;
      final page = docs.take(size).map(DocItem.new).toList();
      state = state.copyWith(
        isLoading: false,
        showCancel: false,
        page: pageIndex,
        docs: page,
        hasNext: docs.length > size,
        columns: columnsOf(page),
      );
    } on Object catch (error) {
      if (iterator != _stream) return;
      state = state.copyWith(
        isLoading: false,
        showCancel: false,
        error: '$error',
      );
    } finally {
      if (iterator == _stream) _stop();
    }
  }

  void cancel() {
    if (!state.isLoading) return;
    _stop();
    state = state.copyWith(
      isLoading: false,
      showCancel: false,
      error: state.docs.isEmpty ? 'Results cancelled.' : null,
    );
  }

  void setView(DocView v) => state = state.copyWith(view: v);

  void select(int row, {bool toggle = false}) {
    final s = toggle ? ({...state.selected}..toggle(row)) : {row};
    state = state.copyWith(selected: s);
  }

  void nextPage() {
    if (!state.hasNext || state.isLoading) return;
    unawaited(_load(state.page + 1));
  }

  void prevPage() {
    if (state.page == 0 || state.isLoading) return;
    unawaited(_load(state.page - 1));
  }

  void setPageSize(int n) {
    state = state.copyWith(
      pageSize: n,
      page: 0,
      docs: const [],
      hasNext: false,
    );
    unawaited(_load(0));
  }

  void refresh() {
    unawaited(_load(state.page));
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
