import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/connections.pbgrpc.dart' as pb;
import '../domain/cancellation.dart';
import '../domain/models.dart';

/// Access to saved connections in the core.
abstract interface class ConnectionsRepository {
  Future<List<EngineSpec>> listEngines();

  Future<List<ConnectionProfile>> list();

  /// Saves a new connection. A non-empty [password] goes to the keychain.
  Future<ConnectionProfile> create(ConnectionProfile draft, {String? password});

  /// Updates a connection. [password] null keeps the stored one;
  /// [clearPassword] removes it.
  Future<ConnectionProfile> update(
    ConnectionProfile profile, {
    String? password,
    bool clearPassword = false,
  });

  Future<void> delete(String id);

  /// Tests a saved connection ([id]), a [draft], or a draft of a saved one
  /// (password falls back to the stored one when [password] is null).
  /// Throws [OperationCancelled] if [cancel] fires first.
  Future<TestResult> test({
    String? id,
    ConnectionProfile? draft,
    String? password,
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
  }) => _call((c) async {
    final req = pb.CreateConnectionRequest(connection: profileToProto(draft));
    if (password != null && password.isNotEmpty) req.password = password;
    final resp = await c.createConnection(req, options: _opts);
    return profileFromProto(resp.connection);
  });

  @override
  Future<ConnectionProfile> update(
    ConnectionProfile profile, {
    String? password,
    bool clearPassword = false,
  }) => _call((c) async {
    final req = pb.UpdateConnectionRequest(
      connection: profileToProto(profile),
      clearPassword_3: clearPassword,
    );
    if (password != null && password.isNotEmpty) req.password = password;
    final resp = await c.updateConnection(req, options: _opts);
    return profileFromProto(resp.connection);
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
    Duration? timeout,
    CancellationToken? cancel,
  }) => _call((c) async {
    final t = timeout ?? const Duration(seconds: 10);
    final req = pb.TestConnectionRequest(
      id: id,
      draft: draft == null ? null : profileToProto(draft),
      timeoutMs: t.inMilliseconds,
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
);

TestResult testResultFromProto(pb.TestConnectionResponse r) {
  if (r.ok) {
    return TestPassed(
      product: r.server.product,
      version: r.server.version,
      connectMs: r.connectMs,
      latencyMs: r.latencyMs,
    );
  }
  final kind = switch (r.error.kind) {
    pb.ErrorKind.ERROR_KIND_AUTH => ConnectionErrorKind.auth,
    pb.ErrorKind.ERROR_KIND_NETWORK => ConnectionErrorKind.network,
    pb.ErrorKind.ERROR_KIND_TLS => ConnectionErrorKind.tls,
    pb.ErrorKind.ERROR_KIND_NOT_FOUND => ConnectionErrorKind.notFound,
    pb.ErrorKind.ERROR_KIND_TIMEOUT => ConnectionErrorKind.timeout,
    pb.ErrorKind.ERROR_KIND_INVALID_CONFIG => ConnectionErrorKind.invalidConfig,
    _ => ConnectionErrorKind.unknown,
  };
  return TestFailed(kind, r.error.message);
}
