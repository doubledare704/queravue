// This is a generated file - do not edit.
//
// Generated from queravue/v1/validation.proto.

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

import 'validation.pb.dart' as $0;

export 'validation.pb.dart';

/// ValidationService reads and changes the Mongo collection validator
/// ($jsonSchema). The UI offers it only when the connection reports the
/// validation capability.
@$pb.GrpcServiceName('queravue.v1.ValidationService')
class ValidationServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ValidationServiceClient(super.channel, {super.options, super.interceptors});

  /// GetValidation returns the collection's current validator, level and action.
  $grpc.ResponseFuture<$0.GetValidationResponse> getValidation(
    $0.GetValidationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getValidation, request, options: options);
  }

  /// SetValidation replaces the validator (collMod). An empty validator removes
  /// it. With dry_run it only returns the command.
  $grpc.ResponseFuture<$0.SetValidationResponse> setValidation(
    $0.SetValidationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setValidation, request, options: options);
  }

  // method descriptors

  static final _$getValidation =
      $grpc.ClientMethod<$0.GetValidationRequest, $0.GetValidationResponse>(
          '/queravue.v1.ValidationService/GetValidation',
          ($0.GetValidationRequest value) => value.writeToBuffer(),
          $0.GetValidationResponse.fromBuffer);
  static final _$setValidation =
      $grpc.ClientMethod<$0.SetValidationRequest, $0.SetValidationResponse>(
          '/queravue.v1.ValidationService/SetValidation',
          ($0.SetValidationRequest value) => value.writeToBuffer(),
          $0.SetValidationResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.ValidationService')
abstract class ValidationServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.ValidationService';

  ValidationServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GetValidationRequest, $0.GetValidationResponse>(
            'GetValidation',
            getValidation_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetValidationRequest.fromBuffer(value),
            ($0.GetValidationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SetValidationRequest, $0.SetValidationResponse>(
            'SetValidation',
            setValidation_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SetValidationRequest.fromBuffer(value),
            ($0.SetValidationResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetValidationResponse> getValidation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetValidationRequest> $request) async {
    return getValidation($call, await $request);
  }

  $async.Future<$0.GetValidationResponse> getValidation(
      $grpc.ServiceCall call, $0.GetValidationRequest request);

  $async.Future<$0.SetValidationResponse> setValidation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetValidationRequest> $request) async {
    return setValidation($call, await $request);
  }

  $async.Future<$0.SetValidationResponse> setValidation(
      $grpc.ServiceCall call, $0.SetValidationRequest request);
}
