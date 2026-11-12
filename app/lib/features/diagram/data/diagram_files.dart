import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/data/workspace_repository.dart';
import '../../workspace/domain/workspace_models.dart';
import '../domain/diagram_models.dart';
import '../domain/saved_diagram.dart';

const diagramsDir = '.queravue/diagrams';
const _extension = '.json';
const _maxNameLength = 80;
final _validName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 _.\-]*$');

bool isSavedDiagramPath(FilePath file) =>
    file.path.startsWith('$diagramsDir/') &&
    file.path.endsWith(_extension) &&
    !file.path.substring(diagramsDir.length + 1).contains('/');

String diagramNameOf(FilePath file) =>
    file.name.substring(0, file.name.length - _extension.length);

/// The name the user typed, trimmed, or null if it cannot be a file name.
String? validDiagramName(String typed) {
  final name = typed.trim();
  if (name.toLowerCase().endsWith(_extension)) {
    return validDiagramName(name.substring(0, name.length - _extension.length));
  }
  if (name.isEmpty || name.length > _maxNameLength) return null;
  return _validName.hasMatch(name) ? name : null;
}

final diagramFilesProvider = Provider<DiagramFiles>(
  (ref) => DiagramFiles(ref.watch(workspaceRepositoryProvider)),
);

/// Saved diagrams in the first workspace root, through the core.
class DiagramFiles {
  DiagramFiles(this._repo);

  final WorkspaceRepository _repo;

  /// Where a diagram called [name] is saved; null without a workspace.
  Future<FilePath?> pathFor(String name) async {
    final roots = await _repo.roots();
    if (roots.isEmpty) return null;
    return FilePath(roots.first.id, '$diagramsDir/$name$_extension');
  }

  Future<List<FilePath>> list() async {
    final roots = await _repo.roots();
    if (roots.isEmpty) return const [];
    final dir = FilePath(roots.first.id, diagramsDir);
    final List<TreeEntry> entries;
    try {
      entries = await _repo.listTree(dir);
    } on WorkspaceFailure catch (e) {
      if (e.kind == WorkspaceErrorKind.notFound) return const [];
      rethrow;
    }
    final files = [
      for (final e in entries)
        if (!e.isDir && e.name.endsWith(_extension))
          FilePath(dir.root, '$diagramsDir/${e.name}'),
    ];
    return files..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<bool> exists(FilePath file) async {
    try {
      await _repo.read(file);
      return true;
    } on WorkspaceFailure catch (e) {
      if (e.kind == WorkspaceErrorKind.notFound) return false;
      rethrow;
    }
  }

  /// Throws [DiagramFailure] when the file is missing or not a diagram.
  Future<SavedDiagram> read(FilePath file) async {
    final WorkspaceFile content;
    try {
      content = await _repo.read(file);
    } on WorkspaceFailure catch (e) {
      throw DiagramFailure(
        e.kind == WorkspaceErrorKind.notFound
            ? '${file.name} does not exist'
            : e.message,
      );
    }
    final diagram = SavedDiagram.fromJson(content.content);
    if (diagram == null) {
      throw DiagramFailure('${file.name} is not a Queravue diagram');
    }
    return diagram;
  }

  /// Writes [diagram] to [file], creating the folders it needs.
  Future<void> write(FilePath file, SavedDiagram diagram) async {
    final content = diagram.toJson();
    try {
      if (await exists(file)) {
        await _repo.write(file, content, force: true);
        return;
      }
      for (final dir in ['.queravue', diagramsDir]) {
        try {
          await _repo.create(FilePath(file.root, dir), isDir: true);
        } on WorkspaceFailure catch (e) {
          if (e.kind != WorkspaceErrorKind.alreadyExists) rethrow;
        }
      }
      await _repo.create(file, content: content);
    } on WorkspaceFailure catch (e) {
      throw DiagramFailure(e.message);
    }
  }
}
