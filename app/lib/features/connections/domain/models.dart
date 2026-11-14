import 'package:flutter/foundation.dart';

import 'network_settings.dart';

/// Which input widget renders a [FieldSpec].
enum FieldKind { text, integer, password, file, boolean, select }

/// One connection-form field, as described by the core.
@immutable
class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    this.kind = FieldKind.text,
    this.required = false,
    this.defaultValue = '',
    this.placeholder = '',
    this.options = const [],
  });

  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final String defaultValue;
  final String placeholder;
  final List<String> options;
}

/// A database engine the core supports.
@immutable
class EngineSpec {
  const EngineSpec({
    required this.id,
    required this.displayName,
    required this.fields,
    this.family = '',
    this.supportsUri = false,
    this.supportsSsh = false,
    this.supportsTls = false,
    this.uriExample = '',
    this.capabilities = const {},
  });

  final String id;
  final String displayName;
  final String family;
  final List<FieldSpec> fields;
  final bool supportsUri;
  final bool supportsSsh;
  final bool supportsTls;
  final String uriExample;
  final Set<String> capabilities;

  /// Non-password fields, which are stored in params.
  Iterable<FieldSpec> get paramFields =>
      fields.where((f) => f.kind != FieldKind.password);

  /// Whether the engine takes a password.
  bool get hasPasswordField => fields.any((f) => f.kind == FieldKind.password);

  /// Default params for a new connection.
  Map<String, String> get defaults => {
    for (final f in paramFields)
      if (f.defaultValue.isNotEmpty) f.key: f.defaultValue,
  };
}

/// Color dot shown next to a connection.
enum ColorTag { none, red, orange, yellow, green, blue, purple, gray }

/// A saved (or draft) connection profile. Never holds a password.
@immutable
class ConnectionProfile {
  const ConnectionProfile({
    this.id = '',
    required this.name,
    required this.engineId,
    this.params = const {},
    this.folder = '',
    this.color = ColorTag.none,
    this.production = false,
    this.hasPassword = false,
    this.ssh,
    this.tls,
  });

  /// Empty for a draft that has not been saved yet.
  final String id;
  final String name;
  final String engineId;
  final Map<String, String> params;

  /// "/"-separated folder path; empty is the root.
  final String folder;
  final ColorTag color;
  final bool production;

  /// Whether the keychain holds a password for this connection.
  final bool hasPassword;
  final SshSettings? ssh;
  final TlsSettings? tls;

  bool get isSaved => id.isNotEmpty;

  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? engineId,
    Map<String, String>? params,
    String? folder,
    ColorTag? color,
    bool? production,
    bool? hasPassword,
  }) => ConnectionProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    engineId: engineId ?? this.engineId,
    params: params ?? this.params,
    folder: folder ?? this.folder,
    color: color ?? this.color,
    production: production ?? this.production,
    hasPassword: hasPassword ?? this.hasPassword,
    ssh: ssh,
    tls: tls,
  );

  @override
  bool operator ==(Object other) =>
      other is ConnectionProfile &&
      other.id == id &&
      other.name == name &&
      other.engineId == engineId &&
      mapEquals(other.params, params) &&
      other.folder == folder &&
      other.color == color &&
      other.production == production &&
      other.hasPassword == hasPassword &&
      other.ssh == ssh &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    engineId,
    Object.hashAllUnordered(params.entries.map((e) => '${e.key}=${e.value}')),
    folder,
    color,
    production,
    hasPassword,
    ssh,
    tls,
  );
}

/// Classified connection failure.
enum ConnectionErrorKind {
  unknown,
  auth,
  network,
  tls,
  notFound,
  timeout,
  invalidConfig,
  sshUnknownKey,
  sshChangedKey,
  sshAuth,
  tunnelLost,
}

/// Outcome of a connection test.
sealed class TestResult {
  const TestResult(this.steps);

  final List<ConnectionTestStep> steps;
}

final class TestPassed extends TestResult {
  const TestPassed({
    required this.product,
    required this.version,
    required this.connectMs,
    required this.latencyMs,
    List<ConnectionTestStep> steps = const [],
  }) : super(steps);

  final String product;
  final String version;
  final int connectMs;
  final int latencyMs;

  /// "PostgreSQL 17.11 · 3 ms".
  String get summary => '$product $version · $latencyMs ms';
}

final class TestFailed extends TestResult {
  const TestFailed(
    this.kind,
    this.message, {
    this.hostKey,
    List<ConnectionTestStep> steps = const [],
  }) : super(steps);

  final SshHostKey? hostKey;

  final ConnectionErrorKind kind;

  /// Detail from the core. Never contains secrets.
  final String message;

  /// Short, friendly headline for [kind].
  String get headline => switch (kind) {
    ConnectionErrorKind.auth => 'Wrong user or password',
    ConnectionErrorKind.network => "Can't reach the server",
    ConnectionErrorKind.tls => 'TLS/SSL handshake failed',
    ConnectionErrorKind.notFound => 'Database or file not found',
    ConnectionErrorKind.timeout => 'Connection timed out',
    ConnectionErrorKind.invalidConfig => 'Invalid settings',
    ConnectionErrorKind.sshUnknownKey => 'Unknown SSH host key',
    ConnectionErrorKind.sshChangedKey => 'SSH host key changed',
    ConnectionErrorKind.sshAuth => 'SSH authentication failed',
    ConnectionErrorKind.tunnelLost => 'SSH tunnel lost',
    ConnectionErrorKind.unknown => 'Connection failed',
  };
}

/// A repository call failed (core unreachable, validation, not found...).
class ConnectionsException implements Exception {
  const ConnectionsException(this.message, {this.coreUnavailable = false});

  final String message;

  /// True when there is no live core to talk to.
  final bool coreUnavailable;

  @override
  String toString() => message;
}
