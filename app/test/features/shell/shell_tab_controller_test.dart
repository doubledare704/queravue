import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';

import '../../support/shell_workspace_fakes.dart';

String openShellTab(ShellEnv env) =>
    env.container.read(editorTabsProvider.notifier).openShell('c1').id;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'runs a script and collects prints, values and the end marker',
    () async {
      final env = await makeShellEnv();
      env.shell.scripts.add(const [
        ShellPrint(PrintLevel.log, 'hello'),
        ShellValue(ValueKind.scalar, '{"\$numberInt":"3"}'),
        ShellValue(
          ValueKind.write,
          '{"acknowledged":true}',
          writeOp: 'insertOne',
        ),
        ShellDone(Duration(milliseconds: 12)),
      ]);
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('print("hello")');

      final s = env.container.read(shellTabProvider(id));
      expect(s.phase, ShellPhase.idle);
      expect(s.entries.map((e) => e.runtimeType), [
        OutputRun,
        OutputPrint,
        OutputValue,
        OutputValue,
        OutputDone,
      ]);
      expect((s.entries[3] as OutputValue).writeOp, 'insertOne');
      expect(env.shell.evals.single.code, 'print("hello")');
      expect(env.shell.evals.single.confirmed, isFalse);
      expect(env.query.openSessions, 1);
      expect(env.shell.opened.single.sessionId, 'session-1');
    },
  );

  test('the shell is opened once and reused for later runs', () async {
    final env = await makeShellEnv();
    final id = openShellTab(env);
    final c = env.container.read(shellTabProvider(id).notifier);
    await c.run('1');
    await c.run('2');
    expect(env.shell.opened.length, 1);
    expect(env.shell.evals.map((e) => e.shellId).toSet(), {'shell-1'});
  });

  test('blank code does nothing', () async {
    final env = await makeShellEnv();
    final id = openShellTab(env);
    await env.container.read(shellTabProvider(id).notifier).run('  \n ');
    expect(env.shell.evals, isEmpty);
    expect(env.container.read(shellTabProvider(id)).entries, isEmpty);
  });

  test('errors point into the buffer, shifted by the run offset', () async {
    final env = await makeShellEnv();
    env.shell.scripts.add(const [
      ShellErrorEvent(
        ShellFailure(
          kind: ShellErrorKind.runtime,
          message: 'boom',
          line: 2,
          column: 5,
        ),
      ),
    ]);
    final id = openShellTab(env);
    await env.container
        .read(shellTabProvider(id).notifier)
        .run('a\nb', lineOffset: 10);
    final e =
        env.container.read(shellTabProvider(id)).entries.last as OutputError;
    expect(e.line, 11, reason: 'line 2 of a run that starts at buffer line 10');
    expect(e.column, 5);
    expect(e.failure.message, 'boom');
  });

  test('an error without a position has no line to jump to', () async {
    final env = await makeShellEnv();
    env.shell.scripts.add(const [
      ShellErrorEvent(
        ShellFailure(kind: ShellErrorKind.server, message: 'duplicate key'),
      ),
    ]);
    final id = openShellTab(env);
    await env.container
        .read(shellTabProvider(id).notifier)
        .run('x', lineOffset: 4);
    expect(
      (env.container.read(shellTabProvider(id)).entries.last as OutputError)
          .line,
      0,
    );
  });

  group('production confirmation', () {
    const gated = ShellErrorEvent(
      ShellFailure(
        kind: ShellErrorKind.confirmationRequired,
        message: 'confirmation required: deleteMany({}) on shop.orders',
        operation: 'deleteMany({}) on shop.orders',
      ),
    );

    test('a gated operation is held, not shown as an error', () async {
      final env = await makeShellEnv(production: true);
      env.shell.scripts.add(const [gated]);
      final id = openShellTab(env);
      await env.container
          .read(shellTabProvider(id).notifier)
          .run('db.orders.deleteMany({})', lineOffset: 3);
      final s = env.container.read(shellTabProvider(id));
      expect(s.pending!.operation, 'deleteMany({}) on shop.orders');
      expect(s.pending!.code, 'db.orders.deleteMany({})');
      expect(s.entries.whereType<OutputError>(), isEmpty);
      expect(s.busy, isFalse);
    });

    test('confirming re-runs the same code with confirmed=true', () async {
      final env = await makeShellEnv(production: true);
      env.shell.scripts
        ..add(const [gated])
        ..add(const [ShellDone(Duration.zero)]);
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('db.orders.deleteMany({})');
      await c.confirmPending();
      expect(env.shell.evals.map((e) => e.confirmed), [false, true]);
      expect(env.shell.evals[1].code, 'db.orders.deleteMany({})');
      expect(env.container.read(shellTabProvider(id)).pending, isNull);
    });

    test('declining runs nothing and says so', () async {
      final env = await makeShellEnv(production: true);
      env.shell.scripts.add(const [gated]);
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('db.orders.deleteMany({})');
      c.dismissPending();
      final s = env.container.read(shellTabProvider(id));
      expect(s.pending, isNull);
      expect(env.shell.evals.length, 1);
      expect(
        (s.entries.last as OutputError).failure.message,
        contains('nothing was changed'),
      );
    });

    test('a run without confirmation never sends confirmed=true', () async {
      final env = await makeShellEnv(production: true);
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('1');
      await c.run('2');
      expect(env.shell.evals.every((e) => !e.confirmed), isTrue);
    });
  });

  group('cancel', () {
    test(
      'the Cancel button appears after 300 ms and cancels the shell',
      () async {
        final env = await makeShellEnv();
        env.shell.holdOpen = Completer<void>();
        final id = openShellTab(env);
        final c = env.container.read(shellTabProvider(id).notifier);
        final run = c.run('while (true) {}');
        await settle(() => env.container.read(shellTabProvider(id)).busy);
        expect(env.container.read(shellTabProvider(id)).showCancel, isFalse);
        await Future<void>.delayed(
          kShellCancelDelay + const Duration(milliseconds: 80),
        );
        expect(env.container.read(shellTabProvider(id)).showCancel, isTrue);

        await c.cancel();
        expect(env.shell.cancelled, ['shell-1']);
        env.shell.cancelled.clear();
        await run.timeout(const Duration(milliseconds: 1), onTimeout: () {});
      },
    );

    test('cancel does nothing while idle', () async {
      final env = await makeShellEnv();
      final id = openShellTab(env);
      await env.container.read(shellTabProvider(id).notifier).cancel();
      expect(env.shell.cancelled, isEmpty);
    });

    test('a second run is ignored while one is in flight', () async {
      final env = await makeShellEnv();
      final hold = env.shell.holdOpen = Completer<void>();
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      final first = c.run('1');
      await settle(() => env.container.read(shellTabProvider(id)).busy);
      await c.run('2');
      expect(env.shell.evals.length, 1);
      hold.complete();
      await first;
      expect(env.container.read(shellTabProvider(id)).busy, isFalse);
    });
  });

  group('connecting', () {
    test('a connection without the shell capability says so', () async {
      final env = await makeShellEnv(capabilities: {'connect', 'execute'});
      final id = openShellTab(env);
      await env.container.read(shellTabProvider(id).notifier).run('1');
      final s = env.container.read(shellTabProvider(id));
      expect(s.connectionError, contains('does not support the shell'));
      expect(env.shell.evals, isEmpty);
    });

    test('a failed connection is reported and a later run can retry', () async {
      final env = await makeShellEnv();
      env.query.openError = StateError('refused');
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('1');
      expect(
        env.container.read(shellTabProvider(id)).connectionError,
        contains('refused'),
      );
      env.query.openError = null;
      await c.run('1');
      expect(env.container.read(shellTabProvider(id)).connectionError, isNull);
      expect(env.shell.evals.length, 1);
    });

    test('a shell that failed to start is reported', () async {
      final env = await makeShellEnv();
      env.shell.openError = StateError('no core');
      final id = openShellTab(env);
      await env.container.read(shellTabProvider(id).notifier).run('1');
      expect(
        env.container.read(shellTabProvider(id)).connectionError,
        contains('Cannot start the shell'),
      );
    });
  });

  test(
    'a shell the core forgot is dropped so the next run restarts it',
    () async {
      final env = await makeShellEnv();
      final id = openShellTab(env);
      final c = env.container.read(shellTabProvider(id).notifier);
      await c.run('1');
      env.shell.evalError = const GrpcError.notFound('shell not found');
      await c.run('2');
      var s = env.container.read(shellTabProvider(id));
      expect(s.shellId, isNull);
      expect(
        (s.entries.last as OutputError).failure.message,
        contains('shell was closed'),
      );
      await c.run('3');
      s = env.container.read(shellTabProvider(id));
      expect(s.shellId, 'shell-2');
    },
  );

  test('clear empties the output', () async {
    final env = await makeShellEnv();
    final id = openShellTab(env);
    final c = env.container.read(shellTabProvider(id).notifier);
    await c.run('1');
    expect(env.container.read(shellTabProvider(id)).entries, isNotEmpty);
    c.clear();
    expect(env.container.read(shellTabProvider(id)).entries, isEmpty);
  });

  test('closing the tab closes its shell', () async {
    final env = await makeShellEnv();
    final id = openShellTab(env);
    await env.container.read(shellTabProvider(id).notifier).run('1');
    env.container.read(editorTabsProvider.notifier).close(id);
    await settle(() => env.shell.closed.isNotEmpty);
    expect(env.shell.closed, ['shell-1']);
  });

  test('cursor results become output entries', () async {
    final env = await makeShellEnv();
    env.shell.scripts.add(const [
      ShellCursorEvent(
        CursorHandle(
          cursorId: 'cursor1',
          kind: CursorKind.find,
          database: 'shop',
          collection: 'users',
        ),
      ),
    ]);
    final id = openShellTab(env);
    await env.container
        .read(shellTabProvider(id).notifier)
        .run('db.users.find()');
    expect(
      (env.container.read(shellTabProvider(id)).entries.last as OutputCursor)
          .handle
          .collection,
      'users',
    );
  });
}
