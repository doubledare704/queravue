import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schema/application/schema_controller.dart';
import '../../schema/presentation/schema_tree_view.dart';
import '../application/connection_session.dart';
import '../application/connections_controller.dart';
import '../domain/models.dart';
import 'connection_actions.dart';

/// Left sidebar: the connection tree.
class ConnectionSidebar extends ConsumerWidget {
  const ConnectionSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(connectionTreeProvider);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Connections',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: const Key('sidebar-new-connection'),
                  tooltip: 'New connection (⌘N)',
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => showConnectionDialog(context, ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (tree) {
              AsyncData(value: final rows) when rows.isEmpty => _Empty(
                onCreate: () => showConnectionDialog(context, ref),
              ),
              AsyncData(value: final rows) => ListView.builder(
                key: const Key('connection-tree'),
                itemCount: rows.length,
                itemBuilder: (_, i) => switch (rows[i]) {
                  final FolderRow f => _FolderTile(row: f),
                  final ConnectionRow c => _ConnectionTile(row: c),
                },
              ),
              AsyncError(:final error) => _Error(
                message: error is ConnectionsException
                    ? error.message
                    : '$error',
                onRetry: () => ref.invalidate(connectionsControllerProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No connections yet', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onCreate,
              child: const Text('New connection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.row});

  final FolderRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      key: Key('folder-${row.path}'),
      onTap: () => ref.read(collapsedFoldersProvider.notifier).toggle(row.path),
      child: Padding(
        padding: EdgeInsets.only(left: 8 + row.depth * 16.0, right: 8),
        child: Row(
          children: [
            Icon(
              row.expanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
            ),
            const SizedBox(width: 2),
            Icon(
              row.expanded ? Icons.folder_open : Icons.folder,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(row.name, overflow: TextOverflow.ellipsis)),
            Text('${row.count}', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { connect, disconnect, refresh, edit, duplicate, delete }

class _ConnectionTile extends ConsumerWidget {
  const _ConnectionTile({required this.row});

  final ConnectionRow row;

  Future<void> _run(BuildContext context, WidgetRef ref, _MenuAction a) async {
    final p = row.profile;
    switch (a) {
      case _MenuAction.connect:
        await connectTo(context, ref, p);
      case _MenuAction.disconnect:
        await ref.read(connectionSessionProvider(p.id).notifier).disconnect();
      case _MenuAction.refresh:
        await ref.read(schemaTreeProvider(p.id).notifier).refresh('root');
      case _MenuAction.edit:
        await showConnectionDialog(context, ref, initial: p);
      case _MenuAction.duplicate:
        await showConnectionDialog(context, ref, initial: p, duplicate: true);
      case _MenuAction.delete:
        await confirmDeleteConnection(context, ref, p);
    }
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    bool isConnected,
  ) async {
    final items = <PopupMenuEntry<_MenuAction>>[
      if (!isConnected)
        const PopupMenuItem(value: _MenuAction.connect, child: Text('Connect'))
      else ...[
        const PopupMenuItem(
          value: _MenuAction.disconnect,
          child: Text('Disconnect'),
        ),
        const PopupMenuItem(
          value: _MenuAction.refresh,
          child: Text('Refresh schema'),
        ),
      ],
      const PopupMenuDivider(),
      const PopupMenuItem(value: _MenuAction.edit, child: Text('Edit…')),
      const PopupMenuItem(
        value: _MenuAction.duplicate,
        child: Text('Duplicate…'),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(value: _MenuAction.delete, child: Text('Delete…')),
    ];

    final a = await showMenu<_MenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    );
    if (a != null && context.mounted) await _run(context, ref, a);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = row.profile;
    final selected = ref.watch(selectedConnectionProvider) == p.id;
    final status = ref.watch(connectionTestsProvider.select((m) => m[p.id]));
    final session = ref.watch(connectionSessionProvider(p.id));
    final isConnected = session.isConnected;
    final isCollapsed = ref.watch(collapsedConnectionsProvider).contains(p.id);
    final isExpanded = isConnected && !isCollapsed;

    final scheme = Theme.of(context).colorScheme;
    final dot = colorTagColor(p.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onSecondaryTapUp: (d) =>
              _showMenu(context, ref, d.globalPosition, isConnected),
          child: Material(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: Key('connection-${p.id}'),
                      onTap: () {
                        ref
                            .read(selectedConnectionProvider.notifier)
                            .select(p.id);
                        if (isConnected) {
                          ref
                              .read(collapsedConnectionsProvider.notifier)
                              .toggle(p.id);
                        }
                      },
                      onDoubleTap: () => connectTo(context, ref, p),
                      child: Padding(
                        padding: EdgeInsets.only(left: 12 + row.depth * 16.0),
                        child: Row(
                          children: [
                            if (isConnected)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  isExpanded
                                      ? Icons.expand_more
                                      : Icons.chevron_right,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            Container(
                              key: Key('color-dot-${p.id}'),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dot ?? Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.production) const _ProdBadge(),
                            _StatusIcon(status: status),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<_MenuAction>(
                    key: Key('connection-menu-${p.id}'),
                    tooltip: 'Actions',
                    icon: const Icon(Icons.more_horiz, size: 16),
                    padding: EdgeInsets.zero,
                    onSelected: (a) => _run(context, ref, a),
                    itemBuilder: (_) => [
                      if (!isConnected)
                        const PopupMenuItem(
                          value: _MenuAction.connect,
                          child: Text('Connect'),
                        )
                      else ...[
                        const PopupMenuItem(
                          value: _MenuAction.disconnect,
                          child: Text('Disconnect'),
                        ),
                        const PopupMenuItem(
                          value: _MenuAction.refresh,
                          child: Text('Refresh schema'),
                        ),
                      ],
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: _MenuAction.edit,
                        child: Text('Edit…'),
                      ),
                      const PopupMenuItem(
                        value: _MenuAction.duplicate,
                        child: Text('Duplicate…'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: _MenuAction.delete,
                        child: Text('Delete…'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) SchemaTreeView(connectionId: p.id),
      ],
    );
  }
}

class _ProdBadge extends StatelessWidget {
  const _ProdBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('prod-badge'),
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'PROD',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final ConnectStatus? status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      null => const SizedBox(width: 4),
      Connecting() => const Padding(
        padding: EdgeInsets.only(left: 6),
        child: SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      Connected(result: final TestPassed ok) => Tooltip(
        message: ok.summary,
        child: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.check_circle, size: 14, color: Colors.green),
        ),
      ),
      Connected(result: final TestFailed err) => Tooltip(
        message: '${err.headline}\n${err.message}',
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Icon(
            Icons.error,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    };
  }
}
