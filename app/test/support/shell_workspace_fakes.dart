import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/shell/data/shell_repository.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';
import 'package:queravue/features/workspace/data/workspace_repository.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import 'fake_connections_repository.dart';
import 'fake_query_repository.dart';
import 'providers.dart';

/// A MongoDB engine that declares the shell capability.
const shellEngine = EngineSpec(
  id: 'mongodb',
  displayName: 'MongoDB',
  family: 'mongodb',
  supportsUri: true,
  capabilities: {'connect', 'schema_inspector', 'document_store', 'shell'},
  fields: [FieldSpec(key: 'hosts', label: 'Hosts', required: true)],
);

/// A SQL engine that can execute.
const sqlEngine = EngineSpec(
  id: 'postgres',
  displayName: 'PostgreSQL',
  family: 'postgres',
  supportsUri: true,
  capabilities: {'connect', 'execute'},
  fields: [],
);

/// A schema repository with one database and no objects.
class EmptySchemaRepository implements SchemaRepository {
  @override
  Future<List<String>> listDatabases(
    String sessionId, {
    bool refresh = false,
  }) async => const ['shop'];

  @override
  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  }) async => const [];

  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  }) async => const [];

  @override
  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  }) => throw StateError('not needed');

  @override
  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]) async {}
}

/// Scripted [ShellRepository].
class FakeShellRepository implements ShellRepository {
  /// Events of the next `eval` calls, one list per call, emitted in order.
  final scripts = <List<ShellEvent>>[];

  /// If set, the next `eval` stays open until it completes.
  Completer<void>? holdOpen;

  final evals = <({String shellId, String code, bool confirmed})>[];
  final opened = <({String sessionId, String database})>[];
  final closed = <String>[];
  final cancelled = <String>[];
  final fetches = <({String cursorId, int skip, int limit})>[];

  /// Documents behind every cursor handle.
  List<String> cursorDocs = const [];

  /// If set, `openShell` throws it.
  Object? openError;

  /// If set, the next `eval` stream fails with it.
  Object? evalError;

  /// If set, `fetchCursor` fails with it.
  Object? fetchError;

  @override
  Future<String> openShell(String sessionId, String database) async {
    final e = openError;
    if (e != null) throw e;
    opened.add((sessionId: sessionId, database: database));
    return 'shell-${opened.length}';
  }

  @override
  Stream<ShellEvent> eval(
    String shellId,
    String code, {
    bool confirmed = false,
  }) {
    evals.add((shellId: shellId, code: code, confirmed: confirmed));
    final script = scripts.isEmpty
        ? const <ShellEvent>[ShellDone(Duration.zero)]
        : scripts.removeAt(0);
    late StreamController<ShellEvent> c;
    c = StreamController<ShellEvent>(
      onListen: () async {
        final err = evalError;
        if (err != null) {
          evalError = null;
          c.addError(err);
          await c.close();
          return;
        }
        for (final e in script) {
          await Future<void>.delayed(Duration.zero);
          if (c.isClosed) return;
          c.add(e);
        }
        final h = holdOpen;
        if (h != null) {
          holdOpen = null;
          await h.future;
        }
        if (!c.isClosed) await c.close();
      },
    );
    return c.stream;
  }

  @override
  Stream<DocBatch> fetchCursor(
    String shellId,
    String cursorId, {
    int skip = 0,
    int limit = 0,
  }) {
    fetches.add((cursorId: cursorId, skip: skip, limit: limit));
    final err = fetchError;
    if (err != null) return Stream.error(err);
    final docs = cursorDocs.skip(skip).take(limit == 0 ? 50 : limit).toList();
    return Stream.value(DocBatch(offset: skip, documents: docs, done: true));
  }

  @override
  Future<void> cancel(String shellId) async => cancelled.add(shellId);

  @override
  Future<void> closeShell(String shellId) async => closed.add(shellId);
}

String fakeHash(String content) => 'h${content.hashCode}';

