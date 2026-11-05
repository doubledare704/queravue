import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core_client/core_providers.dart';
import '../../core_client/core_supervisor.dart';

/// Exposes the core sidecar's lifecycle status to widgets.
class CoreStatusController extends Notifier<CoreStatus> {
  @override
  CoreStatus build() {
    final supervisor = ref.watch(coreSupervisorProvider);
    final sub = supervisor.statusChanges.listen((status) => state = status);
    ref.onDispose(sub.cancel);
    return supervisor.status;
  }
}

final coreStatusProvider = NotifierProvider<CoreStatusController, CoreStatus>(
  CoreStatusController.new,
);

/// "vX.Y" from a semantic version like "0.1.0-dev".
String shortVersion(String version) {
  final parts = version.split(RegExp(r'[.\-+]'));
  if (parts.length < 2) return 'v$version';
  return 'v${parts[0]}.${parts[1]}';
}

/// Status bar label for [status].
String coreStatusLabel(CoreStatus status) => switch (status) {
  CoreStarting() => 'Starting core…',
  CoreConnected(:final info) => 'Core connected ${shortVersion(info.version)}',
  CoreReconnecting(:final attempt) =>
    attempt > 1 ? 'Reconnecting… (attempt $attempt)' : 'Reconnecting…',
};
