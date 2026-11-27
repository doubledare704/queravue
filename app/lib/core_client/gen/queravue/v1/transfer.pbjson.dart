// This is a generated file - do not edit.
//
// Generated from queravue/v1/transfer.proto.

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

@$core.Deprecated('Use transferFormatDescriptor instead')
const TransferFormat$json = {
  '1': 'TransferFormat',
  '2': [
    {'1': 'TRANSFER_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'TRANSFER_FORMAT_CSV', '2': 1},
    {'1': 'TRANSFER_FORMAT_TSV', '2': 2},
    {'1': 'TRANSFER_FORMAT_JSON', '2': 3},
    {'1': 'TRANSFER_FORMAT_NDJSON', '2': 4},
    {'1': 'TRANSFER_FORMAT_SQL', '2': 5},
    {'1': 'TRANSFER_FORMAT_PARQUET', '2': 6},
  ],
};

/// Descriptor for `TransferFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List transferFormatDescriptor = $convert.base64Decode(
    'Cg5UcmFuc2ZlckZvcm1hdBIfChtUUkFOU0ZFUl9GT1JNQVRfVU5TUEVDSUZJRUQQABIXChNUUk'
    'FOU0ZFUl9GT1JNQVRfQ1NWEAESFwoTVFJBTlNGRVJfRk9STUFUX1RTVhACEhgKFFRSQU5TRkVS'
    'X0ZPUk1BVF9KU09OEAMSGgoWVFJBTlNGRVJfRk9STUFUX05ESlNPThAEEhcKE1RSQU5TRkVSX0'
    'ZPUk1BVF9TUUwQBRIbChdUUkFOU0ZFUl9GT1JNQVRfUEFSUVVFVBAG');

@$core.Deprecated('Use jsonFlavorDescriptor instead')
const JsonFlavor$json = {
  '1': 'JsonFlavor',
  '2': [
    {'1': 'JSON_FLAVOR_UNSPECIFIED', '2': 0},
    {'1': 'JSON_FLAVOR_RELAXED', '2': 1},
    {'1': 'JSON_FLAVOR_CANONICAL', '2': 2},
  ],
};

/// Descriptor for `JsonFlavor`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List jsonFlavorDescriptor = $convert.base64Decode(
    'CgpKc29uRmxhdm9yEhsKF0pTT05fRkxBVk9SX1VOU1BFQ0lGSUVEEAASFwoTSlNPTl9GTEFWT1'
    'JfUkVMQVhFRBABEhkKFUpTT05fRkxBVk9SX0NBTk9OSUNBTBAC');

