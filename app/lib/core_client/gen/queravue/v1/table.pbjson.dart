// This is a generated file - do not edit.
//
// Generated from queravue/v1/table.proto.

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

@$core.Deprecated('Use filterOpDescriptor instead')
const FilterOp$json = {
  '1': 'FilterOp',
  '2': [
    {'1': 'FILTER_OP_UNSPECIFIED', '2': 0},
    {'1': 'FILTER_OP_EQUALS', '2': 1},
    {'1': 'FILTER_OP_NOT_EQUALS', '2': 2},
    {'1': 'FILTER_OP_LESS_THAN', '2': 3},
    {'1': 'FILTER_OP_LESS_THAN_OR_EQUAL', '2': 4},
    {'1': 'FILTER_OP_GREATER_THAN', '2': 5},
    {'1': 'FILTER_OP_GREATER_THAN_OR_EQUAL', '2': 6},
    {'1': 'FILTER_OP_LIKE', '2': 7},
    {'1': 'FILTER_OP_ILIKE', '2': 8},
    {'1': 'FILTER_OP_IN', '2': 9},
    {'1': 'FILTER_OP_IS_NULL', '2': 10},
    {'1': 'FILTER_OP_IS_NOT_NULL', '2': 11},
    {'1': 'FILTER_OP_BETWEEN', '2': 12},
  ],
};

/// Descriptor for `FilterOp`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List filterOpDescriptor = $convert.base64Decode(
    'CghGaWx0ZXJPcBIZChVGSUxURVJfT1BfVU5TUEVDSUZJRUQQABIUChBGSUxURVJfT1BfRVFVQU'
    'xTEAESGAoURklMVEVSX09QX05PVF9FUVVBTFMQAhIXChNGSUxURVJfT1BfTEVTU19USEFOEAMS'
    'IAocRklMVEVSX09QX0xFU1NfVEhBTl9PUl9FUVVBTBAEEhoKFkZJTFRFUl9PUF9HUkVBVEVSX1'
    'RIQU4QBRIjCh9GSUxURVJfT1BfR1JFQVRFUl9USEFOX09SX0VRVUFMEAYSEgoORklMVEVSX09Q'
    'X0xJS0UQBxITCg9GSUxURVJfT1BfSUxJS0UQCBIQCgxGSUxURVJfT1BfSU4QCRIVChFGSUxURV'
    'JfT1BfSVNfTlVMTBAKEhkKFUZJTFRFUl9PUF9JU19OT1RfTlVMTBALEhUKEUZJTFRFUl9PUF9C'
    'RVRXRUVOEAw=');

@$core.Deprecated('Use logicalOpDescriptor instead')
const LogicalOp$json = {
  '1': 'LogicalOp',
  '2': [
    {'1': 'LOGICAL_OP_UNSPECIFIED', '2': 0},
    {'1': 'LOGICAL_OP_AND', '2': 1},
    {'1': 'LOGICAL_OP_OR', '2': 2},
  ],
};

/// Descriptor for `LogicalOp`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logicalOpDescriptor = $convert.base64Decode(
    'CglMb2dpY2FsT3ASGgoWTE9HSUNBTF9PUF9VTlNQRUNJRklFRBAAEhIKDkxPR0lDQUxfT1BfQU'
    '5EEAESEQoNTE9HSUNBTF9PUF9PUhAC');

@$core.Deprecated('Use sortDirectionDescriptor instead')
const SortDirection$json = {
  '1': 'SortDirection',
  '2': [
    {'1': 'SORT_DIRECTION_UNSPECIFIED', '2': 0},
    {'1': 'SORT_DIRECTION_ASC', '2': 1},
    {'1': 'SORT_DIRECTION_DESC', '2': 2},
  ],
};

/// Descriptor for `SortDirection`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sortDirectionDescriptor = $convert.base64Decode(
    'Cg1Tb3J0RGlyZWN0aW9uEh4KGlNPUlRfRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASFgoSU09SVF'
    '9ESVJFQ1RJT05fQVNDEAESFwoTU09SVF9ESVJFQ1RJT05fREVTQxAC');

@$core.Deprecated('Use nullsOrderDescriptor instead')
const NullsOrder$json = {
  '1': 'NullsOrder',
  '2': [
    {'1': 'NULLS_ORDER_UNSPECIFIED', '2': 0},
    {'1': 'NULLS_ORDER_FIRST', '2': 1},
    {'1': 'NULLS_ORDER_LAST', '2': 2},
  ],
};

/// Descriptor for `NullsOrder`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nullsOrderDescriptor = $convert.base64Decode(
    'CgpOdWxsc09yZGVyEhsKF05VTExTX09SREVSX1VOU1BFQ0lGSUVEEAASFQoRTlVMTFNfT1JERV'
    'JfRklSU1QQARIUChBOVUxMU19PUkRFUl9MQVNUEAI=');

