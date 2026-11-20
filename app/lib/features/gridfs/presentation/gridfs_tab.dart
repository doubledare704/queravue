import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/domain/admin_models.dart' show formatBytes;
import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/gridfs_controller.dart';
import '../data/pdf_previewer.dart';
import 'gridfs_file_list.dart';
import 'gridfs_flows.dart';
import 'gridfs_preview_panel.dart';

class GridFsTab extends ConsumerStatefulWidget {
  const GridFsTab({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<GridFsTab> createState() => _GridFsTabState();
}

class _GridFsTabState extends ConsumerState<GridFsTab> {
  final _filter = TextEditingController();
  final _sort = TextEditingController(text: '{"_id":1}');

  @override
  void dispose() {
    _filter.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final provider = gridFsControllerProvider(tab.id);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final work = state.work;
    final selected = state.selection != null;
    final canAct = work == null;
    final canCancel = work?.canCancel ?? false;
    final session = ref.watch(connectionSessionProvider(tab.connectionId));
    if (state.target == null) {
      return Center(
        child: session.isConnecting
            ? const CircularProgressIndicator()
            : session.isConnected
            ? const Text('GridFS is unavailable on this connection.')
            : FilledButton.tonal(
                onPressed: () => ref
                    .read(connectionSessionProvider(tab.connectionId).notifier)
                    .connect(),
                child: const Text('Connect to open bucket'),
              ),
      );
    }

    void run(GridFsAction action) =>
        unawaited(runGridFsAction(context, ref, tab, action));
    void apply() => unawaited(controller.apply(_filter.text, _sort.text));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (canCancel) {
            controller.cancel();
          } else if (selected) {
            unawaited(controller.select(null));
          }
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: _queryField(_filter, 'Filter (EJSON)', apply)),
                const SizedBox(width: 8),
                Expanded(child: _queryField(_sort, 'Sort (EJSON)', apply)),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: canAct ? apply : null,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Upload',
                  onPressed: canAct ? () => run(GridFsAction.upload) : null,
                  icon: const Icon(Icons.upload_outlined),
                ),
                IconButton(
                  tooltip: 'Download',
                  onPressed: canAct && selected
                      ? () => run(GridFsAction.download)
                      : null,
                  icon: const Icon(Icons.download_outlined),
                ),
                IconButton(
                  tooltip: 'Rename',
                  onPressed: canAct && selected
                      ? () => run(GridFsAction.rename)
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Replace',
                  onPressed: canAct && selected
                      ? () => run(GridFsAction.replace)
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: canAct && selected
                      ? () => run(GridFsAction.delete)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: canCancel ? 'Cancel' : 'Refresh',
                  onPressed: canAct || canCancel
                      ? () => run(GridFsAction.refresh)
                      : null,
                  icon: Icon(canCancel ? Icons.close : Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: canAct && state.page.index > 0
                      ? controller.previousPage
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: canAct && state.page.hasNext
                      ? controller.nextPage
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                if (state.page.files.isNotEmpty)
                  Text(
                    '${state.page.index * gridFsPageSize + 1}–${state.page.index * gridFsPageSize + state.page.files.length}',
                  ),
                if (work?.total case final total?)
                  Text(
                    '${work!.task == GridFsTask.upload ? 'Uploading' : 'Downloading'} ${formatBytes(work.completed)} / ${formatBytes(total)}',
                  ),
              ],
            ),
          ),
          if (work != null)
            LinearProgressIndicator(
              value: switch (work.total) {
                final total? when total > 0 => (work.completed / total).clamp(
                  0,
                  1,
                ),
                _ => null,
              },
            )
          else
            const Divider(height: 1),
          if (state.error case final error?)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: state.page.files.isEmpty && work == null
                ? const Center(child: Text('No files match.'))
                : GridFsFileList(
                    page: state.page,
                    selectedId: state.selection?.file.id,
                    onSelect: (file) => unawaited(controller.select(file)),
                  ),
          ),
          if (selected) ...[
            const Divider(height: 1),
            Expanded(
              child: GridFsPreviewPanel(
                key: ValueKey(state.selection!.file.id),
                selection: state.selection,
                previewer: ref.watch(pdfPreviewerProvider),
                onDownload: canAct ? () => run(GridFsAction.download) : null,
                onClear: () => unawaited(controller.select(null)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _queryField(
    TextEditingController controller,
    String label,
    VoidCallback apply,
  ) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    onSubmitted: (_) => apply(),
  );
}