@$core.Deprecated('Use transferErrorKindDescriptor instead')
const TransferErrorKind$json = {
  '1': 'TransferErrorKind',
  '2': [
    {'1': 'TRANSFER_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'TRANSFER_ERROR_KIND_PARSE', '2': 1},
    {'1': 'TRANSFER_ERROR_KIND_MAPPING', '2': 2},
    {'1': 'TRANSFER_ERROR_KIND_CONSTRAINT', '2': 3},
    {'1': 'TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 4},
    {'1': 'TRANSFER_ERROR_KIND_AUTH', '2': 5},
    {'1': 'TRANSFER_ERROR_KIND_NETWORK', '2': 6},
    {'1': 'TRANSFER_ERROR_KIND_TIMEOUT', '2': 7},
    {'1': 'TRANSFER_ERROR_KIND_CANCELED', '2': 8},
    {'1': 'TRANSFER_ERROR_KIND_UNSUPPORTED', '2': 9},
    {'1': 'TRANSFER_ERROR_KIND_SERVER', '2': 10},
  ],
};

/// Descriptor for `TransferErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List transferErrorKindDescriptor = $convert.base64Decode(
    'ChFUcmFuc2ZlckVycm9yS2luZBIjCh9UUkFOU0ZFUl9FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEA'
    'ASHQoZVFJBTlNGRVJfRVJST1JfS0lORF9QQVJTRRABEh8KG1RSQU5TRkVSX0VSUk9SX0tJTkRf'
    'TUFQUElORxACEiIKHlRSQU5TRkVSX0VSUk9SX0tJTkRfQ09OU1RSQUlOVBADEi0KKVRSQU5TRk'
    'VSX0VSUk9SX0tJTkRfQ09ORklSTUFUSU9OX1JFUVVJUkVEEAQSHAoYVFJBTlNGRVJfRVJST1Jf'
    'S0lORF9BVVRIEAUSHwobVFJBTlNGRVJfRVJST1JfS0lORF9ORVRXT1JLEAYSHwobVFJBTlNGRV'
    'JfRVJST1JfS0lORF9USU1FT1VUEAcSIAocVFJBTlNGRVJfRVJST1JfS0lORF9DQU5DRUxFRBAI'
    'EiMKH1RSQU5TRkVSX0VSUk9SX0tJTkRfVU5TVVBQT1JURUQQCRIeChpUUkFOU0ZFUl9FUlJPUl'
    '9LSU5EX1NFUlZFUhAK');

@$core.Deprecated('Use importErrorPolicyDescriptor instead')
const ImportErrorPolicy$json = {
  '1': 'ImportErrorPolicy',
  '2': [
    {'1': 'IMPORT_ERROR_POLICY_UNSPECIFIED', '2': 0},
    {'1': 'IMPORT_ERROR_POLICY_STOP', '2': 1},
    {'1': 'IMPORT_ERROR_POLICY_SKIP', '2': 2},
  ],
};

/// Descriptor for `ImportErrorPolicy`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List importErrorPolicyDescriptor = $convert.base64Decode(
    'ChFJbXBvcnRFcnJvclBvbGljeRIjCh9JTVBPUlRfRVJST1JfUE9MSUNZX1VOU1BFQ0lGSUVEEA'
    'ASHAoYSU1QT1JUX0VSUk9SX1BPTElDWV9TVE9QEAESHAoYSU1QT1JUX0VSUk9SX1BPTElDWV9T'
    'S0lQEAI=');

@$core.Deprecated('Use transferErrorDescriptor instead')
const TransferError$json = {
  '1': 'TransferError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `TransferError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferErrorDescriptor = $convert.base64Decode(
    'Cg1UcmFuc2ZlckVycm9yEjIKBGtpbmQYASABKA4yHi5xdWVyYXZ1ZS52MS5UcmFuc2ZlckVycm'
    '9yS2luZFIEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use transferFormatOptionsDescriptor instead')
const TransferFormatOptions$json = {
  '1': 'TransferFormatOptions',
  '2': [
    {'1': 'delimiter', '3': 1, '4': 1, '5': 9, '10': 'delimiter'},
    {'1': 'quote', '3': 2, '4': 1, '5': 9, '10': 'quote'},
    {'1': 'header', '3': 3, '4': 1, '5': 8, '10': 'header'},
    {'1': 'null_text', '3': 4, '4': 1, '5': 9, '10': 'nullText'},
    {
      '1': 'json_flavor',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.JsonFlavor',
      '10': 'jsonFlavor'
    },
    {'1': 'sql_include_ddl', '3': 6, '4': 1, '5': 8, '10': 'sqlIncludeDdl'},
    {'1': 'sql_target_table', '3': 7, '4': 1, '5': 9, '10': 'sqlTargetTable'},
  ],
};

/// Descriptor for `TransferFormatOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferFormatOptionsDescriptor = $convert.base64Decode(
    'ChVUcmFuc2ZlckZvcm1hdE9wdGlvbnMSHAoJZGVsaW1pdGVyGAEgASgJUglkZWxpbWl0ZXISFA'
    'oFcXVvdGUYAiABKAlSBXF1b3RlEhYKBmhlYWRlchgDIAEoCFIGaGVhZGVyEhsKCW51bGxfdGV4'
    'dBgEIAEoCVIIbnVsbFRleHQSOAoLanNvbl9mbGF2b3IYBSABKA4yFy5xdWVyYXZ1ZS52MS5Kc2'
    '9uRmxhdm9yUgpqc29uRmxhdm9yEiYKD3NxbF9pbmNsdWRlX2RkbBgGIAEoCFINc3FsSW5jbHVk'
    'ZURkbBIoChBzcWxfdGFyZ2V0X3RhYmxlGAcgASgJUg5zcWxUYXJnZXRUYWJsZQ==');

