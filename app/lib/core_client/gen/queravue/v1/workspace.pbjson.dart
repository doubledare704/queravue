// This is a generated file - do not edit.
//
// Generated from queravue/v1/workspace.proto.

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

@$core.Deprecated('Use workspaceErrorKindDescriptor instead')
const WorkspaceErrorKind$json = {
  '1': 'WorkspaceErrorKind',
  '2': [
    {'1': 'WORKSPACE_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT', '2': 1},
    {'1': 'WORKSPACE_ERROR_KIND_NOT_FOUND', '2': 2},
    {'1': 'WORKSPACE_ERROR_KIND_ALREADY_EXISTS', '2': 3},
    {'1': 'WORKSPACE_ERROR_KIND_CONFLICT', '2': 4},
    {'1': 'WORKSPACE_ERROR_KIND_TOO_LARGE', '2': 5},
    {'1': 'WORKSPACE_ERROR_KIND_IO', '2': 6},
  ],
};

/// Descriptor for `WorkspaceErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceErrorKindDescriptor = $convert.base64Decode(
    'ChJXb3Jrc3BhY2VFcnJvcktpbmQSJAogV09SS1NQQUNFX0VSUk9SX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIqCiZXT1JLU1BBQ0VfRVJST1JfS0lORF9QQVRIX0VTQ0FQRVNfUk9PVBABEiIKHldPUktT'
    'UEFDRV9FUlJPUl9LSU5EX05PVF9GT1VORBACEicKI1dPUktTUEFDRV9FUlJPUl9LSU5EX0FMUk'
    'VBRFlfRVhJU1RTEAMSIQodV09SS1NQQUNFX0VSUk9SX0tJTkRfQ09ORkxJQ1QQBBIiCh5XT1JL'
    'U1BBQ0VfRVJST1JfS0lORF9UT09fTEFSR0UQBRIbChdXT1JLU1BBQ0VfRVJST1JfS0lORF9JTx'
    'AG');

@$core.Deprecated('Use fileKindDescriptor instead')
const FileKind$json = {
  '1': 'FileKind',
  '2': [
    {'1': 'FILE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'FILE_KIND_SQL', '2': 1},
    {'1': 'FILE_KIND_MONGO', '2': 2},
  ],
};

/// Descriptor for `FileKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fileKindDescriptor = $convert.base64Decode(
    'CghGaWxlS2luZBIZChVGSUxFX0tJTkRfVU5TUEVDSUZJRUQQABIRCg1GSUxFX0tJTkRfU1FMEA'
    'ESEwoPRklMRV9LSU5EX01PTkdPEAI=');

@$core.Deprecated('Use changeKindDescriptor instead')
const ChangeKind$json = {
  '1': 'ChangeKind',
  '2': [
    {'1': 'CHANGE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CHANGE_KIND_CREATED', '2': 1},
    {'1': 'CHANGE_KIND_MODIFIED', '2': 2},
    {'1': 'CHANGE_KIND_DELETED', '2': 3},
    {'1': 'CHANGE_KIND_RENAMED', '2': 4},
  ],
};

/// Descriptor for `ChangeKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List changeKindDescriptor = $convert.base64Decode(
    'CgpDaGFuZ2VLaW5kEhsKF0NIQU5HRV9LSU5EX1VOU1BFQ0lGSUVEEAASFwoTQ0hBTkdFX0tJTk'
    'RfQ1JFQVRFRBABEhgKFENIQU5HRV9LSU5EX01PRElGSUVEEAISFwoTQ0hBTkdFX0tJTkRfREVM'
    'RVRFRBADEhcKE0NIQU5HRV9LSU5EX1JFTkFNRUQQBA==');

@$core.Deprecated('Use workspaceErrorDescriptor instead')
const WorkspaceError$json = {
  '1': 'WorkspaceError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.WorkspaceErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'current',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FileContent',
      '9': 0,
      '10': 'current',
      '17': true
    },
  ],
  '8': [
    {'1': '_current'},
  ],
};

