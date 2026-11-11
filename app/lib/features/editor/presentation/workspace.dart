import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/panes/pane_sizes.dart';
import '../../../shared/shortcuts.dart';
import '../../connections/application/connection_session.dart';
import '../../admin/presentation/admin_host.dart';
import '../../connections/application/connections_controller.dart';
import '../../designer/presentation/designer_tab_view.dart';
import '../../diagram/presentation/diagram_tab_view.dart';
import '../../documents/presentation/document_tab_view.dart';
import '../../shell/presentation/shell_tab_view.dart';
import '../../workspace/application/tab_files.dart';
import '../../workspace/presentation/file_banner.dart';
import '../application/editor_actions.dart';
import '../../connections/presentation/connection_details.dart';
import '../../table_view/presentation/table_tab_view.dart';
import '../application/editor_tabs.dart';
import '../application/editor_layout_controller.dart';
import '../application/layout_persistence.dart';
import '../domain/editor_layout.dart';
import 'query_tab_view.dart';

/// Right-hand pane: the editor groups of the selected connection, or its
/// details when no tab is open.
class Workspace extends ConsumerWidget {
  const Workspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(selectedConnectionProvider);
    final tabs = id == null
        ? const <EditorTab>[]
        : ref.watch(editorTabsProvider).tabsFor(id);
    if (id == null || tabs.isEmpty) return const ConnectionDetails();
    final layout = ref.watch(editorLayoutProvider).of(id);
    final byId = {for (final t in tabs) t.id: t};
    final maximized = ref.watch(
      paneSizesProvider.select((p) => p.editorMaximized),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final horizontal = layout.axis == Axis.horizontal;
        final extent = horizontal ? box.maxWidth : box.maxHeight;
        final count = layout.groups.length;
        final shared = extent - _dividerThickness * (count - 1);
        final children = <Widget>[];
        var start = 0.0;
        for (var i = 0; i < count; i++) {
          if (i > 0) {
            if (!maximized) {
              children.add(
                _slot(
                  key: ValueKey('divider-slot-${i - 1}'),
                  horizontal: horizontal,
                  start: start,
                  length: _dividerThickness,
                  child: _Divider(
                    key: Key('group-divider-${i - 1}'),
                    axis: layout.axis,
                    onDrag: (px) => ref
                        .read(editorLayoutProvider.notifier)
                        .resize(id, i - 1, px / extent),
                  ),
                ),
              );
            }
            start += _dividerThickness;
          }
          final length = shared * layout.fractions[i];
          final pane = Offstage(
            offstage: maximized && i != layout.focused,
            child: _GroupPane(
              key: Key('group-$i'),
              connectionId: id,
              index: i,
              group: layout.groups[i],
              focused: i == layout.focused,
              split: count > 1,
              maximized: maximized,
              tabs: byId,
            ),
          );
          children.add(
            maximized
                ? Positioned.fill(key: ValueKey('group-slot-$i'), child: pane)
                : _slot(
                    key: ValueKey('group-slot-$i'),
                    horizontal: horizontal,
                    start: start,
                    length: length,
                    child: pane,
                  ),
          );
          start += length;
        }
        return Stack(children: children);
      },
    );
  }
}

const _dividerThickness = 6.0;

Positioned _slot({
  required Key key,
  required bool horizontal,
  required double start,
  required double length,
  required Widget child,
}) => horizontal
    ? Positioned(
        key: key,
        left: start,
        width: length,
        top: 0,
        bottom: 0,
        child: child,
      )
    : Positioned(
        key: key,
        top: start,
        height: length,
        left: 0,
        right: 0,
        child: child,
      );

class _Divider extends StatelessWidget {
  const _Divider({super.key, required this.axis, required this.onDrag});

