import 'dart:io';
import 'dart:typed_data';

String sanitizePdfFileName(String rawName) {
  final base = rawName.split(RegExp(r'[\\/]')).last.trim();
  final cleaned = base
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
      .replaceFirst(RegExp(r'^\.+'), '');
  final stem = cleaned.isEmpty ? 'preview' : cleaned;
  final withExt = stem.toLowerCase().endsWith('.pdf') ? stem : '$stem.pdf';
  if (withExt.length <= 120) return withExt;
  return '${withExt.substring(0, 116)}.pdf';
}

class SystemPdfLaunchResult {
  const SystemPdfLaunchResult({
    required this.filePath,
    required this.writeDuration,
    required this.launchDuration,
    required this.exitCode,
  });

  final String filePath;
  final Duration writeDuration;
  final Duration launchDuration;
  final int exitCode;
}

typedef ViewerLauncher = Future<int> Function(
  String filePath, {
  required bool background,
});

class SystemPdfViewer {
  SystemPdfViewer({this.launcher});

  final ViewerLauncher? launcher;
  Directory? _tempDir;
  final List<File> _createdFiles = <File>[];

  String? get tempDirPath => _tempDir?.path;

  Future<SystemPdfLaunchResult> openBytes(
    Uint8List bytes, {
    required String suggestedName,
    bool background = false,
  }) async {
    final dir = await _ensureTempDir();
    final safeName = sanitizePdfFileName(suggestedName);
    final file = File('${dir.path}${Platform.pathSeparator}$safeName');

    final writeWatch = Stopwatch()..start();
    await file.writeAsBytes(bytes, flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['0600', file.path]);
    }
    writeWatch.stop();
    _createdFiles.add(file);

    final launchWatch = Stopwatch()..start();
    final exitCode = await (launcher?.call(file.path, background: background) ??
        _launchOsViewer(file.path, background: background));
    launchWatch.stop();

    return SystemPdfLaunchResult(
      filePath: file.path,
      writeDuration: writeWatch.elapsed,
      launchDuration: launchWatch.elapsed,
      exitCode: exitCode,
    );
  }

  Future<void> cleanup() async {
    for (final file in _createdFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _createdFiles.clear();

    final dir = _tempDir;
    _tempDir = null;
    if (dir != null) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<Directory> _ensureTempDir() async {
    final existing = _tempDir;
    if (existing != null && await existing.exists()) {
      return existing;
    }
    final created = await Directory.systemTemp.createTemp('queravue_pdf_preview_');
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['0700', created.path]);
    }
    _tempDir = created;
    return created;
  }

  Future<int> _launchOsViewer(String filePath, {required bool background}) async {
    if (Platform.isMacOS) {
      final args = <String>[if (background) '-g', filePath];
      final result = await Process.run('/usr/bin/open', args);
      return result.exitCode;
    }
    if (Platform.isWindows) {
      final result = await Process.run('cmd', <String>['/c', 'start', '', filePath]);
      return result.exitCode;
    }
    if (Platform.isLinux) {
      final process = await Process.start(
        'xdg-open',
        <String>[filePath],
        mode: ProcessStartMode.detached,
      );
      return process.pid > 0 ? 0 : 1;
    }
    throw UnsupportedError('Unsupported desktop OS: ${Platform.operatingSystem}');
  }
}
