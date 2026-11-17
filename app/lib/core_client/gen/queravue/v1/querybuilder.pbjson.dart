// This is a generated file - do not edit.
//
// Generated from queravue/v1/querybuilder.proto.

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

@$core.Deprecated('Use queryBuilderErrorKindDescriptor instead')
const QueryBuilderErrorKind$json = {
  '1': 'QueryBuilderErrorKind',
  '2': [
    {'1': 'QUERY_BUILDER_ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'QUERY_BUILDER_ERROR_KIND_INVALID_MODEL', '2': 1},
    {'1': 'QUERY_BUILDER_ERROR_KIND_PARSE', '2': 2},
    {'1': 'QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT', '2': 3},
    {'1': 'QUERY_BUILDER_ERROR_KIND_NOT_SQL', '2': 4},
  ],
};

/// Descriptor for `QueryBuilderErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List queryBuilderErrorKindDescriptor = $convert.base64Decode(
    'ChVRdWVyeUJ1aWxkZXJFcnJvcktpbmQSKAokUVVFUllfQlVJTERFUl9FUlJPUl9LSU5EX1VOU1'
    'BFQ0lGSUVEEAASKgomUVVFUllfQlVJTERFUl9FUlJPUl9LSU5EX0lOVkFMSURfTU9ERUwQARIi'
    'Ch5RVUVSWV9CVUlMREVSX0VSUk9SX0tJTkRfUEFSU0UQAhIyCi5RVUVSWV9CVUlMREVSX0VSUk'
    '9SX0tJTkRfVU5TVVBQT1JURURfQ09OU1RSVUNUEAMSJAogUVVFUllfQlVJTERFUl9FUlJPUl9L'
    'SU5EX05PVF9TUUwQBA==');

@$core.Deprecated('Use sqlJoinKindDescriptor instead')
const SqlJoinKind$json = {
  '1': 'SqlJoinKind',
  '2': [
    {'1': 'SQL_JOIN_KIND_UNSPECIFIED', '2': 0},
    {'1': 'SQL_JOIN_KIND_INNER', '2': 1},
    {'1': 'SQL_JOIN_KIND_LEFT', '2': 2},
    {'1': 'SQL_JOIN_KIND_RIGHT', '2': 3},
    {'1': 'SQL_JOIN_KIND_FULL', '2': 4},
  ],
};

/// Descriptor for `SqlJoinKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sqlJoinKindDescriptor = $convert.base64Decode(
    'CgtTcWxKb2luS2luZBIdChlTUUxfSk9JTl9LSU5EX1VOU1BFQ0lGSUVEEAASFwoTU1FMX0pPSU'
    '5fS0lORF9JTk5FUhABEhYKElNRTF9KT0lOX0tJTkRfTEVGVBACEhcKE1NRTF9KT0lOX0tJTkRf'
    'UklHSFQQAxIWChJTUUxfSk9JTl9LSU5EX0ZVTEwQBA==');

@$core.Deprecated('Use sqlAggregateDescriptor instead')
const SqlAggregate$json = {
  '1': 'SqlAggregate',
  '2': [
    {'1': 'SQL_AGGREGATE_UNSPECIFIED', '2': 0},
    {'1': 'SQL_AGGREGATE_COUNT', '2': 1},
    {'1': 'SQL_AGGREGATE_SUM', '2': 2},
    {'1': 'SQL_AGGREGATE_AVG', '2': 3},
    {'1': 'SQL_AGGREGATE_MIN', '2': 4},
    {'1': 'SQL_AGGREGATE_MAX', '2': 5},
  ],
};

/// Descriptor for `SqlAggregate`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sqlAggregateDescriptor = $convert.base64Decode(
    'CgxTcWxBZ2dyZWdhdGUSHQoZU1FMX0FHR1JFR0FURV9VTlNQRUNJRklFRBAAEhcKE1NRTF9BR0'
    'dSRUdBVEVfQ09VTlQQARIVChFTUUxfQUdHUkVHQVRFX1NVTRACEhUKEVNRTF9BR0dSRUdBVEVf'
    'QVZHEAMSFQoRU1FMX0FHR1JFR0FURV9NSU4QBBIVChFTUUxfQUdHUkVHQVRFX01BWBAF');

@$core.Deprecated('Use sqlOperatorDescriptor instead')
const SqlOperator$json = {
  '1': 'SqlOperator',
  '2': [
    {'1': 'SQL_OPERATOR_UNSPECIFIED', '2': 0},
    {'1': 'SQL_OPERATOR_EQ', '2': 1},
    {'1': 'SQL_OPERATOR_NE', '2': 2},
    {'1': 'SQL_OPERATOR_LT', '2': 3},
    {'1': 'SQL_OPERATOR_LE', '2': 4},
    {'1': 'SQL_OPERATOR_GT', '2': 5},
    {'1': 'SQL_OPERATOR_GE', '2': 6},
    {'1': 'SQL_OPERATOR_LIKE', '2': 7},
    {'1': 'SQL_OPERATOR_IN', '2': 8},
    {'1': 'SQL_OPERATOR_BETWEEN', '2': 9},
    {'1': 'SQL_OPERATOR_IS_NULL', '2': 10},
  ],
};

