// This is a generated file - do not edit.
//
// Generated from queravue/v1/stats.proto.

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

@$core.Deprecated('Use statEntryDescriptor instead')
const StatEntry$json = {
  '1': 'StatEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'value', '3': 3, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `StatEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statEntryDescriptor = $convert.base64Decode(
    'CglTdGF0RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFbGFiZWwYAiABKAlSBWxhYmVsEhQKBX'
    'ZhbHVlGAMgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use tableStatsDescriptor instead')
const TableStats$json = {
  '1': 'TableStats',
  '2': [
    {
      '1': 'estimated_rows',
      '3': 1,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'estimatedRows',
      '17': true
    },
    {
      '1': 'data_bytes',
      '3': 2,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'dataBytes',
      '17': true
    },
    {
      '1': 'index_bytes',
      '3': 3,
      '4': 1,
      '5': 4,
      '9': 2,
      '10': 'indexBytes',
      '17': true
    },
    {
      '1': 'total_bytes',
      '3': 4,
      '4': 1,
      '5': 4,
      '9': 3,
      '10': 'totalBytes',
      '17': true
    },
    {
      '1': 'extras',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.StatEntry',
      '10': 'extras'
    },
  ],
  '8': [
    {'1': '_estimated_rows'},
    {'1': '_data_bytes'},
    {'1': '_index_bytes'},
    {'1': '_total_bytes'},
  ],
};

/// Descriptor for `TableStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableStatsDescriptor = $convert.base64Decode(
    'CgpUYWJsZVN0YXRzEioKDmVzdGltYXRlZF9yb3dzGAEgASgDSABSDWVzdGltYXRlZFJvd3OIAQ'
    'ESIgoKZGF0YV9ieXRlcxgCIAEoBEgBUglkYXRhQnl0ZXOIAQESJAoLaW5kZXhfYnl0ZXMYAyAB'
    'KARIAlIKaW5kZXhCeXRlc4gBARIkCgt0b3RhbF9ieXRlcxgEIAEoBEgDUgp0b3RhbEJ5dGVziA'
    'EBEi4KBmV4dHJhcxgFIAMoCzIWLnF1ZXJhdnVlLnYxLlN0YXRFbnRyeVIGZXh0cmFzQhEKD19l'
    'c3RpbWF0ZWRfcm93c0INCgtfZGF0YV9ieXRlc0IOCgxfaW5kZXhfYnl0ZXNCDgoMX3RvdGFsX2'
    'J5dGVz');

@$core.Deprecated('Use getStatsRequestDescriptor instead')
const GetStatsRequest$json = {
  '1': 'GetStatsRequest',
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

/// Descriptor for `GetStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRTdGF0c1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjIKCXRhYm'
    'xlX3JlZhgCIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgh0YWJsZVJlZg==');

@$core.Deprecated('Use getStatsResponseDescriptor instead')
const GetStatsResponse$json = {
  '1': 'GetStatsResponse',
  '2': [
    {
      '1': 'stats',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableStats',
      '10': 'stats'
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

/// Descriptor for `GetStatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRTdGF0c1Jlc3BvbnNlEi0KBXN0YXRzGAEgASgLMhcucXVlcmF2dWUudjEuVGFibGVTdG'
    'F0c1IFc3RhdHMSLQoFZXJyb3IYAiABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJv'
    'cg==');
