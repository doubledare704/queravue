// This is a generated file - do not edit.
//
// Generated from queravue/v1/index.proto.

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

import 'index.pb.dart' as $0;

export 'index.pb.dart';

/// IndexService lists, creates and drops indexes on SQL tables and Mongo collections.
/// For Mongo, TableRef.database is the database, TableRef.table is the collection
/// and TableRef.schema is empty. The UI offers it only when the connection reports
/// the index_manager capability.
@$pb.GrpcServiceName('queravue.v1.IndexService')
class IndexServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  IndexServiceClient(super.channel, {super.options, super.interceptors});

  /// ListIndexes returns every index on the table or collection, with usage
  /// statistics where the server provides them.
  $grpc.ResponseFuture<$0.ListIndexesResponse> listIndexes(
    $0.ListIndexesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listIndexes, request, options: options);
  }

  /// CreateIndex builds an index. With dry_run it only returns the statement
  /// (SQL DDL, or the createIndexes command as shell text) without running it.
  $grpc.ResponseFuture<$0.CreateIndexResponse> createIndex(
    $0.CreateIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createIndex, request, options: options);
  }

  /// DropIndex removes an index. Always needs confirmed=true; with dry_run it
  /// only returns the statement.
  $grpc.ResponseFuture<$0.DropIndexResponse> dropIndex(
    $0.DropIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$dropIndex, request, options: options);
  }

  // method descriptors

  static final _$listIndexes =
      $grpc.ClientMethod<$0.ListIndexesRequest, $0.ListIndexesResponse>(
          '/queravue.v1.IndexService/ListIndexes',
          ($0.ListIndexesRequest value) => value.writeToBuffer(),
          $0.ListIndexesResponse.fromBuffer);
  static final _$createIndex =
      $grpc.ClientMethod<$0.CreateIndexRequest, $0.CreateIndexResponse>(
          '/queravue.v1.IndexService/CreateIndex',
          ($0.CreateIndexRequest value) => value.writeToBuffer(),
          $0.CreateIndexResponse.fromBuffer);
  static final _$dropIndex =
      $grpc.ClientMethod<$0.DropIndexRequest, $0.DropIndexResponse>(
          '/queravue.v1.IndexService/DropIndex',
          ($0.DropIndexRequest value) => value.writeToBuffer(),
          $0.DropIndexResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.IndexService')
abstract class IndexServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.IndexService';

  IndexServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListIndexesRequest, $0.ListIndexesResponse>(
            'ListIndexes',
            listIndexes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListIndexesRequest.fromBuffer(value),
            ($0.ListIndexesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CreateIndexRequest, $0.CreateIndexResponse>(
            'CreateIndex',
            createIndex_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateIndexRequest.fromBuffer(value),
            ($0.CreateIndexResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DropIndexRequest, $0.DropIndexResponse>(
        'DropIndex',
        dropIndex_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DropIndexRequest.fromBuffer(value),
        ($0.DropIndexResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListIndexesResponse> listIndexes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListIndexesRequest> $request) async {
    return listIndexes($call, await $request);
  }

  $async.Future<$0.ListIndexesResponse> listIndexes(
      $grpc.ServiceCall call, $0.ListIndexesRequest request);

  $async.Future<$0.CreateIndexResponse> createIndex_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateIndexRequest> $request) async {
    return createIndex($call, await $request);
  }

  $async.Future<$0.CreateIndexResponse> createIndex(
      $grpc.ServiceCall call, $0.CreateIndexRequest request);

  $async.Future<$0.DropIndexResponse> dropIndex_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DropIndexRequest> $request) async {
    return dropIndex($call, await $request);
  }

  $async.Future<$0.DropIndexResponse> dropIndex(
      $grpc.ServiceCall call, $0.DropIndexRequest request);
}