@$core.Deprecated('Use exportOptionsDescriptor instead')
const ExportOptions$json = {
  '1': 'ExportOptions',
  '2': [
    {
      '1': 'format',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'format'
    },
    {
      '1': 'format_options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferFormatOptions',
      '10': 'formatOptions'
    },
  ],
};

/// Descriptor for `ExportOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportOptionsDescriptor = $convert.base64Decode(
    'Cg1FeHBvcnRPcHRpb25zEjMKBmZvcm1hdBgBIAEoDjIbLnF1ZXJhdnVlLnYxLlRyYW5zZmVyRm'
    '9ybWF0UgZmb3JtYXQSSQoOZm9ybWF0X29wdGlvbnMYAiABKAsyIi5xdWVyYXZ1ZS52MS5UcmFu'
    'c2ZlckZvcm1hdE9wdGlvbnNSDWZvcm1hdE9wdGlvbnM=');

@$core.Deprecated('Use collectionRefDescriptor instead')
const CollectionRef$json = {
  '1': 'CollectionRef',
  '2': [
    {'1': 'database', '3': 1, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 2, '4': 1, '5': 9, '10': 'collection'},
  ],
};

/// Descriptor for `CollectionRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List collectionRefDescriptor = $convert.base64Decode(
    'Cg1Db2xsZWN0aW9uUmVmEhoKCGRhdGFiYXNlGAEgASgJUghkYXRhYmFzZRIeCgpjb2xsZWN0aW'
    '9uGAIgASgJUgpjb2xsZWN0aW9u');

@$core.Deprecated('Use listFormatsRequestDescriptor instead')
const ListFormatsRequest$json = {
  '1': 'ListFormatsRequest',
};

/// Descriptor for `ListFormatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFormatsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0Rm9ybWF0c1JlcXVlc3Q=');

@$core.Deprecated('Use listFormatsResponseDescriptor instead')
const ListFormatsResponse$json = {
  '1': 'ListFormatsResponse',
  '2': [
    {
      '1': 'import_formats',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'importFormats'
    },
    {
      '1': 'export_formats',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'exportFormats'
    },
  ],
};

/// Descriptor for `ListFormatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFormatsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0Rm9ybWF0c1Jlc3BvbnNlEkIKDmltcG9ydF9mb3JtYXRzGAEgAygOMhsucXVlcmF2dW'
    'UudjEuVHJhbnNmZXJGb3JtYXRSDWltcG9ydEZvcm1hdHMSQgoOZXhwb3J0X2Zvcm1hdHMYAiAD'
    'KA4yGy5xdWVyYXZ1ZS52MS5UcmFuc2ZlckZvcm1hdFINZXhwb3J0Rm9ybWF0cw==');

