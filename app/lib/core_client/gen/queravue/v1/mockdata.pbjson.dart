// This is a generated file - do not edit.
//
// Generated from queravue/v1/mockdata.proto.

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

@$core.Deprecated('Use mockErrorKindDescriptor instead')
const MockErrorKind$json = {
  '1': 'MockErrorKind',
  '2': [
    {'1': 'MOCK_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'MOCK_ERROR_KIND_PARSE', '2': 1},
    {'1': 'MOCK_ERROR_KIND_CYCLE', '2': 2},
    {'1': 'MOCK_ERROR_KIND_UNIQUE_EXHAUSTED', '2': 3},
    {'1': 'MOCK_ERROR_KIND_CONSTRAINT', '2': 4},
    {'1': 'MOCK_ERROR_KIND_CONFIRMATION_REQUIRED', '2': 5},
    {'1': 'MOCK_ERROR_KIND_AUTH', '2': 6},
    {'1': 'MOCK_ERROR_KIND_NETWORK', '2': 7},
    {'1': 'MOCK_ERROR_KIND_TIMEOUT', '2': 8},
    {'1': 'MOCK_ERROR_KIND_CANCELED', '2': 9},
    {'1': 'MOCK_ERROR_KIND_UNSUPPORTED', '2': 10},
    {'1': 'MOCK_ERROR_KIND_SERVER', '2': 11},
  ],
};

/// Descriptor for `MockErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mockErrorKindDescriptor = $convert.base64Decode(
    'Cg1Nb2NrRXJyb3JLaW5kEh8KG01PQ0tfRVJST1JfS0lORF9VTlNQRUNJRklFRBAAEhkKFU1PQ0'
    'tfRVJST1JfS0lORF9QQVJTRRABEhkKFU1PQ0tfRVJST1JfS0lORF9DWUNMRRACEiQKIE1PQ0tf'
    'RVJST1JfS0lORF9VTklRVUVfRVhIQVVTVEVEEAMSHgoaTU9DS19FUlJPUl9LSU5EX0NPTlNUUk'
    'FJTlQQBBIpCiVNT0NLX0VSUk9SX0tJTkRfQ09ORklSTUFUSU9OX1JFUVVJUkVEEAUSGAoUTU9D'
    'S19FUlJPUl9LSU5EX0FVVEgQBhIbChdNT0NLX0VSUk9SX0tJTkRfTkVUV09SSxAHEhsKF01PQ0'
    'tfRVJST1JfS0lORF9USU1FT1VUEAgSHAoYTU9DS19FUlJPUl9LSU5EX0NBTkNFTEVEEAkSHwob'
    'TU9DS19FUlJPUl9LSU5EX1VOU1VQUE9SVEVEEAoSGgoWTU9DS19FUlJPUl9LSU5EX1NFUlZFUh'
    'AL');

@$core.Deprecated('Use mockErrorDescriptor instead')
const MockError$json = {
  '1': 'MockError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.MockErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'target',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetRef',
      '10': 'target'
    },
    {'1': 'column', '3': 4, '4': 1, '5': 9, '10': 'column'},
  ],
};

/// Descriptor for `MockError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockErrorDescriptor = $convert.base64Decode(
    'CglNb2NrRXJyb3ISLgoEa2luZBgBIAEoDjIaLnF1ZXJhdnVlLnYxLk1vY2tFcnJvcktpbmRSBG'
    'tpbmQSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZRIyCgZ0YXJnZXQYAyABKAsyGi5xdWVyYXZ1'
    'ZS52MS5Nb2NrVGFyZ2V0UmVmUgZ0YXJnZXQSFgoGY29sdW1uGAQgASgJUgZjb2x1bW4=');

