import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../data/shell_repository.dart';
import '../domain/shell_models.dart';

/// Delay before the Cancel button shows for a running script.
const Duration kShellCancelDelay = Duration(milliseconds: 300);

/// Where a shell tab's run is.
enum ShellPhase { idle, connecting, running }

/// One line or block of the output pane.
sealed class OutputEntry {
  const OutputEntry();
}

/// Marks the start of a run.
final class OutputRun extends OutputEntry {
  const OutputRun(this.summary);
  final String summary;
}

final class OutputPrint extends OutputEntry {
  const OutputPrint(this.level, this.text);
  final PrintLevel level;
  final String text;
}

final class OutputValue extends OutputEntry {
  const OutputValue(this.kind, this.text, {this.writeOp = ''});
  final ValueKind kind;
  final String text;
  final String writeOp;
}

final class OutputCursor extends OutputEntry {
  const OutputCursor(this.handle);
  final CursorHandle handle;
}

/// A failure. [line] is absolute in the editor buffer (0 if unknown).
final class OutputError extends OutputEntry {
  const OutputError(this.failure, {this.line = 0, this.column = 0});
  final ShellFailure failure;
  final int line;
  final int column;
}

final class OutputDone extends OutputEntry {
  const OutputDone(this.duration);
  final Duration duration;
}

/// A gated operation waiting for the user's confirmation.
@immutable
class PendingConfirmation {
  const PendingConfirmation({
    required this.operation,
    required this.code,
    required this.lineOffset,
  });
  final String operation;
  final String code;
  final int lineOffset;
}

@immutable
class ShellTabState {
  const ShellTabState({
    this.phase = ShellPhase.idle,
    this.shellId,
    this.entries = const [],
    this.showCancel = false,
    this.pending,
    this.connectionError,
  });

  final ShellPhase phase;
  final String? shellId;
  final List<OutputEntry> entries;
  final bool showCancel;
  final PendingConfirmation? pending;
  final String? connectionError;

  bool get busy => phase != ShellPhase.idle;

  ShellTabState copyWith({
    ShellPhase? phase,
    String? shellId,
    List<OutputEntry>? entries,
    bool? showCancel,
    PendingConfirmation? pending,
    bool clearPending = false,
    String? connectionError,
    bool clearConnectionError = false,
  }) => ShellTabState(
    phase: phase ?? this.phase,
    shellId: shellId ?? this.shellId,
    entries: entries ?? this.entries,
    showCancel: showCancel ?? this.showCancel,
    pending: clearPending ? null : (pending ?? this.pending),
    connectionError: clearConnectionError
        ? null
        : (connectionError ?? this.connectionError),
  );
}

final shellTabProvider =
    NotifierProvider.family<ShellTabController, ShellTabState, String>(
      ShellTabController.new,
    );

/// Runs scripts of one shell tab and collects their output.
class ShellTabController extends Notifier<ShellTabState> {
  ShellTabController(this.tabId);

  final String tabId;

  StreamSubscription<ShellEvent>? _sub;
  Timer? _cancelTimer;
  String? _connectionId;

  // Not read from `state` in onDispose: provider state is off limits there.
  String? _shellId;
  int _epoch = 0;

  ShellRepository get _repo => ref.read(shellRepositoryProvider);

  @override
  ShellTabState build() {
    final tab = ref
        .read(editorTabsProvider)
        .tabs
        .where((t) => t.id == tabId)
        .firstOrNull;
    _connectionId = tab?.connectionId;
    ref.listen(
      editorTabsProvider.select((s) => s.tabs.any((t) => t.id == tabId)),
      (was, open) {
        if (was == true && !open) ref.invalidateSelf();
      },
    );
    final repo = ref.read(shellRepositoryProvider);
    ref.onDispose(() {
      _cancelTimer?.cancel();
      unawaited(_sub?.cancel());
      final id = _shellId;
      if (id != null) unawaited(repo.closeShell(id).catchError((_) {}));
    });
    return const ShellTabState();
  }

