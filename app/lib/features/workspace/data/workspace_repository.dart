import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as ts;

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/workspace.pbgrpc.dart' as pb;
import '../domain/workspace_models.dart';

/// Access to the core's WorkspaceService. Failures the core reports in-band
/// throw a [WorkspaceFailure]; transport errors propagate as they are.
abstract interface class WorkspaceRepository {
  Future<List<WorkspaceRoot>> roots();

  /// Lists one directory of a root.
  Future<List<TreeEntry>> listTree(FilePath dir);

  Future<WorkspaceFile> read(FilePath file);

  /// Replaces a file. With [expectedHash] or [expectedMtime] the core refuses
  /// the write, with a conflict failure, if the file changed. [force] skips
  /// the check.
  Future<FileStamp> write(
    FilePath file,
    String content, {
    String expectedHash,
    DateTime? expectedMtime,
    bool force,
  });

  /// Creates a file with [content], or a folder.
  Future<FileStamp?> create(FilePath file, {bool isDir, String content});

  Future<void> rename(String rootId, String from, String to);

  Future<void> delete(FilePath file);

  /// Streams matching script files; cancelling the subscription stops the
  /// search.
  Stream<SearchHit> search(String text, {List<String> tags, String rootId});

  /// Streams changes made on disk until cancelled.
  Stream<WorkspaceChange> watch();
}

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcWorkspaceRepository(() => supervisor.connection);
});

class GrpcWorkspaceRepository implements WorkspaceRepository {
  GrpcWorkspaceRepository(this._connection);

  final CoreConnection? Function() _connection;

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  pb.WorkspaceServiceClient get _svc => _conn.workspaceService;

  @override
  Future<List<WorkspaceRoot>> roots() async {
    final r = await _svc.getRoots(pb.GetRootsRequest());
    return [
      for (final x in r.roots)
        WorkspaceRoot(id: x.id, name: x.name, path: x.path),
    ];
  }

  @override
  Future<List<TreeEntry>> listTree(FilePath dir) async {
    final r = await _svc.listTree(
      pb.ListTreeRequest(rootId: dir.root, path: dir.path),
    );
    _check(r.hasError() ? r.error : null);
    return [
      for (final e in r.entries)
        TreeEntry(
          name: e.name,
          isDir: e.isDir,
          kind: _kind(e.kind),
          size: e.size.toInt(),
          mtime: e.hasMtime() ? e.mtime.toDateTime() : null,
          meta: _meta(e.hasMeta() ? e.meta : null),
        ),
    ];
  }

  @override
  Future<WorkspaceFile> read(FilePath file) async {
    final r = await _svc.read(
      pb.ReadRequest(rootId: file.root, path: file.path),
    );
    _check(r.hasError() ? r.error : null);
    return _file(r.file);
  }

  @override
  Future<FileStamp> write(
    FilePath file,
    String content, {
    String expectedHash = '',
    DateTime? expectedMtime,
    bool force = false,
  }) async {
    final r = await _svc.write(
      pb.WriteRequest(
        rootId: file.root,
        path: file.path,
        content: content,
        expectedHash: expectedHash,
        expectedMtime: expectedMtime == null
            ? null
            : ts.Timestamp.fromDateTime(expectedMtime),
        force: force,
      ),
    );
    _check(r.hasError() ? r.error : null);
    return FileStamp(mtime: r.mtime.toDateTime(), hash: r.hash);
  }

  @override
  Future<FileStamp?> create(
    FilePath file, {
    bool isDir = false,
    String content = '',
  }) async {
    final r = await _svc.create(
      pb.CreateRequest(
        rootId: file.root,
        path: file.path,
        isDir: isDir,
        content: content,
      ),
    );
    _check(r.hasError() ? r.error : null);
    return isDir ? null : FileStamp(mtime: r.mtime.toDateTime(), hash: r.hash);
  }

  @override
  Future<void> rename(String rootId, String from, String to) async {
    final r = await _svc.rename(
      pb.RenameRequest(rootId: rootId, fromPath: from, toPath: to),
    );
    _check(r.hasError() ? r.error : null);
  }

  @override
  Future<void> delete(FilePath file) async {
    final r = await _svc.delete(
      pb.DeleteRequest(rootId: file.root, path: file.path),
    );
    _check(r.hasError() ? r.error : null);
  }

  @override
  Stream<SearchHit> search(
    String text, {
    List<String> tags = const [],
    String rootId = '',
  }) => _svc
      .search(pb.SearchRequest(text: text, tags: tags, rootId: rootId))
      .map(
        (h) => SearchHit(
          file: FilePath(h.rootId, h.path),
          kind: _kind(h.kind),
          meta: _meta(h.hasMeta() ? h.meta : null),
          snippet: h.snippet,
          line: h.line,
        ),
      );

  @override
  Stream<WorkspaceChange> watch() => _svc
      .watch(pb.WatchRequest())
      .map(
        (c) => WorkspaceChange(
          file: FilePath(c.rootId, c.path),
          kind: switch (c.kind) {
            pb.ChangeKind.CHANGE_KIND_CREATED => ChangeKind.created,
            pb.ChangeKind.CHANGE_KIND_DELETED => ChangeKind.deleted,
            pb.ChangeKind.CHANGE_KIND_RENAMED => ChangeKind.renamed,
            _ => ChangeKind.modified,
          },
          oldPath: c.oldPath,
        ),
      );

  void _check(pb.WorkspaceError? e) {
    if (e == null) return;
    throw WorkspaceFailure(
      switch (e.kind) {
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT =>
          WorkspaceErrorKind.pathEscapesRoot,
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_NOT_FOUND =>
          WorkspaceErrorKind.notFound,
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_ALREADY_EXISTS =>
          WorkspaceErrorKind.alreadyExists,
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_CONFLICT =>
          WorkspaceErrorKind.conflict,
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_TOO_LARGE =>
          WorkspaceErrorKind.tooLarge,
        pb.WorkspaceErrorKind.WORKSPACE_ERROR_KIND_IO => WorkspaceErrorKind.io,
        _ => WorkspaceErrorKind.unspecified,
      },
      e.message,
      current: e.hasCurrent() ? _file(e.current) : null,
    );
  }
}

WorkspaceFile _file(pb.FileContent f) => WorkspaceFile(
  content: f.content,
  mtime: f.mtime.toDateTime(),
  hash: f.hash,
  meta: _meta(f.hasMeta() ? f.meta : null),
  kind: _kind(f.kind),
);

FileMeta _meta(pb.FileMeta? m) => m == null
    ? const FileMeta()
    : FileMeta(
        title: m.title,
        description: m.description,
        connection: m.connection,
        tags: List.of(m.tags),
      );

FileKind _kind(pb.FileKind k) => switch (k) {
  pb.FileKind.FILE_KIND_SQL => FileKind.sql,
  pb.FileKind.FILE_KIND_MONGO => FileKind.mongo,
  _ => FileKind.other,
};