@$core.Deprecated('Use mockTargetRefDescriptor instead')
const MockTargetRef$json = {
  '1': 'MockTargetRef',
  '2': [
    {
      '1': 'table',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '9': 0,
      '10': 'table'
    },
    {
      '1': 'collection',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CollectionRef',
      '9': 0,
      '10': 'collection'
    },
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `MockTargetRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockTargetRefDescriptor = $convert.base64Decode(
    'Cg1Nb2NrVGFyZ2V0UmVmEi0KBXRhYmxlGAEgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZIAF'
    'IFdGFibGUSPAoKY29sbGVjdGlvbhgCIAEoCzIaLnF1ZXJhdnVlLnYxLkNvbGxlY3Rpb25SZWZI'
    'AFIKY29sbGVjdGlvbkIICgZ0YXJnZXQ=');

@$core.Deprecated('Use fakerRuleDescriptor instead')
const FakerRule$json = {
  '1': 'FakerRule',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
  ],
};

/// Descriptor for `FakerRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fakerRuleDescriptor =
    $convert.base64Decode('CglGYWtlclJ1bGUSEgoEa2luZBgBIAEoCVIEa2luZA==');

@$core.Deprecated('Use sequenceRuleDescriptor instead')
const SequenceRule$json = {
  '1': 'SequenceRule',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 3, '10': 'start'},
    {'1': 'step', '3': 2, '4': 1, '5': 3, '10': 'step'},
  ],
};

/// Descriptor for `SequenceRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sequenceRuleDescriptor = $convert.base64Decode(
    'CgxTZXF1ZW5jZVJ1bGUSFAoFc3RhcnQYASABKANSBXN0YXJ0EhIKBHN0ZXAYAiABKANSBHN0ZX'
    'A=');

@$core.Deprecated('Use intRangeRuleDescriptor instead')
const IntRangeRule$json = {
  '1': 'IntRangeRule',
  '2': [
    {'1': 'min', '3': 1, '4': 1, '5': 3, '10': 'min'},
    {'1': 'max', '3': 2, '4': 1, '5': 3, '10': 'max'},
  ],
};

/// Descriptor for `IntRangeRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List intRangeRuleDescriptor = $convert.base64Decode(
    'CgxJbnRSYW5nZVJ1bGUSEAoDbWluGAEgASgDUgNtaW4SEAoDbWF4GAIgASgDUgNtYXg=');

@$core.Deprecated('Use floatRangeRuleDescriptor instead')
const FloatRangeRule$json = {
  '1': 'FloatRangeRule',
  '2': [
    {'1': 'min', '3': 1, '4': 1, '5': 1, '10': 'min'},
    {'1': 'max', '3': 2, '4': 1, '5': 1, '10': 'max'},
  ],
};

/// Descriptor for `FloatRangeRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List floatRangeRuleDescriptor = $convert.base64Decode(
    'Cg5GbG9hdFJhbmdlUnVsZRIQCgNtaW4YASABKAFSA21pbhIQCgNtYXgYAiABKAFSA21heA==');

@$core.Deprecated('Use decimalRangeRuleDescriptor instead')
const DecimalRangeRule$json = {
  '1': 'DecimalRangeRule',
  '2': [
    {'1': 'min', '3': 1, '4': 1, '5': 9, '10': 'min'},
    {'1': 'max', '3': 2, '4': 1, '5': 9, '10': 'max'},
    {'1': 'scale', '3': 3, '4': 1, '5': 13, '10': 'scale'},
  ],
};

/// Descriptor for `DecimalRangeRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List decimalRangeRuleDescriptor = $convert.base64Decode(
    'ChBEZWNpbWFsUmFuZ2VSdWxlEhAKA21pbhgBIAEoCVIDbWluEhAKA21heBgCIAEoCVIDbWF4Eh'
    'QKBXNjYWxlGAMgASgNUgVzY2FsZQ==');

@$core.Deprecated('Use timeRangeRuleDescriptor instead')
const TimeRangeRule$json = {
  '1': 'TimeRangeRule',
  '2': [
    {'1': 'from_ms', '3': 1, '4': 1, '5': 3, '10': 'fromMs'},
    {'1': 'to_ms', '3': 2, '4': 1, '5': 3, '10': 'toMs'},
    {'1': 'date_only', '3': 3, '4': 1, '5': 8, '10': 'dateOnly'},
  ],
};