/// In-memory [WorkspaceRepository] over one root, `ws`.
class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository({Map<String, String> files = const {}}) {
    files.forEach(put);
  }

  final contents = <String, String>{};
  final metas = <String, FileMeta>{};
  final dirs = <String>{};
  final changes = StreamController<WorkspaceChange>.broadcast();
  final writes = <({String path, String content, String hash, bool force})>[];
  final deleted = <String>[];
  int _clock = 0;
  final _mtimes = <String, DateTime>{};

  void put(String path, String content, {FileMeta? meta}) {
    contents[path] = content;
    if (meta != null) metas[path] = meta;
    _mtimes[path] = DateTime.utc(2026, 1, 1).add(Duration(seconds: ++_clock));
    var i = path.lastIndexOf('/');
    while (i > 0) {
      dirs.add(path.substring(0, i));
      i = path.lastIndexOf('/', i - 1);
    }
  }

  /// Edits a file as another program would.
  void editExternally(String path, String content) {
    put(path, content);
    changes.add(
      WorkspaceChange(file: FilePath('ws', path), kind: ChangeKind.modified),
    );
  }

  void removeExternally(String path) {
    contents.remove(path);
    changes.add(
      WorkspaceChange(file: FilePath('ws', path), kind: ChangeKind.deleted),
    );
  }

  @override
  Future<List<WorkspaceRoot>> roots() async => const [
    WorkspaceRoot(id: 'ws', name: 'Workspace', path: '/tmp/ws'),
  ];

  @override
  Future<List<TreeEntry>> listTree(FilePath dir) async {
    final prefix = dir.path.isEmpty ? '' : '${dir.path}/';
    final out = <TreeEntry>[];
    final seenDirs = <String>{};
    for (final p in [...contents.keys, ...dirs.map((d) => '$d/')]) {
      if (!p.startsWith(prefix) || p == prefix) continue;
      final rest = p.substring(prefix.length);
      final slash = rest.indexOf('/');
      if (slash >= 0) {
        if (seenDirs.add(rest.substring(0, slash))) {
          out.add(TreeEntry(name: rest.substring(0, slash), isDir: true));
        }
      } else {
        out.add(
          TreeEntry(
            name: rest,
            isDir: false,
            kind: fileKindOf(rest),
            meta: _metaOf(p),
          ),
        );
      }
    }
    out.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  /// Header metadata as the core parses it: leading `--` or `//` lines.
  FileMeta _metaOf(String path) {
    final given = metas[path];
    if (given != null) return given;
    final values = <String, String>{};
    for (final line in contents[path]!.split('\n')) {
      final m = RegExp(r'^(?:--|//)\s*(\w+):\s*(.*)$').firstMatch(line);
      if (m == null) break;
      values[m.group(1)!.toLowerCase()] = m.group(2)!.trim();
    }
    return FileMeta(
      title: values['title'] ?? '',
      connection: values['connection'] ?? '',
      tags: [
        for (final t in (values['tags'] ?? '').split(','))
          if (t.trim().isNotEmpty) t.trim(),
      ],
    );
  }

  WorkspaceFile _file(String path) => WorkspaceFile(
    content: contents[path]!,
    mtime: _mtimes[path]!,
    hash: fakeHash(contents[path]!),
    meta: _metaOf(path),
    kind: fileKindOf(path),
  );

  @override
  Future<WorkspaceFile> read(FilePath file) async {
    if (!contents.containsKey(file.path)) {
      throw const WorkspaceFailure(WorkspaceErrorKind.notFound, 'not found');
    }
    return _file(file.path);
  }

  @override
  Future<FileStamp> write(
    FilePath file,
    String content, {
    String expectedHash = '',
    DateTime? expectedMtime,
    bool force = false,
  }) async {
    writes.add((
      path: file.path,
      content: content,
      hash: expectedHash,
      force: force,
    ));
    final cur = contents[file.path];
    if (!force && expectedHash.isNotEmpty) {
      if (cur == null || fakeHash(cur) != expectedHash) {
        throw WorkspaceFailure(
          WorkspaceErrorKind.conflict,
          '${file.path} changed on disk',
          current: cur == null ? null : _file(file.path),
        );
      }
    }
    put(file.path, content);
    return FileStamp(mtime: _mtimes[file.path]!, hash: fakeHash(content));
  }

  @override
  Future<FileStamp?> create(
    FilePath file, {
    bool isDir = false,
    String content = '',
  }) async {
    if (contents.containsKey(file.path) || dirs.contains(file.path)) {
      throw const WorkspaceFailure(
        WorkspaceErrorKind.alreadyExists,
        'already exists',
      );
    }
    if (isDir) {
      dirs.add(file.path);
      return null;
    }
    put(file.path, content);
    return FileStamp(mtime: _mtimes[file.path]!, hash: fakeHash(content));
  }

  @override
  Future<void> rename(String rootId, String from, String to) async {
    if (contents.containsKey(to)) {
      throw const WorkspaceFailure(
        WorkspaceErrorKind.alreadyExists,
        'already exists',
      );
    }
    final c = contents.remove(from);
    if (c == null) {
      throw const WorkspaceFailure(WorkspaceErrorKind.notFound, 'not found');
    }
    put(to, c, meta: metas.remove(from));
  }

  @override
  Future<void> delete(FilePath file) async {
    deleted.add(file.path);
    contents.removeWhere(
      (p, _) => p == file.path || p.startsWith('${file.path}/'),
    );
    dirs.remove(file.path);
  }

  @override
  Stream<SearchHit> search(
    String text, {
    List<String> tags = const [],
    String rootId = '',
  }) async* {
    final needle = text.toLowerCase();
    for (final p in contents.keys.toList()..sort()) {
      if (fileKindOf(p) == FileKind.other) continue;
      final meta = _metaOf(p);
      if (!tags.every(meta.tags.contains)) continue;
      final body = contents[p]!;
      final lines = body.split('\n');
      final at = lines.indexWhere((l) => l.toLowerCase().contains(needle));
      final nameHit = p.toLowerCase().contains(needle) || needle.isEmpty;
      if (!nameHit && at < 0) continue;
      yield SearchHit(
        file: FilePath('ws', p),
        kind: fileKindOf(p),
        meta: meta,
        snippet: !nameHit && at >= 0 ? lines[at] : '',
        line: !nameHit && at >= 0 ? at + 1 : 0,
      );
    }
  }

  @override
  Stream<WorkspaceChange> watch() => changes.stream;
}

