// This is a generated file - do not edit.
//
// Generated from queravue/v1/table.proto.

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

import 'table.pb.dart' as $0;

export 'table.pb.dart';

/// TableService provides browsing, filtering, sorting, and inline editing of table data.
@$pb.GrpcServiceName('queravue.v1.TableService')
class TableServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TableServiceClient(super.channel, {super.options, super.interceptors});

  /// OpenTable generates dialect-specific SQL for browsing a table with filters,
  /// sorts, and page size, executes it through the core spool, and streams results.
  /// The first response event returns the generated SQL.
  $grpc.ResponseStream<$0.OpenTableResponse> openTable(
    $0.OpenTableRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$openTable, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// ApplyChanges executes inserts, updates, and deletes against a table within a single
  /// transaction. When dry_run is true, it returns the generated SQL preview without executing.
  $grpc.ResponseFuture<$0.ApplyChangesResponse> applyChanges(
    $0.ApplyChangesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyChanges, request, options: options);
  }

  // method descriptors

  static final _$openTable =
      $grpc.ClientMethod<$0.OpenTableRequest, $0.OpenTableResponse>(
          '/queravue.v1.TableService/OpenTable',
          ($0.OpenTableRequest value) => value.writeToBuffer(),
          $0.OpenTableResponse.fromBuffer);
  static final _$applyChanges =
      $grpc.ClientMethod<$0.ApplyChangesRequest, $0.ApplyChangesResponse>(
          '/queravue.v1.TableService/ApplyChanges',
          ($0.ApplyChangesRequest value) => value.writeToBuffer(),
          $0.ApplyChangesResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.TableService')
abstract class TableServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.TableService';

  TableServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.OpenTableRequest, $0.OpenTableResponse>(
        'OpenTable',
        openTable_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.OpenTableRequest.fromBuffer(value),
        ($0.OpenTableResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApplyChangesRequest, $0.ApplyChangesResponse>(
            'ApplyChanges',
            applyChanges_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ApplyChangesRequest.fromBuffer(value),
            ($0.ApplyChangesResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.OpenTableResponse> openTable_Pre($grpc.ServiceCall $call,
      $async.Future<$0.OpenTableRequest> $request) async* {
    yield* openTable($call, await $request);
  }

  $async.Stream<$0.OpenTableResponse> openTable(
      $grpc.ServiceCall call, $0.OpenTableRequest request);

  $async.Future<$0.ApplyChangesResponse> applyChanges_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApplyChangesRequest> $request) async {
    return applyChanges($call, await $request);
  }

  $async.Future<$0.ApplyChangesResponse> applyChanges(
      $grpc.ServiceCall call, $0.ApplyChangesRequest request);
}
