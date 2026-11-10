import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/application/editor_tabs.dart';
import '../../schema/domain/schema_models.dart';
import '../application/diagram_controller.dart';
import 'diagram_canvas.dart';

/// A schema as an entity-relationship diagram: toolbar and canvas, or the
/// loading, failed and empty states.
class DiagramTabView extends ConsumerStatefulWidget {
  const DiagramTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<DiagramTabView> createState() => _DiagramTabViewState();
}

class _DiagramTabViewState extends ConsumerState<DiagramTabView> {
  final _canvas = GlobalKey<DiagramCanvasState>();
  final _scale = ValueNotifier<double>(1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _openTable(DiagramReady ready, String name) {
    final table = ready.graph.tables.where((t) => t.name == name).firstOrNull;
    final target = TableRef(
      database: widget.tab.tableRef?.database ?? '',
      schema: widget.tab.tableRef?.schema ?? '',
      table: name,
    );
    final tabs = ref.read(editorTabsProvider.notifier);
    if (table != null && table.type.isCollection) {
      tabs.openCollection(widget.tab.connectionId, target);
    } else {
      tabs.openTable(widget.tab.connectionId, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagramProvider(widget.tab.id));
    final controller = ref.read(diagramProvider(widget.tab.id).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          state: state,
          scale: _scale,
          onFit: () => _canvas.currentState?.fit(),
          onZoom: (factor) => _canvas.currentState?.zoomBy(factor),
          onRelayout: controller.relayout,
          onRefresh: () => unawaited(controller.load(refresh: true)),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (state) {
            DiagramLoading() => _Loading(
              state: state,
              onCancel: controller.cancel,
            ),
            DiagramFailed(:final message) => _Message(
              key: const Key('diagram-failed'),
              icon: Icons.error_outline,
              text: message,
              action: 'Retry',
              onAction: () => unawaited(controller.load(refresh: true)),
            ),
            DiagramReady() when state.isEmpty => const _Message(
              key: Key('diagram-empty'),
              icon: Icons.account_tree_outlined,
              text: 'This schema has no tables.',
            ),
            DiagramReady() => DiagramCanvas(
              key: _canvas,
              graph: state.graph,
              rects: state.rects,
              selected: state.selected,
              layoutRevision: state.layoutRevision,
              onSelect: controller.select,
              onMoveTable: controller.moveTable,
              onOpenTable: (name) => _openTable(state, name),
              onScaleChanged: (s) => _scale.value = s,
            ),
          },
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.state,
    required this.scale,
    required this.onFit,
    required this.onZoom,
    required this.onRelayout,
    required this.onRefresh,
  });

  final DiagramState state;
  final ValueNotifier<double> scale;
  final VoidCallback onFit;
  final ValueChanged<double> onZoom;
  final VoidCallback onRelayout;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final current = state;
    final ready = current is DiagramReady ? current : null;
    final shown = ready != null && !ready.isEmpty;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (ready != null)
              Text(
                '${ready.graph.tables.length} tables · '
                '${ready.graph.relationCount} relations',
                key: const Key('diagram-summary'),
                style: text.labelLarge,
              ),
            const Spacer(),
            IconButton(
              key: const Key('diagram-zoom-out'),
              tooltip: 'Zoom out (−)',
              icon: const Icon(Icons.remove, size: 18),
              onPressed: shown ? () => onZoom(0.8) : null,
            ),
            SizedBox(
              width: 48,
              child: ValueListenableBuilder(
                valueListenable: scale,
                builder: (_, value, _) => Text(
                  shown ? '${(value * 100).round()}%' : '',
                  key: const Key('diagram-zoom'),
                  textAlign: TextAlign.center,
                  style: text.labelMedium,
                ),
              ),
            ),
            IconButton(
              key: const Key('diagram-zoom-in'),
              tooltip: 'Zoom in (+)',
              icon: const Icon(Icons.add, size: 18),
              onPressed: shown ? () => onZoom(1.25) : null,
            ),
            IconButton(
              key: const Key('diagram-fit'),
              tooltip: 'Fit the diagram (0)',
              icon: const Icon(Icons.fit_screen_outlined, size: 18),
              onPressed: shown ? onFit : null,
            ),
            IconButton(
              key: const Key('diagram-relayout'),
              tooltip: 'Arrange automatically',
              icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
              onPressed: shown ? onRelayout : null,
            ),
            IconButton(
              key: const Key('diagram-refresh'),
              tooltip: 'Reload from the database',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: state is DiagramLoading ? null : onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.state, required this.onCancel});

  final DiagramLoading state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final known = state.tablesTotal > 0;
    return Center(
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: known ? state.tablesDone / state.tablesTotal : null,
            ),
            const SizedBox(height: 12),
            Text(
              known
                  ? 'Loading tables ${state.tablesDone} / ${state.tablesTotal}'
                  : 'Loading the schema…',
              key: const Key('diagram-loading'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('diagram-cancel'),
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(text),
          if (action != null) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('diagram-retry'),
              onPressed: onAction,
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}
