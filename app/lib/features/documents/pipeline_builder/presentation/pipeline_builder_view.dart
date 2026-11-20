import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/document_preview_controller.dart';
import '../../presentation/document_preview_pane.dart';
import '../application/pipeline_builder_controller.dart';
import '../domain/pipeline_stage.dart';
import 'stage_card.dart';

Future<void> showPipelineBuilder(
  BuildContext context,
  PipelineTarget target, {
  String? initialPipeline,
}) => showDialog<void>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: PipelineBuilderView(
      target: target,
      initialPipeline: initialPipeline,
    ),
  ),
);

class PipelineBuilderView extends ConsumerStatefulWidget {
  const PipelineBuilderView({
    super.key,
    required this.target,
    this.initialPipeline,
  });

  final PipelineTarget target;
  final String? initialPipeline;

  @override
  ConsumerState<PipelineBuilderView> createState() =>
      _PipelineBuilderViewState();
}

class _PipelineBuilderViewState extends ConsumerState<PipelineBuilderView> {
  @override
  void initState() {
    super.initState();
    final initialPipeline = widget.initialPipeline;
    if (initialPipeline == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(pipelineBuilderProvider(widget.target).notifier)
            .importText(initialPipeline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final state = ref.watch(pipelineBuilderProvider(target));
    final controller = ref.read(pipelineBuilderProvider(target).notifier);
    final preview = ref.watch(documentPreviewProvider(target));
    final selectedIndex = state.stages.indexWhere(
      (s) => s.id == state.selectedId,
    );
    return Column(
      children: [
        _Toolbar(target: target, controller: controller),
        if (state.notice != null)
          MaterialBanner(
            key: const Key('pipeline-notice'),
            content: Text(state.notice!),
            actions: const [SizedBox.shrink()],
          ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: state.stages.isEmpty
                    ? const Center(
                        child: Text(
                          'No stages yet. Add one or import a pipeline.',
                        ),
                      )
                    : ReorderableListView.builder(
                        key: const Key('stage-list'),
                        buildDefaultDragHandles: false,
                        itemCount: state.stages.length,
                        onReorderItem: controller.moveStage,
                        itemBuilder: (context, i) {
                          final stage = state.stages[i];
                          return StageCard(
                            key: ValueKey('stage-${stage.id}'),
                            stage: stage,
                            index: i,
                            selected: stage.id == state.selectedId,
                            running:
                                preview.running && state.selectedId == stage.id,
                            fieldNames: state.fieldNames,
                            collectionNames: state.collectionNames,
                            actions: StageCardActions(
                              select: () => controller.select(stage.id),
                              toggleEnabled: (v) =>
                                  controller.setEnabled(stage.id, v),
                              setOperator: (o) =>
                                  controller.setOperator(stage.id, o),
                              setBody: (b) => controller.setBody(stage.id, b),
                              setRawText: (t) =>
                                  controller.setRawText(stage.id, t),
                              duplicate: () =>
                                  controller.duplicateStage(stage.id),
                              remove: () => controller.removeStage(stage.id),
                              preview: preview.running
                                  ? null
                                  : () => controller.runPreview(stage.id),
                            ),
                          );
                        },
                      ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: DocumentPreviewPane(
                  previewKey: target,
                  title: selectedIndex < 0
                      ? 'Preview'
                      : 'Preview after stage ${selectedIndex + 1}',
                  idleHint:
                      'Press play on a stage to preview the pipeline up to it.',
                  limit: state.previewLimit,
                  onLimit: controller.setPreviewLimit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.target, required this.controller});

  final PipelineTarget target;
  final PipelineBuilderController controller;

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Copied $what')));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Aggregation pipeline · ${target.database}.${target.collection}',
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          key: const Key('add-stage'),
          tooltip: 'Add stage',
          onSelected: controller.addStage,
          itemBuilder: (_) => [
            for (final o in typedStageOperators)
              PopupMenuItem(value: o, child: Text(o)),
            const PopupMenuDivider(),
            for (final o in rawStageOperators)
              PopupMenuItem(value: o, child: Text('$o (raw)')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 4),
                Text('Add stage'),
              ],
            ),
          ),
        ),
        TextButton(
          key: const Key('import-pipeline'),
          onPressed: () => showImportPipelineDialog(context, controller),
          child: const Text('Import'),
        ),
        PopupMenuButton<String>(
          key: const Key('export-pipeline'),
          tooltip: 'Export',
          onSelected: (v) => v == 'shell'
              ? _copy(context, controller.exportShell(), 'shell code')
              : _copy(context, controller.exportJson(), 'JSON'),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'shell', child: Text('Copy as shell code')),
            PopupMenuItem(value: 'json', child: Text('Copy as JSON')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.ios_share, size: 18),
                SizedBox(width: 4),
                Text('Export'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> showImportPipelineDialog(
  BuildContext context,
  PipelineBuilderController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _ImportDialog(controller: controller),
);

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.controller});

  final PipelineBuilderController controller;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import pipeline'),
    content: SizedBox(
      width: 520,
      child: TextField(
        key: const Key('import-text'),
        controller: _text,
        autofocus: true,
        minLines: 8,
        maxLines: 14,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: const InputDecoration(
          hintText:
              r'[{ $match: { status: "A" } }] or db.orders.aggregate([...])',
          border: OutlineInputBorder(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('import-confirm'),
        onPressed: () {
          if (widget.controller.importText(_text.text)) Navigator.pop(context);
        },
        child: const Text('Import'),
      ),
    ],
  );
}
