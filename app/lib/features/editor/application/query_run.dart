import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../grid/application/result_window.dart';
import '../data/query_repository.dart';
import '../domain/query_models.dart';

/// Where a tab's run is.
enum RunPhase { idle, connecting, running, finished, failed, cancelled }

/// Outcome of one statement of a run.
@immutable
class StatementResult {
  const StatementResult({
    required this.index,
    this.resultId,
    this.hasRows = false,
    this.rowsSpooled = 0,
    this.rowsAffected = 0,
    this.done = false,
    this.truncated = false,
    this.duration,
    this.notices = const [],
    this.errorMessage,
  });

  final int index;

  /// Result id for `fetchRows`; set once the statement started.
  final String? resultId;
  final bool hasRows;
  final int rowsSpooled;
  final int rowsAffected;

  /// Core has finished spooling this statement.
  final bool done;
  final bool truncated;
  final Duration? duration;
  final List<String> notices;
  final String? errorMessage;

  StatementResult copyWith({
    String? resultId,
    bool? hasRows,
    int? rowsSpooled,
    int? rowsAffected,
    bool? done,
    bool? truncated,
    Duration? duration,
    List<String>? notices,
    String? errorMessage,
  }) => StatementResult(
    index: index,
    resultId: resultId ?? this.resultId,
    hasRows: hasRows ?? this.hasRows,
    rowsSpooled: rowsSpooled ?? this.rowsSpooled,
    rowsAffected: rowsAffected ?? this.rowsAffected,
    done: done ?? this.done,
    truncated: truncated ?? this.truncated,
    duration: duration ?? this.duration,
    notices: notices ?? this.notices,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

/// State of one editor tab's executions.
@immutable
class QueryRunState {
  const QueryRunState({
    this.phase = RunPhase.idle,
    this.plan = const [],
    this.results = const [],
    this.activeResult = 0,
    this.startedAt,
    this.message,
    this.errorOffset,
    this.failedStatement,
    this.serverLabel = '',
    this.cancelling = false,
  });

  final RunPhase phase;

  /// Statements of the latest run, as ranges of the text that was sent.
  final List<TextSpanRange> plan;
  final List<StatementResult> results;

  /// Index into [results] shown in the grid.
  final int activeResult;
  final DateTime? startedAt;

  /// Error or info text for the message bar.
  final String? message;

  /// Offset in the sent text where the server located the error.
  final int? errorOffset;

  /// Index of the statement that failed.
  final int? failedStatement;
  final String serverLabel;
  final bool cancelling;

  bool get busy => phase == RunPhase.connecting || phase == RunPhase.running;

  /// Statement the editor highlights: the one that failed, else the last that
  /// started.
  TextSpanRange? get highlight {
    final i = failedStatement ?? (results.isEmpty ? null : results.last.index);
    return i != null && i < plan.length ? plan[i] : null;
  }

  StatementResult? get active =>
      activeResult >= 0 && activeResult < results.length
      ? results[activeResult]
      : null;

  /// Total time of the finished statements.
  Duration get totalDuration =>
      results.fold(Duration.zero, (d, r) => d + (r.duration ?? Duration.zero));

  QueryRunState copyWith({
    RunPhase? phase,
    List<TextSpanRange>? plan,
    List<StatementResult>? results,
    int? activeResult,
    DateTime? startedAt,
    String? message,
    int? errorOffset,
    int? failedStatement,
    String? serverLabel,
    bool? cancelling,
    bool clearMessage = false,
    bool clearFailure = false,
  }) => QueryRunState(
    phase: phase ?? this.phase,
    plan: plan ?? this.plan,
    results: results ?? this.results,
    activeResult: activeResult ?? this.activeResult,
    startedAt: startedAt ?? this.startedAt,
    message: clearMessage ? null : (message ?? this.message),
    errorOffset: clearFailure ? null : (errorOffset ?? this.errorOffset),
    failedStatement: clearFailure
        ? null
        : (failedStatement ?? this.failedStatement),
    serverLabel: serverLabel ?? this.serverLabel,
    cancelling: cancelling ?? this.cancelling,
  );
}

/// Runs statements for one editor tab: owns its session and results.
class QueryRun extends Notifier<QueryRunState> {
  QueryRun(this.tabId);

  final String tabId;

  /// Which connection this tab runs against.
  late String connectionId;

  SessionInfo? _session;
  StreamSubscription<ExecuteEvent>? _sub;
  Completer<void>? _runDone;
  Timer? _cutTimer;
  final List<String> _openResults = [];
  bool _disposed = false;

  // Captured in build: provider disposal runs cleanup that must not use ref.
  late QueryRepository _repo;

  @override
  QueryRunState build() {
    // A notifier instance outlives rebuilds (invalidate), so reset all state.
    _repo = ref.read(queryRepositoryProvider);
    _disposed = false;
    _session = null;
    _sub = null;
    _runDone = null;
    _cutTimer = null;
    _openResults.clear();
    ref.onDispose(() {
      _disposed = true;
      _cutTimer?.cancel();
      unawaited(_sub?.cancel());
      unawaited(_closeAll());
    });
    return const QueryRunState();
  }

  /// Binds the tab to a connection. Call once, right after creating the tab.
  void bind(String connectionId) => this.connectionId = connectionId;

  /// Runs statements of [text] according to [mode]. Resolves when the run
  /// ends (finished, failed or cancelled); never throws.
  Future<void> run({
    required String text,
    int cursorOffset = 0,
    ExecuteMode mode = ExecuteMode.statementAtCursor,
    TextSpanRange? selection,
  }) async {
    if (state.busy) return;
    state = state.copyWith(
      phase: RunPhase.connecting,
      startedAt: DateTime.now(),
      results: const [],
      plan: const [],
      activeResult: 0,
      cancelling: false,
      clearMessage: true,
      clearFailure: true,
    );
    await _closeResults();
    if (_disposed) return;

    try {
      _session ??= await _repo.openSession(connectionId);
    } on QueryException catch (e) {
      _fail(e.message);
      return;
    }
    if (_disposed) {
      return;
    }
    final session = _session!;
    state = state.copyWith(
      serverLabel: '${session.product} ${session.version}'.trim(),
    );
    if (!session.canExecute) {
      _fail('This connection cannot run SQL statements.');
      return;
    }

    state = state.copyWith(phase: RunPhase.running);
    final done = _runDone = Completer<void>();
    _sub = _repo
        .execute(
          ExecuteRequest(
            sessionId: session.id,
            text: text,
            cursorOffset: cursorOffset,
            mode: mode,
            selection: selection,
          ),
        )
        .listen(
          _onEvent,
          onError: (Object e, StackTrace _) {
            if (!done.isCompleted) {
              _failStream(e);
              done.complete();
            }
          },
          onDone: () {
            if (!done.isCompleted) {
              _endStream();
              done.complete();
            }
          },
        );
    await done.future;
    _cutTimer?.cancel();
  }

  void _onEvent(ExecuteEvent e) {
    if (_disposed) {
      return;
    }
    switch (e) {
      case PlanEvent():
        state = state.copyWith(
          plan: e.statements,
          message: e.statements.isEmpty ? 'Nothing to run.' : null,
        );
      case StartedEvent():
        _openResults.add(e.resultId);
        final r = StatementResult(
          index: e.statementIndex,
          resultId: e.resultId,
        );
        state = state.copyWith(
          results: [...state.results, r],
          activeResult: state.results.length,
        );
      case ColumnsEvent():
        _update(e.statementIndex, (r) => r.copyWith(hasRows: true));
        _window(e.statementIndex)?.onColumns(e.columns);
      case RowsEvent():
        _window(e.statementIndex)?.onFirstWindow(e.rows);
        _update(
          e.statementIndex,
          (r) => r.copyWith(
            rowsSpooled: r.rowsSpooled > e.rows.length
                ? r.rowsSpooled
                : e.rows.length,
          ),
        );
      case ProgressEvent():
        _update(
          e.statementIndex,
          (r) => r.copyWith(rowsSpooled: e.rowsSpooled, done: e.done),
        );
        _window(e.statementIndex)?.onProgress(e.rowsSpooled, done: e.done);
      case SummaryEvent():
        _update(
          e.statementIndex,
          (r) => r.copyWith(
            rowsAffected: e.rowsAffected,
            rowsSpooled: e.rowsSpooled,
            duration: e.duration,
            notices: e.notices,
            truncated: e.truncated,
            hasRows: e.hasRows,
            done: true,
          ),
        );
        _window(e.statementIndex)
            ?.onProgress(e.rowsSpooled, done: true, truncated: e.truncated);
      case ErrorEvent():
        final cancelled = e.kind == QueryErrorKind.canceled;
        _update(
          e.statementIndex,
          (r) => r.copyWith(
            errorMessage: e.message,
            duration: e.duration,
            done: true,
          ),
        );
        state = state.copyWith(
          phase: cancelled ? RunPhase.cancelled : RunPhase.failed,
          message: cancelled ? 'Cancelled.' : e.message,
          errorOffset: e.position,
          failedStatement: e.statementIndex,
        );
    }
  }

  ResultWindow? _window(int statementIndex) {
    final id = state.results
        .where((r) => r.index == statementIndex)
        .map((r) => r.resultId)
        .firstOrNull;
    return id == null ? null : ref.read(resultWindowProvider(id).notifier);
  }

  void _update(
    int statementIndex,
    StatementResult Function(StatementResult) f,
  ) {
    state = state.copyWith(
      results: [
        for (final r in state.results) r.index == statementIndex ? f(r) : r,
      ],
    );
  }

  void _endStream() {
    if (_disposed) return;
    if (state.phase == RunPhase.running) {
      // Prefer the last result with rows in the grid.
      final withRows = state.results.lastIndexWhere((r) => r.hasRows);
      state = state.copyWith(
        phase: RunPhase.finished,
        activeResult: withRows >= 0 ? withRows : state.activeResult,
        cancelling: false,
      );
    }
    state = state.copyWith(cancelling: false);
  }

  void _failStream(Object e) {
    if (_disposed) return;
    final lost = e is QueryException && e.coreUnavailable;
    _fail(lost ? 'Lost the connection to the core.' : '$e');
  }

  void _fail(String message) {
    if (_disposed) return;
    state = state.copyWith(
      phase: RunPhase.failed,
      message: message,
      cancelling: false,
    );
  }

  /// Cancels the running statement on the server. The run ends with a
  /// cancelled state; if the core does not answer in 5 s the stream is cut.
  Future<void> cancel() async {
    final session = _session;
    if (!state.busy || session == null) return;
    state = state.copyWith(cancelling: true);
    try {
      await _repo.cancel(session.id);
    } on QueryException catch (e) {
      _fail(e.message);
    }
    final done = _runDone;
    if (done == null || done.isCompleted) return;
    _cutTimer?.cancel();
    _cutTimer = Timer(const Duration(seconds: 5), () {
      if (_disposed || done.isCompleted) return;
      unawaited(_sub?.cancel());
      state = state.copyWith(
        phase: RunPhase.cancelled,
        message: 'Cancelled.',
        cancelling: false,
      );
      done.complete();
    });
  }

  /// Chooses which statement's result the grid shows.
  void selectResult(int i) {
    if (i >= 0 && i < state.results.length) {
      state = state.copyWith(activeResult: i);
    }
  }

  /// Drops the editor highlight, for example after the text was edited.
  void clearHighlight() {
    if (state.plan.isEmpty && state.failedStatement == null) return;
    state = QueryRunState(
      phase: state.phase,
      results: state.results,
      activeResult: state.activeResult,
      startedAt: state.startedAt,
      message: state.message,
      serverLabel: state.serverLabel,
    );
  }

  Future<void> _closeResults() async {
    final ids = List.of(_openResults);
    _openResults.clear();
    for (final id in ids) {
      if (_disposed) break;
      ref.invalidate(resultWindowProvider(id));
      ref.invalidate(viewportProvider(id));
      try {
        await _repo.closeResult(id);
      } on QueryException {
        // The session closing removes the spool anyway.
      }
    }
  }

  Future<void> _closeAll() async {
    final repo = _repo;
    final session = _session;
    _session = null;
    final ids = List.of(_openResults);
    _openResults.clear();
    try {
      for (final id in ids) {
        await repo.closeResult(id);
      }
      if (session != null) await repo.closeSession(session.id);
    } on QueryException {
      // The core drops idle sessions on its own.
    }
  }
}

/// The run state of the tab with this id.
final queryRunProvider =
    NotifierProvider.family<QueryRun, QueryRunState, String>(QueryRun.new);
