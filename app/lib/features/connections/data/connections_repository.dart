import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/connections.pbgrpc.dart' as pb;
import '../domain/cancellation.dart';
import '../domain/models.dart';
import '../domain/network_settings.dart';

/// Access to saved connections in the core.
abstract interface class ConnectionsRepository {
  Future<List<EngineSpec>> listEngines();

  Future<List<ConnectionProfile>> list();

  /// Saves a new connection. A non-empty [password] goes to the keychain.
  Future<ConnectionProfile> create(
    ConnectionProfile draft, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
  });

  /// Updates a connection. [password] null keeps the stored one;
  /// [clearPassword] removes it.
  Future<ConnectionProfile> update(
    ConnectionProfile profile, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    bool clearPassword = false,
  });

  Future<void> delete(String id);

  Future<void> trustHostKey(SshHostKey key);

  /// Tests a saved connection ([id]), a [draft], or a draft of a saved one
  /// (password falls back to the stored one when [password] is null).
  /// Throws [OperationCancelled] if [cancel] fires first.
  Future<TestResult> test({
    String? id,
    ConnectionProfile? draft,
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    Duration? timeout,
    CancellationToken? cancel,
  });

  /// Parses a URI into params and an optional password.
  Future<({Map<String, String> params, String? password})> parseUri(
    String engineId,
    String uri,
  );
}

/// The repository backed by the live core.
final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcConnectionsRepository(() => supervisor.connection);
});

/// gRPC implementation. Resolves the current core connection per call, so it
/// keeps working after the supervisor restarts the core.
class GrpcConnectionsRepository implements ConnectionsRepository {
  GrpcConnectionsRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _unaryTimeout = Duration(seconds: 5);

  pb.ConnectionServiceClient get _client {
    final conn = _connection();
    if (conn == null) {
      throw const ConnectionsException(
        'Core not connected',
        coreUnavailable: true,
      );
    }
    return conn.connectionService;
  }

  Future<T> _call<T>(Future<T> Function(pb.ConnectionServiceClient c) f) async {
    try {
      return await f(_client);
    } on GrpcError catch (e) {
      throw ConnectionsException(
        e.message?.isNotEmpty == true ? e.message! : e.codeName,
        coreUnavailable: e.code == StatusCode.unavailable,
      );
    }
  }

  CallOptions get _opts => CallOptions(timeout: _unaryTimeout);

  @override
  Future<List<EngineSpec>> listEngines() => _call((c) async {
    final resp = await c.listEngines(pb.ListEnginesRequest(), options: _opts);
    return resp.engines.map(engineFromProto).toList();
  });

  @override
  Future<List<ConnectionProfile>> list() => _call((c) async {
    final resp = await c.listConnections(
      pb.ListConnectionsRequest(),
      options: _opts,
    );
    return resp.connections.map(profileFromProto).toList();
  });

  @override
  Future<ConnectionProfile> create(
    ConnectionProfile draft, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
  }) => _call((c) async {
    final req = pb.CreateConnectionRequest(
      connection: profileToProto(draft),
      sshSecrets: sshSecretsToProto(secrets),
      tlsSecrets: tlsSecretsToProto(secrets),
    );
    if (password != null && password.isNotEmpty) req.password = password;
    final resp = await c.createConnection(req, options: _opts);
    return profileFromProto(resp.connection);
  });

  @override
  Future<ConnectionProfile> update(
    ConnectionProfile profile, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    bool clearPassword = false,
  }) => _call((c) async {
    final req = pb.UpdateConnectionRequest(
      connection: profileToProto(profile),
      clearPassword_3: clearPassword,
      sshSecrets: sshSecretsToProto(secrets),
      tlsSecrets: tlsSecretsToProto(secrets),
    );
    if (password != null && password.isNotEmpty) req.password = password;
    final resp = await c.updateConnection(req, options: _opts);
    return profileFromProto(resp.connection);
  });

  @override
  Future<void> trustHostKey(SshHostKey key) => _call((c) async {
    await c.trustHostKey(
      pb.TrustHostKeyRequest(
        host: key.host,
        port: key.port,
        fingerprintSha256: key.presented,
      ),
      options: _opts,
    );
  });

  @override
  Future<void> delete(String id) => _call((c) async {
    await c.deleteConnection(
      pb.DeleteConnectionRequest(id: id),
      options: _opts,
    );
  });

  @override
  Future<TestResult> test({
    String? id,
    ConnectionProfile? draft,
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    Duration? timeout,
    CancellationToken? cancel,
  }) => _call((c) async {
    final t = timeout ?? const Duration(seconds: 10);
    final req = pb.TestConnectionRequest(
      id: id,
      draft: draft == null ? null : profileToProto(draft),
      timeoutMs: t.inMilliseconds,
      sshSecrets: sshSecretsToProto(secrets),
      tlsSecrets: tlsSecretsToProto(secrets),
    );
    if (password != null) req.password = password;
    final call = c.testConnection(
      req,
      // Leave headroom over the core-side timeout.
      options: CallOptions(timeout: t + const Duration(seconds: 5)),
    );
    unawaited(cancel?.whenCancelled.then((_) => call.cancel()));
    try {
      return testResultFromProto(await call);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.cancelled && (cancel?.isCancelled ?? false)) {
        throw const OperationCancelled();
      }
      rethrow;
    }
  });

  @override
  Future<({Map<String, String> params, String? password})> parseUri(
    String engineId,
    String uri,
  ) => _call((c) async {
    final resp = await c.parseConnectionString(
      pb.ParseConnectionStringRequest(
        engineId: engineId,
        connectionString: uri,
      ),
      options: _opts,
    );
    return (
      params: Map<String, String>.of(resp.params),
      password: resp.hasPassword() ? resp.password : null,
    );
  });
}

