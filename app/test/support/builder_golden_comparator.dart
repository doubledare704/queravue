import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class BuilderGoldenComparator extends LocalFileComparator {
  BuilderGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    try {
      // Rasterization can differ slightly between macOS runners.
      if (result.passed || result.diffPercent <= 0.00005) {
        return true;
      }
      throw FlutterError(await generateFailureOutput(result, golden, basedir));
    } finally {
      result.dispose();
    }
  }
}

void useBuilderGoldenComparator() {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = BuilderGoldenComparator(
      current.basedir.resolve('builder_golden_test.dart'),
    );
    addTearDown(() => goldenFileComparator = current);
  }
}
