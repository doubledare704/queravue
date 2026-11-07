// This is a generated file - do not edit.
//
// Generated from queravue/v1/index.proto.

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

@$core.Deprecated('Use indexKeyKindDescriptor instead')
const IndexKeyKind$json = {
  '1': 'IndexKeyKind',
  '2': [
    {'1': 'INDEX_KEY_KIND_UNSPECIFIED', '2': 0},
    {'1': 'INDEX_KEY_KIND_ASCENDING', '2': 1},
    {'1': 'INDEX_KEY_KIND_DESCENDING', '2': 2},
    {'1': 'INDEX_KEY_KIND_HASHED', '2': 3},
    {'1': 'INDEX_KEY_KIND_TEXT', '2': 4},
    {'1': 'INDEX_KEY_KIND_GEO_2DSPHERE', '2': 5},
  ],
};

/// Descriptor for `IndexKeyKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List indexKeyKindDescriptor = $convert.base64Decode(
    'CgxJbmRleEtleUtpbmQSHgoaSU5ERVhfS0VZX0tJTkRfVU5TUEVDSUZJRUQQABIcChhJTkRFWF'
    '9LRVlfS0lORF9BU0NFTkRJTkcQARIdChlJTkRFWF9LRVlfS0lORF9ERVNDRU5ESU5HEAISGQoV'
    'SU5ERVhfS0VZX0tJTkRfSEFTSEVEEAMSFwoTSU5ERVhfS0VZX0tJTkRfVEVYVBAEEh8KG0lORE'
    'VYX0tFWV9LSU5EX0dFT18yRFNQSEVSRRAF');

@$core.Deprecated('Use indexKeyDescriptor instead')
const IndexKey$json = {
  '1': 'IndexKey',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.IndexKeyKind',
      '10': 'kind'
    },
    {'1': 'is_expression', '3': 3, '4': 1, '5': 8, '10': 'isExpression'},
  ],
};

/// Descriptor for `IndexKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexKeyDescriptor = $convert.base64Decode(
    'CghJbmRleEtleRISCgRuYW1lGAEgASgJUgRuYW1lEi0KBGtpbmQYAiABKA4yGS5xdWVyYXZ1ZS'
    '52MS5JbmRleEtleUtpbmRSBGtpbmQSIwoNaXNfZXhwcmVzc2lvbhgDIAEoCFIMaXNFeHByZXNz'
    'aW9u');

@$core.Deprecated('Use indexUsageDescriptor instead')
const IndexUsage$json = {
  '1': 'IndexUsage',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'scans', '3': 2, '4': 1, '5': 4, '9': 0, '10': 'scans', '17': true},
    {
      '1': 'last_used_unix_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'lastUsedUnixMs',
      '17': true
    },
    {
      '1': 'tracking_since_unix_ms',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'trackingSinceUnixMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_scans'},
    {'1': '_last_used_unix_ms'},
    {'1': '_tracking_since_unix_ms'},
  ],
};

/// Descriptor for `IndexUsage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexUsageDescriptor = $convert.base64Decode(
    'CgpJbmRleFVzYWdlEhwKCWF2YWlsYWJsZRgBIAEoCFIJYXZhaWxhYmxlEhkKBXNjYW5zGAIgAS'
    'gESABSBXNjYW5ziAEBEi4KEWxhc3RfdXNlZF91bml4X21zGAMgASgDSAFSDmxhc3RVc2VkVW5p'
    'eE1ziAEBEjgKFnRyYWNraW5nX3NpbmNlX3VuaXhfbXMYBCABKANIAlITdHJhY2tpbmdTaW5jZV'
    'VuaXhNc4gBAUIICgZfc2NhbnNCFAoSX2xhc3RfdXNlZF91bml4X21zQhkKF190cmFja2luZ19z'
    'aW5jZV91bml4X21z');

@$core.Deprecated('Use indexSpecDescriptor instead')
const IndexSpec$json = {
  '1': 'IndexSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'keys',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.IndexKey',
      '10': 'keys'
    },
    {'1': 'unique', '3': 3, '4': 1, '5': 8, '10': 'unique'},
    {'1': 'method', '3': 4, '4': 1, '5': 9, '10': 'method'},
    {
      '1': 'partial_predicate',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'partialPredicate'
    },
    {'1': 'include_columns', '3': 6, '4': 3, '5': 9, '10': 'includeColumns'},
    {
      '1': 'options',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.IndexSpec.OptionsEntry',
      '10': 'options'
    },
  ],
  '3': [IndexSpec_OptionsEntry$json],
};

@$core.Deprecated('Use indexSpecDescriptor instead')
const IndexSpec_OptionsEntry$json = {
  '1': 'OptionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `IndexSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexSpecDescriptor = $convert.base64Decode(
    'CglJbmRleFNwZWMSEgoEbmFtZRgBIAEoCVIEbmFtZRIpCgRrZXlzGAIgAygLMhUucXVlcmF2dW'
    'UudjEuSW5kZXhLZXlSBGtleXMSFgoGdW5pcXVlGAMgASgIUgZ1bmlxdWUSFgoGbWV0aG9kGAQg'
    'ASgJUgZtZXRob2QSKwoRcGFydGlhbF9wcmVkaWNhdGUYBSABKAlSEHBhcnRpYWxQcmVkaWNhdG'
    'USJwoPaW5jbHVkZV9jb2x1bW5zGAYgAygJUg5pbmNsdWRlQ29sdW1ucxI9CgdvcHRpb25zGAcg'
    'AygLMiMucXVlcmF2dWUudjEuSW5kZXhTcGVjLk9wdGlvbnNFbnRyeVIHb3B0aW9ucxo6CgxPcH'
    'Rpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use indexInfoDescriptor instead')
