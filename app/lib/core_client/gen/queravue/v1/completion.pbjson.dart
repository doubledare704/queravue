// This is a generated file - do not edit.
//
// Generated from queravue/v1/completion.proto.

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

@$core.Deprecated('Use completionContextKindDescriptor instead')
const CompletionContextKind$json = {
  '1': 'CompletionContextKind',
  '2': [
    {'1': 'COMPLETION_CONTEXT_KIND_UNSPECIFIED', '2': 0},
    {'1': 'COMPLETION_CONTEXT_KIND_SQL', '2': 1},
    {'1': 'COMPLETION_CONTEXT_KIND_SHELL', '2': 2},
    {'1': 'COMPLETION_CONTEXT_KIND_MONGO_QUERY', '2': 3},
  ],
};

/// Descriptor for `CompletionContextKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List completionContextKindDescriptor = $convert.base64Decode(
    'ChVDb21wbGV0aW9uQ29udGV4dEtpbmQSJwojQ09NUExFVElPTl9DT05URVhUX0tJTkRfVU5TUE'
    'VDSUZJRUQQABIfChtDT01QTEVUSU9OX0NPTlRFWFRfS0lORF9TUUwQARIhCh1DT01QTEVUSU9O'
    'X0NPTlRFWFRfS0lORF9TSEVMTBACEicKI0NPTVBMRVRJT05fQ09OVEVYVF9LSU5EX01PTkdPX1'
    'FVRVJZEAM=');

@$core.Deprecated('Use completionItemKindDescriptor instead')
const CompletionItemKind$json = {
  '1': 'CompletionItemKind',
  '2': [
    {'1': 'COMPLETION_ITEM_KIND_UNSPECIFIED', '2': 0},
    {'1': 'COMPLETION_ITEM_KIND_KEYWORD', '2': 1},
    {'1': 'COMPLETION_ITEM_KIND_FUNCTION', '2': 2},
    {'1': 'COMPLETION_ITEM_KIND_TABLE', '2': 3},
    {'1': 'COMPLETION_ITEM_KIND_VIEW', '2': 4},
    {'1': 'COMPLETION_ITEM_KIND_COLUMN', '2': 5},
    {'1': 'COMPLETION_ITEM_KIND_SCHEMA', '2': 6},
    {'1': 'COMPLETION_ITEM_KIND_DATABASE', '2': 7},
    {'1': 'COMPLETION_ITEM_KIND_ALIAS', '2': 8},
    {'1': 'COMPLETION_ITEM_KIND_COLLECTION', '2': 9},
    {'1': 'COMPLETION_ITEM_KIND_FIELD', '2': 10},
    {'1': 'COMPLETION_ITEM_KIND_OPERATOR', '2': 11},
    {'1': 'COMPLETION_ITEM_KIND_METHOD', '2': 12},
  ],
};

/// Descriptor for `CompletionItemKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List completionItemKindDescriptor = $convert.base64Decode(
    'ChJDb21wbGV0aW9uSXRlbUtpbmQSJAogQ09NUExFVElPTl9JVEVNX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIgChxDT01QTEVUSU9OX0lURU1fS0lORF9LRVlXT1JEEAESIQodQ09NUExFVElPTl9JVEVN'
    'X0tJTkRfRlVOQ1RJT04QAhIeChpDT01QTEVUSU9OX0lURU1fS0lORF9UQUJMRRADEh0KGUNPTV'
    'BMRVRJT05fSVRFTV9LSU5EX1ZJRVcQBBIfChtDT01QTEVUSU9OX0lURU1fS0lORF9DT0xVTU4Q'
    'BRIfChtDT01QTEVUSU9OX0lURU1fS0lORF9TQ0hFTUEQBhIhCh1DT01QTEVUSU9OX0lURU1fS0'
    'lORF9EQVRBQkFTRRAHEh4KGkNPTVBMRVRJT05fSVRFTV9LSU5EX0FMSUFTEAgSIwofQ09NUExF'
    'VElPTl9JVEVNX0tJTkRfQ09MTEVDVElPThAJEh4KGkNPTVBMRVRJT05fSVRFTV9LSU5EX0ZJRU'
    'xEEAoSIQodQ09NUExFVElPTl9JVEVNX0tJTkRfT1BFUkFUT1IQCxIfChtDT01QTEVUSU9OX0lU'
    'RU1fS0lORF9NRVRIT0QQDA==');

