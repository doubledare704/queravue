import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/core_client/gen/queravue/v1/querybuilder.pb.dart'
    as pb;
import 'package:queravue/core_client/query_builder_client.dart';
import 'package:queravue/features/documents/application/document_preview_controller.dart';
import 'package:queravue/features/documents/filter_builder/filter_builder_controller.dart';
import 'package:queravue/features/documents/presentation/doc_views.dart';
import 'package:queravue/features/documents/presentation/query_bar.dart';

import '../../../support/document_harness.dart';
import '../../../support/fake_document_repository.dart';

class _OfflineCore extends Fake implements CoreSupervisor {
  @override
  CoreConnection? get connection => null;
}

class FakeCall<T> extends Fake implements ResponseFuture<T> {
  FakeCall(this.value);
  final T value;

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      Future.value(value).then(onValue, onError: onError);
  @override
  Future<void> cancel() async {}
  @override
  Future<Map<String, String>> get headers async => {};
  @override
  Future<Map<String, String>> get trailers async => {};
}

class FakeClient extends QueryBuilderClient {
  FakeClient() : super(() => null);
  pb.QueryBuilderErrorKind? failure;
  @override
  ResponseFuture<pb.ParseMongoQueryResponse> parseMongoQuery(
    pb.ParseMongoQueryRequest request, {
    Duration timeout = const Duration(seconds: 15),
  }) => FakeCall(
    failure == null
        ? pb.ParseMongoQueryResponse(model: pb.MongoFindModel())
        : pb.ParseMongoQueryResponse(
            error: pb.QueryBuilderError(kind: failure, message: 'bad input'),
          ),
  );
  @override
  ResponseFuture<pb.GenerateMongoQueryResponse> generateMongoQuery(
    pb.GenerateMongoQueryRequest request, {
    Duration timeout = const Duration(seconds: 15),
  }) => FakeCall(pb.GenerateMongoQueryResponse(filterEjson: '{}'));
}

void main() {
  Future<void> openPreview(
    WidgetTester tester,
    FakeDocumentRepository docs,
  ) async {
    tester.view.physicalSize = const Size(1300, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        ...documentOverrides(docs),
        coreSupervisorProvider.overrideWithValue(_OfflineCore()),
        queryBuilderClientProvider.overrideWithValue(FakeClient()),
      ],
    );
    addTearDown(container.dispose);
    final id = openUsersTab(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: DocumentQueryBar(tabId: id)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('doc-filter')), '{"age":18}');
    await tester.enterText(
      find.byKey(const Key('doc-projection')),
      '{"name":1}',
    );
    await tester.enterText(find.byKey(const Key('doc-sort')), '{"age":-1}');
    await tester.enterText(find.byKey(const Key('doc-skip')), '2');
    await tester.tap(find.byTooltip('Visual filter builder'));
    await tester.pumpAndSettle();
  }

  const runKey = Key('preview-run');
  const cancelKey = Key('preview-cancel');

  testWidgets('filter preview runs a capped Find in its own document view', (
    tester,
  ) async {
    final docs = FakeDocumentRepository();
    await openPreview(tester, docs);
    final findsBeforePreview = docs.finds.length;
    await tester.tap(find.byKey(runKey));
    await tester.pumpAndSettle();

    expect(docs.finds, hasLength(findsBeforePreview + 1));
    final query = docs.finds.last;
    expect(query.limit, 20);
    expect(query.skip, 2);
    expect(query.filter, '{"age":18}');
    expect(query.projection, '{"name":1}');
    expect(query.sort, '{"age":-1}');
    expect(docs.findTimeouts.last, kPreviewMaxTimeMs);
    expect(docs.findTargets.last.database, 'shop');
    expect(docs.findTargets.last.collection, 'users');
    expect(
      tester.widget<DocJsonView>(find.byType(DocJsonView)).docs,
      hasLength(20),
    );
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(DocTableView), findsOneWidget);
  });

  testWidgets('filter preview replaces Run with Cancel at 300 ms', (
    tester,
  ) async {
    final docs = FakeDocumentRepository();
    await openPreview(tester, docs);
    final cancelledBeforePreview = docs.findCancelled;
    final hold = docs.holdFind = Completer<void>();
    await tester.tap(find.byKey(runKey));
    await tester.pump(const Duration(milliseconds: 299));
    expect(tester.widget<TextButton>(find.byKey(runKey)).onPressed, isNull);
    expect(find.byKey(cancelKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(runKey), findsNothing);
    await tester.tap(find.byKey(cancelKey));
    await tester.pumpAndSettle();
    expect(docs.findCancelled, cancelledBeforePreview + 1);
    expect(tester.widget<TextButton>(find.byKey(runKey)).onPressed, isNotNull);
    expect(find.byKey(const Key('doc-cancel')), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DocJsonView), findsNothing);
  });

  test('parses, generates and classifies actionable errors', () async {
    final client = FakeClient();
    final container = ProviderContainer(
      overrides: [queryBuilderClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    final controller = container.read(filterBuilderProvider('tab').notifier);
    await controller.open('{}', '', '', null, 'db', 'collection');
    expect(container.read(filterBuilderProvider('tab')).model, isNotNull);
    await controller.update(pb.MongoFindModel());
    expect(
      container.read(filterBuilderProvider('tab')).output!.filterEjson,
      '{}',
    );
    client.failure = pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_PARSE;
    await controller.parse('{', '', '');
    expect(container.read(filterBuilderProvider('tab')).cannotShow, isTrue);
    client.failure =
        pb.QueryBuilderErrorKind.QUERY_BUILDER_ERROR_KIND_INVALID_MODEL;
    await controller.parse('{}', '', '');
    expect(container.read(filterBuilderProvider('tab')).cannotShow, isFalse);
  });
}
