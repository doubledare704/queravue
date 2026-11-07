import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/workspace/application/workspace_controller.dart';
import 'package:queravue/features/workspace/domain/file_header.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import '../../support/shell_workspace_fakes.dart';

const _root = FilePath('ws', '');

Future<ShellEnv> env([Map<String, String>? files]) async {
  final e = await makeShellEnv(
    files:
        files ??
        {
          'b.sql': 'SELECT 1',
          'a.mongo.js': 'db.t.find()',
          'notes.txt': 'x',
          'reports/users.sql': '-- title: Users\nSELECT * FROM users',
        },
  );
  e.container.read(coreReadyProvider);
  e.container.read(workspaceProvider);
  await settle(() => e.container.read(workspaceProvider).loaded);
  await settle(
    () => e.container.read(workspaceProvider).dirs.containsKey(_root),
  );
  return e;
}

List<String> names(ShellEnv e) => [
  for (final r in flattenWorkspace(e.container.read(workspaceProvider)))
    '${'  ' * r.depth}${r.name}',
];

void main() {
  test('loads the root with folders first, then files by name', () async {
    final e = await env();
    expect(names(e), [
      'Workspace',
      '  reports',
      '  a.mongo.js',
      '  b.sql',
      '  notes.txt',
    ]);
  });

  test(
    'expanding a folder loads and shows its files; collapsing hides them',
    () async {
      final e = await env();
      final c = e.container.read(workspaceProvider.notifier);
      await c.toggle(const FilePath('ws', 'reports'));
      expect(names(e), contains('    users.sql'));
      await c.toggle(const FilePath('ws', 'reports'));
      expect(names(e), isNot(contains('    users.sql')));
    },
  );

  test(
    'createFile adds the extension of its kind and reveals the folder',
    () async {
      final e = await env();
      final c = e.container.read(workspaceProvider.notifier);
      final f = await c.createFile(
        const FilePath('ws', 'reports'),
        'daily',
        FileKind.sql,
      );
      expect(f.path, 'reports/daily.sql');
      expect(e.workspace.contents.containsKey('reports/daily.sql'), isTrue);
      expect(names(e), contains('    daily.sql'));

      final m = await c.createFile(_root, 'job.mongo.js', FileKind.mongo);
      expect(m.path, 'job.mongo.js', reason: 'a known extension is kept');
      final other = await c.createFile(_root, 'x.sql', FileKind.mongo);
      expect(other.path, 'x.sql');
    },
  );

  test('creating a file that exists fails and changes nothing', () async {
    final e = await env();
    final c = e.container.read(workspaceProvider.notifier);
    await expectLater(
      c.createFile(_root, 'b.sql', FileKind.sql),
      throwsA(
        isA<WorkspaceFailure>().having(
          (f) => f.kind,
          'kind',
          WorkspaceErrorKind.alreadyExists,
        ),
      ),
    );
    expect(e.workspace.contents['b.sql'], 'SELECT 1');
  });

  test('createFolder, rename, move and delete refresh the tree', () async {
    final e = await env();
    final c = e.container.read(workspaceProvider.notifier);
    await c.createFolder(_root, 'archive');
    expect(names(e), contains('  archive'));

    await c.rename(const FilePath('ws', 'b.sql'), 'archive/b-old.sql');
    expect(e.workspace.contents.containsKey('archive/b-old.sql'), isTrue);
    expect(names(e), isNot(contains('  b.sql')));

    await c.rename(const FilePath('ws', 'a.mongo.js'), 'renamed.mongo.js');
    expect(names(e), contains('  renamed.mongo.js'));

    await c.delete(const FilePath('ws', 'notes.txt'));
    expect(e.workspace.deleted, ['notes.txt']);
    expect(names(e), isNot(contains('  notes.txt')));
  });

  test('a change made on disk refreshes the folder', () async {
    final e = await env();
    // Like the sidebar panel: an active listener keeps the provider running.
    e.container.listen(workspaceProvider, (_, _) {});
    await settle(() => e.workspace.changes.hasListener);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    e.workspace.put('fresh.sql', 'SELECT 2');
    e.workspace.changes.add(
      const WorkspaceChange(
        file: FilePath('ws', 'fresh.sql'),
        kind: ChangeKind.created,
      ),
    );
    await settle(() => names(e).contains('  fresh.sql'));
  });

  group('search', () {
    test('streams hits and clears again', () async {
      final e = await env();
      final c = e.container.read(workspaceProvider.notifier);
      await c.search('users');
      var s = e.container.read(workspaceProvider);
      expect(s.isSearch, isTrue);
      expect(s.searching, isFalse);
      expect(s.hits.map((h) => h.file.path), ['reports/users.sql']);
      expect(s.hits.single.meta.title, 'Users');

      await c.search('');
      s = e.container.read(workspaceProvider);
      expect(s.isSearch, isFalse);
      expect(s.hits, isEmpty);
    });

    test('#tags become filters', () async {
      final e = await env();
      e.workspace.metas['b.sql'] = const FileMeta(tags: ['reports']);
      final c = e.container.read(workspaceProvider.notifier);
      await c.search('#reports');
      expect(e.container.read(workspaceProvider).hits.map((h) => h.file.path), [
        'b.sql',
      ]);
    });

    test('a content match carries a snippet and line', () async {
      final e = await env();
      final c = e.container.read(workspaceProvider.notifier);
      await c.search('FROM users');
      final h = e.container.read(workspaceProvider).hits.single;
      expect(h.line, 2);
      expect(h.snippet, contains('FROM users'));
    });

    test('no match gives no hits', () async {
      final e = await env();
      await e.container.read(workspaceProvider.notifier).search('zzzz');
      final s = e.container.read(workspaceProvider);
      expect(s.hits, isEmpty);
      expect(s.searching, isFalse);
    });
  });

  group('pure helpers', () {
    test('parseSearch splits text and tags', () {
      final q = parseSearch('  daily  #reports report #x  ');
      expect(q.text, 'daily report');
      expect(q.tags, ['reports', 'x']);
      expect(parseSearch('#').text, '#');
      expect(parseSearch('#').tags, isEmpty);
    });

    test('withExtension', () {
      expect(withExtension('q', FileKind.sql), 'q.sql');
      expect(withExtension('q', FileKind.mongo), 'q.mongo.js');
      expect(withExtension('q.sql', FileKind.mongo), 'q.sql');
      expect(withExtension('q.mongo.js', FileKind.sql), 'q.mongo.js');
    });

    test('FilePath', () {
      const f = FilePath('ws', 'a/b/c.sql');
      expect(f.name, 'c.sql');
      expect(f.parent, 'a/b');
      expect(const FilePath('ws', 'c.sql').parent, '');
      expect(const FilePath('ws', '').child('x'), const FilePath('ws', 'x'));
      expect(f.child('d'), const FilePath('ws', 'a/b/c.sql/d'));
    });

    test('withHeader writes comments in the right style', () {
      expect(
        withHeader(FileKind.sql, 'SELECT 1', title: 'T', connection: 'Pg'),
        '-- title: T\n-- connection: Pg\n\nSELECT 1',
      );
      expect(
        withHeader(FileKind.mongo, 'db.t.find()', connection: 'Mongo'),
        '// connection: Mongo\n\ndb.t.find()',
      );
      expect(withHeader(FileKind.sql, 'SELECT 1'), 'SELECT 1');
      expect(withHeader(FileKind.sql, '  ', title: 'T'), '-- title: T\n');
      expect(
        withHeader(FileKind.sql, 'x', title: 'a\nb'),
        startsWith('-- title: a b\n'),
      );
    });
  });
}