/// Descriptor for `WorkspaceError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceErrorDescriptor = $convert.base64Decode(
    'Cg5Xb3Jrc3BhY2VFcnJvchIzCgRraW5kGAEgASgOMh8ucXVlcmF2dWUudjEuV29ya3NwYWNlRX'
    'Jyb3JLaW5kUgRraW5kEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USNwoHY3VycmVudBgDIAEo'
    'CzIYLnF1ZXJhdnVlLnYxLkZpbGVDb250ZW50SABSB2N1cnJlbnSIAQFCCgoIX2N1cnJlbnQ=');

@$core.Deprecated('Use workspaceRootDescriptor instead')
const WorkspaceRoot$json = {
  '1': 'WorkspaceRoot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `WorkspaceRoot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workspaceRootDescriptor = $convert.base64Decode(
    'Cg1Xb3Jrc3BhY2VSb290Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBH'
    'BhdGgYAyABKAlSBHBhdGg=');

@$core.Deprecated('Use getRootsRequestDescriptor instead')
const GetRootsRequest$json = {
  '1': 'GetRootsRequest',
};

/// Descriptor for `GetRootsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRootsRequestDescriptor =
    $convert.base64Decode('Cg9HZXRSb290c1JlcXVlc3Q=');

@$core.Deprecated('Use getRootsResponseDescriptor instead')
const GetRootsResponse$json = {
  '1': 'GetRootsResponse',
  '2': [
    {
      '1': 'roots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.WorkspaceRoot',
      '10': 'roots'
    },
  ],
};

/// Descriptor for `GetRootsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRootsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRSb290c1Jlc3BvbnNlEjAKBXJvb3RzGAEgAygLMhoucXVlcmF2dWUudjEuV29ya3NwYW'
    'NlUm9vdFIFcm9vdHM=');

@$core.Deprecated('Use setRootsRequestDescriptor instead')
const SetRootsRequest$json = {
  '1': 'SetRootsRequest',
  '2': [
    {
      '1': 'roots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.WorkspaceRoot',
      '10': 'roots'
    },
  ],
};

/// Descriptor for `SetRootsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRootsRequestDescriptor = $convert.base64Decode(
    'Cg9TZXRSb290c1JlcXVlc3QSMAoFcm9vdHMYASADKAsyGi5xdWVyYXZ1ZS52MS5Xb3Jrc3BhY2'
    'VSb290UgVyb290cw==');

