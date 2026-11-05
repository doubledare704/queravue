// This is a generated file - do not edit.
//
// Generated from queravue/v1/session.proto.

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

@$core.Deprecated('Use openRequestDescriptor instead')
const OpenRequest$json = {
  '1': 'OpenRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `OpenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openRequestDescriptor = $convert.base64Decode(
    'CgtPcGVuUmVxdWVzdBIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW9uSWQ=');

@$core.Deprecated('Use openResponseDescriptor instead')
const OpenResponse$json = {
  '1': 'OpenResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'server_info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ServerInfo',
      '10': 'serverInfo'
    },
    {'1': 'capabilities', '3': 3, '4': 3, '5': 9, '10': 'capabilities'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ConnectionError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `OpenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openResponseDescriptor = $convert.base64Decode(
    'CgxPcGVuUmVzcG9uc2USHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjgKC3NlcnZlcl'
    '9pbmZvGAIgASgLMhcucXVlcmF2dWUudjEuU2VydmVySW5mb1IKc2VydmVySW5mbxIiCgxjYXBh'
    'YmlsaXRpZXMYAyADKAlSDGNhcGFiaWxpdGllcxIyCgVlcnJvchgEIAEoCzIcLnF1ZXJhdnVlLn'
    'YxLkNvbm5lY3Rpb25FcnJvclIFZXJyb3I=');

@$core.Deprecated('Use closeRequestDescriptor instead')
const CloseRequest$json = {
  '1': 'CloseRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `CloseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeRequestDescriptor = $convert.base64Decode(
    'CgxDbG9zZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use closeResponseDescriptor instead')
const CloseResponse$json = {
  '1': 'CloseResponse',
};

/// Descriptor for `CloseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeResponseDescriptor =
    $convert.base64Decode('Cg1DbG9zZVJlc3BvbnNl');
