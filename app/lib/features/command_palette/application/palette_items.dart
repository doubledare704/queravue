import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../connections/presentation/connection_actions.dart';
import '../../editor/application/editor_tabs.dart';
import '../../keybindings/application/keybindings_controller.dart';
import '../../schema/application/schema_controller.dart';
import '../domain/palette_search.dart';

/// Everything the palette can show without asking the core: actions, open
/// tabs, saved connections and the objects the schema tree has loaded for the
/// selected connection.
final paletteItemsProvider = Provider<List<PaletteItem>>((ref) {
  final registry = ref.watch(actionRegistryProvider);
  final enabled = ref.watch(enabledActionIdsProvider);
  final connections =
      ref.watch(connectionsControllerProvider).value ?? const [];
  final nameOf = {for (final c in connections) c.id: c.name};
  final tabs = ref.watch(editorTabsProvider).tabs;
  final selected = ref.watch(selectedConnectionProvider);

  return [
    for (final a in registry.actions)
      PaletteItem(
        id: a.id,
        title: a.title,
        subtitle: a.subtitle,
        trailing: registry.shortcutLabel(a.id),
        conflicted: registry.isConflicted(a.id),
        enabled: enabled.contains(a.id),
        group: PaletteGroup.action,
        run: a.run,
      ),
    for (final t in tabs)
      PaletteItem(
        id: 'tab.${t.id}',
        title: t.title,
        subtitle: nameOf[t.connectionId] ?? '',
        group: PaletteGroup.tab,
        run: (context, ref) async {
          ref.read(selectedConnectionProvider.notifier).select(t.connectionId);
          ref.read(editorTabsProvider.notifier).select(t.id);
        },
      ),
    for (final c in connections)
      PaletteItem(
        id: 'connection.connect.${c.id}',
        title: 'Connect: ${c.name}',
        subtitle: [c.engineId, if (c.folder.isNotEmpty) c.folder].join(' · '),
        group: PaletteGroup.connection,
        run: (context, ref) => connectTo(ref, c),
      ),
    if (selected != null)
      ..._objectItems(ref, selected, nameOf[selected] ?? ''),
  ];
});

List<PaletteItem> _objectItems(
  Ref ref,
  String connectionId,
  String connectionName,
) {
  final tree = ref.watch(schemaTreeProvider(connectionId));
  final objects = {
    for (final nodes in tree.childrenByKey.values)
      for (final node in nodes.whereType<ObjectNode>()) node.tableRef: node,
  };
  return [
    for (final node in objects.values)
      PaletteItem(
        id: 'object.$connectionId.${node.key}',
        title: node.label,
        subtitle: [
          if (node.tableRef.database.isNotEmpty) node.tableRef.database,
          connectionName,
        ].join(' · '),
        group: PaletteGroup.object,
        run: (context, ref) async {
          final tabs = ref.read(editorTabsProvider.notifier);
          if (tree.documentStore) {
            tabs.openCollection(connectionId, node.tableRef);
          } else {
            tabs.openTable(connectionId, node.tableRef);
          }
        },
      ),
  ];
}
