// This is a generated file - do not edit.
//
// Generated from queravue/v1/query.proto.

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

@$core.Deprecated('Use executeModeDescriptor instead')
const ExecuteMode$json = {
  '1': 'ExecuteMode',
  '2': [
    {'1': 'EXECUTE_MODE_UNSPECIFIED', '2': 0},
    {'1': 'EXECUTE_MODE_STATEMENT_AT_CURSOR', '2': 1},
    {'1': 'EXECUTE_MODE_SELECTION', '2': 2},
    {'1': 'EXECUTE_MODE_ALL', '2': 3},
  ],
};

/// Descriptor for `ExecuteMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List executeModeDescriptor = $convert.base64Decode(
    'CgtFeGVjdXRlTW9kZRIcChhFWEVDVVRFX01PREVfVU5TUEVDSUZJRUQQABIkCiBFWEVDVVRFX0'
    '1PREVfU1RBVEVNRU5UX0FUX0NVUlNPUhABEhoKFkVYRUNVVEVfTU9ERV9TRUxFQ1RJT04QAhIU'
    'ChBFWEVDVVRFX01PREVfQUxMEAM=');

@$core.Deprecated('Use valueKindDescriptor instead')
const ValueKind$json = {
  '1': 'ValueKind',
  '2': [
    {'1': 'VALUE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'VALUE_KIND_BOOL', '2': 1},
    {'1': 'VALUE_KIND_INT', '2': 2},
    {'1': 'VALUE_KIND_FLOAT', '2': 3},
    {'1': 'VALUE_KIND_DECIMAL', '2': 4},
    {'1': 'VALUE_KIND_TEXT', '2': 5},
    {'1': 'VALUE_KIND_BYTES', '2': 6},
    {'1': 'VALUE_KIND_TIMESTAMPTZ', '2': 7},
    {'1': 'VALUE_KIND_JSON', '2': 8},
    {'1': 'VALUE_KIND_UUID', '2': 9},
    {'1': 'VALUE_KIND_ARRAY', '2': 10},
  ],
};

/// Descriptor for `ValueKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List valueKindDescriptor = $convert.base64Decode(
    'CglWYWx1ZUtpbmQSGgoWVkFMVUVfS0lORF9VTlNQRUNJRklFRBAAEhMKD1ZBTFVFX0tJTkRfQk'
    '9PTBABEhIKDlZBTFVFX0tJTkRfSU5UEAISFAoQVkFMVUVfS0lORF9GTE9BVBADEhYKElZBTFVF'
    'X0tJTkRfREVDSU1BTBAEEhMKD1ZBTFVFX0tJTkRfVEVYVBAFEhQKEFZBTFVFX0tJTkRfQllURV'
    'MQBhIaChZWQUxVRV9LSU5EX1RJTUVTVEFNUFRaEAcSEwoPVkFMVUVfS0lORF9KU09OEAgSEwoP'
    'VkFMVUVfS0lORF9VVUlEEAkSFAoQVkFMVUVfS0lORF9BUlJBWRAK');

@$core.Deprecated('Use queryErrorKindDescriptor instead')
const QueryErrorKind$json = {
  '1': 'QueryErrorKind',
  '2': [
    {'1': 'QUERY_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'QUERY_ERROR_KIND_SQL', '2': 1},
    {'1': 'QUERY_ERROR_KIND_CANCELED', '2': 2},
    {'1': 'QUERY_ERROR_KIND_CONNECTION', '2': 3},
    {'1': 'QUERY_ERROR_KIND_UNSUPPORTED', '2': 4},
  ],
};

/// Descriptor for `QueryErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List queryErrorKindDescriptor = $convert.base64Decode(
    'Cg5RdWVyeUVycm9yS2luZBIgChxRVUVSWV9FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEAASGAoUUV'
    'VFUllfRVJST1JfS0lORF9TUUwQARIdChlRVUVSWV9FUlJPUl9LSU5EX0NBTkNFTEVEEAISHwob'
    'UVVFUllfRVJST1JfS0lORF9DT05ORUNUSU9OEAMSIAocUVVFUllfRVJST1JfS0lORF9VTlNVUF'
    'BPUlRFRBAE');

