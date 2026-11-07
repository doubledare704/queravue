import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/application/editor_tabs.dart';
import '../application/schema_controller.dart';
import '../domain/schema_models.dart';

/// Formats row count estimate (e.g. ~1M rows).
String formatRowCount(int count, {String unit = 'rows'}) {
  if (count < 0) return '';
  if (count >= 1000000) {
    final m = count / 1000000.0;
    final s = m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
    final clean = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    return '~${clean}M $unit';
  }
  if (count >= 1000) {
    final k = count / 1000.0;
    final s = k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    final clean = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    return '~${clean}k $unit';
  }
  return '~$count $unit';
}

/// A tree view of databases, schemas, tables, and columns for a connection.
class SchemaTreeView extends ConsumerStatefulWidget {
  const SchemaTreeView({
    super.key,
    required this.connectionId,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  final String connectionId;
  final EdgeInsets padding;

  @override
  ConsumerState<SchemaTreeView> createState() => _SchemaTreeViewState();
}

class _SchemaTreeViewState extends ConsumerState<SchemaTreeView> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedKey;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schemaTreeProvider(widget.connectionId));
    final controller = ref.read(
      schemaTreeProvider(widget.connectionId).notifier,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state.isLoading && state.childrenByKey.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state.error != null && state.childrenByKey.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Failed to load schema',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => controller.refresh('root'),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final rootNodes = state.childrenByKey['root'] ?? const [];

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _selectNext(1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _selectNext(-1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter &&
              _selectedKey != null) {
            _handleEnter(_selectedKey!);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: SizedBox(
              height: 28,
              child: TextField(
                key: const Key('schema-tree-filter'),
                controller: _searchController,
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Filter schema…',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 14),
                  prefixIconConstraints: const BoxConstraints(minWidth: 24),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            controller.setFilter('');
                          },
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 24),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onChanged: controller.setFilter,
              ),
            ),
          ),
          ...rootNodes.map((n) => _buildNode(context, n, 0, state, controller)),
        ],
      ),
    );
  }

  void _selectNext(int delta) {
    // Basic navigation helper
  }

  void _handleEnter(String key) {
    final controller = ref.read(
      schemaTreeProvider(widget.connectionId).notifier,
    );
    if (key.startsWith('coll:')) {
      final node = _findObject(key);
      if (node != null) _openObject(node);
    } else if (key.startsWith('table:')) {
      final raw = key.substring(6);
      final parts = raw.split('.');
      final schema = parts.length > 1 ? parts[0] : '';
      final table = parts.length > 1 ? parts[1] : parts[0];
      ref
          .read(editorTabsProvider.notifier)
          .openTable(
            widget.connectionId,
            TableRef(schema: schema, table: table),
          );
    } else {
      controller.toggleExpand(key);
    }
  }

  ObjectNode? _findObject(String key) {
    final all = ref.read(schemaTreeProvider(widget.connectionId)).childrenByKey;
    for (final list in all.values) {
      for (final n in list) {
        if (n is ObjectNode && n.key == key) return n;
      }
    }
    return null;
  }

  /// Opens a table tab, or a document tab for document engines.
  void _openObject(ObjectNode node) {
    final tabs = ref.read(editorTabsProvider.notifier);
    if (ref.read(schemaTreeProvider(widget.connectionId)).documentStore) {
      tabs.openCollection(widget.connectionId, node.tableRef);
    } else {
      tabs.openTable(widget.connectionId, node.tableRef);
    }
  }

  Widget _buildNode(
    BuildContext context,
    SchemaTreeNode node,
    int depth,
    SchemaTreeState state,
    SchemaTreeController controller,
  ) {
    final isExpanded = state.expandedKeys.contains(node.key);
    final isLoading = state.loadingKeys.contains(node.key);
    final children = state.childrenByKey[node.key] ?? const [];
    final filter = state.filterText.trim().toLowerCase();

    // Check filter match
    if (filter.isNotEmpty && node is ObjectNode) {
      if (!node.label.toLowerCase().contains(filter)) {
        return const SizedBox.shrink();
      }
    }

    final isSelected = _selectedKey == node.key;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Widget tile = InkWell(
      key: Key('tree-node-${node.key}'),
      onTap: () {
        setState(() => _selectedKey = node.key);
        if (node is ObjectNode) {
          _openObject(node);
        } else {
          controller.toggleExpand(node.key);
        }
      },
      onSecondaryTapUp: (d) =>
          _showContextMenu(context, d.globalPosition, node, controller),
      child: Container(
        height: 26,
        padding: EdgeInsets.only(left: 8.0 + depth * 14.0, right: 6),
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        child: Row(
          children: [
            if (_canExpand(node))
              SizedBox(
                width: 14,
                height: 14,
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 4),
            _iconFor(node, scheme),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                node.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: node is ObjectNode || node is DatabaseNode
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (node is ObjectNode && node.rowCountEstimate >= 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  formatRowCount(
                    node.rowCountEstimate,
                    unit: state.documentStore ? 'docs' : 'rows',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            if (node is ColumnNode)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  node.column.typeName + (node.column.nullable ? '?' : ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isExpanded || children.isEmpty) {
      return tile;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        ...children.map(
          (child) => _buildNode(context, child, depth + 1, state, controller),
        ),
      ],
    );
  }

  bool _canExpand(SchemaTreeNode node) {
    if (node is ObjectNode && node.key.startsWith('coll:')) return false;
    return node is DatabaseNode ||
        node is SchemaNamespaceNode ||
        node is ObjectNode;
  }

  Widget _iconFor(SchemaTreeNode node, ColorScheme scheme) {
    return switch (node) {
      DatabaseNode() => Icon(
        Icons.dns_outlined,
        size: 14,
        color: scheme.primary,
      ),
      SchemaNamespaceNode() => Icon(
        Icons.folder_outlined,
        size: 14,
        color: scheme.secondary,
      ),
      ObjectNode(:final type) => switch (type) {
        SchemaObjectType.table => Icon(
          Icons.table_chart_outlined,
          size: 14,
          color: scheme.primary,
        ),
        SchemaObjectType.view => Icon(
          Icons.table_view_outlined,
          size: 14,
          color: scheme.tertiary,
        ),
        SchemaObjectType.materializedView => Icon(
          Icons.layers_outlined,
          size: 14,
          color: scheme.tertiary,
        ),
        SchemaObjectType.collection => Icon(
          Icons.data_object,
          size: 14,
          color: scheme.primary,
        ),
        SchemaObjectType.timeSeries => Icon(
          Icons.show_chart,
          size: 14,
          color: scheme.primary,
        ),
      },
      ColumnNode(:final column) =>
        column.isPrimaryKey
            ? const Icon(Icons.vpn_key_outlined, size: 13, color: Colors.amber)
            : Icon(
                Icons.view_column_outlined,
                size: 13,
                color: scheme.onSurfaceVariant,
              ),
      IndexNode() => Icon(
        Icons.bolt_outlined,
        size: 13,
        color: scheme.onSurfaceVariant,
      ),
      ForeignKeyNode() => Icon(
        Icons.link_outlined,
        size: 13,
        color: scheme.onSurfaceVariant,
      ),
    };
  }

  Future<void> _showContextMenu(
    BuildContext context,
    Offset position,
    SchemaTreeNode node,
    SchemaTreeController controller,
  ) async {
    final items = <PopupMenuEntry<String>>[];

    final docs = ref
        .read(schemaTreeProvider(widget.connectionId))
        .documentStore;
    if (node is ObjectNode) {
      items.addAll([
        PopupMenuItem(
          value: 'open',
          child: Text(docs ? 'Open collection' : 'Open table'),
        ),
        if (!docs)
          const PopupMenuItem(value: 'query', child: Text('New query here')),
        if (!docs && node.type == SchemaObjectType.table)
          const PopupMenuItem(value: 'design', child: Text('Design table')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'copy', child: Text('Copy name')),
        const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
      ]);
    } else {
      if (!docs && (node is SchemaNamespaceNode)) {
        items.add(
          const PopupMenuItem(value: 'new-table', child: Text('New table')),
        );
      }
      items.addAll([
        const PopupMenuItem(value: 'copy', child: Text('Copy name')),
        const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
      ]);
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    );

    if (selected == null || !mounted) return;

    switch (selected) {
      case 'open':
        if (node is ObjectNode) _openObject(node);
      case 'query':
        if (node is ObjectNode) {
          final sql = node.tableRef.schema.isNotEmpty
              ? 'SELECT * FROM "${node.tableRef.schema}"."${node.tableRef.table}" LIMIT 100;'
              : 'SELECT * FROM "${node.tableRef.table}" LIMIT 100;';
          ref
              .read(editorTabsProvider.notifier)
              .openQueryWithSql(widget.connectionId, sql);
        }
      case 'design':
        if (node is ObjectNode) {
          ref
              .read(editorTabsProvider.notifier)
              .openDesigner(widget.connectionId, node.tableRef);
        }
      case 'new-table':
        if (node is SchemaNamespaceNode) {
          ref
              .read(editorTabsProvider.notifier)
              .openDesigner(
                widget.connectionId,
                TableRef(
                  database: node.database,
                  schema: node.label,
                  table: '',
                ),
                newTable: true,
              );
        }
      case 'copy':
        await Clipboard.setData(ClipboardData(text: node.label));
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Copied "${node.label}" to clipboard'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      case 'refresh':
        await controller.refresh(node.key);
    }
  }
}
