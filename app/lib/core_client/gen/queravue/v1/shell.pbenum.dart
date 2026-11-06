// This is a generated file - do not edit.
//
// Generated from queravue/v1/shell.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// PrintLevel is the console method that produced a print line.
class PrintLevel extends $pb.ProtobufEnum {
  /// Same as LOG.
  static const PrintLevel PRINT_LEVEL_UNSPECIFIED =
      PrintLevel._(0, _omitEnumNames ? '' : 'PRINT_LEVEL_UNSPECIFIED');

  /// print, printjson or console.log.
  static const PrintLevel PRINT_LEVEL_LOG =
      PrintLevel._(1, _omitEnumNames ? '' : 'PRINT_LEVEL_LOG');

  /// console.info.
  static const PrintLevel PRINT_LEVEL_INFO =
      PrintLevel._(2, _omitEnumNames ? '' : 'PRINT_LEVEL_INFO');

  /// console.warn.
  static const PrintLevel PRINT_LEVEL_WARN =
      PrintLevel._(3, _omitEnumNames ? '' : 'PRINT_LEVEL_WARN');

  /// console.error.
  static const PrintLevel PRINT_LEVEL_ERROR =
      PrintLevel._(4, _omitEnumNames ? '' : 'PRINT_LEVEL_ERROR');

  static const $core.List<PrintLevel> values = <PrintLevel>[
    PRINT_LEVEL_UNSPECIFIED,
    PRINT_LEVEL_LOG,
    PRINT_LEVEL_INFO,
    PRINT_LEVEL_WARN,
    PRINT_LEVEL_ERROR,
  ];

  static final $core.List<PrintLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PrintLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrintLevel._(super.value, super.name);
}

/// CursorKind says how a cursor handle is replayed.
class CursorKind extends $pb.ProtobufEnum {
  /// Not set.
  static const CursorKind CURSOR_KIND_UNSPECIFIED =
      CursorKind._(0, _omitEnumNames ? '' : 'CURSOR_KIND_UNSPECIFIED');

  /// A find query: DocumentService.Find can page it.
  static const CursorKind CURSOR_KIND_FIND =
      CursorKind._(1, _omitEnumNames ? '' : 'CURSOR_KIND_FIND');

  /// An aggregate pipeline: only FetchCursor can page it.
  static const CursorKind CURSOR_KIND_AGGREGATE =
      CursorKind._(2, _omitEnumNames ? '' : 'CURSOR_KIND_AGGREGATE');

  static const $core.List<CursorKind> values = <CursorKind>[
    CURSOR_KIND_UNSPECIFIED,
    CURSOR_KIND_FIND,
    CURSOR_KIND_AGGREGATE,
  ];

  static final $core.List<CursorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CursorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CursorKind._(super.value, super.name);
}

/// ShellErrorKind classifies a script failure.
class ShellErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const ShellErrorKind SHELL_ERROR_KIND_UNSPECIFIED =
      ShellErrorKind._(0, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_UNSPECIFIED');

  /// The code does not parse.
  static const ShellErrorKind SHELL_ERROR_KIND_SYNTAX =
      ShellErrorKind._(1, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_SYNTAX');

  /// The script threw.
  static const ShellErrorKind SHELL_ERROR_KIND_RUNTIME =
      ShellErrorKind._(2, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_RUNTIME');

  /// A gated operation on a production connection needs `confirmed`. Nothing
  /// was changed by that operation.
  static const ShellErrorKind SHELL_ERROR_KIND_CONFIRMATION_REQUIRED =
      ShellErrorKind._(
          3, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_CONFIRMATION_REQUIRED');

  /// Output or materialised documents exceeded the cap.
  static const ShellErrorKind SHELL_ERROR_KIND_OUTPUT_LIMIT = ShellErrorKind._(
      4, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_OUTPUT_LIMIT');

  /// The wall-clock timeout was reached.
  static const ShellErrorKind SHELL_ERROR_KIND_TIMEOUT =
      ShellErrorKind._(5, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_TIMEOUT');

  /// The script was cancelled.
  static const ShellErrorKind SHELL_ERROR_KIND_CANCELED =
      ShellErrorKind._(6, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_CANCELED');

  /// The server rejected an operation.
  static const ShellErrorKind SHELL_ERROR_KIND_SERVER =
      ShellErrorKind._(7, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_SERVER');

  /// The script used something the shell does not provide (load, require, an
  /// unsupported method).
  static const ShellErrorKind SHELL_ERROR_KIND_UNSUPPORTED =
      ShellErrorKind._(8, _omitEnumNames ? '' : 'SHELL_ERROR_KIND_UNSUPPORTED');

  static const $core.List<ShellErrorKind> values = <ShellErrorKind>[
    SHELL_ERROR_KIND_UNSPECIFIED,
    SHELL_ERROR_KIND_SYNTAX,
    SHELL_ERROR_KIND_RUNTIME,
    SHELL_ERROR_KIND_CONFIRMATION_REQUIRED,
    SHELL_ERROR_KIND_OUTPUT_LIMIT,
    SHELL_ERROR_KIND_TIMEOUT,
    SHELL_ERROR_KIND_CANCELED,
    SHELL_ERROR_KIND_SERVER,
    SHELL_ERROR_KIND_UNSUPPORTED,
  ];

  static final $core.List<ShellErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static ShellErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ShellErrorKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
