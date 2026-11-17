import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/gen/queravue/v1/querybuilder.pb.dart'
    as pb;
import 'package:queravue/features/documents/filter_builder/filter_builder_controller.dart';
import 'package:queravue/features/documents/filter_builder/filter_builder_view.dart';

import '../../../support/builder_golden_comparator.dart';

class FakeBuilder extends FilterBuilderController {
  FakeBuilder() : super('tab');
  @override
  FilterBuilderState build() => FilterBuilderState(
    open: true,
    model: pb.MongoFindModel(
      filter: pb.MongoCondition(
        group: pb.MongoConditionGroup(
          op: pb.MongoBoolOp.MONGO_BOOL_OP_AND,
          children: [
            pb.MongoCondition(
              field_1: pb.MongoFieldCondition(
                path: 'age',
                op: pb.MongoOperator.MONGO_OPERATOR_GT,
                valueEjson: '18',
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Future<void> update(
    pb.MongoFindModel model, {
    bool resetFields = false,
  }) async {
    state = FilterBuilderState(
      open: true,
      model: model,
      revision: resetFields ? state.revision + 1 : state.revision,
    );
  }
}

void main() {
  Future<void> pumpBuilder(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [filterBuilderProvider('tab').overrideWith(FakeBuilder.new)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FilterBuilderView(tabId: 'tab')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adds and removes conditions', (tester) async {
    await pumpBuilder(tester);
    expect(find.text('age'), findsOneWidget);
    await tester.tap(find.text('Add condition'));
    await tester.pump();
    expect(find.text('field'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(find.text('age'), findsNothing);
  });
  testWidgets('condition tree golden', (tester) async {
    useBuilderGoldenComparator();
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpBuilder(tester);
    await expectLater(
      find.byType(FilterBuilderView),
      matchesGoldenFile('goldens/filter_tree.png'),
    );
  });
}
