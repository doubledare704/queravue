import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shortcuts.dart';
import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../documents/presentation/document_tab_view.dart';
import '../../shell/presentation/shell_tab_view.dart';
import '../../workspace/application/tab_files.dart';
import '../../workspace/presentation/file_banner.dart';
import '../application/editor_actions.dart';
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
                if (ref.watch(connectionHasShellProvider(id)))
                  IconButton(
                    key: const Key('new-shell-tab'),
                    tooltip: 'New Mongo shell ($primaryLabel⇧T)',
                    icon: const Icon(Icons.terminal, size: 18),
                    onPressed: () => openShellTab(ref),
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
        FileChangeBanner(key: ValueKey('banner-${active.id}'), tab: active),
        Expanded(
          child: IndexedStack(
            index: tabs.indexWhere((t) => t.id == active.id),
            children: [
              for (final t in tabs)
                t.isShell
                    ? ShellTabView(key: ValueKey(t.id), tab: t)
                    : t.isCollection
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
              tab.isShell
                  ? Icons.terminal
                  : tab.isCollection
                  ? Icons.data_object
                  : tab.isTable
                  ? Icons.table_chart_outlined
                  : Icons.code,
              size: 14,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            _TabTitle(tab: tab),
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

/// Tab title, with a dot while the buffer differs from its workspace file.
class _TabTitle extends ConsumerStatefulWidget {
  const _TabTitle({required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<_TabTitle> createState() => _TabTitleState();
}

class _TabTitleState extends ConsumerState<_TabTitle> {
  @override
  void initState() {
    super.initState();
    widget.tab.controller.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(_TabTitle old) {
    super.didUpdateWidget(old);
    if (old.tab.controller != widget.tab.controller) {
      old.tab.controller.removeListener(_onEdit);
      widget.tab.controller.addListener(_onEdit);
    }
  }

  @override
  void dispose() {
    widget.tab.controller.removeListener(_onEdit);
    super.dispose();
  }

  // The editor notifies while it is being built; rebuild after the frame.
  void _onEdit() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final file = ref.watch(tabFileProvider(tab.id));
    final style = Theme.of(context).textTheme.labelLarge;
    if (!isTabDirty(tab, file)) return Text(tab.title, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            Icons.circle,
            key: Key('tab-dirty-${tab.id}'),
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(tab.title, style: style),
      ],
    );
  }
}