/// Descriptor for `SqlOperator`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sqlOperatorDescriptor = $convert.base64Decode(
    'CgtTcWxPcGVyYXRvchIcChhTUUxfT1BFUkFUT1JfVU5TUEVDSUZJRUQQABITCg9TUUxfT1BFUk'
    'FUT1JfRVEQARITCg9TUUxfT1BFUkFUT1JfTkUQAhITCg9TUUxfT1BFUkFUT1JfTFQQAxITCg9T'
    'UUxfT1BFUkFUT1JfTEUQBBITCg9TUUxfT1BFUkFUT1JfR1QQBRITCg9TUUxfT1BFUkFUT1JfR0'
    'UQBhIVChFTUUxfT1BFUkFUT1JfTElLRRAHEhMKD1NRTF9PUEVSQVRPUl9JThAIEhgKFFNRTF9P'
    'UEVSQVRPUl9CRVRXRUVOEAkSGAoUU1FMX09QRVJBVE9SX0lTX05VTEwQCg==');

@$core.Deprecated('Use sqlBoolOpDescriptor instead')
const SqlBoolOp$json = {
  '1': 'SqlBoolOp',
  '2': [
    {'1': 'SQL_BOOL_OP_UNSPECIFIED', '2': 0},
    {'1': 'SQL_BOOL_OP_AND', '2': 1},
    {'1': 'SQL_BOOL_OP_OR', '2': 2},
  ],
};

/// Descriptor for `SqlBoolOp`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sqlBoolOpDescriptor = $convert.base64Decode(
    'CglTcWxCb29sT3ASGwoXU1FMX0JPT0xfT1BfVU5TUEVDSUZJRUQQABITCg9TUUxfQk9PTF9PUF'
    '9BTkQQARISCg5TUUxfQk9PTF9PUF9PUhAC');

@$core.Deprecated('Use sqlNullsDescriptor instead')
const SqlNulls$json = {
  '1': 'SqlNulls',
  '2': [
    {'1': 'SQL_NULLS_UNSPECIFIED', '2': 0},
    {'1': 'SQL_NULLS_FIRST', '2': 1},
    {'1': 'SQL_NULLS_LAST', '2': 2},
  ],
};

/// Descriptor for `SqlNulls`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sqlNullsDescriptor = $convert.base64Decode(
    'CghTcWxOdWxscxIZChVTUUxfTlVMTFNfVU5TUEVDSUZJRUQQABITCg9TUUxfTlVMTFNfRklSU1'
    'QQARISCg5TUUxfTlVMTFNfTEFTVBAC');

@$core.Deprecated('Use mongoBoolOpDescriptor instead')
const MongoBoolOp$json = {
  '1': 'MongoBoolOp',
  '2': [
    {'1': 'MONGO_BOOL_OP_UNSPECIFIED', '2': 0},
    {'1': 'MONGO_BOOL_OP_AND', '2': 1},
    {'1': 'MONGO_BOOL_OP_OR', '2': 2},
    {'1': 'MONGO_BOOL_OP_NOR', '2': 3},
  ],
};

/// Descriptor for `MongoBoolOp`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mongoBoolOpDescriptor = $convert.base64Decode(
    'CgtNb25nb0Jvb2xPcBIdChlNT05HT19CT09MX09QX1VOU1BFQ0lGSUVEEAASFQoRTU9OR09fQk'
    '9PTF9PUF9BTkQQARIUChBNT05HT19CT09MX09QX09SEAISFQoRTU9OR09fQk9PTF9PUF9OT1IQ'
    'Aw==');

@$core.Deprecated('Use mongoOperatorDescriptor instead')
const MongoOperator$json = {
  '1': 'MongoOperator',
  '2': [
    {'1': 'MONGO_OPERATOR_UNSPECIFIED', '2': 0},
    {'1': 'MONGO_OPERATOR_EQ', '2': 1},
    {'1': 'MONGO_OPERATOR_NE', '2': 2},
    {'1': 'MONGO_OPERATOR_GT', '2': 3},
    {'1': 'MONGO_OPERATOR_GTE', '2': 4},
    {'1': 'MONGO_OPERATOR_LT', '2': 5},
    {'1': 'MONGO_OPERATOR_LTE', '2': 6},
    {'1': 'MONGO_OPERATOR_IN', '2': 7},
    {'1': 'MONGO_OPERATOR_NIN', '2': 8},
    {'1': 'MONGO_OPERATOR_EXISTS', '2': 9},
    {'1': 'MONGO_OPERATOR_REGEX', '2': 10},
    {'1': 'MONGO_OPERATOR_TYPE', '2': 11},
  ],
};

