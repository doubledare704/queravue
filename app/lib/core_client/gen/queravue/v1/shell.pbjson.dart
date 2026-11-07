// This is a generated file - do not edit.
//
// Generated from queravue/v1/shell.proto.

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

@$core.Deprecated('Use printLevelDescriptor instead')
const PrintLevel$json = {
  '1': 'PrintLevel',
  '2': [
    {'1': 'PRINT_LEVEL_UNSPECIFIED', '2': 0},
    {'1': 'PRINT_LEVEL_LOG', '2': 1},
    {'1': 'PRINT_LEVEL_INFO', '2': 2},
    {'1': 'PRINT_LEVEL_WARN', '2': 3},
    {'1': 'PRINT_LEVEL_ERROR', '2': 4},
  ],
};

/// Descriptor for `PrintLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List printLevelDescriptor = $convert.base64Decode(
    'CgpQcmludExldmVsEhsKF1BSSU5UX0xFVkVMX1VOU1BFQ0lGSUVEEAASEwoPUFJJTlRfTEVWRU'
    'xfTE9HEAESFAoQUFJJTlRfTEVWRUxfSU5GTxACEhQKEFBSSU5UX0xFVkVMX1dBUk4QAxIVChFQ'
    'UklOVF9MRVZFTF9FUlJPUhAE');

@$core.Deprecated('Use cursorKindDescriptor instead')
const CursorKind$json = {
  '1': 'CursorKind',
  '2': [
    {'1': 'CURSOR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CURSOR_KIND_FIND', '2': 1},
    {'1': 'CURSOR_KIND_AGGREGATE', '2': 2},
  ],
};

/// Descriptor for `CursorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cursorKindDescriptor = $convert.base64Decode(
    'CgpDdXJzb3JLaW5kEhsKF0NVUlNPUl9LSU5EX1VOU1BFQ0lGSUVEEAASFAoQQ1VSU09SX0tJTk'
    'RfRklORBABEhkKFUNVUlNPUl9LSU5EX0FHR1JFR0FURRAC');

@$core.Deprecated('Use shellErrorKindDescriptor instead')
const ShellErrorKind$json = {
  '1': 'ShellErrorKind',
  '2': [
    {'1': 'SHELL_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'SHELL_ERROR_KIND_SYNTAX', '2': 1},
    {'1': 'SHELL_ERROR_KIND_RUNTIME', '2': 2},
    {'1': 'SHELL_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 3},
    {'1': 'SHELL_ERROR_KIND_OUTPUT_LIMIT', '2': 4},
    {'1': 'SHELL_ERROR_KIND_TIMEOUT', '2': 5},
    {'1': 'SHELL_ERROR_KIND_CANCELED', '2': 6},
    {'1': 'SHELL_ERROR_KIND_SERVER', '2': 7},
    {'1': 'SHELL_ERROR_KIND_UNSUPPORTED', '2': 8},
  ],
};

/// Descriptor for `ShellErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List shellErrorKindDescriptor = $convert.base64Decode(
    'Cg5TaGVsbEVycm9yS2luZBIgChxTSEVMTF9FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEAASGwoXU0'
    'hFTExfRVJST1JfS0lORF9TWU5UQVgQARIcChhTSEVMTF9FUlJPUl9LSU5EX1JVTlRJTUUQAhIq'
    'CiZTSEVMTF9FUlJPUl9LSU5EX0NPTkZJUk1BVElPTl9SRVFVSVJFRBADEiEKHVNIRUxMX0VSUk'
    '9SX0tJTkRfT1VUUFVUX0xJTUlUEAQSHAoYU0hFTExfRVJST1JfS0lORF9USU1FT1VUEAUSHQoZ'
    'U0hFTExfRVJST1JfS0lORF9DQU5DRUxFRBAGEhsKF1NIRUxMX0VSUk9SX0tJTkRfU0VSVkVSEA'
    'cSIAocU0hFTExfRVJST1JfS0lORF9VTlNVUFBPUlRFRBAI');

@$core.Deprecated('Use openShellRequestDescriptor instead')
const OpenShellRequest$json = {
  '1': 'OpenShellRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
  ],
};

