// This is a generated file - do not edit.
//
// Generated from queravue/v1/completion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// CompletionContextKind says what kind of text is being completed.
class CompletionContextKind extends $pb.ProtobufEnum {
  /// Unspecified. Rejected as INVALID.
  static const CompletionContextKind COMPLETION_CONTEXT_KIND_UNSPECIFIED =
      CompletionContextKind._(
          0, _omitEnumNames ? '' : 'COMPLETION_CONTEXT_KIND_UNSPECIFIED');

  /// A SQL statement in the SQL editor.
  static const CompletionContextKind COMPLETION_CONTEXT_KIND_SQL =
      CompletionContextKind._(
          1, _omitEnumNames ? '' : 'COMPLETION_CONTEXT_KIND_SQL');

  /// JavaScript in the Mongo shell.
  static const CompletionContextKind COMPLETION_CONTEXT_KIND_SHELL =
      CompletionContextKind._(
          2, _omitEnumNames ? '' : 'COMPLETION_CONTEXT_KIND_SHELL');

  /// EJSON in the Mongo filter, sort or projection inputs.
  static const CompletionContextKind COMPLETION_CONTEXT_KIND_MONGO_QUERY =
      CompletionContextKind._(
          3, _omitEnumNames ? '' : 'COMPLETION_CONTEXT_KIND_MONGO_QUERY');

  static const $core.List<CompletionContextKind> values =
      <CompletionContextKind>[
    COMPLETION_CONTEXT_KIND_UNSPECIFIED,
    COMPLETION_CONTEXT_KIND_SQL,
    COMPLETION_CONTEXT_KIND_SHELL,
    COMPLETION_CONTEXT_KIND_MONGO_QUERY,
  ];

  static final $core.List<CompletionContextKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CompletionContextKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CompletionContextKind._(super.value, super.name);
}