/// Descriptor for `MongoOperator`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mongoOperatorDescriptor = $convert.base64Decode(
    'Cg1Nb25nb09wZXJhdG9yEh4KGk1PTkdPX09QRVJBVE9SX1VOU1BFQ0lGSUVEEAASFQoRTU9OR0'
    '9fT1BFUkFUT1JfRVEQARIVChFNT05HT19PUEVSQVRPUl9ORRACEhUKEU1PTkdPX09QRVJBVE9S'
    'X0dUEAMSFgoSTU9OR09fT1BFUkFUT1JfR1RFEAQSFQoRTU9OR09fT1BFUkFUT1JfTFQQBRIWCh'
    'JNT05HT19PUEVSQVRPUl9MVEUQBhIVChFNT05HT19PUEVSQVRPUl9JThAHEhYKEk1PTkdPX09Q'
    'RVJBVE9SX05JThAIEhkKFU1PTkdPX09QRVJBVE9SX0VYSVNUUxAJEhgKFE1PTkdPX09QRVJBVE'
    '9SX1JFR0VYEAoSFwoTTU9OR09fT1BFUkFUT1JfVFlQRRAL');

@$core.Deprecated('Use mongoProjectionModeDescriptor instead')
const MongoProjectionMode$json = {
  '1': 'MongoProjectionMode',
  '2': [
    {'1': 'MONGO_PROJECTION_MODE_UNSPECIFIED', '2': 0},
    {'1': 'MONGO_PROJECTION_MODE_INCLUDE', '2': 1},
    {'1': 'MONGO_PROJECTION_MODE_EXCLUDE', '2': 2},
  ],
};

/// Descriptor for `MongoProjectionMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mongoProjectionModeDescriptor = $convert.base64Decode(
    'ChNNb25nb1Byb2plY3Rpb25Nb2RlEiUKIU1PTkdPX1BST0pFQ1RJT05fTU9ERV9VTlNQRUNJRk'
    'lFRBAAEiEKHU1PTkdPX1BST0pFQ1RJT05fTU9ERV9JTkNMVURFEAESIQodTU9OR09fUFJPSkVD'
    'VElPTl9NT0RFX0VYQ0xVREUQAg==');

@$core.Deprecated('Use queryBuilderErrorDescriptor instead')
const QueryBuilderError$json = {
  '1': 'QueryBuilderError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.QueryBuilderErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'offset',
      '3': 3,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'offset',
      '17': true
    },
  ],
  '8': [
    {'1': '_offset'},
  ],
};

/// Descriptor for `QueryBuilderError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryBuilderErrorDescriptor = $convert.base64Decode(
    'ChFRdWVyeUJ1aWxkZXJFcnJvchI2CgRraW5kGAEgASgOMiIucXVlcmF2dWUudjEuUXVlcnlCdW'
    'lsZGVyRXJyb3JLaW5kUgRraW5kEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USGwoGb2Zmc2V0'
    'GAMgASgNSABSBm9mZnNldIgBAUIJCgdfb2Zmc2V0');

@$core.Deprecated('Use generateSqlRequestDescriptor instead')
const GenerateSqlRequest$json = {
  '1': 'GenerateSqlRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'model',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlQueryModel',
      '10': 'model'
    },
  ],
};

/// Descriptor for `GenerateSqlRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateSqlRequestDescriptor = $convert.base64Decode(
    'ChJHZW5lcmF0ZVNxbFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjAKBW'
    '1vZGVsGAIgASgLMhoucXVlcmF2dWUudjEuU3FsUXVlcnlNb2RlbFIFbW9kZWw=');

