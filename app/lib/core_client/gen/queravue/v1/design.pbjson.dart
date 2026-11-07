// This is a generated file - do not edit.
//
// Generated from queravue/v1/design.proto.

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

@$core.Deprecated('Use columnSpecDescriptor instead')
const ColumnSpec$json = {
  '1': 'ColumnSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type_name', '3': 2, '4': 1, '5': 9, '10': 'typeName'},
    {'1': 'nullable', '3': 3, '4': 1, '5': 8, '10': 'nullable'},
    {
      '1': 'default_expression',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'defaultExpression',
      '17': true
    },
    {'1': 'identity', '3': 5, '4': 1, '5': 8, '10': 'identity'},
    {
      '1': 'collation',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'collation',
      '17': true
    },
  ],
  '8': [
    {'1': '_default_expression'},
    {'1': '_collation'},
  ],
};

/// Descriptor for `ColumnSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnSpecDescriptor = $convert.base64Decode(
    'CgpDb2x1bW5TcGVjEhIKBG5hbWUYASABKAlSBG5hbWUSGwoJdHlwZV9uYW1lGAIgASgJUgh0eX'
    'BlTmFtZRIaCghudWxsYWJsZRgDIAEoCFIIbnVsbGFibGUSMgoSZGVmYXVsdF9leHByZXNzaW9u'
    'GAQgASgJSABSEWRlZmF1bHRFeHByZXNzaW9uiAEBEhoKCGlkZW50aXR5GAUgASgIUghpZGVudG'
    'l0eRIhCgljb2xsYXRpb24YBiABKAlIAVIJY29sbGF0aW9uiAEBQhUKE19kZWZhdWx0X2V4cHJl'
    'c3Npb25CDAoKX2NvbGxhdGlvbg==');

@$core.Deprecated('Use foreignKeySpecDescriptor instead')
const ForeignKeySpec$json = {
  '1': 'ForeignKeySpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'columns', '3': 2, '4': 3, '5': 9, '10': 'columns'},
    {
      '1': 'referenced_table',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableRef',
      '10': 'referencedTable'
    },
    {
      '1': 'referenced_columns',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'referencedColumns'
    },
    {
      '1': 'on_delete',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ReferentialAction',
      '10': 'onDelete'
    },
    {
      '1': 'on_update',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ReferentialAction',
      '10': 'onUpdate'
    },
  ],
};

/// Descriptor for `ForeignKeySpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List foreignKeySpecDescriptor = $convert.base64Decode(
    'Cg5Gb3JlaWduS2V5U3BlYxISCgRuYW1lGAEgASgJUgRuYW1lEhgKB2NvbHVtbnMYAiADKAlSB2'
    'NvbHVtbnMSQAoQcmVmZXJlbmNlZF90YWJsZRgDIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVm'
    'Ug9yZWZlcmVuY2VkVGFibGUSLQoScmVmZXJlbmNlZF9jb2x1bW5zGAQgAygJUhFyZWZlcmVuY2'
    'VkQ29sdW1ucxI7Cglvbl9kZWxldGUYBSABKA4yHi5xdWVyYXZ1ZS52MS5SZWZlcmVudGlhbEFj'
    'dGlvblIIb25EZWxldGUSOwoJb25fdXBkYXRlGAYgASgOMh4ucXVlcmF2dWUudjEuUmVmZXJlbn'
    'RpYWxBY3Rpb25SCG9uVXBkYXRl');

@$core.Deprecated('Use uniqueSpecDescriptor instead')
const UniqueSpec$json = {
  '1': 'UniqueSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'columns', '3': 2, '4': 3, '5': 9, '10': 'columns'},
  ],
};

/// Descriptor for `UniqueSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uniqueSpecDescriptor = $convert.base64Decode(
    'CgpVbmlxdWVTcGVjEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHY29sdW1ucxgCIAMoCVIHY29sdW'
    '1ucw==');

@$core.Deprecated('Use checkSpecDescriptor instead')
const CheckSpec$json = {
  '1': 'CheckSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'expression', '3': 2, '4': 1, '5': 9, '10': 'expression'},
  ],
};

/// Descriptor for `CheckSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkSpecDescriptor = $convert.base64Decode(
    'CglDaGVja1NwZWMSEgoEbmFtZRgBIAEoCVIEbmFtZRIeCgpleHByZXNzaW9uGAIgASgJUgpleH'
    'ByZXNzaW9u');

