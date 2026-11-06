// This is a generated file - do not edit.
//
// Generated from queravue/v1/schema.proto.

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

@$core.Deprecated('Use schemaObjectTypeDescriptor instead')
const SchemaObjectType$json = {
  '1': 'SchemaObjectType',
  '2': [
    {'1': 'SCHEMA_OBJECT_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SCHEMA_OBJECT_TYPE_TABLE', '2': 1},
    {'1': 'SCHEMA_OBJECT_TYPE_VIEW', '2': 2},
    {'1': 'SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW', '2': 3},
  ],
};

/// Descriptor for `SchemaObjectType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List schemaObjectTypeDescriptor = $convert.base64Decode(
    'ChBTY2hlbWFPYmplY3RUeXBlEiIKHlNDSEVNQV9PQkpFQ1RfVFlQRV9VTlNQRUNJRklFRBAAEh'
    'wKGFNDSEVNQV9PQkpFQ1RfVFlQRV9UQUJMRRABEhsKF1NDSEVNQV9PQkpFQ1RfVFlQRV9WSUVX'
    'EAISKAokU0NIRU1BX09CSkVDVF9UWVBFX01BVEVSSUFMSVpFRF9WSUVXEAM=');

@$core.Deprecated('Use tableRefDescriptor instead')
const TableRef$json = {
  '1': 'TableRef',
  '2': [
    {'1': 'database', '3': 1, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 2, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'table', '3': 3, '4': 1, '5': 9, '10': 'table'},
  ],
};

/// Descriptor for `TableRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableRefDescriptor = $convert.base64Decode(
    'CghUYWJsZVJlZhIaCghkYXRhYmFzZRgBIAEoCVIIZGF0YWJhc2USFgoGc2NoZW1hGAIgASgJUg'
    'ZzY2hlbWESFAoFdGFibGUYAyABKAlSBXRhYmxl');

@$core.Deprecated('Use schemaObjectDescriptor instead')
const SchemaObject$json = {
  '1': 'SchemaObject',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SchemaObjectType',
      '10': 'type'
    },
    {
      '1': 'row_count_estimate',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'rowCountEstimate'
    },
  ],
};

/// Descriptor for `SchemaObject`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaObjectDescriptor = $convert.base64Decode(
    'CgxTY2hlbWFPYmplY3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIxCgR0eXBlGAIgASgOMh0ucXVlcm'
    'F2dWUudjEuU2NoZW1hT2JqZWN0VHlwZVIEdHlwZRIsChJyb3dfY291bnRfZXN0aW1hdGUYAyAB'
    'KANSEHJvd0NvdW50RXN0aW1hdGU=');

@$core.Deprecated('Use columnDetailsDescriptor instead')
const ColumnDetails$json = {
  '1': 'ColumnDetails',
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
    {'1': 'nullable', '3': 4, '4': 1, '5': 8, '10': 'nullable'},
    {
      '1': 'default_value',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'defaultValue',
      '17': true
    },
    {'1': 'is_primary_key', '3': 6, '4': 1, '5': 8, '10': 'isPrimaryKey'},
    {
      '1': 'primary_key_order',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'primaryKeyOrder'
    },
  ],
  '8': [
    {'1': '_default_value'},
  ],
};

/// Descriptor for `ColumnDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnDetailsDescriptor = $convert.base64Decode(
    'Cg1Db2x1bW5EZXRhaWxzEhIKBG5hbWUYASABKAlSBG5hbWUSGwoJdHlwZV9uYW1lGAIgASgJUg'
    'h0eXBlTmFtZRIqCgRraW5kGAMgASgOMhYucXVlcmF2dWUudjEuVmFsdWVLaW5kUgRraW5kEhoK'
    'CG51bGxhYmxlGAQgASgIUghudWxsYWJsZRIoCg1kZWZhdWx0X3ZhbHVlGAUgASgJSABSDGRlZm'
    'F1bHRWYWx1ZYgBARIkCg5pc19wcmltYXJ5X2tleRgGIAEoCFIMaXNQcmltYXJ5S2V5EioKEXBy'
    'aW1hcnlfa2V5X29yZGVyGAcgASgNUg9wcmltYXJ5S2V5T3JkZXJCEAoOX2RlZmF1bHRfdmFsdW'
    'U=');

