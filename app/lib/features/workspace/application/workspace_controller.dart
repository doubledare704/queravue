import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../data/workspace_repository.dart';
import '../domain/workspace_models.dart';

/// Changes made on disk, from the core's Watch stream. Restarts when the
/// core reconnects.
final workspaceChangesProvider = StreamProvider<WorkspaceChange>((ref) {
  if (!ref.watch(coreReadyProvider)) return const Stream.empty();
  return ref.watch(workspaceRepositoryProvider).watch();
});

/// One visible row of the workspace tree.
@immutable
class WorkspaceRow {
  const WorkspaceRow({
    required this.file,
    required this.depth,
    required this.isDir,
    required this.name,
    this.entry,
    this.expanded = false,
  });

  final FilePath file;
  final int depth;
  final bool isDir;
  final String name;

  /// Null for a root.
  final TreeEntry? entry;
  final bool expanded;
}

@immutable
class WorkspaceState {
  const WorkspaceState({
    this.roots = const [],
    this.dirs = const {},
    this.expanded = const {},
    this.loaded = false,
    this.error,
    this.query = '',
    this.hits = const [],
    this.searching = false,
    this.searchError,
  });

  final List<WorkspaceRoot> roots;

  /// Loaded directory listings.
  final Map<FilePath, List<TreeEntry>> dirs;
  final Set<FilePath> expanded;
  final bool loaded;
  final String? error;

  final String query;
  final List<SearchHit> hits;
  final bool searching;
  final String? searchError;

  bool get isSearch => query.trim().isNotEmpty;

  WorkspaceState copyWith({
    List<WorkspaceRoot>? roots,
    Map<FilePath, List<TreeEntry>>? dirs,
    Set<FilePath>? expanded,
    bool? loaded,
    String? error,
    bool clearError = false,
    String? query,
    List<SearchHit>? hits,
    bool? searching,
    String? searchError,
    bool clearSearchError = false,
  }) => WorkspaceState(
    roots: roots ?? this.roots,
    dirs: dirs ?? this.dirs,
    expanded: expanded ?? this.expanded,
    loaded: loaded ?? this.loaded,
    error: clearError ? null : (error ?? this.error),
    query: query ?? this.query,
    hits: hits ?? this.hits,
    searching: searching ?? this.searching,
    searchError: clearSearchError ? null : (searchError ?? this.searchError),
  );
}

/// Rows of the tree: every root, with the contents of expanded folders.
List<WorkspaceRow> flattenWorkspace(WorkspaceState s) {
  final rows = <WorkspaceRow>[];
  void walk(FilePath dir, int depth) {
    for (final e in s.dirs[dir] ?? const <TreeEntry>[]) {
      final f = dir.child(e.name);
      final open = e.isDir && s.expanded.contains(f);
      rows.add(
        WorkspaceRow(
          file: f,
          depth: depth,
          isDir: e.isDir,
          name: e.name,
          entry: e,
          expanded: open,
        ),
      );
      if (open) walk(f, depth + 1);
    }
  }

  for (final r in s.roots) {
    final root = FilePath(r.id, '');
    final open = s.expanded.contains(root);
    rows.add(
      WorkspaceRow(
        file: root,
        depth: 0,
        isDir: true,
        name: r.name,
        expanded: open,
      ),
    );
    if (open) walk(root, 1);
  }
  return rows;
}

/// Splits a search box text into free text and `#tag` filters.
({String text, List<String> tags}) parseSearch(String raw) {
  final words = raw.trim().split(RegExp(r'\s+'));
  final tags = [
    for (final w in words)
      if (w.length > 1 && w.startsWith('#')) w.substring(1),
  ];
  final text = [
    for (final w in words)
      if (!(w.length > 1 && w.startsWith('#'))) w,
  ].join(' ').trim();
  return (text: text, tags: tags);
}

final workspaceProvider = NotifierProvider<WorkspaceController, WorkspaceState>(
  WorkspaceController.new,
);

/// The workspace tree and search of the sidebar panel.
class WorkspaceController extends Notifier<WorkspaceState> {
  StreamSubscription<SearchHit>? _search;
  int _searchEpoch = 0;

  WorkspaceRepository get _repo => ref.read(workspaceRepositoryProvider);

  @override
  WorkspaceState build() {
    final ready = ref.watch(coreReadyProvider);
    ref.onDispose(() => unawaited(_search?.cancel()));
    ref.listen(workspaceChangesProvider, (_, next) {
      final c = next.value;
      if (c != null) _onChange(c);
    });
    if (ready) Future.microtask(load);
    return const WorkspaceState();
  }

  /// Loads the roots and their top-level folders.
  Future<void> load() async {
    try {
      final roots = await _repo.roots();
      if (!ref.mounted) return;
      state = state.copyWith(
        roots: roots,
        loaded: true,
        clearError: true,
        expanded: {
          ...state.expanded,
          for (final r in roots) FilePath(r.id, ''),
        },
      );
      await Future.wait([for (final r in roots) reload(FilePath(r.id, ''))]);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(loaded: true, error: '$e');
    }
  }