@$core.Deprecated('Use setRootsResponseDescriptor instead')
const SetRootsResponse$json = {
  '1': 'SetRootsResponse',
  '2': [
    {
      '1': 'roots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.WorkspaceRoot',
      '10': 'roots'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SetRootsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRootsResponseDescriptor = $convert.base64Decode(
    'ChBTZXRSb290c1Jlc3BvbnNlEjAKBXJvb3RzGAEgAygLMhoucXVlcmF2dWUudjEuV29ya3NwYW'
    'NlUm9vdFIFcm9vdHMSMQoFZXJyb3IYAiABKAsyGy5xdWVyYXZ1ZS52MS5Xb3Jrc3BhY2VFcnJv'
    'clIFZXJyb3I=');

@$core.Deprecated('Use fileMetaDescriptor instead')
const FileMeta$json = {
  '1': 'FileMeta',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'connection', '3': 3, '4': 1, '5': 9, '10': 'connection'},
    {'1': 'tags', '3': 4, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `FileMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileMetaDescriptor = $convert.base64Decode(
    'CghGaWxlTWV0YRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2'
    'Rlc2NyaXB0aW9uEh4KCmNvbm5lY3Rpb24YAyABKAlSCmNvbm5lY3Rpb24SEgoEdGFncxgEIAMo'
    'CVIEdGFncw==');

@$core.Deprecated('Use treeEntryDescriptor instead')
const TreeEntry$json = {
  '1': 'TreeEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'is_dir', '3': 2, '4': 1, '5': 8, '10': 'isDir'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.FileKind',
      '10': 'kind'
    },
    {'1': 'size', '3': 4, '4': 1, '5': 4, '10': 'size'},
    {
      '1': 'mtime',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'mtime'
    },
    {
      '1': 'meta',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FileMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `TreeEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List treeEntryDescriptor = $convert.base64Decode(
    'CglUcmVlRW50cnkSEgoEbmFtZRgBIAEoCVIEbmFtZRIVCgZpc19kaXIYAiABKAhSBWlzRGlyEi'
    'kKBGtpbmQYAyABKA4yFS5xdWVyYXZ1ZS52MS5GaWxlS2luZFIEa2luZBISCgRzaXplGAQgASgE'
    'UgRzaXplEjAKBW10aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIFbXRpbW'
    'USKQoEbWV0YRgGIAEoCzIVLnF1ZXJhdnVlLnYxLkZpbGVNZXRhUgRtZXRh');

@$core.Deprecated('Use listTreeRequestDescriptor instead')
const ListTreeRequest$json = {
  '1': 'ListTreeRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `ListTreeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTreeRequestDescriptor = $convert.base64Decode(
    'Cg9MaXN0VHJlZVJlcXVlc3QSFwoHcm9vdF9pZBgBIAEoCVIGcm9vdElkEhIKBHBhdGgYAiABKA'
    'lSBHBhdGg=');

@$core.Deprecated('Use listTreeResponseDescriptor instead')
const ListTreeResponse$json = {
  '1': 'ListTreeResponse',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TreeEntry',
      '10': 'entries'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ListTreeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTreeResponseDescriptor = $convert.base64Decode(
    'ChBMaXN0VHJlZVJlc3BvbnNlEjAKB2VudHJpZXMYASADKAsyFi5xdWVyYXZ1ZS52MS5UcmVlRW'
    '50cnlSB2VudHJpZXMSMQoFZXJyb3IYAiABKAsyGy5xdWVyYXZ1ZS52MS5Xb3Jrc3BhY2VFcnJv'
    'clIFZXJyb3I=');

@$core.Deprecated('Use fileContentDescriptor instead')
const FileContent$json = {
  '1': 'FileContent',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'mtime',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'mtime'
    },
    {'1': 'hash', '3': 3, '4': 1, '5': 9, '10': 'hash'},
    {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FileMeta',
      '10': 'meta'
    },
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.FileKind',
      '10': 'kind'
    },
  ],
};

/// Descriptor for `FileContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileContentDescriptor = $convert.base64Decode(
    'CgtGaWxlQ29udGVudBIYCgdjb250ZW50GAEgASgJUgdjb250ZW50EjAKBW10aW1lGAIgASgLMh'
    'ouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIFbXRpbWUSEgoEaGFzaBgDIAEoCVIEaGFzaBIp'
    'CgRtZXRhGAQgASgLMhUucXVlcmF2dWUudjEuRmlsZU1ldGFSBG1ldGESKQoEa2luZBgFIAEoDj'
    'IVLnF1ZXJhdnVlLnYxLkZpbGVLaW5kUgRraW5k');

@$core.Deprecated('Use readRequestDescriptor instead')
const ReadRequest$json = {
  '1': 'ReadRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `ReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readRequestDescriptor = $convert.base64Decode(
    'CgtSZWFkUmVxdWVzdBIXCgdyb290X2lkGAEgASgJUgZyb290SWQSEgoEcGF0aBgCIAEoCVIEcG'
    'F0aA==');

@$core.Deprecated('Use readResponseDescriptor instead')
const ReadResponse$json = {
  '1': 'ReadResponse',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FileContent',
      '10': 'file'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ReadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readResponseDescriptor = $convert.base64Decode(
    'CgxSZWFkUmVzcG9uc2USLAoEZmlsZRgBIAEoCzIYLnF1ZXJhdnVlLnYxLkZpbGVDb250ZW50Ug'
    'RmaWxlEjEKBWVycm9yGAIgASgLMhsucXVlcmF2dWUudjEuV29ya3NwYWNlRXJyb3JSBWVycm9y');

@$core.Deprecated('Use writeRequestDescriptor instead')
const WriteRequest$json = {
  '1': 'WriteRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'content', '3': 3, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'expected_mtime',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expectedMtime'
    },
    {'1': 'expected_hash', '3': 5, '4': 1, '5': 9, '10': 'expectedHash'},
    {'1': 'force', '3': 6, '4': 1, '5': 8, '10': 'force'},
  ],
};

