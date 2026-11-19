// This is a generated file - do not edit.
//
// Generated from queravue/v1/gridfs.proto.

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

@$core.Deprecated('Use gridFsErrorKindDescriptor instead')
const GridFsErrorKind$json = {
  '1': 'GridFsErrorKind',
  '2': [
    {'1': 'GRID_FS_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'GRID_FS_ERROR_KIND_PARSE', '2': 1},
    {'1': 'GRID_FS_ERROR_KIND_NOT_FOUND', '2': 2},
    {'1': 'GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 3},
    {'1': 'GRID_FS_ERROR_KIND_AUTH', '2': 4},
    {'1': 'GRID_FS_ERROR_KIND_NETWORK', '2': 5},
    {'1': 'GRID_FS_ERROR_KIND_TIMEOUT', '2': 6},
    {'1': 'GRID_FS_ERROR_KIND_CANCELED', '2': 7},
    {'1': 'GRID_FS_ERROR_KIND_UNSUPPORTED', '2': 8},
    {'1': 'GRID_FS_ERROR_KIND_SERVER', '2': 9},
    {'1': 'GRID_FS_ERROR_KIND_CORRUPT', '2': 10},
  ],
};

/// Descriptor for `GridFsErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridFsErrorKindDescriptor = $convert.base64Decode(
    'Cg9HcmlkRnNFcnJvcktpbmQSIgoeR1JJRF9GU19FUlJPUl9LSU5EX1VOU1BFQ0lGSUVEEAASHA'
    'oYR1JJRF9GU19FUlJPUl9LSU5EX1BBUlNFEAESIAocR1JJRF9GU19FUlJPUl9LSU5EX05PVF9G'
    'T1VORBACEiwKKEdSSURfRlNfRVJST1JfS0lORF9DT05GSVJNQVRJT05fUkVRVUlSRUQQAxIbCh'
    'dHUklEX0ZTX0VSUk9SX0tJTkRfQVVUSBAEEh4KGkdSSURfRlNfRVJST1JfS0lORF9ORVRXT1JL'
    'EAUSHgoaR1JJRF9GU19FUlJPUl9LSU5EX1RJTUVPVVQQBhIfChtHUklEX0ZTX0VSUk9SX0tJTk'
    'RfQ0FOQ0VMRUQQBxIiCh5HUklEX0ZTX0VSUk9SX0tJTkRfVU5TVVBQT1JURUQQCBIdChlHUklE'
    'X0ZTX0VSUk9SX0tJTkRfU0VSVkVSEAkSHgoaR1JJRF9GU19FUlJPUl9LSU5EX0NPUlJVUFQQCg'
    '==');

@$core.Deprecated('Use gridFsErrorDescriptor instead')
const GridFsError$json = {
  '1': 'GridFsError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.GridFsErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `GridFsError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFsErrorDescriptor = $convert.base64Decode(
    'CgtHcmlkRnNFcnJvchIwCgRraW5kGAEgASgOMhwucXVlcmF2dWUudjEuR3JpZEZzRXJyb3JLaW'
    '5kUgRraW5kEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use gridFsBucketDescriptor instead')
const GridFsBucket$json = {
  '1': 'GridFsBucket',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'file_count_estimate',
      '3': 2,
      '4': 1,
      '5': 4,
      '10': 'fileCountEstimate'
    },
    {
      '1': 'total_bytes',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 0,
      '10': 'totalBytes',
      '17': true
    },
  ],
  '8': [
    {'1': '_total_bytes'},
  ],
};

/// Descriptor for `GridFsBucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFsBucketDescriptor = $convert.base64Decode(
    'CgxHcmlkRnNCdWNrZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIuChNmaWxlX2NvdW50X2VzdGltYX'
    'RlGAIgASgEUhFmaWxlQ291bnRFc3RpbWF0ZRIkCgt0b3RhbF9ieXRlcxgDIAEoBEgAUgp0b3Rh'
    'bEJ5dGVziAEBQg4KDF90b3RhbF9ieXRlcw==');

