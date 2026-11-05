import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';

import 'core_launcher.dart';
import 'gen/queravue/v1/connections.pbgrpc.dart';
import 'gen/queravue/v1/core.pbgrpc.dart';

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
