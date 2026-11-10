import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/application/query_run.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:re_editor/re_editor.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';

const _conn = ConnectionProfile(
  id: 'c1',
  name: 'Local PG',
  engineId: 'postgres',
);

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(version: '0.1.0-dev', protocolVersion: 3, capabilities: {'query'}),
  );
}

List<ExecuteEvent> _script({int rows = 600}) => [
  const PlanEvent([TextSpanRange(0, 8)]),
  const StartedEvent(0, 'res-1'),
  const ColumnsEvent(0, fakeColumns),
  RowsEvent(0, [for (var r = 0; r < 500 && r < rows; r++) fakeRow(r)]),
  ProgressEvent(0, rows, true),
  SummaryEvent(
    statementIndex: 0,
    rowsAffected: 0,
    rowsSpooled: rows,
    duration: const Duration(milliseconds: 1230),
    notices: const [],
    truncated: false,
    hasRows: true,
  ),
];

Future<({FakeQueryRepository repo, ProviderContainer container})> pumpApp(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeQueryRepository(totalRows: 600)..script = _script();
  final conns = FakeConnectionsRepository(initial: const [_conn]);
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(conns),
      queryRepositoryProvider.overrideWithValue(repo),
      coreStatusProvider.overrideWith(_Connected.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  container.read(selectedConnectionProvider.notifier).select('c1');
  await tester.pumpAndSettle();
  return (repo: repo, container: container);
}

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey k, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(k);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
}

void setText(
  ProviderContainer c,
  String text, {
  int? cursorLine,
  int cursorCol = 0,
}) {
  final tab = c.read(editorTabsProvider).tabs.single;
  tab.controller.text = text;
  if (cursorLine != null) {
    tab.controller.selection = CodeLineSelection.collapsed(
      index: cursorLine,
      offset: cursorCol,
    );
  }
}