@$core.Deprecated('Use indexDetailsDescriptor instead')
const IndexDetails$json = {
  '1': 'IndexDetails',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'columns', '3': 2, '4': 3, '5': 9, '10': 'columns'},
    {'1': 'is_unique', '3': 3, '4': 1, '5': 8, '10': 'isUnique'},
    {'1': 'is_primary', '3': 4, '4': 1, '5': 8, '10': 'isPrimary'},
  ],
};

/// Descriptor for `IndexDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexDetailsDescriptor = $convert.base64Decode(
    'CgxJbmRleERldGFpbHMSEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgdjb2x1bW5zGAIgAygJUgdjb2'
    'x1bW5zEhsKCWlzX3VuaXF1ZRgDIAEoCFIIaXNVbmlxdWUSHQoKaXNfcHJpbWFyeRgEIAEoCFIJ'
    'aXNQcmltYXJ5');

@$core.Deprecated('Use foreignKeyDetailsDescriptor instead')
const ForeignKeyDetails$json = {
  '1': 'ForeignKeyDetails',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'columns', '3': 2, '4': 3, '5': 9, '10': 'columns'},
    {
      '1': 'referenced_schema',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'referencedSchema'
    },
    {'1': 'referenced_table', '3': 4, '4': 1, '5': 9, '10': 'referencedTable'},
    {
      '1': 'referenced_columns',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'referencedColumns'
    },
  ],
};

/// Descriptor for `ForeignKeyDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List foreignKeyDetailsDescriptor = $convert.base64Decode(
    'ChFGb3JlaWduS2V5RGV0YWlscxISCgRuYW1lGAEgASgJUgRuYW1lEhgKB2NvbHVtbnMYAiADKA'
    'lSB2NvbHVtbnMSKwoRcmVmZXJlbmNlZF9zY2hlbWEYAyABKAlSEHJlZmVyZW5jZWRTY2hlbWES'
    'KQoQcmVmZXJlbmNlZF90YWJsZRgEIAEoCVIPcmVmZXJlbmNlZFRhYmxlEi0KEnJlZmVyZW5jZW'
    'RfY29sdW1ucxgFIAMoCVIRcmVmZXJlbmNlZENvbHVtbnM=');

@$core.Deprecated('Use listDatabasesRequestDescriptor instead')
const ListDatabasesRequest$json = {
  '1': 'ListDatabasesRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'refresh', '3': 2, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `ListDatabasesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDatabasesRequestDescriptor = $convert.base64Decode(
    'ChRMaXN0RGF0YWJhc2VzUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSGA'
    'oHcmVmcmVzaBgCIAEoCFIHcmVmcmVzaA==');

@$core.Deprecated('Use listDatabasesResponseDescriptor instead')
const ListDatabasesResponse$json = {
  '1': 'ListDatabasesResponse',
  '2': [
    {'1': 'databases', '3': 1, '4': 3, '5': 9, '10': 'databases'},
  ],
};

/// Descriptor for `ListDatabasesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDatabasesResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0RGF0YWJhc2VzUmVzcG9uc2USHAoJZGF0YWJhc2VzGAEgAygJUglkYXRhYmFzZXM=');

@$core.Deprecated('Use listSchemasRequestDescriptor instead')
const ListSchemasRequest$json = {
  '1': 'ListSchemasRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'refresh', '3': 3, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `ListSchemasRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemasRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0U2NoZW1hc1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCG'
    'RhdGFiYXNlGAIgASgJUghkYXRhYmFzZRIYCgdyZWZyZXNoGAMgASgIUgdyZWZyZXNo');

@$core.Deprecated('Use listSchemasResponseDescriptor instead')
const ListSchemasResponse$json = {
  '1': 'ListSchemasResponse',
  '2': [
    {'1': 'schemas', '3': 1, '4': 3, '5': 9, '10': 'schemas'},
  ],
};

/// Descriptor for `ListSchemasResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemasResponseDescriptor =
    $convert.base64Decode(
        'ChNMaXN0U2NoZW1hc1Jlc3BvbnNlEhgKB3NjaGVtYXMYASADKAlSB3NjaGVtYXM=');

@$core.Deprecated('Use listObjectsRequestDescriptor instead')
const ListObjectsRequest$json = {
  '1': 'ListObjectsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'refresh', '3': 4, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `ListObjectsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listObjectsRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0T2JqZWN0c1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCG'
    'RhdGFiYXNlGAIgASgJUghkYXRhYmFzZRIWCgZzY2hlbWEYAyABKAlSBnNjaGVtYRIYCgdyZWZy'
    'ZXNoGAQgASgIUgdyZWZyZXNo');