// --- proto ↔ domain mapping ---

EngineSpec engineFromProto(pb.EngineInfo e) => EngineSpec(
  id: e.id,
  displayName: e.displayName,
  family: e.family,
  supportsUri: e.supportsUri,
  supportsSsh: e.supportsSsh,
  supportsTls: e.supportsTls,
  uriExample: e.uriExample,
  capabilities: e.capabilities.toSet(),
  fields: [
    for (final f in e.fields)
      FieldSpec(
        key: f.key,
        label: f.label,
        kind: _fieldKind(f.kind),
        required: f.required,
        defaultValue: f.defaultValue,
        placeholder: f.placeholder,
        options: List.of(f.options),
      ),
  ],
);

FieldKind _fieldKind(pb.FieldKind k) => switch (k) {
  pb.FieldKind.FIELD_KIND_INTEGER => FieldKind.integer,
  pb.FieldKind.FIELD_KIND_PASSWORD => FieldKind.password,
  pb.FieldKind.FIELD_KIND_FILE => FieldKind.file,
  pb.FieldKind.FIELD_KIND_BOOLEAN => FieldKind.boolean,
  pb.FieldKind.FIELD_KIND_SELECT => FieldKind.select,
  _ => FieldKind.text,
};

ConnectionProfile profileFromProto(pb.Connection c) => ConnectionProfile(
  id: c.id,
  name: c.name,
  engineId: c.engineId,
  params: Map<String, String>.of(c.params),
  folder: c.folder,
  color: ColorTag.values.elementAtOrNull(c.color.value) ?? ColorTag.none,
  production: c.production,
  hasPassword: c.hasPassword,
  ssh: c.hasSshTunnel() ? sshFromProto(c.sshTunnel) : null,
  tls: c.hasTls() ? tlsFromProto(c.tls) : null,
);

pb.Connection profileToProto(ConnectionProfile p) => pb.Connection(
  id: p.id,
  name: p.name,
  engineId: p.engineId,
  params: p.params.entries,
  folder: p.folder,
  color:
      pb.ColorTag.valueOf(p.color.index) ?? pb.ColorTag.COLOR_TAG_UNSPECIFIED,
  production: p.production,
  sshTunnel: sshToProto(p.ssh),
  tls: tlsToProto(p.tls),
);

SshEndpoint _endpointFromProto(pb.SshTunnel p) => (
  host: p.host,
  port: p.port,
  user: p.user,
  auth: switch (p.authMethod) {
    pb.SshAuthMethod.SSH_AUTH_METHOD_KEY_FILE => SshAuth.keyFile,
    pb.SshAuthMethod.SSH_AUTH_METHOD_AGENT => SshAuth.agent,
    _ => SshAuth.password,
  },
  keyFile: p.keyFile,
  hasPassword: p.hasPassword,
  hasPassphrase: p.hasKeyPassphrase,
);

SshSettings sshFromProto(pb.SshTunnel p) => (
  bastion: _endpointFromProto(p),
  jump: p.hasJumpHost() ? _endpointFromProto(p.jumpHost) : null,
  keepaliveSeconds: p.keepaliveSeconds,
  timeoutSeconds: p.connectTimeoutSeconds,
);