void main() {
  testWidgets(
    'New query opens an editor tab; Ctrl+T and Ctrl+W add and close tabs',
    (tester) async {
      final env = await pumpApp(tester);
      expect(find.byKey(const Key('details-new-query')), findsOneWidget);
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      expect(find.text('Query 1'), findsOneWidget);
      expect(find.byKey(const Key('run-button')), findsOneWidget);

      await chord(tester, LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();
      expect(find.text('Query 2'), findsOneWidget);
      expect(env.container.read(editorTabsProvider).tabs.length, 2);

      await chord(tester, LogicalKeyboardKey.keyW);
      await tester.pumpAndSettle();
      expect(find.text('Query 2'), findsNothing);
      await chord(tester, LogicalKeyboardKey.keyW);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('details-new-query')),
        findsOneWidget,
        reason: 'back to details',
      );
    },
  );

  testWidgets(
    'Ctrl+Enter runs the statement at the cursor and shows the grid and status',
    (tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      setText(
        env.container,
        'select 1;\nselect 2',
        cursorLine: 1,
        cursorCol: 3,
      );
      await tester.pump();

      await chord(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final req = env.repo.executed.single;
      expect(req.mode, ExecuteMode.statementAtCursor);
      expect(req.text, 'select 1;\nselect 2');
      expect(req.cursorOffset, 13, reason: 'line 1 starts at offset 10, +3');
      expect(env.repo.openSessions, 1);
      expect(
        find.text('row-5'),
        findsOneWidget,
        reason: 'the grid shows the first window',
      );
      expect(find.byKey(const Key('query-status')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('query-status'))).data,
        '600 rows · rows 1–15 · 1.23 s',
      );
    },
  );

  testWidgets('Ctrl+Shift+Enter runs all statements', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    setText(env.container, 'select 1; select 2');
    await tester.pump();
    await chord(tester, LogicalKeyboardKey.enter, shift: true);
    await tester.pumpAndSettle();
    expect(env.repo.executed.single.mode, ExecuteMode.all);
  });

  testWidgets('a selection runs the selection', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    setText(env.container, 'select 1; select 2');
    env.container
        .read(editorTabsProvider)
        .tabs
        .single
        .controller
        .selection = const CodeLineSelection(
      baseIndex: 0,
      baseOffset: 10,
      extentIndex: 0,
      extentOffset: 18,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-button')));
    await tester.pumpAndSettle();
    final req = env.repo.executed.single;
    expect(req.mode, ExecuteMode.selection);
    expect(req.selection, const TextSpanRange(10, 18));
  });

  testWidgets(
    'Esc and the Cancel button cancel a running statement and show the timer',
    (tester) async {
      final env = await pumpApp(tester);
      final hold = Completer<void>();
      env.repo
        ..holdOpen = hold
        ..script = const [
          PlanEvent([TextSpanRange(0, 8)]),
          StartedEvent(0, 'res-1'),
        ];
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      setText(env.container, 'select pg_sleep(100)');
      await tester.pump();
      await tester.tap(find.byKey(const Key('run-button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('cancel-button')), findsOneWidget);
      expect(find.byKey(const Key('elapsed')), findsOneWidget);
      final before = tester.widget<Text>(find.byKey(const Key('elapsed'))).data;
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.widget<Text>(find.byKey(const Key('elapsed'))).data,
        isNot(before),
        reason: 'the timer ticks',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(env.repo.cancelCalls, 1);
      env.repo.holdOpen = null;
      hold.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('run-button')),
        findsOneWidget,
        reason: 'idle again',
      );
    },
  );

  testWidgets(
    'a failed statement shows the error and moves the caret to the error position',
    (tester) async {
      final env = await pumpApp(tester);
      env.repo.script = const [
        PlanEvent([TextSpanRange(0, 20)]),
        StartedEvent(0, 'r'),
        ErrorEvent(
          statementIndex: 0,
          kind: QueryErrorKind.sql,
          message: 'column "foo" does not exist',
          position: 18,
        ),
      ];
      await tester.tap(find.byKey(const Key('details-new-query')));
      await tester.pumpAndSettle();
      setText(
        env.container,
        'select 1;\nselect foo',
        cursorLine: 0,
        cursorCol: 0,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('run-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('run-message')), findsOneWidget);
      expect(find.text('column "foo" does not exist'), findsOneWidget);
      final sel = env.container
          .read(editorTabsProvider)
          .tabs
          .single
          .controller
          .selection;
      expect(
        (sel.extentIndex, sel.extentOffset),
        (1, 8),
        reason: 'offset 18 is line 1, column 8',
      );
      final run = env.container.read(
        queryRunProvider(env.container.read(editorTabsProvider).tabs.single.id),
      );
      expect(run.highlight, const TextSpanRange(0, 20));
    },
  );

  testWidgets('editing the text clears the marked statement', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    setText(env.container, 'select 1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-button')));
    await tester.pumpAndSettle();
    final id = env.container.read(editorTabsProvider).tabs.single.id;
    expect(env.container.read(queryRunProvider(id)).highlight, isNotNull);
    setText(env.container, 'select 12');
    await tester.pump();
    expect(env.container.read(queryRunProvider(id)).highlight, isNull);
  });

  testWidgets('closing a tab closes its session and result', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    setText(env.container, 'select 1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-button')));
    await tester.pumpAndSettle();
    final id = env.container.read(editorTabsProvider).tabs.single.id;
    await tester.tap(find.byKey(Key('close-$id')));
    await tester.pumpAndSettle();
    expect(env.repo.closedResults, ['res-1']);
    expect(env.repo.closedSessions, ['session-1']);
  });

  testWidgets('multi-statement results get chips to switch between them', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    env.repo.script = [
      const PlanEvent([TextSpanRange(0, 8), TextSpanRange(10, 18)]),
      const StartedEvent(0, 'a'),
      const ColumnsEvent(0, fakeColumns),
      RowsEvent(0, [fakeRow(0)]),
      const SummaryEvent(
        statementIndex: 0,
        rowsAffected: 0,
        rowsSpooled: 1,
        duration: Duration.zero,
        notices: [],
        truncated: false,
        hasRows: true,
      ),
      const StartedEvent(1, 'b'),
      const SummaryEvent(
        statementIndex: 1,
        rowsAffected: 4,
        rowsSpooled: 0,
        duration: Duration.zero,
        notices: [],
        truncated: false,
        hasRows: false,
      ),
    ];
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    setText(env.container, 'select 1; update x');
    await tester.pump();
    await chord(tester, LogicalKeyboardKey.enter, shift: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result-chip-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-chip-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rows-affected')), findsOneWidget);
    expect(find.text('OK · 4 rows affected'), findsOneWidget);
  });

  testWidgets('the palette lists the editor commands', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('details-new-query')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    expect(find.text('New query tab'), findsOneWidget);
    expect(find.text('Run statement at cursor'), findsOneWidget);
    expect(find.text('Run all statements'), findsOneWidget);
    expect(find.text('Cancel running statement'), findsOneWidget);
  });
}
