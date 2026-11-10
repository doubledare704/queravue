// This is a generated file - do not edit.
//
// Generated from queravue/v1/diagram.proto.

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

import 'diagram.pb.dart' as $0;

export 'diagram.pb.dart';

/// DiagramService feeds schema diagrams and applies what was designed on one
/// (ADR 0017). The UI enables it from the "schema_graph" capability and never
/// from engine ids.
///
/// Failures are returned in-band as AdminError so streams and transport stay
/// healthy. Unknown sessions are NOT_FOUND.
@$pb.GrpcServiceName('queravue.v1.DiagramService')
class DiagramServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DiagramServiceClient(super.channel, {super.options, super.interceptors});

  /// GetSchemaGraph streams every table of a schema with its columns and
  /// relations, in batches, using one query per kind of object rather than one
  /// per table. On document stores it samples each collection and infers the
  /// relations. The last message has done=true. Cancel the call to stop it.
  $grpc.ResponseStream<$0.GetSchemaGraphResponse> getSchemaGraph(
    $0.GetSchemaGraphRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getSchemaGraph, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// PreviewDiagramDDL returns the DDL for changes to several tables without
  /// running it. The core orders the statements so that tables exist before
  /// the foreign keys that point at them.
  $grpc.ResponseFuture<$0.PreviewDiagramDDLResponse> previewDiagramDDL(
    $0.PreviewDiagramDDLRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewDiagramDDL, request, options: options);
  }

  /// ApplyDiagramDDL runs the DDL for changes to several tables, in the order
  /// PreviewDiagramDDL reports. It needs confirmed=true for destructive
  /// statements and on connections flagged production.
  $grpc.ResponseFuture<$0.ApplyDiagramDDLResponse> applyDiagramDDL(
    $0.ApplyDiagramDDLRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyDiagramDDL, request, options: options);
  }

  // method descriptors

  static final _$getSchemaGraph =
      $grpc.ClientMethod<$0.GetSchemaGraphRequest, $0.GetSchemaGraphResponse>(
          '/queravue.v1.DiagramService/GetSchemaGraph',
          ($0.GetSchemaGraphRequest value) => value.writeToBuffer(),
          $0.GetSchemaGraphResponse.fromBuffer);
  static final _$previewDiagramDDL = $grpc.ClientMethod<
          $0.PreviewDiagramDDLRequest, $0.PreviewDiagramDDLResponse>(
      '/queravue.v1.DiagramService/PreviewDiagramDDL',
      ($0.PreviewDiagramDDLRequest value) => value.writeToBuffer(),
      $0.PreviewDiagramDDLResponse.fromBuffer);
  static final _$applyDiagramDDL =
      $grpc.ClientMethod<$0.ApplyDiagramDDLRequest, $0.ApplyDiagramDDLResponse>(
          '/queravue.v1.DiagramService/ApplyDiagramDDL',
          ($0.ApplyDiagramDDLRequest value) => value.writeToBuffer(),
          $0.ApplyDiagramDDLResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.DiagramService')
abstract class DiagramServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.DiagramService';

  DiagramServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetSchemaGraphRequest,
            $0.GetSchemaGraphResponse>(
        'GetSchemaGraph',
        getSchemaGraph_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.GetSchemaGraphRequest.fromBuffer(value),
        ($0.GetSchemaGraphResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PreviewDiagramDDLRequest,
            $0.PreviewDiagramDDLResponse>(
        'PreviewDiagramDDL',
        previewDiagramDDL_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PreviewDiagramDDLRequest.fromBuffer(value),
        ($0.PreviewDiagramDDLResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApplyDiagramDDLRequest,
            $0.ApplyDiagramDDLResponse>(
        'ApplyDiagramDDL',
        applyDiagramDDL_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ApplyDiagramDDLRequest.fromBuffer(value),
        ($0.ApplyDiagramDDLResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.GetSchemaGraphResponse> getSchemaGraph_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSchemaGraphRequest> $request) async* {
    yield* getSchemaGraph($call, await $request);
  }

  $async.Stream<$0.GetSchemaGraphResponse> getSchemaGraph(
      $grpc.ServiceCall call, $0.GetSchemaGraphRequest request);

  $async.Future<$0.PreviewDiagramDDLResponse> previewDiagramDDL_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PreviewDiagramDDLRequest> $request) async {
    return previewDiagramDDL($call, await $request);
  }

  $async.Future<$0.PreviewDiagramDDLResponse> previewDiagramDDL(
      $grpc.ServiceCall call, $0.PreviewDiagramDDLRequest request);

  $async.Future<$0.ApplyDiagramDDLResponse> applyDiagramDDL_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApplyDiagramDDLRequest> $request) async {
    return applyDiagramDDL($call, await $request);
  }

  $async.Future<$0.ApplyDiagramDDLResponse> applyDiagramDDL(
      $grpc.ServiceCall call, $0.ApplyDiagramDDLRequest request);
}
