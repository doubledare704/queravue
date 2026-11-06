// This is a generated file - do not edit.
//
// Generated from queravue/v1/document.proto.

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

@$core.Deprecated('Use documentErrorKindDescriptor instead')
const DocumentErrorKind$json = {
  '1': 'DocumentErrorKind',
  '2': [
    {'1': 'DOCUMENT_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'DOCUMENT_ERROR_KIND_PARSE', '2': 1},
    {'1': 'DOCUMENT_ERROR_KIND_CONFLICT', '2': 2},
    {'1': 'DOCUMENT_ERROR_KIND_NOT_FOUND', '2': 3},
    {'1': 'DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 4},
    {'1': 'DOCUMENT_ERROR_KIND_AUTH', '2': 5},
    {'1': 'DOCUMENT_ERROR_KIND_NETWORK', '2': 6},
    {'1': 'DOCUMENT_ERROR_KIND_TIMEOUT', '2': 7},
    {'1': 'DOCUMENT_ERROR_KIND_CANCELED', '2': 8},
    {'1': 'DOCUMENT_ERROR_KIND_UNSUPPORTED', '2': 9},
    {'1': 'DOCUMENT_ERROR_KIND_SERVER', '2': 10},
  ],
};

/// Descriptor for `DocumentErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentErrorKindDescriptor = $convert.base64Decode(
    'ChFEb2N1bWVudEVycm9yS2luZBIjCh9ET0NVTUVOVF9FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEA'
    'ASHQoZRE9DVU1FTlRfRVJST1JfS0lORF9QQVJTRRABEiAKHERPQ1VNRU5UX0VSUk9SX0tJTkRf'
    'Q09ORkxJQ1QQAhIhCh1ET0NVTUVOVF9FUlJPUl9LSU5EX05PVF9GT1VORBADEi0KKURPQ1VNRU'
    '5UX0VSUk9SX0tJTkRfQ09ORklSTUFUSU9OX1JFUVVJUkVEEAQSHAoYRE9DVU1FTlRfRVJST1Jf'
    'S0lORF9BVVRIEAUSHwobRE9DVU1FTlRfRVJST1JfS0lORF9ORVRXT1JLEAYSHwobRE9DVU1FTl'
    'RfRVJST1JfS0lORF9USU1FT1VUEAcSIAocRE9DVU1FTlRfRVJST1JfS0lORF9DQU5DRUxFRBAI'
    'EiMKH0RPQ1VNRU5UX0VSUk9SX0tJTkRfVU5TVVBQT1JURUQQCRIeChpET0NVTUVOVF9FUlJPUl'
    '9LSU5EX1NFUlZFUhAK');

@$core.Deprecated('Use documentInputDescriptor instead')
const DocumentInput$json = {
  '1': 'DocumentInput',
  '2': [
    {'1': 'DOCUMENT_INPUT_UNSPECIFIED', '2': 0},
    {'1': 'DOCUMENT_INPUT_FILTER', '2': 1},
    {'1': 'DOCUMENT_INPUT_SORT', '2': 2},
    {'1': 'DOCUMENT_INPUT_PROJECTION', '2': 3},
    {'1': 'DOCUMENT_INPUT_DOCUMENT', '2': 4},
  ],
};

/// Descriptor for `DocumentInput`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentInputDescriptor = $convert.base64Decode(
    'Cg1Eb2N1bWVudElucHV0Eh4KGkRPQ1VNRU5UX0lOUFVUX1VOU1BFQ0lGSUVEEAASGQoVRE9DVU'
    '1FTlRfSU5QVVRfRklMVEVSEAESFwoTRE9DVU1FTlRfSU5QVVRfU09SVBACEh0KGURPQ1VNRU5U'
    'X0lOUFVUX1BST0pFQ1RJT04QAxIbChdET0NVTUVOVF9JTlBVVF9ET0NVTUVOVBAE');

