import 'dart:io';

import '../../connections/domain/cancellation.dart';
import '../domain/gridfs_models.dart';

Stream<List<int>> readGridFsFile(
  File file,
  CancellationToken cancel,
  void Function(int) progress,
) async* {
  final source = await file.open();
  var sent = 0;
  try {
    while (!cancel.isCancelled) {
      final chunk = await source.read(gridFsChunkBytes);
      if (chunk.isEmpty || cancel.isCancelled) break;
      yield chunk;
      sent += chunk.length;
      progress(sent);
    }
    if (cancel.isCancelled) throw const OperationCancelled();
  } finally {
    await source.close();
  }
}

Future<void> saveGridFsDownload(
  File destination,
  Stream<List<int>> bytes,
  CancellationToken cancel,
  void Function(int) progress,
) async {
  final staging = await destination.absolute.parent.createTemp(
    '.queravue-gridfs-',
  );
  final file = File('${staging.path}${Platform.pathSeparator}download');
  try {
    final output = await file.open(mode: FileMode.write);
    var written = 0;
    try {
      await for (final chunk in bytes) {
        if (cancel.isCancelled) throw const OperationCancelled();
        await output.writeFrom(chunk);
        written += chunk.length;
        progress(written);
      }
    } finally {
      await output.close();
    }
    if (cancel.isCancelled) throw const OperationCancelled();
    await file.rename(destination.absolute.path);
  } finally {
    await staging.delete(recursive: true);
  }
}
