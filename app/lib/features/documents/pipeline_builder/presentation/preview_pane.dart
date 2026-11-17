import 'package:flutter/material.dart';

import '../../domain/ejson.dart';
import '../application/pipeline_builder_controller.dart';

String previewLine(String ejson) {
  try {
    return shellCompact(decodeEjson(ejson), maxChars: 400);
  } on FormatException {
    return ejson;
  }
}

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.preview,
    required this.stageNumber,
    required this.limit,
    required this.onLimit,
    required this.onCancel,
  });

  final StagePreview preview;
  final int? stageNumber;
  final int limit;
  final ValueChanged<int> onLimit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  stageNumber == null
                      ? 'Preview'
                      : 'Preview after stage $stageNumber',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  key: const Key('preview-limit'),
                  initialValue: '$limit',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Limit',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (t) {
                    final n = int.tryParse(t.trim());
                    if (n != null) onLimit(n);
                  },
                ),
              ),
              if (preview.phase == PreviewPhase.running)
                TextButton(
                  key: const Key('preview-cancel'),
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _content(theme)),
      ],
    );
  }

  Widget _content(ThemeData theme) {
    switch (preview.phase) {
      case PreviewPhase.idle:
        return const _Hint(
          'Press play on a stage to preview the pipeline up to it.',
        );
      case PreviewPhase.running:
        return const Center(child: CircularProgressIndicator());
      case PreviewPhase.failed:
        return _Hint(preview.error ?? 'Preview failed.', error: true);
      case PreviewPhase.done:
        if (preview.documents.isEmpty) return const _Hint('No documents.');
        return ListView.separated(
          key: const Key('preview-list'),
          itemCount: preview.documents.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              previewLine(preview.documents[i]),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        );
    }
  }
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
