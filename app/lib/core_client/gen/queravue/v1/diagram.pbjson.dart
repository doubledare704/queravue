// This is a generated file - do not edit.
//
// Generated from queravue/v1/diagram.proto.

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

@$core.Deprecated('Use getSchemaGraphRequestDescriptor instead')
const GetSchemaGraphRequest$json = {
  '1': 'GetSchemaGraphRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'refresh', '3': 4, '4': 1, '5': 8, '10': 'refresh'},
    {'1': 'sample_size', '3': 5, '4': 1, '5': 13, '10': 'sampleSize'},
  ],
};

/// Descriptor for `GetSchemaGraphRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSchemaGraphRequestDescriptor = $convert.base64Decode(
    'ChVHZXRTY2hlbWFHcmFwaFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh'
    'oKCGRhdGFiYXNlGAIgASgJUghkYXRhYmFzZRIWCgZzY2hlbWEYAyABKAlSBnNjaGVtYRIYCgdy'
    'ZWZyZXNoGAQgASgIUgdyZWZyZXNoEh8KC3NhbXBsZV9zaXplGAUgASgNUgpzYW1wbGVTaXpl');

@$core.Deprecated('Use graphColumnDescriptor instead')
const GraphColumn$json = {
  '1': 'GraphColumn',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type_name', '3': 2, '4': 1, '5': 9, '10': 'typeName'},
    {'1': 'nullable', '3': 3, '4': 1, '5': 8, '10': 'nullable'},
    {
      '1': 'primary_key_order',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'primaryKeyOrder'
    },
  ],
};

/// Descriptor for `GraphColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphColumnDescriptor = $convert.base64Decode(
    'CgtHcmFwaENvbHVtbhISCgRuYW1lGAEgASgJUgRuYW1lEhsKCXR5cGVfbmFtZRgCIAEoCVIIdH'
    'lwZU5hbWUSGgoIbnVsbGFibGUYAyABKAhSCG51bGxhYmxlEioKEXByaW1hcnlfa2V5X29yZGVy'
    'GAQgASgNUg9wcmltYXJ5S2V5T3JkZXI=');

@$core.Deprecated('Use graphRelationDescriptor instead')
const GraphRelation$json = {
  '1': 'GraphRelation',
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
    {
      '1': 'on_delete',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ReferentialAction',
      '10': 'onDelete'
    },
    {
      '1': 'on_update',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ReferentialAction',
      '10': 'onUpdate'
    },
    {'1': 'inferred', '3': 8, '4': 1, '5': 8, '10': 'inferred'},
    {'1': 'confidence', '3': 9, '4': 1, '5': 1, '10': 'confidence'},
  ],
};

/// Descriptor for `GraphRelation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphRelationDescriptor = $convert.base64Decode(
    'Cg1HcmFwaFJlbGF0aW9uEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHY29sdW1ucxgCIAMoCVIHY2'
    '9sdW1ucxIrChFyZWZlcmVuY2VkX3NjaGVtYRgDIAEoCVIQcmVmZXJlbmNlZFNjaGVtYRIpChBy'
    'ZWZlcmVuY2VkX3RhYmxlGAQgASgJUg9yZWZlcmVuY2VkVGFibGUSLQoScmVmZXJlbmNlZF9jb2'
    'x1bW5zGAUgAygJUhFyZWZlcmVuY2VkQ29sdW1ucxI7Cglvbl9kZWxldGUYBiABKA4yHi5xdWVy'
    'YXZ1ZS52MS5SZWZlcmVudGlhbEFjdGlvblIIb25EZWxldGUSOwoJb25fdXBkYXRlGAcgASgOMh'
    '4ucXVlcmF2dWUudjEuUmVmZXJlbnRpYWxBY3Rpb25SCG9uVXBkYXRlEhoKCGluZmVycmVkGAgg'
    'ASgIUghpbmZlcnJlZBIeCgpjb25maWRlbmNlGAkgASgBUgpjb25maWRlbmNl');

@$core.Deprecated('Use graphTableDescriptor instead')
const GraphTable$json = {
  '1': 'GraphTable',
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
    {
      '1': 'columns',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.GraphColumn',
      '10': 'columns'
    },
    {
      '1': 'relations',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.GraphRelation',
      '10': 'relations'
    },
    {
      '1': 'columns_truncated',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'columnsTruncated'
    },
  ],
};

/// Descriptor for `GraphTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphTableDescriptor = $convert.base64Decode(
    'CgpHcmFwaFRhYmxlEhIKBG5hbWUYASABKAlSBG5hbWUSMQoEdHlwZRgCIAEoDjIdLnF1ZXJhdn'
    'VlLnYxLlNjaGVtYU9iamVjdFR5cGVSBHR5cGUSLAoScm93X2NvdW50X2VzdGltYXRlGAMgASgD'
    'UhByb3dDb3VudEVzdGltYXRlEjIKB2NvbHVtbnMYBCADKAsyGC5xdWVyYXZ1ZS52MS5HcmFwaE'
    'NvbHVtblIHY29sdW1ucxI4CglyZWxhdGlvbnMYBSADKAsyGi5xdWVyYXZ1ZS52MS5HcmFwaFJl'
    'bGF0aW9uUglyZWxhdGlvbnMSKwoRY29sdW1uc190cnVuY2F0ZWQYBiABKAhSEGNvbHVtbnNUcn'
    'VuY2F0ZWQ=');

