// This is a generated file - do not edit.
//
// Generated from queravue/v1/keyvalue.proto.

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

@$core.Deprecated('Use keyValueErrorKindDescriptor instead')
const KeyValueErrorKind$json = {
  '1': 'KeyValueErrorKind',
  '2': [
    {'1': 'KEY_VALUE_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 1},
    {'1': 'KEY_VALUE_ERROR_KIND_UNSUPPORTED', '2': 2},
    {'1': 'KEY_VALUE_ERROR_KIND_INVALID', '2': 3},
    {'1': 'KEY_VALUE_ERROR_KIND_NOT_FOUND', '2': 4},
    {'1': 'KEY_VALUE_ERROR_KIND_SERVER', '2': 5},
    {'1': 'KEY_VALUE_ERROR_KIND_CANCELED', '2': 6},
    {'1': 'KEY_VALUE_ERROR_KIND_KEYS_REFUSED', '2': 7},
    {'1': 'KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED', '2': 8},
  ],
};

/// Descriptor for `KeyValueErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List keyValueErrorKindDescriptor = $convert.base64Decode(
    'ChFLZXlWYWx1ZUVycm9yS2luZBIkCiBLRVlfVkFMVUVfRVJST1JfS0lORF9VTlNQRUNJRklFRB'
    'AAEi4KKktFWV9WQUxVRV9FUlJPUl9LSU5EX0NPTkZJUk1BVElPTl9SRVFVSVJFRBABEiQKIEtF'
    'WV9WQUxVRV9FUlJPUl9LSU5EX1VOU1VQUE9SVEVEEAISIAocS0VZX1ZBTFVFX0VSUk9SX0tJTk'
    'RfSU5WQUxJRBADEiIKHktFWV9WQUxVRV9FUlJPUl9LSU5EX05PVF9GT1VORBAEEh8KG0tFWV9W'
    'QUxVRV9FUlJPUl9LSU5EX1NFUlZFUhAFEiEKHUtFWV9WQUxVRV9FUlJPUl9LSU5EX0NBTkNFTE'
    'VEEAYSJQohS0VZX1ZBTFVFX0VSUk9SX0tJTkRfS0VZU19SRUZVU0VEEAcSKQolS0VZX1ZBTFVF'
    'X0VSUk9SX0tJTkRfQkxPQ0tJTkdfUkVGVVNFRBAI');

@$core.Deprecated('Use keyTypeDescriptor instead')
const KeyType$json = {
  '1': 'KeyType',
  '2': [
    {'1': 'KEY_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'KEY_TYPE_STRING', '2': 1},
    {'1': 'KEY_TYPE_HASH', '2': 2},
    {'1': 'KEY_TYPE_LIST', '2': 3},
    {'1': 'KEY_TYPE_SET', '2': 4},
    {'1': 'KEY_TYPE_ZSET', '2': 5},
    {'1': 'KEY_TYPE_STREAM', '2': 6},
    {'1': 'KEY_TYPE_JSON', '2': 7},
    {'1': 'KEY_TYPE_HYPERLOGLOG', '2': 8},
  ],
};

/// Descriptor for `KeyType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List keyTypeDescriptor = $convert.base64Decode(
    'CgdLZXlUeXBlEhgKFEtFWV9UWVBFX1VOU1BFQ0lGSUVEEAASEwoPS0VZX1RZUEVfU1RSSU5HEA'
    'ESEQoNS0VZX1RZUEVfSEFTSBACEhEKDUtFWV9UWVBFX0xJU1QQAxIQCgxLRVlfVFlQRV9TRVQQ'
    'BBIRCg1LRVlfVFlQRV9aU0VUEAUSEwoPS0VZX1RZUEVfU1RSRUFNEAYSEQoNS0VZX1RZUEVfSl'
    'NPThAHEhgKFEtFWV9UWVBFX0hZUEVSTE9HTE9HEAg=');

@$core.Deprecated('Use keyValueErrorDescriptor instead')
const KeyValueError$json = {
  '1': 'KeyValueError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeyValueErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'operation', '3': 3, '4': 1, '5': 9, '10': 'operation'},
  ],
};

/// Descriptor for `KeyValueError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyValueErrorDescriptor = $convert.base64Decode(
    'Cg1LZXlWYWx1ZUVycm9yEjIKBGtpbmQYASABKA4yHi5xdWVyYXZ1ZS52MS5LZXlWYWx1ZUVycm'
    '9yS2luZFIEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEhwKCW9wZXJhdGlvbhgDIAEo'
    'CVIJb3BlcmF0aW9u');

@$core.Deprecated('Use kvDatabaseDescriptor instead')
const KvDatabase$json = {
  '1': 'KvDatabase',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'key_count', '3': 2, '4': 1, '5': 4, '10': 'keyCount'},
    {'1': 'expiring_count', '3': 3, '4': 1, '5': 4, '10': 'expiringCount'},
  ],
};

/// Descriptor for `KvDatabase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List kvDatabaseDescriptor = $convert.base64Decode(
    'CgpLdkRhdGFiYXNlEhQKBWluZGV4GAEgASgNUgVpbmRleBIbCglrZXlfY291bnQYAiABKARSCG'
    'tleUNvdW50EiUKDmV4cGlyaW5nX2NvdW50GAMgASgEUg1leHBpcmluZ0NvdW50');

