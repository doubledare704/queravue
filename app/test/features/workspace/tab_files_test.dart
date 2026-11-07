import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/workspace/application/tab_files.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import '../../support/shell_workspace_fakes.dart';

const _sql = FilePath('ws', 'q/users.sql');
const _mongo = FilePath('ws', 'jobs/clean.mongo.js');

Future<ShellEnv> env() => makeShellEnv(
  files: {
    'q/users.sql': '-- title: Users\nSELECT 1',
    'jobs/clean.mongo.js': '// connection: Mongo\ndb.t.deleteMany({a: 1})',
    'notes.txt': 'plain',
  },
);

Future<OpenOutcome> open(ShellEnv e, FilePath f) =>
    e.container.read(fileOpenerProvider).open(f);

EditorTab tabOf(ShellEnv e, String id) =>
    e.container.read(editorTabsProvider).tabs.firstWhere((t) => t.id == id);

TabFileState? fileOf(ShellEnv e, String id) =>
    e.container.read(tabFileProvider(id));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('opening', () {
    test('a Mongo script opens in a shell tab on the connection named in its header', () async {
      final e = await env();
      final out = await open(e, _mongo) as Opened;
      final tab = tabOf(e, out.tabId);
      expect(tab.isShell, isTrue);
      expect(tab.connectionId, 'c1');
      expect(tab.title, 'clean.mongo.js');
      expect(tab.controller.text, contains('deleteMany'));
      expect(fileOf(e, tab.id)!.file, _mongo);
      expect(e.container.read(selectedConnectionProvider), 'c1');
    });

    test(
      'a SQL file opens in a query tab on the selected SQL connection',
      () async {
        final e = await env();
        e.container.read(selectedConnectionProvider.notifier).select('c2');
        final out = await open(e, _sql) as Opened;
        final tab = tabOf(e, out.tabId);
        expect(tab.isQuery, isTrue);
        expect(tab.connectionId, 'c2');
        expect(tab.controller.text, contains('SELECT 1'));
      },
    );

    test('a header connection that is given by id works too', () async {
      final e = await makeShellEnv(
        files: {'a.sql': '-- connection: c2\nSELECT 1'},
      );
      final out = await open(e, const FilePath('ws', 'a.sql')) as Opened;
      expect(tabOf(e, out.tabId).connectionId, 'c2');
    });

    test('without a suitable connection it says what to do', () async {
      final e = await env();
      final sql = await open(e, _sql);
      expect((sql as OpenFailed).message, contains('SQL connection'));

      e.container.read(selectedConnectionProvider.notifier).select('c2');
      final mongo = await open(e, const FilePath('ws', 'jobs/clean.mongo.js'));
      expect(mongo, isA<Opened>(), reason: 'the header names Mongo');

      final e2 = await makeShellEnv(files: {'x.mongo.js': 'db.t.find()'});
      e2.container.read(selectedConnectionProvider.notifier).select('c2');
      expect(
        (await open(
          e2,
          const FilePath('ws', 'x.mongo.js'),
        ) as OpenFailed).message,
        contains('MongoDB connection'),
      );
    });

    test('a file whose header connection is wrong for it falls back to the selected one', () async {
      final e = await makeShellEnv(
        files: {'a.sql': '-- connection: Mongo\nSELECT 1'},
      );
      e.container.read(selectedConnectionProvider.notifier).select('c2');
      final out = await open(e, const FilePath('ws', 'a.sql')) as Opened;
      expect(tabOf(e, out.tabId).connectionId, 'c2');
    });

    test('other files and missing files do not open', () async {
      final e = await env();
      e.container.read(selectedConnectionProvider.notifier).select('c2');
      expect(
        await open(e, const FilePath('ws', 'notes.txt')),
        isA<OpenFailed>(),
      );
      expect(
        await open(e, const FilePath('ws', 'gone.sql')),
        isA<OpenFailed>(),
      );
    });

    test('opening a file that is already open focuses its tab', () async {
      final e = await env();
      final a = await open(e, _mongo) as Opened;
      final b = await open(e, _mongo) as Opened;
      expect(b.tabId, a.tabId);
      expect(e.container.read(editorTabsProvider).tabs.length, 1);
    });
  });

  group('saving', () {
    test('writes the buffer with the hash it was read with', () async {
      final e = await env();
      final out = await open(e, _mongo) as Opened;
      final tab = tabOf(e, out.tabId);
      final before = fileOf(e, tab.id)!;
      tab.controller.text = 'db.t.find()';
      expect(isTabDirty(tab, fileOf(e, tab.id)), isTrue);

      final r = await e.container.read(tabFileProvider(tab.id).notifier).save();
      expect(r, isA<Saved>());
      expect(e.workspace.contents['jobs/clean.mongo.js'], 'db.t.find()');
      expect(e.workspace.writes.single.hash, before.savedHash);
      expect(e.workspace.writes.single.force, isFalse);
      expect(isTabDirty(tab, fileOf(e, tab.id)), isFalse);
      expect(fileOf(e, tab.id)!.savedHash, isNot(before.savedHash));
    });

    test(
      'a file changed on disk is not overwritten without a decision',
      () async {
        final e = await env();
        final out = await open(e, _mongo) as Opened;
        final tab = tabOf(e, out.tabId);
        final c = e.container.read(tabFileProvider(tab.id).notifier);
        tab.controller.text = 'mine';
        e.workspace.put('jobs/clean.mongo.js', 'theirs');

        final r = await c.save();
        expect(r, isA<SaveConflict>());
        expect((r as SaveConflict).current!.content, 'theirs');
        expect(e.workspace.contents['jobs/clean.mongo.js'], 'theirs');

        expect(await c.save(force: true), isA<Saved>());
        expect(e.workspace.contents['jobs/clean.mongo.js'], 'mine');
      },
    );

    test('a deleted file conflicts, and a forced save recreates it', () async {
      final e = await env();
      final out = await open(e, _mongo) as Opened;
      final tab = tabOf(e, out.tabId);
      final c = e.container.read(tabFileProvider(tab.id).notifier);
      e.workspace.contents.remove('jobs/clean.mongo.js');
      final r = await c.save();
      expect(r, isA<SaveConflict>());
      expect((r as SaveConflict).current, isNull);
      expect(await c.save(force: true), isA<Saved>());
      expect(e.workspace.contents.containsKey('jobs/clean.mongo.js'), isTrue);
    });

    test('an unbound tab asks for save as', () async {
      final e = await env();
      final tab = e.container.read(editorTabsProvider.notifier).open('c2');
      expect(
        await e.container.read(tabFileProvider(tab.id).notifier).save(),
        isA<NotBound>(),
      );
    });
  });

  group('save as', () {
    test('creates the file, binds the tab and renames it', () async {
      final e = await env();
      final tab = e.container.read(editorTabsProvider.notifier).openShell('c1');
      tab.controller.text = 'db.users.find()';
      final c = e.container.read(tabFileProvider(tab.id).notifier);
      const target = FilePath('ws', 'new/list.mongo.js');
      final r = await c.saveAs(
        target,
        '// connection: Mongo\n\ndb.users.find()',
      );
      expect(r, isA<Saved>());
      expect(e.workspace.contents[target.path], contains('db.users.find()'));
      expect(fileOf(e, tab.id)!.file, target);
      expect(tabOf(e, tab.id).title, 'list.mongo.js');
      expect(
        tabOf(e, tab.id).controller.text,
        startsWith('// connection: Mongo'),
      );
      expect(isTabDirty(tabOf(e, tab.id), fileOf(e, tab.id)), isFalse);
    });

    test('an existing target is reported, and overwrite replaces it', () async {
      final e = await env();
      final tab = e.container.read(editorTabsProvider.notifier).open('c2');
      final c = e.container.read(tabFileProvider(tab.id).notifier);
      final r = await c.saveAs(_sql, 'SELECT 9');
      expect((r as SaveFailed).exists, isTrue);
      expect(e.workspace.contents[_sql.path], isNot('SELECT 9'));
      expect(await c.saveAs(_sql, 'SELECT 9', overwrite: true), isA<Saved>());
      expect(e.workspace.contents[_sql.path], 'SELECT 9');
    });
  });

  group('external changes', () {
    Future<(ShellEnv, EditorTab)> opened() async {
      final e = await env();
      final out = await open(e, _mongo) as Opened;
      final tab = tabOf(e, out.tabId);
      // Keep the watch subscription alive like the UI does.
      e.container.listen(tabFileProvider(tab.id), (_, _) {});
      return (e, tab);
    }

    test(
      'a changed file raises a banner; reload takes the disk version',
      () async {
        final (e, tab) = await opened();
        e.workspace.editExternally('jobs/clean.mongo.js', 'from git pull');
        await settle(() => fileOf(e, tab.id)!.external != null);
        expect(fileOf(e, tab.id)!.external!.kind, ExternalKind.modified);

        expect(
          await e.container.read(tabFileProvider(tab.id).notifier).reload(),
          isTrue,
        );
        expect(tab.controller.text, 'from git pull');
        expect(fileOf(e, tab.id)!.external, isNull);
        expect(isTabDirty(tab, fileOf(e, tab.id)), isFalse);
      },
    );

    test(
      'keep mine clears the banner and lets the next save through',
      () async {
        final (e, tab) = await opened();
        tab.controller.text = 'mine';
        e.workspace.editExternally('jobs/clean.mongo.js', 'theirs');
        await settle(() => fileOf(e, tab.id)!.external != null);
        final c = e.container.read(tabFileProvider(tab.id).notifier);
        c.keepMine();
        expect(fileOf(e, tab.id)!.external, isNull);
        expect(await c.save(), isA<Saved>());
        expect(e.workspace.contents['jobs/clean.mongo.js'], 'mine');
        expect(
          e.workspace.writes.single.force,
          isFalse,
          reason: 'no force needed after keep mine',
        );
      },
    );

    test('our own write is not reported as an external change', () async {
      final (e, tab) = await opened();
      tab.controller.text = 'mine';
      await e.container.read(tabFileProvider(tab.id).notifier).save();
      e.workspace.changes.add(
        const WorkspaceChange(file: _mongo, kind: ChangeKind.modified),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fileOf(e, tab.id)!.external, isNull);
    });

    test('a deleted file raises a banner without a reload option', () async {
      final (e, tab) = await opened();
      e.workspace.removeExternally('jobs/clean.mongo.js');
      await settle(() => fileOf(e, tab.id)!.external != null);
      expect(fileOf(e, tab.id)!.external!.kind, ExternalKind.deleted);
      expect(
        await e.container.read(tabFileProvider(tab.id).notifier).reload(),
        isFalse,
      );
      e.container.read(tabFileProvider(tab.id).notifier).keepMine();
      expect(
        fileOf(e, tab.id)!.savedHash,
        isEmpty,
        reason: 'a save recreates the file',
      );
    });

    test('changes to other files are ignored', () async {
      final (e, tab) = await opened();
      e.workspace.editExternally('q/users.sql', 'other');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fileOf(e, tab.id)!.external, isNull);
    });

    test('a rename of the file or its folder rebinds the tab', () async {
      final (e, tab) = await opened();
      e.workspace.changes.add(
        const WorkspaceChange(
          file: FilePath('ws', 'jobs/new-name.mongo.js'),
          kind: ChangeKind.renamed,
          oldPath: 'jobs/clean.mongo.js',
        ),
      );
      await settle(
        () => fileOf(e, tab.id)!.file.path == 'jobs/new-name.mongo.js',
      );
      expect(tabOf(e, tab.id).title, 'new-name.mongo.js');

      e.workspace.changes.add(
        const WorkspaceChange(
          file: FilePath('ws', 'archive'),
          kind: ChangeKind.renamed,
          oldPath: 'jobs',
        ),
      );
      await settle(
        () => fileOf(e, tab.id)!.file.path == 'archive/new-name.mongo.js',
      );
    });
  });

  test('closing a tab drops its binding', () async {
    final e = await env();
    final out = await open(e, _mongo) as Opened;
    e.container.listen(tabFileProvider(out.tabId), (_, _) {});
    e.container.read(editorTabsProvider.notifier).close(out.tabId);
    await settle(() => fileOf(e, out.tabId) == null);
  });
}