@$core.Deprecated('Use gridFsFileDescriptor instead')
const GridFsFile$json = {
  '1': 'GridFsFile',
  '2': [
    {'1': 'id_ejson', '3': 1, '4': 1, '5': 9, '10': 'idEjson'},
    {'1': 'filename', '3': 2, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'length', '3': 3, '4': 1, '5': 4, '10': 'length'},
    {'1': 'chunk_size', '3': 4, '4': 1, '5': 13, '10': 'chunkSize'},
    {'1': 'upload_date_ms', '3': 5, '4': 1, '5': 3, '10': 'uploadDateMs'},
    {'1': 'content_type', '3': 6, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'metadata_ejson', '3': 7, '4': 1, '5': 9, '10': 'metadataEjson'},
  ],
};

/// Descriptor for `GridFsFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFsFileDescriptor = $convert.base64Decode(
    'CgpHcmlkRnNGaWxlEhkKCGlkX2Vqc29uGAEgASgJUgdpZEVqc29uEhoKCGZpbGVuYW1lGAIgAS'
    'gJUghmaWxlbmFtZRIWCgZsZW5ndGgYAyABKARSBmxlbmd0aBIdCgpjaHVua19zaXplGAQgASgN'
    'UgljaHVua1NpemUSJAoOdXBsb2FkX2RhdGVfbXMYBSABKANSDHVwbG9hZERhdGVNcxIhCgxjb2'
    '50ZW50X3R5cGUYBiABKAlSC2NvbnRlbnRUeXBlEiUKDm1ldGFkYXRhX2Vqc29uGAcgASgJUg1t'
    'ZXRhZGF0YUVqc29u');

@$core.Deprecated('Use listBucketsRequestDescriptor instead')
const ListBucketsRequest$json = {
  '1': 'ListBucketsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
  ],
};

/// Descriptor for `ListBucketsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBucketsRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0QnVja2V0c1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCG'
    'RhdGFiYXNlGAIgASgJUghkYXRhYmFzZQ==');

@$core.Deprecated('Use listBucketsResponseDescriptor instead')
const ListBucketsResponse$json = {
  '1': 'ListBucketsResponse',
  '2': [
    {
      '1': 'buckets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.GridFsBucket',
      '10': 'buckets'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ListBucketsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBucketsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0QnVja2V0c1Jlc3BvbnNlEjMKB2J1Y2tldHMYASADKAsyGS5xdWVyYXZ1ZS52MS5Hcm'
    'lkRnNCdWNrZXRSB2J1Y2tldHMSLgoFZXJyb3IYAiABKAsyGC5xdWVyYXZ1ZS52MS5HcmlkRnNF'
    'cnJvclIFZXJyb3I=');

@$core.Deprecated('Use listFilesRequestDescriptor instead')
const ListFilesRequest$json = {
  '1': 'ListFilesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'bucket', '3': 3, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'filter', '3': 4, '4': 1, '5': 9, '10': 'filter'},
    {'1': 'sort', '3': 5, '4': 1, '5': 9, '10': 'sort'},
    {'1': 'skip', '3': 6, '4': 1, '5': 4, '10': 'skip'},
    {'1': 'limit', '3': 7, '4': 1, '5': 4, '10': 'limit'},
    {'1': 'max_time_ms', '3': 8, '4': 1, '5': 13, '10': 'maxTimeMs'},
  ],
};

/// Descriptor for `ListFilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFilesRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0RmlsZXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIaCghkYX'
    'RhYmFzZRgCIAEoCVIIZGF0YWJhc2USFgoGYnVja2V0GAMgASgJUgZidWNrZXQSFgoGZmlsdGVy'
    'GAQgASgJUgZmaWx0ZXISEgoEc29ydBgFIAEoCVIEc29ydBISCgRza2lwGAYgASgEUgRza2lwEh'
    'QKBWxpbWl0GAcgASgEUgVsaW1pdBIeCgttYXhfdGltZV9tcxgIIAEoDVIJbWF4VGltZU1z');

