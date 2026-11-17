import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'builder_golden_comparator.dart';

Future<Uint8List> imageWithChangedPixels(int changed) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, changed.toDouble(), 1),
    Paint()..color = Colors.black,
  );
  final image = await recorder.endRecording().toImage(1000, 1000);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  testWidgets('accepts small pixel differences and rejects larger ones', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'builder-golden-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final golden = File('${directory.path}/golden.png');
      await golden.writeAsBytes(await imageWithChangedPixels(0));
      final comparator = BuilderGoldenComparator(
        Uri.file('${directory.path}/test.dart'),
      );

      expect(
        await comparator.compare(
          await imageWithChangedPixels(20),
          Uri.parse('golden.png'),
        ),
        isTrue,
      );
      await expectLater(
        comparator.compare(
          await imageWithChangedPixels(60),
          Uri.parse('golden.png'),
        ),
        throwsFlutterError,
      );
    });
  });
}
