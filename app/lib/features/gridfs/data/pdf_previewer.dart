import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class PdfPreviewer {
  Future<void> open(Uint8List bytes);

  Future<void> dispose();
}

final pdfPreviewerProvider = Provider<PdfPreviewer>((ref) {
  final previewer = SystemPdfPreviewer();
  ref.onDispose(() => unawaited(previewer.dispose()));
  return previewer;
});

class SystemPdfPreviewer implements PdfPreviewer {
  final _files = <Directory>{};
  var _disposed = false;

  @override
  Future<void> open(Uint8List bytes) async {
    if (_disposed) return;
    final directory = await Directory.systemTemp.createTemp(
      'queravue-gridfs-pdf-',
    );
    try {
      final file = File(
        '${directory.path}${Platform.pathSeparator}preview.pdf',
      );
      await file.writeAsBytes(bytes);
      if (_disposed) {
        await _delete(directory);
        return;
      }
      final result = await (Platform.isMacOS
          ? Process.run('open', [file.path])
          : Platform.isWindows
          ? Process.run('rundll32.exe', [
              'url.dll,FileProtocolHandler',
              Uri.file(file.path, windows: true).toString(),
            ])
          : Process.run('xdg-open', [file.path]));
      if (result.exitCode != 0) {
        throw StateError('Could not open the system PDF viewer');
      }
      if (_disposed) {
        await _delete(directory);
      } else {
        _files.add(directory);
      }
    } on Object {
      await _delete(directory);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final pending = _files.map(_delete).toList();
    _files.clear();
    await Future.wait(pending);
  }

  Future<void> _delete(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // A system viewer may still have the PDF open.
    }
  }
}