@$core.Deprecated('Use generateSqlResponseDescriptor instead')
const GenerateSqlResponse$json = {
  '1': 'GenerateSqlResponse',
  '2': [
    {'1': 'sql', '3': 1, '4': 1, '5': 9, '10': 'sql'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.QueryBuilderError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `GenerateSqlResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateSqlResponseDescriptor = $convert.base64Decode(
    'ChNHZW5lcmF0ZVNxbFJlc3BvbnNlEhAKA3NxbBgBIAEoCVIDc3FsEjQKBWVycm9yGAIgASgLMh'
    '4ucXVlcmF2dWUudjEuUXVlcnlCdWlsZGVyRXJyb3JSBWVycm9y');

@$core.Deprecated('Use parseSqlRequestDescriptor instead')
const ParseSqlRequest$json = {
  '1': 'ParseSqlRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'sql', '3': 2, '4': 1, '5': 9, '10': 'sql'},
  ],
};

/// Descriptor for `ParseSqlRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseSqlRequestDescriptor = $convert.base64Decode(
    'Cg9QYXJzZVNxbFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhAKA3NxbB'
    'gCIAEoCVIDc3Fs');

@$core.Deprecated('Use parseSqlResponseDescriptor instead')
const ParseSqlResponse$json = {
  '1': 'ParseSqlResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlQueryModel',
      '10': 'model'
    },
    {'1': 'comments_dropped', '3': 2, '4': 1, '5': 8, '10': 'commentsDropped'},
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.QueryBuilderError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ParseSqlResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseSqlResponseDescriptor = $convert.base64Decode(
    'ChBQYXJzZVNxbFJlc3BvbnNlEjAKBW1vZGVsGAEgASgLMhoucXVlcmF2dWUudjEuU3FsUXVlcn'
    'lNb2RlbFIFbW9kZWwSKQoQY29tbWVudHNfZHJvcHBlZBgCIAEoCFIPY29tbWVudHNEcm9wcGVk'
    'EjQKBWVycm9yGAMgASgLMh4ucXVlcmF2dWUudjEuUXVlcnlCdWlsZGVyRXJyb3JSBWVycm9y');

@$core.Deprecated('Use sqlQueryModelDescriptor instead')
const SqlQueryModel$json = {
  '1': 'SqlQueryModel',
  '2': [
    {
      '1': 'from',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlTableRef',
      '10': 'from'
    },
    {
      '1': 'joins',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlJoin',
      '10': 'joins'
    },
    {
      '1': 'select',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlSelectItem',
      '10': 'select'
    },
    {'1': 'distinct', '3': 4, '4': 1, '5': 8, '10': 'distinct'},
    {
      '1': 'where',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlCondition',
      '10': 'where'
    },
    {
      '1': 'group_by',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlColumnRef',
      '10': 'groupBy'
    },
    {
      '1': 'having',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlCondition',
      '10': 'having'
    },
    {
      '1': 'order_by',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlOrderTerm',
      '10': 'orderBy'
    },
    {'1': 'limit', '3': 9, '4': 1, '5': 4, '9': 0, '10': 'limit', '17': true},
    {
      '1': 'offset',
      '3': 10,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'offset',
      '17': true
    },
  ],
  '8': [
    {'1': '_limit'},
    {'1': '_offset'},
  ],
};

/// Descriptor for `SqlQueryModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlQueryModelDescriptor = $convert.base64Decode(
    'Cg1TcWxRdWVyeU1vZGVsEiwKBGZyb20YASABKAsyGC5xdWVyYXZ1ZS52MS5TcWxUYWJsZVJlZl'
    'IEZnJvbRIqCgVqb2lucxgCIAMoCzIULnF1ZXJhdnVlLnYxLlNxbEpvaW5SBWpvaW5zEjIKBnNl'
    'bGVjdBgDIAMoCzIaLnF1ZXJhdnVlLnYxLlNxbFNlbGVjdEl0ZW1SBnNlbGVjdBIaCghkaXN0aW'
    '5jdBgEIAEoCFIIZGlzdGluY3QSLwoFd2hlcmUYBSABKAsyGS5xdWVyYXZ1ZS52MS5TcWxDb25k'
    'aXRpb25SBXdoZXJlEjQKCGdyb3VwX2J5GAYgAygLMhkucXVlcmF2dWUudjEuU3FsQ29sdW1uUm'
    'VmUgdncm91cEJ5EjEKBmhhdmluZxgHIAEoCzIZLnF1ZXJhdnVlLnYxLlNxbENvbmRpdGlvblIG'
    'aGF2aW5nEjQKCG9yZGVyX2J5GAggAygLMhkucXVlcmF2dWUudjEuU3FsT3JkZXJUZXJtUgdvcm'
    'RlckJ5EhkKBWxpbWl0GAkgASgESABSBWxpbWl0iAEBEhsKBm9mZnNldBgKIAEoBEgBUgZvZmZz'
    'ZXSIAQFCCAoGX2xpbWl0QgkKB19vZmZzZXQ=');

@$core.Deprecated('Use sqlTableRefDescriptor instead')
const SqlTableRef$json = {
  '1': 'SqlTableRef',
  '2': [
    {'1': 'schema', '3': 1, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'table', '3': 2, '4': 1, '5': 9, '10': 'table'},
    {'1': 'alias', '3': 3, '4': 1, '5': 9, '10': 'alias'},
  ],
};

/// Descriptor for `SqlTableRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlTableRefDescriptor = $convert.base64Decode(
    'CgtTcWxUYWJsZVJlZhIWCgZzY2hlbWEYASABKAlSBnNjaGVtYRIUCgV0YWJsZRgCIAEoCVIFdG'
    'FibGUSFAoFYWxpYXMYAyABKAlSBWFsaWFz');

@$core.Deprecated('Use sqlJoinDescriptor instead')
const SqlJoin$json = {
  '1': 'SqlJoin',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SqlJoinKind',
      '10': 'kind'
    },
    {
      '1': 'table',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlTableRef',
      '10': 'table'
    },
    {
      '1': 'on',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlCondition',
      '10': 'on'
    },
  ],
};

