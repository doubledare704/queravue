import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/document_preview_controller.dart';
import '../application/document_tab_controller.dart' show DocView;
import 'doc_view_switch.dart';
import 'doc_views.dart';

class DocumentPreviewPane extends ConsumerStatefulWidget {
  const DocumentPreviewPane({
    super.key,
    required this.previewKey,
    this.title = 'Preview',
    this.idleHint = 'Run to preview up to $kDefaultPreviewLimit documents.',
    this.limit = kDefaultPreviewLimit,
    this.onLimit,
    this.onRun,
    this.showRun = false,
  });

  final Object previewKey;
  final String title;
  final String idleHint;
  final int limit;
  final ValueChanged<int>? onLimit;
  final VoidCallback? onRun;
  final bool showRun;

  @override
  ConsumerState<DocumentPreviewPane> createState() =>
      _DocumentPreviewPaneState();
}

class _DocumentPreviewPaneState extends ConsumerState<DocumentPreviewPane> {
  DocView _view = DocView.json;

  @override
  Widget build(BuildContext context) {
    final provider = documentPreviewProvider(widget.previewKey);
    final preview = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (widget.onLimit case final onLimit?)
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: const Key('preview-limit'),
                    initialValue: '${widget.limit}',
                    enabled: !preview.running,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limit',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      final limit = int.tryParse(text.trim());
                      if (limit != null) onLimit(limit);
                    },
                  ),
                ),
              if (preview.canCancel)
                TextButton(
                  key: const Key('preview-cancel'),
                  onPressed: ref.read(provider.notifier).reset,
                  child: const Text('Cancel'),
                )
              else if (widget.showRun)
                TextButton(
                  key: const Key('preview-run'),
                  onPressed: preview.running ? null : widget.onRun,
                  child: const Text('Run'),
                ),
            ],
          ),
        ),
        if (preview.docs.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: DocViewSwitch(
                view: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(child: _content(preview)),
      ],
    );
  }

  Widget _content(DocumentPreviewState preview) => switch (preview.phase) {
    PreviewPhase.idle => _Hint(widget.idleHint),
    PreviewPhase.running => const Center(child: CircularProgressIndicator()),
    PreviewPhase.failed => _Hint(
      preview.error ?? 'Preview failed.',
      error: true,
    ),
    PreviewPhase.done when preview.docs.isEmpty => const _Hint('No documents.'),
    PreviewPhase.done => switch (_view) {
      DocView.table => DocTableView(
        docs: preview.docs,
        columns: const [],
        selected: const {},
        firstIndex: 0,
      ),
      DocView.tree => DocTreeView(docs: preview.docs, selected: const {}),
      DocView.json => DocJsonView(docs: preview.docs, selected: const {}),
    },
  };
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      text,
      style: TextStyle(
        color: error ? Theme.of(context).colorScheme.error : null,
      ),
    ),
  );
}
