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
import 'package:queravue/features/workspace/application/tab_files.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import '../../support/fake_query_repository.dart';
import '../../support/shell_workspace_fakes.dart';

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(version: '0.1.0-dev', protocolVersion: 6, capabilities: {'query'}),
  );
}

const _files = {
  'reports/users.sql':
      '-- title: Active users\n-- tags: reports\nSELECT * FROM users',
  'reports/orders.sql': 'SELECT total FROM orders',
  'jobs/clean.mongo.js':
      '// connection: Mongo\ndb.logs.deleteMany({old: true})',
  'readme.txt': 'hello',
};

Future<ShellEnv> pumpApp(WidgetTester tester, {bool openPanel = true}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shell = FakeShellRepository();
  final workspace = FakeWorkspaceRepository(files: _files);
  final query = FakeQueryRepository()
    ..capabilities = {'connect', 'document_store', 'shell', 'execute'};
  final container = ProviderContainer(
    overrides: [
      ...shellOverrides(shell: shell, workspace: workspace, query: query),
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
  if (openPanel) {
    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
  }
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

Future<void> openFile(WidgetTester tester, String path) async {
  await tester.tap(find.byKey(Key('ws-row-$path')));
  await tester.pumpAndSettle();
}

EditorTab onlyTab(ShellEnv e) =>
    e.container.read(editorTabsProvider).tabs.single;

void main() {
  testWidgets('the sidebar switches to the workspace tree', (tester) async {
    await pumpApp(tester, openPanel: false);
    expect(find.byKey(const Key('ws-tree')), findsNothing);
    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ws-tree')), findsOneWidget);
    // Root, then folders first, then files; folders start collapsed.
    expect(find.byKey(const Key('ws-row-ws')), findsOneWidget);
    expect(find.byKey(const Key('ws-row-jobs')), findsOneWidget);
    expect(find.byKey(const Key('ws-row-reports')), findsOneWidget);
    expect(find.byKey(const Key('ws-row-readme.txt')), findsOneWidget);
    expect(find.byKey(const Key('ws-row-reports/users.sql')), findsNothing);

    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ws-tree')), findsNothing);
  });

  testWidgets('folders expand and show titles from the header', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('ws-row-reports')));
    await tester.pumpAndSettle();
    expect(
      find.text('Active users'),
      findsOneWidget,
      reason: 'title replaces the file name',
    );
    expect(find.text('orders.sql'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ws-row-reports')));
    await tester.pumpAndSettle();
    expect(find.text('orders.sql'), findsNothing);
  });

  testWidgets('a Mongo script opens in a shell tab on its default connection', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('ws-row-jobs')));
    await tester.pumpAndSettle();
    await openFile(tester, 'jobs/clean.mongo.js');
    final tab = onlyTab(env);
    expect(tab.isShell, isTrue);
    expect(tab.title, 'clean.mongo.js');
    expect(tab.controller.text, contains('deleteMany'));
    expect(find.byKey(const Key('shell-run')), findsOneWidget);
  });

  testWidgets('a SQL file opens in the SQL editor', (tester) async {
    final env = await pumpApp(tester);
    env.container.read(selectedConnectionProvider.notifier).select('c2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ws-row-reports')));
    await tester.pumpAndSettle();
    await openFile(tester, 'reports/orders.sql');
    final tab = onlyTab(env);
    expect(tab.isQuery, isTrue);
    expect(tab.connectionId, 'c2');
    expect(find.byKey(const Key('run-button')), findsOneWidget);
  });

  testWidgets('opening a file with no suitable connection explains why', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    env.container.read(selectedConnectionProvider.notifier).select(null);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ws-row-reports')));
    await tester.pumpAndSettle();
    await openFile(tester, 'reports/orders.sql');
    expect(find.textContaining('Select a SQL connection'), findsOneWidget);
    expect(env.container.read(editorTabsProvider).tabs, isEmpty);
  });

  group('search', () {
    testWidgets('finds files by text and tag, and opens a hit', (tester) async {
      final env = await pumpApp(tester);
      env.container.read(selectedConnectionProvider.notifier).select('c2');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('ws-search')), 'FROM users');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-results')), findsOneWidget);
      expect(find.byKey(const Key('ws-hit-reports/users.sql')), findsOneWidget);
      expect(find.byKey(const Key('ws-hit-reports/orders.sql')), findsNothing);
      expect(
        find.textContaining('SELECT * FROM users'),
        findsOneWidget,
        reason: 'snippet',
      );

      await tester.enterText(find.byKey(const Key('ws-search')), '#reports');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-hit-reports/users.sql')), findsOneWidget);

      await tester.tap(find.byKey(const Key('ws-hit-reports/users.sql')));
      await tester.pumpAndSettle();
      expect(onlyTab(env).title, 'users.sql');
    });

    testWidgets('no match says so; clearing the box returns to the tree', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.enterText(find.byKey(const Key('ws-search')), 'zzzzzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-no-hits')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('ws-search')), '');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-tree')), findsOneWidget);
    });

    testWidgets('Ctrl+Shift+F shows the panel and focuses the search box', (
      tester,
    ) async {
      await pumpApp(tester, openPanel: false);
      await chord(tester, LogicalKeyboardKey.keyF, shift: true);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-search')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('ws-search')),
      );
      expect(field.focusNode!.hasFocus, isTrue);
    });
  });

  group('file actions', () {
    testWidgets('new SQL file asks for a name, creates and opens it', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      env.container.read(selectedConnectionProvider.notifier).select('c2');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ws-new-sql')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prompt-field')), 'daily');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(env.workspace.contents.containsKey('daily.sql'), isTrue);
      expect(onlyTab(env).title, 'daily.sql');
      expect(find.byKey(const Key('ws-row-daily.sql')), findsOneWidget);
    });

    testWidgets('creating over an existing file reports it', (tester) async {
      final env = await pumpApp(tester);
      env.container.read(selectedConnectionProvider.notifier).select('c2');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ws-new-sql')));
      await tester.pumpAndSettle();
      env.workspace.put('query.sql', 'SELECT 0');
      await tester.enterText(find.byKey(const Key('prompt-field')), 'query');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(find.textContaining('already exists'), findsOneWidget);
      expect(env.workspace.contents['query.sql'], 'SELECT 0');
    });

    testWidgets('new folder', (tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('ws-new-folder')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prompt-field')), 'archive');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(env.workspace.dirs, contains('archive'));
      expect(find.byKey(const Key('ws-row-archive')), findsOneWidget);
    });

    testWidgets('rename or move through the row menu', (tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('ws-menu-readme.txt')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename / move…'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('prompt-field')),
        'jobs/notes.txt',
      );
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(env.workspace.contents.containsKey('jobs/notes.txt'), isTrue);
      expect(env.workspace.contents.containsKey('readme.txt'), isFalse);
      expect(find.byKey(const Key('ws-row-readme.txt')), findsNothing);
    });

    testWidgets('delete asks first', (tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('ws-menu-readme.txt')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete file?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(env.workspace.deleted, isEmpty);

      await tester.tap(find.byKey(const Key('ws-menu-readme.txt')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await tester.pumpAndSettle();
      expect(env.workspace.deleted, ['readme.txt']);
      expect(find.byKey(const Key('ws-row-readme.txt')), findsNothing);
    });

    testWidgets('a root has no rename or delete', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('ws-menu-ws')));
      await tester.pumpAndSettle();
      expect(find.text('New SQL file'), findsWidgets);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Rename / move…'), findsNothing);
    });
  });

  group('saving', () {
    Future<ShellEnv> openScript(WidgetTester tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('ws-row-jobs')));
      await tester.pumpAndSettle();
      await openFile(tester, 'jobs/clean.mongo.js');
      return env;
    }

    testWidgets('editing shows a dirty dot; Ctrl+S saves and clears it', (
      tester,
    ) async {
      final env = await openScript(tester);
      final tab = onlyTab(env);
      expect(find.byKey(Key('tab-dirty-${tab.id}')), findsNothing);
      tab.controller.text = 'db.logs.find()';
      await tester.pumpAndSettle();
      expect(find.byKey(Key('tab-dirty-${tab.id}')), findsOneWidget);

      await chord(tester, LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();
      expect(env.workspace.contents['jobs/clean.mongo.js'], 'db.logs.find()');
      expect(find.byKey(Key('tab-dirty-${tab.id}')), findsNothing);
    });

    testWidgets('a file changed on disk asks before it is overwritten', (
      tester,
    ) async {
      final env = await openScript(tester);
      final tab = onlyTab(env);
      tab.controller.text = 'mine';
      env.workspace.put('jobs/clean.mongo.js', 'theirs');
      await chord(tester, LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict-dialog')), findsOneWidget);
      expect(env.workspace.contents['jobs/clean.mongo.js'], 'theirs');

      await tester.tap(find.byKey(const Key('conflict-keep')));
      await tester.pumpAndSettle();
      expect(env.workspace.contents['jobs/clean.mongo.js'], 'mine');
    });

    testWidgets('the conflict dialog can reload the disk version instead', (
      tester,
    ) async {
      final env = await openScript(tester);
      final tab = onlyTab(env);
      tab.controller.text = 'mine';
      env.workspace.put('jobs/clean.mongo.js', 'theirs');
      await chord(tester, LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conflict-reload')));
      await tester.pumpAndSettle();
      expect(tab.controller.text, 'theirs');
      expect(env.workspace.contents['jobs/clean.mongo.js'], 'theirs');
    });

    testWidgets('an external edit raises a banner with reload and keep mine', (
      tester,
    ) async {
      final env = await openScript(tester);
      final tab = onlyTab(env);
      env.workspace.editExternally('jobs/clean.mongo.js', 'from git');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('file-change-banner')), findsOneWidget);
      expect(find.text('clean.mongo.js changed on disk.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('banner-keep')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('file-change-banner')), findsNothing);
      expect(tab.controller.text, contains('deleteMany'));

      env.workspace.editExternally('jobs/clean.mongo.js', 'again');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('banner-reload')));
      await tester.pumpAndSettle();
      expect(tab.controller.text, 'again');
      expect(find.byKey(const Key('file-change-banner')), findsNothing);
    });

    testWidgets('a deleted file raises a banner without reload', (
      tester,
    ) async {
      final env = await openScript(tester);
      env.workspace.removeExternally('jobs/clean.mongo.js');
      await tester.pumpAndSettle();
      expect(find.text('clean.mongo.js was deleted on disk.'), findsOneWidget);
      expect(find.byKey(const Key('banner-reload')), findsNothing);
      expect(find.byKey(const Key('banner-keep')), findsOneWidget);
    });

    testWidgets(
      'Ctrl+S on an unsaved tab asks where to save; the file gets a header',
      (tester) async {
        final env = await pumpApp(tester);
        final tab = env.container
            .read(editorTabsProvider.notifier)
            .openShell('c1');
        await tester.pumpAndSettle();
        tab.controller.text = 'db.users.find()';
        await chord(tester, LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('save-as-dialog')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('save-as-path')),
          'saved/list',
        );
        await tester.enterText(
          find.byKey(const Key('save-as-title')),
          'List users',
        );
        await tester.tap(find.byKey(const Key('save-as-ok')));
        await tester.pumpAndSettle();
        final saved = env.workspace.contents['saved/list.mongo.js']!;
        expect(
          saved,
          startsWith('// title: List users\n// connection: Mongo\n'),
        );
        expect(saved, endsWith('db.users.find()'));
        expect(
          find.text('list.mongo.js'),
          findsOneWidget,
          reason: 'tab renamed',
        );
        expect(
          env.container.read(tabFileProvider(tab.id))!.file,
          const FilePath('ws', 'saved/list.mongo.js'),
        );
        expect(find.byKey(Key('tab-dirty-${tab.id}')), findsNothing);
      },
    );

    testWidgets(
      'save as without remembering the connection leaves no connection line',
      (tester) async {
        final env = await pumpApp(tester);
        final tab = env.container.read(editorTabsProvider.notifier).open('c2');
        env.container.read(selectedConnectionProvider.notifier).select('c2');
        await tester.pumpAndSettle();
        tab.controller.text = 'SELECT 1';
        await chord(tester, LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('save-as-path')), 'one');
        await tester.tap(find.byKey(const Key('save-as-remember')));
        await tester.tap(find.byKey(const Key('save-as-ok')));
        await tester.pumpAndSettle();
        expect(env.workspace.contents['one.sql'], 'SELECT 1');
      },
    );

    testWidgets('save as onto an existing file asks before overwriting', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      final tab = env.container.read(editorTabsProvider.notifier).open('c2');
      env.container.read(selectedConnectionProvider.notifier).select('c2');
      await tester.pumpAndSettle();
      tab.controller.text = 'SELECT 42';
      await chord(tester, LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('save-as-path')),
        'reports/orders.sql',
      );
      await tester.tap(find.byKey(const Key('save-as-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict-dialog')), findsOneWidget);
      expect(
        env.workspace.contents['reports/orders.sql'],
        'SELECT total FROM orders',
      );
      await tester.tap(find.byKey(const Key('conflict-keep')));
      await tester.pumpAndSettle();
      expect(
        env.workspace.contents['reports/orders.sql'],
        contains('SELECT 42'),
      );
    });
  });

  group('command palette', () {
    Future<void> palette(WidgetTester tester, String query) async {
      await chord(tester, LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('palette-query')), query);
      await tester.pumpAndSettle();
    }

    testWidgets('lists the workspace commands', (tester) async {
      await pumpApp(tester, openPanel: false);
      await palette(tester, 'work');
      expect(find.byKey(const Key('palette-workspace.open')), findsOneWidget);
      expect(find.byKey(const Key('palette-workspace.search')), findsOneWidget);
      await palette(tester, 'new');
      expect(find.byKey(const Key('palette-workspace.newSql')), findsOneWidget);
      expect(
        find.byKey(const Key('palette-workspace.newMongo')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('palette-shell.new')), findsOneWidget);
    });

    testWidgets('Open workspace file searches and opens the pick', (
      tester,
    ) async {
      final env = await pumpApp(tester, openPanel: false);
      await palette(tester, 'open workspace');
      await tester.tap(find.byKey(const Key('palette-workspace.open')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('quick-open-query')),
        'clean',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick-open-jobs/clean.mongo.js')));
      await tester.pumpAndSettle();
      expect(onlyTab(env).title, 'clean.mongo.js');
    });

    testWidgets('Search workspace shows the panel', (tester) async {
      await pumpApp(tester, openPanel: false);
      await palette(tester, 'search work');
      await tester.tap(find.byKey(const Key('palette-workspace.search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ws-search')), findsOneWidget);
    });

    testWidgets('New Mongo script creates and opens a script', (tester) async {
      final env = await pumpApp(tester, openPanel: false);
      await palette(tester, 'new mongo script');
      await tester.tap(find.byKey(const Key('palette-workspace.newMongo')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('prompt-field')), 'cleanup');
      await tester.tap(find.byKey(const Key('prompt-ok')));
      await tester.pumpAndSettle();
      expect(env.workspace.contents.containsKey('cleanup.mongo.js'), isTrue);
      expect(onlyTab(env).isShell, isTrue);
    });
  });
}