/// Descriptor for `TimeRangeRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeRangeRuleDescriptor = $convert.base64Decode(
    'Cg1UaW1lUmFuZ2VSdWxlEhcKB2Zyb21fbXMYASABKANSBmZyb21NcxITCgV0b19tcxgCIAEoA1'
    'IEdG9NcxIbCglkYXRlX29ubHkYAyABKAhSCGRhdGVPbmx5');

@$core.Deprecated('Use weightedValuesRuleDescriptor instead')
const WeightedValuesRule$json = {
  '1': 'WeightedValuesRule',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'values'
    },
    {'1': 'weights', '3': 2, '4': 3, '5': 1, '10': 'weights'},
  ],
};

/// Descriptor for `WeightedValuesRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List weightedValuesRuleDescriptor = $convert.base64Decode(
    'ChJXZWlnaHRlZFZhbHVlc1J1bGUSKgoGdmFsdWVzGAEgAygLMhIucXVlcmF2dWUudjEuVmFsdW'
    'VSBnZhbHVlcxIYCgd3ZWlnaHRzGAIgAygBUgd3ZWlnaHRz');

@$core.Deprecated('Use constantRuleDescriptor instead')
const ConstantRule$json = {
  '1': 'ConstantRule',
  '2': [
    {
      '1': 'value',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Value',
      '10': 'value'
    },
  ],
};

/// Descriptor for `ConstantRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List constantRuleDescriptor = $convert.base64Decode(
    'CgxDb25zdGFudFJ1bGUSKAoFdmFsdWUYASABKAsyEi5xdWVyYXZ1ZS52MS5WYWx1ZVIFdmFsdW'
    'U=');

@$core.Deprecated('Use patternRuleDescriptor instead')
const PatternRule$json = {
  '1': 'PatternRule',
  '2': [
    {'1': 'pattern', '3': 1, '4': 1, '5': 9, '10': 'pattern'},
  ],
};

/// Descriptor for `PatternRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patternRuleDescriptor = $convert
    .base64Decode('CgtQYXR0ZXJuUnVsZRIYCgdwYXR0ZXJuGAEgASgJUgdwYXR0ZXJu');

@$core.Deprecated('Use foreignKeyRuleDescriptor instead')
const ForeignKeyRule$json = {
  '1': 'ForeignKeyRule',
  '2': [
    {
      '1': 'parent',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'parent'
    },
    {'1': 'parent_column', '3': 2, '4': 1, '5': 9, '10': 'parentColumn'},
    {
      '1': 'from_existing_rows',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'fromExistingRows'
    },
  ],
};

/// Descriptor for `ForeignKeyRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List foreignKeyRuleDescriptor = $convert.base64Decode(
    'Cg5Gb3JlaWduS2V5UnVsZRItCgZwYXJlbnQYASABKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZl'
    'IGcGFyZW50EiMKDXBhcmVudF9jb2x1bW4YAiABKAlSDHBhcmVudENvbHVtbhIsChJmcm9tX2V4'
    'aXN0aW5nX3Jvd3MYAyABKAhSEGZyb21FeGlzdGluZ1Jvd3M=');

@$core.Deprecated('Use documentRuleDescriptor instead')
const DocumentRule$json = {
  '1': 'DocumentRule',
  '2': [
    {
      '1': 'fields',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockColumnRule',
      '10': 'fields'
    },
  ],
};

/// Descriptor for `DocumentRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentRuleDescriptor = $convert.base64Decode(
    'CgxEb2N1bWVudFJ1bGUSMwoGZmllbGRzGAEgAygLMhsucXVlcmF2dWUudjEuTW9ja0NvbHVtbl'
    'J1bGVSBmZpZWxkcw==');