  /// Runs [code]. [lineOffset] is the buffer line [code] starts at, so error
  /// lines point into the editor. [confirmed] lets gated operations through.
  Future<void> run(
    String code, {
    int lineOffset = 0,
    bool confirmed = false,
  }) async {
    if (state.busy || code.trim().isEmpty) return;
    final epoch = ++_epoch;
    state = state.copyWith(
      phase: ShellPhase.connecting,
      showCancel: false,
      clearPending: true,
      clearConnectionError: true,
    );
    _armCancelButton(epoch);
    final shellId = await _ensureShell();
    if (shellId == null || epoch != _epoch || !ref.mounted) {
      _finish(epoch);
      return;
    }
    state = state.copyWith(
      phase: ShellPhase.running,
      entries: [...state.entries, OutputRun(_summary(code))],
    );
    final done = Completer<void>();
    _sub = _repo
        .eval(shellId, code, confirmed: confirmed)
        .listen(
          (e) => _onEvent(epoch, e, code, lineOffset),
          onError: (Object err) {
            _onTransportError(epoch, err);
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
    _finish(epoch);
  }

  void _armCancelButton(int epoch) {
    _cancelTimer?.cancel();
    _cancelTimer = Timer(kShellCancelDelay, () {
      if (ref.mounted && epoch == _epoch && state.busy) {
        state = state.copyWith(showCancel: true);
      }
    });
  }

  void _finish(int epoch) {
    if (!ref.mounted || epoch != _epoch) return;
    _cancelTimer?.cancel();
    _sub = null;
    state = state.copyWith(phase: ShellPhase.idle, showCancel: false);
  }

  Future<String?> _ensureShell() async {
    final existing = state.shellId;
    if (existing != null) return existing;
    final id = _connectionId;
    if (id == null) {
      _fail('The tab has no connection.');
      return null;
    }
    final session = await ref
        .read(connectionSessionProvider(id).notifier)
        .connect();
    if (!ref.mounted) return null;
    if (session == null) {
      _fail(ref.read(connectionSessionProvider(id)).error ?? 'Cannot connect.');
      return null;
    }
    if (!session.capabilities.contains('shell')) {
      _fail('This connection does not support the shell.');
      return null;
    }
    try {
      final shellId = await _repo.openShell(session.id, '');
      if (!ref.mounted) return null;
      _shellId = shellId;
      state = state.copyWith(shellId: shellId);
      return shellId;
    } catch (e) {
      _fail('Cannot start the shell: $e');
      return null;
    }
  }

  void _fail(String message) {
    if (ref.mounted) state = state.copyWith(connectionError: message);
  }

  void _onEvent(int epoch, ShellEvent e, String code, int lineOffset) {
    if (!ref.mounted || epoch != _epoch) return;
    final entries = [...state.entries];
    switch (e) {
      case ShellPrint():
        entries.add(OutputPrint(e.level, e.text));
      case ShellValue():
        entries.add(OutputValue(e.kind, e.text, writeOp: e.writeOp));
      case ShellCursorEvent():
        entries.add(OutputCursor(e.handle));
      case ShellDone():
        entries.add(OutputDone(e.duration));
      case ShellErrorEvent():
        final f = e.failure;
        if (f.needsConfirmation) {
          state = state.copyWith(
            entries: entries,
            pending: PendingConfirmation(
              operation: f.operation,
              code: code,
              lineOffset: lineOffset,
            ),
          );
          return;
        }
        entries.add(
          OutputError(
            f,
            line: f.line > 0 ? f.line - 1 + lineOffset : 0,
            column: f.column,
          ),
        );
    }
    state = state.copyWith(entries: entries);
  }

  void _onTransportError(int epoch, Object err) {
    if (!ref.mounted || epoch != _epoch) return;
    final message = err is GrpcError && err.code == StatusCode.notFound
        ? 'The shell was closed (its session ended). Run again to restart it.'
        : '$err';
    if (err is GrpcError && err.code == StatusCode.notFound) {
      _shellId = null;
      state = ShellTabState(entries: state.entries);
    }
    state = state.copyWith(
      entries: [
        ...state.entries,
        OutputError(
          ShellFailure(kind: ShellErrorKind.runtime, message: message),
        ),
      ],
    );
  }

  /// Runs the script again with the gated operation allowed.
  Future<void> confirmPending() async {
    final p = state.pending;
    if (p == null) return;
    await run(p.code, lineOffset: p.lineOffset, confirmed: true);
  }

  /// Drops the confirmation request without running anything.
  void dismissPending() {
    if (state.pending == null) return;
    state = state.copyWith(
      clearPending: true,
      entries: [
        ...state.entries,
        const OutputError(
          ShellFailure(
            kind: ShellErrorKind.canceled,
            message: 'Not confirmed; nothing was changed.',
          ),
        ),
      ],
    );
  }

  /// Interrupts the running script.
  Future<void> cancel() async {
    final id = state.shellId;
    if (id == null || !state.busy) return;
    await _repo.cancel(id);
  }

  void clear() => state = state.copyWith(entries: const []);

  String _summary(String code) {
    final first = code.trim().split('\n').first;
    final lines = code.trim().split('\n').length;
    final head = first.length > 80 ? '${first.substring(0, 80)}…' : first;
    return lines > 1 ? '$head  (+${lines - 1} lines)' : head;
  }
}
