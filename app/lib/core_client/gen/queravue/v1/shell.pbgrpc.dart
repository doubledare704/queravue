// This is a generated file - do not edit.
//
// Generated from queravue/v1/shell.proto.

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

import 'shell.pb.dart' as $0;

export 'shell.pb.dart';

/// ShellService runs mongosh-style JavaScript against sessions whose engine has
/// the "shell" capability (ADR 0010). A shell keeps its variables between Eval
/// calls. Values travel as MongoDB Extended JSON v2 text (ADR 0009).
///
/// Unknown shells are NOT_FOUND and sessions without the capability are
/// FAILED_PRECONDITION. Script failures are reported in-band as ShellError
/// events.
@$pb.GrpcServiceName('queravue.v1.ShellService')
class ShellServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ShellServiceClient(super.channel, {super.options, super.interceptors});

  /// OpenShell starts a shell on an open session. Honours cancellation.
  $grpc.ResponseFuture<$0.OpenShellResponse> openShell(
    $0.OpenShellRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openShell, request, options: options);
  }

  /// Eval runs code and streams its output events in order. The stream ends
  /// with a done event, or with an error event for a failure. Cancelling the
  /// call, or calling Cancel, interrupts the script and any driver operation in
  /// flight.
  $grpc.ResponseStream<$0.EvalResponse> eval(
    $0.EvalRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$eval, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// FetchCursor streams one page of the documents behind a cursor handle by
  /// re-running its query with skip and limit.
  $grpc.ResponseStream<$0.FetchCursorResponse> fetchCursor(
    $0.FetchCursorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$fetchCursor, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Cancel interrupts the running Eval of a shell. Cancelling an idle shell
  /// succeeds.
  $grpc.ResponseFuture<$0.ShellServiceCancelResponse> cancel(
    $0.ShellServiceCancelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancel, request, options: options);
  }

  /// CloseShell frees the shell and its cursor handles. Closing an unknown or
  /// closed shell succeeds.
  $grpc.ResponseFuture<$0.CloseShellResponse> closeShell(
    $0.CloseShellRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeShell, request, options: options);
  }

  // method descriptors

  static final _$openShell =
      $grpc.ClientMethod<$0.OpenShellRequest, $0.OpenShellResponse>(
          '/queravue.v1.ShellService/OpenShell',
          ($0.OpenShellRequest value) => value.writeToBuffer(),
          $0.OpenShellResponse.fromBuffer);
  static final _$eval = $grpc.ClientMethod<$0.EvalRequest, $0.EvalResponse>(
      '/queravue.v1.ShellService/Eval',
      ($0.EvalRequest value) => value.writeToBuffer(),
      $0.EvalResponse.fromBuffer);
  static final _$fetchCursor =
      $grpc.ClientMethod<$0.FetchCursorRequest, $0.FetchCursorResponse>(
          '/queravue.v1.ShellService/FetchCursor',
          ($0.FetchCursorRequest value) => value.writeToBuffer(),
          $0.FetchCursorResponse.fromBuffer);
  static final _$cancel = $grpc.ClientMethod<$0.ShellServiceCancelRequest,
          $0.ShellServiceCancelResponse>(
      '/queravue.v1.ShellService/Cancel',
      ($0.ShellServiceCancelRequest value) => value.writeToBuffer(),
      $0.ShellServiceCancelResponse.fromBuffer);
  static final _$closeShell =
      $grpc.ClientMethod<$0.CloseShellRequest, $0.CloseShellResponse>(
          '/queravue.v1.ShellService/CloseShell',
          ($0.CloseShellRequest value) => value.writeToBuffer(),
          $0.CloseShellResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.ShellService')
abstract class ShellServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.ShellService';

  ShellServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.OpenShellRequest, $0.OpenShellResponse>(
        'OpenShell',
        openShell_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OpenShellRequest.fromBuffer(value),
        ($0.OpenShellResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EvalRequest, $0.EvalResponse>(
        'Eval',
        eval_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.EvalRequest.fromBuffer(value),
        ($0.EvalResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.FetchCursorRequest, $0.FetchCursorResponse>(
            'FetchCursor',
            fetchCursor_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.FetchCursorRequest.fromBuffer(value),
            ($0.FetchCursorResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ShellServiceCancelRequest,
            $0.ShellServiceCancelResponse>(
        'Cancel',
        cancel_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ShellServiceCancelRequest.fromBuffer(value),
        ($0.ShellServiceCancelResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CloseShellRequest, $0.CloseShellResponse>(
        'CloseShell',
        closeShell_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CloseShellRequest.fromBuffer(value),
        ($0.CloseShellResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.OpenShellResponse> openShell_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OpenShellRequest> $request) async {
    return openShell($call, await $request);
  }

  $async.Future<$0.OpenShellResponse> openShell(
      $grpc.ServiceCall call, $0.OpenShellRequest request);

  $async.Stream<$0.EvalResponse> eval_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EvalRequest> $request) async* {
    yield* eval($call, await $request);
  }

  $async.Stream<$0.EvalResponse> eval(
      $grpc.ServiceCall call, $0.EvalRequest request);

  $async.Stream<$0.FetchCursorResponse> fetchCursor_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FetchCursorRequest> $request) async* {
    yield* fetchCursor($call, await $request);
  }

  $async.Stream<$0.FetchCursorResponse> fetchCursor(
      $grpc.ServiceCall call, $0.FetchCursorRequest request);

  $async.Future<$0.ShellServiceCancelResponse> cancel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ShellServiceCancelRequest> $request) async {
    return cancel($call, await $request);
  }

  $async.Future<$0.ShellServiceCancelResponse> cancel(
      $grpc.ServiceCall call, $0.ShellServiceCancelRequest request);

  $async.Future<$0.CloseShellResponse> closeShell_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CloseShellRequest> $request) async {
    return closeShell($call, await $request);
  }

  $async.Future<$0.CloseShellResponse> closeShell(
      $grpc.ServiceCall call, $0.CloseShellRequest request);
}