@$core.Deprecated('Use arrayRuleDescriptor instead')
const ArrayRule$json = {
  '1': 'ArrayRule',
  '2': [
    {'1': 'min_length', '3': 1, '4': 1, '5': 13, '10': 'minLength'},
    {'1': 'max_length', '3': 2, '4': 1, '5': 13, '10': 'maxLength'},
    {
      '1': 'element',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockColumnRule',
      '10': 'element'
    },
  ],
};

/// Descriptor for `ArrayRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arrayRuleDescriptor = $convert.base64Decode(
    'CglBcnJheVJ1bGUSHQoKbWluX2xlbmd0aBgBIAEoDVIJbWluTGVuZ3RoEh0KCm1heF9sZW5ndG'
    'gYAiABKA1SCW1heExlbmd0aBI1CgdlbGVtZW50GAMgASgLMhsucXVlcmF2dWUudjEuTW9ja0Nv'
    'bHVtblJ1bGVSB2VsZW1lbnQ=');

@$core.Deprecated('Use skipRuleDescriptor instead')
const SkipRule$json = {
  '1': 'SkipRule',
};

/// Descriptor for `SkipRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skipRuleDescriptor =
    $convert.base64Decode('CghTa2lwUnVsZQ==');

@$core.Deprecated('Use mockColumnRuleDescriptor instead')
const MockColumnRule$json = {
  '1': 'MockColumnRule',
  '2': [
    {'1': 'column_or_path', '3': 1, '4': 1, '5': 9, '10': 'columnOrPath'},
    {'1': 'null_ratio', '3': 2, '4': 1, '5': 1, '10': 'nullRatio'},
    {'1': 'unique', '3': 3, '4': 1, '5': 8, '10': 'unique'},
    {
      '1': 'faker',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FakerRule',
      '9': 0,
      '10': 'faker'
    },
    {
      '1': 'sequence',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SequenceRule',
      '9': 0,
      '10': 'sequence'
    },
    {
      '1': 'int_range',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.IntRangeRule',
      '9': 0,
      '10': 'intRange'
    },
    {
      '1': 'float_range',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.FloatRangeRule',
      '9': 0,
      '10': 'floatRange'
    },
    {
      '1': 'decimal_range',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DecimalRangeRule',
      '9': 0,
      '10': 'decimalRange'
    },
    {
      '1': 'time_range',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TimeRangeRule',
      '9': 0,
      '10': 'timeRange'
    },
    {
      '1': 'weighted_values',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.WeightedValuesRule',
      '9': 0,
      '10': 'weightedValues'
    },
    {
      '1': 'constant',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ConstantRule',
      '9': 0,
      '10': 'constant'
    },
    {
      '1': 'pattern',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.PatternRule',
      '9': 0,
      '10': 'pattern'
    },
    {
      '1': 'foreign_key',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ForeignKeyRule',
      '9': 0,
      '10': 'foreignKey'
    },
    {
      '1': 'document',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DocumentRule',
      '9': 0,
      '10': 'document'
    },
    {
      '1': 'array',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ArrayRule',
      '9': 0,
      '10': 'array'
    },
    {
      '1': 'skip',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SkipRule',
      '9': 0,
      '10': 'skip'
    },
  ],
  '8': [
    {'1': 'rule'},
  ],
};

