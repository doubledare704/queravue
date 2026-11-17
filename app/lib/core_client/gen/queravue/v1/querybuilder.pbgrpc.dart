// This is a generated file - do not edit.
//
// Generated from queravue/v1/querybuilder.proto.

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

import 'querybuilder.pb.dart' as $0;

export 'querybuilder.pb.dart';

/// QueryBuilderService turns visual builder models into query text and parses
/// query text back into models (ADR 0021). Generation always succeeds for a
/// valid model; parsing covers a documented subset and reports the rest as
/// UNSUPPORTED_CONSTRUCT. Failures the user can act on are returned in-band in
/// `error`.
@$pb.GrpcServiceName('queravue.v1.QueryBuilderService')
class QueryBuilderServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  QueryBuilderServiceClient(super.channel, {super.options, super.interceptors});

  /// GenerateSql renders a SQL model as one SELECT statement in the dialect of
  /// the session's engine.
  $grpc.ResponseFuture<$0.GenerateSqlResponse> generateSql(
    $0.GenerateSqlRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$generateSql, request, options: options);
  }

  /// ParseSql reads one SELECT statement into a SQL model. Statements outside
  /// the supported subset fail with UNSUPPORTED_CONSTRUCT.
  $grpc.ResponseFuture<$0.ParseSqlResponse> parseSql(
    $0.ParseSqlRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$parseSql, request, options: options);
  }

  /// GenerateMongoQuery renders a find model as EJSON filter, projection and
  /// sort documents.
  $grpc.ResponseFuture<$0.GenerateMongoQueryResponse> generateMongoQuery(
    $0.GenerateMongoQueryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$generateMongoQuery, request, options: options);
  }

  /// ParseMongoQuery reads EJSON filter, projection and sort documents into a
  /// find model. Operators without a visual form are kept as raw EJSON leaves.
  $grpc.ResponseFuture<$0.ParseMongoQueryResponse> parseMongoQuery(
    $0.ParseMongoQueryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$parseMongoQuery, request, options: options);
  }

  // method descriptors

  static final _$generateSql =
      $grpc.ClientMethod<$0.GenerateSqlRequest, $0.GenerateSqlResponse>(
          '/queravue.v1.QueryBuilderService/GenerateSql',
          ($0.GenerateSqlRequest value) => value.writeToBuffer(),
          $0.GenerateSqlResponse.fromBuffer);
  static final _$parseSql =
      $grpc.ClientMethod<$0.ParseSqlRequest, $0.ParseSqlResponse>(
          '/queravue.v1.QueryBuilderService/ParseSql',
          ($0.ParseSqlRequest value) => value.writeToBuffer(),
          $0.ParseSqlResponse.fromBuffer);
  static final _$generateMongoQuery = $grpc.ClientMethod<
          $0.GenerateMongoQueryRequest, $0.GenerateMongoQueryResponse>(
      '/queravue.v1.QueryBuilderService/GenerateMongoQuery',
      ($0.GenerateMongoQueryRequest value) => value.writeToBuffer(),
      $0.GenerateMongoQueryResponse.fromBuffer);
  static final _$parseMongoQuery =
      $grpc.ClientMethod<$0.ParseMongoQueryRequest, $0.ParseMongoQueryResponse>(
          '/queravue.v1.QueryBuilderService/ParseMongoQuery',
          ($0.ParseMongoQueryRequest value) => value.writeToBuffer(),
          $0.ParseMongoQueryResponse.fromBuffer);
}

@$pb.GrpcServiceName('queravue.v1.QueryBuilderService')
abstract class QueryBuilderServiceBase extends $grpc.Service {
  $core.String get $name => 'queravue.v1.QueryBuilderService';

  QueryBuilderServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GenerateSqlRequest, $0.GenerateSqlResponse>(
            'GenerateSql',
            generateSql_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GenerateSqlRequest.fromBuffer(value),
            ($0.GenerateSqlResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ParseSqlRequest, $0.ParseSqlResponse>(
        'ParseSql',
        parseSql_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ParseSqlRequest.fromBuffer(value),
        ($0.ParseSqlResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GenerateMongoQueryRequest,
            $0.GenerateMongoQueryResponse>(
        'GenerateMongoQuery',
        generateMongoQuery_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GenerateMongoQueryRequest.fromBuffer(value),
        ($0.GenerateMongoQueryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ParseMongoQueryRequest,
            $0.ParseMongoQueryResponse>(
        'ParseMongoQuery',
        parseMongoQuery_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ParseMongoQueryRequest.fromBuffer(value),
        ($0.ParseMongoQueryResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GenerateSqlResponse> generateSql_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GenerateSqlRequest> $request) async {
    return generateSql($call, await $request);
  }

  $async.Future<$0.GenerateSqlResponse> generateSql(
      $grpc.ServiceCall call, $0.GenerateSqlRequest request);

  $async.Future<$0.ParseSqlResponse> parseSql_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ParseSqlRequest> $request) async {
    return parseSql($call, await $request);
  }

  $async.Future<$0.ParseSqlResponse> parseSql(
      $grpc.ServiceCall call, $0.ParseSqlRequest request);

  $async.Future<$0.GenerateMongoQueryResponse> generateMongoQuery_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GenerateMongoQueryRequest> $request) async {
    return generateMongoQuery($call, await $request);
  }

  $async.Future<$0.GenerateMongoQueryResponse> generateMongoQuery(
      $grpc.ServiceCall call, $0.GenerateMongoQueryRequest request);

  $async.Future<$0.ParseMongoQueryResponse> parseMongoQuery_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ParseMongoQueryRequest> $request) async {
    return parseMongoQuery($call, await $request);
  }

  $async.Future<$0.ParseMongoQueryResponse> parseMongoQuery(
      $grpc.ServiceCall call, $0.ParseMongoQueryRequest request);
}
