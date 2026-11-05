// This is a generated file - do not edit.
//
// Generated from queravue/v1/schema.proto.

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

import 'schema.pb.dart' as $0;

export 'schema.pb.dart';

/// SchemaService provides lazy database schema inspection for connections.
/// Calls are cached per session and can be invalidated explicitly via refresh.
@$pb.GrpcServiceName('queravue.v1.SchemaService')
class SchemaServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SchemaServiceClient(super.channel, {super.options, super.interceptors});

  /// ListDatabases returns the names of all accessible databases for the session.
  $grpc.ResponseFuture<$0.ListDatabasesResponse> listDatabases(
    $0.ListDatabasesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDatabases, request, options: options);
  }

  /// ListSchemas returns the names of schemas within the specified database.
  $grpc.ResponseFuture<$0.ListSchemasResponse> listSchemas(
    $0.ListSchemasRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSchemas, request, options: options);
  }

  /// ListObjects returns tables, views, and materialized views inside a schema.
  $grpc.ResponseFuture<$0.ListObjectsResponse> listObjects(
    $0.ListObjectsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listObjects, request, options: options);
  }

  /// GetTableDetails returns detailed column definitions, indexes, foreign keys,
  /// and editability status for a single table or view.
  $grpc.ResponseFuture<$0.GetTableDetailsResponse> getTableDetails(
    $0.GetTableDetailsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTableDetails, request, options: options);
  }

  /// RefreshSchema invalidates cached schema metadata for a session or specific table.
  $grpc.ResponseFuture<$0.RefreshSchemaResponse> refreshSchema(
    $0.RefreshSchemaRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$refreshSchema, request, options: options);
  }

  // method descriptors

  static final _$listDatabases =
      $grpc.ClientMethod<$0.ListDatabasesRequest, $0.ListDatabasesResponse>(
          '/queravue.v1.SchemaService/ListDatabases',
          ($0.ListDatabasesRequest value) => value.writeToBuffer(),
          $0.ListDatabasesResponse.fromBuffer);
  static final _$listSchemas =
      $grpc.ClientMethod<$0.ListSchemasRequest, $0.ListSchemasResponse>(
          '/queravue.v1.SchemaService/ListSchemas',
          ($0.ListSchemasRequest value) => value.writeToBuffer(),
          $0.ListSchemasResponse.fromBuffer);
  static final _$listObjects =
      $grpc.ClientMethod<$0.ListObjectsRequest, $0.ListObjectsResponse>(
          '/queravue.v1.SchemaService/ListObjects',
          ($0.ListObjectsRequest value) => value.writeToBuffer(),
          $0.ListObjectsResponse.fromBuffer);
  static final _$getTableDetails =
      $grpc.ClientMethod<$0.GetTableDetailsRequest, $0.GetTableDetailsResponse>(
          '/queravue.v1.SchemaService/GetTableDetails',
          ($0.GetTableDetailsRequest value) => value.writeToBuffer(),
          $0.GetTableDetailsResponse.fromBuffer);
  static final _$refreshSchema =
      $grpc.ClientMethod<$0.RefreshSchemaRequest, $0.RefreshSchemaResponse>(
          '/queravue.v1.SchemaService/RefreshSchema',
          ($0.RefreshSchemaRequest value) => value.writeToBuffer(),
          $0.RefreshSchemaResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.SchemaService')
abstract class SchemaServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.SchemaService';

  SchemaServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListDatabasesRequest, $0.ListDatabasesResponse>(
            'ListDatabases',
            listDatabases_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListDatabasesRequest.fromBuffer(value),
            ($0.ListDatabasesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListSchemasRequest, $0.ListSchemasResponse>(
            'ListSchemas',
            listSchemas_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListSchemasRequest.fromBuffer(value),
            ($0.ListSchemasResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListObjectsRequest, $0.ListObjectsResponse>(
            'ListObjects',
            listObjects_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListObjectsRequest.fromBuffer(value),
            ($0.ListObjectsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTableDetailsRequest,
            $0.GetTableDetailsResponse>(
        'GetTableDetails',
        getTableDetails_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetTableDetailsRequest.fromBuffer(value),
        ($0.GetTableDetailsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RefreshSchemaRequest, $0.RefreshSchemaResponse>(
            'RefreshSchema',
            refreshSchema_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RefreshSchemaRequest.fromBuffer(value),
            ($0.RefreshSchemaResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListDatabasesResponse> listDatabases_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDatabasesRequest> $request) async {
    return listDatabases($call, await $request);
  }

  $async.Future<$0.ListDatabasesResponse> listDatabases(
      $grpc.ServiceCall call, $0.ListDatabasesRequest request);

  $async.Future<$0.ListSchemasResponse> listSchemas_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListSchemasRequest> $request) async {
    return listSchemas($call, await $request);
  }

  $async.Future<$0.ListSchemasResponse> listSchemas(
      $grpc.ServiceCall call, $0.ListSchemasRequest request);

  $async.Future<$0.ListObjectsResponse> listObjects_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListObjectsRequest> $request) async {
    return listObjects($call, await $request);
  }

  $async.Future<$0.ListObjectsResponse> listObjects(
      $grpc.ServiceCall call, $0.ListObjectsRequest request);

  $async.Future<$0.GetTableDetailsResponse> getTableDetails_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetTableDetailsRequest> $request) async {
    return getTableDetails($call, await $request);
  }

  $async.Future<$0.GetTableDetailsResponse> getTableDetails(
      $grpc.ServiceCall call, $0.GetTableDetailsRequest request);

  $async.Future<$0.RefreshSchemaResponse> refreshSchema_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RefreshSchemaRequest> $request) async {
    return refreshSchema($call, await $request);
  }

  $async.Future<$0.RefreshSchemaResponse> refreshSchema(
      $grpc.ServiceCall call, $0.RefreshSchemaRequest request);
}
