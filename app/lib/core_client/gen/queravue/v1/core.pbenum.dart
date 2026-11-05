// This is a generated file - do not edit.
//
// Generated from queravue/v1/core.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// HealthStatus is the core's self-reported state.
class HealthStatus extends $pb.ProtobufEnum {
  /// Not set. Treat as unhealthy.
  static const HealthStatus HEALTH_STATUS_UNSPECIFIED =
      HealthStatus._(0, _omitEnumNames ? '' : 'HEALTH_STATUS_UNSPECIFIED');

  /// Accepting and serving requests.
  static const HealthStatus HEALTH_STATUS_SERVING =
      HealthStatus._(1, _omitEnumNames ? '' : 'HEALTH_STATUS_SERVING');

  /// Shutting down; the stream will end shortly.
  static const HealthStatus HEALTH_STATUS_DRAINING =
      HealthStatus._(2, _omitEnumNames ? '' : 'HEALTH_STATUS_DRAINING');

  static const $core.List<HealthStatus> values = <HealthStatus>[
    HEALTH_STATUS_UNSPECIFIED,
    HEALTH_STATUS_SERVING,
    HEALTH_STATUS_DRAINING,
  ];

  static final $core.List<HealthStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static HealthStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HealthStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
