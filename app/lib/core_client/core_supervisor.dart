import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core_connection.dart';
import 'core_launcher.dart';

/// Lifecycle state of the core sidecar as seen by the UI.
sealed class CoreStatus {
  const CoreStatus();
}

/// First launch in progress.
final class CoreStarting extends CoreStatus {
  const CoreStarting();
}

/// Core is up and answered Hello.
final class CoreConnected extends CoreStatus {
  const CoreConnected(this.info);

  final CoreInfo info;
}

/// Core died or could not start; a restart is scheduled.
final class CoreReconnecting extends CoreStatus {
  const CoreReconnecting({required this.attempt, required this.reason});

  /// Consecutive failed attempt number, starting at 1.
  final int attempt;

  /// Why the previous core was lost. For logs and tooltips only.
  final String reason;
}

/// Delay before restart [attempt] (1-based): [initial] doubled per attempt,
/// capped at [max].
Duration backoffDelay(
  int attempt, {
  Duration initial = const Duration(milliseconds: 250),
  Duration max = const Duration(seconds: 5),
}) {
  final shift = (attempt - 1).clamp(0, 20);
  final ms = initial.inMilliseconds * (1 << shift);
  return Duration(
    milliseconds: ms > max.inMilliseconds ? max.inMilliseconds : ms,
  );
}

/// Launches the core, keeps it connected and restarts it with backoff
/// whenever it dies, stops answering heartbeats or fails to start.
class CoreSupervisor {
  CoreSupervisor({
    required this._launcher,
    required this._connector,
    this.heartbeatInterval = const Duration(seconds: 1),
    this.heartbeatTimeout = const Duration(seconds: 3),
    this.stableAfter = const Duration(seconds: 10),
    this.backoff = backoffDelay,
  });

  final CoreLauncher _launcher;
  final CoreConnector _connector;

  /// Heartbeat interval requested from the core.
  final Duration heartbeatInterval;

  /// A core silent for this long is considered hung and is killed.
  final Duration heartbeatTimeout;

  /// Uptime after which the backoff counter resets.
  final Duration stableAfter;

  /// Upper bound for closing a connection during teardown.
  static const closeTimeout = Duration(seconds: 1);

  /// Restart delay for a given attempt number.
  final Duration Function(int attempt) backoff;

  final _statusController = StreamController<CoreStatus>.broadcast();
  CoreStatus _status = const CoreStarting();
  CoreHandle? _handle;
  CoreConnection? _connection;
  bool _started = false;
  bool _disposed = false;
  final _stop = Completer<void>();
  Future<void>? _loop;

  /// Current status.
  CoreStatus get status => _status;

  /// Status changes.
  Stream<CoreStatus> get statusChanges => _statusController.stream;

  /// PID of the current core process, if one is running.
  int? get corePid => _handle?.pid;

  /// Connection to the current core, while connected.
  CoreConnection? get connection =>
      _status is CoreConnected ? _connection : null;

  /// Starts supervising. Safe to call more than once.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _loop = _run();
  }

  /// Stops supervising and shuts the core down gracefully.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stop.complete();
    await _loop;
    await _statusController.close();
  }

  void _emit(CoreStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> _run() async {
    var attempt = 0;
    while (!_disposed) {
      DateTime? connectedAt;
      String reason;
      try {
        final handle = _handle = await _launcher.launch();
        if (_disposed) break;
        final conn = _connection = await _connector(handle);
        final info = await conn.hello();
        if (_disposed) break;
        connectedAt = DateTime.now();
        _emit(CoreConnected(info));
        reason = await _watch(handle, conn);
      } catch (e) {
        reason = e.toString();
      }
      if (_disposed) break;
      debugPrint('core lost: $reason');
      await _teardown(graceful: false);

      if (connectedAt != null &&
          DateTime.now().difference(connectedAt) >= stableAfter) {
        attempt = 0;
      }
      attempt++;
      _emit(CoreReconnecting(attempt: attempt, reason: reason));
      final wake = Completer<void>();
      final timer = Timer(backoff(attempt), wake.complete);
      await Future.any([wake.future, _stop.future]);
      timer.cancel();
    }
    await _teardown(graceful: true);
  }

  /// Completes with a reason once the core is gone or unresponsive.
  Future<String> _watch(CoreHandle handle, CoreConnection conn) {
    final lost = Completer<String>();
    void finish(String reason) {
      if (!lost.isCompleted) lost.complete(reason);
    }

    Timer? watchdog;
    void armWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(
        heartbeatTimeout,
        () => finish('no heartbeat for $heartbeatTimeout'),
      );
    }

    armWatchdog();
    final sub = conn
        .health(intervalMs: heartbeatInterval.inMilliseconds)
        .listen(
          (beat) {
            if (beat.status == HealthStatus.HEALTH_STATUS_SERVING) {
              armWatchdog();
            }
          },
          onError: (Object e) => finish('health stream error: $e'),
          onDone: () => finish('health stream ended'),
          cancelOnError: true,
        );
    unawaited(
      handle.exitCode.then((code) => finish('core exited with code $code')),
    );
    unawaited(_stop.future.then((_) => finish('stopping')));

    return lost.future.whenComplete(() {
      watchdog?.cancel();
      unawaited(sub.cancel());
    });
  }

  Future<void> _teardown({required bool graceful}) async {
    final conn = _connection;
    final handle = _handle;
    _connection = null;
    _handle = null;
    if (handle != null) {
      if (graceful) {
        await handle.shutdown();
      } else {
        await handle.kill();
      }
    }
    // Closing a channel whose peer died mid-stream can hang in grpc-dart,
    // so never let it block a restart.
    try {
      await conn?.close().timeout(closeTimeout);
    } on TimeoutException {
      debugPrint('core channel close timed out; abandoning it');
    } catch (_) {
      // Channel already broken.
    }
  }
}