/// Connections `mongo` (id `c1`, flagged production if asked) and `pg`
/// (id `c2`).
FakeConnectionsRepository fakeConnections({bool production = false}) =>
    FakeConnectionsRepository(
      initial: [
        ConnectionProfile(
          id: 'c1',
          name: 'Mongo',
          engineId: 'mongodb',
          production: production,
        ),
        const ConnectionProfile(id: 'c2', name: 'Pg', engineId: 'postgres'),
      ],
    )..engines = [shellEngine, sqlEngine];

/// Everything a shell or workspace test needs.
typedef ShellEnv = ({
  ProviderContainer container,
  FakeShellRepository shell,
  FakeWorkspaceRepository workspace,
  FakeQueryRepository query,
});

List<Override> shellOverrides({
  required FakeShellRepository shell,
  required FakeWorkspaceRepository workspace,
  required FakeQueryRepository query,
  bool production = false,
  bool fakeLayoutPersistence = true,
}) => [
  ...fakeCoreOverrides(
    fakeConnections(production: production),
    fakeLayoutPersistence: fakeLayoutPersistence,
  ),
  shellRepositoryProvider.overrideWithValue(shell),
  workspaceRepositoryProvider.overrideWithValue(workspace),
  queryRepositoryProvider.overrideWithValue(query),
  schemaRepositoryProvider.overrideWithValue(EmptySchemaRepository()),
];

/// A container with fakes; connections and engines are already loaded.
Future<ShellEnv> makeShellEnv({
  Map<String, String> files = const {},
  bool production = false,
  Set<String>? capabilities,
}) async {
  final shell = FakeShellRepository();
  final workspace = FakeWorkspaceRepository(files: files);
  final query = FakeQueryRepository()
    ..capabilities = capabilities ?? {'connect', 'document_store', 'shell'};
  final container = ProviderContainer(
    overrides: shellOverrides(
      shell: shell,
      workspace: workspace,
      query: query,
      production: production,
    ),
  );
  addTearDown(container.dispose);
  await container.read(connectionsControllerProvider.future);
  await container.read(enginesProvider.future);
  return (
    container: container,
    shell: shell,
    workspace: workspace,
    query: query,
  );
}

Future<void> settle(bool Function() test, {int tries = 400}) async {
  for (var i = 0; i < tries; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not reached');
}
