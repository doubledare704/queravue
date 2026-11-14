// This is a generated file - do not edit.
//
// Generated from queravue/v1/keyvalue.proto.

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

import 'keyvalue.pb.dart' as $0;

export 'keyvalue.pb.dart';

/// KeyValueService browses and edits key-value stores (Redis and compatible).
/// It is available on sessions whose capabilities include "key_value_store".
/// Failures that the user can act on are returned in-band in `error`.
@$pb.GrpcServiceName('queravue.v1.KeyValueService')
class KeyValueServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  KeyValueServiceClient(super.channel, {super.options, super.interceptors});

  /// ListDatabases lists logical databases with their key counts.
  $grpc.ResponseFuture<$0.ListKvDatabasesResponse> listKvDatabases(
    $0.ListKvDatabasesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listKvDatabases, request, options: options);
  }

  /// ScanKeys streams matching keys in pages using SCAN, never KEYS. On a
  /// cluster it scans every master. Cancelling stops the scan.
  $grpc.ResponseStream<$0.ScanKeysResponse> scanKeys(
    $0.ScanKeysRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$scanKeys, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// GetKeyInfo returns type, TTL, encoding, length and memory use of one key.
  $grpc.ResponseFuture<$0.GetKeyInfoResponse> getKeyInfo(
    $0.GetKeyInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getKeyInfo, request, options: options);
  }

  /// ReadValue reads one page of a key's value. Collections are always paged.
  $grpc.ResponseFuture<$0.ReadValueResponse> readValue(
    $0.ReadValueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readValue, request, options: options);
  }

  /// WriteValue applies one typed edit to a key.
  $grpc.ResponseFuture<$0.WriteValueResponse> writeValue(
    $0.WriteValueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$writeValue, request, options: options);
  }

  /// RenameKey renames a key.
  $grpc.ResponseFuture<$0.RenameKeyResponse> renameKey(
    $0.RenameKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameKey, request, options: options);
  }

  /// SetExpiry sets or removes a key's time to live.
  $grpc.ResponseFuture<$0.SetExpiryResponse> setExpiry(
    $0.SetExpiryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setExpiry, request, options: options);
  }

  /// DeleteKeys deletes keys.
  $grpc.ResponseFuture<$0.DeleteKeysResponse> deleteKeys(
    $0.DeleteKeysRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteKeys, request, options: options);
  }

  /// ExecuteCommand runs one command and returns its typed reply. Blocking
  /// commands are refused; use Subscribe for pub/sub.
  $grpc.ResponseFuture<$0.ExecuteCommandResponse> executeCommand(
    $0.ExecuteCommandRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$executeCommand, request, options: options);
  }

  /// Subscribe streams messages from channels and patterns until cancelled.
  $grpc.ResponseStream<$0.SubscribeResponse> subscribe(
    $0.SubscribeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribe, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Publish sends a message to a channel and returns the receiver count.
  $grpc.ResponseFuture<$0.PublishResponse> publish(
    $0.PublishRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$publish, request, options: options);
  }

  // method descriptors

  static final _$listKvDatabases =
      $grpc.ClientMethod<$0.ListKvDatabasesRequest, $0.ListKvDatabasesResponse>(
          '/queravue.v1.KeyValueService/ListKvDatabases',
          ($0.ListKvDatabasesRequest value) => value.writeToBuffer(),
          $0.ListKvDatabasesResponse.fromBuffer);
  static final _$scanKeys =
      $grpc.ClientMethod<$0.ScanKeysRequest, $0.ScanKeysResponse>(
          '/queravue.v1.KeyValueService/ScanKeys',
          ($0.ScanKeysRequest value) => value.writeToBuffer(),
          $0.ScanKeysResponse.fromBuffer);
  static final _$getKeyInfo =
      $grpc.ClientMethod<$0.GetKeyInfoRequest, $0.GetKeyInfoResponse>(
          '/queravue.v1.KeyValueService/GetKeyInfo',
          ($0.GetKeyInfoRequest value) => value.writeToBuffer(),
          $0.GetKeyInfoResponse.fromBuffer);
  static final _$readValue =
      $grpc.ClientMethod<$0.ReadValueRequest, $0.ReadValueResponse>(
          '/queravue.v1.KeyValueService/ReadValue',
          ($0.ReadValueRequest value) => value.writeToBuffer(),
          $0.ReadValueResponse.fromBuffer);
  static final _$writeValue =
      $grpc.ClientMethod<$0.WriteValueRequest, $0.WriteValueResponse>(
          '/queravue.v1.KeyValueService/WriteValue',
          ($0.WriteValueRequest value) => value.writeToBuffer(),
          $0.WriteValueResponse.fromBuffer);
  static final _$renameKey =
      $grpc.ClientMethod<$0.RenameKeyRequest, $0.RenameKeyResponse>(
          '/queravue.v1.KeyValueService/RenameKey',
          ($0.RenameKeyRequest value) => value.writeToBuffer(),
          $0.RenameKeyResponse.fromBuffer);
  static final _$setExpiry =
      $grpc.ClientMethod<$0.SetExpiryRequest, $0.SetExpiryResponse>(
          '/queravue.v1.KeyValueService/SetExpiry',
          ($0.SetExpiryRequest value) => value.writeToBuffer(),
          $0.SetExpiryResponse.fromBuffer);
  static final _$deleteKeys =
      $grpc.ClientMethod<$0.DeleteKeysRequest, $0.DeleteKeysResponse>(
          '/queravue.v1.KeyValueService/DeleteKeys',
          ($0.DeleteKeysRequest value) => value.writeToBuffer(),
          $0.DeleteKeysResponse.fromBuffer);
  static final _$executeCommand =
      $grpc.ClientMethod<$0.ExecuteCommandRequest, $0.ExecuteCommandResponse>(
          '/queravue.v1.KeyValueService/ExecuteCommand',
          ($0.ExecuteCommandRequest value) => value.writeToBuffer(),
          $0.ExecuteCommandResponse.fromBuffer);
  static final _$subscribe =
      $grpc.ClientMethod<$0.SubscribeRequest, $0.SubscribeResponse>(
          '/queravue.v1.KeyValueService/Subscribe',
          ($0.SubscribeRequest value) => value.writeToBuffer(),
          $0.SubscribeResponse.fromBuffer);
  static final _$publish =
      $grpc.ClientMethod<$0.PublishRequest, $0.PublishResponse>(
          '/queravue.v1.KeyValueService/Publish',
          ($0.PublishRequest value) => value.writeToBuffer(),
          $0.PublishResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.KeyValueService')
abstract class KeyValueServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.KeyValueService';

  KeyValueServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListKvDatabasesRequest,
            $0.ListKvDatabasesResponse>(
        'ListKvDatabases',
        listKvDatabases_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListKvDatabasesRequest.fromBuffer(value),
        ($0.ListKvDatabasesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ScanKeysRequest, $0.ScanKeysResponse>(
        'ScanKeys',
        scanKeys_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ScanKeysRequest.fromBuffer(value),
        ($0.ScanKeysResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetKeyInfoRequest, $0.GetKeyInfoResponse>(
        'GetKeyInfo',
        getKeyInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetKeyInfoRequest.fromBuffer(value),
        ($0.GetKeyInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReadValueRequest, $0.ReadValueResponse>(
        'ReadValue',
        readValue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReadValueRequest.fromBuffer(value),
        ($0.ReadValueResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WriteValueRequest, $0.WriteValueResponse>(
        'WriteValue',
        writeValue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.WriteValueRequest.fromBuffer(value),
        ($0.WriteValueResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameKeyRequest, $0.RenameKeyResponse>(
        'RenameKey',
        renameKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameKeyRequest.fromBuffer(value),
        ($0.RenameKeyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetExpiryRequest, $0.SetExpiryResponse>(
        'SetExpiry',
        setExpiry_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetExpiryRequest.fromBuffer(value),
        ($0.SetExpiryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteKeysRequest, $0.DeleteKeysResponse>(
        'DeleteKeys',
        deleteKeys_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteKeysRequest.fromBuffer(value),
        ($0.DeleteKeysResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecuteCommandRequest,
            $0.ExecuteCommandResponse>(
        'ExecuteCommand',
        executeCommand_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExecuteCommandRequest.fromBuffer(value),
        ($0.ExecuteCommandResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SubscribeRequest, $0.SubscribeResponse>(
        'Subscribe',
        subscribe_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.SubscribeRequest.fromBuffer(value),
        ($0.SubscribeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PublishRequest, $0.PublishResponse>(
        'Publish',
        publish_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PublishRequest.fromBuffer(value),
        ($0.PublishResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListKvDatabasesResponse> listKvDatabases_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListKvDatabasesRequest> $request) async {
    return listKvDatabases($call, await $request);
  }

  $async.Future<$0.ListKvDatabasesResponse> listKvDatabases(
      $grpc.ServiceCall call, $0.ListKvDatabasesRequest request);

  $async.Stream<$0.ScanKeysResponse> scanKeys_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ScanKeysRequest> $request) async* {
    yield* scanKeys($call, await $request);
  }

  $async.Stream<$0.ScanKeysResponse> scanKeys(
      $grpc.ServiceCall call, $0.ScanKeysRequest request);

  $async.Future<$0.GetKeyInfoResponse> getKeyInfo_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetKeyInfoRequest> $request) async {
    return getKeyInfo($call, await $request);
  }

  $async.Future<$0.GetKeyInfoResponse> getKeyInfo(
      $grpc.ServiceCall call, $0.GetKeyInfoRequest request);

  $async.Future<$0.ReadValueResponse> readValue_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadValueRequest> $request) async {
    return readValue($call, await $request);
  }

  $async.Future<$0.ReadValueResponse> readValue(
      $grpc.ServiceCall call, $0.ReadValueRequest request);

  $async.Future<$0.WriteValueResponse> writeValue_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WriteValueRequest> $request) async {
    return writeValue($call, await $request);
  }

  $async.Future<$0.WriteValueResponse> writeValue(
      $grpc.ServiceCall call, $0.WriteValueRequest request);

  $async.Future<$0.RenameKeyResponse> renameKey_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RenameKeyRequest> $request) async {
    return renameKey($call, await $request);
  }

  $async.Future<$0.RenameKeyResponse> renameKey(
      $grpc.ServiceCall call, $0.RenameKeyRequest request);

  $async.Future<$0.SetExpiryResponse> setExpiry_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetExpiryRequest> $request) async {
    return setExpiry($call, await $request);
  }

  $async.Future<$0.SetExpiryResponse> setExpiry(
      $grpc.ServiceCall call, $0.SetExpiryRequest request);

  $async.Future<$0.DeleteKeysResponse> deleteKeys_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteKeysRequest> $request) async {
    return deleteKeys($call, await $request);
  }

  $async.Future<$0.DeleteKeysResponse> deleteKeys(
      $grpc.ServiceCall call, $0.DeleteKeysRequest request);

  $async.Future<$0.ExecuteCommandResponse> executeCommand_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExecuteCommandRequest> $request) async {
    return executeCommand($call, await $request);
  }

  $async.Future<$0.ExecuteCommandResponse> executeCommand(
      $grpc.ServiceCall call, $0.ExecuteCommandRequest request);

  $async.Stream<$0.SubscribeResponse> subscribe_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SubscribeRequest> $request) async* {
    yield* subscribe($call, await $request);
  }

  $async.Stream<$0.SubscribeResponse> subscribe(
      $grpc.ServiceCall call, $0.SubscribeRequest request);

  $async.Future<$0.PublishResponse> publish_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PublishRequest> $request) async {
    return publish($call, await $request);
  }

  $async.Future<$0.PublishResponse> publish(
      $grpc.ServiceCall call, $0.PublishRequest request);
}