@$core.Deprecated('Use gridFsFileBatchDescriptor instead')
const GridFsFileBatch$json = {
  '1': 'GridFsFileBatch',
  '2': [
    {'1': 'offset', '3': 1, '4': 1, '5': 4, '10': 'offset'},
    {
      '1': 'files',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.GridFsFile',
      '10': 'files'
    },
    {'1': 'done', '3': 3, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `GridFsFileBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFsFileBatchDescriptor = $convert.base64Decode(
    'Cg9HcmlkRnNGaWxlQmF0Y2gSFgoGb2Zmc2V0GAEgASgEUgZvZmZzZXQSLQoFZmlsZXMYAiADKA'
    'syFy5xdWVyYXZ1ZS52MS5HcmlkRnNGaWxlUgVmaWxlcxISCgRkb25lGAMgASgIUgRkb25l');

@$core.Deprecated('Use listFilesResponseDescriptor instead')
const ListFilesResponse$json = {
  '1': 'ListFilesResponse',
  '2': [
    {
      '1': 'batch',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsFileBatch',
      '9': 0,
      '10': 'batch'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ListFilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFilesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0RmlsZXNSZXNwb25zZRI0CgViYXRjaBgBIAEoCzIcLnF1ZXJhdnVlLnYxLkdyaWRGc0'
    'ZpbGVCYXRjaEgAUgViYXRjaBIwCgVlcnJvchgCIAEoCzIYLnF1ZXJhdnVlLnYxLkdyaWRGc0Vy'
    'cm9ySABSBWVycm9yQgcKBWV2ZW50');

@$core.Deprecated('Use downloadRequestDescriptor instead')
const DownloadRequest$json = {
  '1': 'DownloadRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'bucket', '3': 3, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'id_ejson', '3': 4, '4': 1, '5': 9, '10': 'idEjson'},
    {'1': 'offset', '3': 5, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'length', '3': 6, '4': 1, '5': 4, '9': 0, '10': 'length', '17': true},
  ],
  '8': [
    {'1': '_length'},
  ],
};

/// Descriptor for `DownloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadRequestDescriptor = $convert.base64Decode(
    'Cg9Eb3dubG9hZFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCGRhdG'
    'FiYXNlGAIgASgJUghkYXRhYmFzZRIWCgZidWNrZXQYAyABKAlSBmJ1Y2tldBIZCghpZF9lanNv'
    'bhgEIAEoCVIHaWRFanNvbhIWCgZvZmZzZXQYBSABKARSBm9mZnNldBIbCgZsZW5ndGgYBiABKA'
    'RIAFIGbGVuZ3RoiAEBQgkKB19sZW5ndGg=');

@$core.Deprecated('Use downloadResponseDescriptor instead')
const DownloadResponse$json = {
  '1': 'DownloadResponse',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsFile',
      '9': 0,
      '10': 'file'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `DownloadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadResponseDescriptor = $convert.base64Decode(
    'ChBEb3dubG9hZFJlc3BvbnNlEi0KBGZpbGUYASABKAsyFy5xdWVyYXZ1ZS52MS5HcmlkRnNGaW'
    'xlSABSBGZpbGUSFgoFY2h1bmsYAiABKAxIAFIFY2h1bmsSMAoFZXJyb3IYAyABKAsyGC5xdWVy'
    'YXZ1ZS52MS5HcmlkRnNFcnJvckgAUgVlcnJvckIHCgVldmVudA==');

@$core.Deprecated('Use uploadHeaderDescriptor instead')
const UploadHeader$json = {
  '1': 'UploadHeader',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'bucket', '3': 3, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'filename', '3': 4, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'content_type', '3': 5, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'metadata_ejson', '3': 6, '4': 1, '5': 9, '10': 'metadataEjson'},
    {'1': 'chunk_size_bytes', '3': 7, '4': 1, '5': 13, '10': 'chunkSizeBytes'},
    {'1': 'replace_id_ejson', '3': 8, '4': 1, '5': 9, '10': 'replaceIdEjson'},
    {'1': 'confirmed', '3': 9, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `UploadHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadHeaderDescriptor = $convert.base64Decode(
    'CgxVcGxvYWRIZWFkZXISHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCGRhdGFiYX'
    'NlGAIgASgJUghkYXRhYmFzZRIWCgZidWNrZXQYAyABKAlSBmJ1Y2tldBIaCghmaWxlbmFtZRgE'
    'IAEoCVIIZmlsZW5hbWUSIQoMY29udGVudF90eXBlGAUgASgJUgtjb250ZW50VHlwZRIlCg5tZX'
    'RhZGF0YV9lanNvbhgGIAEoCVINbWV0YWRhdGFFanNvbhIoChBjaHVua19zaXplX2J5dGVzGAcg'
    'ASgNUg5jaHVua1NpemVCeXRlcxIoChByZXBsYWNlX2lkX2Vqc29uGAggASgJUg5yZXBsYWNlSW'
    'RFanNvbhIcCgljb25maXJtZWQYCSABKAhSCWNvbmZpcm1lZA==');

@$core.Deprecated('Use uploadRequestDescriptor instead')
const UploadRequest$json = {
  '1': 'UploadRequest',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.UploadHeader',
      '9': 0,
      '10': 'header'
    },
    {'1': 'chunk', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'chunk'},
  ],
  '8': [
    {'1': 'part'},
  ],
};

/// Descriptor for `UploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadRequestDescriptor = $convert.base64Decode(
    'Cg1VcGxvYWRSZXF1ZXN0EjMKBmhlYWRlchgBIAEoCzIZLnF1ZXJhdnVlLnYxLlVwbG9hZEhlYW'
    'RlckgAUgZoZWFkZXISFgoFY2h1bmsYAiABKAxIAFIFY2h1bmtCBgoEcGFydA==');

@$core.Deprecated('Use uploadResponseDescriptor instead')
const UploadResponse$json = {
  '1': 'UploadResponse',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsFile',
      '10': 'file'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `UploadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadResponseDescriptor = $convert.base64Decode(
    'Cg5VcGxvYWRSZXNwb25zZRIrCgRmaWxlGAEgASgLMhcucXVlcmF2dWUudjEuR3JpZEZzRmlsZV'
    'IEZmlsZRIuCgVlcnJvchgCIAEoCzIYLnF1ZXJhdnVlLnYxLkdyaWRGc0Vycm9yUgVlcnJvcg==');

@$core.Deprecated('Use deleteFileRequestDescriptor instead')
const DeleteFileRequest$json = {
  '1': 'DeleteFileRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'bucket', '3': 3, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'id_ejson', '3': 4, '4': 1, '5': 9, '10': 'idEjson'},
    {'1': 'confirmed', '3': 5, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `DeleteFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFileRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVGaWxlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKAlSCGRhdGFiYXNlEhYKBmJ1Y2tldBgDIAEoCVIGYnVja2V0EhkKCGlkX2Vq'
    'c29uGAQgASgJUgdpZEVqc29uEhwKCWNvbmZpcm1lZBgFIAEoCFIJY29uZmlybWVk');

@$core.Deprecated('Use deleteFileResponseDescriptor instead')
const DeleteFileResponse$json = {
  '1': 'DeleteFileResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `DeleteFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFileResponseDescriptor = $convert.base64Decode(
    'ChJEZWxldGVGaWxlUmVzcG9uc2USLgoFZXJyb3IYASABKAsyGC5xdWVyYXZ1ZS52MS5HcmlkRn'
    'NFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use renameFileRequestDescriptor instead')
const RenameFileRequest$json = {
  '1': 'RenameFileRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'bucket', '3': 3, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'id_ejson', '3': 4, '4': 1, '5': 9, '10': 'idEjson'},
    {'1': 'new_filename', '3': 5, '4': 1, '5': 9, '10': 'newFilename'},
  ],
};

/// Descriptor for `RenameFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameFileRequestDescriptor = $convert.base64Decode(
    'ChFSZW5hbWVGaWxlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKAlSCGRhdGFiYXNlEhYKBmJ1Y2tldBgDIAEoCVIGYnVja2V0EhkKCGlkX2Vq'
    'c29uGAQgASgJUgdpZEVqc29uEiEKDG5ld19maWxlbmFtZRgFIAEoCVILbmV3RmlsZW5hbWU=');

@$core.Deprecated('Use renameFileResponseDescriptor instead')
const RenameFileResponse$json = {
  '1': 'RenameFileResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.GridFsError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `RenameFileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameFileResponseDescriptor = $convert.base64Decode(
    'ChJSZW5hbWVGaWxlUmVzcG9uc2USLgoFZXJyb3IYASABKAsyGC5xdWVyYXZ1ZS52MS5HcmlkRn'
    'NFcnJvclIFZXJyb3I=');
