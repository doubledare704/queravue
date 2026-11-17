import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/querybuilder.pb.dart'
    as pb;
import 'package:queravue/core_client/query_builder_client.dart';
import 'package:queravue/features/documents/filter_builder/filter_builder_controller.dart';

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