/// Descriptor for `MockColumnRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockColumnRuleDescriptor = $convert.base64Decode(
    'Cg5Nb2NrQ29sdW1uUnVsZRIkCg5jb2x1bW5fb3JfcGF0aBgBIAEoCVIMY29sdW1uT3JQYXRoEh'
    '0KCm51bGxfcmF0aW8YAiABKAFSCW51bGxSYXRpbxIWCgZ1bmlxdWUYAyABKAhSBnVuaXF1ZRIu'
    'CgVmYWtlchgEIAEoCzIWLnF1ZXJhdnVlLnYxLkZha2VyUnVsZUgAUgVmYWtlchI3CghzZXF1ZW'
    '5jZRgFIAEoCzIZLnF1ZXJhdnVlLnYxLlNlcXVlbmNlUnVsZUgAUghzZXF1ZW5jZRI4CglpbnRf'
    'cmFuZ2UYBiABKAsyGS5xdWVyYXZ1ZS52MS5JbnRSYW5nZVJ1bGVIAFIIaW50UmFuZ2USPgoLZm'
    'xvYXRfcmFuZ2UYByABKAsyGy5xdWVyYXZ1ZS52MS5GbG9hdFJhbmdlUnVsZUgAUgpmbG9hdFJh'
    'bmdlEkQKDWRlY2ltYWxfcmFuZ2UYCCABKAsyHS5xdWVyYXZ1ZS52MS5EZWNpbWFsUmFuZ2VSdW'
    'xlSABSDGRlY2ltYWxSYW5nZRI7Cgp0aW1lX3JhbmdlGAkgASgLMhoucXVlcmF2dWUudjEuVGlt'
    'ZVJhbmdlUnVsZUgAUgl0aW1lUmFuZ2USSgoPd2VpZ2h0ZWRfdmFsdWVzGAogASgLMh8ucXVlcm'
    'F2dWUudjEuV2VpZ2h0ZWRWYWx1ZXNSdWxlSABSDndlaWdodGVkVmFsdWVzEjcKCGNvbnN0YW50'
    'GAsgASgLMhkucXVlcmF2dWUudjEuQ29uc3RhbnRSdWxlSABSCGNvbnN0YW50EjQKB3BhdHRlcm'
    '4YDCABKAsyGC5xdWVyYXZ1ZS52MS5QYXR0ZXJuUnVsZUgAUgdwYXR0ZXJuEj4KC2ZvcmVpZ25f'
    'a2V5GA0gASgLMhsucXVlcmF2dWUudjEuRm9yZWlnbktleVJ1bGVIAFIKZm9yZWlnbktleRI3Cg'
    'hkb2N1bWVudBgOIAEoCzIZLnF1ZXJhdnVlLnYxLkRvY3VtZW50UnVsZUgAUghkb2N1bWVudBIu'
    'CgVhcnJheRgPIAEoCzIWLnF1ZXJhdnVlLnYxLkFycmF5UnVsZUgAUgVhcnJheRIrCgRza2lwGB'
    'AgASgLMhUucXVlcmF2dWUudjEuU2tpcFJ1bGVIAFIEc2tpcEIGCgRydWxl');

@$core.Deprecated('Use mockTargetDescriptor instead')
const MockTarget$json = {
  '1': 'MockTarget',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetRef',
      '10': 'target'
    },
    {'1': 'rows', '3': 2, '4': 1, '5': 4, '10': 'rows'},
    {
      '1': 'rules',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockColumnRule',
      '10': 'rules'
    },
  ],
};

/// Descriptor for `MockTarget`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockTargetDescriptor = $convert.base64Decode(
    'CgpNb2NrVGFyZ2V0EjIKBnRhcmdldBgBIAEoCzIaLnF1ZXJhdnVlLnYxLk1vY2tUYXJnZXRSZW'
    'ZSBnRhcmdldBISCgRyb3dzGAIgASgEUgRyb3dzEjEKBXJ1bGVzGAMgAygLMhsucXVlcmF2dWUu'
    'djEuTW9ja0NvbHVtblJ1bGVSBXJ1bGVz');

@$core.Deprecated('Use mockSpecDescriptor instead')
const MockSpec$json = {
  '1': 'MockSpec',
  '2': [
    {'1': 'seed', '3': 1, '4': 1, '5': 4, '10': 'seed'},
    {
      '1': 'targets',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockTarget',
      '10': 'targets'
    },
  ],
};