/// Descriptor for `SqlJoin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlJoinDescriptor = $convert.base64Decode(
    'CgdTcWxKb2luEiwKBGtpbmQYASABKA4yGC5xdWVyYXZ1ZS52MS5TcWxKb2luS2luZFIEa2luZB'
    'IuCgV0YWJsZRgCIAEoCzIYLnF1ZXJhdnVlLnYxLlNxbFRhYmxlUmVmUgV0YWJsZRIpCgJvbhgD'
    'IAEoCzIZLnF1ZXJhdnVlLnYxLlNxbENvbmRpdGlvblICb24=');

@$core.Deprecated('Use sqlColumnRefDescriptor instead')
const SqlColumnRef$json = {
  '1': 'SqlColumnRef',
  '2': [
    {'1': 'table_alias', '3': 1, '4': 1, '5': 9, '10': 'tableAlias'},
    {'1': 'column', '3': 2, '4': 1, '5': 9, '10': 'column'},
  ],
};

/// Descriptor for `SqlColumnRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlColumnRefDescriptor = $convert.base64Decode(
    'CgxTcWxDb2x1bW5SZWYSHwoLdGFibGVfYWxpYXMYASABKAlSCnRhYmxlQWxpYXMSFgoGY29sdW'
    '1uGAIgASgJUgZjb2x1bW4=');

@$core.Deprecated('Use sqlAggregateExprDescriptor instead')
const SqlAggregateExpr$json = {
  '1': 'SqlAggregateExpr',
  '2': [
    {
      '1': 'function',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SqlAggregate',
      '10': 'function'
    },
    {
      '1': 'column',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlColumnRef',
      '10': 'column'
    },
    {'1': 'distinct', '3': 3, '4': 1, '5': 8, '10': 'distinct'},
  ],
};

/// Descriptor for `SqlAggregateExpr`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlAggregateExprDescriptor = $convert.base64Decode(
    'ChBTcWxBZ2dyZWdhdGVFeHByEjUKCGZ1bmN0aW9uGAEgASgOMhkucXVlcmF2dWUudjEuU3FsQW'
    'dncmVnYXRlUghmdW5jdGlvbhIxCgZjb2x1bW4YAiABKAsyGS5xdWVyYXZ1ZS52MS5TcWxDb2x1'
    'bW5SZWZSBmNvbHVtbhIaCghkaXN0aW5jdBgDIAEoCFIIZGlzdGluY3Q=');

@$core.Deprecated('Use sqlSelectItemDescriptor instead')
const SqlSelectItem$json = {
  '1': 'SqlSelectItem',
  '2': [
    {
      '1': 'column',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlColumnRef',
      '9': 0,
      '10': 'column'
    },
    {
      '1': 'aggregate',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlAggregateExpr',
      '9': 0,
      '10': 'aggregate'
    },
    {'1': 'alias', '3': 3, '4': 1, '5': 9, '10': 'alias'},
  ],
  '8': [
    {'1': 'expression'},
  ],
};

/// Descriptor for `SqlSelectItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlSelectItemDescriptor = $convert.base64Decode(
    'Cg1TcWxTZWxlY3RJdGVtEjMKBmNvbHVtbhgBIAEoCzIZLnF1ZXJhdnVlLnYxLlNxbENvbHVtbl'
    'JlZkgAUgZjb2x1bW4SPQoJYWdncmVnYXRlGAIgASgLMh0ucXVlcmF2dWUudjEuU3FsQWdncmVn'
    'YXRlRXhwckgAUglhZ2dyZWdhdGUSFAoFYWxpYXMYAyABKAlSBWFsaWFzQgwKCmV4cHJlc3Npb2'
    '4=');