/// Descriptor for `OpenShellRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openShellRequestDescriptor = $convert.base64Decode(
    'ChBPcGVuU2hlbGxSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghkYX'
    'RhYmFzZRgCIAEoCVIIZGF0YWJhc2U=');

@$core.Deprecated('Use openShellResponseDescriptor instead')
const OpenShellResponse$json = {
  '1': 'OpenShellResponse',
  '2': [
    {'1': 'shell_id', '3': 1, '4': 1, '5': 9, '10': 'shellId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
  ],
};

/// Descriptor for `OpenShellResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openShellResponseDescriptor = $convert.base64Decode(
    'ChFPcGVuU2hlbGxSZXNwb25zZRIZCghzaGVsbF9pZBgBIAEoCVIHc2hlbGxJZBIaCghkYXRhYm'
    'FzZRgCIAEoCVIIZGF0YWJhc2U=');

@$core.Deprecated('Use evalRequestDescriptor instead')
const EvalRequest$json = {
  '1': 'EvalRequest',
  '2': [
    {'1': 'shell_id', '3': 1, '4': 1, '5': 9, '10': 'shellId'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {'1': 'confirmed', '3': 3, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `EvalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evalRequestDescriptor = $convert.base64Decode(
    'CgtFdmFsUmVxdWVzdBIZCghzaGVsbF9pZBgBIAEoCVIHc2hlbGxJZBISCgRjb2RlGAIgASgJUg'
    'Rjb2RlEhwKCWNvbmZpcm1lZBgDIAEoCFIJY29uZmlybWVk');

@$core.Deprecated('Use evalResponseDescriptor instead')
const EvalResponse$json = {
  '1': 'EvalResponse',
  '2': [
    {
      '1': 'print',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.PrintLine',
      '9': 0,
      '10': 'print'
    },
    {
      '1': 'result',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ResultItem',
      '9': 0,
      '10': 'result'
    },
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ShellError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'done',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.EvalDone',
      '9': 0,
      '10': 'done'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `EvalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evalResponseDescriptor = $convert.base64Decode(
    'CgxFdmFsUmVzcG9uc2USLgoFcHJpbnQYASABKAsyFi5xdWVyYXZ1ZS52MS5QcmludExpbmVIAF'
    'IFcHJpbnQSMQoGcmVzdWx0GAIgASgLMhcucXVlcmF2dWUudjEuUmVzdWx0SXRlbUgAUgZyZXN1'
    'bHQSLwoFZXJyb3IYAyABKAsyFy5xdWVyYXZ1ZS52MS5TaGVsbEVycm9ySABSBWVycm9yEisKBG'
    'RvbmUYBCABKAsyFS5xdWVyYXZ1ZS52MS5FdmFsRG9uZUgAUgRkb25lQgcKBWV2ZW50');

@$core.Deprecated('Use printLineDescriptor instead')
const PrintLine$json = {
  '1': 'PrintLine',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'level',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.PrintLevel',
      '10': 'level'
    },
  ],
};

/// Descriptor for `PrintLine`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List printLineDescriptor = $convert.base64Decode(
    'CglQcmludExpbmUSEgoEdGV4dBgBIAEoCVIEdGV4dBItCgVsZXZlbBgCIAEoDjIXLnF1ZXJhdn'
    'VlLnYxLlByaW50TGV2ZWxSBWxldmVs');

@$core.Deprecated('Use resultItemDescriptor instead')
const ResultItem$json = {
  '1': 'ResultItem',
  '2': [
    {'1': 'scalar', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'scalar'},
    {'1': 'document', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'document'},
    {
      '1': 'write',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WriteResult',
      '9': 0,
      '10': 'write'
    },
    {
      '1': 'cursor',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CursorHandle',
      '9': 0,
      '10': 'cursor'
    },
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `ResultItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultItemDescriptor = $convert.base64Decode(
    'CgpSZXN1bHRJdGVtEhgKBnNjYWxhchgBIAEoCUgAUgZzY2FsYXISHAoIZG9jdW1lbnQYAiABKA'
    'lIAFIIZG9jdW1lbnQSMAoFd3JpdGUYAyABKAsyGC5xdWVyYXZ1ZS52MS5Xcml0ZVJlc3VsdEgA'
    'UgV3cml0ZRIzCgZjdXJzb3IYBCABKAsyGS5xdWVyYXZ1ZS52MS5DdXJzb3JIYW5kbGVIAFIGY3'
    'Vyc29yQgcKBXZhbHVl');

@$core.Deprecated('Use writeResultDescriptor instead')
const WriteResult$json = {
  '1': 'WriteResult',
  '2': [
    {'1': 'operation', '3': 1, '4': 1, '5': 9, '10': 'operation'},
    {'1': 'result', '3': 2, '4': 1, '5': 9, '10': 'result'},
  ],
};

/// Descriptor for `WriteResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeResultDescriptor = $convert.base64Decode(
    'CgtXcml0ZVJlc3VsdBIcCglvcGVyYXRpb24YASABKAlSCW9wZXJhdGlvbhIWCgZyZXN1bHQYAi'
    'ABKAlSBnJlc3VsdA==');

@$core.Deprecated('Use cursorHandleDescriptor instead')
const CursorHandle$json = {
  '1': 'CursorHandle',
  '2': [
    {'1': 'cursor_id', '3': 1, '4': 1, '5': 9, '10': 'cursorId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CursorKind',
      '10': 'kind'
    },
    {'1': 'database', '3': 3, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 4, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'filter', '3': 5, '4': 1, '5': 9, '10': 'filter'},
    {'1': 'sort', '3': 6, '4': 1, '5': 9, '10': 'sort'},
    {'1': 'projection', '3': 7, '4': 1, '5': 9, '10': 'projection'},
    {'1': 'skip', '3': 8, '4': 1, '5': 4, '10': 'skip'},
    {'1': 'limit', '3': 9, '4': 1, '5': 4, '10': 'limit'},
    {'1': 'pipeline', '3': 10, '4': 1, '5': 9, '10': 'pipeline'},
  ],
};

/// Descriptor for `CursorHandle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cursorHandleDescriptor = $convert.base64Decode(
    'CgxDdXJzb3JIYW5kbGUSGwoJY3Vyc29yX2lkGAEgASgJUghjdXJzb3JJZBIrCgRraW5kGAIgAS'
    'gOMhcucXVlcmF2dWUudjEuQ3Vyc29yS2luZFIEa2luZBIaCghkYXRhYmFzZRgDIAEoCVIIZGF0'
    'YWJhc2USHgoKY29sbGVjdGlvbhgEIAEoCVIKY29sbGVjdGlvbhIWCgZmaWx0ZXIYBSABKAlSBm'
    'ZpbHRlchISCgRzb3J0GAYgASgJUgRzb3J0Eh4KCnByb2plY3Rpb24YByABKAlSCnByb2plY3Rp'
    'b24SEgoEc2tpcBgIIAEoBFIEc2tpcBIUCgVsaW1pdBgJIAEoBFIFbGltaXQSGgoIcGlwZWxpbm'
    'UYCiABKAlSCHBpcGVsaW5l');

@$core.Deprecated('Use shellErrorDescriptor instead')
const ShellError$json = {
  '1': 'ShellError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ShellErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'js_stack', '3': 3, '4': 1, '5': 9, '10': 'jsStack'},
    {'1': 'line', '3': 4, '4': 1, '5': 13, '10': 'line'},
    {'1': 'column', '3': 5, '4': 1, '5': 13, '10': 'column'},
    {'1': 'operation', '3': 6, '4': 1, '5': 9, '10': 'operation'},
  ],
};

/// Descriptor for `ShellError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shellErrorDescriptor = $convert.base64Decode(
    'CgpTaGVsbEVycm9yEi8KBGtpbmQYASABKA4yGy5xdWVyYXZ1ZS52MS5TaGVsbEVycm9yS2luZF'
    'IEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEhkKCGpzX3N0YWNrGAMgASgJUgdqc1N0'
    'YWNrEhIKBGxpbmUYBCABKA1SBGxpbmUSFgoGY29sdW1uGAUgASgNUgZjb2x1bW4SHAoJb3Blcm'
    'F0aW9uGAYgASgJUglvcGVyYXRpb24=');