@$core.Deprecated('Use tableDesignDescriptor instead')
const TableDesign$json = {
  '1': 'TableDesign',
  '2': [
    {
      '1': 'columns',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ColumnSpec',
      '10': 'columns'
    },
    {'1': 'primary_key_name', '3': 2, '4': 1, '5': 9, '10': 'primaryKeyName'},
    {
      '1': 'primary_key_columns',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'primaryKeyColumns'
    },
    {
      '1': 'uniques',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.UniqueSpec',
      '10': 'uniques'
    },
    {
      '1': 'checks',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.CheckSpec',
      '10': 'checks'
    },
    {
      '1': 'foreign_keys',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ForeignKeySpec',
      '10': 'foreignKeys'
    },
    {
      '1': 'indexes',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.IndexSpec',
      '10': 'indexes'
    },
  ],
};

/// Descriptor for `TableDesign`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableDesignDescriptor = $convert.base64Decode(
    'CgtUYWJsZURlc2lnbhIxCgdjb2x1bW5zGAEgAygLMhcucXVlcmF2dWUudjEuQ29sdW1uU3BlY1'
    'IHY29sdW1ucxIoChBwcmltYXJ5X2tleV9uYW1lGAIgASgJUg5wcmltYXJ5S2V5TmFtZRIuChNw'
    'cmltYXJ5X2tleV9jb2x1bW5zGAMgAygJUhFwcmltYXJ5S2V5Q29sdW1ucxIxCgd1bmlxdWVzGA'
    'QgAygLMhcucXVlcmF2dWUudjEuVW5pcXVlU3BlY1IHdW5pcXVlcxIuCgZjaGVja3MYBSADKAsy'
    'Fi5xdWVyYXZ1ZS52MS5DaGVja1NwZWNSBmNoZWNrcxI+Cgxmb3JlaWduX2tleXMYBiADKAsyGy'
    '5xdWVyYXZ1ZS52MS5Gb3JlaWduS2V5U3BlY1ILZm9yZWlnbktleXMSMAoHaW5kZXhlcxgHIAMo'
    'CzIWLnF1ZXJhdnVlLnYxLkluZGV4U3BlY1IHaW5kZXhlcw==');

@$core.Deprecated('Use createTableDescriptor instead')
const CreateTable$json = {
  '1': 'CreateTable',
  '2': [
    {
      '1': 'design',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TableDesign',
      '10': 'design'
    },
  ],
};

/// Descriptor for `CreateTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTableDescriptor = $convert.base64Decode(
    'CgtDcmVhdGVUYWJsZRIwCgZkZXNpZ24YASABKAsyGC5xdWVyYXZ1ZS52MS5UYWJsZURlc2lnbl'
    'IGZGVzaWdu');

@$core.Deprecated('Use dropTableDescriptor instead')
const DropTable$json = {
  '1': 'DropTable',
};

/// Descriptor for `DropTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropTableDescriptor =
    $convert.base64Decode('CglEcm9wVGFibGU=');

@$core.Deprecated('Use renameTableDescriptor instead')
const RenameTable$json = {
  '1': 'RenameTable',
  '2': [
    {'1': 'new_name', '3': 1, '4': 1, '5': 9, '10': 'newName'},
  ],
};

/// Descriptor for `RenameTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameTableDescriptor = $convert
    .base64Decode('CgtSZW5hbWVUYWJsZRIZCghuZXdfbmFtZRgBIAEoCVIHbmV3TmFtZQ==');

@$core.Deprecated('Use addColumnDescriptor instead')
const AddColumn$json = {
  '1': 'AddColumn',
  '2': [
    {
      '1': 'column',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ColumnSpec',
      '10': 'column'
    },
  ],
};

/// Descriptor for `AddColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addColumnDescriptor = $convert.base64Decode(
    'CglBZGRDb2x1bW4SLwoGY29sdW1uGAEgASgLMhcucXVlcmF2dWUudjEuQ29sdW1uU3BlY1IGY2'
    '9sdW1u');

@$core.Deprecated('Use dropColumnDescriptor instead')
const DropColumn$json = {
  '1': 'DropColumn',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DropColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropColumnDescriptor =
    $convert.base64Decode('CgpEcm9wQ29sdW1uEhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use renameColumnDescriptor instead')
const RenameColumn$json = {
  '1': 'RenameColumn',
  '2': [
    {'1': 'from', '3': 1, '4': 1, '5': 9, '10': 'from'},
    {'1': 'to', '3': 2, '4': 1, '5': 9, '10': 'to'},
  ],
};

/// Descriptor for `RenameColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameColumnDescriptor = $convert.base64Decode(
    'CgxSZW5hbWVDb2x1bW4SEgoEZnJvbRgBIAEoCVIEZnJvbRIOCgJ0bxgCIAEoCVICdG8=');