  final Axis axis;
  final void Function(double pixels) onDrag;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: horizontal ? (d) => onDrag(d.delta.dx) : null,
        onVerticalDragUpdate: horizontal ? null : (d) => onDrag(d.delta.dy),
        child: SizedBox(
          width: horizontal ? _dividerThickness : null,
          height: horizontal ? null : _dividerThickness,
          child: Center(
            child: Container(
              width: horizontal ? 1 : null,
              height: horizontal ? null : 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupPane extends ConsumerWidget {
  const _GroupPane({
    super.key,
    required this.connectionId,
    required this.index,
    required this.group,
    required this.focused,
    required this.split,
    required this.maximized,
    required this.tabs,
  });

  final String connectionId;
  final int index;
  final EditorGroup group;
  final bool focused;
  final bool split;
  final bool maximized;
  final Map<String, EditorTab> tabs;

  void _drop(WidgetRef ref, String tabId, {String? before}) => ref
      .read(editorLayoutProvider.notifier)
      .moveTab(connectionId, tabId, index, before: before);

  void _focus(WidgetRef ref) {
    if (!focused) {
      ref.read(editorLayoutProvider.notifier).focusGroup(connectionId, index);
    }
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    EditorTab tab,
    Offset at,
  ) async {
    ref.read(editorTabsProvider.notifier).select(tab.id);
    final layout = ref.read(editorLayoutProvider);
    final current = layout.of(connectionId);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        PopupMenuItem(
          value: 'right',
          enabled: current.canSplit,
          child: const Text('Split right'),
        ),
        PopupMenuItem(
          value: 'down',
          enabled: current.canSplit,
          child: const Text('Split down'),
        ),
        PopupMenuItem(
          value: 'next',
          enabled: current.groups.length > 1,
          child: const Text('Move to next group'),
        ),
        const PopupMenuItem(value: 'close', child: Text('Close')),
      ],
    );
    final controller = ref.read(editorLayoutProvider.notifier);
    switch (choice) {
      case 'right':
        controller.split(connectionId, Axis.horizontal);
      case 'down':
        controller.split(connectionId, Axis.vertical);
      case 'next':
        controller.moveActive(connectionId, 1);
      case 'close':
        ref.read(editorTabsProvider.notifier).close(tab.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = [
      for (final id in group.tabIds)
        if (tabs[id] != null) tabs[id]!,
    ];
    if (members.isEmpty) return const SizedBox.shrink();
    final active = tabs[group.activeId] ?? members.last;
    final cs = Theme.of(context).colorScheme;
    return Listener(
      onPointerDown: (_) => _focus(ref),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (d) => group.tabIds.lastOrNull != d.data,
        onAcceptWithDetails: (d) => _drop(ref, d.data),
        builder: (context, incoming, _) => Container(
          foregroundDecoration: incoming.isEmpty
              ? null
              : BoxDecoration(border: Border.all(color: cs.primary, width: 2)),
          child: _content(context, ref, members, active),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<EditorTab> members,
    EditorTab active,
  ) {
    final notifier = ref.read(editorTabsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: cs.surfaceContainerLow,
          child: Container(
            key: Key('group-bar-$index'),
            height: 36,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: split && focused ? cs.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in members)
                        _TabButton(
                          tab: t,
                          selected: t.id == active.id,
                          onSelect: () => notifier.select(t.id),
                          onClose: () => notifier.close(t.id),
                          onContextMenu: (at) => _showMenu(context, ref, t, at),
                          onDropBefore: (dragged) =>
                              _drop(ref, dragged, before: t.id),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('maximize-group-$index'),
                  tooltip: maximized
                      ? 'Restore editor groups ($primaryLabel⇧M)'
                      : 'Maximize editor group ($primaryLabel⇧M)',
                  icon: Icon(
                    maximized ? Icons.fullscreen_exit : Icons.fullscreen,
                    size: 18,
                  ),
                  onPressed: () {
                    _focus(ref);
                    ref
                        .read(paneSizesProvider.notifier)
                        .toggleEditorMaximized();
                  },
                ),
                if (ref.watch(connectionHasShellProvider(connectionId)))
                  IconButton(
                    key: Key(
                      index == 0 ? 'new-shell-tab' : 'new-shell-tab-$index',
                    ),
                    tooltip: 'New Mongo shell ($primaryLabel⇧T)',
                    icon: const Icon(Icons.terminal, size: 18),
                    onPressed: () {
                      _focus(ref);
                      openShellTab(ref);
                    },
                  ),
                if (!ref.watch(connectionIsDocumentOnlyProvider(connectionId)))
                  IconButton(
                    key: Key(index == 0 ? 'new-tab' : 'new-tab-$index'),
                    tooltip: 'New query tab (${primaryLabel}T)',
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      _focus(ref);
                      notifier.open(connectionId);
                    },
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        FileChangeBanner(key: ValueKey('banner-${active.id}'), tab: active),
        Expanded(
          child: _GroupBody(members: members, active: active),
        ),
      ],
    );
  }
}

/// Builds a tab's view only once the tab has been shown, then keeps it alive,
/// so tabs restored in the background cost nothing until the user looks.
class _GroupBody extends ConsumerStatefulWidget {
  const _GroupBody({required this.members, required this.active});

  final List<EditorTab> members;
  final EditorTab active;

  @override
  ConsumerState<_GroupBody> createState() => _GroupBodyState();
}

class _GroupBodyState extends ConsumerState<_GroupBody> {
  final _shown = <String>{};

  @override
  Widget build(BuildContext context) {
    if (_shown.add(widget.active.id)) {
      final id = widget.active.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(ref.read(layoutPersistenceProvider).ensureLoaded(id));
        }
      });
    }
    final visible = [
      for (final t in widget.members)
        if (_shown.contains(t.id)) t,
    ];
    return IndexedStack(
      index: visible.indexWhere((t) => t.id == widget.active.id),
      children: [
        for (final t in visible) _TabView(key: ValueKey(t.id), tab: t),
      ],
    );
  }
}

class _TabView extends StatelessWidget {
  const _TabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context) => tab.isShell
      ? ShellTabView(tab: tab)
      : tab.isDesigner
      ? DesignerTabView(tab: tab)
      : tab.isDiagram
      ? DiagramTabView(tab: tab)
      : tab.isCollection
      ? AdminHost(
          tab: tab,
          child: DocumentTabView(tab: tab),
        )
      : tab.isTable
      ? AdminHost(
          tab: tab,
          child: TableTabView(tab: tab),
        )
      : QueryTabView(tab: tab);
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onSelect,
    required this.onClose,
    required this.onContextMenu,
    required this.onDropBefore,
  });

  final EditorTab tab;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onClose;
  final void Function(Offset globalPosition) onContextMenu;
  final void Function(String draggedTabId) onDropBefore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != tab.id,
      onAcceptWithDetails: (d) => onDropBefore(d.data),
      builder: (context, incoming, _) => Draggable<String>(
        data: tab.id,
        feedback: Material(
          elevation: 4,
          color: cs.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(tab.title),
          ),
        ),
        child: Container(
          foregroundDecoration: incoming.isEmpty
              ? null
              : BoxDecoration(
                  border: Border(left: BorderSide(color: cs.primary, width: 2)),
                ),
          child: _button(context, cs),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, ColorScheme cs) {
    return InkWell(
      key: Key('tab-${tab.id}'),
      onTap: onSelect,
      onSecondaryTapDown: (d) => onContextMenu(d.globalPosition),
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
                  : tab.isDiagram
                  ? Icons.account_tree_outlined
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