@$core.Deprecated('Use exportResultRequestDescriptor instead')
const ExportResultRequest$json = {
  '1': 'ExportResultRequest',
  '2': [
    {'1': 'result_id', '3': 1, '4': 1, '5': 9, '10': 'resultId'},
    {'1': 'column_indices', '3': 2, '4': 3, '5': 13, '10': 'columnIndices'},
    {
      '1': 'options',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `ExportResultRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportResultRequestDescriptor = $convert.base64Decode(
    'ChNFeHBvcnRSZXN1bHRSZXF1ZXN0EhsKCXJlc3VsdF9pZBgBIAEoCVIIcmVzdWx0SWQSJQoOY2'
    '9sdW1uX2luZGljZXMYAiADKA1SDWNvbHVtbkluZGljZXMSNAoHb3B0aW9ucxgDIAEoCzIaLnF1'
    'ZXJhdnVlLnYxLkV4cG9ydE9wdGlvbnNSB29wdGlvbnM=');

@$core.Deprecated('Use exportTableRequestDescriptor instead')
const ExportTableRequest$json = {
  '1': 'ExportTableRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'table',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'table'
    },
    {
      '1': 'filter',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableFilter',
      '10': 'filter'
    },
    {
      '1': 'sort',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SortClause',
      '10': 'sort'
    },
    {'1': 'columns', '3': 5, '4': 3, '5': 9, '10': 'columns'},
    {
      '1': 'options',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `ExportTableRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportTableRequestDescriptor = $convert.base64Decode(
    'ChJFeHBvcnRUYWJsZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEisKBX'
    'RhYmxlGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSBXRhYmxlEjAKBmZpbHRlchgDIAEo'
    'CzIYLnF1ZXJhdnVlLnYxLlRhYmxlRmlsdGVyUgZmaWx0ZXISKwoEc29ydBgEIAMoCzIXLnF1ZX'
    'JhdnVlLnYxLlNvcnRDbGF1c2VSBHNvcnQSGAoHY29sdW1ucxgFIAMoCVIHY29sdW1ucxI0Cgdv'
    'cHRpb25zGAYgASgLMhoucXVlcmF2dWUudjEuRXhwb3J0T3B0aW9uc1IHb3B0aW9ucw==');

@$core.Deprecated('Use exportCollectionRequestDescriptor instead')
const ExportCollectionRequest$json = {
  '1': 'ExportCollectionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'collection',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CollectionRef',
      '10': 'collection'
    },
    {'1': 'filter_ejson', '3': 3, '4': 1, '5': 9, '10': 'filterEjson'},
    {'1': 'projection_ejson', '3': 4, '4': 1, '5': 9, '10': 'projectionEjson'},
    {'1': 'sort_ejson', '3': 5, '4': 1, '5': 9, '10': 'sortEjson'},
    {'1': 'field_paths', '3': 6, '4': 3, '5': 9, '10': 'fieldPaths'},
    {
      '1': 'options',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportOptions',
      '10': 'options'
    },
  ],
};

/// Descriptor for `ExportCollectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportCollectionRequestDescriptor = $convert.base64Decode(
    'ChdFeHBvcnRDb2xsZWN0aW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSW'
    'QSOgoKY29sbGVjdGlvbhgCIAEoCzIaLnF1ZXJhdnVlLnYxLkNvbGxlY3Rpb25SZWZSCmNvbGxl'
    'Y3Rpb24SIQoMZmlsdGVyX2Vqc29uGAMgASgJUgtmaWx0ZXJFanNvbhIpChBwcm9qZWN0aW9uX2'
    'Vqc29uGAQgASgJUg9wcm9qZWN0aW9uRWpzb24SHQoKc29ydF9lanNvbhgFIAEoCVIJc29ydEVq'
    'c29uEh8KC2ZpZWxkX3BhdGhzGAYgAygJUgpmaWVsZFBhdGhzEjQKB29wdGlvbnMYByABKAsyGi'
    '5xdWVyYXZ1ZS52MS5FeHBvcnRPcHRpb25zUgdvcHRpb25z');

@$core.Deprecated('Use exportHeaderDescriptor instead')
const ExportHeader$json = {
  '1': 'ExportHeader',
  '2': [
    {
      '1': 'format',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'format'
    },
    {
      '1': 'suggested_filename',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'suggestedFilename'
    },
  ],
};

/// Descriptor for `ExportHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportHeaderDescriptor = $convert.base64Decode(
    'CgxFeHBvcnRIZWFkZXISMwoGZm9ybWF0GAEgASgOMhsucXVlcmF2dWUudjEuVHJhbnNmZXJGb3'
    'JtYXRSBmZvcm1hdBItChJzdWdnZXN0ZWRfZmlsZW5hbWUYAiABKAlSEXN1Z2dlc3RlZEZpbGVu'
    'YW1l');

