import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';
import 'page_cache.dart';

/// Tuning of the row window (ADR 0004: 40 pages × 500 rows).
@immutable
class ResultWindowConfig {
  const ResultWindowConfig({
    this.pageSize = 500,
    this.maxPages = 40,
    this.prefetchPages = 2,
  });

  final int pageSize;
  final int maxPages;

  /// Pages fetched ahead of and behind the viewport.
  final int prefetchPages;
}

/// Override in tests to use small pages.
final resultWindowConfigProvider = Provider<ResultWindowConfig>(
  (ref) => const ResultWindowConfig(),
);

/// What the grid needs to render one result.
@immutable
class ResultWindowState {
  const ResultWindowState({
    this.columns = const [],
    this.rowCount = 0,
    this.done = false,
    this.truncated = false,
    this.revision = 0,
    this.error,
  });

  final List<ResultColumn> columns;

  /// Rows readable now (rows spooled by the core so far).
  final int rowCount;

  /// True once the core has finished spooling.
  final bool done;

  /// True if spooling stopped at the core's size cap.
  final bool truncated;

  /// Bumped whenever page contents change, so the grid repaints.
  final int revision;

  /// Last fetch failure, if any.
  final Object? error;

  ResultWindowState copyWith({
    List<ResultColumn>? columns,
    int? rowCount,
    bool? done,
    bool? truncated,
    int? revision,
    Object? error,
    bool clearError = false,
  }) => ResultWindowState(
    columns: columns ?? this.columns,
    rowCount: rowCount ?? this.rowCount,
    done: done ?? this.done,
    truncated: truncated ?? this.truncated,
    revision: revision ?? this.revision,
    error: clearError ? null : (error ?? this.error),
  );
}

/// The row window of one result: a bounded page cache over the core's result
/// spool. Pages missing from the cache are fetched with `FetchRows`;
/// pages around the viewport are prefetched and never evicted.
class ResultWindow extends Notifier<ResultWindowState> {
  ResultWindow(this.resultId);

  final String resultId;

  late PageCache _cache;
  late ResultWindowConfig _config;
  final Set<int> _inflight = {};
  Set<int> _protected = const {};
  bool _disposed = false;
  int _epoch = 0; // bumped per build, so fetches of an old build are dropped

  QueryRepository get _repo => ref.read(queryRepositoryProvider);

  @override
  ResultWindowState build() {
    _config = ref.read(resultWindowConfigProvider);
    _cache = PageCache(pageSize: _config.pageSize, maxPages: _config.maxPages);
    // The instance outlives rebuilds (invalidate): reset per-build state.
    _disposed = false;
    _epoch++;
    _inflight.clear();
    _protected = const {};
    ref.onDispose(() {
      _disposed = true;
      _cache.clear();
    });
    return const ResultWindowState();
  }

  /// Rows held right now (for tests and the perf budget).
  int get residentRows => _cache.residentRows;

  /// Resident page indexes, least recently used first.
  List<int> get residentPages => _cache.pageIndexes;

  // ---- fed by the execute stream ----

  /// Column metadata arrived.
  void onColumns(List<ResultColumn> columns) {
    state = state.copyWith(columns: columns, revision: state.revision + 1);
  }

  /// The first window of rows arrived (rows 0..n).
  void onFirstWindow(List<ResultRow> rows) {
    if (rows.isEmpty) return;
    _cache.put(0, rows, protect: _protected);
    state = state.copyWith(
      rowCount: rows.length > state.rowCount ? rows.length : state.rowCount,
      revision: state.revision + 1,
    );
  }

  /// Spooling progress: [rowsSpooled] rows can be fetched.
  void onProgress(int rowsSpooled, {required bool done, bool? truncated}) {
    if (rowsSpooled == state.rowCount &&
        done == state.done &&
        (truncated ?? state.truncated) == state.truncated) {
      return;
    }
    state = state.copyWith(
      rowCount: rowsSpooled,
      done: done,
      truncated: truncated,
      revision: state.revision + 1,
    );
  }

