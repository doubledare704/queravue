import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/presentation/connection_sidebar.dart';
import '../application/sidebar_mode.dart';
import 'workspace_panel.dart';

/// The left pane: connections or the workspace, switched at the top.
class LeftSidebar extends ConsumerWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(sidebarModeProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: SegmentedButton<SidebarMode>(
              key: const Key('sidebar-switch'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: SidebarMode.connections,
                  icon: Icon(Icons.storage_outlined, size: 16),
                  label: Text('Connections'),
                ),
                ButtonSegment(
                  value: SidebarMode.workspace,
                  icon: Icon(Icons.folder_copy_outlined, size: 16),
                  label: Text('Workspace'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(sidebarModeProvider.notifier).show(s.first),
            ),
          ),
        ),
        Expanded(
          child: mode == SidebarMode.workspace
              ? const WorkspacePanel()
              : const ConnectionSidebar(),
        ),
      ],
    );
  }
}