@$core.Deprecated('Use exportProgressDescriptor instead')
const ExportProgress$json = {
  '1': 'ExportProgress',
  '2': [
    {'1': 'rows', '3': 1, '4': 1, '5': 4, '10': 'rows'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ExportProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportProgressDescriptor = $convert.base64Decode(
    'Cg5FeHBvcnRQcm9ncmVzcxISCgRyb3dzGAEgASgEUgRyb3dzEhQKBWJ5dGVzGAIgASgEUgVieX'
    'Rlcw==');

@$core.Deprecated('Use exportSummaryDescriptor instead')
const ExportSummary$json = {
  '1': 'ExportSummary',
  '2': [
    {'1': 'rows', '3': 1, '4': 1, '5': 4, '10': 'rows'},
    {'1': 'bytes', '3': 2, '4': 1, '5': 4, '10': 'bytes'},
  ],
};

/// Descriptor for `ExportSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportSummaryDescriptor = $convert.base64Decode(
    'Cg1FeHBvcnRTdW1tYXJ5EhIKBHJvd3MYASABKARSBHJvd3MSFAoFYnl0ZXMYAiABKARSBWJ5dG'
    'Vz');

@$core.Deprecated('Use exportEventDescriptor instead')
const ExportEvent$json = {
  '1': 'ExportEvent',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportHeader',
      '9': 0,
      '10': 'header'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
    {
      '1': 'progress',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'summary',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportSummary',
      '9': 0,
      '10': 'summary'
    },
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ExportEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportEventDescriptor = $convert.base64Decode(
    'CgtFeHBvcnRFdmVudBIzCgZoZWFkZXIYASABKAsyGS5xdWVyYXZ1ZS52MS5FeHBvcnRIZWFkZX'
    'JIAFIGaGVhZGVyEhYKBWNodW5rGAIgASgMSABSBWNodW5rEjkKCHByb2dyZXNzGAMgASgLMhsu'
    'cXVlcmF2dWUudjEuRXhwb3J0UHJvZ3Jlc3NIAFIIcHJvZ3Jlc3MSNgoHc3VtbWFyeRgEIAEoCz'
    'IaLnF1ZXJhdnVlLnYxLkV4cG9ydFN1bW1hcnlIAFIHc3VtbWFyeRIyCgVlcnJvchgFIAEoCzIa'
    'LnF1ZXJhdnVlLnYxLlRyYW5zZmVyRXJyb3JIAFIFZXJyb3JCBwoFZXZlbnQ=');

@$core.Deprecated('Use exportResultResponseDescriptor instead')
const ExportResultResponse$json = {
  '1': 'ExportResultResponse',
  '2': [
    {
      '1': 'event',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportEvent',
      '10': 'event'
    },
  ],
};

/// Descriptor for `ExportResultResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportResultResponseDescriptor = $convert.base64Decode(
    'ChRFeHBvcnRSZXN1bHRSZXNwb25zZRIuCgVldmVudBgBIAEoCzIYLnF1ZXJhdnVlLnYxLkV4cG'
    '9ydEV2ZW50UgVldmVudA==');

@$core.Deprecated('Use exportTableResponseDescriptor instead')
const ExportTableResponse$json = {
  '1': 'ExportTableResponse',
  '2': [
    {
      '1': 'event',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportEvent',
      '10': 'event'
    },
  ],
};

/// Descriptor for `ExportTableResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportTableResponseDescriptor = $convert.base64Decode(
    'ChNFeHBvcnRUYWJsZVJlc3BvbnNlEi4KBWV2ZW50GAEgASgLMhgucXVlcmF2dWUudjEuRXhwb3'
    'J0RXZlbnRSBWV2ZW50');

@$core.Deprecated('Use exportCollectionResponseDescriptor instead')
const ExportCollectionResponse$json = {
  '1': 'ExportCollectionResponse',
  '2': [
    {
      '1': 'event',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExportEvent',
      '10': 'event'
    },
  ],
};

/// Descriptor for `ExportCollectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportCollectionResponseDescriptor =
    $convert.base64Decode(
        'ChhFeHBvcnRDb2xsZWN0aW9uUmVzcG9uc2USLgoFZXZlbnQYASABKAsyGC5xdWVyYXZ1ZS52MS'
        '5FeHBvcnRFdmVudFIFZXZlbnQ=');

@$core.Deprecated('Use inferImportHeaderDescriptor instead')
const InferImportHeader$json = {
  '1': 'InferImportHeader',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'filename', '3': 2, '4': 1, '5': 9, '10': 'filename'},
    {
      '1': 'format',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'format'
    },
    {
      '1': 'format_options',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferFormatOptions',
      '10': 'formatOptions'
    },
  ],
};

/// Descriptor for `InferImportHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inferImportHeaderDescriptor = $convert.base64Decode(
    'ChFJbmZlckltcG9ydEhlYWRlchIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZm'
    'lsZW5hbWUYAiABKAlSCGZpbGVuYW1lEjMKBmZvcm1hdBgDIAEoDjIbLnF1ZXJhdnVlLnYxLlRy'
    'YW5zZmVyRm9ybWF0UgZmb3JtYXQSSQoOZm9ybWF0X29wdGlvbnMYBCABKAsyIi5xdWVyYXZ1ZS'
    '52MS5UcmFuc2ZlckZvcm1hdE9wdGlvbnNSDWZvcm1hdE9wdGlvbnM=');

