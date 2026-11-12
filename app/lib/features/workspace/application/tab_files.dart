import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diagram/application/saved_diagram_opener.dart';
import '../../diagram/data/diagram_files.dart';
import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../connections/domain/models.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/application/layout_persistence.dart';
import '../data/workspace_repository.dart';
import '../domain/file_header.dart';
import '../domain/workspace_models.dart';
import 'workspace_controller.dart';

enum ExternalKind { modified, deleted }

/// A change made outside the app to the file a tab is bound to.
@immutable
class ExternalChange {
  const ExternalChange(this.kind, {this.hash = '', this.mtime});
  final ExternalKind kind;
  final String hash;
  final DateTime? mtime;
}

/// The workspace file an editor tab is bound to, and what was last saved.
@immutable
class TabFileState {
  const TabFileState({
    required this.file,
    required this.savedText,
    required this.savedHash,
    required this.savedMtime,
    this.external,
  });

  final FilePath file;
  final String savedText;

  /// Hash of the file as the tab last read or wrote it; empty if the file was
  /// deleted underneath and a save will recreate it.
  final String savedHash;
  final DateTime? savedMtime;
  final ExternalChange? external;

  TabFileState copyWith({
    FilePath? file,
    String? savedText,
    String? savedHash,
    DateTime? savedMtime,
    ExternalChange? external,
    bool clearExternal = false,
  }) => TabFileState(
    file: file ?? this.file,
    savedText: savedText ?? this.savedText,
    savedHash: savedHash ?? this.savedHash,
    savedMtime: savedMtime ?? this.savedMtime,
    external: clearExternal ? null : (external ?? this.external),
  );
}

/// Whether the tab's buffer differs from its file.
bool isTabDirty(EditorTab tab, TabFileState? file) =>
    file != null && tab.controller.text != file.savedText;

/// Result of a save.
sealed class SaveOutcome {
  const SaveOutcome();
}

final class Saved extends SaveOutcome {
  const Saved();
}

/// The tab is not bound to a file: use save as.
final class NotBound extends SaveOutcome {
  const NotBound();
}

/// The file changed on disk. [current] is null if it was deleted.
final class SaveConflict extends SaveOutcome {
  const SaveConflict(this.current);
  final WorkspaceFile? current;
}

final class SaveFailed extends SaveOutcome {
  const SaveFailed(this.message, {this.exists = false});
  final String message;

  /// The target of a save as already exists.
  final bool exists;
}

final tabFileProvider =
    NotifierProvider.family<TabFileController, TabFileState?, String>(
      TabFileController.new,
    );

/// Keeps one editor tab and its workspace file in step.
class TabFileController extends Notifier<TabFileState?> {
  TabFileController(this.tabId);

  final String tabId;

  WorkspaceRepository get _repo => ref.read(workspaceRepositoryProvider);

  EditorTab? get _tab =>
      ref.read(editorTabsProvider).tabs.where((t) => t.id == tabId).firstOrNull;

  @override
  TabFileState? build() {
    ref.listen(
      editorTabsProvider.select((s) => s.tabs.any((t) => t.id == tabId)),
      (was, open) {
        if (was == true && !open) ref.invalidateSelf();
      },
    );
    return null;
  }

  // Started on first bind, so unbound tabs never touch the core.
  ProviderSubscription<AsyncValue<WorkspaceChange>>? _changes;

  void _watchChanges() {
    _changes ??= ref.listen(workspaceChangesProvider, (_, next) {
      final c = next.value;
      if (c != null) unawaited(_onChange(c));
    });
  }

  /// Binds the tab to [file], whose content the buffer now holds.
  void bind(FilePath file, WorkspaceFile content) {
    _watchChanges();
    state = TabFileState(
      file: file,
      savedText: content.content,
      savedHash: content.hash,
      savedMtime: content.mtime,
    );
    ref.read(editorTabsProvider.notifier).retitle(tabId, file.name);
  }

