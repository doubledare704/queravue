// This is a generated file - do not edit.
//
// Generated from queravue/v1/mockdata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mockdata.pb.dart' as $0;

export 'mockdata.pb.dart';

/// MockDataService generates realistic rows and documents and loads them
/// through the engine's bulk loader (ADR 0025).
///
/// Generation is deterministic for a seed, so a preview equals the first rows
/// of a run. Failures the user can act on are returned in-band as MockError.
/// Unknown sessions are NOT_FOUND and sessions without "bulk_load" or
/// "document_load" are FAILED_PRECONDITION.
@$pb.GrpcServiceName('queravue.v1.MockDataService')
class MockDataServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MockDataServiceClient(super.channel, {super.options, super.interceptors});

  /// SuggestMockSpec proposes rules for the given tables or collections from
  /// their columns or sampled field paths, orders tables by foreign keys and
  /// reports cycles.
  $grpc.ResponseFuture<$0.SuggestMockSpecResponse> suggestMockSpec(
    $0.SuggestMockSpecRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$suggestMockSpec, request, options: options);
  }

  /// PreviewMock generates the first rows of each target without writing.
  $grpc.ResponseFuture<$0.PreviewMockResponse> previewMock(
    $0.PreviewMockRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewMock, request, options: options);
  }

  /// RunMock generates and loads every target in order. Cancelling the call
  /// stops after the current batch; finished tables stay committed.
  $grpc.ResponseStream<$0.RunMockResponse> runMock(
    $0.RunMockRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$runMock, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$suggestMockSpec =
      $grpc.ClientMethod<$0.SuggestMockSpecRequest, $0.SuggestMockSpecResponse>(
          '/queravue.v1.MockDataService/SuggestMockSpec',
          ($0.SuggestMockSpecRequest value) => value.writeToBuffer(),
          $0.SuggestMockSpecResponse.fromBuffer);
  static final _$previewMock =
      $grpc.ClientMethod<$0.PreviewMockRequest, $0.PreviewMockResponse>(
          '/queravue.v1.MockDataService/PreviewMock',
          ($0.PreviewMockRequest value) => value.writeToBuffer(),
          $0.PreviewMockResponse.fromBuffer);
  static final _$runMock =
      $grpc.ClientMethod<$0.RunMockRequest, $0.RunMockResponse>(
          '/queravue.v1.MockDataService/RunMock',
          ($0.RunMockRequest value) => value.writeToBuffer(),
          $0.RunMockResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.MockDataService')
abstract class MockDataServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.MockDataService';

  MockDataServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SuggestMockSpecRequest,
            $0.SuggestMockSpecResponse>(
        'SuggestMockSpec',
        suggestMockSpec_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SuggestMockSpecRequest.fromBuffer(value),
        ($0.SuggestMockSpecResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PreviewMockRequest, $0.PreviewMockResponse>(
            'PreviewMock',
            previewMock_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PreviewMockRequest.fromBuffer(value),
            ($0.PreviewMockResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RunMockRequest, $0.RunMockResponse>(
        'RunMock',
        runMock_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.RunMockRequest.fromBuffer(value),
        ($0.RunMockResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SuggestMockSpecResponse> suggestMockSpec_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SuggestMockSpecRequest> $request) async {
    return suggestMockSpec($call, await $request);
  }

  $async.Future<$0.SuggestMockSpecResponse> suggestMockSpec(
      $grpc.ServiceCall call, $0.SuggestMockSpecRequest request);

  $async.Future<$0.PreviewMockResponse> previewMock_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PreviewMockRequest> $request) async {
    return previewMock($call, await $request);
  }

  $async.Future<$0.PreviewMockResponse> previewMock(
      $grpc.ServiceCall call, $0.PreviewMockRequest request);

  $async.Stream<$0.RunMockResponse> runMock_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RunMockRequest> $request) async* {
    yield* runMock($call, await $request);
  }

  $async.Stream<$0.RunMockResponse> runMock(
      $grpc.ServiceCall call, $0.RunMockRequest request);
}