/// Descriptor for `WriteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeRequestDescriptor = $convert.base64Decode(
    'CgxXcml0ZVJlcXVlc3QSFwoHcm9vdF9pZBgBIAEoCVIGcm9vdElkEhIKBHBhdGgYAiABKAlSBH'
    'BhdGgSGAoHY29udGVudBgDIAEoCVIHY29udGVudBJBCg5leHBlY3RlZF9tdGltZRgEIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDWV4cGVjdGVkTXRpbWUSIwoNZXhwZWN0ZWRfaG'
    'FzaBgFIAEoCVIMZXhwZWN0ZWRIYXNoEhQKBWZvcmNlGAYgASgIUgVmb3JjZQ==');

@$core.Deprecated('Use writeResponseDescriptor instead')
const WriteResponse$json = {
  '1': 'WriteResponse',
  '2': [
    {
      '1': 'mtime',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'mtime'
    },
    {'1': 'hash', '3': 2, '4': 1, '5': 9, '10': 'hash'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `WriteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeResponseDescriptor = $convert.base64Decode(
    'Cg1Xcml0ZVJlc3BvbnNlEjAKBW10aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIFbXRpbWUSEgoEaGFzaBgCIAEoCVIEaGFzaBIxCgVlcnJvchgDIAEoCzIbLnF1ZXJhdnVl'
    'LnYxLldvcmtzcGFjZUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use createRequestDescriptor instead')
const CreateRequest$json = {
  '1': 'CreateRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'is_dir', '3': 3, '4': 1, '5': 8, '10': 'isDir'},
    {'1': 'content', '3': 4, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `CreateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createRequestDescriptor = $convert.base64Decode(
    'Cg1DcmVhdGVSZXF1ZXN0EhcKB3Jvb3RfaWQYASABKAlSBnJvb3RJZBISCgRwYXRoGAIgASgJUg'
    'RwYXRoEhUKBmlzX2RpchgDIAEoCFIFaXNEaXISGAoHY29udGVudBgEIAEoCVIHY29udGVudA==');

@$core.Deprecated('Use createResponseDescriptor instead')
const CreateResponse$json = {
  '1': 'CreateResponse',
  '2': [
    {
      '1': 'mtime',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'mtime'
    },
    {'1': 'hash', '3': 2, '4': 1, '5': 9, '10': 'hash'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `CreateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createResponseDescriptor = $convert.base64Decode(
    'Cg5DcmVhdGVSZXNwb25zZRIwCgVtdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3'
    'RhbXBSBW10aW1lEhIKBGhhc2gYAiABKAlSBGhhc2gSMQoFZXJyb3IYAyABKAsyGy5xdWVyYXZ1'
    'ZS52MS5Xb3Jrc3BhY2VFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use renameRequestDescriptor instead')
const RenameRequest$json = {
  '1': 'RenameRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'from_path', '3': 2, '4': 1, '5': 9, '10': 'fromPath'},
    {'1': 'to_path', '3': 3, '4': 1, '5': 9, '10': 'toPath'},
  ],
};

/// Descriptor for `RenameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameRequestDescriptor = $convert.base64Decode(
    'Cg1SZW5hbWVSZXF1ZXN0EhcKB3Jvb3RfaWQYASABKAlSBnJvb3RJZBIbCglmcm9tX3BhdGgYAi'
    'ABKAlSCGZyb21QYXRoEhcKB3RvX3BhdGgYAyABKAlSBnRvUGF0aA==');

@$core.Deprecated('Use renameResponseDescriptor instead')
const RenameResponse$json = {
  '1': 'RenameResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `RenameResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameResponseDescriptor = $convert.base64Decode(
    'Cg5SZW5hbWVSZXNwb25zZRIxCgVlcnJvchgBIAEoCzIbLnF1ZXJhdnVlLnYxLldvcmtzcGFjZU'
    'Vycm9yUgVlcnJvcg==');

@$core.Deprecated('Use deleteRequestDescriptor instead')
const DeleteRequest$json = {
  '1': 'DeleteRequest',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `DeleteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteRequestDescriptor = $convert.base64Decode(
    'Cg1EZWxldGVSZXF1ZXN0EhcKB3Jvb3RfaWQYASABKAlSBnJvb3RJZBISCgRwYXRoGAIgASgJUg'
    'RwYXRo');

@$core.Deprecated('Use deleteResponseDescriptor instead')
const DeleteResponse$json = {
  '1': 'DeleteResponse',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WorkspaceError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `DeleteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteResponseDescriptor = $convert.base64Decode(
    'Cg5EZWxldGVSZXNwb25zZRIxCgVlcnJvchgBIAEoCzIbLnF1ZXJhdnVlLnYxLldvcmtzcGFjZU'
    'Vycm9yUgVlcnJvcg==');

@$core.Deprecated('Use searchRequestDescriptor instead')
const SearchRequest$json = {
  '1': 'SearchRequest',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'tags', '3': 2, '4': 3, '5': 9, '10': 'tags'},
    {'1': 'root_id', '3': 3, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'limit', '3': 4, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `SearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchRequestDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hSZXF1ZXN0EhIKBHRleHQYASABKAlSBHRleHQSEgoEdGFncxgCIAMoCVIEdGFncx'
    'IXCgdyb290X2lkGAMgASgJUgZyb290SWQSFAoFbGltaXQYBCABKA1SBWxpbWl0');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.FileKind',
      '10': 'kind'
    },
    {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FileMeta',
      '10': 'meta'
    },
    {'1': 'snippet', '3': 5, '4': 1, '5': 9, '10': 'snippet'},
    {'1': 'line', '3': 6, '4': 1, '5': 13, '10': 'line'},
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRIXCgdyb290X2lkGAEgASgJUgZyb290SWQSEgoEcGF0aBgCIAEoCV'
    'IEcGF0aBIpCgRraW5kGAMgASgOMhUucXVlcmF2dWUudjEuRmlsZUtpbmRSBGtpbmQSKQoEbWV0'
    'YRgEIAEoCzIVLnF1ZXJhdnVlLnYxLkZpbGVNZXRhUgRtZXRhEhgKB3NuaXBwZXQYBSABKAlSB3'
    'NuaXBwZXQSEgoEbGluZRgGIAEoDVIEbGluZQ==');

@$core.Deprecated('Use watchRequestDescriptor instead')
const WatchRequest$json = {
  '1': 'WatchRequest',
  '2': [
    {'1': 'root_ids', '3': 1, '4': 3, '5': 9, '10': 'rootIds'},
  ],
};

/// Descriptor for `WatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchRequestDescriptor = $convert
    .base64Decode('CgxXYXRjaFJlcXVlc3QSGQoIcm9vdF9pZHMYASADKAlSB3Jvb3RJZHM=');

@$core.Deprecated('Use watchResponseDescriptor instead')
const WatchResponse$json = {
  '1': 'WatchResponse',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 9, '10': 'rootId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ChangeKind',
      '10': 'kind'
    },
    {'1': 'old_path', '3': 4, '4': 1, '5': 9, '10': 'oldPath'},
    {
      '1': 'mtime',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'mtime'
    },
  ],
};

/// Descriptor for `WatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchResponseDescriptor = $convert.base64Decode(
    'Cg1XYXRjaFJlc3BvbnNlEhcKB3Jvb3RfaWQYASABKAlSBnJvb3RJZBISCgRwYXRoGAIgASgJUg'
    'RwYXRoEisKBGtpbmQYAyABKA4yFy5xdWVyYXZ1ZS52MS5DaGFuZ2VLaW5kUgRraW5kEhkKCG9s'
    'ZF9wYXRoGAQgASgJUgdvbGRQYXRoEjAKBW10aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLl'
    'RpbWVzdGFtcFIFbXRpbWU=');
