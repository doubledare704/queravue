import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/editor/application/editor_layout_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/application/layout_persistence.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/workspace/application/tab_files.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';
import 'package:queravue/shared/panes/pane_sizes.dart';

import '../../support/fake_query_repository.dart';
import '../../support/shell_workspace_fakes.dart';

Future<ProviderContainer> start(FakeWorkspaceRepository workspace) async {
  final query = FakeQueryRepository()
    ..capabilities = {'connect', 'document_store', 'shell'};
  final container = ProviderContainer(
    overrides: [
      ...shellOverrides(
        shell: FakeShellRepository(),
        workspace: workspace,
        query: query,
        fakeLayoutPersistence: false,
      ),
      layoutPersistenceProvider.overrideWith(LayoutPersistence.new),
    ],
  );
  addTearDown(container.dispose);
  await container.read(connectionsControllerProvider.future);
  return container;
}

Future<void> restored(ProviderContainer c) async {
  await c.read(layoutPersistenceProvider).restore();
}

EditorLayoutState layoutOf(ProviderContainer c) => c.read(editorLayoutProvider);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('groups follow the tabs', () {
    test(
      'closing the active tab shows its neighbour in the same group',
      () async {
        final c = await start(FakeWorkspaceRepository());
        final tabs = c.read(editorTabsProvider.notifier);
        final a = tabs.open('c2');
        final b = tabs.open('c2');
        final d = tabs.open('c2');
        c.read(editorLayoutProvider.notifier).split('c2', Axis.horizontal);
        expect(layoutOf(c).of('c2').groups.map((g) => g.tabIds), [
          [a.id, b.id],
          [d.id],
        ]);
        c.read(editorLayoutProvider.notifier).focusGroup('c2', 0);
        expect(c.read(editorTabsProvider).activeByConnection['c2'], b.id);
        tabs.close(b.id);
        expect(c.read(editorTabsProvider).activeByConnection['c2'], a.id);
        expect(layoutOf(c).of('c2').focused, 0);
      },
    );

    test('closing the last tab of a group removes the group', () async {
      final c = await start(FakeWorkspaceRepository());
      final tabs = c.read(editorTabsProvider.notifier);
      tabs.open('c2');
      final b = tabs.open('c2');
      c.read(editorLayoutProvider.notifier).split('c2', Axis.horizontal);
      tabs.close(b.id);
      expect(layoutOf(c).of('c2').groups, hasLength(1));
    });

    test('a new tab opens in the focused group', () async {
      final c = await start(FakeWorkspaceRepository());
      final tabs = c.read(editorTabsProvider.notifier);
      tabs.open('c2');
      tabs.open('c2');
      c.read(editorLayoutProvider.notifier).split('c2', Axis.horizontal);
      c.read(editorLayoutProvider.notifier).focusGroup('c2', 0);
      final fresh = tabs.open('c2');
      expect(layoutOf(c).of('c2').groups[0].tabIds, contains(fresh.id));
      expect(layoutOf(c).of('c2').focused, 0);
    });

    test('moving a tab to the next group refocuses it', () async {
      final c = await start(FakeWorkspaceRepository());
      final tabs = c.read(editorTabsProvider.notifier);
      final a = tabs.open('c2');
      tabs.open('c2');
      final controller = c.read(editorLayoutProvider.notifier);
      controller.split('c2', Axis.horizontal);
      controller.focusGroup('c2', 0);
      controller.moveActive('c2', 1);
      expect(layoutOf(c).of('c2').groups.single.tabIds, hasLength(2));
      expect(c.read(editorTabsProvider).activeByConnection['c2'], a.id);
    });
  });

  group('persistence', () {
    test('diagram tabs come back with their schema and saved file', () async {
      final workspace = FakeWorkspaceRepository();
      final first = await start(workspace);
      await restored(first);
      final tabs = first.read(editorTabsProvider.notifier);
      tabs.openDiagram('c2', database: 'shop', schema: 'public');
      tabs.openDiagram(
        'c2',
        schema: 'sales',
        savedFile: const FilePath('ws', '.queravue/diagrams/sales.json'),
        title: 'sales',
      );
      await first.read(layoutPersistenceProvider).flush();

      final second = await start(workspace);
      await restored(second);
      final diagrams = second
          .read(editorTabsProvider)
          .tabs
          .where((t) => t.isDiagram)
          .toList();
      expect(diagrams.map((t) => t.title), ['Diagram public', 'sales']);
      expect(
        diagrams[0].tableRef,
        const TableRef(database: 'shop', schema: 'public', table: ''),
      );
      expect(diagrams[0].diagramFile, isNull);
      expect(diagrams[1].tableRef!.schema, 'sales');
      expect(
        diagrams[1].diagramFile,
        const FilePath('ws', '.queravue/diagrams/sales.json'),
      );
    });

    test('pane sizes come back, maximize does not', () async {
      final workspace = FakeWorkspaceRepository();
      final first = await start(workspace);
      await restored(first);
      final panes = first.read(paneSizesProvider.notifier)
        ..dragSidebar(70)
        ..setEditorShare(0.65)
        ..toggleOutput()
        ..toggleEditorMaximized();
      expect(panes.state.editorMaximized, isTrue);
      await first.read(layoutPersistenceProvider).flush();

      final second = await start(workspace);
      await restored(second);
      expect(
        second.read(paneSizesProvider),
        const PaneSizes(
          sidebarWidth: 330,
          editorShare: 0.65,
          outputCollapsed: true,
        ),
      );
    });

    test('a split layout comes back with its tabs, files and drafts', () async {
      final workspace = FakeWorkspaceRepository(
        files: {'q/users.sql': 'SELECT * FROM users'},
      );
      final first = await start(workspace);
      final tabs = first.read(editorTabsProvider.notifier);
      await restored(first);
      first.read(selectedConnectionProvider.notifier).select('c2');
      final out =
          await first
                  .read(fileOpenerProvider)
                  .open(const FilePath('ws', 'q/users.sql'))
              as Opened;
      final scratch = tabs.open('c2');
      scratch.controller.text = 'SELECT draft';
      final third = tabs.open('c2');
      first.read(editorLayoutProvider.notifier).split('c2', Axis.horizontal);
      first.read(editorLayoutProvider.notifier).resize('c2', 0, 0.2);
      await first.read(layoutPersistenceProvider).flush();
      expect(workspace.contents, contains(layoutPath));

      final second = await start(workspace);
      await restored(second);
      final tabsAfter = second.read(editorTabsProvider).tabs;
      expect(tabsAfter.map((t) => t.title), [
        'users.sql',
        'Query 2',
        'Query 3',
      ]);
      final layout = second.read(editorLayoutProvider).of('c2');
      expect(layout.groups.map((g) => g.tabIds.length), [2, 1]);
      expect(layout.fractions[0], closeTo(0.7, 1e-9));
      expect(layout.focused, 1);
      expect(second.read(selectedConnectionProvider), 'c2');
      expect(out.tabId, isNotEmpty);
      expect(third.id, isNotEmpty);

      expect(tabsAfter[1].controller.text, 'SELECT draft');
    });

    test('a file-bound tab loads only when it is first shown', () async {
      final workspace = FakeWorkspaceRepository(
        files: {'q/users.sql': 'SELECT * FROM users'},
      );
      final first = await start(workspace);
      await restored(first);
      first.read(selectedConnectionProvider.notifier).select('c2');
      await first
          .read(fileOpenerProvider)
          .open(const FilePath('ws', 'q/users.sql'));
      first.read(editorTabsProvider.notifier).open('c2');
      await first.read(layoutPersistenceProvider).flush();

      final second = await start(workspace);
      await restored(second);
      final tab = second.read(editorTabsProvider).tabs.first;
      expect(tab.controller.text, isEmpty);
      expect(second.read(tabFileProvider(tab.id)), isNull);

      await second.read(layoutPersistenceProvider).ensureLoaded(tab.id);
      expect(tab.controller.text, 'SELECT * FROM users');
      expect(second.read(tabFileProvider(tab.id))?.file.path, 'q/users.sql');
    });

    test(
      'opening a file reuses its restored tab instead of adding one',
      () async {
        final workspace = FakeWorkspaceRepository(
          files: {'q/users.sql': 'SELECT 1'},
        );
        final first = await start(workspace);
        await restored(first);
        first.read(selectedConnectionProvider.notifier).select('c2');
        await first
            .read(fileOpenerProvider)
            .open(const FilePath('ws', 'q/users.sql'));
        await first.read(layoutPersistenceProvider).flush();

        final second = await start(workspace);
        await restored(second);
        final restoredTab = second.read(editorTabsProvider).tabs.single;
        final out =
            await second
                    .read(fileOpenerProvider)
                    .open(const FilePath('ws', 'q/users.sql'))
                as Opened;
        expect(out.tabId, restoredTab.id);
        expect(second.read(editorTabsProvider).tabs, hasLength(1));
        expect(restoredTab.controller.text, 'SELECT 1');
      },
    );

    test('unsaved edits of a bound file survive and stay unsaved', () async {
      final workspace = FakeWorkspaceRepository(
        files: {'q/users.sql': 'SELECT 1'},
      );
      final first = await start(workspace);
      await restored(first);
      first.read(selectedConnectionProvider.notifier).select('c2');
      final out =
          await first
                  .read(fileOpenerProvider)
                  .open(const FilePath('ws', 'q/users.sql'))
              as Opened;
      first
              .read(editorTabsProvider)
              .tabs
              .firstWhere((t) => t.id == out.tabId)
              .controller
              .text =
          'SELECT 2';
      await first.read(layoutPersistenceProvider).flush();

      final second = await start(workspace);
      await restored(second);
      final tab = second.read(editorTabsProvider).tabs.single;
      await second.read(layoutPersistenceProvider).ensureLoaded(tab.id);
      expect(tab.controller.text, 'SELECT 2');
      expect(isTabDirty(tab, second.read(tabFileProvider(tab.id))), isTrue);
    });

    test('nothing is written before the layout was read', () async {
      final workspace = FakeWorkspaceRepository();
      final c = await start(workspace);
      await c.read(layoutPersistenceProvider).flush();
      expect(workspace.contents, isNot(contains(layoutPath)));
    });

    test('a broken or foreign file starts fresh and is not fatal', () async {
      for (final bad in ['{nope', '[]', '{"version": 99}']) {
        final c = await start(
          FakeWorkspaceRepository(files: {layoutPath: bad}),
        );
        await restored(c);
        expect(c.read(editorTabsProvider).tabs, isEmpty, reason: bad);
      }
    });

    test('connections that no longer exist are skipped', () async {
      final workspace = FakeWorkspaceRepository(
        files: {
          layoutPath:
              '{"version":1,"selected":"gone","connections":{"gone":{"tabs":'
              '[{"kind":"query","title":"x"}],"layout":null}}}',
        },
      );
      final c = await start(workspace);
      await restored(c);
      expect(c.read(editorTabsProvider).tabs, isEmpty);
    });

    test(
      'restoring many tabs is quick and reads nothing but the layout',
      () async {
        final workspace = FakeWorkspaceRepository();
        final first = await start(workspace);
        await restored(first);
        final tabs = first.read(editorTabsProvider.notifier);
        for (var i = 0; i < 60; i++) {
          tabs.open('c2').controller.text = 'SELECT $i';
        }
        first.read(editorLayoutProvider.notifier).split('c2', Axis.horizontal);
        await first.read(layoutPersistenceProvider).flush();

        final second = await start(workspace);
        final watch = Stopwatch()..start();
        await restored(second);
        watch.stop();
        // ignore: avoid_print
        print('RESTORE_MS ${watch.elapsedMilliseconds}');
        expect(second.read(editorTabsProvider).tabs, hasLength(60));
        expect(watch.elapsedMilliseconds, lessThan(500));
      },
    );
  });
}
