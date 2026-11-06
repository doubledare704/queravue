import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/documents/presentation/doc_views.dart';

/// Goldens render slightly differently across macOS versions, so allow a tiny
/// pixel difference (same approach as the result grid goldens).
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= tolerance) return true;
    if (!result.passed) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return true;
  }
}

/// One document with every kind of value the tree view badges.
const _doc =
    '{"_id":{"\$oid":"650000000000000000000001"},"name":"Ada Lovelace",'
    '"age":{"\$numberInt":"36"},"visits":{"\$numberLong":"9007199254740993"},'
    '"score":{"\$numberDouble":"98.5"},"balance":{"\$numberDecimal":"1234.5678"},'
    '"joined":{"\$date":{"\$numberLong":"1579084200000"}},'
    '"session":{"\$binary":{"base64":"D4+tW9nLRp+hZXCGdyiVDg==","subType":"04"}},'
    '"address":{"city":"London","geo":{"lat":{"\$numberDouble":"51.5"}}},'
    '"roles":["admin","dev"],"nickname":null,"active":true}';

const _second = '{"_id":"string-id-3","name":"Grace Hopper","roles":[]}';

void main() {
  setUpAll(() {
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      goldenFileComparator = _TolerantComparator(
        Uri.parse('${current.basedir}doc_tree_golden_test.dart'),
        tolerance: 0.005,
      );
    }
  });

  for (final b in Brightness.values) {
    testWidgets('golden: tree view, ${b.name} theme', (tester) async {
      tester.view.physicalSize = const Size(760, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: b,
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('golden'),
              child: DocTreeView(
                docs: [DocItem(_doc), DocItem(_second)],
                selected: const {1},
                initiallyExpanded: const {'0', '0/address', '0/roles'},
                onSelect: (_, {toggle = false}) {},
                onEdit: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Int64'), findsOneWidget);
      expect(find.text('Decimal128'), findsOneWidget);
      expect(find.text('UUID'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('golden')),
        matchesGoldenFile('goldens/doc_tree_${b.name}.png'),
      );
    });
  }
}