@$core.Deprecated('Use listObjectsResponseDescriptor instead')
const ListObjectsResponse$json = {
  '1': 'ListObjectsResponse',
  '2': [
    {
      '1': 'objects',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SchemaObject',
      '10': 'objects'
    },
  ],
};

/// Descriptor for `ListObjectsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listObjectsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0T2JqZWN0c1Jlc3BvbnNlEjMKB29iamVjdHMYASADKAsyGS5xdWVyYXZ1ZS52MS5TY2'
    'hlbWFPYmplY3RSB29iamVjdHM=');

@$core.Deprecated('Use getTableDetailsRequestDescriptor instead')
const GetTableDetailsRequest$json = {
  '1': 'GetTableDetailsRequest',
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
    {'1': 'refresh', '3': 3, '4': 1, '5': 8, '10': 'refresh'},
  ],
};

/// Descriptor for `GetTableDetailsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTableDetailsRequestDescriptor = $convert.base64Decode(
    'ChZHZXRUYWJsZURldGFpbHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IyCgl0YWJsZV9yZWYYAiABKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZlIIdGFibGVSZWYSGAoH'
    'cmVmcmVzaBgDIAEoCFIHcmVmcmVzaA==');

@$core.Deprecated('Use getTableDetailsResponseDescriptor instead')
const GetTableDetailsResponse$json = {
  '1': 'GetTableDetailsResponse',
  '2': [
    {
      '1': 'table_ref',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'tableRef'
    },
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SchemaObjectType',
      '10': 'type'
    },
    {
      '1': 'columns',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnDetails',
      '10': 'columns'
    },
    {
      '1': 'indexes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.IndexDetails',
      '10': 'indexes'
    },
    {
      '1': 'foreign_keys',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ForeignKeyDetails',
      '10': 'foreignKeys'
    },
    {
      '1': 'row_count_estimate',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'rowCountEstimate'
    },
    {'1': 'can_edit', '3': 7, '4': 1, '5': 8, '10': 'canEdit'},
    {
      '1': 'edit_disabled_reason',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'editDisabledReason'
    },
  ],
};

/// Descriptor for `GetTableDetailsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTableDetailsResponseDescriptor = $convert.base64Decode(
    'ChdHZXRUYWJsZURldGFpbHNSZXNwb25zZRIyCgl0YWJsZV9yZWYYASABKAsyFS5xdWVyYXZ1ZS'
    '52MS5UYWJsZVJlZlIIdGFibGVSZWYSMQoEdHlwZRgCIAEoDjIdLnF1ZXJhdnVlLnYxLlNjaGVt'
    'YU9iamVjdFR5cGVSBHR5cGUSNAoHY29sdW1ucxgDIAMoCzIaLnF1ZXJhdnVlLnYxLkNvbHVtbk'
    'RldGFpbHNSB2NvbHVtbnMSMwoHaW5kZXhlcxgEIAMoCzIZLnF1ZXJhdnVlLnYxLkluZGV4RGV0'
    'YWlsc1IHaW5kZXhlcxJBCgxmb3JlaWduX2tleXMYBSADKAsyHi5xdWVyYXZ1ZS52MS5Gb3JlaW'
    'duS2V5RGV0YWlsc1ILZm9yZWlnbktleXMSLAoScm93X2NvdW50X2VzdGltYXRlGAYgASgDUhBy'
    'b3dDb3VudEVzdGltYXRlEhkKCGNhbl9lZGl0GAcgASgIUgdjYW5FZGl0EjAKFGVkaXRfZGlzYW'
    'JsZWRfcmVhc29uGAggASgJUhJlZGl0RGlzYWJsZWRSZWFzb24=');

@$core.Deprecated('Use refreshSchemaRequestDescriptor instead')
const RefreshSchemaRequest$json = {
  '1': 'RefreshSchemaRequest',
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

/// Descriptor for `RefreshSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSchemaRequestDescriptor = $convert.base64Decode(
    'ChRSZWZyZXNoU2NoZW1hUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSMg'
    'oJdGFibGVfcmVmGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSCHRhYmxlUmVm');

@$core.Deprecated('Use refreshSchemaResponseDescriptor instead')
const RefreshSchemaResponse$json = {
  '1': 'RefreshSchemaResponse',
};

/// Descriptor for `RefreshSchemaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSchemaResponseDescriptor =
    $convert.base64Decode('ChVSZWZyZXNoU2NoZW1hUmVzcG9uc2U=');