/// Descriptor for `MockSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockSpecDescriptor = $convert.base64Decode(
    'CghNb2NrU3BlYxISCgRzZWVkGAEgASgEUgRzZWVkEjEKB3RhcmdldHMYAiADKAsyFy5xdWVyYX'
    'Z1ZS52MS5Nb2NrVGFyZ2V0Ugd0YXJnZXRz');

@$core.Deprecated('Use mockCycleEdgeDescriptor instead')
const MockCycleEdge$json = {
  '1': 'MockCycleEdge',
  '2': [
    {
      '1': 'child',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'child'
    },
    {
      '1': 'parent',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'parent'
    },
    {'1': 'constraint_name', '3': 3, '4': 1, '5': 9, '10': 'constraintName'},
    {'1': 'nullable', '3': 4, '4': 1, '5': 8, '10': 'nullable'},
  ],
};

/// Descriptor for `MockCycleEdge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockCycleEdgeDescriptor = $convert.base64Decode(
    'Cg1Nb2NrQ3ljbGVFZGdlEisKBWNoaWxkGAEgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSBW'
    'NoaWxkEi0KBnBhcmVudBgCIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgZwYXJlbnQSJwoP'
    'Y29uc3RyYWludF9uYW1lGAMgASgJUg5jb25zdHJhaW50TmFtZRIaCghudWxsYWJsZRgEIAEoCF'
    'IIbnVsbGFibGU=');

@$core.Deprecated('Use mockCycleDescriptor instead')
const MockCycle$json = {
  '1': 'MockCycle',
  '2': [
    {
      '1': 'edges',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockCycleEdge',
      '10': 'edges'
    },
  ],
};

/// Descriptor for `MockCycle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockCycleDescriptor = $convert.base64Decode(
    'CglNb2NrQ3ljbGUSMAoFZWRnZXMYASADKAsyGi5xdWVyYXZ1ZS52MS5Nb2NrQ3ljbGVFZGdlUg'
    'VlZGdlcw==');

@$core.Deprecated('Use suggestMockSpecRequestDescriptor instead')
const SuggestMockSpecRequest$json = {
  '1': 'SuggestMockSpecRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'tables',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'tables'
    },
    {
      '1': 'collections',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.CollectionRef',
      '10': 'collections'
    },
    {'1': 'rows', '3': 4, '4': 1, '5': 4, '10': 'rows'},
  ],
};

/// Descriptor for `SuggestMockSpecRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestMockSpecRequestDescriptor = $convert.base64Decode(
    'ChZTdWdnZXN0TW9ja1NwZWNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZB'
    'ItCgZ0YWJsZXMYAiADKAsyFS5xdWVyYXZ1ZS52MS5UYWJsZVJlZlIGdGFibGVzEjwKC2NvbGxl'
    'Y3Rpb25zGAMgAygLMhoucXVlcmF2dWUudjEuQ29sbGVjdGlvblJlZlILY29sbGVjdGlvbnMSEg'
    'oEcm93cxgEIAEoBFIEcm93cw==');

