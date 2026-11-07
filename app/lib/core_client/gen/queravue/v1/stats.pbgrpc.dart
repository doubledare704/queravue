// This is a generated file - do not edit.
//
// Generated from queravue/v1/stats.proto.

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

import 'stats.pb.dart' as $0;

export 'stats.pb.dart';

/// StatsService reports table and collection statistics. The UI offers it only
/// when the connection reports the stats capability.
@$pb.GrpcServiceName('queravue.v1.StatsService')
class StatsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  StatsServiceClient(super.channel, {super.options, super.interceptors});

  /// GetStats returns sizes, row estimates and engine-specific figures for one
  /// table or collection. It reads server metadata and never scans the data.
  $grpc.ResponseFuture<$0.GetStatsResponse> getStats(
    $0.GetStatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStats, request, options: options);
  }

  // method descriptors

  static final _$getStats =
      $grpc.ClientMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
          '/queravue.v1.StatsService/GetStats',
          ($0.GetStatsRequest value) => value.writeToBuffer(),
          $0.GetStatsResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.StatsService')
abstract class StatsServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.StatsService';

  StatsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
        'GetStats',
        getStats_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatsRequest.fromBuffer(value),
        ($0.GetStatsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetStatsResponse> getStats_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetStatsRequest> $request) async {
    return getStats($call, await $request);
  }

  $async.Future<$0.GetStatsResponse> getStats(
      $grpc.ServiceCall call, $0.GetStatsRequest request);
}
