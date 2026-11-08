// This is a generated file - do not edit.
//
// Generated from queravue/v1/completion.proto.

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

import 'completion.pb.dart' as $0;

export 'completion.pb.dart';

/// CompletionService answers editor completion and formatting requests (ADR 0015).
/// The UI enables it from the "completion" and "format" capabilities and never
/// from engine ids.
///
/// Failures are returned in-band as AdminError so streams and transport stay
/// healthy. Unknown sessions are NOT_FOUND.
@$pb.GrpcServiceName('queravue.v1.CompletionService')
class CompletionServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CompletionServiceClient(super.channel, {super.options, super.interceptors});

  /// Complete returns ranked candidates for the cursor position. It answers
  /// from the cached catalog and never waits for WarmCatalog. Cancel the call
  /// when the user types again.
  $grpc.ResponseFuture<$0.CompleteResponse> complete(
    $0.CompleteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$complete, request, options: options);
  }

  /// WarmCatalog loads all columns of a database in the background with one
  /// query per schema and streams progress. The last message has done=true.
  /// Calls for the same database share one load. Cancelling the last call
  /// stops a load that no automatic warm-up started; the core also starts one
  /// when a session opens, and that one only stops when the session closes or
  /// its schema changes.
  $grpc.ResponseStream<$0.WarmCatalogResponse> warmCatalog(
    $0.WarmCatalogRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$warmCatalog, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// FormatSQL formats SQL text or a range of it. Unknown syntax is returned
  /// unchanged.
  $grpc.ResponseFuture<$0.FormatSQLResponse> formatSQL(
    $0.FormatSQLRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$formatSQL, request, options: options);
  }

  // method descriptors

  static final _$complete =
      $grpc.ClientMethod<$0.CompleteRequest, $0.CompleteResponse>(
          '/queravue.v1.CompletionService/Complete',
          ($0.CompleteRequest value) => value.writeToBuffer(),
          $0.CompleteResponse.fromBuffer);
  static final _$warmCatalog =
      $grpc.ClientMethod<$0.WarmCatalogRequest, $0.WarmCatalogResponse>(
          '/queravue.v1.CompletionService/WarmCatalog',
          ($0.WarmCatalogRequest value) => value.writeToBuffer(),
          $0.WarmCatalogResponse.fromBuffer);
  static final _$formatSQL =
      $grpc.ClientMethod<$0.FormatSQLRequest, $0.FormatSQLResponse>(
          '/queravue.v1.CompletionService/FormatSQL',
          ($0.FormatSQLRequest value) => value.writeToBuffer(),
          $0.FormatSQLResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.CompletionService')
abstract class CompletionServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.CompletionService';

  CompletionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CompleteRequest, $0.CompleteResponse>(
        'Complete',
        complete_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CompleteRequest.fromBuffer(value),
        ($0.CompleteResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WarmCatalogRequest, $0.WarmCatalogResponse>(
            'WarmCatalog',
            warmCatalog_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WarmCatalogRequest.fromBuffer(value),
            ($0.WarmCatalogResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FormatSQLRequest, $0.FormatSQLResponse>(
        'FormatSQL',
        formatSQL_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FormatSQLRequest.fromBuffer(value),
        ($0.FormatSQLResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CompleteResponse> complete_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CompleteRequest> $request) async {
    return complete($call, await $request);
  }

  $async.Future<$0.CompleteResponse> complete(
      $grpc.ServiceCall call, $0.CompleteRequest request);

  $async.Stream<$0.WarmCatalogResponse> warmCatalog_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WarmCatalogRequest> $request) async* {
    yield* warmCatalog($call, await $request);
  }

  $async.Stream<$0.WarmCatalogResponse> warmCatalog(
      $grpc.ServiceCall call, $0.WarmCatalogRequest request);

  $async.Future<$0.FormatSQLResponse> formatSQL_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FormatSQLRequest> $request) async {
    return formatSQL($call, await $request);
  }

  $async.Future<$0.FormatSQLResponse> formatSQL(
      $grpc.ServiceCall call, $0.FormatSQLRequest request);
}