@$core.Deprecated('Use alterColumnDescriptor instead')
const AlterColumn$json = {
  '1': 'AlterColumn',
  '2': [
    {
      '1': 'before',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ColumnSpec',
      '10': 'before'
    },
    {
      '1': 'after',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ColumnSpec',
      '10': 'after'
    },
  ],
};

/// Descriptor for `AlterColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alterColumnDescriptor = $convert.base64Decode(
    'CgtBbHRlckNvbHVtbhIvCgZiZWZvcmUYASABKAsyFy5xdWVyYXZ1ZS52MS5Db2x1bW5TcGVjUg'
    'ZiZWZvcmUSLQoFYWZ0ZXIYAiABKAsyFy5xdWVyYXZ1ZS52MS5Db2x1bW5TcGVjUgVhZnRlcg==');

@$core.Deprecated('Use addForeignKeyDescriptor instead')
const AddForeignKey$json = {
  '1': 'AddForeignKey',
  '2': [
    {
      '1': 'foreign_key',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ForeignKeySpec',
      '10': 'foreignKey'
    },
  ],
};

/// Descriptor for `AddForeignKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addForeignKeyDescriptor = $convert.base64Decode(
    'Cg1BZGRGb3JlaWduS2V5EjwKC2ZvcmVpZ25fa2V5GAEgASgLMhsucXVlcmF2dWUudjEuRm9yZW'
    'lnbktleVNwZWNSCmZvcmVpZ25LZXk=');

@$core.Deprecated('Use addUniqueDescriptor instead')
const AddUnique$json = {
  '1': 'AddUnique',
  '2': [
    {
      '1': 'unique',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.UniqueSpec',
      '10': 'unique'
    },
  ],
};

/// Descriptor for `AddUnique`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addUniqueDescriptor = $convert.base64Decode(
    'CglBZGRVbmlxdWUSLwoGdW5pcXVlGAEgASgLMhcucXVlcmF2dWUudjEuVW5pcXVlU3BlY1IGdW'
    '5pcXVl');

@$core.Deprecated('Use addCheckDescriptor instead')
const AddCheck$json = {
  '1': 'AddCheck',
  '2': [
    {
      '1': 'check',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CheckSpec',
      '10': 'check'
    },
  ],
};

/// Descriptor for `AddCheck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addCheckDescriptor = $convert.base64Decode(
    'CghBZGRDaGVjaxIsCgVjaGVjaxgBIAEoCzIWLnF1ZXJhdnVlLnYxLkNoZWNrU3BlY1IFY2hlY2'
    's=');

@$core.Deprecated('Use dropConstraintDescriptor instead')
const DropConstraint$json = {
  '1': 'DropConstraint',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DropConstraint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropConstraintDescriptor =
    $convert.base64Decode('Cg5Ecm9wQ29uc3RyYWludBISCgRuYW1lGAEgASgJUgRuYW1l');

@$core.Deprecated('Use addIndexDescriptor instead')
const AddIndex$json = {
  '1': 'AddIndex',
  '2': [
    {
      '1': 'index',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.IndexSpec',
      '10': 'index'
    },
  ],
};

/// Descriptor for `AddIndex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addIndexDescriptor = $convert.base64Decode(
    'CghBZGRJbmRleBIsCgVpbmRleBgBIAEoCzIWLnF1ZXJhdnVlLnYxLkluZGV4U3BlY1IFaW5kZX'
    'g=');

