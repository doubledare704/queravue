// This is a generated file - do not edit.
//
// Generated from queravue/v1/history.proto.

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

import 'history.pb.dart' as $0;

export 'history.pb.dart';

/// HistoryService manages query execution history stored in core.
@$pb.GrpcServiceName('queravue.v1.HistoryService')
class HistoryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HistoryServiceClient(super.channel, {super.options, super.interceptors});

  /// ListHistory returns executed queries matching search criteria, newest first.
  $grpc.ResponseFuture<$0.ListHistoryResponse> listHistory(
    $0.ListHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listHistory, request, options: options);
  }

  /// ClearHistory removes query history entries.
  $grpc.ResponseFuture<$0.ClearHistoryResponse> clearHistory(
    $0.ClearHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$clearHistory, request, options: options);
  }

  // method descriptors

  static final _$listHistory =
      $grpc.ClientMethod<$0.ListHistoryRequest, $0.ListHistoryResponse>(
          '/queravue.v1.HistoryService/ListHistory',
          ($0.ListHistoryRequest value) => value.writeToBuffer(),
          $0.ListHistoryResponse.fromBuffer);
  static final _$clearHistory =
      $grpc.ClientMethod<$0.ClearHistoryRequest, $0.ClearHistoryResponse>(
          '/queravue.v1.HistoryService/ClearHistory',
          ($0.ClearHistoryRequest value) => value.writeToBuffer(),
          $0.ClearHistoryResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.HistoryService')
abstract class HistoryServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.HistoryService';

  HistoryServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListHistoryRequest, $0.ListHistoryResponse>(
            'ListHistory',
            listHistory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListHistoryRequest.fromBuffer(value),
            ($0.ListHistoryResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ClearHistoryRequest, $0.ClearHistoryResponse>(
            'ClearHistory',
            clearHistory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ClearHistoryRequest.fromBuffer(value),
            ($0.ClearHistoryResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListHistoryResponse> listHistory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListHistoryRequest> $request) async {
    return listHistory($call, await $request);
  }

  $async.Future<$0.ListHistoryResponse> listHistory(
      $grpc.ServiceCall call, $0.ListHistoryRequest request);

  $async.Future<$0.ClearHistoryResponse> clearHistory_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ClearHistoryRequest> $request) async {
    return clearHistory($call, await $request);
  }

  $async.Future<$0.ClearHistoryResponse> clearHistory(
      $grpc.ServiceCall call, $0.ClearHistoryRequest request);
}
