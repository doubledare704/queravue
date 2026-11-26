import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final gridFsPreviewFilesProvider = Provider<GridFsPreviewFiles>((ref) {
  final files = GridFsPreviewFiles();
  ref.onDispose(() => unawaited(files.dispose()));
  return files;
});

class GridFsPreviewFiles {
  final _directories = <String, Directory>{};

  Future<File> create(String name) async {
    final directory = await Directory.systemTemp.createTemp(
      'queravue-gridfs-preview-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    _directories[file.path] = directory;
    return file;
  }

  Future<void> delete(File file) async {
    final directory = _directories.remove(file.path);
    if (directory != null) await _deleteDirectory(directory);
  }

  Future<void> dispose() async {
    final pending = _directories.values.map(_deleteDirectory).toList();
    _directories.clear();
    await Future.wait(pending);
  }

  Future<void> _deleteDirectory(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // A system viewer may still have the file open.
    }
  }
}