const IndexInfo$json = {
  '1': 'IndexInfo',
  '2': [
    {
      '1': 'spec',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.IndexSpec',
      '10': 'spec'
    },
    {'1': 'is_primary', '3': 2, '4': 1, '5': 8, '10': 'isPrimary'},
    {
      '1': 'size_bytes',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'sizeBytes',
      '17': true
    },
    {
      '1': 'usage',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.IndexUsage',
      '10': 'usage'
    },
  ],
  '8': [
    {'1': '_size_bytes'},
  ],
};

/// Descriptor for `IndexInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexInfoDescriptor = $convert.base64Decode(
    'CglJbmRleEluZm8SKgoEc3BlYxgBIAEoCzIWLnF1ZXJhdnVlLnYxLkluZGV4U3BlY1IEc3BlYx'
    'IdCgppc19wcmltYXJ5GAIgASgIUglpc1ByaW1hcnkSIgoKc2l6ZV9ieXRlcxgDIAEoBEgAUglz'
    'aXplQnl0ZXOIAQESLQoFdXNhZ2UYBCABKAsyFy5xdWVyYXZ1ZS52MS5JbmRleFVzYWdlUgV1c2'
    'FnZUINCgtfc2l6ZV9ieXRlcw==');

@$core.Deprecated('Use listIndexesRequestDescriptor instead')
const ListIndexesRequest$json = {
  '1': 'ListIndexesRequest',
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

/// Descriptor for `ListIndexesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listIndexesRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0SW5kZXhlc1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjIKCX'
    'RhYmxlX3JlZhgCIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgh0YWJsZVJlZg==');

@$core.Deprecated('Use listIndexesResponseDescriptor instead')
const ListIndexesResponse$json = {
  '1': 'ListIndexesResponse',
  '2': [
    {
      '1': 'indexes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.IndexInfo',
      '10': 'indexes'
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

/// Descriptor for `ListIndexesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listIndexesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0SW5kZXhlc1Jlc3BvbnNlEjAKB2luZGV4ZXMYASADKAsyFi5xdWVyYXZ1ZS52MS5Jbm'
    'RleEluZm9SB2luZGV4ZXMSLQoFZXJyb3IYAiABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9y'
    'UgVlcnJvcg==');

@$core.Deprecated('Use createIndexRequestDescriptor instead')
const CreateIndexRequest$json = {
  '1': 'CreateIndexRequest',
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
      '1': 'spec',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.IndexSpec',
      '10': 'spec'
    },
    {'1': 'dry_run', '3': 4, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `CreateIndexRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createIndexRequestDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVJbmRleFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjIKCX'
    'RhYmxlX3JlZhgCIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgh0YWJsZVJlZhIqCgRzcGVj'
    'GAMgASgLMhYucXVlcmF2dWUudjEuSW5kZXhTcGVjUgRzcGVjEhcKB2RyeV9ydW4YBCABKAhSBm'
    'RyeVJ1bhIcCgljb25maXJtZWQYBSABKAhSCWNvbmZpcm1lZA==');

@$core.Deprecated('Use createIndexResponseDescriptor instead')
const CreateIndexResponse$json = {
  '1': 'CreateIndexResponse',
  '2': [
    {'1': 'statement', '3': 1, '4': 1, '5': 9, '10': 'statement'},
    {'1': 'dry_run', '3': 2, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'index_name', '3': 3, '4': 1, '5': 9, '10': 'indexName'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `CreateIndexResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createIndexResponseDescriptor = $convert.base64Decode(
    'ChNDcmVhdGVJbmRleFJlc3BvbnNlEhwKCXN0YXRlbWVudBgBIAEoCVIJc3RhdGVtZW50EhcKB2'
    'RyeV9ydW4YAiABKAhSBmRyeVJ1bhIdCgppbmRleF9uYW1lGAMgASgJUglpbmRleE5hbWUSLQoF'
    'ZXJyb3IYBCABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use dropIndexRequestDescriptor instead')
const DropIndexRequest$json = {
  '1': 'DropIndexRequest',
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
    {'1': 'index_name', '3': 3, '4': 1, '5': 9, '10': 'indexName'},
    {'1': 'dry_run', '3': 4, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `DropIndexRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropIndexRequestDescriptor = $convert.base64Decode(
    'ChBEcm9wSW5kZXhSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIyCgl0YW'
    'JsZV9yZWYYAiABKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZlIIdGFibGVSZWYSHQoKaW5kZXhf'
    'bmFtZRgDIAEoCVIJaW5kZXhOYW1lEhcKB2RyeV9ydW4YBCABKAhSBmRyeVJ1bhIcCgljb25maX'
    'JtZWQYBSABKAhSCWNvbmZpcm1lZA==');

@$core.Deprecated('Use dropIndexResponseDescriptor instead')
const DropIndexResponse$json = {
  '1': 'DropIndexResponse',
  '2': [
    {'1': 'statement', '3': 1, '4': 1, '5': 9, '10': 'statement'},
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

/// Descriptor for `DropIndexResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropIndexResponseDescriptor = $convert.base64Decode(
    'ChFEcm9wSW5kZXhSZXNwb25zZRIcCglzdGF0ZW1lbnQYASABKAlSCXN0YXRlbWVudBIXCgdkcn'
    'lfcnVuGAIgASgIUgZkcnlSdW4SLQoFZXJyb3IYAyABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVy'
    'cm9yUgVlcnJvcg==');
