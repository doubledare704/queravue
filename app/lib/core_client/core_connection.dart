import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';

import 'core_launcher.dart';
import 'gen/queravue/v1/connections.pbgrpc.dart';
import 'gen/queravue/v1/core.pbgrpc.dart';
import 'gen/queravue/v1/design.pbgrpc.dart';
import 'gen/queravue/v1/document.pbgrpc.dart';
import 'gen/queravue/v1/history.pbgrpc.dart';
import 'gen/queravue/v1/index.pbgrpc.dart';
import 'gen/queravue/v1/query.pbgrpc.dart';
import 'gen/queravue/v1/schema.pbgrpc.dart';
import 'gen/queravue/v1/session.pbgrpc.dart';
import 'gen/queravue/v1/shell.pbgrpc.dart';
import 'gen/queravue/v1/stats.pbgrpc.dart';
import 'gen/queravue/v1/table.pbgrpc.dart';
import 'gen/queravue/v1/validation.pbgrpc.dart';
import 'gen/queravue/v1/workspace.pbgrpc.dart';

export 'gen/queravue/v1/core.pb.dart' show HealthResponse;
export 'gen/queravue/v1/core.pbenum.dart' show HealthStatus;

/// What the core reported in its Hello handshake.
class CoreInfo {
  const CoreInfo({
    required this.version,
    required this.protocolVersion,
    required this.capabilities,
  });

  final String version;
  final int protocolVersion;
  final Set<String> capabilities;
}

/// A client connection to one core process.
abstract interface class CoreConnection {
  /// Performs the Hello handshake.
  Future<CoreInfo> hello();

  /// Streams heartbeats until cancelled or the core goes away.
  Stream<HealthResponse> health({int intervalMs});

  /// Client for saved connections, authenticated with the core's token.
  ConnectionServiceClient get connectionService;

  /// Client for live sessions, authenticated with the core's token.
  SessionServiceClient get sessionService;

  /// Client for running statements and reading results.
  QueryServiceClient get queryService;

  /// Client for database schema introspection.
  SchemaServiceClient get schemaService;

  /// Client for table browsing and inline editing.
  TableServiceClient get tableService;

  /// Client for query execution history.
  HistoryServiceClient get historyService;

  /// Client for browsing and editing documents.
  DocumentServiceClient get documentService;

  /// Client for the Mongo shell.
  ShellServiceClient get shellService;

  /// Client for the workspace of saved queries and scripts.
  WorkspaceServiceClient get workspaceService;

  /// Client for listing, creating and dropping indexes.
  IndexServiceClient get indexService;

  /// Client for table and collection statistics.
  StatsServiceClient get statsService;

  /// Client for Mongo collection validators.
  ValidationServiceClient get validationService;

  /// Client for previewing and applying schema changes.
  SchemaDesignServiceClient get designService;

  /// Closes the underlying channel.
  Future<void> close();
}

/// Opens a [CoreConnection] to a launched core.
typedef CoreConnector = Future<CoreConnection> Function(CoreHandle handle);

/// gRPC implementation over the core's Unix socket.
class GrpcCoreConnection implements CoreConnection {
  GrpcCoreConnection._(this._channel, String token)
    : _client = CoreServiceClient(_channel),
      _auth = CallOptions(metadata: {'authorization': 'Bearer $token'}) {
    connectionService = ConnectionServiceClient(_channel, options: _auth);
    sessionService = SessionServiceClient(_channel, options: _auth);
    queryService = QueryServiceClient(_channel, options: _auth);
    schemaService = SchemaServiceClient(_channel, options: _auth);
    tableService = TableServiceClient(_channel, options: _auth);
    historyService = HistoryServiceClient(_channel, options: _auth);
    documentService = DocumentServiceClient(_channel, options: _auth);
    shellService = ShellServiceClient(_channel, options: _auth);
    workspaceService = WorkspaceServiceClient(_channel, options: _auth);
    indexService = IndexServiceClient(_channel, options: _auth);
    statsService = StatsServiceClient(_channel, options: _auth);
    validationService = ValidationServiceClient(_channel, options: _auth);
    designService = SchemaDesignServiceClient(_channel, options: _auth);
  }

  /// Connects to [handle]'s socket. The connection is lazy; the first RPC
  /// establishes it.
  static Future<CoreConnection> connect(CoreHandle handle) async {
    final channel = ClientChannel(
      InternetAddress(handle.socketPath, type: InternetAddressType.unix),
      port: 0,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        // Fail fast instead of retrying a dead socket; the supervisor
        // restarts the core.
        connectionTimeout: Duration(seconds: 2),
      ),
    );
    return GrpcCoreConnection._(channel, handle.token);
  }

  static const _clientVersion = '0.1.0';

  final ClientChannel _channel;
  final CoreServiceClient _client;
  final CallOptions _auth;

  @override
  late final ConnectionServiceClient connectionService;

  @override
  late final SessionServiceClient sessionService;

  @override
  late final QueryServiceClient queryService;

  @override
  late final SchemaServiceClient schemaService;

  @override
  late final TableServiceClient tableService;

  @override
  late final HistoryServiceClient historyService;

  @override
  late final DocumentServiceClient documentService;

  @override
  late final ShellServiceClient shellService;

  @override
  late final WorkspaceServiceClient workspaceService;

  @override
  late final IndexServiceClient indexService;

  @override
  late final StatsServiceClient statsService;

  @override
  late final ValidationServiceClient validationService;

  @override
  late final SchemaDesignServiceClient designService;

  @override
  Future<CoreInfo> hello() async {
    final resp = await _client.hello(
      HelloRequest(clientVersion: _clientVersion),
      options: _auth.mergedWith(
        CallOptions(timeout: const Duration(seconds: 3)),
      ),
    );
    return CoreInfo(
      version: resp.coreVersion,
      protocolVersion: resp.protocolVersion,
      capabilities: resp.capabilities.toSet(),
    );
  }

  @override
  Stream<HealthResponse> health({int intervalMs = 1000}) =>
      _client.health(HealthRequest(intervalMs: intervalMs), options: _auth);

  @override
  Future<void> close() => _channel.terminate();
}