@$core.Deprecated('Use evalDoneDescriptor instead')
const EvalDone$json = {
  '1': 'EvalDone',
  '2': [
    {
      '1': 'duration',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
  ],
};

/// Descriptor for `EvalDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evalDoneDescriptor = $convert.base64Decode(
    'CghFdmFsRG9uZRI1CghkdXJhdGlvbhgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbl'
    'IIZHVyYXRpb24=');

@$core.Deprecated('Use fetchCursorResponseDescriptor instead')
const FetchCursorResponse$json = {
  '1': 'FetchCursorResponse',
  '2': [
    {
      '1': 'batch',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentBatch',
      '10': 'batch'
    },
  ],
};

/// Descriptor for `FetchCursorResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchCursorResponseDescriptor = $convert.base64Decode(
    'ChNGZXRjaEN1cnNvclJlc3BvbnNlEjAKBWJhdGNoGAEgASgLMhoucXVlcmF2dWUudjEuRG9jdW'
    '1lbnRCYXRjaFIFYmF0Y2g=');

@$core.Deprecated('Use fetchCursorRequestDescriptor instead')
const FetchCursorRequest$json = {
  '1': 'FetchCursorRequest',
  '2': [
    {'1': 'shell_id', '3': 1, '4': 1, '5': 9, '10': 'shellId'},
    {'1': 'cursor_id', '3': 2, '4': 1, '5': 9, '10': 'cursorId'},
    {'1': 'skip', '3': 3, '4': 1, '5': 4, '10': 'skip'},
    {'1': 'limit', '3': 4, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `FetchCursorRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchCursorRequestDescriptor = $convert.base64Decode(
    'ChJGZXRjaEN1cnNvclJlcXVlc3QSGQoIc2hlbGxfaWQYASABKAlSB3NoZWxsSWQSGwoJY3Vyc2'
    '9yX2lkGAIgASgJUghjdXJzb3JJZBISCgRza2lwGAMgASgEUgRza2lwEhQKBWxpbWl0GAQgASgN'
    'UgVsaW1pdA==');

@$core.Deprecated('Use shellServiceCancelRequestDescriptor instead')
const ShellServiceCancelRequest$json = {
  '1': 'ShellServiceCancelRequest',
  '2': [
    {'1': 'shell_id', '3': 1, '4': 1, '5': 9, '10': 'shellId'},
  ],
};

/// Descriptor for `ShellServiceCancelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shellServiceCancelRequestDescriptor =
    $convert.base64Decode(
        'ChlTaGVsbFNlcnZpY2VDYW5jZWxSZXF1ZXN0EhkKCHNoZWxsX2lkGAEgASgJUgdzaGVsbElk');

@$core.Deprecated('Use shellServiceCancelResponseDescriptor instead')
const ShellServiceCancelResponse$json = {
  '1': 'ShellServiceCancelResponse',
};

/// Descriptor for `ShellServiceCancelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shellServiceCancelResponseDescriptor =
    $convert.base64Decode('ChpTaGVsbFNlcnZpY2VDYW5jZWxSZXNwb25zZQ==');

@$core.Deprecated('Use closeShellRequestDescriptor instead')
const CloseShellRequest$json = {
  '1': 'CloseShellRequest',
  '2': [
    {'1': 'shell_id', '3': 1, '4': 1, '5': 9, '10': 'shellId'},
  ],
};

/// Descriptor for `CloseShellRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeShellRequestDescriptor = $convert.base64Decode(
    'ChFDbG9zZVNoZWxsUmVxdWVzdBIZCghzaGVsbF9pZBgBIAEoCVIHc2hlbGxJZA==');

@$core.Deprecated('Use closeShellResponseDescriptor instead')
const CloseShellResponse$json = {
  '1': 'CloseShellResponse',
};

/// Descriptor for `CloseShellResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeShellResponseDescriptor =
    $convert.base64Decode('ChJDbG9zZVNoZWxsUmVzcG9uc2U=');
