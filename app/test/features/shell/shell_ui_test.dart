import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';
import 'package:re_editor/re_editor.dart';

import '../../support/fake_query_repository.dart';
import '../../support/shell_workspace_fakes.dart';

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(version: '0.1.0-dev', protocolVersion: 6, capabilities: {'query'}),
  );
}

Future<ShellEnv> pumpApp(
  WidgetTester tester, {
  bool production = false,
  String selected = 'c1',
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shell = FakeShellRepository();
  final workspace = FakeWorkspaceRepository();
  final query = FakeQueryRepository()
    ..capabilities = {'connect', 'document_store', 'shell'};
  final container = ProviderContainer(
    overrides: [
      ...shellOverrides(
        shell: shell,
        workspace: workspace,
        query: query,
        production: production,
      ),
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
  container.read(selectedConnectionProvider.notifier).select(selected);
  await tester.pumpAndSettle();
  return (
    container: container,
    shell: shell,
    workspace: workspace,
    query: query,
  );
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

EditorTab shellTab(ShellEnv e) =>
    e.container.read(editorTabsProvider).tabs.singleWhere((t) => t.isShell);

void main() {
  testWidgets(
    'the new shell button exists only on connections with the shell capability',
    (tester) async {
      await pumpApp(tester, selected: 'c2');
      // c2 is a SQL connection: no tab yet, details view is shown.
      final env = await pumpApp(tester);
      env.container.read(editorTabsProvider.notifier).open('c1');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-shell-tab')), findsOneWidget);
      env.container.read(editorTabsProvider.notifier).open('c2');
      env.container.read(selectedConnectionProvider.notifier).select('c2');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-shell-tab')), findsNothing);
      expect(find.byKey(const Key('new-tab')), findsOneWidget);
    },
  );

  testWidgets(
    'Ctrl+Shift+T opens a shell tab; Ctrl+Enter runs the buffer and shows output',
    (tester) async {
      final env = await pumpApp(tester);
      env.container.read(editorTabsProvider.notifier).open('c1');
      await tester.pumpAndSettle();
      await chord(tester, LogicalKeyboardKey.keyT, shift: true);
      await tester.pumpAndSettle();
      expect(find.text('Shell 1'), findsOneWidget);
      expect(find.byKey(const Key('shell-run')), findsOneWidget);

      env.shell.scripts.add(const [
        ShellPrint(PrintLevel.log, 'hello from the shell'),
        ShellValue(ValueKind.scalar, '{"\$numberInt":"2"}'),
        ShellDone(Duration(milliseconds: 5)),
      ]);
      shellTab(env).controller.text = 'print("hello from the shell")\n1 + 1';
      await chord(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        env.shell.evals.single.code,
        'print("hello from the shell")\n1 + 1',
      );
      expect(find.text('hello from the shell'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('done in 5 ms'), findsOneWidget);
    },
  );

  testWidgets('with a selection only the selection runs', (tester) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    tab.controller.text = 'var a = 1\ndb.t.find()\nvar b = 2';
    tab.controller.selection = const CodeLineSelection(
      baseIndex: 1,
      baseOffset: 0,
      extentIndex: 1,
      extentOffset: 11,
    );
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    expect(env.shell.evals.single.code, 'db.t.find()');
  });

  testWidgets('clicking an error moves the caret to its line', (tester) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    env.shell.scripts.add(const [
      ShellErrorEvent(
        ShellFailure(
          kind: ShellErrorKind.runtime,
          message: 'ReferenceError: x is not defined',
          line: 3,
          column: 3,
        ),
      ),
    ]);
    tab.controller.text = 'var a = 1\nvar b = 2\nx.y\nvar c = 3';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('output-error')));
    await tester.pumpAndSettle();
    final sel = tab.controller.selection;
    expect(sel.baseIndex, 2);
    expect(sel.baseOffset, 2, reason: 'column 3 is offset 2');
  });

  testWidgets(
    'a gated operation on a production connection asks, then re-runs with confirmation',
    (tester) async {
      final env = await pumpApp(tester, production: true);
      final tab = env.container
          .read(editorTabsProvider.notifier)
          .openShell('c1');
      await tester.pumpAndSettle();
      env.shell.scripts
        ..add(const [
          ShellErrorEvent(
            ShellFailure(
              kind: ShellErrorKind.confirmationRequired,
              message: 'confirmation required',
              operation: 'deleteMany({}) on shop.orders',
            ),
          ),
        ])
        ..add(const [ShellDone(Duration.zero)]);
      tab.controller.text = 'db.orders.deleteMany({})';
      await tester.tap(find.byKey(const Key('shell-run')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shell-confirm')), findsOneWidget);
      expect(
        find.textContaining('deleteMany({}) on shop.orders'),
        findsOneWidget,
      );
      expect(find.textContaining('Mongo is marked production'), findsOneWidget);
      expect(
        env.shell.evals.length,
        1,
        reason: 'nothing re-run before the user agrees',
      );

      await tester.tap(find.byKey(const Key('shell-confirm-run')));
      await tester.pumpAndSettle();
      expect(env.shell.evals.map((e) => e.confirmed), [false, true]);
      expect(find.byKey(const Key('shell-confirm')), findsNothing);
    },
  );

  testWidgets('declining the confirmation runs nothing more', (tester) async {
    final env = await pumpApp(tester, production: true);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    env.shell.scripts.add(const [
      ShellErrorEvent(
        ShellFailure(
          kind: ShellErrorKind.confirmationRequired,
          message: 'x',
          operation: 'drop shop.orders',
        ),
      ),
    ]);
    tab.controller.text = 'db.orders.drop()';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell-confirm-cancel')));
    await tester.pumpAndSettle();
    expect(env.shell.evals.length, 1);
    expect(find.textContaining('nothing was changed'), findsOneWidget);
  });

  testWidgets('Cancel appears after 300 ms and Esc cancels the script', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    final hold = env.shell.holdOpen = Completer<void>();
    tab.controller.text = 'while (true) {}';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('shell-cancel')), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('shell-cancel')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('shell-run'))).onPressed,
      isNull,
      reason: 'Run is disabled while running',
    );

    await tester.tap(find.byKey(const Key('shell-cancel')));
    await tester.pump();
    expect(env.shell.cancelled, ['shell-1']);
    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell-cancel')), findsNothing);

    env.shell.holdOpen = Completer<void>();
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(env.shell.cancelled.length, 2);
    env.shell.holdOpen = null;
  });

  testWidgets('a cursor result is shown as a document table with paging', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    env.shell
      ..cursorDocs = [
        for (var i = 0; i < 30; i++)
          '{"_id":{"\$numberInt":"$i"},"name":"doc-$i"}',
      ]
      ..scripts.add(const [
        ShellCursorEvent(
          CursorHandle(
            cursorId: 'cursor1',
            kind: CursorKind.find,
            database: 'shop',
            collection: 'users',
          ),
        ),
      ]);
    tab.controller.text = 'db.users.find()';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cursor-table')), findsOneWidget);
    expect(find.text('1–20'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cursor-next')));
    await tester.pumpAndSettle();
    expect(find.text('21–30'), findsOneWidget);
  });

  testWidgets('a connection error shows a banner', (tester) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    env.query.openError = StateError('connection refused');
    tab.controller.text = '1';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell-connection-error')), findsOneWidget);
    expect(find.textContaining('connection refused'), findsOneWidget);
  });

  testWidgets('clear empties the output', (tester) async {
    final env = await pumpApp(tester);
    final tab = env.container.read(editorTabsProvider.notifier).openShell('c1');
    await tester.pumpAndSettle();
    env.shell.scripts.add(const [
      ShellPrint(PrintLevel.log, 'x'),
      ShellDone(Duration.zero),
    ]);
    tab.controller.text = 'print("x")';
    await tester.tap(find.byKey(const Key('shell-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('output-print')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell-output-empty')), findsOneWidget);
    expect(env.container.read(shellTabProvider(tab.id)).entries, isEmpty);
  });
}
