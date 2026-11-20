import 'package:flutter/material.dart';

import '../domain/gridfs_models.dart';

Future<String?> showGridFsNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _GridFsFieldsDialog(title: title, label: 'Name', initial: initial),
);

Future<GridFsUpload?> showGridFsUploadDialog(
  BuildContext context,
  String filename, {
  GridFsEntry? replacing,
}) => showDialog<GridFsUpload>(
  context: context,
  builder: (_) => _GridFsFieldsDialog(
    title: replacing == null ? 'Upload file' : 'Replace ${replacing.filename}',
    label: 'Filename',
    initial: filename,
    upload: true,
    replacing: replacing,
  ),
);

Future<bool> confirmGridFsWrite(
  BuildContext context,
  GridFsEntry file, {
  required bool production,
  required bool replace,
}) async {
  final verb = replace ? 'Replace' : 'Delete';
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(production ? '$verb file in production?' : '$verb file?'),
          content: Text(
            production
                ? '$verb “${file.filename}” on this production connection?'
                : '$verb “${file.filename}”?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(production ? '$verb in production' : verb),
            ),
          ],
        ),
      ) ??
      false;
}

class _GridFsFieldsDialog extends StatefulWidget {
  const _GridFsFieldsDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.upload = false,
    this.replacing,
  });

  final String title;
  final String label;
  final String initial;
  final bool upload;
  final GridFsEntry? replacing;

  @override
  State<_GridFsFieldsDialog> createState() => _GridFsFieldsDialogState();
}

class _GridFsFieldsDialogState extends State<_GridFsFieldsDialog> {
  late final _name = TextEditingController(text: widget.initial);
  final _contentType = TextEditingController();
  final _metadata = TextEditingController();

  void _submit() {
    final name = _name.text;
    if (name.trim().isEmpty) return;
    if (widget.upload) {
      Navigator.pop(
        context,
        GridFsUpload(
          filename: name,
          contentType: _contentType.text.trim(),
          metadata: _metadata.text.trim(),
          replaceId: widget.replacing?.id,
        ),
      );
    } else {
      Navigator.pop(context, name);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contentType.dispose();
    _metadata.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            controller: _name,
            decoration: InputDecoration(labelText: widget.label),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.upload) ...[
            TextField(
              controller: _contentType,
              decoration: const InputDecoration(
                labelText: 'Content type (optional)',
              ),
            ),
            TextField(
              controller: _metadata,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Metadata EJSON (optional)',
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.upload ? 'Upload' : 'OK'),
      ),
    ],
  );
}