@$core.Deprecated('Use sqlLiteralDescriptor instead')
const SqlLiteral$json = {
  '1': 'SqlLiteral',
  '2': [
    {'1': 'null_value', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'nullValue'},
    {'1': 'bool_value', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'boolValue'},
    {'1': 'int_value', '3': 3, '4': 1, '5': 18, '9': 0, '10': 'intValue'},
    {'1': 'double_value', '3': 4, '4': 1, '5': 1, '9': 0, '10': 'doubleValue'},
    {'1': 'string_value', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'stringValue'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `SqlLiteral`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlLiteralDescriptor = $convert.base64Decode(
    'CgpTcWxMaXRlcmFsEh8KCm51bGxfdmFsdWUYASABKAhIAFIJbnVsbFZhbHVlEh8KCmJvb2xfdm'
    'FsdWUYAiABKAhIAFIJYm9vbFZhbHVlEh0KCWludF92YWx1ZRgDIAEoEkgAUghpbnRWYWx1ZRIj'
    'Cgxkb3VibGVfdmFsdWUYBCABKAFIAFILZG91YmxlVmFsdWUSIwoMc3RyaW5nX3ZhbHVlGAUgAS'
    'gJSABSC3N0cmluZ1ZhbHVlQgcKBXZhbHVl');

@$core.Deprecated('Use sqlOperandDescriptor instead')
const SqlOperand$json = {
  '1': 'SqlOperand',
  '2': [
    {
      '1': 'column',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlColumnRef',
      '9': 0,
      '10': 'column'
    },
    {
      '1': 'literal',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlLiteral',
      '9': 0,
      '10': 'literal'
    },
    {
      '1': 'aggregate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlAggregateExpr',
      '9': 0,
      '10': 'aggregate'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `SqlOperand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlOperandDescriptor = $convert.base64Decode(
    'CgpTcWxPcGVyYW5kEjMKBmNvbHVtbhgBIAEoCzIZLnF1ZXJhdnVlLnYxLlNxbENvbHVtblJlZk'
    'gAUgZjb2x1bW4SMwoHbGl0ZXJhbBgCIAEoCzIXLnF1ZXJhdnVlLnYxLlNxbExpdGVyYWxIAFIH'
    'bGl0ZXJhbBI9CglhZ2dyZWdhdGUYAyABKAsyHS5xdWVyYXZ1ZS52MS5TcWxBZ2dyZWdhdGVFeH'
    'BySABSCWFnZ3JlZ2F0ZUIGCgRraW5k');

@$core.Deprecated('Use sqlComparisonDescriptor instead')
const SqlComparison$json = {
  '1': 'SqlComparison',
  '2': [
    {
      '1': 'left',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlOperand',
      '10': 'left'
    },
    {
      '1': 'op',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SqlOperator',
      '10': 'op'
    },
    {
      '1': 'operands',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlOperand',
      '10': 'operands'
    },
    {'1': 'negated', '3': 4, '4': 1, '5': 8, '10': 'negated'},
  ],
};

/// Descriptor for `SqlComparison`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlComparisonDescriptor = $convert.base64Decode(
    'Cg1TcWxDb21wYXJpc29uEisKBGxlZnQYASABKAsyFy5xdWVyYXZ1ZS52MS5TcWxPcGVyYW5kUg'
    'RsZWZ0EigKAm9wGAIgASgOMhgucXVlcmF2dWUudjEuU3FsT3BlcmF0b3JSAm9wEjMKCG9wZXJh'
    'bmRzGAMgAygLMhcucXVlcmF2dWUudjEuU3FsT3BlcmFuZFIIb3BlcmFuZHMSGAoHbmVnYXRlZB'
    'gEIAEoCFIHbmVnYXRlZA==');

@$core.Deprecated('Use sqlConditionGroupDescriptor instead')
const SqlConditionGroup$json = {
  '1': 'SqlConditionGroup',
  '2': [
    {
      '1': 'op',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SqlBoolOp',
      '10': 'op'
    },
    {
      '1': 'children',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.SqlCondition',
      '10': 'children'
    },
    {'1': 'negated', '3': 3, '4': 1, '5': 8, '10': 'negated'},
  ],
};

/// Descriptor for `SqlConditionGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlConditionGroupDescriptor = $convert.base64Decode(
    'ChFTcWxDb25kaXRpb25Hcm91cBImCgJvcBgBIAEoDjIWLnF1ZXJhdnVlLnYxLlNxbEJvb2xPcF'
    'ICb3ASNQoIY2hpbGRyZW4YAiADKAsyGS5xdWVyYXZ1ZS52MS5TcWxDb25kaXRpb25SCGNoaWxk'
    'cmVuEhgKB25lZ2F0ZWQYAyABKAhSB25lZ2F0ZWQ=');

@$core.Deprecated('Use sqlConditionDescriptor instead')
const SqlCondition$json = {
  '1': 'SqlCondition',
  '2': [
    {
      '1': 'comparison',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlComparison',
      '9': 0,
      '10': 'comparison'
    },
    {
      '1': 'group',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlConditionGroup',
      '9': 0,
      '10': 'group'
    },
  ],
  '8': [
    {'1': 'node'},
  ],
};

/// Descriptor for `SqlCondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlConditionDescriptor = $convert.base64Decode(
    'CgxTcWxDb25kaXRpb24SPAoKY29tcGFyaXNvbhgBIAEoCzIaLnF1ZXJhdnVlLnYxLlNxbENvbX'
    'Bhcmlzb25IAFIKY29tcGFyaXNvbhI2CgVncm91cBgCIAEoCzIeLnF1ZXJhdnVlLnYxLlNxbENv'
    'bmRpdGlvbkdyb3VwSABSBWdyb3VwQgYKBG5vZGU=');

@$core.Deprecated('Use sqlOrderTermDescriptor instead')
const SqlOrderTerm$json = {
  '1': 'SqlOrderTerm',
  '2': [
    {
      '1': 'expression',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SqlOperand',
      '10': 'expression'
    },
    {'1': 'descending', '3': 2, '4': 1, '5': 8, '10': 'descending'},
    {
      '1': 'nulls',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SqlNulls',
      '10': 'nulls'
    },
  ],
};

/// Descriptor for `SqlOrderTerm`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sqlOrderTermDescriptor = $convert.base64Decode(
    'CgxTcWxPcmRlclRlcm0SNwoKZXhwcmVzc2lvbhgBIAEoCzIXLnF1ZXJhdnVlLnYxLlNxbE9wZX'
    'JhbmRSCmV4cHJlc3Npb24SHgoKZGVzY2VuZGluZxgCIAEoCFIKZGVzY2VuZGluZxIrCgVudWxs'
    'cxgDIAEoDjIVLnF1ZXJhdnVlLnYxLlNxbE51bGxzUgVudWxscw==');

@$core.Deprecated('Use generateMongoQueryRequestDescriptor instead')
const GenerateMongoQueryRequest$json = {
  '1': 'GenerateMongoQueryRequest',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MongoFindModel',
      '10': 'model'
    },
  ],
};

/// Descriptor for `GenerateMongoQueryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateMongoQueryRequestDescriptor =
    $convert.base64Decode(
        'ChlHZW5lcmF0ZU1vbmdvUXVlcnlSZXF1ZXN0EjEKBW1vZGVsGAEgASgLMhsucXVlcmF2dWUudj'
        'EuTW9uZ29GaW5kTW9kZWxSBW1vZGVs');

@$core.Deprecated('Use generateMongoQueryResponseDescriptor instead')
const GenerateMongoQueryResponse$json = {
  '1': 'GenerateMongoQueryResponse',
  '2': [
    {'1': 'filter_ejson', '3': 1, '4': 1, '5': 9, '10': 'filterEjson'},
    {'1': 'projection_ejson', '3': 2, '4': 1, '5': 9, '10': 'projectionEjson'},
    {'1': 'sort_ejson', '3': 3, '4': 1, '5': 9, '10': 'sortEjson'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.QueryBuilderError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `GenerateMongoQueryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List generateMongoQueryResponseDescriptor = $convert.base64Decode(
    'ChpHZW5lcmF0ZU1vbmdvUXVlcnlSZXNwb25zZRIhCgxmaWx0ZXJfZWpzb24YASABKAlSC2ZpbH'
    'RlckVqc29uEikKEHByb2plY3Rpb25fZWpzb24YAiABKAlSD3Byb2plY3Rpb25FanNvbhIdCgpz'
    'b3J0X2Vqc29uGAMgASgJUglzb3J0RWpzb24SNAoFZXJyb3IYBCABKAsyHi5xdWVyYXZ1ZS52MS'
    '5RdWVyeUJ1aWxkZXJFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use parseMongoQueryRequestDescriptor instead')
const ParseMongoQueryRequest$json = {
  '1': 'ParseMongoQueryRequest',
  '2': [
    {'1': 'filter_ejson', '3': 1, '4': 1, '5': 9, '10': 'filterEjson'},
    {'1': 'projection_ejson', '3': 2, '4': 1, '5': 9, '10': 'projectionEjson'},
    {'1': 'sort_ejson', '3': 3, '4': 1, '5': 9, '10': 'sortEjson'},
  ],
};

/// Descriptor for `ParseMongoQueryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseMongoQueryRequestDescriptor = $convert.base64Decode(
    'ChZQYXJzZU1vbmdvUXVlcnlSZXF1ZXN0EiEKDGZpbHRlcl9lanNvbhgBIAEoCVILZmlsdGVyRW'
    'pzb24SKQoQcHJvamVjdGlvbl9lanNvbhgCIAEoCVIPcHJvamVjdGlvbkVqc29uEh0KCnNvcnRf'
    'ZWpzb24YAyABKAlSCXNvcnRFanNvbg==');

@$core.Deprecated('Use parseMongoQueryResponseDescriptor instead')
const ParseMongoQueryResponse$json = {
  '1': 'ParseMongoQueryResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MongoFindModel',
      '10': 'model'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.QueryBuilderError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `ParseMongoQueryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseMongoQueryResponseDescriptor = $convert.base64Decode(
    'ChdQYXJzZU1vbmdvUXVlcnlSZXNwb25zZRIxCgVtb2RlbBgBIAEoCzIbLnF1ZXJhdnVlLnYxLk'
    '1vbmdvRmluZE1vZGVsUgVtb2RlbBI0CgVlcnJvchgCIAEoCzIeLnF1ZXJhdnVlLnYxLlF1ZXJ5'
    'QnVpbGRlckVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use mongoFindModelDescriptor instead')
const MongoFindModel$json = {
  '1': 'MongoFindModel',
  '2': [
    {
      '1': 'filter',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MongoCondition',
      '10': 'filter'
    },
    {
      '1': 'projection',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MongoProjectionField',
      '10': 'projection'
    },
    {
      '1': 'sort',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MongoSortField',
      '10': 'sort'
    },
  ],
};

/// Descriptor for `MongoFindModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoFindModelDescriptor = $convert.base64Decode(
    'Cg5Nb25nb0ZpbmRNb2RlbBIzCgZmaWx0ZXIYASABKAsyGy5xdWVyYXZ1ZS52MS5Nb25nb0Nvbm'
    'RpdGlvblIGZmlsdGVyEkEKCnByb2plY3Rpb24YAiADKAsyIS5xdWVyYXZ1ZS52MS5Nb25nb1By'
    'b2plY3Rpb25GaWVsZFIKcHJvamVjdGlvbhIvCgRzb3J0GAMgAygLMhsucXVlcmF2dWUudjEuTW'
    '9uZ29Tb3J0RmllbGRSBHNvcnQ=');

@$core.Deprecated('Use mongoConditionGroupDescriptor instead')
const MongoConditionGroup$json = {
  '1': 'MongoConditionGroup',
  '2': [
    {
      '1': 'op',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.MongoBoolOp',
      '10': 'op'
    },
    {
      '1': 'children',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.MongoCondition',
      '10': 'children'
    },
  ],
};

/// Descriptor for `MongoConditionGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoConditionGroupDescriptor = $convert.base64Decode(
    'ChNNb25nb0NvbmRpdGlvbkdyb3VwEigKAm9wGAEgASgOMhgucXVlcmF2dWUudjEuTW9uZ29Cb2'
    '9sT3BSAm9wEjcKCGNoaWxkcmVuGAIgAygLMhsucXVlcmF2dWUudjEuTW9uZ29Db25kaXRpb25S'
    'CGNoaWxkcmVu');

@$core.Deprecated('Use mongoFieldConditionDescriptor instead')
const MongoFieldCondition$json = {
  '1': 'MongoFieldCondition',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'op',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.MongoOperator',
      '10': 'op'
    },
    {'1': 'value_ejson', '3': 3, '4': 1, '5': 9, '10': 'valueEjson'},
    {'1': 'regex_options', '3': 4, '4': 1, '5': 9, '10': 'regexOptions'},
    {'1': 'negated', '3': 5, '4': 1, '5': 8, '10': 'negated'},
  ],
};

/// Descriptor for `MongoFieldCondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoFieldConditionDescriptor = $convert.base64Decode(
    'ChNNb25nb0ZpZWxkQ29uZGl0aW9uEhIKBHBhdGgYASABKAlSBHBhdGgSKgoCb3AYAiABKA4yGi'
    '5xdWVyYXZ1ZS52MS5Nb25nb09wZXJhdG9yUgJvcBIfCgt2YWx1ZV9lanNvbhgDIAEoCVIKdmFs'
    'dWVFanNvbhIjCg1yZWdleF9vcHRpb25zGAQgASgJUgxyZWdleE9wdGlvbnMSGAoHbmVnYXRlZB'
    'gFIAEoCFIHbmVnYXRlZA==');

@$core.Deprecated('Use mongoConditionDescriptor instead')
const MongoCondition$json = {
  '1': 'MongoCondition',
  '2': [
    {
      '1': 'field',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MongoFieldCondition',
      '9': 0,
      '10': 'field'
    },
    {
      '1': 'group',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.MongoConditionGroup',
      '9': 0,
      '10': 'group'
    },
    {'1': 'raw_ejson', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'rawEjson'},
  ],
  '8': [
    {'1': 'node'},
  ],
};

/// Descriptor for `MongoCondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoConditionDescriptor = $convert.base64Decode(
    'Cg5Nb25nb0NvbmRpdGlvbhI4CgVmaWVsZBgBIAEoCzIgLnF1ZXJhdnVlLnYxLk1vbmdvRmllbG'
    'RDb25kaXRpb25IAFIFZmllbGQSOAoFZ3JvdXAYAiABKAsyIC5xdWVyYXZ1ZS52MS5Nb25nb0Nv'
    'bmRpdGlvbkdyb3VwSABSBWdyb3VwEh0KCXJhd19lanNvbhgDIAEoCUgAUghyYXdFanNvbkIGCg'
    'Rub2Rl');

@$core.Deprecated('Use mongoProjectionFieldDescriptor instead')
const MongoProjectionField$json = {
  '1': 'MongoProjectionField',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.MongoProjectionMode',
      '10': 'mode'
    },
  ],
};

/// Descriptor for `MongoProjectionField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoProjectionFieldDescriptor = $convert.base64Decode(
    'ChRNb25nb1Byb2plY3Rpb25GaWVsZBISCgRwYXRoGAEgASgJUgRwYXRoEjQKBG1vZGUYAiABKA'
    '4yIC5xdWVyYXZ1ZS52MS5Nb25nb1Byb2plY3Rpb25Nb2RlUgRtb2Rl');

@$core.Deprecated('Use mongoSortFieldDescriptor instead')
const MongoSortField$json = {
  '1': 'MongoSortField',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'descending', '3': 2, '4': 1, '5': 8, '10': 'descending'},
  ],
};

/// Descriptor for `MongoSortField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mongoSortFieldDescriptor = $convert.base64Decode(
    'Cg5Nb25nb1NvcnRGaWVsZBISCgRwYXRoGAEgASgJUgRwYXRoEh4KCmRlc2NlbmRpbmcYAiABKA'
    'hSCmRlc2NlbmRpbmc=');
