// This is a generated file - do not edit.
//
// Generated from queravue/v1/connections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ColorTag is the color dot shown next to a connection, e.g. red for prod.
class ColorTag extends $pb.ProtobufEnum {
  /// No color.
  static const ColorTag COLOR_TAG_UNSPECIFIED =
      ColorTag._(0, _omitEnumNames ? '' : 'COLOR_TAG_UNSPECIFIED');

  /// Red.
  static const ColorTag COLOR_TAG_RED =
      ColorTag._(1, _omitEnumNames ? '' : 'COLOR_TAG_RED');

  /// Orange.
  static const ColorTag COLOR_TAG_ORANGE =
      ColorTag._(2, _omitEnumNames ? '' : 'COLOR_TAG_ORANGE');

  /// Yellow.
  static const ColorTag COLOR_TAG_YELLOW =
      ColorTag._(3, _omitEnumNames ? '' : 'COLOR_TAG_YELLOW');

  /// Green.
  static const ColorTag COLOR_TAG_GREEN =
      ColorTag._(4, _omitEnumNames ? '' : 'COLOR_TAG_GREEN');

  /// Blue.
  static const ColorTag COLOR_TAG_BLUE =
      ColorTag._(5, _omitEnumNames ? '' : 'COLOR_TAG_BLUE');

  /// Purple.
  static const ColorTag COLOR_TAG_PURPLE =
      ColorTag._(6, _omitEnumNames ? '' : 'COLOR_TAG_PURPLE');

  /// Gray.
  static const ColorTag COLOR_TAG_GRAY =
      ColorTag._(7, _omitEnumNames ? '' : 'COLOR_TAG_GRAY');

  static const $core.List<ColorTag> values = <ColorTag>[
    COLOR_TAG_UNSPECIFIED,
    COLOR_TAG_RED,
    COLOR_TAG_ORANGE,
    COLOR_TAG_YELLOW,
    COLOR_TAG_GREEN,
    COLOR_TAG_BLUE,
    COLOR_TAG_PURPLE,
    COLOR_TAG_GRAY,
  ];

  static final $core.List<ColorTag?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ColorTag? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColorTag._(super.value, super.name);
}

/// SshAuthMethod selects how the tunnel authenticates.
class SshAuthMethod extends $pb.ProtobufEnum {
  /// Not set; treated as password.
  static const SshAuthMethod SSH_AUTH_METHOD_UNSPECIFIED =
      SshAuthMethod._(0, _omitEnumNames ? '' : 'SSH_AUTH_METHOD_UNSPECIFIED');

  /// Password stored in the keychain.
  static const SshAuthMethod SSH_AUTH_METHOD_PASSWORD =
      SshAuthMethod._(1, _omitEnumNames ? '' : 'SSH_AUTH_METHOD_PASSWORD');

  /// Private key file, optional passphrase stored in the keychain.
  static const SshAuthMethod SSH_AUTH_METHOD_KEY_FILE =
      SshAuthMethod._(2, _omitEnumNames ? '' : 'SSH_AUTH_METHOD_KEY_FILE');

  /// The running SSH agent.
  static const SshAuthMethod SSH_AUTH_METHOD_AGENT =
      SshAuthMethod._(3, _omitEnumNames ? '' : 'SSH_AUTH_METHOD_AGENT');

  static const $core.List<SshAuthMethod> values = <SshAuthMethod>[
    SSH_AUTH_METHOD_UNSPECIFIED,
    SSH_AUTH_METHOD_PASSWORD,
    SSH_AUTH_METHOD_KEY_FILE,
    SSH_AUTH_METHOD_AGENT,
  ];

  static final $core.List<SshAuthMethod?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SshAuthMethod? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SshAuthMethod._(super.value, super.name);
}

/// TlsMode selects how strictly TLS is enforced.
class TlsMode extends $pb.ProtobufEnum {
  /// Not set; the engine default applies.
  static const TlsMode TLS_MODE_UNSPECIFIED =
      TlsMode._(0, _omitEnumNames ? '' : 'TLS_MODE_UNSPECIFIED');