@$core.Deprecated('Use copyFormatDescriptor instead')
const CopyFormat$json = {
  '1': 'CopyFormat',
  '2': [
    {'1': 'COPY_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'COPY_FORMAT_TSV', '2': 1},
    {'1': 'COPY_FORMAT_CSV', '2': 2},
    {'1': 'COPY_FORMAT_JSON', '2': 3},
  ],
};

/// Descriptor for `CopyFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List copyFormatDescriptor = $convert.base64Decode(
    'CgpDb3B5Rm9ybWF0EhsKF0NPUFlfRk9STUFUX1VOU1BFQ0lGSUVEEAASEwoPQ09QWV9GT1JNQV'
    'RfVFNWEAESEwoPQ09QWV9GT1JNQVRfQ1NWEAISFAoQQ09QWV9GT1JNQVRfSlNPThAD');

@$core.Deprecated('Use textRangeDescriptor instead')
const TextRange$json = {
  '1': 'TextRange',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 13, '10': 'start'},
    {'1': 'end', '3': 2, '4': 1, '5': 13, '10': 'end'},
  ],
};

/// Descriptor for `TextRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textRangeDescriptor = $convert.base64Decode(
    'CglUZXh0UmFuZ2USFAoFc3RhcnQYASABKA1SBXN0YXJ0EhAKA2VuZBgCIAEoDVIDZW5k');

@$core.Deprecated('Use columnDescriptor instead')
const Column$json = {
  '1': 'Column',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type_name', '3': 2, '4': 1, '5': 9, '10': 'typeName'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ValueKind',
      '10': 'kind'
    },
  ],
};

/// Descriptor for `Column`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnDescriptor = $convert.base64Decode(
    'CgZDb2x1bW4SEgoEbmFtZRgBIAEoCVIEbmFtZRIbCgl0eXBlX25hbWUYAiABKAlSCHR5cGVOYW'
    '1lEioKBGtpbmQYAyABKA4yFi5xdWVyYXZ1ZS52MS5WYWx1ZUtpbmRSBGtpbmQ=');

@$core.Deprecated('Use arrayValueDescriptor instead')
const ArrayValue$json = {
  '1': 'ArrayValue',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'values'
    },
  ],
};

/// Descriptor for `ArrayValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arrayValueDescriptor = $convert.base64Decode(
    'CgpBcnJheVZhbHVlEioKBnZhbHVlcxgBIAMoCzISLnF1ZXJhdnVlLnYxLlZhbHVlUgZ2YWx1ZX'
    'M=');

@$core.Deprecated('Use valueDescriptor instead')
const Value$json = {
  '1': 'Value',
  '2': [
    {
      '1': 'null_value',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.google.protobuf.NullValue',
      '9': 0,
      '10': 'nullValue'
    },
    {'1': 'bool_value', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'boolValue'},
    {'1': 'int_value', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'intValue'},
    {'1': 'double_value', '3': 4, '4': 1, '5': 1, '9': 0, '10': 'doubleValue'},
    {
      '1': 'decimal_value',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'decimalValue'
    },
    {'1': 'text_value', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'textValue'},
    {'1': 'bytes_value', '3': 7, '4': 1, '5': 12, '9': 0, '10': 'bytesValue'},
    {
      '1': 'timestamp_value',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '9': 0,
      '10': 'timestampValue'
    },
    {'1': 'json_value', '3': 9, '4': 1, '5': 9, '9': 0, '10': 'jsonValue'},
    {'1': 'uuid_value', '3': 10, '4': 1, '5': 9, '9': 0, '10': 'uuidValue'},
    {
      '1': 'array_value',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ArrayValue',
      '9': 0,
      '10': 'arrayValue'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode(
    'CgVWYWx1ZRI7CgpudWxsX3ZhbHVlGAEgASgOMhouZ29vZ2xlLnByb3RvYnVmLk51bGxWYWx1ZU'
    'gAUgludWxsVmFsdWUSHwoKYm9vbF92YWx1ZRgCIAEoCEgAUglib29sVmFsdWUSHQoJaW50X3Zh'
    'bHVlGAMgASgDSABSCGludFZhbHVlEiMKDGRvdWJsZV92YWx1ZRgEIAEoAUgAUgtkb3VibGVWYW'
    'x1ZRIlCg1kZWNpbWFsX3ZhbHVlGAUgASgJSABSDGRlY2ltYWxWYWx1ZRIfCgp0ZXh0X3ZhbHVl'
    'GAYgASgJSABSCXRleHRWYWx1ZRIhCgtieXRlc192YWx1ZRgHIAEoDEgAUgpieXRlc1ZhbHVlEk'
    'UKD3RpbWVzdGFtcF92YWx1ZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBIAFIO'
    'dGltZXN0YW1wVmFsdWUSHwoKanNvbl92YWx1ZRgJIAEoCUgAUglqc29uVmFsdWUSHwoKdXVpZF'
    '92YWx1ZRgKIAEoCUgAUgl1dWlkVmFsdWUSOgoLYXJyYXlfdmFsdWUYCyABKAsyFy5xdWVyYXZ1'
    'ZS52MS5BcnJheVZhbHVlSABSCmFycmF5VmFsdWVCBgoEa2luZA==');

@$core.Deprecated('Use rowDescriptor instead')
const Row$json = {
  '1': 'Row',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'values'
    },
  ],
};

/// Descriptor for `Row`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowDescriptor = $convert.base64Decode(
    'CgNSb3cSKgoGdmFsdWVzGAEgAygLMhIucXVlcmF2dWUudjEuVmFsdWVSBnZhbHVlcw==');