  /// Writes the buffer to the bound file. [force] overwrites a file that
  /// changed on disk.
  Future<SaveOutcome> save({bool force = false}) async {
    final s = state;
    final tab = _tab;
    if (s == null || tab == null) return const NotBound();
    final text = tab.controller.text;
    try {
      final stamp = await _repo.write(
        s.file,
        text,
        expectedHash: s.savedHash,
        force: force,
      );
      if (!ref.mounted) return const Saved();
      state = s.copyWith(
        savedText: text,
        savedHash: stamp.hash,
        savedMtime: stamp.mtime,
        clearExternal: true,
      );
      return const Saved();
    } on WorkspaceFailure catch (e) {
      return e.isConflict ? SaveConflict(e.current) : SaveFailed(e.message);
    } catch (e) {
      return SaveFailed('$e');
    }
  }

  /// Saves the buffer as a new file [target] and binds the tab to it. The
  /// buffer becomes [content] (the text with a header, if one was added).
  Future<SaveOutcome> saveAs(
    FilePath target,
    String content, {
    bool overwrite = false,
  }) async {
    final tab = _tab;
    if (tab == null) return const SaveFailed('The tab is closed.');
    try {
      _watchChanges();
      final FileStamp? stamp;
      if (overwrite) {
        stamp = await _repo.write(target, content, force: true);
      } else {
        stamp = await _repo.create(target, content: content);
      }
      if (!ref.mounted || stamp == null) return const Saved();
      tab.controller.text = content;
      state = TabFileState(
        file: target,
        savedText: content,
        savedHash: stamp.hash,
        savedMtime: stamp.mtime,
      );
      ref.read(editorTabsProvider.notifier).retitle(tabId, target.name);
      return const Saved();
    } on WorkspaceFailure catch (e) {
      return SaveFailed(
        e.message,
        exists: e.kind == WorkspaceErrorKind.alreadyExists,
      );
    } catch (e) {
      return SaveFailed('$e');
    }
  }

