// This is a generated file - do not edit.
//
// Generated from queravue/v1/transfer.proto.

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

import 'transfer.pb.dart' as $0;

export 'transfer.pb.dart';

/// TransferService imports files into tables and collections and exports
/// results, tables and collections to files (ADR 0024).
///
/// File bytes always stream in chunks of at most 1 MiB; neither side holds a
/// whole file. The app reads and writes the files; the core never opens a path
/// sent by the UI. Failures the user can act on are returned in-band as
/// TransferError. Unknown sessions or results are NOT_FOUND and sessions
/// without the needed capability are FAILED_PRECONDITION.
@$pb.GrpcServiceName('queravue.v1.TransferService')
class TransferServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TransferServiceClient(super.channel, {super.options, super.interceptors});

  /// ListFormats returns the formats this core build can import and export.
  /// Parquet is listed only when the core is built with DuckDB.
  $grpc.ResponseFuture<$0.ListFormatsResponse> listFormats(
    $0.ListFormatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listFormats, request, options: options);
  }

  /// ExportResult encodes a spooled query result. Cancelling the call stops
  /// the export.
  $grpc.ResponseStream<$0.ExportResultResponse> exportResult(
    $0.ExportResultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$exportResult, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// ExportTable encodes a table, optionally filtered and sorted, without
  /// spooling it. Needs the "execute" capability.
  $grpc.ResponseStream<$0.ExportTableResponse> exportTable(
    $0.ExportTableRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$exportTable, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// ExportCollection encodes a collection's documents. Needs the
  /// "document_store" capability.
  $grpc.ResponseStream<$0.ExportCollectionResponse> exportCollection(
    $0.ExportCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$exportCollection, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// InferImport reads the first bytes of a file and proposes its format,
  /// columns, types and a preview. The first message carries the header,
  /// every later one a chunk; the app sends at most a few MiB and closes.
  $grpc.ResponseFuture<$0.InferImportResponse> inferImport(
    $async.Stream<$0.InferImportRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$inferImport, request, options: options)
        .single;
  }

  /// Import loads a file into a table or collection. The first message carries
  /// the header, every later one a chunk. Progress and the summary stream back.
  /// Cancelling the call stops after the current batch; committed batches stay.
  $grpc.ResponseStream<$0.ImportResponse> import(
    $async.Stream<$0.ImportRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$import, request, options: options);
  }

  // method descriptors

  static final _$listFormats =
      $grpc.ClientMethod<$0.ListFormatsRequest, $0.ListFormatsResponse>(
          '/queravue.v1.TransferService/ListFormats',
          ($0.ListFormatsRequest value) => value.writeToBuffer(),
          $0.ListFormatsResponse.fromBuffer);
  static final _$exportResult =
      $grpc.ClientMethod<$0.ExportResultRequest, $0.ExportResultResponse>(
          '/queravue.v1.TransferService/ExportResult',
          ($0.ExportResultRequest value) => value.writeToBuffer(),
          $0.ExportResultResponse.fromBuffer);
  static final _$exportTable =
      $grpc.ClientMethod<$0.ExportTableRequest, $0.ExportTableResponse>(
          '/queravue.v1.TransferService/ExportTable',
          ($0.ExportTableRequest value) => value.writeToBuffer(),
          $0.ExportTableResponse.fromBuffer);
  static final _$exportCollection = $grpc.ClientMethod<
          $0.ExportCollectionRequest, $0.ExportCollectionResponse>(
      '/queravue.v1.TransferService/ExportCollection',
      ($0.ExportCollectionRequest value) => value.writeToBuffer(),
      $0.ExportCollectionResponse.fromBuffer);
  static final _$inferImport =
      $grpc.ClientMethod<$0.InferImportRequest, $0.InferImportResponse>(
          '/queravue.v1.TransferService/InferImport',
          ($0.InferImportRequest value) => value.writeToBuffer(),
          $0.InferImportResponse.fromBuffer);
  static final _$import =
      $grpc.ClientMethod<$0.ImportRequest, $0.ImportResponse>(
          '/queravue.v1.TransferService/Import',
          ($0.ImportRequest value) => value.writeToBuffer(),
          $0.ImportResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.TransferService')
abstract class TransferServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.TransferService';

  TransferServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListFormatsRequest, $0.ListFormatsResponse>(
            'ListFormats',
            listFormats_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListFormatsRequest.fromBuffer(value),
            ($0.ListFormatsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExportResultRequest, $0.ExportResultResponse>(
            'ExportResult',
            exportResult_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ExportResultRequest.fromBuffer(value),
            ($0.ExportResultResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExportTableRequest, $0.ExportTableResponse>(
            'ExportTable',
            exportTable_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.ExportTableRequest.fromBuffer(value),
            ($0.ExportTableResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportCollectionRequest,
            $0.ExportCollectionResponse>(
        'ExportCollection',
        exportCollection_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.ExportCollectionRequest.fromBuffer(value),
        ($0.ExportCollectionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.InferImportRequest, $0.InferImportResponse>(
            'InferImport',
            inferImport,
            true,
            false,
            ($core.List<$core.int> value) =>
                $0.InferImportRequest.fromBuffer(value),
            ($0.InferImportResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ImportRequest, $0.ImportResponse>(
        'Import',
        import,
        true,
        true,
        ($core.List<$core.int> value) => $0.ImportRequest.fromBuffer(value),
        ($0.ImportResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListFormatsResponse> listFormats_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListFormatsRequest> $request) async {
    return listFormats($call, await $request);
  }

  $async.Future<$0.ListFormatsResponse> listFormats(
      $grpc.ServiceCall call, $0.ListFormatsRequest request);

  $async.Stream<$0.ExportResultResponse> exportResult_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExportResultRequest> $request) async* {
    yield* exportResult($call, await $request);
  }

  $async.Stream<$0.ExportResultResponse> exportResult(
      $grpc.ServiceCall call, $0.ExportResultRequest request);

  $async.Stream<$0.ExportTableResponse> exportTable_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExportTableRequest> $request) async* {
    yield* exportTable($call, await $request);
  }

  $async.Stream<$0.ExportTableResponse> exportTable(
      $grpc.ServiceCall call, $0.ExportTableRequest request);

  $async.Stream<$0.ExportCollectionResponse> exportCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExportCollectionRequest> $request) async* {
    yield* exportCollection($call, await $request);
  }

  $async.Stream<$0.ExportCollectionResponse> exportCollection(
      $grpc.ServiceCall call, $0.ExportCollectionRequest request);

  $async.Future<$0.InferImportResponse> inferImport(
      $grpc.ServiceCall call, $async.Stream<$0.InferImportRequest> request);

  $async.Stream<$0.ImportResponse> import(
      $grpc.ServiceCall call, $async.Stream<$0.ImportRequest> request);
}
