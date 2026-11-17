import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/gen/queravue/v1/querybuilder.pb.dart'
    as pb;
import 'package:queravue/features/documents/filter_builder/filter_builder_controller.dart';
import 'package:queravue/features/documents/presentation/query_bar.dart';

import '../../../support/document_harness.dart';
import '../../../support/fake_document_repository.dart';

class SyncBuilder extends FilterBuilderController {
  SyncBuilder() : super('tab-1');
  String? parsed;
  pb.MongoFindModel makeModel(String path) => pb.MongoFindModel(
    filter: pb.MongoCondition(
      field_1: pb.MongoFieldCondition(
        path: path,
        op: pb.MongoOperator.MONGO_OPERATOR_EQ,
        valueEjson: '1',
      ),
    ),
  );
  @override
  FilterBuilderState build() =>
      FilterBuilderState(open: true, model: makeModel('age'));
  @override
  Future<void> parse(String filter, String projection, String sort) async {
    parsed = filter;
    state = FilterBuilderState(
      open: true,
      model: makeModel('status'),
      revision: state.revision + 1,
    );
  }

  @override
  Future<void> update(
    pb.MongoFindModel model, {
    bool resetFields = false,
  }) async {
    state = FilterBuilderState(
      open: true,
      model: model,
      output: pb.GenerateMongoQueryResponse(filterEjson: '{"visual":1}'),
    );
  }
}

void main() {
  testWidgets('query bar and visual edits update each other', (tester) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ProviderContainer(
      overrides: [
        ...documentOverrides(FakeDocumentRepository()),
        filterBuilderProvider('tab-1').overrideWith(SyncBuilder.new),
      ],
    );
    addTearDown(c.dispose);
    final id = openUsersTab(c);
    expect(id, 'tab-1');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(body: DocumentQueryBar(tabId: 'tab-1')),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('doc-filter')), '{"status":1}');
    await tester.pump();
    expect(
      (c.read(filterBuilderProvider(id).notifier) as SyncBuilder).parsed,
      '{"status":1}',
    );
    expect(find.text('status'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('1path[]')), 'visual');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('doc-filter')))
          .controller!
          .text,
      '{"visual":1}',
    );
  });
}