@$core.Deprecated('Use rowBatchDescriptor instead')
const RowBatch$json = {
  '1': 'RowBatch',
  '2': [
    {
      '1': 'rows',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Row',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `RowBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowBatchDescriptor = $convert.base64Decode(
    'CghSb3dCYXRjaBIkCgRyb3dzGAEgAygLMhAucXVlcmF2dWUudjEuUm93UgRyb3dz');

@$core.Deprecated('Use statementRangeDescriptor instead')
const StatementRange$json = {
  '1': 'StatementRange',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {
      '1': 'range',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TextRange',
      '10': 'range'
    },
  ],
};

/// Descriptor for `StatementRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementRangeDescriptor = $convert.base64Decode(
    'Cg5TdGF0ZW1lbnRSYW5nZRIUCgVpbmRleBgBIAEoDVIFaW5kZXgSLAoFcmFuZ2UYAiABKAsyFi'
    '5xdWVyYXZ1ZS52MS5UZXh0UmFuZ2VSBXJhbmdl');

@$core.Deprecated('Use executeRequestDescriptor instead')
const ExecuteRequest$json = {
  '1': 'ExecuteRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'cursor_offset', '3': 3, '4': 1, '5': 13, '10': 'cursorOffset'},
    {
      '1': 'mode',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ExecuteMode',
      '10': 'mode'
    },
    {
      '1': 'selection',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TextRange',
      '10': 'selection'
    },
    {
      '1': 'params',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'params'
    },
  ],
};

/// Descriptor for `ExecuteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeRequestDescriptor = $convert.base64Decode(
    'Cg5FeGVjdXRlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEdGV4dB'
    'gCIAEoCVIEdGV4dBIjCg1jdXJzb3Jfb2Zmc2V0GAMgASgNUgxjdXJzb3JPZmZzZXQSLAoEbW9k'
    'ZRgEIAEoDjIYLnF1ZXJhdnVlLnYxLkV4ZWN1dGVNb2RlUgRtb2RlEjQKCXNlbGVjdGlvbhgFIA'
    'EoCzIWLnF1ZXJhdnVlLnYxLlRleHRSYW5nZVIJc2VsZWN0aW9uEioKBnBhcmFtcxgGIAMoCzIS'
    'LnF1ZXJhdnVlLnYxLlZhbHVlUgZwYXJhbXM=');

@$core.Deprecated('Use statementPlanDescriptor instead')
const StatementPlan$json = {
  '1': 'StatementPlan',
  '2': [
    {
      '1': 'statements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.StatementRange',
      '10': 'statements'
    },
  ],
};

/// Descriptor for `StatementPlan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementPlanDescriptor = $convert.base64Decode(
    'Cg1TdGF0ZW1lbnRQbGFuEjsKCnN0YXRlbWVudHMYASADKAsyGy5xdWVyYXZ1ZS52MS5TdGF0ZW'
    '1lbnRSYW5nZVIKc3RhdGVtZW50cw==');

@$core.Deprecated('Use statementStartedDescriptor instead')
const StatementStarted$json = {
  '1': 'StatementStarted',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {'1': 'result_id', '3': 2, '4': 1, '5': 9, '10': 'resultId'},
  ],
};

