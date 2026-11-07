import 'package:flutter/foundation.dart';

/// Failure class of a workspace operation (mirrors WorkspaceErrorKind).
enum WorkspaceErrorKind {
  unspecified,
  pathEscapesRoot,
  notFound,
  alreadyExists,
  conflict,
  tooLarge,
  io,
}

/// What a workspace file is for.
enum FileKind { other, sql, mongo }

/// Header metadata of a script.
@immutable
class FileMeta {
  const FileMeta({
    this.title = '',
    this.description = '',
    this.connection = '',
    this.tags = const [],
  });

  final String title;
  final String description;

  /// Default connection id or name. Never credentials.
  final String connection;
  final List<String> tags;
}

/// A workspace folder.
@immutable
class WorkspaceRoot {
  const WorkspaceRoot({
    required this.id,
    required this.name,
    required this.path,
  });
  final String id;
  final String name;
  final String path;
}

/// A file or folder inside a root: [root] and a slash-separated [path],
/// empty for the root itself.
@immutable
class FilePath {
  const FilePath(this.root, this.path);
  final String root;
  final String path;

  String get name => path.split('/').last;

  /// Directory part, empty for a file at the top of the root.
  String get parent {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  FilePath child(String name) =>
      FilePath(root, path.isEmpty ? name : '$path/$name');

  @override
  bool operator ==(Object other) =>
      other is FilePath && other.root == root && other.path == path;

  @override
  int get hashCode => Object.hash(root, path);

  @override
  String toString() => '$root:$path';
}

/// One row of a directory listing.
@immutable
class TreeEntry {
  const TreeEntry({
    required this.name,
    required this.isDir,
    this.kind = FileKind.other,
    this.size = 0,
    this.mtime,
    this.meta = const FileMeta(),
  });

  final String name;
  final bool isDir;
  final FileKind kind;
  final int size;
  final DateTime? mtime;
  final FileMeta meta;
}

/// A file read from disk.
@immutable
class WorkspaceFile {
  const WorkspaceFile({
    required this.content,
    required this.mtime,
    required this.hash,
    this.meta = const FileMeta(),
    this.kind = FileKind.other,
  });

  final String content;
  final DateTime mtime;
  final String hash;
  final FileMeta meta;
  final FileKind kind;
}

/// The state of a file after a write or create.
@immutable
class FileStamp {
  const FileStamp({required this.mtime, required this.hash});
  final DateTime mtime;
  final String hash;
}

/// A search result.
@immutable
class SearchHit {
  const SearchHit({
    required this.file,
    required this.kind,
    this.meta = const FileMeta(),
    this.snippet = '',
    this.line = 0,
  });

  final FilePath file;
  final FileKind kind;
  final FileMeta meta;
  final String snippet;
  final int line;
}

enum ChangeKind { created, modified, deleted, renamed }

/// A change made on disk.
@immutable
class WorkspaceChange {
  const WorkspaceChange({
    required this.file,
    required this.kind,
    this.oldPath = '',
  });

  final FilePath file;
  final ChangeKind kind;

  /// For renames: the previous path.
  final String oldPath;
}

/// Thrown by a repository call the core reported as failed.
class WorkspaceFailure implements Exception {
  const WorkspaceFailure(this.kind, this.message, {this.current});
  final WorkspaceErrorKind kind;
  final String message;

  /// For conflicts: the file as it is on disk now; null if it was deleted.
  final WorkspaceFile? current;

  bool get isConflict => kind == WorkspaceErrorKind.conflict;

  @override
  String toString() => message;
}

/// Kind of a file name, from its extension.
FileKind fileKindOf(String name) {
  if (name.endsWith('.mongo.js')) return FileKind.mongo;
  if (name.endsWith('.sql')) return FileKind.sql;
  return FileKind.other;
}
