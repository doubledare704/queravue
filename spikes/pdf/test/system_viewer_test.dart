import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_spike/system_viewer.dart';

void main() {
  test('sanitizePdfFileName strips paths and guarantees .pdf extension', () {
    expect(sanitizePdfFileName('report'), 'report.pdf');
    expect(sanitizePdfFileName('../secret/invoice.PDF'), 'invoice.PDF');
    expect(sanitizePdfFileName('a/b\\my file?.pdf'), 'my_file_.pdf');
    expect(sanitizePdfFileName('...hidden.pdf'), 'hidden.pdf');
    expect(sanitizePdfFileName('   '), 'preview.pdf');
  });

  test('SystemPdfViewer writes sanitized temp file and cleans up on dispose', () async {
    String? launchedPath;
    final viewer = SystemPdfViewer(
      launcher: (path, {required background}) async {
        launchedPath = path;
        return 0;
      },
    );
    final bytes = Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]);

    final result = await viewer.openBytes(bytes, suggestedName: '../doc');
    expect(result.exitCode, 0);
    expect(launchedPath, result.filePath);
    expect(result.filePath.endsWith('${Platform.pathSeparator}doc.pdf'), isTrue);
    expect(await File(result.filePath).readAsBytes(), bytes);

    final tempDirPath = viewer.tempDirPath!;
    expect(await Directory(tempDirPath).exists(), isTrue);

    await viewer.cleanup();
    expect(await File(result.filePath).exists(), isFalse);
    expect(await Directory(tempDirPath).exists(), isFalse);
  });
}
