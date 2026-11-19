// This is a generated file - do not edit.
//
// Generated from queravue/v1/gridfs.proto.

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

import 'gridfs.pb.dart' as $0;

export 'gridfs.pb.dart';

/// GridFsService browses, previews, uploads and downloads files stored in
/// MongoDB GridFS buckets, for sessions whose engine has the "gridfs"
/// capability (ADR 0023).
///
/// File bytes always stream in chunks of at most 1 MiB; neither side holds a
/// whole file. File ids travel as canonical EJSON. Failures the user can act
/// on are returned in-band as GridFsError. Unknown sessions are NOT_FOUND and
/// sessions without the capability are FAILED_PRECONDITION.
@$pb.GrpcServiceName('queravue.v1.GridFsService')
class GridFsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GridFsServiceClient(super.channel, {super.options, super.interceptors});

  /// ListBuckets returns the buckets of a database: every <name>.files
  /// collection that has a matching <name>.chunks collection.
  $grpc.ResponseFuture<$0.ListBucketsResponse> listBuckets(
    $0.ListBucketsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listBuckets, request, options: options);
  }

  /// ListFiles streams one page of a bucket's files in batches. The last batch
  /// has done=true. Cancelling the call closes the cursor.
  $grpc.ResponseStream<$0.ListFilesResponse> listFiles(
    $0.ListFilesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$listFiles, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Download streams the file header and then its bytes, optionally a range.
  /// Cancelling the call stops reading chunks.
  $grpc.ResponseStream<$0.DownloadResponse> download(
    $0.DownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$download, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Upload stores a new file, or replaces one. The first message carries the
  /// header, every later one a chunk of bytes. A cancelled or failed upload
  /// removes the chunks it wrote.
  $grpc.ResponseFuture<$0.UploadResponse> upload(
    $async.Stream<$0.UploadRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$upload, request, options: options).single;
  }

  /// DeleteFile removes a file and its chunks. Needs confirmed=true on
  /// production connections.
  $grpc.ResponseFuture<$0.DeleteFileResponse> deleteFile(
    $0.DeleteFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteFile, request, options: options);
  }

  /// RenameFile changes a file's filename.
  $grpc.ResponseFuture<$0.RenameFileResponse> renameFile(
    $0.RenameFileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameFile, request, options: options);
  }

  // method descriptors

  static final _$listBuckets =
      $grpc.ClientMethod<$0.ListBucketsRequest, $0.ListBucketsResponse>(
          '/queravue.v1.GridFsService/ListBuckets',
          ($0.ListBucketsRequest value) => value.writeToBuffer(),
          $0.ListBucketsResponse.fromBuffer);
  static final _$listFiles =
      $grpc.ClientMethod<$0.ListFilesRequest, $0.ListFilesResponse>(
          '/queravue.v1.GridFsService/ListFiles',
          ($0.ListFilesRequest value) => value.writeToBuffer(),
          $0.ListFilesResponse.fromBuffer);
  static final _$download =
      $grpc.ClientMethod<$0.DownloadRequest, $0.DownloadResponse>(
          '/queravue.v1.GridFsService/Download',
          ($0.DownloadRequest value) => value.writeToBuffer(),
          $0.DownloadResponse.fromBuffer);
  static final _$upload =
      $grpc.ClientMethod<$0.UploadRequest, $0.UploadResponse>(
          '/queravue.v1.GridFsService/Upload',
          ($0.UploadRequest value) => value.writeToBuffer(),
          $0.UploadResponse.fromBuffer);
  static final _$deleteFile =
      $grpc.ClientMethod<$0.DeleteFileRequest, $0.DeleteFileResponse>(
          '/queravue.v1.GridFsService/DeleteFile',
          ($0.DeleteFileRequest value) => value.writeToBuffer(),
          $0.DeleteFileResponse.fromBuffer);
  static final _$renameFile =
      $grpc.ClientMethod<$0.RenameFileRequest, $0.RenameFileResponse>(
          '/queravue.v1.GridFsService/RenameFile',
          ($0.RenameFileRequest value) => value.writeToBuffer(),
          $0.RenameFileResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.GridFsService')
abstract class GridFsServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.GridFsService';

  GridFsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListBucketsRequest, $0.ListBucketsResponse>(
            'ListBuckets',
            listBuckets_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListBucketsRequest.fromBuffer(value),
            ($0.ListBucketsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListFilesRequest, $0.ListFilesResponse>(
        'ListFiles',
        listFiles_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ListFilesRequest.fromBuffer(value),
        ($0.ListFilesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadRequest, $0.DownloadResponse>(
        'Download',
        download_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.DownloadRequest.fromBuffer(value),
        ($0.DownloadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadRequest, $0.UploadResponse>(
        'Upload',
        upload,
        true,
        false,
        ($core.List<$core.int> value) => $0.UploadRequest.fromBuffer(value),
        ($0.UploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteFileRequest, $0.DeleteFileResponse>(
        'DeleteFile',
        deleteFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteFileRequest.fromBuffer(value),
        ($0.DeleteFileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameFileRequest, $0.RenameFileResponse>(
        'RenameFile',
        renameFile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameFileRequest.fromBuffer(value),
        ($0.RenameFileResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListBucketsResponse> listBuckets_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListBucketsRequest> $request) async {
    return listBuckets($call, await $request);
  }

  $async.Future<$0.ListBucketsResponse> listBuckets(
      $grpc.ServiceCall call, $0.ListBucketsRequest request);

  $async.Stream<$0.ListFilesResponse> listFiles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListFilesRequest> $request) async* {
    yield* listFiles($call, await $request);
  }

  $async.Stream<$0.ListFilesResponse> listFiles(
      $grpc.ServiceCall call, $0.ListFilesRequest request);

  $async.Stream<$0.DownloadResponse> download_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadRequest> $request) async* {
    yield* download($call, await $request);
  }

  $async.Stream<$0.DownloadResponse> download(
      $grpc.ServiceCall call, $0.DownloadRequest request);

  $async.Future<$0.UploadResponse> upload(
      $grpc.ServiceCall call, $async.Stream<$0.UploadRequest> request);

  $async.Future<$0.DeleteFileResponse> deleteFile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteFileRequest> $request) async {
    return deleteFile($call, await $request);
  }

  $async.Future<$0.DeleteFileResponse> deleteFile(
      $grpc.ServiceCall call, $0.DeleteFileRequest request);

  $async.Future<$0.RenameFileResponse> renameFile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RenameFileRequest> $request) async {
    return renameFile($call, await $request);
  }

  $async.Future<$0.RenameFileResponse> renameFile(
      $grpc.ServiceCall call, $0.RenameFileRequest request);
}