@$core.Deprecated('Use rowChangeTypeDescriptor instead')
const RowChangeType$json = {
  '1': 'RowChangeType',
  '2': [
    {'1': 'ROW_CHANGE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'ROW_CHANGE_TYPE_INSERT', '2': 1},
    {'1': 'ROW_CHANGE_TYPE_UPDATE', '2': 2},
    {'1': 'ROW_CHANGE_TYPE_DELETE', '2': 3},
  ],
};

/// Descriptor for `RowChangeType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List rowChangeTypeDescriptor = $convert.base64Decode(
    'Cg1Sb3dDaGFuZ2VUeXBlEh8KG1JPV19DSEFOR0VfVFlQRV9VTlNQRUNJRklFRBAAEhoKFlJPV1'
    '9DSEFOR0VfVFlQRV9JTlNFUlQQARIaChZST1dfQ0hBTkdFX1RZUEVfVVBEQVRFEAISGgoWUk9X'
    'X0NIQU5HRV9UWVBFX0RFTEVURRAD');

@$core.Deprecated('Use filterConditionDescriptor instead')
const FilterCondition$json = {
  '1': 'FilterCondition',
  '2': [
    {'1': 'column', '3': 1, '4': 1, '5': 9, '10': 'column'},
    {
      '1': 'op',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.FilterOp',
      '10': 'op'
    },
    {
      '1': 'values',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'values'
    },
  ],
};

/// Descriptor for `FilterCondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterConditionDescriptor = $convert.base64Decode(
    'Cg9GaWx0ZXJDb25kaXRpb24SFgoGY29sdW1uGAEgASgJUgZjb2x1bW4SJQoCb3AYAiABKA4yFS'
    '5xdWVyYXZ1ZS52MS5GaWx0ZXJPcFICb3ASKgoGdmFsdWVzGAMgAygLMhIucXVlcmF2dWUudjEu'
    'VmFsdWVSBnZhbHVlcw==');

@$core.Deprecated('Use filterGroupDescriptor instead')
const FilterGroup$json = {
  '1': 'FilterGroup',
  '2': [
    {
      '1': 'op',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.LogicalOp',
      '10': 'op'
    },
    {
      '1': 'conditions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.FilterCondition',
      '10': 'conditions'
    },
    {
      '1': 'groups',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.FilterGroup',
      '10': 'groups'
    },
  ],
};

/// Descriptor for `FilterGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterGroupDescriptor = $convert.base64Decode(
    'CgtGaWx0ZXJHcm91cBImCgJvcBgBIAEoDjIWLnF1ZXJhdnVlLnYxLkxvZ2ljYWxPcFICb3ASPA'
    'oKY29uZGl0aW9ucxgCIAMoCzIcLnF1ZXJhdnVlLnYxLkZpbHRlckNvbmRpdGlvblIKY29uZGl0'
    'aW9ucxIwCgZncm91cHMYAyADKAsyGC5xdWVyYXZ1ZS52MS5GaWx0ZXJHcm91cFIGZ3JvdXBz');

@$core.Deprecated('Use tableFilterDescriptor instead')
const TableFilter$json = {
  '1': 'TableFilter',
  '2': [
    {
      '1': 'root',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FilterGroup',
      '10': 'root'
    },
    {'1': 'raw_where', '3': 2, '4': 1, '5': 9, '10': 'rawWhere'},
  ],
};

/// Descriptor for `TableFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableFilterDescriptor = $convert.base64Decode(
    'CgtUYWJsZUZpbHRlchIsCgRyb290GAEgASgLMhgucXVlcmF2dWUudjEuRmlsdGVyR3JvdXBSBH'
    'Jvb3QSGwoJcmF3X3doZXJlGAIgASgJUghyYXdXaGVyZQ==');

@$core.Deprecated('Use sortClauseDescriptor instead')
const SortClause$json = {
  '1': 'SortClause',
  '2': [
    {'1': 'column', '3': 1, '4': 1, '5': 9, '10': 'column'},
    {
      '1': 'direction',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SortDirection',
      '10': 'direction'
    },
    {
      '1': 'nulls',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.NullsOrder',
      '10': 'nulls'
    },
  ],
};

/// Descriptor for `SortClause`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sortClauseDescriptor = $convert.base64Decode(
    'CgpTb3J0Q2xhdXNlEhYKBmNvbHVtbhgBIAEoCVIGY29sdW1uEjgKCWRpcmVjdGlvbhgCIAEoDj'
    'IaLnF1ZXJhdnVlLnYxLlNvcnREaXJlY3Rpb25SCWRpcmVjdGlvbhItCgVudWxscxgDIAEoDjIX'
    'LnF1ZXJhdnVlLnYxLk51bGxzT3JkZXJSBW51bGxz');

@$core.Deprecated('Use openTableRequestDescriptor instead')
const OpenTableRequest$json = {
  '1': 'OpenTableRequest',
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
    {'1': 'page_size', '3': 5, '4': 1, '5': 4, '10': 'pageSize'},
  ],
};

