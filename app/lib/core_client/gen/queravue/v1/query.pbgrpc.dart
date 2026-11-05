// This is a generated file - do not edit.
//
// Generated from queravue/v1/query.proto.

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

import 'query.pb.dart' as $0;

export 'query.pb.dart';

/// QueryService runs statements on a session and serves their results.
///
/// Every statement gets a result_id. Its rows are spooled to disk by the core
/// in pages, so Execute only streams the first window of rows; the UI reads
/// the rest with FetchRows and CopyRange. Results live until CloseResult or
/// until their session closes.
@$pb.GrpcServiceName('queravue.v1.QueryService')
class QueryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  QueryServiceClient(super.channel, {super.options, super.interceptors});

  /// Execute splits `text` into statements according to `mode`, runs them one
  /// after another on the session and streams events: the plan, then for each
  /// statement StatementStarted, Columns, the first window of Rows, Progress
  /// updates and a Summary. Execution stops at the first failing statement
  /// (an Error event). Rows past the first window are never sent on this
  /// stream. Cancelling the call cancels the running statement.
  /// FAILED_PRECONDITION if the session is already running a statement.
  $grpc.ResponseStream<$0.ExecuteResponse> execute(
    $0.ExecuteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$execute, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// FetchRows returns rows [offset, offset+limit) of a spooled result. It
  /// may return fewer rows if the result is shorter or still being spooled.
  /// NOT_FOUND if the result is unknown or closed.
  $grpc.ResponseFuture<$0.FetchRowsResponse> fetchRows(
    $0.FetchRowsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$fetchRows, request, options: options);
  }

  /// Cancel stops the statement currently running on a session, on the server
  /// as well as in the core. Succeeds if nothing is running.
  $grpc.ResponseFuture<$0.CancelResponse> cancel(
    $0.CancelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancel, request, options: options);
  }

  /// CloseResult discards a result and deletes its spool file. Closing an
  /// unknown result succeeds.
  $grpc.ResponseFuture<$0.CloseResultResponse> closeResult(
    $0.CloseResultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeResult, request, options: options);
  }

  /// CopyRange formats a row range of a result as text and streams it in
  /// chunks, so large copies never load the range into memory. Honours
  /// cancellation. NOT_FOUND if the result is unknown or closed.
  $grpc.ResponseStream<$0.CopyRangeResponse> copyRange(
    $0.CopyRangeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$copyRange, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$execute =
      $grpc.ClientMethod<$0.ExecuteRequest, $0.ExecuteResponse>(
          '/queravue.v1.QueryService/Execute',
          ($0.ExecuteRequest value) => value.writeToBuffer(),
          $0.ExecuteResponse.fromBuffer);
  static final _$fetchRows =
      $grpc.ClientMethod<$0.FetchRowsRequest, $0.FetchRowsResponse>(
          '/queravue.v1.QueryService/FetchRows',
          ($0.FetchRowsRequest value) => value.writeToBuffer(),
          $0.FetchRowsResponse.fromBuffer);
  static final _$cancel =
      $grpc.ClientMethod<$0.CancelRequest, $0.CancelResponse>(
          '/queravue.v1.QueryService/Cancel',
          ($0.CancelRequest value) => value.writeToBuffer(),
          $0.CancelResponse.fromBuffer);
  static final _$closeResult =
      $grpc.ClientMethod<$0.CloseResultRequest, $0.CloseResultResponse>(
          '/queravue.v1.QueryService/CloseResult',
          ($0.CloseResultRequest value) => value.writeToBuffer(),
          $0.CloseResultResponse.fromBuffer);
  static final _$copyRange =
      $grpc.ClientMethod<$0.CopyRangeRequest, $0.CopyRangeResponse>(
          '/queravue.v1.QueryService/CopyRange',
          ($0.CopyRangeRequest value) => value.writeToBuffer(),
          $0.CopyRangeResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.QueryService')
abstract class QueryServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.QueryService';

  QueryServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ExecuteRequest, $0.ExecuteResponse>(
        'Execute',
        execute_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ExecuteRequest.fromBuffer(value),
        ($0.ExecuteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FetchRowsRequest, $0.FetchRowsResponse>(
        'FetchRows',
        fetchRows_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FetchRowsRequest.fromBuffer(value),
        ($0.FetchRowsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelRequest, $0.CancelResponse>(
        'Cancel',
        cancel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CancelRequest.fromBuffer(value),
        ($0.CancelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CloseResultRequest, $0.CloseResultResponse>(
            'CloseResult',
            closeResult_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CloseResultRequest.fromBuffer(value),
            ($0.CloseResultResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CopyRangeRequest, $0.CopyRangeResponse>(
        'CopyRange',
        copyRange_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.CopyRangeRequest.fromBuffer(value),
        ($0.CopyRangeResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ExecuteResponse> execute_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExecuteRequest> $request) async* {
    yield* execute($call, await $request);
  }

  $async.Stream<$0.ExecuteResponse> execute(
      $grpc.ServiceCall call, $0.ExecuteRequest request);

  $async.Future<$0.FetchRowsResponse> fetchRows_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FetchRowsRequest> $request) async {
    return fetchRows($call, await $request);
  }

  $async.Future<$0.FetchRowsResponse> fetchRows(
      $grpc.ServiceCall call, $0.FetchRowsRequest request);

  $async.Future<$0.CancelResponse> cancel_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CancelRequest> $request) async {
    return cancel($call, await $request);
  }

  $async.Future<$0.CancelResponse> cancel(
      $grpc.ServiceCall call, $0.CancelRequest request);

  $async.Future<$0.CloseResultResponse> closeResult_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CloseResultRequest> $request) async {
    return closeResult($call, await $request);
  }

  $async.Future<$0.CloseResultResponse> closeResult(
      $grpc.ServiceCall call, $0.CloseResultRequest request);

  $async.Stream<$0.CopyRangeResponse> copyRange_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CopyRangeRequest> $request) async* {
    yield* copyRange($call, await $request);
  }

  $async.Stream<$0.CopyRangeResponse> copyRange(
      $grpc.ServiceCall call, $0.CopyRangeRequest request);
}
