// This is a generated file - do not edit.
//
// Generated from queravue/v1/connections.proto.

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

import 'connections.pb.dart' as $0;

export 'connections.pb.dart';

/// ConnectionService manages saved connection profiles and tests them.
/// Profiles are stored by the core without secrets; passwords live in the OS
/// keychain and never travel back to the UI.
@$pb.GrpcServiceName('queravue.v1.ConnectionService')
class ConnectionServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ConnectionServiceClient(super.channel, {super.options, super.interceptors});

  /// ListEngines returns the engines this core supports, with the form fields
  /// the UI should render for each. The UI must build its connection form from
  /// this data and never special-case engine ids.
  $grpc.ResponseFuture<$0.ListEnginesResponse> listEngines(
    $0.ListEnginesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listEngines, request, options: options);
  }

  /// ListConnections returns all saved connections, ordered by folder then name.
  $grpc.ResponseFuture<$0.ListConnectionsResponse> listConnections(
    $0.ListConnectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listConnections, request, options: options);
  }

  /// GetConnection returns one saved connection. NOT_FOUND if the id is unknown.
  $grpc.ResponseFuture<$0.GetConnectionResponse> getConnection(
    $0.GetConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getConnection, request, options: options);
  }

  /// CreateConnection saves a new connection. The core assigns the id and
  /// timestamps. INVALID_ARGUMENT if the engine is unknown or a required field
  /// is missing.
  $grpc.ResponseFuture<$0.CreateConnectionResponse> createConnection(
    $0.CreateConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createConnection, request, options: options);
  }

  /// UpdateConnection replaces a saved connection's settings. NOT_FOUND if the
  /// id is unknown.
  $grpc.ResponseFuture<$0.UpdateConnectionResponse> updateConnection(
    $0.UpdateConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateConnection, request, options: options);
  }

  /// DeleteConnection removes a saved connection and its keychain secret.
  /// Deleting an unknown id returns NOT_FOUND.
  $grpc.ResponseFuture<$0.DeleteConnectionResponse> deleteConnection(
    $0.DeleteConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteConnection, request, options: options);
  }

  /// TestConnection connects, pings and reads the server version, then closes.
  /// Connection failures are reported in-band in the response, not as gRPC
  /// errors. Honours cancellation.
  $grpc.ResponseFuture<$0.TestConnectionResponse> testConnection(
    $0.TestConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testConnection, request, options: options);
  }

  /// ParseConnectionString splits a URI or DSN into form fields. The password,
  /// if present, is returned separately so the UI can put it into the password
  /// field without ever storing it in params.
  $grpc.ResponseFuture<$0.ParseConnectionStringResponse> parseConnectionString(
    $0.ParseConnectionStringRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$parseConnectionString, request, options: options);
  }

  /// TrustHostKey records an SSH host key the user accepted after an
  /// ERROR_KIND_SSH_HOST_KEY_UNKNOWN failure. The fingerprint must equal the one
  /// the failure carried; a changed key can never be trusted this way.
  $grpc.ResponseFuture<$0.TrustHostKeyResponse> trustHostKey(
    $0.TrustHostKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$trustHostKey, request, options: options);
  }

  // method descriptors

  static final _$listEngines =
      $grpc.ClientMethod<$0.ListEnginesRequest, $0.ListEnginesResponse>(
          '/queravue.v1.ConnectionService/ListEngines',
          ($0.ListEnginesRequest value) => value.writeToBuffer(),
          $0.ListEnginesResponse.fromBuffer);
  static final _$listConnections =
      $grpc.ClientMethod<$0.ListConnectionsRequest, $0.ListConnectionsResponse>(
          '/queravue.v1.ConnectionService/ListConnections',
          ($0.ListConnectionsRequest value) => value.writeToBuffer(),
          $0.ListConnectionsResponse.fromBuffer);
  static final _$getConnection =
      $grpc.ClientMethod<$0.GetConnectionRequest, $0.GetConnectionResponse>(
          '/queravue.v1.ConnectionService/GetConnection',
          ($0.GetConnectionRequest value) => value.writeToBuffer(),
          $0.GetConnectionResponse.fromBuffer);
  static final _$createConnection = $grpc.ClientMethod<
          $0.CreateConnectionRequest, $0.CreateConnectionResponse>(
      '/queravue.v1.ConnectionService/CreateConnection',
      ($0.CreateConnectionRequest value) => value.writeToBuffer(),
      $0.CreateConnectionResponse.fromBuffer);
  static final _$updateConnection = $grpc.ClientMethod<
          $0.UpdateConnectionRequest, $0.UpdateConnectionResponse>(
      '/queravue.v1.ConnectionService/UpdateConnection',
      ($0.UpdateConnectionRequest value) => value.writeToBuffer(),
      $0.UpdateConnectionResponse.fromBuffer);
  static final _$deleteConnection = $grpc.ClientMethod<
          $0.DeleteConnectionRequest, $0.DeleteConnectionResponse>(
      '/queravue.v1.ConnectionService/DeleteConnection',
      ($0.DeleteConnectionRequest value) => value.writeToBuffer(),
      $0.DeleteConnectionResponse.fromBuffer);
  static final _$testConnection =
      $grpc.ClientMethod<$0.TestConnectionRequest, $0.TestConnectionResponse>(
          '/queravue.v1.ConnectionService/TestConnection',
          ($0.TestConnectionRequest value) => value.writeToBuffer(),
          $0.TestConnectionResponse.fromBuffer);
  static final _$parseConnectionString = $grpc.ClientMethod<
          $0.ParseConnectionStringRequest, $0.ParseConnectionStringResponse>(
      '/queravue.v1.ConnectionService/ParseConnectionString',
      ($0.ParseConnectionStringRequest value) => value.writeToBuffer(),
      $0.ParseConnectionStringResponse.fromBuffer);
  static final _$trustHostKey =
      $grpc.ClientMethod<$0.TrustHostKeyRequest, $0.TrustHostKeyResponse>(
          '/queravue.v1.ConnectionService/TrustHostKey',
          ($0.TrustHostKeyRequest value) => value.writeToBuffer(),
          $0.TrustHostKeyResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.ConnectionService')
abstract class ConnectionServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.ConnectionService';

  ConnectionServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListEnginesRequest, $0.ListEnginesResponse>(
            'ListEngines',
            listEngines_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListEnginesRequest.fromBuffer(value),
            ($0.ListEnginesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListConnectionsRequest,
            $0.ListConnectionsResponse>(
        'ListConnections',
        listConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListConnectionsRequest.fromBuffer(value),
        ($0.ListConnectionsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetConnectionRequest, $0.GetConnectionResponse>(
            'GetConnection',
            getConnection_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetConnectionRequest.fromBuffer(value),
            ($0.GetConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateConnectionRequest,
            $0.CreateConnectionResponse>(
        'CreateConnection',
        createConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateConnectionRequest.fromBuffer(value),
        ($0.CreateConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateConnectionRequest,
            $0.UpdateConnectionResponse>(
        'UpdateConnection',
        updateConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateConnectionRequest.fromBuffer(value),
        ($0.UpdateConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteConnectionRequest,
            $0.DeleteConnectionResponse>(
        'DeleteConnection',
        deleteConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteConnectionRequest.fromBuffer(value),
        ($0.DeleteConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TestConnectionRequest,
            $0.TestConnectionResponse>(
        'TestConnection',
        testConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.TestConnectionRequest.fromBuffer(value),
        ($0.TestConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ParseConnectionStringRequest,
            $0.ParseConnectionStringResponse>(
        'ParseConnectionString',
        parseConnectionString_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ParseConnectionStringRequest.fromBuffer(value),
        ($0.ParseConnectionStringResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.TrustHostKeyRequest, $0.TrustHostKeyResponse>(
            'TrustHostKey',
            trustHostKey_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.TrustHostKeyRequest.fromBuffer(value),
            ($0.TrustHostKeyResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListEnginesResponse> listEngines_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListEnginesRequest> $request) async {
    return listEngines($call, await $request);
  }

  $async.Future<$0.ListEnginesResponse> listEngines(
      $grpc.ServiceCall call, $0.ListEnginesRequest request);

  $async.Future<$0.ListConnectionsResponse> listConnections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListConnectionsRequest> $request) async {
    return listConnections($call, await $request);
  }

  $async.Future<$0.ListConnectionsResponse> listConnections(
      $grpc.ServiceCall call, $0.ListConnectionsRequest request);

  $async.Future<$0.GetConnectionResponse> getConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetConnectionRequest> $request) async {
    return getConnection($call, await $request);
  }

  $async.Future<$0.GetConnectionResponse> getConnection(
      $grpc.ServiceCall call, $0.GetConnectionRequest request);

  $async.Future<$0.CreateConnectionResponse> createConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateConnectionRequest> $request) async {
    return createConnection($call, await $request);
  }

  $async.Future<$0.CreateConnectionResponse> createConnection(
      $grpc.ServiceCall call, $0.CreateConnectionRequest request);

  $async.Future<$0.UpdateConnectionResponse> updateConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateConnectionRequest> $request) async {
    return updateConnection($call, await $request);
  }

  $async.Future<$0.UpdateConnectionResponse> updateConnection(
      $grpc.ServiceCall call, $0.UpdateConnectionRequest request);

  $async.Future<$0.DeleteConnectionResponse> deleteConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteConnectionRequest> $request) async {
    return deleteConnection($call, await $request);
  }

  $async.Future<$0.DeleteConnectionResponse> deleteConnection(
      $grpc.ServiceCall call, $0.DeleteConnectionRequest request);

  $async.Future<$0.TestConnectionResponse> testConnection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TestConnectionRequest> $request) async {
    return testConnection($call, await $request);
  }

  $async.Future<$0.TestConnectionResponse> testConnection(
      $grpc.ServiceCall call, $0.TestConnectionRequest request);

  $async.Future<$0.ParseConnectionStringResponse> parseConnectionString_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ParseConnectionStringRequest> $request) async {
    return parseConnectionString($call, await $request);
  }

  $async.Future<$0.ParseConnectionStringResponse> parseConnectionString(
      $grpc.ServiceCall call, $0.ParseConnectionStringRequest request);

  $async.Future<$0.TrustHostKeyResponse> trustHostKey_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TrustHostKeyRequest> $request) async {
    return trustHostKey($call, await $request);
  }

  $async.Future<$0.TrustHostKeyResponse> trustHostKey(
      $grpc.ServiceCall call, $0.TrustHostKeyRequest request);
}
