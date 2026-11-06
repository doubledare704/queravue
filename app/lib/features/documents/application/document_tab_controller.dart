import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/domain/cancellation.dart';
import '../../editor/application/editor_tabs.dart';
import '../data/document_repository.dart';
import '../domain/models.dart';

/// The three views over the same page of documents.
enum DocView { table, tree, json }

/// Delay before the Cancel button shows for a running Find or Count.
const Duration kCancelDelay = Duration(milliseconds: 300);

/// Page sizes offered in the UI.
const List<int> kDocPageSizes = [20, 50, 100, 500];

@immutable
class DocumentTabState {
  const DocumentTabState({
    this.connectionId = '',
    this.database = '',
    this.collection = '',
    this.sessionId,
    this.view = DocView.table,
    this.query = const FindQuery(),
    this.draft = const FindQuery(),
    this.pageSize = 50,
    this.page = 0,
    this.docs = const [],
    this.hasNext = false,
    this.isLoading = false,
    this.showCancel = false,
    this.loaded = false,
    this.count,
    this.isCounting = false,
    this.columns = const [],
    this.queryError,
    this.error,
    this.selected = const {},
    this.isWriting = false,
  });

  final String connectionId;
  final String database;
  final String collection;
  final String? sessionId;
  final DocView view;

  /// The query that produced [docs] (the draft in the query bar may differ).
  final FindQuery query;

  /// What the query bar holds now; [DocumentTabController.runDraft] runs it.
  final FindQuery draft;
  final int pageSize;
  final int page;

  /// The current page, at most [pageSize] documents.
  final List<DocItem> docs;
  final bool hasNext;
  final bool isLoading;

  /// True once a running Find has taken longer than [kCancelDelay].
  final bool showCancel;

  /// A query has completed at least once.
  final bool loaded;
  final CountResult? count;
  final bool isCounting;

  /// Table columns: `_id` first, then sampled fields by frequency.
  final List<FieldStat> columns;

  /// Parse error of the filter, sort or projection, shown inline.
  final DocumentError? queryError;

  /// Other failure, shown in a banner.
  final String? error;

  /// Selected rows of the current page.
  final Set<int> selected;
  final bool isWriting;

  /// Documents skipped before the first row of the current page.
  int get firstIndex => query.skip + page * pageSize;

  DocumentTabState copyWith({
    String? sessionId,
    DocView? view,
    FindQuery? query,
    FindQuery? draft,
    int? pageSize,
    int? page,
    List<DocItem>? docs,
    bool? hasNext,
    bool? isLoading,
    bool? showCancel,
    bool? loaded,
    CountResult? count,
    bool clearCount = false,
    bool? isCounting,
    List<FieldStat>? columns,
    DocumentError? queryError,
    bool clearQueryError = false,
    String? error,
    bool clearError = false,
    Set<int>? selected,
    bool? isWriting,
  }) => DocumentTabState(
    connectionId: connectionId,
    database: database,
    collection: collection,
    sessionId: sessionId ?? this.sessionId,
    view: view ?? this.view,
    query: query ?? this.query,
    draft: draft ?? this.draft,
    pageSize: pageSize ?? this.pageSize,
    page: page ?? this.page,
    docs: docs ?? this.docs,
    hasNext: hasNext ?? this.hasNext,
    isLoading: isLoading ?? this.isLoading,
    showCancel: showCancel ?? this.showCancel,
    loaded: loaded ?? this.loaded,
    count: clearCount ? null : (count ?? this.count),
    isCounting: isCounting ?? this.isCounting,
    columns: columns ?? this.columns,
    queryError: clearQueryError ? null : (queryError ?? this.queryError),
    error: clearError ? null : (error ?? this.error),
    selected: selected ?? this.selected,
    isWriting: isWriting ?? this.isWriting,
  );
}

/// Result of a write the user triggered.
sealed class WriteOutcome {
  const WriteOutcome();
}

final class WriteOk extends WriteOutcome {
  const WriteOk();
}

/// The stored document changed. [current] is its canonical EJSON, or null if
/// it was deleted.
final class WriteConflict extends WriteOutcome {
  const WriteConflict(this.current);
  final String? current;
}

final class WriteFailed extends WriteOutcome {
  const WriteFailed(this.error);
  final DocumentError error;
}

final documentTabProvider =
    NotifierProvider.family<DocumentTabController, DocumentTabState, String>(
      DocumentTabController.new,
    );

/// Owns the query, the current page and the edits of one collection tab.
class DocumentTabController extends Notifier<DocumentTabState> {
  DocumentTabController(this.tabId);

  final String tabId;

  StreamSubscription<DocBatch>? _sub;
  CancellationToken? _countCancel;
  Timer? _cancelTimer;
  int _epoch = 0; // identifies the latest load; older ones are dropped
  Completer<void>? _loadDone;
  bool _disposed = false;

  DocumentRepository get _repo => ref.read(documentRepositoryProvider);