@$core.Deprecated('Use listKvDatabasesRequestDescriptor instead')
const ListKvDatabasesRequest$json = {
  '1': 'ListKvDatabasesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ListKvDatabasesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKvDatabasesRequestDescriptor =
    $convert.base64Decode(
        'ChZMaXN0S3ZEYXRhYmFzZXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA'
        '==');

@$core.Deprecated('Use listKvDatabasesResponseDescriptor instead')
const ListKvDatabasesResponse$json = {
  '1': 'ListKvDatabasesResponse',
  '2': [
    {
      '1': 'databases',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.KvDatabase',
      '10': 'databases'
    },
    {'1': 'database_limit', '3': 2, '4': 1, '5': 13, '10': 'databaseLimit'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ListKvDatabasesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKvDatabasesResponseDescriptor = $convert.base64Decode(
    'ChdMaXN0S3ZEYXRhYmFzZXNSZXNwb25zZRI1CglkYXRhYmFzZXMYASADKAsyFy5xdWVyYXZ1ZS'
    '52MS5LdkRhdGFiYXNlUglkYXRhYmFzZXMSJQoOZGF0YWJhc2VfbGltaXQYAiABKA1SDWRhdGFi'
    'YXNlTGltaXQSMAoFZXJyb3IYAyABKAsyGi5xdWVyYXZ1ZS52MS5LZXlWYWx1ZUVycm9yUgVlcn'
    'Jvcg==');

@$core.Deprecated('Use scanKeysRequestDescriptor instead')
const ScanKeysRequest$json = {
  '1': 'ScanKeysRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'pattern', '3': 3, '4': 1, '5': 9, '10': 'pattern'},
    {
      '1': 'type_filter',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeyType',
      '10': 'typeFilter'
    },
    {'1': 'page_size', '3': 5, '4': 1, '5': 13, '10': 'pageSize'},
  ],
};

/// Descriptor for `ScanKeysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanKeysRequestDescriptor = $convert.base64Decode(
    'Cg9TY2FuS2V5c1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCGRhdG'
    'FiYXNlGAIgASgNUghkYXRhYmFzZRIYCgdwYXR0ZXJuGAMgASgJUgdwYXR0ZXJuEjUKC3R5cGVf'
    'ZmlsdGVyGAQgASgOMhQucXVlcmF2dWUudjEuS2V5VHlwZVIKdHlwZUZpbHRlchIbCglwYWdlX3'
    'NpemUYBSABKA1SCHBhZ2VTaXpl');

@$core.Deprecated('Use keySummaryDescriptor instead')
const KeySummary$json = {
  '1': 'KeySummary',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 12, '10': 'key'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeyType',
      '10': 'type'
    },
    {'1': 'ttl_ms', '3': 3, '4': 1, '5': 3, '10': 'ttlMs'},
  ],
};

/// Descriptor for `KeySummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keySummaryDescriptor = $convert.base64Decode(
    'CgpLZXlTdW1tYXJ5EhAKA2tleRgBIAEoDFIDa2V5EigKBHR5cGUYAiABKA4yFC5xdWVyYXZ1ZS'
    '52MS5LZXlUeXBlUgR0eXBlEhUKBnR0bF9tcxgDIAEoA1IFdHRsTXM=');

@$core.Deprecated('Use scanKeysResponseDescriptor instead')
const ScanKeysResponse$json = {
  '1': 'ScanKeysResponse',
  '2': [
    {
      '1': 'keys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.KeySummary',
      '10': 'keys'
    },
    {'1': 'scanned', '3': 2, '4': 1, '5': 4, '10': 'scanned'},
    {'1': 'done', '3': 3, '4': 1, '5': 8, '10': 'done'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ScanKeysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanKeysResponseDescriptor = $convert.base64Decode(
    'ChBTY2FuS2V5c1Jlc3BvbnNlEisKBGtleXMYASADKAsyFy5xdWVyYXZ1ZS52MS5LZXlTdW1tYX'
    'J5UgRrZXlzEhgKB3NjYW5uZWQYAiABKARSB3NjYW5uZWQSEgoEZG9uZRgDIAEoCFIEZG9uZRIw'
    'CgVlcnJvchgEIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbHVlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use getKeyInfoRequestDescriptor instead')
const GetKeyInfoRequest$json = {
  '1': 'GetKeyInfoRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '10': 'key'},
  ],
};

/// Descriptor for `GetKeyInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKeyInfoRequestDescriptor = $convert.base64Decode(
    'ChFHZXRLZXlJbmZvUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKA1SCGRhdGFiYXNlEhAKA2tleRgDIAEoDFIDa2V5');

@$core.Deprecated('Use getKeyInfoResponseDescriptor instead')
const GetKeyInfoResponse$json = {
  '1': 'GetKeyInfoResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeyType',
      '10': 'type'
    },
    {'1': 'ttl_ms', '3': 2, '4': 1, '5': 3, '10': 'ttlMs'},
    {'1': 'encoding', '3': 3, '4': 1, '5': 9, '10': 'encoding'},
    {'1': 'length', '3': 4, '4': 1, '5': 4, '10': 'length'},
    {
      '1': 'memory_bytes',
      '3': 5,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'memoryBytes',
      '17': true
    },
    {'1': 'big_key', '3': 6, '4': 1, '5': 8, '10': 'bigKey'},
    {
      '1': 'error',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
  '8': [
    {'1': '_memory_bytes'},
  ],
};

/// Descriptor for `GetKeyInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKeyInfoResponseDescriptor = $convert.base64Decode(
    'ChJHZXRLZXlJbmZvUmVzcG9uc2USKAoEdHlwZRgBIAEoDjIULnF1ZXJhdnVlLnYxLktleVR5cG'
    'VSBHR5cGUSFQoGdHRsX21zGAIgASgDUgV0dGxNcxIaCghlbmNvZGluZxgDIAEoCVIIZW5jb2Rp'
    'bmcSFgoGbGVuZ3RoGAQgASgEUgZsZW5ndGgSJgoMbWVtb3J5X2J5dGVzGAUgASgESABSC21lbW'
    '9yeUJ5dGVziAEBEhcKB2JpZ19rZXkYBiABKAhSBmJpZ0tleRIwCgVlcnJvchgHIAEoCzIaLnF1'
    'ZXJhdnVlLnYxLktleVZhbHVlRXJyb3JSBWVycm9yQg8KDV9tZW1vcnlfYnl0ZXM=');

