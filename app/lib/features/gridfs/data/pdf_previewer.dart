import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class PdfPreviewer {
  Future<void> open(File pdf);
}

final pdfPreviewerProvider = Provider<PdfPreviewer>(
  (ref) => SystemPdfPreviewer(),
);

class SystemPdfPreviewer implements PdfPreviewer {
  @override
  Future<void> open(File pdf) async {
    final result = await (Platform.isMacOS
        ? Process.run('open', [pdf.path])
        : Platform.isWindows
        ? Process.run('rundll32.exe', [
            'url.dll,FileProtocolHandler',
            Uri.file(pdf.path, windows: true).toString(),
          ])
        : Process.run('xdg-open', [pdf.path]));
    if (result.exitCode != 0) {
      throw StateError('Could not open the system PDF viewer');
    }
  }
}
