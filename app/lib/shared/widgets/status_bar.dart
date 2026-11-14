import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core_client/core_supervisor.dart';
import '../../features/core_status/core_status_controller.dart';
import '../../features/connections/application/connections_controller.dart';
import '../../features/connections/application/connection_session.dart';
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
              const _TunnelStatus(),
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

class _TunnelStatus extends ConsumerWidget {
  const _TunnelStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(selectedConnectionProvider);
    if (id == null) return const SizedBox.shrink();
    final profile = ref
        .watch(connectionsControllerProvider)
        .value
        ?.where((profile) => profile.id == id)
        .firstOrNull;
    if (profile?.ssh == null) return const SizedBox.shrink();
    final provider = connectionSessionProvider(id);
    final tunnel = ref.watch(provider);
    final style = Theme.of(context).textTheme.labelSmall;
    final label = switch (tunnel) {
      ConnectionSessionState(isConnecting: true) => 'Opening SSH tunnel…',
      ConnectionSessionState(tunnelLost: true) => 'SSH tunnel lost',
      ConnectionSessionState(isConnected: true) => 'SSH tunnel connected',
      _ => 'SSH tunnel disconnected',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Tooltip(
            message: tunnel.error ?? label,
            child: Text(label, style: style),
          ),
          if (tunnel.tunnelLost && !tunnel.isConnecting)
            TextButton(
              onPressed: () => ref.read(provider.notifier).reconnect(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Reconnect', style: style),
            ),
        ],
      ),
    );
  }
}