  // ---- read by the grid ----

  /// Row [r] if resident. A miss schedules a fetch of its page and returns
  /// null; the grid repaints when the page arrives. Safe to call from build.
  ResultRow? rowAt(int r) {
    if (r < 0 || r >= state.rowCount) return null;
    final row = _cache.rowAt(r);
    if (row == null) _ensurePage(r ~/ _config.pageSize);
    return row;
  }

  /// Rows [start, end) if all are resident, else null (no fetch).
  List<ResultRow>? residentRange(int start, int end) {
    final out = <ResultRow>[];
    for (var r = start; r < end; r++) {
      final row = _cache.rowAt(r);
      if (row == null) return null;
      out.add(row);
    }
    return out;
  }

  /// Tells the window which rows are on screen: their pages are protected
  /// from eviction and pages within the prefetch distance are fetched.
  void setViewport(int firstRow, int lastRow) {
    final ps = _config.pageSize;
    final total = state.rowCount;
    if (total == 0) return;
    final first = firstRow.clamp(0, total - 1) ~/ ps;
    final last = lastRow.clamp(0, total - 1) ~/ ps;
    _protected = {for (var p = first; p <= last; p++) p};
    final lastPage = (total - 1) ~/ ps;
    for (
      var p = first - _config.prefetchPages;
      p <= last + _config.prefetchPages;
      p++
    ) {
      if (p < 0 || p > lastPage) continue;
      if (_needsFetch(p)) _ensurePage(p);
    }
  }

  bool _needsFetch(int p) {
    final ps = _config.pageSize;
    final expected = (state.rowCount - p * ps).clamp(0, ps);
    return _cache.lengthOf(p) < expected;
  }

  void _ensurePage(int p) {
    if (_disposed || !_inflight.add(p)) return;
    unawaited(_fetchPage(p, _epoch));
  }

  Future<void> _fetchPage(int p, int epoch) async {
    final ps = _config.pageSize;
    try {
      final got = await _repo.fetchRows(resultId, p * ps, ps);
      if (_disposed || epoch != _epoch) return;
      // Pages may arrive in any order and a page may have been refetched
      // meanwhile; keep the longer one.
      if (got.rows.isNotEmpty && got.rows.length >= _cache.lengthOf(p)) {
        _cache.put(p, got.rows, protect: _protected);
      }
      final spooled = got.rowsSpooled > state.rowCount
          ? got.rowsSpooled
          : state.rowCount;
      state = state.copyWith(
        rowCount: spooled,
        done: state.done || got.done,
        revision: state.revision + 1,
        clearError: true,
      );
    } on Object catch (e) {
      if (_disposed || epoch != _epoch) return;
      state = state.copyWith(error: e);
    } finally {
      if (epoch == _epoch) _inflight.remove(p);
    }
  }
}

/// The row window of the result with this id. Invalidate it when the result
/// is closed.
final resultWindowProvider =
    NotifierProvider.family<ResultWindow, ResultWindowState, String>(
      ResultWindow.new,
    );

/// Which rows are on screen, for the status bar. Kept apart from
/// [ResultWindowState] so scrolling does not rebuild the grid.
@immutable
class ViewportRange {
  const ViewportRange(this.first, this.last);

  final int first;
  final int last;

  @override
  bool operator ==(Object other) =>
      other is ViewportRange && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);
}

/// Notifier behind [viewportProvider].
class ViewportNotifier extends Notifier<ViewportRange> {
  ViewportNotifier(this.resultId);

  final String resultId;

  @override
  ViewportRange build() => const ViewportRange(0, 0);

  /// Records the visible row range.
  void set(int first, int last) {
    final next = ViewportRange(first, last);
    if (next != state) state = next;
  }
}

/// Visible row range of a result.
final viewportProvider =
    NotifierProvider.family<ViewportNotifier, ViewportRange, String>(
      ViewportNotifier.new,
    );