  /// No TLS.
  static const TlsMode TLS_MODE_DISABLE =
      TlsMode._(1, _omitEnumNames ? '' : 'TLS_MODE_DISABLE');

  /// Use TLS if the server offers it.
  static const TlsMode TLS_MODE_PREFER =
      TlsMode._(2, _omitEnumNames ? '' : 'TLS_MODE_PREFER');

  /// TLS required, certificate not verified.
  static const TlsMode TLS_MODE_REQUIRE =
      TlsMode._(3, _omitEnumNames ? '' : 'TLS_MODE_REQUIRE');

  /// TLS required, certificate chain verified.
  static const TlsMode TLS_MODE_VERIFY_CA =
      TlsMode._(4, _omitEnumNames ? '' : 'TLS_MODE_VERIFY_CA');

  /// TLS required, chain and host name verified.
  static const TlsMode TLS_MODE_VERIFY_FULL =
      TlsMode._(5, _omitEnumNames ? '' : 'TLS_MODE_VERIFY_FULL');

  static const $core.List<TlsMode> values = <TlsMode>[
    TLS_MODE_UNSPECIFIED,
    TLS_MODE_DISABLE,
    TLS_MODE_PREFER,
    TLS_MODE_REQUIRE,
    TLS_MODE_VERIFY_CA,
    TLS_MODE_VERIFY_FULL,
  ];

  static final $core.List<TlsMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static TlsMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TlsMode._(super.value, super.name);
}

/// FieldKind tells the UI which input widget to render.
class FieldKind extends $pb.ProtobufEnum {
  /// Not set; render as text.
  static const FieldKind FIELD_KIND_UNSPECIFIED =
      FieldKind._(0, _omitEnumNames ? '' : 'FIELD_KIND_UNSPECIFIED');

  /// Single-line text.
  static const FieldKind FIELD_KIND_TEXT =
      FieldKind._(1, _omitEnumNames ? '' : 'FIELD_KIND_TEXT');

  /// Integer, e.g. a port.
  static const FieldKind FIELD_KIND_INTEGER =
      FieldKind._(2, _omitEnumNames ? '' : 'FIELD_KIND_INTEGER');

  /// Secret; stored in the keychain, sent only in the password fields of
  /// requests, never in params.
  static const FieldKind FIELD_KIND_PASSWORD =
      FieldKind._(3, _omitEnumNames ? '' : 'FIELD_KIND_PASSWORD');

  /// Local file path with a file picker.
  static const FieldKind FIELD_KIND_FILE =
      FieldKind._(4, _omitEnumNames ? '' : 'FIELD_KIND_FILE');

  /// Checkbox; value "true" or "false".
  static const FieldKind FIELD_KIND_BOOLEAN =
      FieldKind._(5, _omitEnumNames ? '' : 'FIELD_KIND_BOOLEAN');

  /// One of FieldSpec.options.
  static const FieldKind FIELD_KIND_SELECT =
      FieldKind._(6, _omitEnumNames ? '' : 'FIELD_KIND_SELECT');

  static const $core.List<FieldKind> values = <FieldKind>[
    FIELD_KIND_UNSPECIFIED,
    FIELD_KIND_TEXT,
    FIELD_KIND_INTEGER,
    FIELD_KIND_PASSWORD,
    FIELD_KIND_FILE,
    FIELD_KIND_BOOLEAN,
    FIELD_KIND_SELECT,
  ];

  static final $core.List<FieldKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static FieldKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FieldKind._(super.value, super.name);
}

/// ErrorKind classifies a connection failure.
class ErrorKind extends $pb.ProtobufEnum {
  /// Unclassified failure.
  static const ErrorKind ERROR_KIND_UNSPECIFIED =
      ErrorKind._(0, _omitEnumNames ? '' : 'ERROR_KIND_UNSPECIFIED');

  /// Bad credentials or not permitted.
  static const ErrorKind ERROR_KIND_AUTH =
      ErrorKind._(1, _omitEnumNames ? '' : 'ERROR_KIND_AUTH');

  /// Host unreachable, refused, DNS failure.
  static const ErrorKind ERROR_KIND_NETWORK =
      ErrorKind._(2, _omitEnumNames ? '' : 'ERROR_KIND_NETWORK');