@$core.Deprecated('Use documentErrorDescriptor instead')
const DocumentError$json = {
  '1': 'DocumentError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.DocumentErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'input',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.DocumentInput',
      '10': 'input'
    },
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
      '1': 'document_index',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'documentIndex',
      '17': true
    },
    {
      '1': 'current_document',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'currentDocument',
      '17': true
    },
  ],
  '8': [
    {'1': '_position'},
    {'1': '_document_index'},
    {'1': '_current_document'},
  ],
};

/// Descriptor for `DocumentError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentErrorDescriptor = $convert.base64Decode(
    'Cg1Eb2N1bWVudEVycm9yEjIKBGtpbmQYASABKA4yHi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEVycm'
    '9yS2luZFIEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEjAKBWlucHV0GAMgASgOMhou'
    'cXVlcmF2dWUudjEuRG9jdW1lbnRJbnB1dFIFaW5wdXQSHwoIcG9zaXRpb24YBCABKA1IAFIIcG'
    '9zaXRpb26IAQESKgoOZG9jdW1lbnRfaW5kZXgYBSABKA1IAVINZG9jdW1lbnRJbmRleIgBARIu'
    'ChBjdXJyZW50X2RvY3VtZW50GAYgASgJSAJSD2N1cnJlbnREb2N1bWVudIgBAUILCglfcG9zaX'
    'Rpb25CEQoPX2RvY3VtZW50X2luZGV4QhMKEV9jdXJyZW50X2RvY3VtZW50');

@$core.Deprecated('Use findRequestDescriptor instead')
const FindRequest$json = {
  '1': 'FindRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'filter', '3': 4, '4': 1, '5': 9, '10': 'filter'},
    {'1': 'sort', '3': 5, '4': 1, '5': 9, '10': 'sort'},
    {'1': 'projection', '3': 6, '4': 1, '5': 9, '10': 'projection'},
    {'1': 'skip', '3': 7, '4': 1, '5': 4, '10': 'skip'},
    {'1': 'limit', '3': 8, '4': 1, '5': 4, '10': 'limit'},
    {'1': 'batch_size', '3': 9, '4': 1, '5': 13, '10': 'batchSize'},
    {'1': 'max_time_ms', '3': 10, '4': 1, '5': 13, '10': 'maxTimeMs'},
  ],
};

/// Descriptor for `FindRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List findRequestDescriptor = $convert.base64Decode(
    'CgtGaW5kUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZGF0YWJhc2'
    'UYAiABKAlSCGRhdGFiYXNlEh4KCmNvbGxlY3Rpb24YAyABKAlSCmNvbGxlY3Rpb24SFgoGZmls'
    'dGVyGAQgASgJUgZmaWx0ZXISEgoEc29ydBgFIAEoCVIEc29ydBIeCgpwcm9qZWN0aW9uGAYgAS'
    'gJUgpwcm9qZWN0aW9uEhIKBHNraXAYByABKARSBHNraXASFAoFbGltaXQYCCABKARSBWxpbWl0'
    'Eh0KCmJhdGNoX3NpemUYCSABKA1SCWJhdGNoU2l6ZRIeCgttYXhfdGltZV9tcxgKIAEoDVIJbW'
    'F4VGltZU1z');