  /// Replaces the buffer with the file on disk. False if it is gone.
  Future<bool> reload() async {
    final s = state;
    final tab = _tab;
    if (s == null || tab == null) return false;
    try {
      final f = await _repo.read(s.file);
      if (!ref.mounted) return false;
      tab.controller.text = f.content;
      state = s.copyWith(
        savedText: f.content,
        savedHash: f.hash,
        savedMtime: f.mtime,
        clearExternal: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Keeps the buffer and treats the disk version as seen, so the next save
  /// overwrites it.
  void keepMine() {
    final s = state;
    final ext = s?.external;
    if (s == null || ext == null) return;
    state = s.copyWith(
      savedHash: ext.kind == ExternalKind.deleted ? '' : ext.hash,
      savedMtime: ext.mtime,
      clearExternal: true,
    );
  }

  Future<void> _onChange(WorkspaceChange c) async {
    final s = state;
    if (s == null || c.file.root != s.file.root) return;
    switch (c.kind) {
      case ChangeKind.renamed:
        final moved = _renamed(s.file.path, c.oldPath, c.file.path);
        if (moved != null) {
          state = s.copyWith(file: FilePath(s.file.root, moved));
          ref
              .read(editorTabsProvider.notifier)
              .retitle(tabId, FilePath(s.file.root, moved).name);
        }
      case ChangeKind.deleted:
        if (_covers(c.file.path, s.file.path)) {
          state = s.copyWith(
            external: const ExternalChange(ExternalKind.deleted),
          );
        }
      case ChangeKind.created || ChangeKind.modified:
        if (c.file.path != s.file.path) return;
        try {
          final f = await _repo.read(s.file);
          final now = state;
          if (!ref.mounted || now == null || f.hash == now.savedHash) return;
          state = now.copyWith(
            external: ExternalChange(
              ExternalKind.modified,
              hash: f.hash,
              mtime: f.mtime,
            ),
          );
        } on WorkspaceFailure catch (e) {
          if (e.kind == WorkspaceErrorKind.notFound && ref.mounted) {
            state = state?.copyWith(
              external: const ExternalChange(ExternalKind.deleted),
            );
          }
        } catch (_) {}
    }
  }

  static bool _covers(String changed, String file) =>
      file == changed || file.startsWith('$changed/');

  /// The new path of [file] after [from] was renamed to [to], if affected.
  static String? _renamed(String file, String from, String to) {
    if (file == from) return to;
    if (file.startsWith('$from/')) return '$to${file.substring(from.length)}';
    return null;
  }
}

/// What opening a file produced.
sealed class OpenOutcome {
  const OpenOutcome();
}

final class Opened extends OpenOutcome {
  const Opened(this.tabId);
  final String tabId;
}

final class OpenFailed extends OpenOutcome {
  const OpenFailed(this.message);
  final String message;
}

final fileOpenerProvider = Provider<FileOpener>(FileOpener.new);

/// Opens workspace files in editor tabs: SQL files in a query tab, Mongo
/// scripts in a shell tab, on the file's default connection.
class FileOpener {
  FileOpener(this._ref);

  final Ref _ref;

  Future<OpenOutcome> open(FilePath file) async {
    if (isSavedDiagramPath(file)) return openSavedDiagram(_ref.read, file);
    final persistence = _ref.read(layoutPersistenceProvider);
    final restored = persistence.unloadedTabFor(file);
    if (restored != null) {
      await persistence.ensureLoaded(restored);
      final tab = _ref
          .read(editorTabsProvider)
          .tabs
          .where((t) => t.id == restored)
          .firstOrNull;
      if (tab != null) {
        _ref.read(selectedConnectionProvider.notifier).select(tab.connectionId);
        _ref.read(editorTabsProvider.notifier).select(tab.id);
        return Opened(tab.id);
      }
    }
    final tabs = _ref.read(editorTabsProvider);
    for (final t in tabs.tabs) {
      if (_ref.read(tabFileProvider(t.id))?.file == file) {
        _ref.read(selectedConnectionProvider.notifier).select(t.connectionId);
        _ref.read(editorTabsProvider.notifier).select(t.id);
        return Opened(t.id);
      }
    }
    final WorkspaceFile content;
    try {
      content = await _ref.read(workspaceRepositoryProvider).read(file);
    } on WorkspaceFailure catch (e) {
      return OpenFailed(e.message);
    } catch (e) {
      return OpenFailed('$e');
    }
    final kind = content.kind != FileKind.other
        ? content.kind
        : fileKindOf(file.name);
    if (kind == FileKind.other) {
      return const OpenFailed(
        'Only .sql and .mongo.js files open in an editor.',
      );
    }
    // Right after startup the connections and engines may still be loading,
    // and without them no connection can be judged suitable.
    try {
      await Future.wait([
        _ref.read(connectionsControllerProvider.future),
        _ref.read(enginesProvider.future),
      ]);
    } catch (_) {
      return const OpenFailed('Connections are not available yet.');
    }
    final connectionId = _pickConnection(kind, content.meta.connection);
    if (connectionId == null) {
      return OpenFailed(
        kind == FileKind.sql
            ? 'Select a SQL connection first, then open the file.'
            : 'Select a MongoDB connection first, then open the file.',
      );
    }
    final notifier = _ref.read(editorTabsProvider.notifier);
    final tab = kind == FileKind.sql
        ? notifier.open(connectionId)
        : notifier.openShell(connectionId);
    tab.controller.text = content.content;
    _ref.read(selectedConnectionProvider.notifier).select(connectionId);
    _ref.read(tabFileProvider(tab.id).notifier).bind(file, content);
    return Opened(tab.id);
  }

  /// The connection named in the header, else the selected one, if it suits
  /// [kind].
  String? _pickConnection(FileKind kind, String headerRef) {
    final profiles =
        _ref.read(connectionsControllerProvider).value ??
        const <ConnectionProfile>[];
    bool suits(String id) {
      final isDoc = _ref.read(connectionIsDocumentOnlyProvider(id));
      return kind == FileKind.sql
          ? !isDoc
          : _ref.read(connectionHasShellProvider(id));
    }

    final named = headerRef.isEmpty
        ? null
        : profiles
              .where((p) => p.id == headerRef)
              .followedBy(profiles.where((p) => p.name == headerRef))
              .firstOrNull;
    if (named != null && suits(named.id)) return named.id;
    final selected = _ref.read(selectedConnectionProvider);
    if (selected != null && suits(selected)) return selected;
    return null;
  }

  /// Header text for a new file saved from [tab]'s connection.
  String headerFor(String connectionId) =>
      _ref
          .read(connectionsControllerProvider)
          .value
          ?.where((p) => p.id == connectionId)
          .firstOrNull
          ?.name ??
      '';
}

/// [body] saved for the first time, with an optional title and connection
/// header.
String bodyForNewFile(
  FileKind kind,
  String body, {
  String title = '',
  String connection = '',
}) => withHeader(kind, body, title: title, connection: connection);
