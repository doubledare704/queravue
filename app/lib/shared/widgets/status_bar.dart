import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core_client/core_supervisor.dart';
import '../../features/core_status/core_status_controller.dart';
import '../../features/editor/application/query_status.dart';

/// Bottom status bar showing the core sidecar's state.
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(coreStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    final (color, tooltip) = switch (status) {
      CoreStarting() => (scheme.outline, 'Launching queravued'),
      CoreConnected(:final info) => (
        Colors.green,
        'queravued ${info.version} · protocol ${info.protocolVersion}',
      ),
      CoreReconnecting(:final reason) => (Colors.orange, reason),
    };

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Tooltip(
                message: tooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: color,
                      key: const Key('core-status-dot'),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      coreStatusLabel(status),
                      key: const Key('core-status-label'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                ref.watch(queryStatusProvider).text,
                key: const Key('query-status'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
