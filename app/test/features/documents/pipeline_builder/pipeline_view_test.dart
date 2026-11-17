import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/pipeline_builder/presentation/pipeline_builder_view.dart';

import 'pipeline_harness.dart';

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= 0.005) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

const _typicalPipeline = r'''[
  { $match: { status: "A", age: { $gte: 18 } } },
  { $unwind: "$items" },
  { $group: { _id: "$items.sku", total: { $sum: "$items.qty" } } },
  { $lookup: { from: "products", localField: "_id", foreignField: "sku", as: "product" } },
  { $sort: { total: -1 } },
  { $project: { total: 1, product: 1 } },
  { $limit: 10 },
  { $facet: { a: [{ $count: "n" }] } },
  { oops: 1 }
]''';

Future<PipelineHarness> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  String? importText,
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = PipelineHarness();
  addTearDown(h.container.dispose);
  if (importText != null) h.controller.importText(importText);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: RepaintBoundary(
            key: Key('golden-root'),
            child: PipelineBuilderView(target: pipelineTarget),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUpAll(() {
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      goldenFileComparator = _TolerantComparator(
        Uri.parse('${current.basedir}pipeline_view_test.dart'),
      );
    }
  });

  testWidgets('shows an empty hint without stages', (tester) async {
    await _pump(tester);
    expect(find.textContaining('No stages yet'), findsOneWidget);
  });

  testWidgets('shows one card per stage, raw cards included', (tester) async {
    final h = await _pump(tester, importText: _typicalPipeline);
    expect(h.state.stages, hasLength(9));
    expect(find.byKey(const Key('stage-operator-0')), findsOneWidget);
    expect(h.state.stages.last.isUnparsed, isTrue);
    expect(find.byKey(const Key('pipeline-notice')), findsOneWidget);
  });

  testWidgets('the card list matches the golden (light)', (tester) async {
    await _pump(tester, importText: _typicalPipeline);
    await expectLater(
      find.byKey(const Key('golden-root')),
      matchesGoldenFile('goldens/pipeline_cards_light.png'),
    );
  });

  testWidgets('the card list matches the golden (dark)', (tester) async {
    await _pump(tester, theme: ThemeData.dark(), importText: _typicalPipeline);
    await expectLater(
      find.byKey(const Key('golden-root')),
      matchesGoldenFile('goldens/pipeline_cards_dark.png'),
    );
  });

  testWidgets('a typed form edits the stage body', (tester) async {
    final h = await _pump(tester, importText: r'[{ $limit: 5 }]');
    await tester.enterText(find.widgetWithText(TextFormField, '5'), '7');
    expect(h.state.stages.single.body, 7);
  });

  testWidgets('duplicate, disable and remove buttons work', (tester) async {
    final h = await _pump(tester, importText: r'[{ $limit: 5 }]');

    await tester.tap(find.byKey(const Key('stage-duplicate-0')));
    await tester.pumpAndSettle();
    expect(h.state.stages, hasLength(2));

    await tester.tap(find.byKey(const Key('stage-enabled-1')));
    await tester.pumpAndSettle();
    expect(h.state.stages[1].enabled, isFalse);

    await tester.tap(find.byKey(const Key('stage-remove-0')));
    await tester.pumpAndSettle();
    expect(h.state.stages, hasLength(1));
  });

  testWidgets('dragging a handle reorders the stages', (tester) async {
    final h = await _pump(
      tester,
      importText: r'[{ $limit: 1 }, { $skip: 2 }, { $count: "n" }]',
    );
    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 260));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      [for (final s in h.state.stages) s.operator].first,
      isNot(r'$limit'),
    );
  });

  testWidgets('the add menu adds a stage', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('add-stage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$group').last);
    await tester.pumpAndSettle();
    expect(h.state.stages.single.operator, r'$group');
    expect(find.text('Add accumulator'), findsOneWidget);
  });

  testWidgets('preview shows documents of the selected stage', (tester) async {
    final h = await _pump(tester, importText: r'[{ $match: {} }]');
    h.queueCursor();
    await tester.tap(find.byKey(const Key('stage-preview-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-list')), findsOneWidget);
    expect(find.textContaining('doc-1'), findsOneWidget);
  });

  testWidgets('the import dialog fills the list', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(const Key('import-pipeline')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('import-text')),
      r'db.orders.aggregate([{ $limit: 3 }])',
    );
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();
    expect(h.state.stages.single.body, 3);
  });
}
