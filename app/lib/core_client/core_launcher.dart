import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// A running core sidecar process.
abstract interface class CoreHandle {
  /// OS process id, for diagnostics and tests.
  int get pid;

  /// Unix socket the core listens on.
  String get socketPath;

  /// Per-launch auth token the core expects in every request.
  String get token;

  /// Completes with the exit code when the process ends.
  Future<int> get exitCode;

  /// Kills the process immediately and removes its socket directory.
  Future<void> kill();

  /// Asks the core to stop (SIGTERM), then kills it after [timeout].
  Future<void> shutdown({Duration timeout});
}

/// Starts core sidecar processes.
abstract interface class CoreLauncher {
  /// Starts a core and returns once its socket accepts connections.
  Future<CoreHandle> launch();
}

/// Thrown when the core cannot be started.
class CoreLaunchException implements Exception {
  CoreLaunchException(this.message);

  final String message;

  @override
  String toString() => 'CoreLaunchException: $message';
}

/// Launches the real `queravued` binary.
///
/// The binary is looked up in `$QUERAVUE_CORE_BIN`, then next to the app
/// executable (`Queravue.app/Contents/MacOS/queravued`, copied there by the
/// "Embed queravued" Xcode build phase).
class ProcessCoreLauncher implements CoreLauncher {
  ProcessCoreLauncher({
    this._binaryPath,
    this.readyTimeout = const Duration(seconds: 5),
  });

  final String? _binaryPath;

  /// How long to wait for the socket to appear after spawning.
  final Duration readyTimeout;

  static final _random = Random.secure();

  /// Prefix of the per-launch socket directories under the system temp dir.
  static const socketDirPrefix = 'queravue-';

  bool _swept = false;

  /// Resolves the core binary path.
  String resolveBinary() {
    final override = _binaryPath ?? Platform.environment['QUERAVUE_CORE_BIN'];
    if (override != null && override.isNotEmpty) return override;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir/queravued';
  }

  @override
  Future<CoreHandle> launch() async {
    final binary = resolveBinary();
    if (!File(binary).existsSync()) {
      throw CoreLaunchException('core binary not found at $binary');
    }
    // $TMPDIR is per-user on macOS; keep the path well under the 104-byte
    // sun_path limit.
    if (!_swept) {
      _swept = true;
      await sweepStaleSocketDirs(Directory.systemTemp);
    }
    final dir = await Directory.systemTemp.createTemp(socketDirPrefix);
    final socketPath = '${dir.path}/core.sock';
    final token = _newToken();

    final Process process;
    try {
      process = await Process.start(
        binary,
        ['--socket', socketPath, '--exit-on-stdin-eof'],
        // Token goes through the environment so it never shows up in `ps`.
        environment: {'QUERAVUE_TOKEN': token},
      );
    } on ProcessException catch (e) {
      await _deleteDir(dir);
      throw CoreLaunchException('spawn $binary: ${e.message}');
    }

    final handle = _ProcessCoreHandle(process, dir, socketPath, token);
    try {
      await _waitForSocket(socketPath, handle.exitCode);
    } catch (_) {
      await handle.kill();
      rethrow;
    }
    return handle;
  }

  Future<void> _waitForSocket(String path, Future<int> exited) async {
    var exitCode = -1;
    var hasExited = false;
    unawaited(
      exited.then((code) {
        exitCode = code;
        hasExited = true;
      }),
    );
    final deadline = DateTime.now().add(readyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (hasExited) {
        throw CoreLaunchException(
          'core exited during startup (code $exitCode)',
        );
      }
      if (FileSystemEntity.typeSync(path) ==
          FileSystemEntityType.unixDomainSock) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw CoreLaunchException(
      'core did not open its socket within $readyTimeout',
    );
  }

  static String _newToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

class _ProcessCoreHandle implements CoreHandle {
  _ProcessCoreHandle(this._process, this._dir, this.socketPath, this.token) {
    // Core logs are structured JSON on stderr and never include secrets.
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => debugPrint('[core] $line'));
    _process.stdout.drain<void>();
    // stdin stays open: the core exits when it reaches EOF, so it follows
    // the app if the app dies without cleaning up.
  }

  final Process _process;
  final Directory _dir;

  @override
  final String socketPath;

  @override
  final String token;

  @override
  int get pid => _process.pid;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> kill() async {
    _process.kill(ProcessSignal.sigkill);
    await _process.exitCode.timeout(
      const Duration(seconds: 2),
      onTimeout: () => -1,
    );
    await _deleteDir(_dir);
  }

  @override
  Future<void> shutdown({Duration timeout = const Duration(seconds: 3)}) async {
    _process.kill(ProcessSignal.sigterm);
    try {
      await _process.exitCode.timeout(timeout);
      await _deleteDir(_dir);
    } on TimeoutException {
      await kill();
    }
  }
}

/// Deletes socket directories left behind when a core or the app was killed.
///
/// A directory is stale when it is older than [minAge] and no core accepts
/// connections on its socket. The age check protects a directory another app
/// instance has just created.
@visibleForTesting
Future<int> sweepStaleSocketDirs(
  Directory parent, {
  Duration minAge = const Duration(minutes: 1),
}) async {
  var removed = 0;
  final List<FileSystemEntity> entries;
  try {
    entries = await parent.list(followLinks: false).toList();
  } on FileSystemException {
    return 0;
  }
  for (final entry in entries) {
    if (entry is! Directory) continue;
    final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (!name.startsWith(ProcessCoreLauncher.socketDirPrefix)) continue;
    try {
      final age = DateTime.now().difference((await entry.stat()).modified);
      if (age < minAge) continue;
      if (await _socketIsLive('${entry.path}/core.sock')) continue;
      await entry.delete(recursive: true);
      removed++;
    } on FileSystemException {
      // Raced with another cleanup, or not ours to delete; skip.
    }
  }
  return removed;
}

Future<bool> _socketIsLive(String path) async {
  if (FileSystemEntity.typeSync(path) != FileSystemEntityType.unixDomainSock) {
    return false;
  }
  try {
    final socket = await Socket.connect(
      InternetAddress(path, type: InternetAddressType.unix),
      0,
      timeout: const Duration(milliseconds: 300),
    );
    socket.destroy();
    return true;
  } on SocketException {
    return false;
  }
}

Future<void> _deleteDir(Directory dir) async {
  try {
    await dir.delete(recursive: true);
  } on FileSystemException {
    // Already gone.
  }
}
