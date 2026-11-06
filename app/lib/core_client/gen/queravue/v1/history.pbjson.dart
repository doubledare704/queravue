// This is a generated file - do not edit.
//
// Generated from queravue/v1/history.proto.

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

@$core.Deprecated('Use historyEntryDescriptor instead')
const HistoryEntry$json = {
  '1': 'HistoryEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'connection_id', '3': 2, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'query_text', '3': 3, '4': 1, '5': 9, '10': 'queryText'},
    {
      '1': 'started_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'duration',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
    {'1': 'rows_affected', '3': 6, '4': 1, '5': 4, '10': 'rowsAffected'},
    {'1': 'error', '3': 7, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `HistoryEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List historyEntryDescriptor = $convert.base64Decode(
    'CgxIaXN0b3J5RW50cnkSDgoCaWQYASABKANSAmlkEiMKDWNvbm5lY3Rpb25faWQYAiABKAlSDG'
    'Nvbm5lY3Rpb25JZBIdCgpxdWVyeV90ZXh0GAMgASgJUglxdWVyeVRleHQSOQoKc3RhcnRlZF9h'
    'dBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0ZWRBdBI1CghkdXJhdG'
    'lvbhgFIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIIZHVyYXRpb24SIwoNcm93c19h'
    'ZmZlY3RlZBgGIAEoBFIMcm93c0FmZmVjdGVkEhQKBWVycm9yGAcgASgJUgVlcnJvcg==');

@$core.Deprecated('Use listHistoryRequestDescriptor instead')
const ListHistoryRequest$json = {
  '1': 'ListHistoryRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'search_query', '3': 2, '4': 1, '5': 9, '10': 'searchQuery'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'offset', '3': 4, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `ListHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHistoryRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0SGlzdG9yeVJlcXVlc3QSIwoNY29ubmVjdGlvbl9pZBgBIAEoCVIMY29ubmVjdGlvbk'
    'lkEiEKDHNlYXJjaF9xdWVyeRgCIAEoCVILc2VhcmNoUXVlcnkSFAoFbGltaXQYAyABKA1SBWxp'
    'bWl0EhYKBm9mZnNldBgEIAEoDVIGb2Zmc2V0');

@$core.Deprecated('Use listHistoryResponseDescriptor instead')
const ListHistoryResponse$json = {
  '1': 'ListHistoryResponse',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.HistoryEntry',
      '10': 'entries'
    },
    {'1': 'total_count', '3': 2, '4': 1, '5': 4, '10': 'totalCount'},
  ],
};

/// Descriptor for `ListHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHistoryResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0SGlzdG9yeVJlc3BvbnNlEjMKB2VudHJpZXMYASADKAsyGS5xdWVyYXZ1ZS52MS5IaX'
    'N0b3J5RW50cnlSB2VudHJpZXMSHwoLdG90YWxfY291bnQYAiABKARSCnRvdGFsQ291bnQ=');

@$core.Deprecated('Use clearHistoryRequestDescriptor instead')
const ClearHistoryRequest$json = {
  '1': 'ClearHistoryRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `ClearHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clearHistoryRequestDescriptor = $convert.base64Decode(
    'ChNDbGVhckhpc3RvcnlSZXF1ZXN0EiMKDWNvbm5lY3Rpb25faWQYASABKAlSDGNvbm5lY3Rpb2'
    '5JZA==');

@$core.Deprecated('Use clearHistoryResponseDescriptor instead')
const ClearHistoryResponse$json = {
  '1': 'ClearHistoryResponse',
};

/// Descriptor for `ClearHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clearHistoryResponseDescriptor =
    $convert.base64Decode('ChRDbGVhckhpc3RvcnlSZXNwb25zZQ==');
