// This is a generated file - do not edit.
//
// Generated from queravue/v1/document.proto.

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

import 'document.pb.dart' as $0;

export 'document.pb.dart';

/// DocumentService browses and edits documents of engines with the
/// "document_store" capability (MongoDB and wire-compatible servers).
///
/// Every document, _id, filter, sort and projection travels as text in
/// MongoDB Extended JSON v2. Documents and _id values are CANONICAL EJSON, so
/// every BSON type survives a round trip (ADR 0009). Filter, sort and
/// projection also accept relaxed EJSON. Databases and collections are listed
/// through SchemaService.
///
/// Operational failures that the UI shows next to the input (parse errors,
/// write conflicts, confirmation required) are reported in-band as
/// DocumentError. Unknown sessions are NOT_FOUND and sessions whose engine has
/// no document_store capability are FAILED_PRECONDITION.
@$pb.GrpcServiceName('queravue.v1.DocumentService')
class DocumentServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DocumentServiceClient(super.channel, {super.options, super.interceptors});

  /// Find streams the documents matching `filter`, `batch_size` documents (or
  /// about 2 MiB) at a time. The last batch has done=true. Cancelling the call
  /// kills the server-side cursor. A failure ends the stream with an error
  /// event.
  $grpc.ResponseStream<$0.FindResponse> find(
    $0.FindRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$find, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Count returns the number of matching documents: an estimate when the
  /// filter is empty, exact otherwise.
  $grpc.ResponseFuture<$0.CountResponse> count(
    $0.CountRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$count, request, options: options);
  }

  /// InsertDocuments inserts documents. Documents without _id get an ObjectId.
  $grpc.ResponseFuture<$0.InsertDocumentsResponse> insertDocuments(
    $0.InsertDocumentsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$insertDocuments, request, options: options);
  }

  /// ReplaceDocument replaces the document with the given _id. With
  /// expected_document set, the write only happens if the stored document still
  /// equals it; otherwise a CONFLICT error carries the current document.
  $grpc.ResponseFuture<$0.ReplaceDocumentResponse> replaceDocument(
    $0.ReplaceDocumentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$replaceDocument, request, options: options);
  }

  /// UpdateFields sets and unsets top-level or dotted fields of one document,
  /// leaving other fields untouched. Optimistic concurrency works as in
  /// ReplaceDocument.
  $grpc.ResponseFuture<$0.UpdateFieldsResponse> updateFields(
    $0.UpdateFieldsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateFields, request, options: options);
  }

  /// DeleteDocuments deletes documents by _id.
  $grpc.ResponseFuture<$0.DeleteDocumentsResponse> deleteDocuments(
    $0.DeleteDocumentsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteDocuments, request, options: options);
  }

  /// SampleFields samples a collection and reports its top-level fields, the
  /// types seen and how often they occur. The UI uses it to build table-view
  /// columns.
  $grpc.ResponseFuture<$0.SampleFieldsResponse> sampleFields(
    $0.SampleFieldsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sampleFields, request, options: options);
  }

  /// SampleFieldPaths samples a collection and reports nested field paths
  /// (address.city, tags.[], items.[].sku) with types and frequency. Editor
  /// completion uses it. Results are cached per collection for a short time.
  $grpc.ResponseFuture<$0.SampleFieldPathsResponse> sampleFieldPaths(
    $0.SampleFieldPathsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sampleFieldPaths, request, options: options);
  }

  // method descriptors

  static final _$find = $grpc.ClientMethod<$0.FindRequest, $0.FindResponse>(
      '/queravue.v1.DocumentService/Find',
      ($0.FindRequest value) => value.writeToBuffer(),
      $0.FindResponse.fromBuffer);
  static final _$count = $grpc.ClientMethod<$0.CountRequest, $0.CountResponse>(
      '/queravue.v1.DocumentService/Count',
      ($0.CountRequest value) => value.writeToBuffer(),
      $0.CountResponse.fromBuffer);
  static final _$insertDocuments =
      $grpc.ClientMethod<$0.InsertDocumentsRequest, $0.InsertDocumentsResponse>(
          '/queravue.v1.DocumentService/InsertDocuments',
          ($0.InsertDocumentsRequest value) => value.writeToBuffer(),
          $0.InsertDocumentsResponse.fromBuffer);
  static final _$replaceDocument =
      $grpc.ClientMethod<$0.ReplaceDocumentRequest, $0.ReplaceDocumentResponse>(
          '/queravue.v1.DocumentService/ReplaceDocument',
          ($0.ReplaceDocumentRequest value) => value.writeToBuffer(),
          $0.ReplaceDocumentResponse.fromBuffer);
  static final _$updateFields =
      $grpc.ClientMethod<$0.UpdateFieldsRequest, $0.UpdateFieldsResponse>(
          '/queravue.v1.DocumentService/UpdateFields',
          ($0.UpdateFieldsRequest value) => value.writeToBuffer(),
          $0.UpdateFieldsResponse.fromBuffer);
  static final _$deleteDocuments =
      $grpc.ClientMethod<$0.DeleteDocumentsRequest, $0.DeleteDocumentsResponse>(
          '/queravue.v1.DocumentService/DeleteDocuments',
          ($0.DeleteDocumentsRequest value) => value.writeToBuffer(),
          $0.DeleteDocumentsResponse.fromBuffer);
  static final _$sampleFields =
      $grpc.ClientMethod<$0.SampleFieldsRequest, $0.SampleFieldsResponse>(
          '/queravue.v1.DocumentService/SampleFields',
          ($0.SampleFieldsRequest value) => value.writeToBuffer(),
          $0.SampleFieldsResponse.fromBuffer);
  static final _$sampleFieldPaths = $grpc.ClientMethod<
          $0.SampleFieldPathsRequest, $0.SampleFieldPathsResponse>(
      '/queravue.v1.DocumentService/SampleFieldPaths',
      ($0.SampleFieldPathsRequest value) => value.writeToBuffer(),
      $0.SampleFieldPathsResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.DocumentService')
abstract class DocumentServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.DocumentService';

  DocumentServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.FindRequest, $0.FindResponse>(
        'Find',
        find_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.FindRequest.fromBuffer(value),
        ($0.FindResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CountRequest, $0.CountResponse>(
        'Count',
        count_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CountRequest.fromBuffer(value),
        ($0.CountResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InsertDocumentsRequest,
            $0.InsertDocumentsResponse>(
        'InsertDocuments',
        insertDocuments_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InsertDocumentsRequest.fromBuffer(value),
        ($0.InsertDocumentsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReplaceDocumentRequest,
            $0.ReplaceDocumentResponse>(
        'ReplaceDocument',
        replaceDocument_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReplaceDocumentRequest.fromBuffer(value),
        ($0.ReplaceDocumentResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateFieldsRequest, $0.UpdateFieldsResponse>(
            'UpdateFields',
            updateFields_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateFieldsRequest.fromBuffer(value),
            ($0.UpdateFieldsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteDocumentsRequest,
            $0.DeleteDocumentsResponse>(
        'DeleteDocuments',
        deleteDocuments_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteDocumentsRequest.fromBuffer(value),
        ($0.DeleteDocumentsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SampleFieldsRequest, $0.SampleFieldsResponse>(
            'SampleFields',
            sampleFields_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SampleFieldsRequest.fromBuffer(value),
            ($0.SampleFieldsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SampleFieldPathsRequest,
            $0.SampleFieldPathsResponse>(
        'SampleFieldPaths',
        sampleFieldPaths_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SampleFieldPathsRequest.fromBuffer(value),
        ($0.SampleFieldPathsResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.FindResponse> find_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FindRequest> $request) async* {
    yield* find($call, await $request);
  }

  $async.Stream<$0.FindResponse> find(
      $grpc.ServiceCall call, $0.FindRequest request);

  $async.Future<$0.CountResponse> count_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CountRequest> $request) async {
    return count($call, await $request);
  }

  $async.Future<$0.CountResponse> count(
      $grpc.ServiceCall call, $0.CountRequest request);

  $async.Future<$0.InsertDocumentsResponse> insertDocuments_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InsertDocumentsRequest> $request) async {
    return insertDocuments($call, await $request);
  }

  $async.Future<$0.InsertDocumentsResponse> insertDocuments(
      $grpc.ServiceCall call, $0.InsertDocumentsRequest request);

  $async.Future<$0.ReplaceDocumentResponse> replaceDocument_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReplaceDocumentRequest> $request) async {
    return replaceDocument($call, await $request);
  }

  $async.Future<$0.ReplaceDocumentResponse> replaceDocument(
      $grpc.ServiceCall call, $0.ReplaceDocumentRequest request);

  $async.Future<$0.UpdateFieldsResponse> updateFields_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateFieldsRequest> $request) async {
    return updateFields($call, await $request);
  }

  $async.Future<$0.UpdateFieldsResponse> updateFields(
      $grpc.ServiceCall call, $0.UpdateFieldsRequest request);

  $async.Future<$0.DeleteDocumentsResponse> deleteDocuments_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteDocumentsRequest> $request) async {
    return deleteDocuments($call, await $request);
  }

  $async.Future<$0.DeleteDocumentsResponse> deleteDocuments(
      $grpc.ServiceCall call, $0.DeleteDocumentsRequest request);

  $async.Future<$0.SampleFieldsResponse> sampleFields_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SampleFieldsRequest> $request) async {
    return sampleFields($call, await $request);
  }

  $async.Future<$0.SampleFieldsResponse> sampleFields(
      $grpc.ServiceCall call, $0.SampleFieldsRequest request);

  $async.Future<$0.SampleFieldPathsResponse> sampleFieldPaths_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SampleFieldPathsRequest> $request) async {
    return sampleFieldPaths($call, await $request);
  }

  $async.Future<$0.SampleFieldPathsResponse> sampleFieldPaths(
      $grpc.ServiceCall call, $0.SampleFieldPathsRequest request);
}