  /// TLS handshake or certificate problem.
  static const ErrorKind ERROR_KIND_TLS =
      ErrorKind._(3, _omitEnumNames ? '' : 'ERROR_KIND_TLS');

  /// Database, file or other target does not exist.
  static const ErrorKind ERROR_KIND_NOT_FOUND =
      ErrorKind._(4, _omitEnumNames ? '' : 'ERROR_KIND_NOT_FOUND');

  /// The operation exceeded its timeout.
  static const ErrorKind ERROR_KIND_TIMEOUT =
      ErrorKind._(5, _omitEnumNames ? '' : 'ERROR_KIND_TIMEOUT');

  /// The settings are invalid (missing field, bad port...).
  static const ErrorKind ERROR_KIND_INVALID_CONFIG =
      ErrorKind._(6, _omitEnumNames ? '' : 'ERROR_KIND_INVALID_CONFIG');

  /// The SSH host key is not known yet. ConnectionError carries its
  /// fingerprint; the UI asks the user and calls TrustHostKey.
  static const ErrorKind ERROR_KIND_SSH_HOST_KEY_UNKNOWN =
      ErrorKind._(7, _omitEnumNames ? '' : 'ERROR_KIND_SSH_HOST_KEY_UNKNOWN');

  /// The SSH host key differs from the trusted one. Never offered for trust.
  static const ErrorKind ERROR_KIND_SSH_HOST_KEY_CHANGED =
      ErrorKind._(8, _omitEnumNames ? '' : 'ERROR_KIND_SSH_HOST_KEY_CHANGED');

  /// The bastion rejected the credentials or key.
  static const ErrorKind ERROR_KIND_SSH_AUTH =
      ErrorKind._(9, _omitEnumNames ? '' : 'ERROR_KIND_SSH_AUTH');

  /// The tunnel dropped after it was established.
  static const ErrorKind ERROR_KIND_TUNNEL_LOST =
      ErrorKind._(10, _omitEnumNames ? '' : 'ERROR_KIND_TUNNEL_LOST');

  static const $core.List<ErrorKind> values = <ErrorKind>[
    ERROR_KIND_UNSPECIFIED,
    ERROR_KIND_AUTH,
    ERROR_KIND_NETWORK,
    ERROR_KIND_TLS,
    ERROR_KIND_NOT_FOUND,
    ERROR_KIND_TIMEOUT,
    ERROR_KIND_INVALID_CONFIG,
    ERROR_KIND_SSH_HOST_KEY_UNKNOWN,
    ERROR_KIND_SSH_HOST_KEY_CHANGED,
    ERROR_KIND_SSH_AUTH,
    ERROR_KIND_TUNNEL_LOST,
  ];

  static final $core.List<ErrorKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static ErrorKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorKind._(super.value, super.name);
}

/// TestStage is one step of a connection test.
class TestStage extends $pb.ProtobufEnum {
  /// Not set.
  static const TestStage TEST_STAGE_UNSPECIFIED =
      TestStage._(0, _omitEnumNames ? '' : 'TEST_STAGE_UNSPECIFIED');

  /// Opening the SSH tunnel.
  static const TestStage TEST_STAGE_SSH =
      TestStage._(1, _omitEnumNames ? '' : 'TEST_STAGE_SSH');

  /// TLS handshake.
  static const TestStage TEST_STAGE_TLS =
      TestStage._(2, _omitEnumNames ? '' : 'TEST_STAGE_TLS');

  /// Authenticating to the database.
  static const TestStage TEST_STAGE_AUTH =
      TestStage._(3, _omitEnumNames ? '' : 'TEST_STAGE_AUTH');

  /// Ping.
  static const TestStage TEST_STAGE_PING =
      TestStage._(4, _omitEnumNames ? '' : 'TEST_STAGE_PING');

  static const $core.List<TestStage> values = <TestStage>[
    TEST_STAGE_UNSPECIFIED,
    TEST_STAGE_SSH,
    TEST_STAGE_TLS,
    TEST_STAGE_AUTH,
    TEST_STAGE_PING,
  ];

  static final $core.List<TestStage?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static TestStage? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TestStage._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