/// Descriptor for `OpenTableRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openTableRequestDescriptor = $convert.base64Decode(
    'ChBPcGVuVGFibGVSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIyCgl0YW'
    'JsZV9yZWYYAiABKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZlIIdGFibGVSZWYSMAoGZmlsdGVy'
    'GAMgASgLMhgucXVlcmF2dWUudjEuVGFibGVGaWx0ZXJSBmZpbHRlchIrCgRzb3J0GAQgAygLMh'
    'cucXVlcmF2dWUudjEuU29ydENsYXVzZVIEc29ydBIbCglwYWdlX3NpemUYBSABKARSCHBhZ2VT'
    'aXpl');

@$core.Deprecated('Use openTableResponseDescriptor instead')
const OpenTableResponse$json = {
  '1': 'OpenTableResponse',
  '2': [
    {'1': 'sql', '3': 1, '4': 1, '5': 9, '10': 'sql'},
    {
      '1': 'event',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ExecuteResponse',
      '10': 'event'
    },
  ],
};

/// Descriptor for `OpenTableResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openTableResponseDescriptor = $convert.base64Decode(
    'ChFPcGVuVGFibGVSZXNwb25zZRIQCgNzcWwYASABKAlSA3NxbBIyCgVldmVudBgCIAEoCzIcLn'
    'F1ZXJhdnVlLnYxLkV4ZWN1dGVSZXNwb25zZVIFZXZlbnQ=');

@$core.Deprecated('Use columnValueDescriptor instead')
const ColumnValue$json = {
  '1': 'ColumnValue',
  '2': [
    {'1': 'column', '3': 1, '4': 1, '5': 9, '10': 'column'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'value'
    },
  ],
};

/// Descriptor for `ColumnValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnValueDescriptor = $convert.base64Decode(
    'CgtDb2x1bW5WYWx1ZRIWCgZjb2x1bW4YASABKAlSBmNvbHVtbhIoCgV2YWx1ZRgCIAEoCzISLn'
    'F1ZXJhdnVlLnYxLlZhbHVlUgV2YWx1ZQ==');

@$core.Deprecated('Use rowChangeDescriptor instead')
const RowChange$json = {
  '1': 'RowChange',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.RowChangeType',
      '10': 'type'
    },
    {
      '1': 'keys',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnValue',
      '10': 'keys'
    },
    {
      '1': 'values',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnValue',
      '10': 'values'
    },
  ],
};

/// Descriptor for `RowChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowChangeDescriptor = $convert.base64Decode(
    'CglSb3dDaGFuZ2USLgoEdHlwZRgBIAEoDjIaLnF1ZXJhdnVlLnYxLlJvd0NoYW5nZVR5cGVSBH'
    'R5cGUSLAoEa2V5cxgCIAMoCzIYLnF1ZXJhdnVlLnYxLkNvbHVtblZhbHVlUgRrZXlzEjAKBnZh'
    'bHVlcxgDIAMoCzIYLnF1ZXJhdnVlLnYxLkNvbHVtblZhbHVlUgZ2YWx1ZXM=');

@$core.Deprecated('Use applyChangesRequestDescriptor instead')
const ApplyChangesRequest$json = {
  '1': 'ApplyChangesRequest',
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
    {
      '1': 'changes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.RowChange',
      '10': 'changes'
    },
    {'1': 'dry_run', '3': 4, '4': 1, '5': 8, '10': 'dryRun'},
    {
      '1': 'confirm_production',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'confirmProduction'
    },
  ],
};

/// Descriptor for `ApplyChangesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyChangesRequestDescriptor = $convert.base64Decode(
    'ChNBcHBseUNoYW5nZXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIyCg'
    'l0YWJsZV9yZWYYAiABKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZlIIdGFibGVSZWYSMAoHY2hh'
    'bmdlcxgDIAMoCzIWLnF1ZXJhdnVlLnYxLlJvd0NoYW5nZVIHY2hhbmdlcxIXCgdkcnlfcnVuGA'
    'QgASgIUgZkcnlSdW4SLQoSY29uZmlybV9wcm9kdWN0aW9uGAUgASgIUhFjb25maXJtUHJvZHVj'
    'dGlvbg==');

@$core.Deprecated('Use applyChangesResponseDescriptor instead')
const ApplyChangesResponse$json = {
  '1': 'ApplyChangesResponse',
  '2': [
    {'1': 'generated_sql', '3': 1, '4': 1, '5': 9, '10': 'generatedSql'},
    {'1': 'rows_affected', '3': 2, '4': 1, '5': 4, '10': 'rowsAffected'},
    {'1': 'dry_run', '3': 3, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'success', '3': 4, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error_message', '3': 5, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `ApplyChangesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyChangesResponseDescriptor = $convert.base64Decode(
    'ChRBcHBseUNoYW5nZXNSZXNwb25zZRIjCg1nZW5lcmF0ZWRfc3FsGAEgASgJUgxnZW5lcmF0ZW'
    'RTcWwSIwoNcm93c19hZmZlY3RlZBgCIAEoBFIMcm93c0FmZmVjdGVkEhcKB2RyeV9ydW4YAyAB'
    'KAhSBmRyeVJ1bhIYCgdzdWNjZXNzGAQgASgIUgdzdWNjZXNzEiMKDWVycm9yX21lc3NhZ2UYBS'
    'ABKAlSDGVycm9yTWVzc2FnZQ==');
