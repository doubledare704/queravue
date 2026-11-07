// This is a generated file - do not edit.
//
// Generated from queravue/v1/admin.proto.

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

@$core.Deprecated('Use adminErrorKindDescriptor instead')
const AdminErrorKind$json = {
  '1': 'AdminErrorKind',
  '2': [
    {'1': 'ADMIN_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 1},
    {'1': 'ADMIN_ERROR_KIND_UNSUPPORTED', '2': 2},
    {'1': 'ADMIN_ERROR_KIND_INVALID', '2': 3},
    {'1': 'ADMIN_ERROR_KIND_NOT_FOUND', '2': 4},
    {'1': 'ADMIN_ERROR_KIND_ALREADY_EXISTS', '2': 5},
    {'1': 'ADMIN_ERROR_KIND_SERVER', '2': 6},
    {'1': 'ADMIN_ERROR_KIND_CANCELED', '2': 7},
  ],
};

/// Descriptor for `AdminErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List adminErrorKindDescriptor = $convert.base64Decode(
    'Cg5BZG1pbkVycm9yS2luZBIgChxBRE1JTl9FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEAASKgomQU'
    'RNSU5fRVJST1JfS0lORF9DT05GSVJNQVRJT05fUkVRVUlSRUQQARIgChxBRE1JTl9FUlJPUl9L'
    'SU5EX1VOU1VQUE9SVEVEEAISHAoYQURNSU5fRVJST1JfS0lORF9JTlZBTElEEAMSHgoaQURNSU'
    '5fRVJST1JfS0lORF9OT1RfRk9VTkQQBBIjCh9BRE1JTl9FUlJPUl9LSU5EX0FMUkVBRFlfRVhJ'
    'U1RTEAUSGwoXQURNSU5fRVJST1JfS0lORF9TRVJWRVIQBhIdChlBRE1JTl9FUlJPUl9LSU5EX0'
    'NBTkNFTEVEEAc=');

@$core.Deprecated('Use adminErrorDescriptor instead')
const AdminError$json = {
  '1': 'AdminError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.AdminErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'operation', '3': 3, '4': 1, '5': 9, '10': 'operation'},
    {
      '1': 'position',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'position',
      '17': true
    },
  ],
  '8': [
    {'1': '_position'},
  ],
};

/// Descriptor for `AdminError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminErrorDescriptor = $convert.base64Decode(
    'CgpBZG1pbkVycm9yEi8KBGtpbmQYASABKA4yGy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yS2luZF'
    'IEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEhwKCW9wZXJhdGlvbhgDIAEoCVIJb3Bl'
    'cmF0aW9uEh8KCHBvc2l0aW9uGAQgASgNSABSCHBvc2l0aW9uiAEBQgsKCV9wb3NpdGlvbg==');
