// This is a generated file - do not edit.
//
// Generated from queravue/v1/design.proto.

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

import 'design.pb.dart' as $0;

export 'design.pb.dart';

/// SchemaDesignService turns structured table changes into dialect-specific DDL
/// and runs it. The UI always previews first. It is offered only on connections
/// that can execute SQL and report the schema_inspector capability.
@$pb.GrpcServiceName('queravue.v1.SchemaDesignService')
class SchemaDesignServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SchemaDesignServiceClient(super.channel, {super.options, super.interceptors});

  /// PreviewDDL builds the statements for the changes without running anything.
  $grpc.ResponseFuture<$0.PreviewDDLResponse> previewDDL(
    $0.PreviewDDLRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewDDL, request, options: options);
  }

  /// ApplyDDL builds and runs the statements, in one transaction where the
  /// engine's DDL is transactional, and refreshes the schema cache.
  $grpc.ResponseFuture<$0.ApplyDDLResponse> applyDDL(
    $0.ApplyDDLRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyDDL, request, options: options);
  }

  // method descriptors

  static final _$previewDDL =
      $grpc.ClientMethod<$0.PreviewDDLRequest, $0.PreviewDDLResponse>(
          '/queravue.v1.SchemaDesignService/PreviewDDL',
          ($0.PreviewDDLRequest value) => value.writeToBuffer(),
          $0.PreviewDDLResponse.fromBuffer);
  static final _$applyDDL =
      $grpc.ClientMethod<$0.ApplyDDLRequest, $0.ApplyDDLResponse>(
          '/queravue.v1.SchemaDesignService/ApplyDDL',
          ($0.ApplyDDLRequest value) => value.writeToBuffer(),
          $0.ApplyDDLResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.SchemaDesignService')
abstract class SchemaDesignServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.SchemaDesignService';

  SchemaDesignServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PreviewDDLRequest, $0.PreviewDDLResponse>(
        'PreviewDDL',
        previewDDL_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PreviewDDLRequest.fromBuffer(value),
        ($0.PreviewDDLResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApplyDDLRequest, $0.ApplyDDLResponse>(
        'ApplyDDL',
        applyDDL_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ApplyDDLRequest.fromBuffer(value),
        ($0.ApplyDDLResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.PreviewDDLResponse> previewDDL_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PreviewDDLRequest> $request) async {
    return previewDDL($call, await $request);
  }

  $async.Future<$0.PreviewDDLResponse> previewDDL(
      $grpc.ServiceCall call, $0.PreviewDDLRequest request);

  $async.Future<$0.ApplyDDLResponse> applyDDL_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ApplyDDLRequest> $request) async {
    return applyDDL($call, await $request);
  }

  $async.Future<$0.ApplyDDLResponse> applyDDL(
      $grpc.ServiceCall call, $0.ApplyDDLRequest request);
}