@$core.Deprecated('Use catalogStateDescriptor instead')
const CatalogState$json = {
  '1': 'CatalogState',
  '2': [
    {'1': 'CATALOG_STATE_UNSPECIFIED', '2': 0},
    {'1': 'CATALOG_STATE_COLD', '2': 1},
    {'1': 'CATALOG_STATE_WARMING', '2': 2},
    {'1': 'CATALOG_STATE_READY', '2': 3},
  ],
};

/// Descriptor for `CatalogState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List catalogStateDescriptor = $convert.base64Decode(
    'CgxDYXRhbG9nU3RhdGUSHQoZQ0FUQUxPR19TVEFURV9VTlNQRUNJRklFRBAAEhYKEkNBVEFMT0'
    'dfU1RBVEVfQ09MRBABEhkKFUNBVEFMT0dfU1RBVEVfV0FSTUlORxACEhcKE0NBVEFMT0dfU1RB'
    'VEVfUkVBRFkQAw==');

@$core.Deprecated('Use keywordCaseDescriptor instead')
const KeywordCase$json = {
  '1': 'KeywordCase',
  '2': [
    {'1': 'KEYWORD_CASE_UNSPECIFIED', '2': 0},
    {'1': 'KEYWORD_CASE_UPPER', '2': 1},
    {'1': 'KEYWORD_CASE_LOWER', '2': 2},
    {'1': 'KEYWORD_CASE_PRESERVE', '2': 3},
  ],
};

/// Descriptor for `KeywordCase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List keywordCaseDescriptor = $convert.base64Decode(
    'CgtLZXl3b3JkQ2FzZRIcChhLRVlXT1JEX0NBU0VfVU5TUEVDSUZJRUQQABIWChJLRVlXT1JEX0'
    'NBU0VfVVBQRVIQARIWChJLRVlXT1JEX0NBU0VfTE9XRVIQAhIZChVLRVlXT1JEX0NBU0VfUFJF'
    'U0VSVkUQAw==');

@$core.Deprecated('Use commaStyleDescriptor instead')
const CommaStyle$json = {
  '1': 'CommaStyle',
  '2': [
    {'1': 'COMMA_STYLE_UNSPECIFIED', '2': 0},
    {'1': 'COMMA_STYLE_TRAILING', '2': 1},
    {'1': 'COMMA_STYLE_LEADING', '2': 2},
  ],
};

/// Descriptor for `CommaStyle`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List commaStyleDescriptor = $convert.base64Decode(
    'CgpDb21tYVN0eWxlEhsKF0NPTU1BX1NUWUxFX1VOU1BFQ0lGSUVEEAASGAoUQ09NTUFfU1RZTE'
    'VfVFJBSUxJTkcQARIXChNDT01NQV9TVFlMRV9MRUFESU5HEAI=');

@$core.Deprecated('Use completeRequestDescriptor instead')
const CompleteRequest$json = {
  '1': 'CompleteRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CompletionContextKind',
      '10': 'kind'
    },
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'cursor_offset', '3': 4, '4': 1, '5': 13, '10': 'cursorOffset'},
    {'1': 'max_items', '3': 5, '4': 1, '5': 13, '10': 'maxItems'},
    {'1': 'database', '3': 6, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 7, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'collection', '3': 8, '4': 1, '5': 9, '10': 'collection'},
  ],
};

/// Descriptor for `CompleteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeRequestDescriptor = $convert.base64Decode(
    'Cg9Db21wbGV0ZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjYKBGtpbm'
    'QYAiABKA4yIi5xdWVyYXZ1ZS52MS5Db21wbGV0aW9uQ29udGV4dEtpbmRSBGtpbmQSEgoEdGV4'
    'dBgDIAEoCVIEdGV4dBIjCg1jdXJzb3Jfb2Zmc2V0GAQgASgNUgxjdXJzb3JPZmZzZXQSGwoJbW'
    'F4X2l0ZW1zGAUgASgNUghtYXhJdGVtcxIaCghkYXRhYmFzZRgGIAEoCVIIZGF0YWJhc2USFgoG'
    'c2NoZW1hGAcgASgJUgZzY2hlbWESHgoKY29sbGVjdGlvbhgIIAEoCVIKY29sbGVjdGlvbg==');