/// CompletionItemKind selects the icon and tells the UI what the item is.
class CompletionItemKind extends $pb.ProtobufEnum {
  /// Unspecified.
  static const CompletionItemKind COMPLETION_ITEM_KIND_UNSPECIFIED =
      CompletionItemKind._(
          0, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_UNSPECIFIED');

  /// A SQL or shell keyword.
  static const CompletionItemKind COMPLETION_ITEM_KIND_KEYWORD =
      CompletionItemKind._(
          1, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_KEYWORD');

  /// A function.
  static const CompletionItemKind COMPLETION_ITEM_KIND_FUNCTION =
      CompletionItemKind._(
          2, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_FUNCTION');

  /// A table.
  static const CompletionItemKind COMPLETION_ITEM_KIND_TABLE =
      CompletionItemKind._(
          3, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_TABLE');

  /// A view or materialized view.
  static const CompletionItemKind COMPLETION_ITEM_KIND_VIEW =
      CompletionItemKind._(
          4, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_VIEW');

  /// A column.
  static const CompletionItemKind COMPLETION_ITEM_KIND_COLUMN =
      CompletionItemKind._(
          5, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_COLUMN');

  /// A schema.
  static const CompletionItemKind COMPLETION_ITEM_KIND_SCHEMA =
      CompletionItemKind._(
          6, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_SCHEMA');

  /// A database.
  static const CompletionItemKind COMPLETION_ITEM_KIND_DATABASE =
      CompletionItemKind._(
          7, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_DATABASE');

  /// A table alias or CTE name defined in the statement.
  static const CompletionItemKind COMPLETION_ITEM_KIND_ALIAS =
      CompletionItemKind._(
          8, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_ALIAS');

  /// A Mongo collection.
  static const CompletionItemKind COMPLETION_ITEM_KIND_COLLECTION =
      CompletionItemKind._(
          9, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_COLLECTION');

  /// A Mongo field path.
  static const CompletionItemKind COMPLETION_ITEM_KIND_FIELD =
      CompletionItemKind._(
          10, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_FIELD');

  /// A Mongo query or update operator such as $in.
  static const CompletionItemKind COMPLETION_ITEM_KIND_OPERATOR =
      CompletionItemKind._(
          11, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_OPERATOR');

  /// A collection or cursor method in the shell.
  static const CompletionItemKind COMPLETION_ITEM_KIND_METHOD =
      CompletionItemKind._(
          12, _omitEnumNames ? '' : 'COMPLETION_ITEM_KIND_METHOD');

  static const $core.List<CompletionItemKind> values = <CompletionItemKind>[
    COMPLETION_ITEM_KIND_UNSPECIFIED,
    COMPLETION_ITEM_KIND_KEYWORD,
    COMPLETION_ITEM_KIND_FUNCTION,
    COMPLETION_ITEM_KIND_TABLE,
    COMPLETION_ITEM_KIND_VIEW,
    COMPLETION_ITEM_KIND_COLUMN,
    COMPLETION_ITEM_KIND_SCHEMA,
    COMPLETION_ITEM_KIND_DATABASE,
    COMPLETION_ITEM_KIND_ALIAS,
    COMPLETION_ITEM_KIND_COLLECTION,
    COMPLETION_ITEM_KIND_FIELD,
    COMPLETION_ITEM_KIND_OPERATOR,
    COMPLETION_ITEM_KIND_METHOD,
  ];

  static final $core.List<CompletionItemKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static CompletionItemKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CompletionItemKind._(super.value, super.name);
}

/// CatalogState tells how much of the schema catalog is loaded.
class CatalogState extends $pb.ProtobufEnum {
  /// Unspecified, for example Mongo contexts without a catalog.
  static const CatalogState CATALOG_STATE_UNSPECIFIED =
      CatalogState._(0, _omitEnumNames ? '' : 'CATALOG_STATE_UNSPECIFIED');

  /// Nothing loaded yet; only the object list may be available.
  static const CatalogState CATALOG_STATE_COLD =
      CatalogState._(1, _omitEnumNames ? '' : 'CATALOG_STATE_COLD');

  /// Columns are still arriving; the UI shows a loading hint.
  static const CatalogState CATALOG_STATE_WARMING =
      CatalogState._(2, _omitEnumNames ? '' : 'CATALOG_STATE_WARMING');

  /// All columns are cached.
  static const CatalogState CATALOG_STATE_READY =
      CatalogState._(3, _omitEnumNames ? '' : 'CATALOG_STATE_READY');

  static const $core.List<CatalogState> values = <CatalogState>[
    CATALOG_STATE_UNSPECIFIED,
    CATALOG_STATE_COLD,
    CATALOG_STATE_WARMING,
    CATALOG_STATE_READY,
  ];

  static final $core.List<CatalogState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CatalogState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CatalogState._(super.value, super.name);
}

/// KeywordCase selects how keywords are written.
class KeywordCase extends $pb.ProtobufEnum {
  /// Use the default, upper case.
  static const KeywordCase KEYWORD_CASE_UNSPECIFIED =
      KeywordCase._(0, _omitEnumNames ? '' : 'KEYWORD_CASE_UNSPECIFIED');

  /// SELECT
  static const KeywordCase KEYWORD_CASE_UPPER =
      KeywordCase._(1, _omitEnumNames ? '' : 'KEYWORD_CASE_UPPER');

  /// select
  static const KeywordCase KEYWORD_CASE_LOWER =
      KeywordCase._(2, _omitEnumNames ? '' : 'KEYWORD_CASE_LOWER');

  /// Leave keywords as written.
  static const KeywordCase KEYWORD_CASE_PRESERVE =
      KeywordCase._(3, _omitEnumNames ? '' : 'KEYWORD_CASE_PRESERVE');

  static const $core.List<KeywordCase> values = <KeywordCase>[
    KEYWORD_CASE_UNSPECIFIED,
    KEYWORD_CASE_UPPER,
    KEYWORD_CASE_LOWER,
    KEYWORD_CASE_PRESERVE,
  ];

  static final $core.List<KeywordCase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static KeywordCase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KeywordCase._(super.value, super.name);
}

/// CommaStyle selects where commas go in lists that span lines.
class CommaStyle extends $pb.ProtobufEnum {
  /// Use the default, trailing.
  static const CommaStyle COMMA_STYLE_UNSPECIFIED =
      CommaStyle._(0, _omitEnumNames ? '' : 'COMMA_STYLE_UNSPECIFIED');

  /// a,
  /// b
  static const CommaStyle COMMA_STYLE_TRAILING =
      CommaStyle._(1, _omitEnumNames ? '' : 'COMMA_STYLE_TRAILING');

  /// a
  /// , b
  static const CommaStyle COMMA_STYLE_LEADING =
      CommaStyle._(2, _omitEnumNames ? '' : 'COMMA_STYLE_LEADING');

  static const $core.List<CommaStyle> values = <CommaStyle>[
    COMMA_STYLE_UNSPECIFIED,
    COMMA_STYLE_TRAILING,
    COMMA_STYLE_LEADING,
  ];

  static final $core.List<CommaStyle?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CommaStyle? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CommaStyle._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