@$core.Deprecated('Use readValueRequestDescriptor instead')
const ReadValueRequest$json = {
  '1': 'ReadValueRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '10': 'key'},
    {'1': 'cursor', '3': 4, '4': 1, '5': 9, '10': 'cursor'},
    {'1': 'page_size', '3': 5, '4': 1, '5': 13, '10': 'pageSize'},
    {'1': 'max_bytes', '3': 6, '4': 1, '5': 13, '10': 'maxBytes'},
    {'1': 'reverse', '3': 7, '4': 1, '5': 8, '10': 'reverse'},
    {'1': 'order_by_score', '3': 8, '4': 1, '5': 8, '10': 'orderByScore'},
  ],
};

/// Descriptor for `ReadValueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readValueRequestDescriptor = $convert.base64Decode(
    'ChBSZWFkVmFsdWVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghkYX'
    'RhYmFzZRgCIAEoDVIIZGF0YWJhc2USEAoDa2V5GAMgASgMUgNrZXkSFgoGY3Vyc29yGAQgASgJ'
    'UgZjdXJzb3ISGwoJcGFnZV9zaXplGAUgASgNUghwYWdlU2l6ZRIbCgltYXhfYnl0ZXMYBiABKA'
    '1SCG1heEJ5dGVzEhgKB3JldmVyc2UYByABKAhSB3JldmVyc2USJAoOb3JkZXJfYnlfc2NvcmUY'
    'CCABKAhSDG9yZGVyQnlTY29yZQ==');

@$core.Deprecated('Use hashEntryDescriptor instead')
const HashEntry$json = {
  '1': 'HashEntry',
  '2': [
    {'1': 'field', '3': 1, '4': 1, '5': 12, '10': 'field'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `HashEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hashEntryDescriptor = $convert.base64Decode(
    'CglIYXNoRW50cnkSFAoFZmllbGQYASABKAxSBWZpZWxkEhQKBXZhbHVlGAIgASgMUgV2YWx1ZQ'
    '==');

@$core.Deprecated('Use zsetEntryDescriptor instead')
const ZsetEntry$json = {
  '1': 'ZsetEntry',
  '2': [
    {'1': 'member', '3': 1, '4': 1, '5': 12, '10': 'member'},
    {'1': 'score', '3': 2, '4': 1, '5': 1, '10': 'score'},
  ],
};

/// Descriptor for `ZsetEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List zsetEntryDescriptor = $convert.base64Decode(
    'Cglac2V0RW50cnkSFgoGbWVtYmVyGAEgASgMUgZtZW1iZXISFAoFc2NvcmUYAiABKAFSBXNjb3'
    'Jl');

@$core.Deprecated('Use streamEntryDescriptor instead')
const StreamEntry$json = {
  '1': 'StreamEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'fields',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.HashEntry',
      '10': 'fields'
    },
  ],
};

/// Descriptor for `StreamEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamEntryDescriptor = $convert.base64Decode(
    'CgtTdHJlYW1FbnRyeRIOCgJpZBgBIAEoCVICaWQSLgoGZmllbGRzGAIgAygLMhYucXVlcmF2dW'
    'UudjEuSGFzaEVudHJ5UgZmaWVsZHM=');

@$core.Deprecated('Use listValuesDescriptor instead')
const ListValues$json = {
  '1': 'ListValues',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 12, '10': 'items'},
    {'1': 'start_index', '3': 2, '4': 1, '5': 4, '10': 'startIndex'},
  ],
};

/// Descriptor for `ListValues`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listValuesDescriptor = $convert.base64Decode(
    'CgpMaXN0VmFsdWVzEhQKBWl0ZW1zGAEgAygMUgVpdGVtcxIfCgtzdGFydF9pbmRleBgCIAEoBF'
    'IKc3RhcnRJbmRleA==');

@$core.Deprecated('Use setValuesDescriptor instead')
const SetValues$json = {
  '1': 'SetValues',
  '2': [
    {'1': 'members', '3': 1, '4': 3, '5': 12, '10': 'members'},
  ],
};

/// Descriptor for `SetValues`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setValuesDescriptor = $convert
    .base64Decode('CglTZXRWYWx1ZXMSGAoHbWVtYmVycxgBIAMoDFIHbWVtYmVycw==');

