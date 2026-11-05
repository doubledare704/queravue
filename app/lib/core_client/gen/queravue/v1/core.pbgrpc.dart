// This is a generated file - do not edit.
//
// Generated from queravue/v1/core.proto.

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

import 'core.pb.dart' as $0;

export 'core.pb.dart';

/// CoreService covers the core sidecar's own lifecycle: handshake and liveness.
@$pb.GrpcServiceName('queravue.v1.CoreService')
class CoreServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CoreServiceClient(super.channel, {super.options, super.interceptors});

  /// Hello is the handshake the UI sends after connecting. It returns the core
  /// version and the features this core supports.
  $grpc.ResponseFuture<$0.HelloResponse> hello(
    $0.HelloRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$hello, request, options: options);
  }

  /// Health streams heartbeats until the client cancels. The UI treats a broken
  /// stream or missing heartbeats as a dead core and restarts it.
  $grpc.ResponseStream<$0.HealthResponse> health(
    $0.HealthRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$health, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$hello = $grpc.ClientMethod<$0.HelloRequest, $0.HelloResponse>(
      '/queravue.v1.CoreService/Hello',
      ($0.HelloRequest value) => value.writeToBuffer(),
      $0.HelloResponse.fromBuffer);
  static final _$health =
      $grpc.ClientMethod<$0.HealthRequest, $0.HealthResponse>(
          '/queravue.v1.CoreService/Health',
          ($0.HealthRequest value) => value.writeToBuffer(),
          $0.HealthResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.CoreService')
abstract class CoreServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.CoreService';

  CoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.HelloRequest, $0.HelloResponse>(
        'Hello',
        hello_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HelloRequest.fromBuffer(value),
        ($0.HelloResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HealthRequest, $0.HealthResponse>(
        'Health',
        health_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.HealthRequest.fromBuffer(value),
        ($0.HealthResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.HelloResponse> hello_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.HelloRequest> $request) async {
    return hello($call, await $request);
  }

  $async.Future<$0.HelloResponse> hello(
      $grpc.ServiceCall call, $0.HelloRequest request);

  $async.Stream<$0.HealthResponse> health_Pre($grpc.ServiceCall $call,
      $async.Future<$0.HealthRequest> $request) async* {
    yield* health($call, await $request);
  }

  $async.Stream<$0.HealthResponse> health(
      $grpc.ServiceCall call, $0.HealthRequest request);
}
