import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';

/// State of an active DB session for a connection.
class ConnectionSessionState {
  const ConnectionSessionState({
    this.isConnecting = false,
    this.session,
    this.error,
  });

  final bool isConnecting;
  final SessionInfo? session;
  final String? error;

  String? get sessionId => session?.id;
  bool get isConnected => session != null;
}

/// Manages a live session per connection.
class ConnectionSessionController extends Notifier<ConnectionSessionState> {
  ConnectionSessionController(this.connectionId);

  final String connectionId;
  QueryRepository? _repo;
  SessionInfo? _session;

  @override
  ConnectionSessionState build() {
    _repo = null;
    _session = null;
    ref.onDispose(() {
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

    state = const ConnectionSessionState(isConnecting: true);
    try {
      final repo = ref.read(queryRepositoryProvider);
      _repo = repo;
      final session = await repo.openSession(connectionId);
      _session = session;
      if (ref.mounted) {
        state = ConnectionSessionState(session: session);
      }
      return session;
    } catch (e) {
      if (ref.mounted) {
        state = ConnectionSessionState(error: e.toString());
      }
      return null;
    }
  }

  Future<void> disconnect() async {
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
