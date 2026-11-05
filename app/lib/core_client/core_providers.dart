import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_connection.dart';
import 'core_launcher.dart';
import 'core_supervisor.dart';

/// Starts core processes. Override in tests.
final coreLauncherProvider = Provider<CoreLauncher>(
  (ref) => ProcessCoreLauncher(),
);

/// Opens connections to a launched core. Override in tests.
final coreConnectorProvider = Provider<CoreConnector>(
  (ref) => GrpcCoreConnection.connect,
);

/// The single supervisor that owns the core sidecar for the app's lifetime.
final coreSupervisorProvider = Provider<CoreSupervisor>((ref) {
  final supervisor = CoreSupervisor(
    launcher: ref.watch(coreLauncherProvider),
    connector: ref.watch(coreConnectorProvider),
  );
  ref.onDispose(supervisor.dispose);
  supervisor.start();
  return supervisor;
});
