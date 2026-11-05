import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/editor/application/query_run.dart';
import 'package:queravue/features/editor/application/query_status.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/grid/application/result_window.dart';

import '../../support/fake_query_repository.dart';

({ProviderContainer c, FakeQueryRepository repo, QueryRun run}) setup() {
  final repo = FakeQueryRepository(totalRows: 1200);
  final c = ProviderContainer(
    overrides: [queryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  c.listen(queryRunProvider('t1'), (_, _) {});
  final run = c.read(queryRunProvider('t1').notifier)..bind('conn-1');
  return (c: c, repo: repo, run: run);
}

List<ExecuteEvent> selectScript() => [
  const PlanEvent([TextSpanRange(0, 8)]),
  const StartedEvent(0, 'res-1'),
  const ColumnsEvent(0, fakeColumns),
  RowsEvent(0, [for (var r = 0; r < 500; r++) fakeRow(r)]),
  const ProgressEvent(0, 1200, true),
  const SummaryEvent(
    statementIndex: 0,
    rowsAffected: 0,
    rowsSpooled: 1200,
    duration: Duration(milliseconds: 40),
    notices: ['NOTICE: hi'],
    truncated: false,
    hasRows: true,
  ),
];

void main() {
  test('a SELECT run feeds the result window and finishes', () async {
    final s = setup();
    s.repo.script = selectScript();
    await s.run.run(text: 'select 1');

    final st = s.c.read(queryRunProvider('t1'));
    expect(st.phase, RunPhase.finished);
    expect(st.results.single.resultId, 'res-1');
    expect(st.results.single.rowsSpooled, 1200);
    expect(st.results.single.notices, ['NOTICE: hi']);
    expect(st.totalDuration, const Duration(milliseconds: 40));
    expect(st.highlight, const TextSpanRange(0, 8));

    final win = s.c.read(resultWindowProvider('res-1'));
    expect(win.columns.map((c) => c.name), ['id', 'label']);
    expect(win.rowCount, 1200);
    expect(win.done, isTrue);
    expect(
      s.c.read(resultWindowProvider('res-1').notifier).rowAt(499),
      isNotNull,
    );
    expect(s.repo.fetches, isEmpty, reason: 'the first window needs no fetch');
  });

  test('the session opens lazily once and is reused', () async {
    final s = setup();
    s.repo.script = selectScript();
    await s.run.run(text: 'select 1');
    await s.run.run(text: 'select 1');
    expect(s.repo.openSessions, 1);
    expect(s.repo.executed.map((r) => r.sessionId).toSet(), {'session-1'});
    // The previous result was closed before the second run.
    expect(s.repo.closedResults, ['res-1']);
  });

  test('passes the mode, cursor and selection to the core', () async {
    final s = setup();
    await s.run.run(
      text: 'a; b',
      cursorOffset: 3,
      mode: ExecuteMode.selection,
      selection: const TextSpanRange(0, 1),
    );
    final r = s.repo.executed.single;
    expect(
      (r.text, r.cursorOffset, r.mode),
      ('a; b', 3, ExecuteMode.selection),
    );
    expect(r.selection, const TextSpanRange(0, 1));
  });

  test(
    'a failed statement records message, error offset and statement',
    () async {
      final s = setup();
      s.repo.script = const [
        PlanEvent([TextSpanRange(0, 9), TextSpanRange(11, 20)]),
        StartedEvent(0, 'r0'),
        SummaryEvent(
          statementIndex: 0,
          rowsAffected: 0,
          rowsSpooled: 0,
          duration: Duration(milliseconds: 1),
          notices: [],
          truncated: false,
          hasRows: false,
        ),
        StartedEvent(1, 'r1'),
        ErrorEvent(
          statementIndex: 1,
          kind: QueryErrorKind.sql,
          message: 'column "foo" does not exist',
          position: 18,
        ),
      ];
      await s.run.run(text: 'select 1; select foo');
      final st = s.c.read(queryRunProvider('t1'));
      expect(st.phase, RunPhase.failed);
      expect(st.message, 'column "foo" does not exist');
      expect(st.errorOffset, 18);
      expect(st.failedStatement, 1);
      expect(st.highlight, const TextSpanRange(11, 20));
      expect(st.results[1].errorMessage, isNotNull);
    },
  );

  test(
    'multiple statements get a result each; the last result with rows is shown',
    () async {
      final s = setup();
      s.repo.script = [
        const PlanEvent([TextSpanRange(0, 5), TextSpanRange(7, 12)]),
        const StartedEvent(0, 'a'),
        const ColumnsEvent(0, fakeColumns),
        const SummaryEvent(
          statementIndex: 0,
          rowsAffected: 0,
          rowsSpooled: 0,
          duration: Duration.zero,
          notices: [],
          truncated: false,
          hasRows: true,
        ),
        const StartedEvent(1, 'b'),
        const SummaryEvent(
          statementIndex: 1,
          rowsAffected: 3,
          rowsSpooled: 0,
          duration: Duration.zero,
          notices: [],
          truncated: false,
          hasRows: false,
        ),
      ];
      await s.run.run(text: 'x; y', mode: ExecuteMode.all);
      final st = s.c.read(queryRunProvider('t1'));
      expect(st.results.length, 2);
      expect(
        st.activeResult,
        0,
        reason: 'result 0 has rows, result 1 does not',
      );
      expect(st.results[1].rowsAffected, 3);
      s.run.selectResult(1);
      expect(s.c.read(queryRunProvider('t1')).active!.resultId, 'b');
    },
  );

  test('cancel asks the core, and the cancelled error ends the run', () async {
    final s = setup();
    final hold = Completer<void>();
    s.repo
      ..holdOpen = hold
      ..script = const [
        PlanEvent([TextSpanRange(0, 8)]),
        StartedEvent(0, 'res-1'),
      ];
    final done = s.run.run(text: 'select 1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(s.c.read(queryRunProvider('t1')).phase, RunPhase.running);

    unawaited(s.run.cancel());
    await Future<void>.delayed(Duration.zero);
    expect(s.repo.cancelCalls, 1);
    expect(s.c.read(queryRunProvider('t1')).cancelling, isTrue);

    // The core answers with a cancelled error and ends the stream.
    s.repo.holdOpen = null;
    hold.complete();
    await done;
    expect(s.c.read(queryRunProvider('t1')).busy, isFalse);
  });

  test('a cancelled-kind error event gives the cancelled phase', () async {
    final s = setup();
    s.repo.script = const [
      PlanEvent([TextSpanRange(0, 8)]),
      StartedEvent(0, 'r'),
      ErrorEvent(
        statementIndex: 0,
        kind: QueryErrorKind.canceled,
        message: 'statement cancelled',
      ),
    ];
    await s.run.run(text: 'select 1');
    final st = s.c.read(queryRunProvider('t1'));
    expect(st.phase, RunPhase.cancelled);
    expect(st.message, 'Cancelled.');
  });

  test('a connection failure is reported and the next run retries', () async {
    final s = setup();
    s.repo.openError = const SessionOpenException(
      'password authentication failed',
    );
    await s.run.run(text: 'select 1');
    var st = s.c.read(queryRunProvider('t1'));
    expect(st.phase, RunPhase.failed);
    expect(st.message, 'password authentication failed');

    s.repo
      ..openError = null
      ..script = selectScript();
    await s.run.run(text: 'select 1');
    st = s.c.read(queryRunProvider('t1'));
    expect(st.phase, RunPhase.finished);
  });

  test('a connection that cannot execute fails with a clear message', () async {
    final s = setup();
    s.repo.capabilities = const {'connect'};
    await s.run.run(text: 'select 1');
    final st = s.c.read(queryRunProvider('t1'));
    expect(st.phase, RunPhase.failed);
    expect(st.message, contains('cannot run SQL'));
    expect(s.repo.executed, isEmpty);
  });

  test('a stream error (core lost) fails the run', () async {
    final s = setup();
    s.repo.script = const [
      PlanEvent([TextSpanRange(0, 8)]),
    ];
    final repo = _ErroringRepo();
    final c = ProviderContainer(
      overrides: [queryRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.listen(queryRunProvider('x'), (_, _) {});
    final run = c.read(queryRunProvider('x').notifier)..bind('c');
    await run.run(text: 'select 1');
    final st = c.read(queryRunProvider('x'));
    expect(st.phase, RunPhase.failed);
    expect(st.message, contains('Lost the connection'));
  });

  test('a run while busy is ignored', () async {
    final s = setup();
    final hold = Completer<void>();
    s.repo
      ..holdOpen = hold
      ..script = const [
        PlanEvent([TextSpanRange(0, 8)]),
      ];
    final first = s.run.run(text: 'select 1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await s.run.run(text: 'select 2');
    expect(s.repo.executed.length, 1);
    s.repo.holdOpen = null;
    hold.complete();
    await first;
  });

  test('disposing the tab closes its results and session', () async {
    final s = setup();
    s.repo.script = selectScript();
    await s.run.run(text: 'select 1');
    s.c.invalidate(queryRunProvider('t1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(s.repo.closedResults, ['res-1']);
    expect(s.repo.closedSessions, ['session-1']);
  });

  test(
    'clearHighlight drops the marked statement but keeps the result',
    () async {
      final s = setup();
      s.repo.script = selectScript();
      await s.run.run(text: 'select 1');
      s.run.clearHighlight();
      final st = s.c.read(queryRunProvider('t1'));
      expect(st.highlight, isNull);
      expect(st.results, isNotEmpty);
    },
  );

  group('status line', () {
    QueryRunState done({bool truncated = false}) => QueryRunState(
      phase: RunPhase.finished,
      results: [
        StatementResult(
          index: 0,
          resultId: 'r',
          hasRows: true,
          rowsSpooled: 1000000,
          done: true,
          truncated: truncated,
          duration: const Duration(milliseconds: 1230),
        ),
      ],
    );

    test('finished', () {
      expect(
        formatQueryStatus(
          run: done(),
          viewport: const ViewportRange(900000, 900030),
        ),
        '1,000,000 rows · rows 900,001–900,031 · 1.23 s',
      );
    });

    test('truncated', () {
      expect(
        formatQueryStatus(run: done(truncated: true)),
        contains('truncated at 1,000,000 rows'),
      );
    });

    test('streaming', () {
      final run = QueryRunState(
        phase: RunPhase.running,
        results: const [
          StatementResult(
            index: 0,
            resultId: 'r',
            hasRows: true,
            rowsSpooled: 5000,
          ),
        ],
      );
      expect(
        formatQueryStatus(run: run, viewport: const ViewportRange(0, 20)),
        '5,000 rows · rows 1–21 · streaming…',
      );
      expect(
        formatQueryStatus(run: run.copyWith(cancelling: true)),
        contains('cancelling…'),
      );
    });

    test('non-row statement and idle', () {
      const run = QueryRunState(
        phase: RunPhase.finished,
        results: [
          StatementResult(
            index: 0,
            rowsAffected: 3,
            duration: Duration(milliseconds: 5),
          ),
        ],
      );
      expect(formatQueryStatus(run: run), '3 rows affected · 5 ms');
      expect(formatQueryStatus(run: const QueryRunState()), '');
    });
  });
}

class _ErroringRepo extends FakeQueryRepository {
  @override
  Stream<ExecuteEvent> execute(ExecuteRequest request) =>
      Stream.error(const QueryException('unavailable', coreUnavailable: true));
}
