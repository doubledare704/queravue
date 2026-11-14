import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/core_supervisor.dart';
import '../../core_status/core_status_controller.dart';
import '../data/connections_repository.dart';
import '../domain/models.dart';
import '../domain/network_settings.dart';

/// Whether a core is connected and can serve requests. Override in tests.
final coreReadyProvider = Provider<bool>(
  (ref) => ref.watch(coreStatusProvider) is CoreConnected,
);

const _coreNotConnected = ConnectionsException(
  'Core not connected',
  coreUnavailable: true,
);

/// No automatic retries: these providers already rebuild when the core
/// (re)connects, and the UI offers an explicit Retry.
Duration? _noRetry(int retryCount, Object error) => null;

/// Engines the core supports. Reloads when the core (re)connects.
final enginesProvider = FutureProvider<List<EngineSpec>>((ref) async {
  if (!ref.watch(coreReadyProvider)) throw _coreNotConnected;
  return ref.watch(connectionsRepositoryProvider).listEngines();
}, retry: _noRetry);

/// Saved connections. Reloads when the core (re)connects.
class ConnectionsController extends AsyncNotifier<List<ConnectionProfile>> {
  ConnectionsRepository get _repo => ref.read(connectionsRepositoryProvider);

  @override
  Future<List<ConnectionProfile>> build() async {
    if (!ref.watch(coreReadyProvider)) throw _coreNotConnected;
    return ref.watch(connectionsRepositoryProvider).list();
  }

  /// Reloads from the core.
  Future<void> reload() async {
    state = await AsyncValue.guard(_repo.list);
  }

  /// Creates or updates [profile] and refreshes the list.
  Future<ConnectionProfile> save(
    ConnectionProfile profile, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    bool clearPassword = false,
  }) async {
    final saved = profile.isSaved
        ? await _repo.update(
            profile,
            password: password,
            secrets: secrets,
            clearPassword: clearPassword,
          )
        : await _repo.create(profile, password: password, secrets: secrets);
    await reload();
    return saved;
  }

  /// Deletes [id] (and its keychain secret) and refreshes the list.
  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.read(connectionTestsProvider.notifier).forget(id);
    if (ref.read(selectedConnectionProvider) == id) {
      ref.read(selectedConnectionProvider.notifier).select(null);
    }
    await reload();
  }
}

final connectionsControllerProvider =
    AsyncNotifierProvider<ConnectionsController, List<ConnectionProfile>>(
      ConnectionsController.new,
      retry: _noRetry,
    );

/// Status of "Connect" (a test against a saved connection) per id.
sealed class ConnectStatus {
  const ConnectStatus();
}

final class Connecting extends ConnectStatus {
  const Connecting();
}

final class Connected extends ConnectStatus {
  const Connected(this.result);

  final TestResult result;
}

/// Runs "Connect" on saved connections and remembers the outcome. In
/// Iteration 1 connecting means a test with the stored keychain password;
/// long-lived sessions arrive with query execution.
class ConnectionTestsController extends Notifier<Map<String, ConnectStatus>> {
  @override
  Map<String, ConnectStatus> build() => const {};

  Future<TestResult> connect(String id) async {
    state = {...state, id: const Connecting()};
    TestResult result;
    try {
      result = await ref.read(connectionsRepositoryProvider).test(id: id);
    } on ConnectionsException catch (e) {
      result = TestFailed(ConnectionErrorKind.unknown, e.message);
    }
    if (ref.mounted) state = {...state, id: Connected(result)};
    return result;
  }

  void forget(String id) => state = {...state}..remove(id);
}

final connectionTestsProvider =
    NotifierProvider<ConnectionTestsController, Map<String, ConnectStatus>>(
      ConnectionTestsController.new,
    );

/// The connection selected in the sidebar.
class SelectedConnection extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedConnectionProvider =
    NotifierProvider<SelectedConnection, String?>(SelectedConnection.new);

/// Folder paths collapsed in the sidebar tree.
class CollapsedFolders extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String path) => state = state.contains(path)
      ? ({...state}..remove(path))
      : {...state, path};
}

final collapsedFoldersProvider =
    NotifierProvider<CollapsedFolders, Set<String>>(CollapsedFolders.new);

/// Connection ids collapsed in the sidebar tree.
class CollapsedConnections extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void expand(String id) => state = {...state}..remove(id);
  void collapse(String id) => state = {...state, id};
}

final collapsedConnectionsProvider =
    NotifierProvider<CollapsedConnections, Set<String>>(
      CollapsedConnections.new,
    );

/// One visible row of the sidebar tree.
sealed class TreeRow {
  const TreeRow(this.depth);

  final int depth;
}

final class FolderRow extends TreeRow {
  const FolderRow({
    required this.path,
    required this.name,
    required int depth,
    required this.expanded,
    required this.count,
  }) : super(depth);

  final String path;
  final String name;
  final bool expanded;

  /// Connections in this folder and its subfolders.
  final int count;
}

final class ConnectionRow extends TreeRow {
  const ConnectionRow(this.profile, int depth) : super(depth);

  final ConnectionProfile profile;
}

class _Folder {
  _Folder(this.name, this.path);

  final String name;
  final String path;
  final folders = <String, _Folder>{};
  final connections = <ConnectionProfile>[];

  int get count =>
      connections.length + folders.values.fold(0, (n, f) => n + f.count);
}

int _byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

/// Flattens [connections] into visible rows: within each folder, subfolders
/// first, then connections, both by name. Collapsed folders hide their
/// contents.
List<TreeRow> buildConnectionTree(
  List<ConnectionProfile> connections,
  Set<String> collapsed,
) {
  final root = _Folder('', '');
  for (final c in connections) {
    var node = root;
    for (final seg in c.folder.split('/').where((s) => s.isNotEmpty)) {
      final path = node.path.isEmpty ? seg : '${node.path}/$seg';
      node = node.folders.putIfAbsent(seg, () => _Folder(seg, path));
    }
    node.connections.add(c);
  }

  final rows = <TreeRow>[];
  void walk(_Folder f, int depth) {
    final subs = f.folders.values.toList()
      ..sort((a, b) => _byName(a.name, b.name));
    for (final sub in subs) {
      final expanded = !collapsed.contains(sub.path);
      rows.add(
        FolderRow(
          path: sub.path,
          name: sub.name,
          depth: depth,
          expanded: expanded,
          count: sub.count,
        ),
      );
      if (expanded) walk(sub, depth + 1);
    }
    final conns = [...f.connections]..sort((a, b) => _byName(a.name, b.name));
    rows.addAll(conns.map((c) => ConnectionRow(c, depth)));
  }

  walk(root, 0);
  return rows;
}

/// Visible tree rows for the sidebar.
final connectionTreeProvider = Provider<AsyncValue<List<TreeRow>>>((ref) {
  final collapsed = ref.watch(collapsedFoldersProvider);
  return ref
      .watch(connectionsControllerProvider)
      .whenData((list) => buildConnectionTree(list, collapsed));
});