/// Descriptor for `StatementStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementStartedDescriptor = $convert.base64Decode(
    'ChBTdGF0ZW1lbnRTdGFydGVkEicKD3N0YXRlbWVudF9pbmRleBgBIAEoDVIOc3RhdGVtZW50SW'
    '5kZXgSGwoJcmVzdWx0X2lkGAIgASgJUghyZXN1bHRJZA==');

@$core.Deprecated('Use columnsDescriptor instead')
const Columns$json = {
  '1': 'Columns',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {
      '1': 'columns',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Column',
      '10': 'columns'
    },
  ],
};

/// Descriptor for `Columns`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnsDescriptor = $convert.base64Decode(
    'CgdDb2x1bW5zEicKD3N0YXRlbWVudF9pbmRleBgBIAEoDVIOc3RhdGVtZW50SW5kZXgSLQoHY2'
    '9sdW1ucxgCIAMoCzITLnF1ZXJhdnVlLnYxLkNvbHVtblIHY29sdW1ucw==');

@$core.Deprecated('Use rowsWindowDescriptor instead')
const RowsWindow$json = {
  '1': 'RowsWindow',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {'1': 'offset', '3': 2, '4': 1, '5': 4, '10': 'offset'},
    {
      '1': 'rows',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Row',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `RowsWindow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowsWindowDescriptor = $convert.base64Decode(
    'CgpSb3dzV2luZG93EicKD3N0YXRlbWVudF9pbmRleBgBIAEoDVIOc3RhdGVtZW50SW5kZXgSFg'
    'oGb2Zmc2V0GAIgASgEUgZvZmZzZXQSJAoEcm93cxgDIAMoCzIQLnF1ZXJhdnVlLnYxLlJvd1IE'
    'cm93cw==');

@$core.Deprecated('Use progressDescriptor instead')
const Progress$json = {
  '1': 'Progress',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {'1': 'rows_spooled', '3': 2, '4': 1, '5': 4, '10': 'rowsSpooled'},
    {'1': 'done', '3': 3, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `Progress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List progressDescriptor = $convert.base64Decode(
    'CghQcm9ncmVzcxInCg9zdGF0ZW1lbnRfaW5kZXgYASABKA1SDnN0YXRlbWVudEluZGV4EiEKDH'
    'Jvd3Nfc3Bvb2xlZBgCIAEoBFILcm93c1Nwb29sZWQSEgoEZG9uZRgDIAEoCFIEZG9uZQ==');

@$core.Deprecated('Use summaryDescriptor instead')
const Summary$json = {
  '1': 'Summary',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {'1': 'rows_affected', '3': 2, '4': 1, '5': 4, '10': 'rowsAffected'},
    {'1': 'rows_spooled', '3': 3, '4': 1, '5': 4, '10': 'rowsSpooled'},
    {
      '1': 'duration',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
    {'1': 'notices', '3': 5, '4': 3, '5': 9, '10': 'notices'},
    {'1': 'truncated', '3': 6, '4': 1, '5': 8, '10': 'truncated'},
    {'1': 'has_rows', '3': 7, '4': 1, '5': 8, '10': 'hasRows'},
  ],
};

/// Descriptor for `Summary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List summaryDescriptor = $convert.base64Decode(
    'CgdTdW1tYXJ5EicKD3N0YXRlbWVudF9pbmRleBgBIAEoDVIOc3RhdGVtZW50SW5kZXgSIwoNcm'
    '93c19hZmZlY3RlZBgCIAEoBFIMcm93c0FmZmVjdGVkEiEKDHJvd3Nfc3Bvb2xlZBgDIAEoBFIL'
    'cm93c1Nwb29sZWQSNQoIZHVyYXRpb24YBCABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb2'
    '5SCGR1cmF0aW9uEhgKB25vdGljZXMYBSADKAlSB25vdGljZXMSHAoJdHJ1bmNhdGVkGAYgASgI'
    'Ugl0cnVuY2F0ZWQSGQoIaGFzX3Jvd3MYByABKAhSB2hhc1Jvd3M=');

@$core.Deprecated('Use executeErrorDescriptor instead')
const ExecuteError$json = {
  '1': 'ExecuteError',
  '2': [
    {'1': 'statement_index', '3': 1, '4': 1, '5': 13, '10': 'statementIndex'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.QueryErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'position',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'position',
      '17': true
    },
    {
      '1': 'duration',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
  ],
  '8': [
    {'1': '_position'},
  ],
};

/// Descriptor for `ExecuteError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeErrorDescriptor = $convert.base64Decode(
    'CgxFeGVjdXRlRXJyb3ISJwoPc3RhdGVtZW50X2luZGV4GAEgASgNUg5zdGF0ZW1lbnRJbmRleB'
    'IvCgRraW5kGAIgASgOMhsucXVlcmF2dWUudjEuUXVlcnlFcnJvcktpbmRSBGtpbmQSGAoHbWVz'
    'c2FnZRgDIAEoCVIHbWVzc2FnZRIfCghwb3NpdGlvbhgEIAEoDUgAUghwb3NpdGlvbogBARI1Cg'
    'hkdXJhdGlvbhgFIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIIZHVyYXRpb25CCwoJ'
    'X3Bvc2l0aW9u');

@$core.Deprecated('Use executeResponseDescriptor instead')
const ExecuteResponse$json = {
  '1': 'ExecuteResponse',
  '2': [
    {
      '1': 'plan',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.StatementPlan',
      '9': 0,
      '10': 'plan'
    },
    {
      '1': 'started',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.StatementStarted',
      '9': 0,
      '10': 'started'
    },
    {
      '1': 'columns',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Columns',
      '9': 0,
      '10': 'columns'
    },
    {
      '1': 'rows',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RowsWindow',
      '9': 0,
      '10': 'rows'
    },
    {
      '1': 'progress',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Progress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'summary',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Summary',
      '9': 0,
      '10': 'summary'
    },
    {
      '1': 'error',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExecuteError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ExecuteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeResponseDescriptor = $convert.base64Decode(
    'Cg9FeGVjdXRlUmVzcG9uc2USMAoEcGxhbhgBIAEoCzIaLnF1ZXJhdnVlLnYxLlN0YXRlbWVudF'
    'BsYW5IAFIEcGxhbhI5CgdzdGFydGVkGAIgASgLMh0ucXVlcmF2dWUudjEuU3RhdGVtZW50U3Rh'
    'cnRlZEgAUgdzdGFydGVkEjAKB2NvbHVtbnMYAyABKAsyFC5xdWVyYXZ1ZS52MS5Db2x1bW5zSA'
    'BSB2NvbHVtbnMSLQoEcm93cxgEIAEoCzIXLnF1ZXJhdnVlLnYxLlJvd3NXaW5kb3dIAFIEcm93'
    'cxIzCghwcm9ncmVzcxgFIAEoCzIVLnF1ZXJhdnVlLnYxLlByb2dyZXNzSABSCHByb2dyZXNzEj'
    'AKB3N1bW1hcnkYBiABKAsyFC5xdWVyYXZ1ZS52MS5TdW1tYXJ5SABSB3N1bW1hcnkSMQoFZXJy'
    'b3IYByABKAsyGS5xdWVyYXZ1ZS52MS5FeGVjdXRlRXJyb3JIAFIFZXJyb3JCBwoFZXZlbnQ=');

@$core.Deprecated('Use fetchRowsRequestDescriptor instead')
const FetchRowsRequest$json = {
  '1': 'FetchRowsRequest',
  '2': [
    {'1': 'result_id', '3': 1, '4': 1, '5': 9, '10': 'resultId'},
    {'1': 'offset', '3': 2, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `FetchRowsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchRowsRequestDescriptor = $convert.base64Decode(
    'ChBGZXRjaFJvd3NSZXF1ZXN0EhsKCXJlc3VsdF9pZBgBIAEoCVIIcmVzdWx0SWQSFgoGb2Zmc2'
    'V0GAIgASgEUgZvZmZzZXQSFAoFbGltaXQYAyABKA1SBWxpbWl0');

@$core.Deprecated('Use fetchRowsResponseDescriptor instead')
const FetchRowsResponse$json = {
  '1': 'FetchRowsResponse',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 4, '10': 'offset'},
    {
      '1': 'rows',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Row',
      '10': 'rows'
    },
    {'1': 'rows_spooled', '3': 3, '4': 1, '5': 4, '10': 'rowsSpooled'},
    {'1': 'done', '3': 4, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `FetchRowsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchRowsResponseDescriptor = $convert.base64Decode(
    'ChFGZXRjaFJvd3NSZXNwb25zZRIWCgZvZmZzZXQYASABKARSBm9mZnNldBIkCgRyb3dzGAIgAy'
    'gLMhAucXVlcmF2dWUudjEuUm93UgRyb3dzEiEKDHJvd3Nfc3Bvb2xlZBgDIAEoBFILcm93c1Nw'
    'b29sZWQSEgoEZG9uZRgEIAEoCFIEZG9uZQ==');

@$core.Deprecated('Use cancelRequestDescriptor instead')
const CancelRequest$json = {
  '1': 'CancelRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `CancelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelRequestDescriptor = $convert.base64Decode(
    'Cg1DYW5jZWxSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA==');

@$core.Deprecated('Use cancelResponseDescriptor instead')
const CancelResponse$json = {
  '1': 'CancelResponse',
};

/// Descriptor for `CancelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelResponseDescriptor =
    $convert.base64Decode('Cg5DYW5jZWxSZXNwb25zZQ==');

@$core.Deprecated('Use closeResultRequestDescriptor instead')
const CloseResultRequest$json = {
  '1': 'CloseResultRequest',
  '2': [
    {'1': 'result_id', '3': 1, '4': 1, '5': 9, '10': 'resultId'},
  ],
};

/// Descriptor for `CloseResultRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeResultRequestDescriptor =
    $convert.base64Decode(
        'ChJDbG9zZVJlc3VsdFJlcXVlc3QSGwoJcmVzdWx0X2lkGAEgASgJUghyZXN1bHRJZA==');

@$core.Deprecated('Use closeResultResponseDescriptor instead')
const CloseResultResponse$json = {
  '1': 'CloseResultResponse',
};

/// Descriptor for `CloseResultResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeResultResponseDescriptor =
    $convert.base64Decode('ChNDbG9zZVJlc3VsdFJlc3BvbnNl');

@$core.Deprecated('Use rowRangeDescriptor instead')
const RowRange$json = {
  '1': 'RowRange',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 4, '10': 'start'},
    {'1': 'end', '3': 2, '4': 1, '5': 4, '10': 'end'},
  ],
};

/// Descriptor for `RowRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowRangeDescriptor = $convert.base64Decode(
    'CghSb3dSYW5nZRIUCgVzdGFydBgBIAEoBFIFc3RhcnQSEAoDZW5kGAIgASgEUgNlbmQ=');

@$core.Deprecated('Use copyRangeRequestDescriptor instead')
const CopyRangeRequest$json = {
  '1': 'CopyRangeRequest',
  '2': [
    {'1': 'result_id', '3': 1, '4': 1, '5': 9, '10': 'resultId'},
    {
      '1': 'row_range',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RowRange',
      '10': 'rowRange'
    },
    {'1': 'column_indices', '3': 3, '4': 3, '5': 13, '10': 'columnIndices'},
    {
      '1': 'format',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CopyFormat',
      '10': 'format'
    },
    {'1': 'include_header', '3': 5, '4': 1, '5': 8, '10': 'includeHeader'},
  ],
};

/// Descriptor for `CopyRangeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copyRangeRequestDescriptor = $convert.base64Decode(
    'ChBDb3B5UmFuZ2VSZXF1ZXN0EhsKCXJlc3VsdF9pZBgBIAEoCVIIcmVzdWx0SWQSMgoJcm93X3'
    'JhbmdlGAIgASgLMhUucXVlcmF2dWUudjEuUm93UmFuZ2VSCHJvd1JhbmdlEiUKDmNvbHVtbl9p'
    'bmRpY2VzGAMgAygNUg1jb2x1bW5JbmRpY2VzEi8KBmZvcm1hdBgEIAEoDjIXLnF1ZXJhdnVlLn'
    'YxLkNvcHlGb3JtYXRSBmZvcm1hdBIlCg5pbmNsdWRlX2hlYWRlchgFIAEoCFINaW5jbHVkZUhl'
    'YWRlcg==');

@$core.Deprecated('Use copyRangeResponseDescriptor instead')
const CopyRangeResponse$json = {
  '1': 'CopyRangeResponse',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'rows_written', '3': 2, '4': 1, '5': 4, '10': 'rowsWritten'},
  ],
};

/// Descriptor for `CopyRangeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copyRangeResponseDescriptor = $convert.base64Decode(
    'ChFDb3B5UmFuZ2VSZXNwb25zZRISCgR0ZXh0GAEgASgJUgR0ZXh0EiEKDHJvd3Nfd3JpdHRlbh'
    'gCIAEoBFILcm93c1dyaXR0ZW4=');