@$core.Deprecated('Use completionItemDescriptor instead')
const CompletionItem$json = {
  '1': 'CompletionItem',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CompletionItemKind',
      '10': 'kind'
    },
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'insert_text', '3': 4, '4': 1, '5': 9, '10': 'insertText'},
    {
      '1': 'replace',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TextRange',
      '10': 'replace'
    },
    {'1': 'sort_key', '3': 6, '4': 1, '5': 9, '10': 'sortKey'},
  ],
};

/// Descriptor for `CompletionItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completionItemDescriptor = $convert.base64Decode(
    'Cg5Db21wbGV0aW9uSXRlbRIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSMwoEa2luZBgCIAEoDjIfLn'
    'F1ZXJhdnVlLnYxLkNvbXBsZXRpb25JdGVtS2luZFIEa2luZBIWCgZkZXRhaWwYAyABKAlSBmRl'
    'dGFpbBIfCgtpbnNlcnRfdGV4dBgEIAEoCVIKaW5zZXJ0VGV4dBIwCgdyZXBsYWNlGAUgASgLMh'
    'YucXVlcmF2dWUudjEuVGV4dFJhbmdlUgdyZXBsYWNlEhkKCHNvcnRfa2V5GAYgASgJUgdzb3J0'
    'S2V5');

@$core.Deprecated('Use completeResponseDescriptor instead')
const CompleteResponse$json = {
  '1': 'CompleteResponse',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.CompletionItem',
      '10': 'items'
    },
    {'1': 'is_incomplete', '3': 2, '4': 1, '5': 8, '10': 'isIncomplete'},
    {
      '1': 'catalog_state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CatalogState',
      '10': 'catalogState'
    },
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

/// Descriptor for `CompleteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeResponseDescriptor = $convert.base64Decode(
    'ChBDb21wbGV0ZVJlc3BvbnNlEjEKBWl0ZW1zGAEgAygLMhsucXVlcmF2dWUudjEuQ29tcGxldG'
    'lvbkl0ZW1SBWl0ZW1zEiMKDWlzX2luY29tcGxldGUYAiABKAhSDGlzSW5jb21wbGV0ZRI+Cg1j'
    'YXRhbG9nX3N0YXRlGAMgASgOMhkucXVlcmF2dWUudjEuQ2F0YWxvZ1N0YXRlUgxjYXRhbG9nU3'
    'RhdGUSLQoFZXJyb3IYBCABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use warmCatalogRequestDescriptor instead')
const WarmCatalogRequest$json = {
  '1': 'WarmCatalogRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
  ],
};

/// Descriptor for `WarmCatalogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warmCatalogRequestDescriptor = $convert.base64Decode(
    'ChJXYXJtQ2F0YWxvZ1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCG'
    'RhdGFiYXNlGAIgASgJUghkYXRhYmFzZQ==');