@$core.Deprecated('Use hashValuesDescriptor instead')
const HashValues$json = {
  '1': 'HashValues',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.HashEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `HashValues`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hashValuesDescriptor = $convert.base64Decode(
    'CgpIYXNoVmFsdWVzEjAKB2VudHJpZXMYASADKAsyFi5xdWVyYXZ1ZS52MS5IYXNoRW50cnlSB2'
    'VudHJpZXM=');

@$core.Deprecated('Use zsetValuesDescriptor instead')
const ZsetValues$json = {
  '1': 'ZsetValues',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ZsetEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ZsetValues`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List zsetValuesDescriptor = $convert.base64Decode(
    'Cgpac2V0VmFsdWVzEjAKB2VudHJpZXMYASADKAsyFi5xdWVyYXZ1ZS52MS5ac2V0RW50cnlSB2'
    'VudHJpZXM=');

@$core.Deprecated('Use streamValuesDescriptor instead')
const StreamValues$json = {
  '1': 'StreamValues',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.StreamEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `StreamValues`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamValuesDescriptor = $convert.base64Decode(
    'CgxTdHJlYW1WYWx1ZXMSMgoHZW50cmllcxgBIAMoCzIYLnF1ZXJhdnVlLnYxLlN0cmVhbUVudH'
    'J5UgdlbnRyaWVz');

@$core.Deprecated('Use stringValueDescriptor instead')
const StringValue$json = {
  '1': 'StringValue',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'total_bytes', '3': 2, '4': 1, '5': 4, '10': 'totalBytes'},
    {'1': 'binary', '3': 3, '4': 1, '5': 8, '10': 'binary'},
  ],
};

/// Descriptor for `StringValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringValueDescriptor = $convert.base64Decode(
    'CgtTdHJpbmdWYWx1ZRISCgRkYXRhGAEgASgMUgRkYXRhEh8KC3RvdGFsX2J5dGVzGAIgASgEUg'
    'p0b3RhbEJ5dGVzEhYKBmJpbmFyeRgDIAEoCFIGYmluYXJ5');

@$core.Deprecated('Use jsonValueDescriptor instead')
const JsonValue$json = {
  '1': 'JsonValue',
  '2': [
    {'1': 'json', '3': 1, '4': 1, '5': 9, '10': 'json'},
  ],
};

/// Descriptor for `JsonValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonValueDescriptor =
    $convert.base64Decode('CglKc29uVmFsdWUSEgoEanNvbhgBIAEoCVIEanNvbg==');

@$core.Deprecated('Use hyperLogLogValueDescriptor instead')
const HyperLogLogValue$json = {
  '1': 'HyperLogLogValue',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 4, '10': 'count'},
  ],
};

/// Descriptor for `HyperLogLogValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hyperLogLogValueDescriptor = $convert
    .base64Decode('ChBIeXBlckxvZ0xvZ1ZhbHVlEhQKBWNvdW50GAEgASgEUgVjb3VudA==');