@$core.Deprecated('Use suggestMockSpecResponseDescriptor instead')
const SuggestMockSpecResponse$json = {
  '1': 'SuggestMockSpecResponse',
  '2': [
    {
      '1': 'spec',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockSpec',
      '10': 'spec'
    },
    {
      '1': 'cycles',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockCycle',
      '10': 'cycles'
    },
    {'1': 'faker_kinds', '3': 3, '4': 3, '5': 9, '10': 'fakerKinds'},
    {'1': 'warnings', '3': 4, '4': 3, '5': 9, '10': 'warnings'},
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `SuggestMockSpecResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestMockSpecResponseDescriptor = $convert.base64Decode(
    'ChdTdWdnZXN0TW9ja1NwZWNSZXNwb25zZRIpCgRzcGVjGAEgASgLMhUucXVlcmF2dWUudjEuTW'
    '9ja1NwZWNSBHNwZWMSLgoGY3ljbGVzGAIgAygLMhYucXVlcmF2dWUudjEuTW9ja0N5Y2xlUgZj'
    'eWNsZXMSHwoLZmFrZXJfa2luZHMYAyADKAlSCmZha2VyS2luZHMSGgoId2FybmluZ3MYBCADKA'
    'lSCHdhcm5pbmdzEiwKBWVycm9yGAUgASgLMhYucXVlcmF2dWUudjEuTW9ja0Vycm9yUgVlcnJv'
    'cg==');

@$core.Deprecated('Use previewMockRequestDescriptor instead')
const PreviewMockRequest$json = {
  '1': 'PreviewMockRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'spec',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockSpec',
      '10': 'spec'
    },
    {'1': 'rows', '3': 3, '4': 1, '5': 13, '10': 'rows'},
  ],
};

/// Descriptor for `PreviewMockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewMockRequestDescriptor = $convert.base64Decode(
    'ChJQcmV2aWV3TW9ja1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEikKBH'
    'NwZWMYAiABKAsyFS5xdWVyYXZ1ZS52MS5Nb2NrU3BlY1IEc3BlYxISCgRyb3dzGAMgASgNUgRy'
    'b3dz');

@$core.Deprecated('Use mockPreviewDescriptor instead')
const MockPreview$json = {
  '1': 'MockPreview',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetRef',
      '10': 'target'
    },
    {'1': 'columns', '3': 2, '4': 3, '5': 9, '10': 'columns'},
    {
      '1': 'rows',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RowBatch',
      '10': 'rows'
    },
    {'1': 'documents_ejson', '3': 4, '4': 3, '5': 9, '10': 'documentsEjson'},
  ],
};

/// Descriptor for `MockPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockPreviewDescriptor = $convert.base64Decode(
    'CgtNb2NrUHJldmlldxIyCgZ0YXJnZXQYASABKAsyGi5xdWVyYXZ1ZS52MS5Nb2NrVGFyZ2V0Um'
    'VmUgZ0YXJnZXQSGAoHY29sdW1ucxgCIAMoCVIHY29sdW1ucxIpCgRyb3dzGAMgASgLMhUucXVl'
    'cmF2dWUudjEuUm93QmF0Y2hSBHJvd3MSJwoPZG9jdW1lbnRzX2Vqc29uGAQgAygJUg5kb2N1bW'
    'VudHNFanNvbg==');

@$core.Deprecated('Use previewMockResponseDescriptor instead')
const PreviewMockResponse$json = {
  '1': 'PreviewMockResponse',
  '2': [
    {
      '1': 'previews',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockPreview',
      '10': 'previews'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `PreviewMockResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewMockResponseDescriptor = $convert.base64Decode(
    'ChNQcmV2aWV3TW9ja1Jlc3BvbnNlEjQKCHByZXZpZXdzGAEgAygLMhgucXVlcmF2dWUudjEuTW'
    '9ja1ByZXZpZXdSCHByZXZpZXdzEiwKBWVycm9yGAIgASgLMhYucXVlcmF2dWUudjEuTW9ja0Vy'
    'cm9yUgVlcnJvcg==');

@$core.Deprecated('Use runMockRequestDescriptor instead')
const RunMockRequest$json = {
  '1': 'RunMockRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'spec',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockSpec',
      '10': 'spec'
    },
    {'1': 'confirmed', '3': 3, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `RunMockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runMockRequestDescriptor = $convert.base64Decode(
    'Cg5SdW5Nb2NrUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSKQoEc3BlYx'
    'gCIAEoCzIVLnF1ZXJhdnVlLnYxLk1vY2tTcGVjUgRzcGVjEhwKCWNvbmZpcm1lZBgDIAEoCFIJ'
    'Y29uZmlybWVk');

@$core.Deprecated('Use mockProgressDescriptor instead')
const MockProgress$json = {
  '1': 'MockProgress',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetRef',
      '10': 'target'
    },
    {'1': 'rows', '3': 2, '4': 1, '5': 4, '10': 'rows'},
    {'1': 'rows_per_second', '3': 3, '4': 1, '5': 1, '10': 'rowsPerSecond'},
  ],
};

/// Descriptor for `MockProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockProgressDescriptor = $convert.base64Decode(
    'CgxNb2NrUHJvZ3Jlc3MSMgoGdGFyZ2V0GAEgASgLMhoucXVlcmF2dWUudjEuTW9ja1RhcmdldF'
    'JlZlIGdGFyZ2V0EhIKBHJvd3MYAiABKARSBHJvd3MSJgoPcm93c19wZXJfc2Vjb25kGAMgASgB'
    'Ug1yb3dzUGVyU2Vjb25k');