@$core.Deprecated('Use getSchemaGraphResponseDescriptor instead')
const GetSchemaGraphResponse$json = {
  '1': 'GetSchemaGraphResponse',
  '2': [
    {
      '1': 'tables',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.GraphTable',
      '10': 'tables'
    },
    {'1': 'tables_total', '3': 2, '4': 1, '5': 13, '10': 'tablesTotal'},
    {'1': 'tables_done', '3': 3, '4': 1, '5': 13, '10': 'tablesDone'},
    {'1': 'done', '3': 4, '4': 1, '5': 8, '10': 'done'},
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `GetSchemaGraphResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSchemaGraphResponseDescriptor = $convert.base64Decode(
    'ChZHZXRTY2hlbWFHcmFwaFJlc3BvbnNlEi8KBnRhYmxlcxgBIAMoCzIXLnF1ZXJhdnVlLnYxLk'
    'dyYXBoVGFibGVSBnRhYmxlcxIhCgx0YWJsZXNfdG90YWwYAiABKA1SC3RhYmxlc1RvdGFsEh8K'
    'C3RhYmxlc19kb25lGAMgASgNUgp0YWJsZXNEb25lEhIKBGRvbmUYBCABKAhSBGRvbmUSLQoFZX'
    'Jyb3IYBSABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use tableChangesDescriptor instead')
const TableChanges$json = {
  '1': 'TableChanges',
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
      '1': 'changes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SchemaChange',
      '10': 'changes'
    },
  ],
};

/// Descriptor for `TableChanges`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableChangesDescriptor = $convert.base64Decode(
    'CgxUYWJsZUNoYW5nZXMSMgoJdGFibGVfcmVmGAEgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZW'
    'ZSCHRhYmxlUmVmEjMKB2NoYW5nZXMYAiADKAsyGS5xdWVyYXZ1ZS52MS5TY2hlbWFDaGFuZ2VS'
    'B2NoYW5nZXM=');

@$core.Deprecated('Use previewDiagramDDLRequestDescriptor instead')
const PreviewDiagramDDLRequest$json = {
  '1': 'PreviewDiagramDDLRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'tables',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TableChanges',
      '10': 'tables'
    },
  ],
};

/// Descriptor for `PreviewDiagramDDLRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewDiagramDDLRequestDescriptor =
    $convert.base64Decode(
        'ChhQcmV2aWV3RGlhZ3JhbURETFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbk'
        'lkEjEKBnRhYmxlcxgCIAMoCzIZLnF1ZXJhdnVlLnYxLlRhYmxlQ2hhbmdlc1IGdGFibGVz');

@$core.Deprecated('Use previewDiagramDDLResponseDescriptor instead')
const PreviewDiagramDDLResponse$json = {
  '1': 'PreviewDiagramDDLResponse',
  '2': [
    {
      '1': 'statements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.DdlStatement',
      '10': 'statements'
    },
    {'1': 'warnings', '3': 2, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'transactional', '3': 3, '4': 1, '5': 8, '10': 'transactional'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `PreviewDiagramDDLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewDiagramDDLResponseDescriptor = $convert.base64Decode(
    'ChlQcmV2aWV3RGlhZ3JhbURETFJlc3BvbnNlEjkKCnN0YXRlbWVudHMYASADKAsyGS5xdWVyYX'
    'Z1ZS52MS5EZGxTdGF0ZW1lbnRSCnN0YXRlbWVudHMSGgoId2FybmluZ3MYAiADKAlSCHdhcm5p'
    'bmdzEiQKDXRyYW5zYWN0aW9uYWwYAyABKAhSDXRyYW5zYWN0aW9uYWwSLQoFZXJyb3IYBCABKA'
    'syFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use applyDiagramDDLRequestDescriptor instead')
const ApplyDiagramDDLRequest$json = {
  '1': 'ApplyDiagramDDLRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'tables',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TableChanges',
      '10': 'tables'
    },
    {'1': 'confirmed', '3': 3, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `ApplyDiagramDDLRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyDiagramDDLRequestDescriptor = $convert.base64Decode(
    'ChZBcHBseURpYWdyYW1ERExSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'IxCgZ0YWJsZXMYAiADKAsyGS5xdWVyYXZ1ZS52MS5UYWJsZUNoYW5nZXNSBnRhYmxlcxIcCglj'
    'b25maXJtZWQYAyABKAhSCWNvbmZpcm1lZA==');

@$core.Deprecated('Use applyDiagramDDLResponseDescriptor instead')
const ApplyDiagramDDLResponse$json = {
  '1': 'ApplyDiagramDDLResponse',
  '2': [
    {
      '1': 'statements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.DdlStatement',
      '10': 'statements'
    },
    {
      '1': 'executed_statements',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'executedStatements'
    },
    {'1': 'transactional', '3': 3, '4': 1, '5': 8, '10': 'transactional'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ApplyDiagramDDLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyDiagramDDLResponseDescriptor = $convert.base64Decode(
    'ChdBcHBseURpYWdyYW1ERExSZXNwb25zZRI5CgpzdGF0ZW1lbnRzGAEgAygLMhkucXVlcmF2dW'
    'UudjEuRGRsU3RhdGVtZW50UgpzdGF0ZW1lbnRzEi8KE2V4ZWN1dGVkX3N0YXRlbWVudHMYAiAB'
    'KA1SEmV4ZWN1dGVkU3RhdGVtZW50cxIkCg10cmFuc2FjdGlvbmFsGAMgASgIUg10cmFuc2FjdG'
    'lvbmFsEi0KBWVycm9yGAQgASgLMhcucXVlcmF2dWUudjEuQWRtaW5FcnJvclIFZXJyb3I=');