pb.SshTunnel _endpointToProto(SshEndpoint e) => pb.SshTunnel(
  host: e.host,
  port: e.port,
  user: e.user,
  authMethod: switch (e.auth) {
    SshAuth.password => pb.SshAuthMethod.SSH_AUTH_METHOD_PASSWORD,
    SshAuth.keyFile => pb.SshAuthMethod.SSH_AUTH_METHOD_KEY_FILE,
    SshAuth.agent => pb.SshAuthMethod.SSH_AUTH_METHOD_AGENT,
  },
  keyFile: e.keyFile,
);

pb.SshTunnel? sshToProto(SshSettings? s) {
  if (s == null) return null;
  final tunnel = _endpointToProto(s.bastion)
    ..keepaliveSeconds = s.keepaliveSeconds
    ..connectTimeoutSeconds = s.timeoutSeconds;
  if (s.jump case final jump?) tunnel.jumpHost = _endpointToProto(jump);
  return tunnel;
}

TlsSettings tlsFromProto(pb.TlsSettings p) => (
  mode: TlsMode.values.elementAtOrNull(p.mode.value) ?? TlsMode.engineDefault,
  caFile: p.caFile,
  certFile: p.clientCertFile,
  keyFile: p.clientKeyFile,
  serverName: p.serverName,
  hasPassphrase: p.hasClientKeyPassphrase,
);

pb.TlsSettings? tlsToProto(TlsSettings? t) => t == null
    ? null
    : pb.TlsSettings(
        mode: pb.TlsMode.valueOf(t.mode.index),
        caFile: t.caFile,
        clientCertFile: t.certFile,
        clientKeyFile: t.keyFile,
        serverName: t.serverName,
      );

pb.SshSecrets sshSecretsToProto(NetworkSecrets s) => pb.SshSecrets(
  password: s.sshPassword,
  keyPassphrase: s.sshPassphrase,
  jumpPassword: s.jumpPassword,
  jumpKeyPassphrase: s.jumpPassphrase,
);

pb.TlsSecrets tlsSecretsToProto(NetworkSecrets s) =>
    pb.TlsSecrets(clientKeyPassphrase: s.tlsPassphrase);

TestResult testResultFromProto(pb.TestConnectionResponse r) {
  final steps = List<ConnectionTestStep>.unmodifiable([
    for (final step in r.steps)
      if (step.stage.value >= 1 &&
          step.stage.value <= ConnectionTestStage.values.length)
        (
          stage: ConnectionTestStage.values[step.stage.value - 1],
          ok: step.ok,
          elapsedMs: step.elapsedMs,
          message: step.error.message,
        ),
  ]);
  return r.ok
      ? TestPassed(
          product: r.server.product,
          version: r.server.version,
          connectMs: r.connectMs,
          latencyMs: r.latencyMs,
          steps: steps,
        )
      : connectionFailureFromProto(r.error, steps: steps);
}

TestFailed connectionFailureFromProto(
  pb.ConnectionError error, {
  List<ConnectionTestStep> steps = const [],
}) {
  final kind = switch (error.kind) {
    pb.ErrorKind.ERROR_KIND_AUTH => ConnectionErrorKind.auth,
    pb.ErrorKind.ERROR_KIND_NETWORK => ConnectionErrorKind.network,
    pb.ErrorKind.ERROR_KIND_TLS => ConnectionErrorKind.tls,
    pb.ErrorKind.ERROR_KIND_NOT_FOUND => ConnectionErrorKind.notFound,
    pb.ErrorKind.ERROR_KIND_TIMEOUT => ConnectionErrorKind.timeout,
    pb.ErrorKind.ERROR_KIND_INVALID_CONFIG => ConnectionErrorKind.invalidConfig,
    pb.ErrorKind.ERROR_KIND_SSH_HOST_KEY_UNKNOWN =>
      ConnectionErrorKind.sshUnknownKey,
    pb.ErrorKind.ERROR_KIND_SSH_HOST_KEY_CHANGED =>
      ConnectionErrorKind.sshChangedKey,
    pb.ErrorKind.ERROR_KIND_SSH_AUTH => ConnectionErrorKind.sshAuth,
    pb.ErrorKind.ERROR_KIND_TUNNEL_LOST => ConnectionErrorKind.tunnelLost,
    _ => ConnectionErrorKind.unknown,
  };
  final address = RegExp(r'^(?:\[(.+)\]|([^:]+)):(\d+)$')
      .firstMatch(error.sshHost);
  return TestFailed(
    kind,
    error.message,
    steps: steps,
    hostKey: address == null
        ? null
        : (
            host: address[1] ?? address[2]!,
            port: int.parse(address[3]!),
            presented: error.sshFingerprintSha256,
            trusted: error.sshTrustedFingerprintSha256,
          ),
  );
}
