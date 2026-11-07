// This is a generated file - do not edit.
//
// Generated from queravue/v1/validation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use validationLevelDescriptor instead')
const ValidationLevel$json = {
  '1': 'ValidationLevel',
  '2': [
    {'1': 'VALIDATION_LEVEL_UNSPECIFIED', '2': 0},
    {'1': 'VALIDATION_LEVEL_OFF', '2': 1},
    {'1': 'VALIDATION_LEVEL_MODERATE', '2': 2},
    {'1': 'VALIDATION_LEVEL_STRICT', '2': 3},
  ],
};

/// Descriptor for `ValidationLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List validationLevelDescriptor = $convert.base64Decode(
    'Cg9WYWxpZGF0aW9uTGV2ZWwSIAocVkFMSURBVElPTl9MRVZFTF9VTlNQRUNJRklFRBAAEhgKFF'
    'ZBTElEQVRJT05fTEVWRUxfT0ZGEAESHQoZVkFMSURBVElPTl9MRVZFTF9NT0RFUkFURRACEhsK'
    'F1ZBTElEQVRJT05fTEVWRUxfU1RSSUNUEAM=');

@$core.Deprecated('Use validationActionDescriptor instead')
const ValidationAction$json = {
  '1': 'ValidationAction',
  '2': [
    {'1': 'VALIDATION_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'VALIDATION_ACTION_ERROR', '2': 1},
    {'1': 'VALIDATION_ACTION_WARN', '2': 2},
  ],
};

/// Descriptor for `ValidationAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List validationActionDescriptor = $convert.base64Decode(
    'ChBWYWxpZGF0aW9uQWN0aW9uEiEKHVZBTElEQVRJT05fQUNUSU9OX1VOU1BFQ0lGSUVEEAASGw'
    'oXVkFMSURBVElPTl9BQ1RJT05fRVJST1IQARIaChZWQUxJREFUSU9OX0FDVElPTl9XQVJOEAI=');

@$core.Deprecated('Use validationRuleDescriptor instead')
const ValidationRule$json = {
  '1': 'ValidationRule',
  '2': [
    {'1': 'validator', '3': 1, '4': 1, '5': 9, '10': 'validator'},
    {
      '1': 'level',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ValidationLevel',
      '10': 'level'
    },
    {
      '1': 'action',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ValidationAction',
      '10': 'action'
    },
  ],
};

/// Descriptor for `ValidationRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validationRuleDescriptor = $convert.base64Decode(
    'Cg5WYWxpZGF0aW9uUnVsZRIcCgl2YWxpZGF0b3IYASABKAlSCXZhbGlkYXRvchIyCgVsZXZlbB'
    'gCIAEoDjIcLnF1ZXJhdnVlLnYxLlZhbGlkYXRpb25MZXZlbFIFbGV2ZWwSNQoGYWN0aW9uGAMg'
    'ASgOMh0ucXVlcmF2dWUudjEuVmFsaWRhdGlvbkFjdGlvblIGYWN0aW9u');

@$core.Deprecated('Use getValidationRequestDescriptor instead')
const GetValidationRequest$json = {
  '1': 'GetValidationRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'table_ref',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'tableRef'
    },
  ],
};

/// Descriptor for `GetValidationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getValidationRequestDescriptor = $convert.base64Decode(
    'ChRHZXRWYWxpZGF0aW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSMg'
    'oJdGFibGVfcmVmGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSCHRhYmxlUmVm');

@$core.Deprecated('Use getValidationResponseDescriptor instead')
const GetValidationResponse$json = {
  '1': 'GetValidationResponse',
  '2': [
    {
      '1': 'rule',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ValidationRule',
      '10': 'rule'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `GetValidationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getValidationResponseDescriptor = $convert.base64Decode(
    'ChVHZXRWYWxpZGF0aW9uUmVzcG9uc2USLwoEcnVsZRgBIAEoCzIbLnF1ZXJhdnVlLnYxLlZhbG'
    'lkYXRpb25SdWxlUgRydWxlEi0KBWVycm9yGAIgASgLMhcucXVlcmF2dWUudjEuQWRtaW5FcnJv'
    'clIFZXJyb3I=');

@$core.Deprecated('Use setValidationRequestDescriptor instead')
const SetValidationRequest$json = {
  '1': 'SetValidationRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'table_ref',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'tableRef'
    },
    {
      '1': 'rule',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ValidationRule',
      '10': 'rule'
    },
    {'1': 'dry_run', '3': 4, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `SetValidationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setValidationRequestDescriptor = $convert.base64Decode(
    'ChRTZXRWYWxpZGF0aW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSMg'
    'oJdGFibGVfcmVmGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSCHRhYmxlUmVmEi8KBHJ1'
    'bGUYAyABKAsyGy5xdWVyYXZ1ZS52MS5WYWxpZGF0aW9uUnVsZVIEcnVsZRIXCgdkcnlfcnVuGA'
    'QgASgIUgZkcnlSdW4SHAoJY29uZmlybWVkGAUgASgIUgljb25maXJtZWQ=');

@$core.Deprecated('Use setValidationResponseDescriptor instead')
const SetValidationResponse$json = {
  '1': 'SetValidationResponse',
  '2': [
    {'1': 'command', '3': 1, '4': 1, '5': 9, '10': 'command'},
    {'1': 'dry_run', '3': 2, '4': 1, '5': 8, '10': 'dryRun'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SetValidationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setValidationResponseDescriptor = $convert.base64Decode(
    'ChVTZXRWYWxpZGF0aW9uUmVzcG9uc2USGAoHY29tbWFuZBgBIAEoCVIHY29tbWFuZBIXCgdkcn'
    'lfcnVuGAIgASgIUgZkcnlSdW4SLQoFZXJyb3IYAyABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVy'
    'cm9yUgVlcnJvcg==');
