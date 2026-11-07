import 'dart:async';

import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/gen/queravue/v1/connections.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/design.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/document.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/history.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/index.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/query.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/schema.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/session.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/shell.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/stats.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/table.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/validation.pbgrpc.dart';
import 'package:queravue/core_client/gen/queravue/v1/workspace.pbgrpc.dart';
import 'package:queravue/core_client/core_launcher.dart';

class FakeCoreHandle implements CoreHandle {
  FakeCoreHandle(this.pid);

  @override
  final int pid;
  final _exit = Completer<int>();
  bool killed = false;
  bool shutDown = false;

  @override
  String get socketPath => '/tmp/fake-$pid.sock';

  @override
  String get token => 'token-$pid';

  @override
  Future<int> get exitCode => _exit.future;

  /// Simulates the process dying on its own (e.g. kill -9).
  void die([int code = -9]) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Future<void> kill() async {
    killed = true;
    die();
  }

  @override
  Future<void> shutdown({Duration timeout = const Duration(seconds: 3)}) async {
    shutDown = true;
    die(0);
  }
}

/// Launcher whose next results are scripted: `null` = succeed, else throw.
class FakeCoreLauncher implements CoreLauncher {
  final handles = <FakeCoreHandle>[];
  final failures = <Object?>[];

  @override
  Future<CoreHandle> launch() async {
    if (failures.isNotEmpty) {
      final failure = failures.removeAt(0);
      if (failure != null) throw failure;
    }
    final handle = FakeCoreHandle(1000 + handles.length);
    handles.add(handle);
    return handle;
  }
}

class FakeCoreConnection implements CoreConnection {
  FakeCoreConnection(
    this.handle, {
    this.hangOnClose = false,
    this.version = '0.1.0-dev',
    this.autoBeat = true,
  });

  final FakeCoreHandle handle;
  final String version;
  final bool autoBeat;

  /// Simulates grpc-dart's terminate() hanging after the peer died.
  final bool hangOnClose;
  final health$ = StreamController<HealthResponse>();
  bool closed = false;

  void beat() =>
      health$.add(HealthResponse(status: HealthStatus.HEALTH_STATUS_SERVING));

  @override
  Future<CoreInfo> hello() async => CoreInfo(
    version: version,
    protocolVersion: 1,
    capabilities: const {'health'},
  );

  @override
  Stream<HealthResponse> health({int intervalMs = 1000}) {
    if (autoBeat) beat();
    // Like gRPC: the stream errors out when the process dies.
    unawaited(
      handle.exitCode.then((_) {
        if (!health$.isClosed) {
          health$.addError(StateError('connection lost'));
          unawaited(health$.close());
        }
      }),
    );
    return health$.stream;
  }

  @override
  ConnectionServiceClient get connectionService =>
      throw UnimplementedError('use a fake ConnectionsRepository');

  @override
  SessionServiceClient get sessionService =>
      throw UnimplementedError('use a fake QueryRepository');

  @override
  QueryServiceClient get queryService =>
      throw UnimplementedError('use a fake QueryRepository');

  @override
  SchemaServiceClient get schemaService =>
      throw UnimplementedError('use a fake SchemaRepository');

  @override
  TableServiceClient get tableService =>
      throw UnimplementedError('use a fake TableRepository');

  @override
  HistoryServiceClient get historyService =>
      throw UnimplementedError('use a fake HistoryRepository');

  @override
  DocumentServiceClient get documentService =>
      throw UnimplementedError('use a fake DocumentRepository');

  @override
  ShellServiceClient get shellService =>
      throw UnimplementedError('use a fake ShellRepository');

  @override
  WorkspaceServiceClient get workspaceService =>
      throw UnimplementedError('use a fake WorkspaceRepository');

  @override
  IndexServiceClient get indexService =>
      throw UnimplementedError('use a fake AdminRepository');

  @override
  StatsServiceClient get statsService =>
      throw UnimplementedError('use a fake AdminRepository');

  @override
  ValidationServiceClient get validationService =>
      throw UnimplementedError('use a fake AdminRepository');

  @override
  SchemaDesignServiceClient get designService =>
      throw UnimplementedError('use a fake DesignRepository');

  @override
  Future<void> close() async {
    closed = true;
    if (hangOnClose) return Completer<void>().future;
    if (!health$.isClosed) await health$.close();
  }
}