@$core.Deprecated('Use inferImportRequestDescriptor instead')
const InferImportRequest$json = {
  '1': 'InferImportRequest',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.InferImportHeader',
      '9': 0,
      '10': 'header'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `InferImportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inferImportRequestDescriptor = $convert.base64Decode(
    'ChJJbmZlckltcG9ydFJlcXVlc3QSOAoGaGVhZGVyGAEgASgLMh4ucXVlcmF2dWUudjEuSW5mZX'
    'JJbXBvcnRIZWFkZXJIAFIGaGVhZGVyEhYKBWNodW5rGAIgASgMSABSBWNodW5rQgkKB21lc3Nh'
    'Z2U=');

@$core.Deprecated('Use importColumnDescriptor instead')
const ImportColumn$json = {
  '1': 'ImportColumn',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'inferred_kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ValueKind',
      '10': 'inferredKind'
    },
    {
      '1': 'suggested_type_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'suggestedTypeName'
    },
    {'1': 'nullable', '3': 4, '4': 1, '5': 8, '10': 'nullable'},
  ],
};

/// Descriptor for `ImportColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importColumnDescriptor = $convert.base64Decode(
    'CgxJbXBvcnRDb2x1bW4SEgoEbmFtZRgBIAEoCVIEbmFtZRI7Cg1pbmZlcnJlZF9raW5kGAIgAS'
    'gOMhYucXVlcmF2dWUudjEuVmFsdWVLaW5kUgxpbmZlcnJlZEtpbmQSLgoTc3VnZ2VzdGVkX3R5'
    'cGVfbmFtZRgDIAEoCVIRc3VnZ2VzdGVkVHlwZU5hbWUSGgoIbnVsbGFibGUYBCABKAhSCG51bG'
    'xhYmxl');

@$core.Deprecated('Use inferImportResponseDescriptor instead')
const InferImportResponse$json = {
  '1': 'InferImportResponse',
  '2': [
    {
      '1': 'format',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'format'
    },
    {
      '1': 'format_options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferFormatOptions',
      '10': 'formatOptions'
    },
    {
      '1': 'columns',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ImportColumn',
      '10': 'columns'
    },
    {
      '1': 'preview_rows',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RowBatch',
      '10': 'previewRows'
    },
    {
      '1': 'preview_documents_ejson',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'previewDocumentsEjson'
    },
    {'1': 'warnings', '3': 6, '4': 3, '5': 9, '10': 'warnings'},
    {
      '1': 'error',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `InferImportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inferImportResponseDescriptor = $convert.base64Decode(
    'ChNJbmZlckltcG9ydFJlc3BvbnNlEjMKBmZvcm1hdBgBIAEoDjIbLnF1ZXJhdnVlLnYxLlRyYW'
    '5zZmVyRm9ybWF0UgZmb3JtYXQSSQoOZm9ybWF0X29wdGlvbnMYAiABKAsyIi5xdWVyYXZ1ZS52'
    'MS5UcmFuc2ZlckZvcm1hdE9wdGlvbnNSDWZvcm1hdE9wdGlvbnMSMwoHY29sdW1ucxgDIAMoCz'
    'IZLnF1ZXJhdnVlLnYxLkltcG9ydENvbHVtblIHY29sdW1ucxI4CgxwcmV2aWV3X3Jvd3MYBCAB'
    'KAsyFS5xdWVyYXZ1ZS52MS5Sb3dCYXRjaFILcHJldmlld1Jvd3MSNgoXcHJldmlld19kb2N1bW'
    'VudHNfZWpzb24YBSADKAlSFXByZXZpZXdEb2N1bWVudHNFanNvbhIaCgh3YXJuaW5ncxgGIAMo'
    'CVIId2FybmluZ3MSMAoFZXJyb3IYByABKAsyGi5xdWVyYXZ1ZS52MS5UcmFuc2ZlckVycm9yUg'
    'VlcnJvcg==');

@$core.Deprecated('Use newTableDescriptor instead')
const NewTable$json = {
  '1': 'NewTable',
  '2': [
    {
      '1': 'table',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'table'
    },
    {
      '1': 'columns',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnDetails',
      '10': 'columns'
    },
  ],
};

/// Descriptor for `NewTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newTableDescriptor = $convert.base64Decode(
    'CghOZXdUYWJsZRIrCgV0YWJsZRgBIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgV0YWJsZR'
    'I0Cgdjb2x1bW5zGAIgAygLMhoucXVlcmF2dWUudjEuQ29sdW1uRGV0YWlsc1IHY29sdW1ucw==');

@$core.Deprecated('Use columnMappingDescriptor instead')
const ColumnMapping$json = {
  '1': 'ColumnMapping',
  '2': [
    {'1': 'source_index', '3': 1, '4': 1, '5': 13, '10': 'sourceIndex'},
    {'1': 'target_column', '3': 2, '4': 1, '5': 9, '10': 'targetColumn'},
  ],
};

/// Descriptor for `ColumnMapping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnMappingDescriptor = $convert.base64Decode(
    'Cg1Db2x1bW5NYXBwaW5nEiEKDHNvdXJjZV9pbmRleBgBIAEoDVILc291cmNlSW5kZXgSIwoNdG'
    'FyZ2V0X2NvbHVtbhgCIAEoCVIMdGFyZ2V0Q29sdW1u');

@$core.Deprecated('Use importHeaderDescriptor instead')
const ImportHeader$json = {
  '1': 'ImportHeader',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'existing_table',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '9': 0,
      '10': 'existingTable'
    },
    {
      '1': 'new_table',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.NewTable',
      '9': 0,
      '10': 'newTable'
    },
    {
      '1': 'collection',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CollectionRef',
      '9': 0,
      '10': 'collection'
    },
    {
      '1': 'format',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TransferFormat',
      '10': 'format'
    },
    {
      '1': 'format_options',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferFormatOptions',
      '10': 'formatOptions'
    },
    {
      '1': 'mappings',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnMapping',
      '10': 'mappings'
    },
    {
      '1': 'error_policy',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ImportErrorPolicy',
      '10': 'errorPolicy'
    },
    {'1': 'max_row_errors', '3': 9, '4': 1, '5': 13, '10': 'maxRowErrors'},
    {
      '1': 'single_transaction',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'singleTransaction'
    },
    {'1': 'confirmed', '3': 11, '4': 1, '5': 8, '10': 'confirmed'},
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `ImportHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importHeaderDescriptor = $convert.base64Decode(
    'CgxJbXBvcnRIZWFkZXISHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEj4KDmV4aXN0aW'
    '5nX3RhYmxlGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZIAFINZXhpc3RpbmdUYWJsZRI0'
    'CgluZXdfdGFibGUYAyABKAsyFS5xdWVyYXZ1ZS52MS5OZXdUYWJsZUgAUghuZXdUYWJsZRI8Cg'
    'pjb2xsZWN0aW9uGAQgASgLMhoucXVlcmF2dWUudjEuQ29sbGVjdGlvblJlZkgAUgpjb2xsZWN0'
    'aW9uEjMKBmZvcm1hdBgFIAEoDjIbLnF1ZXJhdnVlLnYxLlRyYW5zZmVyRm9ybWF0UgZmb3JtYX'
    'QSSQoOZm9ybWF0X29wdGlvbnMYBiABKAsyIi5xdWVyYXZ1ZS52MS5UcmFuc2ZlckZvcm1hdE9w'
    'dGlvbnNSDWZvcm1hdE9wdGlvbnMSNgoIbWFwcGluZ3MYByADKAsyGi5xdWVyYXZ1ZS52MS5Db2'
    'x1bW5NYXBwaW5nUghtYXBwaW5ncxJBCgxlcnJvcl9wb2xpY3kYCCABKA4yHi5xdWVyYXZ1ZS52'
    'MS5JbXBvcnRFcnJvclBvbGljeVILZXJyb3JQb2xpY3kSJAoObWF4X3Jvd19lcnJvcnMYCSABKA'
    '1SDG1heFJvd0Vycm9ycxItChJzaW5nbGVfdHJhbnNhY3Rpb24YCiABKAhSEXNpbmdsZVRyYW5z'
    'YWN0aW9uEhwKCWNvbmZpcm1lZBgLIAEoCFIJY29uZmlybWVkQggKBnRhcmdldA==');

@$core.Deprecated('Use importRequestDescriptor instead')
const ImportRequest$json = {
  '1': 'ImportRequest',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ImportHeader',
      '9': 0,
      '10': 'header'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
  ],
  '8': [
    {'1': 'message'},
  ],
};

/// Descriptor for `ImportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importRequestDescriptor = $convert.base64Decode(
    'Cg1JbXBvcnRSZXF1ZXN0EjMKBmhlYWRlchgBIAEoCzIZLnF1ZXJhdnVlLnYxLkltcG9ydEhlYW'
    'RlckgAUgZoZWFkZXISFgoFY2h1bmsYAiABKAxIAFIFY2h1bmtCCQoHbWVzc2FnZQ==');

@$core.Deprecated('Use importProgressDescriptor instead')
const ImportProgress$json = {
  '1': 'ImportProgress',
  '2': [
    {'1': 'rows_committed', '3': 1, '4': 1, '5': 4, '10': 'rowsCommitted'},
    {'1': 'bytes_read', '3': 2, '4': 1, '5': 4, '10': 'bytesRead'},
  ],
};

/// Descriptor for `ImportProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importProgressDescriptor = $convert.base64Decode(
    'Cg5JbXBvcnRQcm9ncmVzcxIlCg5yb3dzX2NvbW1pdHRlZBgBIAEoBFINcm93c0NvbW1pdHRlZB'
    'IdCgpieXRlc19yZWFkGAIgASgEUglieXRlc1JlYWQ=');

@$core.Deprecated('Use importRowErrorDescriptor instead')
const ImportRowError$json = {
  '1': 'ImportRowError',
  '2': [
    {'1': 'line', '3': 1, '4': 1, '5': 4, '10': 'line'},
    {'1': 'column', '3': 2, '4': 1, '5': 9, '10': 'column'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ImportRowError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importRowErrorDescriptor = $convert.base64Decode(
    'Cg5JbXBvcnRSb3dFcnJvchISCgRsaW5lGAEgASgEUgRsaW5lEhYKBmNvbHVtbhgCIAEoCVIGY2'
    '9sdW1uEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use importSummaryDescriptor instead')
const ImportSummary$json = {
  '1': 'ImportSummary',
  '2': [
    {'1': 'rows_committed', '3': 1, '4': 1, '5': 4, '10': 'rowsCommitted'},
    {'1': 'rows_skipped', '3': 2, '4': 1, '5': 4, '10': 'rowsSkipped'},
    {
      '1': 'row_errors',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ImportRowError',
      '10': 'rowErrors'
    },
    {'1': 'ddl', '3': 4, '4': 1, '5': 9, '10': 'ddl'},
  ],
};

/// Descriptor for `ImportSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importSummaryDescriptor = $convert.base64Decode(
    'Cg1JbXBvcnRTdW1tYXJ5EiUKDnJvd3NfY29tbWl0dGVkGAEgASgEUg1yb3dzQ29tbWl0dGVkEi'
    'EKDHJvd3Nfc2tpcHBlZBgCIAEoBFILcm93c1NraXBwZWQSOgoKcm93X2Vycm9ycxgDIAMoCzIb'
    'LnF1ZXJhdnVlLnYxLkltcG9ydFJvd0Vycm9yUglyb3dFcnJvcnMSEAoDZGRsGAQgASgJUgNkZG'
    'w=');

@$core.Deprecated('Use importResponseDescriptor instead')
const ImportResponse$json = {
  '1': 'ImportResponse',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ImportProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'summary',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ImportSummary',
      '9': 0,
      '10': 'summary'
    },
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TransferError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ImportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List importResponseDescriptor = $convert.base64Decode(
    'Cg5JbXBvcnRSZXNwb25zZRI5Cghwcm9ncmVzcxgBIAEoCzIbLnF1ZXJhdnVlLnYxLkltcG9ydF'
    'Byb2dyZXNzSABSCHByb2dyZXNzEjYKB3N1bW1hcnkYAiABKAsyGi5xdWVyYXZ1ZS52MS5JbXBv'
    'cnRTdW1tYXJ5SABSB3N1bW1hcnkSMgoFZXJyb3IYAyABKAsyGi5xdWVyYXZ1ZS52MS5UcmFuc2'
    'ZlckVycm9ySABSBWVycm9yQgcKBWV2ZW50');
