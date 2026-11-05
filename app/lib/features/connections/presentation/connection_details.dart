import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/connections_controller.dart';
import '../domain/models.dart';
import 'connection_actions.dart';

/// Workspace pane for the selected connection, or a welcome hint.
class ConnectionDetails extends ConsumerWidget {
  const ConnectionDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(selectedConnectionProvider);
    final list = ref.watch(connectionsControllerProvider).value ?? const [];
    final profile = list.where((c) => c.id == id).firstOrNull;
    final text = Theme.of(context).textTheme;

    if (profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Queravue', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '⌘N new connection  ·  ⌘K command palette',
              style: text.bodyMedium,
            ),
          ],
        ),
      );
    }

    final status = ref.watch(connectionTestsProvider)[profile.id];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.name, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [
              profile.engineId,
              if (profile.folder.isNotEmpty) profile.folder,
              if (profile.production) 'production',
            ].join(' · '),
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                key: const Key('details-connect'),
                icon: const Icon(Icons.power, size: 18),
                label: const Text('Connect'),
                onPressed: status is Connecting
                    ? null
                    : () => connectTo(ref, profile),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    showConnectionDialog(context, ref, initial: profile),
                child: const Text('Edit…'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch (status) {
            null => const SizedBox.shrink(),
            Connecting() => const Text('Connecting…'),
            Connected(result: final TestPassed ok) => Text(
              'Connected: ${ok.product} ${ok.version} · '
              'connect ${ok.connectMs} ms · ping ${ok.latencyMs} ms',
              key: const Key('details-status'),
            ),
            Connected(result: final TestFailed err) => Text(
              '${err.headline}: ${err.message}',
              key: const Key('details-status'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          },
        ],
      ),
    );
  }
}
