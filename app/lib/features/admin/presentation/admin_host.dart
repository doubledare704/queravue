import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/admin_controllers.dart';
import 'indexes_panel.dart';
import 'stats_panel.dart';
import 'validation_panel.dart';

enum AdminSection { data, indexes, stats, validation }

/// Wraps a table or collection tab with Data | Indexes | Stats | Validation
/// sections. Only the sections the connection's capabilities allow appear;
/// with none, [child] is shown alone.
class AdminHost extends ConsumerStatefulWidget {
  const AdminHost({super.key, required this.tab, required this.child});

  final EditorTab tab;
  final Widget child;

  @override
  ConsumerState<AdminHost> createState() => _AdminHostState();
}

class _AdminHostState extends ConsumerState<AdminHost> {
  AdminSection _section = AdminSection.data;
  final _visited = {AdminSection.data};

  @override
  Widget build(BuildContext context) {
    final caps =
        ref.watch(connectionCapabilitiesProvider(widget.tab.connectionId)) ??
        const <String>{};
    final sections = [
      AdminSection.data,
      if (caps.contains('index_manager')) AdminSection.indexes,
      if (caps.contains('stats')) AdminSection.stats,
      if (caps.contains('validation')) AdminSection.validation,
    ];
    if (sections.length == 1) return widget.child;
    final active = sections.contains(_section) ? _section : AdminSection.data;
    final ref0 = widget.tab.tableRef;
    final target = ref0 == null
        ? null
        : AdminTarget(widget.tab.connectionId, ref0);

    Widget panel(AdminSection s) => switch (s) {
      AdminSection.data => widget.child,
      _ when target == null => const SizedBox.shrink(),
      AdminSection.indexes => IndexesPanel(target: target),
      AdminSection.stats => StatsPanel(target: target),
      AdminSection.validation => ValidationPanel(target: target),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<AdminSection>(
              key: const Key('admin-sections'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final s in sections)
                  ButtonSegment(
                    value: s,
                    label: Text(
                      s.name[0].toUpperCase() + s.name.substring(1),
                      key: Key('admin-section-${s.name}'),
                    ),
                  ),
              ],
              selected: {active},
              onSelectionChanged: (v) => setState(() {
                _section = v.first;
                _visited.add(_section);
              }),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: AdminSection.values.indexOf(active),
            children: [
              for (final s in AdminSection.values)
                _visited.contains(s) && sections.contains(s)
                    ? panel(s)
                    : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