@$core.Deprecated('Use mockTargetDoneDescriptor instead')
const MockTargetDone$json = {
  '1': 'MockTargetDone',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetRef',
      '10': 'target'
    },
    {'1': 'rows', '3': 2, '4': 1, '5': 4, '10': 'rows'},
    {'1': 'elapsed_ms', '3': 3, '4': 1, '5': 4, '10': 'elapsedMs'},
  ],
};

/// Descriptor for `MockTargetDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockTargetDoneDescriptor = $convert.base64Decode(
    'Cg5Nb2NrVGFyZ2V0RG9uZRIyCgZ0YXJnZXQYASABKAsyGi5xdWVyYXZ1ZS52MS5Nb2NrVGFyZ2'
    'V0UmVmUgZ0YXJnZXQSEgoEcm93cxgCIAEoBFIEcm93cxIdCgplbGFwc2VkX21zGAMgASgEUgll'
    'bGFwc2VkTXM=');

@$core.Deprecated('Use mockSummaryDescriptor instead')
const MockSummary$json = {
  '1': 'MockSummary',
  '2': [
    {'1': 'rows', '3': 1, '4': 1, '5': 4, '10': 'rows'},
    {'1': 'elapsed_ms', '3': 2, '4': 1, '5': 4, '10': 'elapsedMs'},
    {
      '1': 'done',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MockTargetDone',
      '10': 'done'
    },
  ],
};

/// Descriptor for `MockSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mockSummaryDescriptor = $convert.base64Decode(
    'CgtNb2NrU3VtbWFyeRISCgRyb3dzGAEgASgEUgRyb3dzEh0KCmVsYXBzZWRfbXMYAiABKARSCW'
    'VsYXBzZWRNcxIvCgRkb25lGAMgAygLMhsucXVlcmF2dWUudjEuTW9ja1RhcmdldERvbmVSBGRv'
    'bmU=');

@$core.Deprecated('Use runMockResponseDescriptor instead')
const RunMockResponse$json = {
  '1': 'RunMockResponse',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockProgress',
      '9': 0,
      '10': 'progress'
    },
    {
      '1': 'target_done',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockTargetDone',
      '9': 0,
      '10': 'targetDone'
    },
    {
      '1': 'summary',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockSummary',
      '9': 0,
      '10': 'summary'
    },
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MockError',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `RunMockResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runMockResponseDescriptor = $convert.base64Decode(
    'Cg9SdW5Nb2NrUmVzcG9uc2USNwoIcHJvZ3Jlc3MYASABKAsyGS5xdWVyYXZ1ZS52MS5Nb2NrUH'
    'JvZ3Jlc3NIAFIIcHJvZ3Jlc3MSPgoLdGFyZ2V0X2RvbmUYAiABKAsyGy5xdWVyYXZ1ZS52MS5N'
    'b2NrVGFyZ2V0RG9uZUgAUgp0YXJnZXREb25lEjQKB3N1bW1hcnkYAyABKAsyGC5xdWVyYXZ1ZS'
    '52MS5Nb2NrU3VtbWFyeUgAUgdzdW1tYXJ5Ei4KBWVycm9yGAQgASgLMhYucXVlcmF2dWUudjEu'
    'TW9ja0Vycm9ySABSBWVycm9yQgcKBWV2ZW50');