  @override
  DocumentTabState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _cancelTimer?.cancel();
      _countCancel?.cancel();
      unawaited(_sub?.cancel());
    });
    final tab = ref.watch(
      editorTabsProvider.select(
        (s) => s.tabs.where((t) => t.id == tabId).firstOrNull,
      ),
    );
    final initial = DocumentTabState(
      connectionId: tab?.connectionId ?? '',
      database: tab?.tableRef?.database ?? '',
      collection: tab?.tableRef?.table ?? '',
      isLoading: true,
    );
    Future.microtask(() => run(const FindQuery()));
    return initial;
  }

  /// Completes when the running load (Find) has finished.
  Future<void> get settled => _loadDone?.future ?? Future.value();

  // ---- queries ----

  /// Records what the query bar holds, without running it.
  void setDraft(FindQuery q) => state = state.copyWith(draft: q);

  /// Runs the query bar's content (⌘↵).
  Future<void> runDraft() => run(state.draft);

  /// Runs [query] from the first page.
  Future<void> run(FindQuery query) async {
    if (_disposed) return;
    state = state.copyWith(
      query: query,
      draft: query,
      page: 0,
      clearQueryError: true,
      clearCount: true,
      selected: const {},
    );
    await _load(refreshMeta: true);
  }

  /// Re-runs the current query and page.
  Future<void> refresh() => _load(refreshMeta: true);

  Future<void> nextPage() async {
    if (!state.hasNext || state.isLoading) return;
    state = state.copyWith(page: state.page + 1, selected: const {});
    await _load();
  }

  Future<void> prevPage() async {
    if (state.page == 0 || state.isLoading) return;
    state = state.copyWith(page: state.page - 1, selected: const {});
    await _load();
  }

  Future<void> setPageSize(int n) async {
    if (n == state.pageSize) return;
    state = state.copyWith(pageSize: n, page: 0, selected: const {});
    await _load();
  }

  void setView(DocView v) => state = state.copyWith(view: v);

  /// Stops the running Find and Count. The page keeps what already arrived.
  Future<void> cancel() async {
    _epoch++;
    _cancelTimer?.cancel();
    _countCancel?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    if (!_disposed) {
      state = state.copyWith(
        isLoading: false,
        showCancel: false,
        isCounting: false,
      );
    }
    final d = _loadDone;
    if (d != null && !d.isCompleted) d.complete();
  }

  Future<void> _load({bool refreshMeta = false}) async {
    if (_disposed) return;
    // Not awaited: the old stream's result is dropped by the epoch check, and
    // waiting for a gRPC call to wind down would stall the new query.
    unawaited(_sub?.cancel());
    _countCancel?.cancel();
    final epoch = ++_epoch;
    final done = _loadDone = Completer<void>();

    state = state.copyWith(
      isLoading: true,
      showCancel: false,
      clearError: true,
      clearQueryError: true,
    );
    _cancelTimer?.cancel();
    _cancelTimer = Timer(kCancelDelay, () {
      if (!_disposed && epoch == _epoch && state.isLoading) {
        state = state.copyWith(showCancel: true);
      }
    });

    var sessionId = state.sessionId;
    if (sessionId == null) {
      final s = await ref
          .read(connectionSessionProvider(state.connectionId).notifier)
          .connect();
      if (_disposed || epoch != _epoch) return;
      if (s == null) {
        _finish(epoch, done, error: 'Cannot connect to the database');
        return;
      }
      sessionId = s.id;
      state = state.copyWith(sessionId: sessionId);
    }
    final target = CollectionTarget(
      sessionId,
      state.database,
      state.collection,
    );

    if (refreshMeta) {
      unawaited(_loadCount(target, epoch));
      unawaited(_loadColumns(target));
    }

    final q = state.query;
    final skip = state.firstIndex;
    // One extra document tells whether another page exists.
    var want = state.pageSize + 1;
    if (q.limit > 0) {
      final remaining = q.limit - state.page * state.pageSize;
      if (remaining <= 0) {
        _finish(epoch, done, docs: const [], hasNext: false);
        return;
      }
      want = remaining <= state.pageSize ? remaining : state.pageSize + 1;
    }
    final fetched = <String>[];
    _sub = _repo
        .find(target, q.copyWith(skip: skip, limit: want))
        .listen(
          (b) {
            if (_disposed || epoch != _epoch) return;
            fetched.addAll(b.documents);
          },
          onError: (Object e) {
            if (_disposed || epoch != _epoch) return;
            _fail(done, e);
          },
          onDone: () {
            if (_disposed || epoch != _epoch) return;
            final more = fetched.length > state.pageSize;
            final page = more ? fetched.sublist(0, state.pageSize) : fetched;
            final limitReached =
                q.limit > 0 && (state.page + 1) * state.pageSize >= q.limit;
            _finish(
              epoch,
              done,
              docs: [for (final t in page) DocItem(t)],
              hasNext: more && !limitReached,
            );
          },
          cancelOnError: true,
        );
  }

  void _finish(
    int epoch,
    Completer<void> done, {
    List<DocItem>? docs,
    bool hasNext = false,
    String? error,
  }) {
    if (_disposed || epoch != _epoch) return;
    _cancelTimer?.cancel();
    state = state.copyWith(
      docs: docs,
      hasNext: hasNext,
      isLoading: false,
      showCancel: false,
      loaded: true,
      error: error,
    );
    if (!done.isCompleted) done.complete();
  }

  void _fail(Completer<void> done, Object e) {
    _cancelTimer?.cancel();
    if (e is DocumentFailure && e.error.kind == DocErrorKind.parse) {
      state = state.copyWith(
        isLoading: false,
        showCancel: false,
        loaded: true,
        queryError: e.error,
      );
    } else if (e is DocumentFailure && e.error.kind == DocErrorKind.canceled) {
      state = state.copyWith(isLoading: false, showCancel: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        showCancel: false,
        loaded: true,
        error: e is DocumentFailure ? e.error.message : '$e',
      );
    }
    if (!done.isCompleted) done.complete();
  }

  Future<void> _loadCount(CollectionTarget target, int epoch) async {
    final cancel = _countCancel = CancellationToken();
    state = state.copyWith(isCounting: true);
    try {
      final c = await _repo.count(target, state.query.filter, cancel: cancel);
      if (_disposed || epoch != _epoch) return;
      state = state.copyWith(count: c, isCounting: false);
    } on OperationCancelled {
      if (!_disposed) state = state.copyWith(isCounting: false);
    } on Object {
      // The count is a nicety; a bad filter is reported by Find.
      if (!_disposed && epoch == _epoch) {
        state = state.copyWith(isCounting: false);
      }
    }
  }

  Future<void> _loadColumns(CollectionTarget target) async {
    if (state.columns.isNotEmpty) return;
    try {
      final r = await _repo.sampleFields(target);
      if (_disposed) return;
      final cols = [...r.fields];
      if (!cols.any((f) => f.name == '_id')) {
        cols.insert(0, const FieldStat(name: '_id', types: ['objectId']));
      }
      state = state.copyWith(columns: cols);
    } on Object {
      if (!_disposed && state.columns.isEmpty) {
        state = state.copyWith(columns: const [FieldStat(name: '_id')]);
      }
    }
  }

  // ---- selection ----

  void select(int row, {bool toggle = false}) {
    final s = Set<int>.of(state.selected);
    if (toggle) {
      if (!s.remove(row)) s.add(row);
    } else {
      s
        ..clear()
        ..add(row);
    }
    state = state.copyWith(selected: s);
  }

  void selectAll() => state = state.copyWith(
    selected: {for (var i = 0; i < state.docs.length; i++) i},
  );

  void clearSelection() => state = state.copyWith(selected: const {});

  // ---- edits ----

  CollectionTarget? get _target {
    final s = state.sessionId;
    return s == null
        ? null
        : CollectionTarget(s, state.database, state.collection);
  }

  Future<WriteOutcome> insert(String documentText) => _write(() async {
    await _repo.insert(_target!, [documentText]);
  });

  /// Replaces [original] with [newText]. With [overwrite], the stored
  /// document is replaced even if it changed since it was loaded.
  Future<WriteOutcome> replace(
    DocItem original,
    String newText, {
    bool overwrite = false,
  }) {
    final id = original.idText;
    if (id == null) {
      return Future.value(
        const WriteFailed(
          DocumentError(
            kind: DocErrorKind.parse,
            message: 'The document has no _id (it was projected away).',
          ),
        ),
      );
    }
    return _write(() async {
      await _repo.replace(
        _target!,
        id: id,
        document: newText,
        expected: overwrite ? null : original.text,
      );
    });
  }

  /// Deletes the selected documents. [confirmed] is the user's confirmation;
  /// production connections reject unconfirmed deletes.
  Future<WriteOutcome> deleteSelected({required bool confirmed}) {
    final ids = [
      for (final i in state.selected.toList()..sort())
        if (i < state.docs.length && state.docs[i].idText != null)
          state.docs[i].idText!,
    ];
    return _write(() async {
      await _repo.delete(_target!, ids, confirmed: confirmed);
    });
  }

  Future<WriteOutcome> _write(Future<void> Function() op) async {
    if (_target == null) {
      return const WriteFailed(
        DocumentError(kind: DocErrorKind.network, message: 'Not connected'),
      );
    }
    state = state.copyWith(isWriting: true);
    try {
      await op();
      if (_disposed) return const WriteOk();
      state = state.copyWith(isWriting: false, selected: const {});
      await _load(refreshMeta: true);
      return const WriteOk();
    } on DocumentFailure catch (e) {
      if (!_disposed) state = state.copyWith(isWriting: false);
      if (e.error.kind == DocErrorKind.conflict) {
        return WriteConflict(e.error.currentDocument);
      }
      return WriteFailed(e.error);
    } on Object catch (e) {
      if (!_disposed) state = state.copyWith(isWriting: false);
      return WriteFailed(
        DocumentError(kind: DocErrorKind.unspecified, message: '$e'),
      );
    }
  }
}