  /// Loads the roots if that has not happened yet, e.g. when a palette
  /// command needs them before the panel was ever shown.
  Future<void> ensureLoaded() async {
    if (!state.loaded) await load();
  }

  /// Re-reads one folder.
  Future<void> reload(FilePath dir) async {
    try {
      final entries = await _repo.listTree(dir);
      if (!ref.mounted) return;
      state = state.copyWith(
        dirs: {...state.dirs, dir: entries},
        clearError: true,
      );
    } on WorkspaceFailure catch (e) {
      if (!ref.mounted) return;
      if (e.kind == WorkspaceErrorKind.notFound) {
        state = state.copyWith(dirs: {...state.dirs}..remove(dir));
      } else {
        state = state.copyWith(error: e.message);
      }
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: '$e');
    }
  }

  /// Reloads every loaded folder.
  Future<void> refresh() =>
      Future.wait([for (final d in state.dirs.keys.toList()) reload(d)]);

  Future<void> toggle(FilePath dir) async {
    if (state.expanded.contains(dir)) {
      state = state.copyWith(expanded: {...state.expanded}..remove(dir));
      return;
    }
    state = state.copyWith(expanded: {...state.expanded, dir});
    if (!state.dirs.containsKey(dir)) await reload(dir);
  }

  /// Makes sure [dir] and its ancestors are open, so [dir]'s content shows.
  Future<void> reveal(FilePath dir) async {
    final open = {...state.expanded};
    var cur = FilePath(dir.root, '');
    open.add(cur);
    for (final part
        in dir.path.isEmpty ? const <String>[] : dir.path.split('/')) {
      cur = cur.child(part);
      open.add(cur);
    }
    state = state.copyWith(expanded: open);
    for (final d in open.where((d) => d.root == dir.root)) {
      if (!state.dirs.containsKey(d)) await reload(d);
    }
  }

  void _onChange(WorkspaceChange c) {
    final dirs = {
      FilePath(c.file.root, c.file.parent),
      if (c.oldPath.isNotEmpty)
        FilePath(
          c.file.root,
          c.oldPath.contains('/')
              ? c.oldPath.substring(0, c.oldPath.lastIndexOf('/'))
              : '',
        ),
    };
    for (final d in dirs) {
      if (state.dirs.containsKey(d)) unawaited(reload(d));
    }
  }

  /// Creates a file named [name] in [dir] and returns its path. A missing
  /// extension is added from [kind].
  Future<FilePath> createFile(FilePath dir, String name, FileKind kind) async {
    final file = dir.child(withExtension(name.trim(), kind));
    await _repo.create(file);
    await reveal(dir);
    await reload(dir);
    return file;
  }

  Future<void> createFolder(FilePath dir, String name) async {
    await _repo.create(dir.child(name.trim()), isDir: true);
    await reveal(dir);
    await reload(dir);
  }

  /// Renames or moves [file] to the root-relative path [to].
  Future<void> rename(FilePath file, String to) async {
    await _repo.rename(file.root, file.path, to);
    await reload(FilePath(file.root, file.parent));
    final i = to.lastIndexOf('/');
    await reload(FilePath(file.root, i < 0 ? '' : to.substring(0, i)));
  }

  Future<void> delete(FilePath file) async {
    await _repo.delete(file);
    await reload(FilePath(file.root, file.parent));
  }

  /// Searches script files; an empty [raw] clears the search.
  Future<void> search(String raw) async {
    final epoch = ++_searchEpoch;
    unawaited(_search?.cancel());
    if (!ref.mounted) return;
    if (raw.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        hits: const [],
        searching: false,
        clearSearchError: true,
      );
      return;
    }
    state = state.copyWith(
      query: raw,
      hits: const [],
      searching: true,
      clearSearchError: true,
    );
    final q = parseSearch(raw);
    final hits = <SearchHit>[];
    final done = Completer<void>();
    _search = _repo
        .search(q.text, tags: q.tags)
        .listen(
          (h) {
            if (epoch != _searchEpoch || !ref.mounted) return;
            hits.add(h);
            state = state.copyWith(hits: [...hits]);
          },
          onError: (Object e) {
            if (epoch == _searchEpoch && ref.mounted) {
              state = state.copyWith(searching: false, searchError: '$e');
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (epoch == _searchEpoch && ref.mounted) {
              state = state.copyWith(searching: false);
            }
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
  }
}

/// [name] with the extension of [kind] if it has none of the known ones.
String withExtension(String name, FileKind kind) {
  if (fileKindOf(name) != FileKind.other) return name;
  return switch (kind) {
    FileKind.sql => '$name.sql',
    FileKind.mongo => '$name.mongo.js',
    FileKind.other => name,
  };
}