@$core.Deprecated('Use dropIndexChangeDescriptor instead')
const DropIndexChange$json = {
  '1': 'DropIndexChange',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DropIndexChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropIndexChangeDescriptor = $convert
    .base64Decode('Cg9Ecm9wSW5kZXhDaGFuZ2USEgoEbmFtZRgBIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use schemaChangeDescriptor instead')
const SchemaChange$json = {
  '1': 'SchemaChange',
  '2': [
    {
      '1': 'create_table',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.CreateTable',
      '9': 0,
      '10': 'createTable'
    },
    {
      '1': 'drop_table',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DropTable',
      '9': 0,
      '10': 'dropTable'
    },
    {
      '1': 'rename_table',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RenameTable',
      '9': 0,
      '10': 'renameTable'
    },
    {
      '1': 'add_column',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AddColumn',
      '9': 0,
      '10': 'addColumn'
    },
    {
      '1': 'drop_column',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DropColumn',
      '9': 0,
      '10': 'dropColumn'
    },
    {
      '1': 'rename_column',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.RenameColumn',
      '9': 0,
      '10': 'renameColumn'
    },
    {
      '1': 'alter_column',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AlterColumn',
      '9': 0,
      '10': 'alterColumn'
    },
    {
      '1': 'add_foreign_key',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AddForeignKey',
      '9': 0,
      '10': 'addForeignKey'
    },
    {
      '1': 'add_unique',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AddUnique',
      '9': 0,
      '10': 'addUnique'
    },
    {
      '1': 'add_check',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AddCheck',
      '9': 0,
      '10': 'addCheck'
    },
    {
      '1': 'drop_constraint',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DropConstraint',
      '9': 0,
      '10': 'dropConstraint'
    },
    {
      '1': 'add_index',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.AddIndex',
      '9': 0,
      '10': 'addIndex'
    },
    {
      '1': 'drop_index',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.DropIndexChange',
      '9': 0,
      '10': 'dropIndex'
    },
  ],
  '8': [
    {'1': 'change'},
  ],
};

/// Descriptor for `SchemaChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaChangeDescriptor = $convert.base64Decode(
    'CgxTY2hlbWFDaGFuZ2USPQoMY3JlYXRlX3RhYmxlGAEgASgLMhgucXVlcmF2dWUudjEuQ3JlYX'
    'RlVGFibGVIAFILY3JlYXRlVGFibGUSNwoKZHJvcF90YWJsZRgCIAEoCzIWLnF1ZXJhdnVlLnYx'
    'LkRyb3BUYWJsZUgAUglkcm9wVGFibGUSPQoMcmVuYW1lX3RhYmxlGAMgASgLMhgucXVlcmF2dW'
    'UudjEuUmVuYW1lVGFibGVIAFILcmVuYW1lVGFibGUSNwoKYWRkX2NvbHVtbhgEIAEoCzIWLnF1'
    'ZXJhdnVlLnYxLkFkZENvbHVtbkgAUglhZGRDb2x1bW4SOgoLZHJvcF9jb2x1bW4YBSABKAsyFy'
    '5xdWVyYXZ1ZS52MS5Ecm9wQ29sdW1uSABSCmRyb3BDb2x1bW4SQAoNcmVuYW1lX2NvbHVtbhgG'
    'IAEoCzIZLnF1ZXJhdnVlLnYxLlJlbmFtZUNvbHVtbkgAUgxyZW5hbWVDb2x1bW4SPQoMYWx0ZX'
    'JfY29sdW1uGAcgASgLMhgucXVlcmF2dWUudjEuQWx0ZXJDb2x1bW5IAFILYWx0ZXJDb2x1bW4S'
    'RAoPYWRkX2ZvcmVpZ25fa2V5GAggASgLMhoucXVlcmF2dWUudjEuQWRkRm9yZWlnbktleUgAUg'
    '1hZGRGb3JlaWduS2V5EjcKCmFkZF91bmlxdWUYCSABKAsyFi5xdWVyYXZ1ZS52MS5BZGRVbmlx'
    'dWVIAFIJYWRkVW5pcXVlEjQKCWFkZF9jaGVjaxgKIAEoCzIVLnF1ZXJhdnVlLnYxLkFkZENoZW'
    'NrSABSCGFkZENoZWNrEkYKD2Ryb3BfY29uc3RyYWludBgLIAEoCzIbLnF1ZXJhdnVlLnYxLkRy'
    'b3BDb25zdHJhaW50SABSDmRyb3BDb25zdHJhaW50EjQKCWFkZF9pbmRleBgMIAEoCzIVLnF1ZX'
    'JhdnVlLnYxLkFkZEluZGV4SABSCGFkZEluZGV4Ej0KCmRyb3BfaW5kZXgYDSABKAsyHC5xdWVy'
    'YXZ1ZS52MS5Ecm9wSW5kZXhDaGFuZ2VIAFIJZHJvcEluZGV4QggKBmNoYW5nZQ==');