@$core.Deprecated('Use documentBatchDescriptor instead')
const DocumentBatch$json = {
  '1': 'DocumentBatch',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'documents', '3': 2, '4': 3, '5': 9, '10': 'documents'},
    {'1': 'done', '3': 3, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `DocumentBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentBatchDescriptor = $convert.base64Decode(
    'Cg1Eb2N1bWVudEJhdGNoEhYKBm9mZnNldBgBIAEoBFIGb2Zmc2V0EhwKCWRvY3VtZW50cxgCIA'
    'MoCVIJZG9jdW1lbnRzEhIKBGRvbmUYAyABKAhSBGRvbmU=');

@$core.Deprecated('Use findResponseDescriptor instead')
const FindResponse$json = {
  '1': 'FindResponse',
  '2': [
    {
      '1': 'batch',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentBatch',
      '9': 0,
      '10': 'batch'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `FindResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List findResponseDescriptor = $convert.base64Decode(
    'CgxGaW5kUmVzcG9uc2USMgoFYmF0Y2gYASABKAsyGi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEJhdG'
    'NoSABSBWJhdGNoEjIKBWVycm9yGAIgASgLMhoucXVlcmF2dWUudjEuRG9jdW1lbnRFcnJvckgA'
    'UgVlcnJvckIHCgVldmVudA==');

@$core.Deprecated('Use countRequestDescriptor instead')
const CountRequest$json = {
  '1': 'CountRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'filter', '3': 4, '4': 1, '5': 9, '10': 'filter'},
    {'1': 'max_time_ms', '3': 5, '4': 1, '5': 13, '10': 'maxTimeMs'},
  ],
};

/// Descriptor for `CountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List countRequestDescriptor = $convert.base64Decode(
    'CgxDb3VudFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCGRhdGFiYX'
    'NlGAIgASgJUghkYXRhYmFzZRIeCgpjb2xsZWN0aW9uGAMgASgJUgpjb2xsZWN0aW9uEhYKBmZp'
    'bHRlchgEIAEoCVIGZmlsdGVyEh4KC21heF90aW1lX21zGAUgASgNUgltYXhUaW1lTXM=');