@$core.Deprecated('Use warmCatalogResponseDescriptor instead')
const WarmCatalogResponse$json = {
  '1': 'WarmCatalogResponse',
  '2': [
    {'1': 'schemas_total', '3': 1, '4': 1, '5': 13, '10': 'schemasTotal'},
    {'1': 'schemas_done', '3': 2, '4': 1, '5': 13, '10': 'schemasDone'},
    {'1': 'tables_loaded', '3': 3, '4': 1, '5': 13, '10': 'tablesLoaded'},
    {'1': 'columns_loaded', '3': 4, '4': 1, '5': 13, '10': 'columnsLoaded'},
    {'1': 'done', '3': 5, '4': 1, '5': 8, '10': 'done'},
    {
      '1': 'error',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `WarmCatalogResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warmCatalogResponseDescriptor = $convert.base64Decode(
    'ChNXYXJtQ2F0YWxvZ1Jlc3BvbnNlEiMKDXNjaGVtYXNfdG90YWwYASABKA1SDHNjaGVtYXNUb3'
    'RhbBIhCgxzY2hlbWFzX2RvbmUYAiABKA1SC3NjaGVtYXNEb25lEiMKDXRhYmxlc19sb2FkZWQY'
    'AyABKA1SDHRhYmxlc0xvYWRlZBIlCg5jb2x1bW5zX2xvYWRlZBgEIAEoDVINY29sdW1uc0xvYW'
    'RlZBISCgRkb25lGAUgASgIUgRkb25lEi0KBWVycm9yGAYgASgLMhcucXVlcmF2dWUudjEuQWRt'
    'aW5FcnJvclIFZXJyb3I=');

@$core.Deprecated('Use formatOptionsDescriptor instead')
const FormatOptions$json = {
  '1': 'FormatOptions',
  '2': [
    {
      '1': 'keyword_case',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.KeywordCase',
      '10': 'keywordCase'
    },
    {'1': 'indent_width', '3': 2, '4': 1, '5': 13, '10': 'indentWidth'},
    {
      '1': 'comma_style',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.CommaStyle',
      '10': 'commaStyle'
    },
    {'1': 'max_line_width', '3': 4, '4': 1, '5': 13, '10': 'maxLineWidth'},
  ],
};

/// Descriptor for `FormatOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatOptionsDescriptor = $convert.base64Decode(
    'Cg1Gb3JtYXRPcHRpb25zEjsKDGtleXdvcmRfY2FzZRgBIAEoDjIYLnF1ZXJhdnVlLnYxLktleX'
    'dvcmRDYXNlUgtrZXl3b3JkQ2FzZRIhCgxpbmRlbnRfd2lkdGgYAiABKA1SC2luZGVudFdpZHRo'
    'EjgKC2NvbW1hX3N0eWxlGAMgASgOMhcucXVlcmF2dWUudjEuQ29tbWFTdHlsZVIKY29tbWFTdH'
    'lsZRIkCg5tYXhfbGluZV93aWR0aBgEIAEoDVIMbWF4TGluZVdpZHRo');

@$core.Deprecated('Use formatSQLRequestDescriptor instead')
const FormatSQLRequest$json = {
  '1': 'FormatSQLRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'dialect', '3': 2, '4': 1, '5': 9, '10': 'dialect'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'options',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FormatOptions',
      '10': 'options'
    },
    {
      '1': 'range',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TextRange',
      '9': 0,
      '10': 'range',
      '17': true
    },
  ],
  '8': [
    {'1': '_range'},
  ],
};

/// Descriptor for `FormatSQLRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatSQLRequestDescriptor = $convert.base64Decode(
    'ChBGb3JtYXRTUUxSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIYCgdkaW'
    'FsZWN0GAIgASgJUgdkaWFsZWN0EhIKBHRleHQYAyABKAlSBHRleHQSNAoHb3B0aW9ucxgEIAEo'
    'CzIaLnF1ZXJhdnVlLnYxLkZvcm1hdE9wdGlvbnNSB29wdGlvbnMSMQoFcmFuZ2UYBSABKAsyFi'
    '5xdWVyYXZ1ZS52MS5UZXh0UmFuZ2VIAFIFcmFuZ2WIAQFCCAoGX3Jhbmdl');

@$core.Deprecated('Use formatSQLResponseDescriptor instead')
const FormatSQLResponse$json = {
  '1': 'FormatSQLResponse',
  '2': [
    {'1': 'formatted_text', '3': 1, '4': 1, '5': 9, '10': 'formattedText'},
    {
      '1': 'replaced_range',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TextRange',
      '10': 'replacedRange'
    },
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AdminError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `FormatSQLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatSQLResponseDescriptor = $convert.base64Decode(
    'ChFGb3JtYXRTUUxSZXNwb25zZRIlCg5mb3JtYXR0ZWRfdGV4dBgBIAEoCVINZm9ybWF0dGVkVG'
    'V4dBI9Cg5yZXBsYWNlZF9yYW5nZRgCIAEoCzIWLnF1ZXJhdnVlLnYxLlRleHRSYW5nZVINcmVw'
    'bGFjZWRSYW5nZRItCgVlcnJvchgDIAEoCzIXLnF1ZXJhdnVlLnYxLkFkbWluRXJyb3JSBWVycm'
    '9y');