@$core.Deprecated('Use ddlStatementDescriptor instead')
const DdlStatement$json = {
  '1': 'DdlStatement',
  '2': [
    {'1': 'sql', '3': 1, '4': 1, '5': 9, '10': 'sql'},
    {'1': 'destructive', '3': 2, '4': 1, '5': 8, '10': 'destructive'},
    {'1': 'summary', '3': 3, '4': 1, '5': 9, '10': 'summary'},
  ],
};

/// Descriptor for `DdlStatement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ddlStatementDescriptor = $convert.base64Decode(
    'CgxEZGxTdGF0ZW1lbnQSEAoDc3FsGAEgASgJUgNzcWwSIAoLZGVzdHJ1Y3RpdmUYAiABKAhSC2'
    'Rlc3RydWN0aXZlEhgKB3N1bW1hcnkYAyABKAlSB3N1bW1hcnk=');

@$core.Deprecated('Use previewDDLRequestDescriptor instead')
const PreviewDDLRequest$json = {
  '1': 'PreviewDDLRequest',
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
      '6': '.queravue.v1.SchemaChange',
      '10': 'changes'
    },
  ],
};

/// Descriptor for `PreviewDDLRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewDDLRequestDescriptor = $convert.base64Decode(
    'ChFQcmV2aWV3RERMUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSMgoJdG'
    'FibGVfcmVmGAIgASgLMhUucXVlcmF2dWUudjEuVGFibGVSZWZSCHRhYmxlUmVmEjMKB2NoYW5n'
    'ZXMYAyADKAsyGS5xdWVyYXZ1ZS52MS5TY2hlbWFDaGFuZ2VSB2NoYW5nZXM=');

@$core.Deprecated('Use previewDDLResponseDescriptor instead')
const PreviewDDLResponse$json = {
  '1': 'PreviewDDLResponse',
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

/// Descriptor for `PreviewDDLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewDDLResponseDescriptor = $convert.base64Decode(
    'ChJQcmV2aWV3RERMUmVzcG9uc2USOQoKc3RhdGVtZW50cxgBIAMoCzIZLnF1ZXJhdnVlLnYxLk'
    'RkbFN0YXRlbWVudFIKc3RhdGVtZW50cxIaCgh3YXJuaW5ncxgCIAMoCVIId2FybmluZ3MSJAoN'
    'dHJhbnNhY3Rpb25hbBgDIAEoCFINdHJhbnNhY3Rpb25hbBItCgVlcnJvchgEIAEoCzIXLnF1ZX'
    'JhdnVlLnYxLkFkbWluRXJyb3JSBWVycm9y');

@$core.Deprecated('Use applyDDLRequestDescriptor instead')
const ApplyDDLRequest$json = {
  '1': 'ApplyDDLRequest',
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
      '6': '.queravue.v1.SchemaChange',
      '10': 'changes'
    },
    {'1': 'confirmed', '3': 4, '4': 1, '5': 8, '10': 'confirmed'},
  ],
};

/// Descriptor for `ApplyDDLRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyDDLRequestDescriptor = $convert.base64Decode(
    'Cg9BcHBseURETFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEjIKCXRhYm'
    'xlX3JlZhgCIAEoCzIVLnF1ZXJhdnVlLnYxLlRhYmxlUmVmUgh0YWJsZVJlZhIzCgdjaGFuZ2Vz'
    'GAMgAygLMhkucXVlcmF2dWUudjEuU2NoZW1hQ2hhbmdlUgdjaGFuZ2VzEhwKCWNvbmZpcm1lZB'
    'gEIAEoCFIJY29uZmlybWVk');

@$core.Deprecated('Use applyDDLResponseDescriptor instead')
const ApplyDDLResponse$json = {
  '1': 'ApplyDDLResponse',
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

/// Descriptor for `ApplyDDLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyDDLResponseDescriptor = $convert.base64Decode(
    'ChBBcHBseURETFJlc3BvbnNlEjkKCnN0YXRlbWVudHMYASADKAsyGS5xdWVyYXZ1ZS52MS5EZG'
    'xTdGF0ZW1lbnRSCnN0YXRlbWVudHMSLwoTZXhlY3V0ZWRfc3RhdGVtZW50cxgCIAEoDVISZXhl'
    'Y3V0ZWRTdGF0ZW1lbnRzEiQKDXRyYW5zYWN0aW9uYWwYAyABKAhSDXRyYW5zYWN0aW9uYWwSLQ'
    'oFZXJyb3IYBCABKAsyFy5xdWVyYXZ1ZS52MS5BZG1pbkVycm9yUgVlcnJvcg==');
