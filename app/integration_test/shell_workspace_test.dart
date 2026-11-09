// End-to-end: real app + real queravued + the docker Mongo replica set.
//
//   make db-up
//   make test-e2e-shell
//
// Writes a Mongo script in a shell tab, saves it to the workspace, restarts
// the app (a fresh core process), reopens the file from the workspace and
// runs it against the real server. QUERAVUE_WORKSPACE and QUERAVUE_CONFIG_DIR
// point the core at scratch folders (the Makefile target sets them).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/application/layout_persistence.dart';
import 'package:queravue/features/shell/application/cursor_page_controller.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';
import 'package:queravue/features/workspace/application/tab_files.dart';
import 'package:queravue/features/workspace/data/workspace_repository.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

Future<void> _pumpUntil(
  WidgetTester tester,
  String what,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('timed out waiting for $what');
}

Future<ProviderContainer> _startApp(WidgetTester tester) async {
  final container = ProviderContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const QueravueApp()),
  );
  await _pumpUntil(
    tester,
    'core connected',
    () => container.read(coreStatusProvider) is CoreConnected,
  );
  await container.read(connectionsControllerProvider.future);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _stopApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
}

bool _finished(ProviderContainer c, String tabId, int runs) =>
    c.read(shellTabProvider(tabId)).entries.whereType<OutputDone>().length >=
    runs;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'save a Mongo script, restart the app, reopen it and run it',
    timeout: const Timeout(Duration(minutes: 5)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final workspaceDir = Platform.environment['QUERAVUE_WORKSPACE'];
      expect(
        workspaceDir,
        isNotNull,
        reason:
            'run through `make test-e2e-shell`: it points the core at a '
            'scratch workspace',
      );
      final host =
          '${_env('MONGO_HOST', '127.0.0.1')}:${_env('MONGO_PORT', '27017')}';

      // ---- first run: write the script, run it, save it ----
      var container = await _startApp(tester);
      final connections = container.read(connectionsRepositoryProvider);
      final saved = await connections.create(
        ConnectionProfile(
          name: 'e2e shell mongo',
          engineId: 'mongodb',
          params: {
            'hosts': host,
            'replica_set': 'rs0',
            'database': 'queravue_e2e',
          },
        ),
      );
      addTearDown(() async {
        try {
          await connections.delete(saved.id);
        } catch (_) {}
      });
      await container.read(connectionsControllerProvider.notifier).reload();
      container.read(selectedConnectionProvider.notifier).select(saved.id);
      await tester.pumpAndSettle();

      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(saved.id).notifier)
            .connect(),
      );
      expect(session, isNotNull, reason: 'is the dev Mongo up?');
      expect(session!.capabilities, contains('shell'));
      expect(container.read(connectionHasShellProvider(saved.id)), isTrue);

      const script =
          'db.shell_e2e.deleteMany({});\n'
          'db.shell_e2e.insertMany([{_id: 1, n: NumberLong("5")}, '
          '{_id: 2, n: NumberLong("7")}]);\n'
          'db.shell_e2e.find().sort({_id: 1})';
      final tab = container
          .read(editorTabsProvider.notifier)
          .openShell(saved.id);
      tab.controller.text = script;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell-run')));
      await _pumpUntil(
        tester,
        'script finished',
        () => _finished(container, tab.id, 1),
      );
      var out = container.read(shellTabProvider(tab.id));
      expect(out.entries.whereType<OutputError>(), isEmpty);
      final cursor = out.entries.whereType<OutputCursor>().single;
      final key = CursorKey(out.shellId!, cursor.handle.cursorId);
      await _pumpUntil(
        tester,
        'cursor page',
        () => container.read(cursorPageProvider(key)).docs.isNotEmpty,
      );
      expect(container.read(cursorPageProvider(key)).docs.length, 2);
      expect(
        container.read(cursorPageProvider(key)).docs.first.text,
        contains('"\$numberLong":"5"'),
        reason: 'Int64 survives the round trip',
      );

      final workspace = container.read(workspaceRepositoryProvider);
      final roots = await tester.runAsync(workspace.roots);
      final root = roots!.first;
      expect(root.path, workspaceDir);
      final file = FilePath(root.id, 'e2e/items.mongo.js');
      final body =
          '// title: Shell e2e items\n'
          '// connection: e2e shell mongo\n\n$script';
      final saveOutcome = await tester.runAsync(
        () =>
            container.read(tabFileProvider(tab.id).notifier).saveAs(file, body),
      );
      expect(saveOutcome, isA<Saved>());
      expect(File('$workspaceDir/e2e/items.mongo.js').readAsStringSync(), body);
      expect(
        container
            .read(editorTabsProvider)
            .tabs
            .firstWhere((t) => t.id == tab.id)
            .title,
        'items.mongo.js',
      );
      await tester.runAsync(container.read(layoutPersistenceProvider).flush);
      await _stopApp(tester, container);

      // ---- second run: a fresh app and core; reopen and run ----
      container = await _startApp(tester);
      addTearDown(container.dispose);
      await _pumpUntil(
        tester,
        'layout restored',
        () => container.read(editorTabsProvider).tabs.length == 1,
      );
      final entries = await tester.runAsync(
        () => container
            .read(workspaceRepositoryProvider)
            .listTree(FilePath(root.id, 'e2e')),
      );
      expect(entries!.single.name, 'items.mongo.js');
      expect(entries.single.meta.title, 'Shell e2e items');
      expect(entries.single.meta.connection, 'e2e shell mongo');

      final opened = await tester.runAsync(
        () => container.read(fileOpenerProvider).open(file),
      );
      expect(opened, isA<Opened>());
      final reopened = container.read(editorTabsProvider).tabs.single;
      expect(reopened.isShell, isTrue);
      expect(
        reopened.connectionId,
        saved.id,
        reason: 'the header names the connection',
      );
      expect(reopened.controller.text, body);
      expect(
        isTabDirty(reopened, container.read(tabFileProvider(reopened.id))),
        isFalse,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell-run')));
      await _pumpUntil(
        tester,
        'reopened script finished',
        () => _finished(container, reopened.id, 1),
      );
      out = container.read(shellTabProvider(reopened.id));
      expect(out.entries.whereType<OutputError>(), isEmpty);
      final cursor2 = out.entries.whereType<OutputCursor>().single;
      final key2 = CursorKey(out.shellId!, cursor2.handle.cursorId);
      await _pumpUntil(
        tester,
        'cursor page of the reopened script',
        () => container.read(cursorPageProvider(key2)).docs.isNotEmpty,
      );
      expect(container.read(cursorPageProvider(key2)).docs.length, 2);

      // Drop the scratch collection.
      reopened.controller.text = 'db.shell_e2e.drop()';
      await tester.tap(find.byKey(const Key('shell-run')));
      await _pumpUntil(
        tester,
        'cleanup',
        () => _finished(container, reopened.id, 2),
      );
    },
  );
}
