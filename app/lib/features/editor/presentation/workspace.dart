import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shortcuts.dart';
import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../documents/presentation/document_tab_view.dart';
import '../../connections/presentation/connection_details.dart';
import '../../table_view/presentation/table_tab_view.dart';
import '../application/editor_tabs.dart';
import 'query_tab_view.dart';

/// Right-hand pane: editor tabs of the selected connection, or its details
/// when no tab is open.
class Workspace extends ConsumerWidget {
  const Workspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(selectedConnectionProvider);
    final state = ref.watch(editorTabsProvider);
    final tabs = id == null ? const <EditorTab>[] : state.tabsFor(id);
    if (id == null || tabs.isEmpty) return const ConnectionDetails();

    final active = state.activeFor(id)!;
    final notifier = ref.read(editorTabsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: cs.surfaceContainerLow,
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in tabs)
                        _TabButton(
                          tab: t,
                          selected: t.id == active.id,
                          onSelect: () => notifier.select(t.id),
                          onClose: () => notifier.close(t.id),
                        ),
                    ],
                  ),
                ),
                if (!ref.watch(connectionIsDocumentOnlyProvider(id)))
                  IconButton(
                    key: const Key('new-tab'),
                    tooltip: 'New query tab (${primaryLabel}T)',
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => notifier.open(id),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: tabs.indexWhere((t) => t.id == active.id),
            children: [
              for (final t in tabs)
                t.isCollection
                    ? DocumentTabView(key: ValueKey(t.id), tab: t)
                    : t.isTable
                    ? TableTabView(key: ValueKey(t.id), tab: t)
                    : QueryTabView(key: ValueKey(t.id), tab: t),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final EditorTab tab;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('tab-${tab.id}'),
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: selected ? cs.surface : null,
          border: Border(
            bottom: BorderSide(
              color: selected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              tab.isCollection
                  ? Icons.data_object
                  : tab.isTable
                  ? Icons.table_chart_outlined
                  : Icons.code,
              size: 14,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(tab.title, style: Theme.of(context).textTheme.labelLarge),
            IconButton(
              key: Key('close-${tab.id}'),
              tooltip: 'Close tab (${primaryLabel}W)',
              visualDensity: VisualDensity.compact,
              iconSize: 14,
              icon: const Icon(Icons.close),
              onPressed: () => unawaited(Future.sync(onClose)),
            ),
          ],
        ),
      ),
    );
  }
}
