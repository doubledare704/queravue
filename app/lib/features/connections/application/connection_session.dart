import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';
import 'connections_controller.dart';

/// State of an active DB session for a connection.
class ConnectionSessionState {
  const ConnectionSessionState({
    this.isConnecting = false,
    this.session,
    this.error,
    this.tunnelLost = false,
  });

  final bool isConnecting;
  final SessionInfo? session;
  final String? error;
  final bool tunnelLost;

  String? get sessionId => session?.id;
  bool get isConnected => session != null;
}

/// Manages a live session per connection.
class ConnectionSessionController extends Notifier<ConnectionSessionState> {
  ConnectionSessionController(this.connectionId);

  final String connectionId;
  QueryRepository? _repo;
  SessionInfo? _session;
  int _generation = 0;

  @override
  ConnectionSessionState build() {
    _repo = null;
    _session = null;
    ref.onDispose(() {
      _generation++;
      final s = _session;
      final repo = _repo;
      if (s != null && repo != null) {
        unawaited(repo.closeSession(s.id).catchError((_) {}));
      }
    });
    return const ConnectionSessionState();
  }

  Future<SessionInfo?> connect() async {
    if (state.isConnecting) return null;
    if (state.session != null) return state.session;

    final generation = ++_generation;
    state = ConnectionSessionState(
      isConnecting: true,
      tunnelLost: state.tunnelLost,
    );
    try {
      final repo = ref.read(queryRepositoryProvider);
      _repo = repo;
      final session = await repo.openSession(connectionId);
      if (!ref.mounted || generation != _generation) {
        await repo.closeSession(session.id);
        return null;
      }
      _session = session;
      state = ConnectionSessionState(session: session);
      return session;
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = ConnectionSessionState(
          error: e.toString(),
          tunnelLost: state.tunnelLost,
        );
      }
      return null;
    }
  }

  void markTunnelLost() {
    if (state.isConnecting) return;
    state = ConnectionSessionState(session: state.session, tunnelLost: true);
  }

  Future<void> reconnect() async {
    if (state.isConnecting) return;
    final generation = ++_generation;
    final old = _session;
    final repo = _repo;
    _session = null;
    state = const ConnectionSessionState(isConnecting: true, tunnelLost: true);
    if (old != null && repo != null) {
      try {
        await repo.closeSession(old.id);
      } on QueryException {
        // The core may already have closed the lost session.
      }
    }
    if (!ref.mounted || generation != _generation) return;
    state = const ConnectionSessionState(tunnelLost: true);
    await connect();
  }

  Future<void> disconnect() async {
    _generation++;
    final s = _session;
    final repo = _repo;
    _session = null;
    state = const ConnectionSessionState();
    if (s != null && repo != null) {
      try {
        await repo.closeSession(s.id);
      } catch (_) {}
    }
  }
}

final connectionSessionProvider =
    NotifierProvider.family<
      ConnectionSessionController,
      ConnectionSessionState,
      String
    >(ConnectionSessionController.new);

/// Capability names of a connection: from the live session when connected,
/// else from the engine descriptor; null while unknown.
final connectionCapabilitiesProvider = Provider.family<Set<String>?, String>((
  ref,
  connectionId,
) {
  final session = ref.watch(connectionSessionProvider(connectionId)).session;
  if (session != null) return session.capabilities;
  final profile = ref
      .watch(connectionsControllerProvider)
      .value
      ?.where((c) => c.id == connectionId)
      .firstOrNull;
  return ref
      .watch(enginesProvider)
      .value
      ?.where((e) => e.id == profile?.engineId)
      .firstOrNull
      ?.capabilities;
});

/// True if the connection's engine has the `shell` capability. Unknown means
/// false.
final connectionHasShellProvider = Provider.family<bool, String>(
  (ref, connectionId) =>
      ref
          .watch(connectionCapabilitiesProvider(connectionId))
          ?.contains('shell') ??
      false,
);

/// True when the connection can serve a schema diagram.
final connectionHasSchemaGraphProvider = Provider.family<bool, String>(
  (ref, connectionId) =>
      ref
          .watch(connectionCapabilitiesProvider(connectionId))
          ?.contains('schema_graph') ??
      false,
);

/// True when tables can be designed on the connection's diagram: it draws
/// diagrams and runs SQL.
final connectionCanDesignDiagramProvider = Provider.family<bool, String>((
  ref,
  connectionId,
) {
  final capabilities = ref.watch(connectionCapabilitiesProvider(connectionId));
  return capabilities != null &&
      capabilities.contains('schema_graph') &&
      capabilities.contains('execute');
});

/// True for connections to document engines that cannot run SQL: they have
/// the `document_store` capability and not `execute`; unknown means false, so
/// SQL entry points stay available.
final connectionIsDocumentOnlyProvider = Provider.family<bool, String>((
  ref,
  connectionId,
) {
  final caps = ref.watch(connectionCapabilitiesProvider(connectionId));
  return caps != null &&
      caps.contains('document_store') &&
      !caps.contains('execute');
});
