// This is a generated file - do not edit.
//
// Generated from queravue/v1/workspace.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// WorkspaceErrorKind classifies a workspace failure.
class WorkspaceErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_UNSPECIFIED =
      WorkspaceErrorKind._(
          0, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_UNSPECIFIED');

  /// The path resolves outside its root (.. or a symlink).
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT =
      WorkspaceErrorKind._(
          1, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT');

  /// The root or path does not exist.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_NOT_FOUND =
      WorkspaceErrorKind._(
          2, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_NOT_FOUND');

  /// The target path already exists.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_ALREADY_EXISTS =
      WorkspaceErrorKind._(
          3, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_ALREADY_EXISTS');

  /// The file changed on disk since it was read. WorkspaceError.current holds
  /// the file as it is now.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_CONFLICT =
      WorkspaceErrorKind._(
          4, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_CONFLICT');

  /// The file is larger than the size cap.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_TOO_LARGE =
      WorkspaceErrorKind._(
          5, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_TOO_LARGE');

  /// Any other file system failure.
  static const WorkspaceErrorKind WORKSPACE_ERROR_KIND_IO =
      WorkspaceErrorKind._(6, _omitEnumNames ? '' : 'WORKSPACE_ERROR_KIND_IO');

  static const $core.List<WorkspaceErrorKind> values = <WorkspaceErrorKind>[
    WORKSPACE_ERROR_KIND_UNSPECIFIED,
    WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT,
    WORKSPACE_ERROR_KIND_NOT_FOUND,
    WORKSPACE_ERROR_KIND_ALREADY_EXISTS,
    WORKSPACE_ERROR_KIND_CONFLICT,
    WORKSPACE_ERROR_KIND_TOO_LARGE,
    WORKSPACE_ERROR_KIND_IO,
  ];

  static final $core.List<WorkspaceErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static WorkspaceErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WorkspaceErrorKind._(super.value, super.name);
}

/// FileKind says what a file is for.
class FileKind extends $pb.ProtobufEnum {
  /// Not a script.
  static const FileKind FILE_KIND_UNSPECIFIED =
      FileKind._(0, _omitEnumNames ? '' : 'FILE_KIND_UNSPECIFIED');

  /// A .sql query.
  static const FileKind FILE_KIND_SQL =
      FileKind._(1, _omitEnumNames ? '' : 'FILE_KIND_SQL');

  /// A .mongo.js script.
  static const FileKind FILE_KIND_MONGO =
      FileKind._(2, _omitEnumNames ? '' : 'FILE_KIND_MONGO');

  static const $core.List<FileKind> values = <FileKind>[
    FILE_KIND_UNSPECIFIED,
    FILE_KIND_SQL,
    FILE_KIND_MONGO,
  ];

  static final $core.List<FileKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static FileKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FileKind._(super.value, super.name);
}

/// ChangeKind is what happened to a path.
class ChangeKind extends $pb.ProtobufEnum {
  /// Not set.
  static const ChangeKind CHANGE_KIND_UNSPECIFIED =
      ChangeKind._(0, _omitEnumNames ? '' : 'CHANGE_KIND_UNSPECIFIED');

  /// A file or folder appeared.
  static const ChangeKind CHANGE_KIND_CREATED =
      ChangeKind._(1, _omitEnumNames ? '' : 'CHANGE_KIND_CREATED');

  /// A file's content changed.
  static const ChangeKind CHANGE_KIND_MODIFIED =
      ChangeKind._(2, _omitEnumNames ? '' : 'CHANGE_KIND_MODIFIED');

  /// A file or folder disappeared.
  static const ChangeKind CHANGE_KIND_DELETED =
      ChangeKind._(3, _omitEnumNames ? '' : 'CHANGE_KIND_DELETED');

  /// A file or folder was renamed. `path` is the new name.
  static const ChangeKind CHANGE_KIND_RENAMED =
      ChangeKind._(4, _omitEnumNames ? '' : 'CHANGE_KIND_RENAMED');

  static const $core.List<ChangeKind> values = <ChangeKind>[
    CHANGE_KIND_UNSPECIFIED,
    CHANGE_KIND_CREATED,
    CHANGE_KIND_MODIFIED,
    CHANGE_KIND_DELETED,
    CHANGE_KIND_RENAMED,
  ];

  static final $core.List<ChangeKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ChangeKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ChangeKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