@$core.Deprecated('Use readValueResponseDescriptor instead')
const ReadValueResponse$json = {
  '1': 'ReadValueResponse',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeyType',
      '10': 'type'
    },
    {
      '1': 'string_value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.StringValue',
      '9': 0,
      '10': 'stringValue'
    },
    {
      '1': 'hash',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.HashValues',
      '9': 0,
      '10': 'hash'
    },
    {
      '1': 'list',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ListValues',
      '9': 0,
      '10': 'list'
    },
    {
      '1': 'set',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SetValues',
      '9': 0,
      '10': 'set'
    },
    {
      '1': 'zset',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ZsetValues',
      '9': 0,
      '10': 'zset'
    },
    {
      '1': 'stream',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.StreamValues',
      '9': 0,
      '10': 'stream'
    },
    {
      '1': 'json',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.JsonValue',
      '9': 0,
      '10': 'json'
    },
    {
      '1': 'hyperloglog',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.HyperLogLogValue',
      '9': 0,
      '10': 'hyperloglog'
    },
    {'1': 'next_cursor', '3': 10, '4': 1, '5': 9, '10': 'nextCursor'},
    {
      '1': 'error',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `ReadValueResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readValueResponseDescriptor = $convert.base64Decode(
    'ChFSZWFkVmFsdWVSZXNwb25zZRIoCgR0eXBlGAEgASgOMhQucXVlcmF2dWUudjEuS2V5VHlwZV'
    'IEdHlwZRI9CgxzdHJpbmdfdmFsdWUYAiABKAsyGC5xdWVyYXZ1ZS52MS5TdHJpbmdWYWx1ZUgA'
    'UgtzdHJpbmdWYWx1ZRItCgRoYXNoGAMgASgLMhcucXVlcmF2dWUudjEuSGFzaFZhbHVlc0gAUg'
    'RoYXNoEi0KBGxpc3QYBCABKAsyFy5xdWVyYXZ1ZS52MS5MaXN0VmFsdWVzSABSBGxpc3QSKgoD'
    'c2V0GAUgASgLMhYucXVlcmF2dWUudjEuU2V0VmFsdWVzSABSA3NldBItCgR6c2V0GAYgASgLMh'
    'cucXVlcmF2dWUudjEuWnNldFZhbHVlc0gAUgR6c2V0EjMKBnN0cmVhbRgHIAEoCzIZLnF1ZXJh'
    'dnVlLnYxLlN0cmVhbVZhbHVlc0gAUgZzdHJlYW0SLAoEanNvbhgIIAEoCzIWLnF1ZXJhdnVlLn'
    'YxLkpzb25WYWx1ZUgAUgRqc29uEkEKC2h5cGVybG9nbG9nGAkgASgLMh0ucXVlcmF2dWUudjEu'
    'SHlwZXJMb2dMb2dWYWx1ZUgAUgtoeXBlcmxvZ2xvZxIfCgtuZXh0X2N1cnNvchgKIAEoCVIKbm'
    'V4dEN1cnNvchIwCgVlcnJvchgLIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbHVlRXJyb3JSBWVy'
    'cm9yQgcKBXZhbHVl');

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp$json = {
  '1': 'WriteOp',
  '2': [
    {
      '1': 'set_string',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.SetString',
      '9': 0,
      '10': 'setString'
    },
    {
      '1': 'hash_set',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.HashSet',
      '9': 0,
      '10': 'hashSet'
    },
    {
      '1': 'hash_delete',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.HashDelete',
      '9': 0,
      '10': 'hashDelete'
    },
    {
      '1': 'list_push',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.ListPush',
      '9': 0,
      '10': 'listPush'
    },
    {
      '1': 'list_set',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.ListSet',
      '9': 0,
      '10': 'listSet'
    },
    {
      '1': 'list_remove',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.ListRemove',
      '9': 0,
      '10': 'listRemove'
    },
    {
      '1': 'set_add',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.SetAdd',
      '9': 0,
      '10': 'setAdd'
    },
    {
      '1': 'set_remove',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.SetRemove',
      '9': 0,
      '10': 'setRemove'
    },
    {
      '1': 'zset_add',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.ZsetAdd',
      '9': 0,
      '10': 'zsetAdd'
    },
    {
      '1': 'zset_remove',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.ZsetRemove',
      '9': 0,
      '10': 'zsetRemove'
    },
    {
      '1': 'stream_add',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.StreamAdd',
      '9': 0,
      '10': 'streamAdd'
    },
    {
      '1': 'stream_delete',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.StreamDelete',
      '9': 0,
      '10': 'streamDelete'
    },
    {
      '1': 'json_set',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp.JsonSet',
      '9': 0,
      '10': 'jsonSet'
    },
  ],
  '3': [
    WriteOp_SetString$json,
    WriteOp_HashSet$json,
    WriteOp_HashDelete$json,
    WriteOp_ListPush$json,
    WriteOp_ListSet$json,
    WriteOp_ListRemove$json,
    WriteOp_SetAdd$json,
    WriteOp_SetRemove$json,
    WriteOp_ZsetAdd$json,
    WriteOp_ZsetRemove$json,
    WriteOp_StreamAdd$json,
    WriteOp_StreamDelete$json,
    WriteOp_JsonSet$json
  ],
  '8': [
    {'1': 'op'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_SetString$json = {
  '1': 'SetString',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_HashSet$json = {
  '1': 'HashSet',
  '2': [
    {'1': 'field', '3': 1, '4': 1, '5': 12, '10': 'field'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_HashDelete$json = {
  '1': 'HashDelete',
  '2': [
    {'1': 'field', '3': 1, '4': 1, '5': 12, '10': 'field'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_ListPush$json = {
  '1': 'ListPush',
  '2': [
    {'1': 'values', '3': 1, '4': 3, '5': 12, '10': 'values'},
    {'1': 'at_head', '3': 2, '4': 1, '5': 8, '10': 'atHead'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_ListSet$json = {
  '1': 'ListSet',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 3, '10': 'index'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_ListRemove$json = {
  '1': 'ListRemove',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
    {'1': 'count', '3': 2, '4': 1, '5': 3, '10': 'count'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_SetAdd$json = {
  '1': 'SetAdd',
  '2': [
    {'1': 'members', '3': 1, '4': 3, '5': 12, '10': 'members'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_SetRemove$json = {
  '1': 'SetRemove',
  '2': [
    {'1': 'members', '3': 1, '4': 3, '5': 12, '10': 'members'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_ZsetAdd$json = {
  '1': 'ZsetAdd',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ZsetEntry',
      '10': 'entries'
    },
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_ZsetRemove$json = {
  '1': 'ZsetRemove',
  '2': [
    {'1': 'members', '3': 1, '4': 3, '5': 12, '10': 'members'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_StreamAdd$json = {
  '1': 'StreamAdd',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'fields',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.HashEntry',
      '10': 'fields'
    },
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_StreamDelete$json = {
  '1': 'StreamDelete',
  '2': [
    {'1': 'ids', '3': 1, '4': 3, '5': 9, '10': 'ids'},
  ],
};

@$core.Deprecated('Use writeOpDescriptor instead')
const WriteOp_JsonSet$json = {
  '1': 'JsonSet',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'json', '3': 2, '4': 1, '5': 9, '10': 'json'},
  ],
};

/// Descriptor for `WriteOp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeOpDescriptor = $convert.base64Decode(
    'CgdXcml0ZU9wEj8KCnNldF9zdHJpbmcYASABKAsyHi5xdWVyYXZ1ZS52MS5Xcml0ZU9wLlNldF'
    'N0cmluZ0gAUglzZXRTdHJpbmcSOQoIaGFzaF9zZXQYAiABKAsyHC5xdWVyYXZ1ZS52MS5Xcml0'
    'ZU9wLkhhc2hTZXRIAFIHaGFzaFNldBJCCgtoYXNoX2RlbGV0ZRgDIAEoCzIfLnF1ZXJhdnVlLn'
    'YxLldyaXRlT3AuSGFzaERlbGV0ZUgAUgpoYXNoRGVsZXRlEjwKCWxpc3RfcHVzaBgEIAEoCzId'
    'LnF1ZXJhdnVlLnYxLldyaXRlT3AuTGlzdFB1c2hIAFIIbGlzdFB1c2gSOQoIbGlzdF9zZXQYBS'
    'ABKAsyHC5xdWVyYXZ1ZS52MS5Xcml0ZU9wLkxpc3RTZXRIAFIHbGlzdFNldBJCCgtsaXN0X3Jl'
    'bW92ZRgGIAEoCzIfLnF1ZXJhdnVlLnYxLldyaXRlT3AuTGlzdFJlbW92ZUgAUgpsaXN0UmVtb3'
    'ZlEjYKB3NldF9hZGQYByABKAsyGy5xdWVyYXZ1ZS52MS5Xcml0ZU9wLlNldEFkZEgAUgZzZXRB'
    'ZGQSPwoKc2V0X3JlbW92ZRgIIAEoCzIeLnF1ZXJhdnVlLnYxLldyaXRlT3AuU2V0UmVtb3ZlSA'
    'BSCXNldFJlbW92ZRI5Cgh6c2V0X2FkZBgJIAEoCzIcLnF1ZXJhdnVlLnYxLldyaXRlT3AuWnNl'
    'dEFkZEgAUgd6c2V0QWRkEkIKC3pzZXRfcmVtb3ZlGAogASgLMh8ucXVlcmF2dWUudjEuV3JpdG'
    'VPcC5ac2V0UmVtb3ZlSABSCnpzZXRSZW1vdmUSPwoKc3RyZWFtX2FkZBgLIAEoCzIeLnF1ZXJh'
    'dnVlLnYxLldyaXRlT3AuU3RyZWFtQWRkSABSCXN0cmVhbUFkZBJICg1zdHJlYW1fZGVsZXRlGA'
    'wgASgLMiEucXVlcmF2dWUudjEuV3JpdGVPcC5TdHJlYW1EZWxldGVIAFIMc3RyZWFtRGVsZXRl'
    'EjkKCGpzb25fc2V0GA0gASgLMhwucXVlcmF2dWUudjEuV3JpdGVPcC5Kc29uU2V0SABSB2pzb2'
    '5TZXQaIQoJU2V0U3RyaW5nEhQKBXZhbHVlGAEgASgMUgV2YWx1ZRo1CgdIYXNoU2V0EhQKBWZp'
    'ZWxkGAEgASgMUgVmaWVsZBIUCgV2YWx1ZRgCIAEoDFIFdmFsdWUaIgoKSGFzaERlbGV0ZRIUCg'
    'VmaWVsZBgBIAEoDFIFZmllbGQaOwoITGlzdFB1c2gSFgoGdmFsdWVzGAEgAygMUgZ2YWx1ZXMS'
    'FwoHYXRfaGVhZBgCIAEoCFIGYXRIZWFkGjUKB0xpc3RTZXQSFAoFaW5kZXgYASABKANSBWluZG'
    'V4EhQKBXZhbHVlGAIgASgMUgV2YWx1ZRo4CgpMaXN0UmVtb3ZlEhQKBXZhbHVlGAEgASgMUgV2'
    'YWx1ZRIUCgVjb3VudBgCIAEoA1IFY291bnQaIgoGU2V0QWRkEhgKB21lbWJlcnMYASADKAxSB2'
    '1lbWJlcnMaJQoJU2V0UmVtb3ZlEhgKB21lbWJlcnMYASADKAxSB21lbWJlcnMaOwoHWnNldEFk'
    'ZBIwCgdlbnRyaWVzGAEgAygLMhYucXVlcmF2dWUudjEuWnNldEVudHJ5UgdlbnRyaWVzGiYKCl'
    'pzZXRSZW1vdmUSGAoHbWVtYmVycxgBIAMoDFIHbWVtYmVycxpLCglTdHJlYW1BZGQSDgoCaWQY'
    'ASABKAlSAmlkEi4KBmZpZWxkcxgCIAMoCzIWLnF1ZXJhdnVlLnYxLkhhc2hFbnRyeVIGZmllbG'
    'RzGiAKDFN0cmVhbURlbGV0ZRIQCgNpZHMYASADKAlSA2lkcxoxCgdKc29uU2V0EhIKBHBhdGgY'
    'ASABKAlSBHBhdGgSEgoEanNvbhgCIAEoCVIEanNvbkIECgJvcA==');

@$core.Deprecated('Use writeValueRequestDescriptor instead')
const WriteValueRequest$json = {
  '1': 'WriteValueRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '10': 'key'},
    {
      '1': 'op',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteOp',
      '10': 'op'
    },
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `WriteValueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeValueRequestDescriptor = $convert.base64Decode(
    'ChFXcml0ZVZhbHVlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKA1SCGRhdGFiYXNlEhAKA2tleRgDIAEoDFIDa2V5EiQKAm9wGAQgASgLMhQu'
    'cXVlcmF2dWUudjEuV3JpdGVPcFICb3ASHAoJY29uZmlybWVkGAUgASgIUgljb25maXJtZWQ=');

@$core.Deprecated('Use writeValueResponseDescriptor instead')
const WriteValueResponse$json = {
  '1': 'WriteValueResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `WriteValueResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeValueResponseDescriptor = $convert.base64Decode(
    'ChJXcml0ZVZhbHVlUmVzcG9uc2USMAoFZXJyb3IYASABKAsyGi5xdWVyYXZ1ZS52MS5LZXlWYW'
    'x1ZUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use renameKeyRequestDescriptor instead')
const RenameKeyRequest$json = {
  '1': 'RenameKeyRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '10': 'key'},
    {'1': 'new_key', '3': 4, '4': 1, '5': 12, '10': 'newKey'},
    {'1': 'overwrite', '3': 5, '4': 1, '5': 8, '10': 'overwrite'},
    {'1': 'confirmed', '3': 6, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `RenameKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameKeyRequestDescriptor = $convert.base64Decode(
    'ChBSZW5hbWVLZXlSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghkYX'
    'RhYmFzZRgCIAEoDVIIZGF0YWJhc2USEAoDa2V5GAMgASgMUgNrZXkSFwoHbmV3X2tleRgEIAEo'
    'DFIGbmV3S2V5EhwKCW92ZXJ3cml0ZRgFIAEoCFIJb3ZlcndyaXRlEhwKCWNvbmZpcm1lZBgGIA'
    'EoCFIJY29uZmlybWVk');

@$core.Deprecated('Use renameKeyResponseDescriptor instead')
const RenameKeyResponse$json = {
  '1': 'RenameKeyResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `RenameKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameKeyResponseDescriptor = $convert.base64Decode(
    'ChFSZW5hbWVLZXlSZXNwb25zZRIwCgVlcnJvchgBIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbH'
    'VlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use setExpiryRequestDescriptor instead')
const SetExpiryRequest$json = {
  '1': 'SetExpiryRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '10': 'key'},
    {'1': 'ttl_ms', '3': 4, '4': 1, '5': 4, '9': 0, '10': 'ttlMs', '17': true},
  ],
  '8': [
    {'1': '_ttl_ms'},
  ],
};

/// Descriptor for `SetExpiryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setExpiryRequestDescriptor = $convert.base64Decode(
    'ChBTZXRFeHBpcnlSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghkYX'
    'RhYmFzZRgCIAEoDVIIZGF0YWJhc2USEAoDa2V5GAMgASgMUgNrZXkSGgoGdHRsX21zGAQgASgE'
    'SABSBXR0bE1ziAEBQgkKB190dGxfbXM=');

@$core.Deprecated('Use setExpiryResponseDescriptor instead')
const SetExpiryResponse$json = {
  '1': 'SetExpiryResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SetExpiryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setExpiryResponseDescriptor = $convert.base64Decode(
    'ChFTZXRFeHBpcnlSZXNwb25zZRIwCgVlcnJvchgBIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbH'
    'VlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use deleteKeysRequestDescriptor instead')
const DeleteKeysRequest$json = {
  '1': 'DeleteKeysRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'keys', '3': 3, '4': 3, '5': 12, '10': 'keys'},
    {'1': 'confirmed', '3': 4, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `DeleteKeysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteKeysRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVLZXlzUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKA1SCGRhdGFiYXNlEhIKBGtleXMYAyADKAxSBGtleXMSHAoJY29uZmlybWVk'
    'GAQgASgIUgljb25maXJtZWQ=');

@$core.Deprecated('Use deleteKeysResponseDescriptor instead')
const DeleteKeysResponse$json = {
  '1': 'DeleteKeysResponse',
  '2': [
    {'1': 'deleted', '3': 1, '4': 1, '5': 4, '10': 'deleted'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `DeleteKeysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteKeysResponseDescriptor = $convert.base64Decode(
    'ChJEZWxldGVLZXlzUmVzcG9uc2USGAoHZGVsZXRlZBgBIAEoBFIHZGVsZXRlZBIwCgVlcnJvch'
    'gCIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbHVlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use executeCommandRequestDescriptor instead')
const ExecuteCommandRequest$json = {
  '1': 'ExecuteCommandRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 13, '10': 'database'},
    {'1': 'args', '3': 3, '4': 3, '5': 12, '10': 'args'},
    {'1': 'confirmed', '3': 4, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `ExecuteCommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeCommandRequestDescriptor = $convert.base64Decode(
    'ChVFeGVjdXRlQ29tbWFuZFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'oKCGRhdGFiYXNlGAIgASgNUghkYXRhYmFzZRISCgRhcmdzGAMgAygMUgRhcmdzEhwKCWNvbmZp'
    'cm1lZBgEIAEoCFIJY29uZmlybWVk');

@$core.Deprecated('Use respValueDescriptor instead')
const RespValue$json = {
  '1': 'RespValue',
  '2': [
    {'1': 'string_value', '3': 1, '4': 1, '5': 12, '9': 0, '10': 'stringValue'},
    {'1': 'integer', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'integer'},
    {'1': 'double_value', '3': 3, '4': 1, '5': 1, '9': 0, '10': 'doubleValue'},
    {'1': 'boolean', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'boolean'},
    {'1': 'nil', '3': 5, '4': 1, '5': 8, '9': 0, '10': 'nil'},
    {
      '1': 'array',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue.Items',
      '9': 0,
      '10': 'array'
    },
    {
      '1': 'map',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue.Entries',
      '9': 0,
      '10': 'map'
    },
    {
      '1': 'set',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue.Items',
      '9': 0,
      '10': 'set'
    },
    {
      '1': 'verbatim',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue.Verbatim',
      '9': 0,
      '10': 'verbatim'
    },
    {'1': 'error', '3': 10, '4': 1, '5': 9, '9': 0, '10': 'error'},
  ],
  '3': [
    RespValue_MapEntry$json,
    RespValue_Items$json,
    RespValue_Entries$json,
    RespValue_Verbatim$json
  ],
  '8': [
    {'1': 'kind'},
  ],
};

@$core.Deprecated('Use respValueDescriptor instead')
const RespValue_MapEntry$json = {
  '1': 'MapEntry',
  '2': [
    {
      '1': 'key',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue',
      '10': 'key'
    },
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue',
      '10': 'value'
    },
  ],
};

@$core.Deprecated('Use respValueDescriptor instead')
const RespValue_Items$json = {
  '1': 'Items',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.RespValue',
      '10': 'items'
    },
  ],
};

@$core.Deprecated('Use respValueDescriptor instead')
const RespValue_Entries$json = {
  '1': 'Entries',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.RespValue.MapEntry',
      '10': 'entries'
    },
  ],
};

@$core.Deprecated('Use respValueDescriptor instead')
const RespValue_Verbatim$json = {
  '1': 'Verbatim',
  '2': [
    {'1': 'format', '3': 1, '4': 1, '5': 9, '10': 'format'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `RespValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respValueDescriptor = $convert.base64Decode(
    'CglSZXNwVmFsdWUSIwoMc3RyaW5nX3ZhbHVlGAEgASgMSABSC3N0cmluZ1ZhbHVlEhoKB2ludG'
    'VnZXIYAiABKANIAFIHaW50ZWdlchIjCgxkb3VibGVfdmFsdWUYAyABKAFIAFILZG91YmxlVmFs'
    'dWUSGgoHYm9vbGVhbhgEIAEoCEgAUgdib29sZWFuEhIKA25pbBgFIAEoCEgAUgNuaWwSNAoFYX'
    'JyYXkYBiABKAsyHC5xdWVyYXZ1ZS52MS5SZXNwVmFsdWUuSXRlbXNIAFIFYXJyYXkSMgoDbWFw'
    'GAcgASgLMh4ucXVlcmF2dWUudjEuUmVzcFZhbHVlLkVudHJpZXNIAFIDbWFwEjAKA3NldBgIIA'
    'EoCzIcLnF1ZXJhdnVlLnYxLlJlc3BWYWx1ZS5JdGVtc0gAUgNzZXQSPQoIdmVyYmF0aW0YCSAB'
    'KAsyHy5xdWVyYXZ1ZS52MS5SZXNwVmFsdWUuVmVyYmF0aW1IAFIIdmVyYmF0aW0SFgoFZXJyb3'
    'IYCiABKAlIAFIFZXJyb3IaYgoITWFwRW50cnkSKAoDa2V5GAEgASgLMhYucXVlcmF2dWUudjEu'
    'UmVzcFZhbHVlUgNrZXkSLAoFdmFsdWUYAiABKAsyFi5xdWVyYXZ1ZS52MS5SZXNwVmFsdWVSBX'
    'ZhbHVlGjUKBUl0ZW1zEiwKBWl0ZW1zGAEgAygLMhYucXVlcmF2dWUudjEuUmVzcFZhbHVlUgVp'
    'dGVtcxpECgdFbnRyaWVzEjkKB2VudHJpZXMYASADKAsyHy5xdWVyYXZ1ZS52MS5SZXNwVmFsdW'
    'UuTWFwRW50cnlSB2VudHJpZXMaNgoIVmVyYmF0aW0SFgoGZm9ybWF0GAEgASgJUgZmb3JtYXQS'
    'EgoEdGV4dBgCIAEoCVIEdGV4dEIGCgRraW5k');

@$core.Deprecated('Use executeCommandResponseDescriptor instead')
const ExecuteCommandResponse$json = {
  '1': 'ExecuteCommandResponse',
  '2': [
    {
      '1': 'reply',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RespValue',
      '10': 'reply'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
    {'1': 'elapsed_ms', '3': 3, '4': 1, '5': 13, '10': 'elapsedMs'},
  ],
};

/// Descriptor for `ExecuteCommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeCommandResponseDescriptor = $convert.base64Decode(
    'ChZFeGVjdXRlQ29tbWFuZFJlc3BvbnNlEiwKBXJlcGx5GAEgASgLMhYucXVlcmF2dWUudjEuUm'
    'VzcFZhbHVlUgVyZXBseRIwCgVlcnJvchgCIAEoCzIaLnF1ZXJhdnVlLnYxLktleVZhbHVlRXJy'
    'b3JSBWVycm9yEh0KCmVsYXBzZWRfbXMYAyABKA1SCWVsYXBzZWRNcw==');

@$core.Deprecated('Use subscribeRequestDescriptor instead')
const SubscribeRequest$json = {
  '1': 'SubscribeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'channels', '3': 2, '4': 3, '5': 9, '10': 'channels'},
    {'1': 'patterns', '3': 3, '4': 3, '5': 9, '10': 'patterns'},
  ],
};

/// Descriptor for `SubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeRequestDescriptor = $convert.base64Decode(
    'ChBTdWJzY3JpYmVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghjaG'
    'FubmVscxgCIAMoCVIIY2hhbm5lbHMSGgoIcGF0dGVybnMYAyADKAlSCHBhdHRlcm5z');

@$core.Deprecated('Use subscribeResponseDescriptor instead')
const SubscribeResponse$json = {
  '1': 'SubscribeResponse',
  '2': [
    {'1': 'channel', '3': 1, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'pattern', '3': 2, '4': 1, '5': 9, '10': 'pattern'},
    {'1': 'payload', '3': 3, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'received_unix_ms', '3': 4, '4': 1, '5': 3, '10': 'receivedUnixMs'},
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SubscribeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeResponseDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpYmVSZXNwb25zZRIYCgdjaGFubmVsGAEgASgJUgdjaGFubmVsEhgKB3BhdHRlcm'
    '4YAiABKAlSB3BhdHRlcm4SGAoHcGF5bG9hZBgDIAEoDFIHcGF5bG9hZBIoChByZWNlaXZlZF91'
    'bml4X21zGAQgASgDUg5yZWNlaXZlZFVuaXhNcxIwCgVlcnJvchgFIAEoCzIaLnF1ZXJhdnVlLn'
    'YxLktleVZhbHVlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use publishRequestDescriptor instead')
const PublishRequest$json = {
  '1': 'PublishRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'channel', '3': 2, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'payload', '3': 3, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `PublishRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishRequestDescriptor = $convert.base64Decode(
    'Cg5QdWJsaXNoUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGAoHY2hhbm'
    '5lbBgCIAEoCVIHY2hhbm5lbBIYCgdwYXlsb2FkGAMgASgMUgdwYXlsb2Fk');

@$core.Deprecated('Use publishResponseDescriptor instead')
const PublishResponse$json = {
  '1': 'PublishResponse',
  '2': [
    {'1': 'receivers', '3': 1, '4': 1, '5': 4, '10': 'receivers'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.KeyValueError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `PublishResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishResponseDescriptor = $convert.base64Decode(
    'Cg9QdWJsaXNoUmVzcG9uc2USHAoJcmVjZWl2ZXJzGAEgASgEUglyZWNlaXZlcnMSMAoFZXJyb3'
    'IYAiABKAsyGi5xdWVyYXZ1ZS52MS5LZXlWYWx1ZUVycm9yUgVlcnJvcg==');