@$core.Deprecated('Use countResponseDescriptor instead')
const CountResponse$json = {
  '1': 'CountResponse',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 4, '10': 'count'},
    {'1': 'exact', '3': 2, '4': 1, '5': 8, '10': 'exact'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `CountResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List countResponseDescriptor = $convert.base64Decode(
    'Cg1Db3VudFJlc3BvbnNlEhQKBWNvdW50GAEgASgEUgVjb3VudBIUCgVleGFjdBgCIAEoCFIFZX'
    'hhY3QSMAoFZXJyb3IYAyABKAsyGi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use insertDocumentsRequestDescriptor instead')
const InsertDocumentsRequest$json = {
  '1': 'InsertDocumentsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'documents', '3': 4, '4': 3, '5': 9, '10': 'documents'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `InsertDocumentsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertDocumentsRequestDescriptor = $convert.base64Decode(
    'ChZJbnNlcnREb2N1bWVudHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IaCghkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USHgoKY29sbGVjdGlvbhgDIAEoCVIKY29sbGVj'
    'dGlvbhIcCglkb2N1bWVudHMYBCADKAlSCWRvY3VtZW50cxIcCgljb25maXJtZWQYBSABKAhSCW'
    'NvbmZpcm1lZA==');

@$core.Deprecated('Use insertDocumentsResponseDescriptor instead')
const InsertDocumentsResponse$json = {
  '1': 'InsertDocumentsResponse',
  '2': [
    {'1': 'inserted_ids', '3': 1, '4': 3, '5': 9, '10': 'insertedIds'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `InsertDocumentsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertDocumentsResponseDescriptor = $convert.base64Decode(
    'ChdJbnNlcnREb2N1bWVudHNSZXNwb25zZRIhCgxpbnNlcnRlZF9pZHMYASADKAlSC2luc2VydG'
    'VkSWRzEjAKBWVycm9yGAIgASgLMhoucXVlcmF2dWUudjEuRG9jdW1lbnRFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use replaceDocumentRequestDescriptor instead')
const ReplaceDocumentRequest$json = {
  '1': 'ReplaceDocumentRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'id', '3': 4, '4': 1, '5': 9, '10': 'id'},
    {'1': 'document', '3': 5, '4': 1, '5': 9, '10': 'document'},
    {
      '1': 'expected_document',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'expectedDocument',
      '17': true
    },
    {'1': 'confirmed', '3': 7, '4': 1, '5': 8, '10': 'confirmed'},
  ],
  '8': [
    {'1': '_expected_document'},
  ],
};

/// Descriptor for `ReplaceDocumentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replaceDocumentRequestDescriptor = $convert.base64Decode(
    'ChZSZXBsYWNlRG9jdW1lbnRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IaCghkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USHgoKY29sbGVjdGlvbhgDIAEoCVIKY29sbGVj'
    'dGlvbhIOCgJpZBgEIAEoCVICaWQSGgoIZG9jdW1lbnQYBSABKAlSCGRvY3VtZW50EjAKEWV4cG'
    'VjdGVkX2RvY3VtZW50GAYgASgJSABSEGV4cGVjdGVkRG9jdW1lbnSIAQESHAoJY29uZmlybWVk'
    'GAcgASgIUgljb25maXJtZWRCFAoSX2V4cGVjdGVkX2RvY3VtZW50');

@$core.Deprecated('Use replaceDocumentResponseDescriptor instead')
const ReplaceDocumentResponse$json = {
  '1': 'ReplaceDocumentResponse',
  '2': [
    {'1': 'document', '3': 1, '4': 1, '5': 9, '10': 'document'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ReplaceDocumentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replaceDocumentResponseDescriptor =
    $convert.base64Decode(
        'ChdSZXBsYWNlRG9jdW1lbnRSZXNwb25zZRIaCghkb2N1bWVudBgBIAEoCVIIZG9jdW1lbnQSMA'
        'oFZXJyb3IYAiABKAsyGi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use updateFieldsRequestDescriptor instead')
const UpdateFieldsRequest$json = {
  '1': 'UpdateFieldsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'id', '3': 4, '4': 1, '5': 9, '10': 'id'},
    {'1': 'set', '3': 5, '4': 1, '5': 9, '10': 'set'},
    {'1': 'unset', '3': 6, '4': 3, '5': 9, '10': 'unset'},
    {
      '1': 'expected_document',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'expectedDocument',
      '17': true
    },
    {'1': 'confirmed', '3': 8, '4': 1, '5': 8, '10': 'confirmed'},
  ],
  '8': [
    {'1': '_expected_document'},
  ],
};

/// Descriptor for `UpdateFieldsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateFieldsRequestDescriptor = $convert.base64Decode(
    'ChNVcGRhdGVGaWVsZHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCg'
    'hkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USHgoKY29sbGVjdGlvbhgDIAEoCVIKY29sbGVjdGlv'
    'bhIOCgJpZBgEIAEoCVICaWQSEAoDc2V0GAUgASgJUgNzZXQSFAoFdW5zZXQYBiADKAlSBXVuc2'
    'V0EjAKEWV4cGVjdGVkX2RvY3VtZW50GAcgASgJSABSEGV4cGVjdGVkRG9jdW1lbnSIAQESHAoJ'
    'Y29uZmlybWVkGAggASgIUgljb25maXJtZWRCFAoSX2V4cGVjdGVkX2RvY3VtZW50');

@$core.Deprecated('Use updateFieldsResponseDescriptor instead')
const UpdateFieldsResponse$json = {
  '1': 'UpdateFieldsResponse',
  '2': [
    {'1': 'document', '3': 1, '4': 1, '5': 9, '10': 'document'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `UpdateFieldsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateFieldsResponseDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVGaWVsZHNSZXNwb25zZRIaCghkb2N1bWVudBgBIAEoCVIIZG9jdW1lbnQSMAoFZX'
    'Jyb3IYAiABKAsyGi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use deleteDocumentsRequestDescriptor instead')
const DeleteDocumentsRequest$json = {
  '1': 'DeleteDocumentsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'ids', '3': 4, '4': 3, '5': 9, '10': 'ids'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `DeleteDocumentsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteDocumentsRequestDescriptor = $convert.base64Decode(
    'ChZEZWxldGVEb2N1bWVudHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IaCghkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USHgoKY29sbGVjdGlvbhgDIAEoCVIKY29sbGVj'
    'dGlvbhIQCgNpZHMYBCADKAlSA2lkcxIcCgljb25maXJtZWQYBSABKAhSCWNvbmZpcm1lZA==');

@$core.Deprecated('Use deleteDocumentsResponseDescriptor instead')
const DeleteDocumentsResponse$json = {
  '1': 'DeleteDocumentsResponse',
  '2': [
    {'1': 'deleted_count', '3': 1, '4': 1, '5': 4, '10': 'deletedCount'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `DeleteDocumentsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteDocumentsResponseDescriptor = $convert.base64Decode(
    'ChdEZWxldGVEb2N1bWVudHNSZXNwb25zZRIjCg1kZWxldGVkX2NvdW50GAEgASgEUgxkZWxldG'
    'VkQ291bnQSMAoFZXJyb3IYAiABKAsyGi5xdWVyYXZ1ZS52MS5Eb2N1bWVudEVycm9yUgVlcnJv'
    'cg==');

@$core.Deprecated('Use sampleFieldsRequestDescriptor instead')
const SampleFieldsRequest$json = {
  '1': 'SampleFieldsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'collection', '3': 3, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'sample_size', '3': 4, '4': 1, '5': 13, '10': 'sampleSize'},
  ],
};

/// Descriptor for `SampleFieldsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sampleFieldsRequestDescriptor = $convert.base64Decode(
    'ChNTYW1wbGVGaWVsZHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCg'
    'hkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USHgoKY29sbGVjdGlvbhgDIAEoCVIKY29sbGVjdGlv'
    'bhIfCgtzYW1wbGVfc2l6ZRgEIAEoDVIKc2FtcGxlU2l6ZQ==');

@$core.Deprecated('Use typeCountDescriptor instead')
const TypeCount$json = {
  '1': 'TypeCount',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'count', '3': 2, '4': 1, '5': 13, '10': 'count'},
  ],
};

/// Descriptor for `TypeCount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typeCountDescriptor = $convert.base64Decode(
    'CglUeXBlQ291bnQSEgoEdHlwZRgBIAEoCVIEdHlwZRIUCgVjb3VudBgCIAEoDVIFY291bnQ=');

@$core.Deprecated('Use fieldStatDescriptor instead')
const FieldStat$json = {
  '1': 'FieldStat',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'types',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TypeCount',
      '10': 'types'
    },
    {'1': 'frequency', '3': 3, '4': 1, '5': 1, '10': 'frequency'},
  ],
};

/// Descriptor for `FieldStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldStatDescriptor = $convert.base64Decode(
    'CglGaWVsZFN0YXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIsCgV0eXBlcxgCIAMoCzIWLnF1ZXJhdn'
    'VlLnYxLlR5cGVDb3VudFIFdHlwZXMSHAoJZnJlcXVlbmN5GAMgASgBUglmcmVxdWVuY3k=');

@$core.Deprecated('Use sampleFieldsResponseDescriptor instead')
const SampleFieldsResponse$json = {
  '1': 'SampleFieldsResponse',
  '2': [
    {
      '1': 'fields',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.FieldStat',
      '10': 'fields'
    },
    {'1': 'sampled', '3': 2, '4': 1, '5': 13, '10': 'sampled'},
    {'1': 'used_fallback', '3': 3, '4': 1, '5': 8, '10': 'usedFallback'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SampleFieldsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sampleFieldsResponseDescriptor = $convert.base64Decode(
    'ChRTYW1wbGVGaWVsZHNSZXNwb25zZRIuCgZmaWVsZHMYASADKAsyFi5xdWVyYXZ1ZS52MS5GaW'
    'VsZFN0YXRSBmZpZWxkcxIYCgdzYW1wbGVkGAIgASgNUgdzYW1wbGVkEiMKDXVzZWRfZmFsbGJh'
    'Y2sYAyABKAhSDHVzZWRGYWxsYmFjaxIwCgVlcnJvchgEIAEoCzIaLnF1ZXJhdnVlLnYxLkRvY3'
    'VtZW50RXJyb3JSBWVycm9y');
