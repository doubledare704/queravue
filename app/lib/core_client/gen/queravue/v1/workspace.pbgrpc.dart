// This is a generated file - do not edit.
//
// Generated from queravue/v1/workspace.proto.

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

import 'workspace.pb.dart' as $0;

export 'workspace.pb.dart';

/// WorkspaceService reads, writes, searches and watches saved queries and
/// scripts stored as plain files in workspace folders (ADR 0011).
///
/// Paths are a root id plus a slash-separated path relative to the root.
/// Failures are reported in-band as WorkspaceError.
@$pb.GrpcServiceName('queravue.v1.WorkspaceService')
class WorkspaceServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  WorkspaceServiceClient(super.channel, {super.options, super.interceptors});

  /// GetRoots lists the configured workspace roots.
  $grpc.ResponseFuture<$0.GetRootsResponse> getRoots(
    $0.GetRootsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRoots, request, options: options);
  }

  /// SetRoots replaces the list of roots. Missing folders are created.
  $grpc.ResponseFuture<$0.SetRootsResponse> setRoots(
    $0.SetRootsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRoots, request, options: options);
  }

  /// ListTree lists the entries of one directory.
  $grpc.ResponseFuture<$0.ListTreeResponse> listTree(
    $0.ListTreeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listTree, request, options: options);
  }

  /// Read returns a file with its mtime and content hash.
  $grpc.ResponseFuture<$0.ReadResponse> read(
    $0.ReadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$read, request, options: options);
  }

  /// Write replaces a file atomically. With expected_mtime or expected_hash
  /// set, it only writes if the file on disk still matches; otherwise it
  /// returns a CONFLICT error with the current file.
  $grpc.ResponseFuture<$0.WriteResponse> write(
    $0.WriteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$write, request, options: options);
  }

  /// Create makes a new file or folder. ALREADY_EXISTS if the path exists.
  $grpc.ResponseFuture<$0.CreateResponse> create(
    $0.CreateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$create, request, options: options);
  }

  /// Rename renames or moves a file or folder inside one root.
  $grpc.ResponseFuture<$0.RenameResponse> rename(
    $0.RenameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rename, request, options: options);
  }

  /// Delete removes a file or a folder with its contents.
  $grpc.ResponseFuture<$0.DeleteResponse> delete(
    $0.DeleteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$delete, request, options: options);
  }

  /// Search streams the files matching the text and tags as they are found.
  /// Cancelling the call stops the search.
  $grpc.ResponseStream<$0.SearchResponse> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$search, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Watch streams changes made on disk, by the app or anything else, until
  /// the client cancels.
  $grpc.ResponseStream<$0.WatchResponse> watch(
    $0.WatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$watch, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getRoots =
      $grpc.ClientMethod<$0.GetRootsRequest, $0.GetRootsResponse>(
          '/queravue.v1.WorkspaceService/GetRoots',
          ($0.GetRootsRequest value) => value.writeToBuffer(),
          $0.GetRootsResponse.fromBuffer);
  static final _$setRoots =
      $grpc.ClientMethod<$0.SetRootsRequest, $0.SetRootsResponse>(
          '/queravue.v1.WorkspaceService/SetRoots',
          ($0.SetRootsRequest value) => value.writeToBuffer(),
          $0.SetRootsResponse.fromBuffer);
  static final _$listTree =
      $grpc.ClientMethod<$0.ListTreeRequest, $0.ListTreeResponse>(
          '/queravue.v1.WorkspaceService/ListTree',
          ($0.ListTreeRequest value) => value.writeToBuffer(),
          $0.ListTreeResponse.fromBuffer);
  static final _$read = $grpc.ClientMethod<$0.ReadRequest, $0.ReadResponse>(
      '/queravue.v1.WorkspaceService/Read',
      ($0.ReadRequest value) => value.writeToBuffer(),
      $0.ReadResponse.fromBuffer);
  static final _$write = $grpc.ClientMethod<$0.WriteRequest, $0.WriteResponse>(
      '/queravue.v1.WorkspaceService/Write',
      ($0.WriteRequest value) => value.writeToBuffer(),
      $0.WriteResponse.fromBuffer);
  static final _$create =
      $grpc.ClientMethod<$0.CreateRequest, $0.CreateResponse>(
          '/queravue.v1.WorkspaceService/Create',
          ($0.CreateRequest value) => value.writeToBuffer(),
          $0.CreateResponse.fromBuffer);
  static final _$rename =
      $grpc.ClientMethod<$0.RenameRequest, $0.RenameResponse>(
          '/queravue.v1.WorkspaceService/Rename',
          ($0.RenameRequest value) => value.writeToBuffer(),
          $0.RenameResponse.fromBuffer);
  static final _$delete =
      $grpc.ClientMethod<$0.DeleteRequest, $0.DeleteResponse>(
          '/queravue.v1.WorkspaceService/Delete',
          ($0.DeleteRequest value) => value.writeToBuffer(),
          $0.DeleteResponse.fromBuffer);
  static final _$search =
      $grpc.ClientMethod<$0.SearchRequest, $0.SearchResponse>(
          '/queravue.v1.WorkspaceService/Search',
          ($0.SearchRequest value) => value.writeToBuffer(),
          $0.SearchResponse.fromBuffer);
  static final _$watch = $grpc.ClientMethod<$0.WatchRequest, $0.WatchResponse>(
      '/queravue.v1.WorkspaceService/Watch',
      ($0.WatchRequest value) => value.writeToBuffer(),
      $0.WatchResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.WorkspaceService')
abstract class WorkspaceServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.WorkspaceService';

  WorkspaceServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetRootsRequest, $0.GetRootsResponse>(
        'GetRoots',
        getRoots_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetRootsRequest.fromBuffer(value),
        ($0.GetRootsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetRootsRequest, $0.SetRootsResponse>(
        'SetRoots',
        setRoots_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetRootsRequest.fromBuffer(value),
        ($0.SetRootsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTreeRequest, $0.ListTreeResponse>(
        'ListTree',
        listTree_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTreeRequest.fromBuffer(value),
        ($0.ListTreeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReadRequest, $0.ReadResponse>(
        'Read',
        read_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReadRequest.fromBuffer(value),
        ($0.ReadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WriteRequest, $0.WriteResponse>(
        'Write',
        write_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.WriteRequest.fromBuffer(value),
        ($0.WriteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateRequest, $0.CreateResponse>(
        'Create',
        create_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateRequest.fromBuffer(value),
        ($0.CreateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameRequest, $0.RenameResponse>(
        'Rename',
        rename_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameRequest.fromBuffer(value),
        ($0.RenameResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteRequest, $0.DeleteResponse>(
        'Delete',
        delete_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteRequest.fromBuffer(value),
        ($0.DeleteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.SearchResponse>(
        'Search',
        search_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.SearchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchRequest, $0.WatchResponse>(
        'Watch',
        watch_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchRequest.fromBuffer(value),
        ($0.WatchResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetRootsResponse> getRoots_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetRootsRequest> $request) async {
    return getRoots($call, await $request);
  }

  $async.Future<$0.GetRootsResponse> getRoots(
      $grpc.ServiceCall call, $0.GetRootsRequest request);

  $async.Future<$0.SetRootsResponse> setRoots_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetRootsRequest> $request) async {
    return setRoots($call, await $request);
  }

  $async.Future<$0.SetRootsResponse> setRoots(
      $grpc.ServiceCall call, $0.SetRootsRequest request);

  $async.Future<$0.ListTreeResponse> listTree_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListTreeRequest> $request) async {
    return listTree($call, await $request);
  }

  $async.Future<$0.ListTreeResponse> listTree(
      $grpc.ServiceCall call, $0.ListTreeRequest request);

  $async.Future<$0.ReadResponse> read_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ReadRequest> $request) async {
    return read($call, await $request);
  }

  $async.Future<$0.ReadResponse> read(
      $grpc.ServiceCall call, $0.ReadRequest request);

  $async.Future<$0.WriteResponse> write_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WriteRequest> $request) async {
    return write($call, await $request);
  }

  $async.Future<$0.WriteResponse> write(
      $grpc.ServiceCall call, $0.WriteRequest request);

  $async.Future<$0.CreateResponse> create_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CreateRequest> $request) async {
    return create($call, await $request);
  }

  $async.Future<$0.CreateResponse> create(
      $grpc.ServiceCall call, $0.CreateRequest request);

  $async.Future<$0.RenameResponse> rename_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RenameRequest> $request) async {
    return rename($call, await $request);
  }

  $async.Future<$0.RenameResponse> rename(
      $grpc.ServiceCall call, $0.RenameRequest request);

  $async.Future<$0.DeleteResponse> delete_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DeleteRequest> $request) async {
    return delete($call, await $request);
  }

  $async.Future<$0.DeleteResponse> delete(
      $grpc.ServiceCall call, $0.DeleteRequest request);

  $async.Stream<$0.SearchResponse> search_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SearchRequest> $request) async* {
    yield* search($call, await $request);
  }

  $async.Stream<$0.SearchResponse> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Stream<$0.WatchResponse> watch_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WatchRequest> $request) async* {
    yield* watch($call, await $request);
  }

  $async.Stream<$0.WatchResponse> watch(
      $grpc.ServiceCall call, $0.WatchRequest request);
}
