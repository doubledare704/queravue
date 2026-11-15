import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/gen/queravue/v1/keyvalue.pb.dart';
import 'package:queravue/features/keyvalue/application/key_scan_controller.dart';
import 'package:queravue/features/keyvalue/presentation/key_tree.dart';
import 'package:queravue/features/keyvalue/presentation/key_value_view.dart';

const _keyTreeSize = Size(420, 300);

class _KeyTreeGoldenComparator extends LocalFileComparator {
  _KeyTreeGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    try {
      // The macOS CI runner renders two pixels differently from the baseline.
      final tolerance = 2 / (_keyTreeSize.width * _keyTreeSize.height);
      if (result.passed || result.diffPercent <= tolerance) return true;
      throw FlutterError(await generateFailureOutput(result, golden, basedir));
    } finally {
      result.dispose();
    }
  }
}

void main() {
  final examples = <(ReadValueResponse, String)>[
    (
      ReadValueResponse(
        stringValue: StringValue(data: utf8.encode('plain text')),
      ),
      'plain text',
    ),
    (
      ReadValueResponse(stringValue: StringValue(data: [255, 0], binary: true)),
      '00000000  ff 00',
    ),
    (
      ReadValueResponse(
        hash: HashValues(
          entries: [
            HashEntry(field_1: utf8.encode('city'), value: utf8.encode('Kyiv')),
          ],
        ),
      ),
      'city',
    ),
    (
      ReadValueResponse(
        list: ListValues(startIndex: Int64(100), items: [utf8.encode('val')]),
      ),
      '100',
    ),
    (
      ReadValueResponse(set: SetValues(members: [utf8.encode('member')])),
      'member',
    ),
    (
      ReadValueResponse(
        zset: ZsetValues(
          entries: [ZsetEntry(member: utf8.encode('member'), score: 2.5)],
        ),
      ),
      '2.5',
    ),
    (
      ReadValueResponse(
        stream: StreamValues(entries: [StreamEntry(id: '1234-0')]),
      ),
      '1234-0',
    ),
    (ReadValueResponse(json: JsonValue(json: '{"name":"Ada"}')), 'name  "Ada"'),
    (
      ReadValueResponse(hyperloglog: HyperLogLogValue(count: Int64(19))),
      'Estimated cardinality · 19',
    ),
  ];
  for (final (page, text) in examples) {
    testWidgets('renders ${page.whichValue().name}: $text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyValueView(
              page: page,
              onEdit: (_) {},
              onRemove: (_) {},
              busy: false,
            ),
          ),
        ),
      );
      expect(find.text(text), findsOneWidget);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('key tree ${brightness.name} golden', (tester) async {
      final comparator = goldenFileComparator;
      if (comparator is LocalFileComparator) {
        goldenFileComparator = _KeyTreeGoldenComparator(
          comparator.basedir.resolve('key_value_views_test.dart'),
        );
        addTearDown(() => goldenFileComparator = comparator);
      }
      await tester.binding.setSurfaceSize(_keyTreeSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyInfoProvider.overrideWith(
              (ref, address) async => GetKeyInfoResponse(
                type: KeyType.KEY_TYPE_HASH,
                ttlMs: Int64(45000),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: KeyTree(
                scope: (
                  session: 'session',
                  database: 0,
                  pattern: '',
                  type: KeyType.KEY_TYPE_UNSPECIFIED,
                ),
                window: KeyScanWindow(
                  keys: [
                    KeySummary(key: utf8.encode('settings')),
                    KeySummary(key: utf8.encode('users:ada')),
                    KeySummary(key: utf8.encode('users:grace')),
                  ],
                ),
                selected: base64Encode(utf8.encode('users:ada')),
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('ada'), findsNothing);
      await tester.tap(find.text('users'));
      await tester.pumpAndSettle();
      expect(find.text('ada'), findsOneWidget);
      expect(find.text('hash · 45000 ms'), findsNWidgets(3));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/key_tree_${brightness.name}.png'),
      );
    });
  }
}
