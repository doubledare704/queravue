import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/workspace_controller.dart';
import '../data/workspace_repository.dart';
import '../domain/workspace_models.dart';

/// Asks for one line of text. Null if cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirm = 'OK',
}) => showDialog<String>(
  context: context,
  builder: (_) => _PromptDialog(
    title: title,
    label: label,
    initial: initial,
    confirm: confirm,
  ),
);

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.confirm,
  });
  final String title;
  final String label;
  final String initial;
  final String confirm;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isNotEmpty) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('prompt-field'),
      controller: _c,
      autofocus: true,
      decoration: InputDecoration(labelText: widget.label),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('prompt-ok'),
        onPressed: _submit,
        child: Text(widget.confirm),
      ),
    ],
  );
}

Future<bool> confirmDeleteEntry(
  BuildContext context, {
  required String name,
  required bool isDir,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDir ? 'Delete folder?' : 'Delete file?'),
      content: Text(
        isDir
            ? '"$name" and everything in it will be deleted from disk.'
            : '"$name" will be deleted from disk.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

enum ConflictChoice { reload, keepMine }

/// The file changed on disk since it was opened.
Future<ConflictChoice?> showConflictDialog(
  BuildContext context, {
  required bool deleted,
  required String name,
}) => showDialog<ConflictChoice>(
  context: context,
  builder: (ctx) => AlertDialog(
    key: const Key('conflict-dialog'),
    title: const Text('File changed on disk'),
    content: Text(
      deleted
          ? '"$name" was deleted since you opened it. Saving recreates it.'
          : '"$name" was changed outside the app since you opened it. '
                'Overwrite it with your version, or reload the disk version?',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
      if (!deleted)
        TextButton(
          key: const Key('conflict-reload'),
          onPressed: () => Navigator.pop(ctx, ConflictChoice.reload),
          child: const Text('Reload'),
        ),
      FilledButton(
        key: const Key('conflict-keep'),
        onPressed: () => Navigator.pop(ctx, ConflictChoice.keepMine),
        child: Text(deleted ? 'Save anyway' : 'Overwrite'),
      ),
    ],
  ),
);

/// What the Save as dialog asked for.
class SaveAsRequest {
  const SaveAsRequest({
    required this.file,
    required this.title,
    required this.rememberConnection,
  });
  final FilePath file;
  final String title;
  final bool rememberConnection;
}

Future<SaveAsRequest?> showSaveAsDialog(
  BuildContext context, {
  required FileKind kind,
  required String suggested,
}) => showDialog<SaveAsRequest>(
  context: context,
  builder: (_) => _SaveAsDialog(kind: kind, suggested: suggested),
);

class _SaveAsDialog extends ConsumerStatefulWidget {
  const _SaveAsDialog({required this.kind, required this.suggested});
  final FileKind kind;
  final String suggested;

  @override
  ConsumerState<_SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends ConsumerState<_SaveAsDialog> {
  late final _path = TextEditingController(text: widget.suggested);
  final _title = TextEditingController();
  String? _root;
  bool _remember = true;

  @override
  void dispose() {
    _path.dispose();
    _title.dispose();
    super.dispose();
  }

  void _submit(List<WorkspaceRoot> roots) {
    final raw = _path.text.trim().replaceAll(RegExp(r'^/+'), '');
    if (raw.isEmpty || roots.isEmpty) return;
    Navigator.pop(
      context,
      SaveAsRequest(
        file: FilePath(
          _root ?? roots.first.id,
          withExtension(raw, widget.kind),
        ),
        title: _title.text.trim(),
        rememberConnection: _remember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = ref.watch(workspaceProvider.select((s) => s.roots));
    return AlertDialog(
      key: const Key('save-as-dialog'),
      title: const Text('Save to workspace'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (roots.length > 1)
              DropdownButtonFormField<String>(
                key: const Key('save-as-root'),
                initialValue: _root ?? roots.first.id,
                decoration: const InputDecoration(labelText: 'Workspace'),
                items: [
                  for (final r in roots)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _root = v),
              ),
            TextField(
              key: const Key('save-as-path'),
              controller: _path,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'File path',
                helperText:
                    'Folders are created as needed, e.g. reports/users.sql',
              ),
              onSubmitted: (_) => _submit(roots),
            ),
            TextField(
              key: const Key('save-as-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            CheckboxListTile(
              key: const Key('save-as-remember'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              title: const Text('Remember this connection in the file'),
              subtitle: const Text('Only its name, never credentials'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-as-ok'),
          onPressed: roots.isEmpty ? null : () => _submit(roots),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Quick open: search the workspace and pick a file.
Future<FilePath?> showQuickOpen(BuildContext context) =>
    showDialog<FilePath>(context: context, builder: (_) => const _QuickOpen());

class _QuickOpen extends ConsumerStatefulWidget {
  const _QuickOpen();

  @override
  ConsumerState<_QuickOpen> createState() => _QuickOpenState();
}

class _QuickOpenState extends ConsumerState<_QuickOpen> {
  final _q = TextEditingController();
  StreamSubscription<SearchHit>? _sub;
  Timer? _debounce;
  List<SearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_sub?.cancel());
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => _run(v));
  }

  void _run(String raw) {
    unawaited(_sub?.cancel());
    final q = parseSearch(raw);
    final hits = <SearchHit>[];
    setState(() => _hits = const []);
    _sub = ref
        .read(workspaceRepositoryProvider)
        .search(q.text, tags: q.tags)
        .listen((h) {
          hits.add(h);
          if (mounted) setState(() => _hits = [...hits]);
        }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) => Dialog(
    alignment: Alignment.topCenter,
    insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('quick-open-query'),
            controller: _q,
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Open workspace file (text, #tag)',
              border: InputBorder.none,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) {
              if (_hits.isNotEmpty) Navigator.pop(context, _hits.first.file);
            },
          ),
          const Divider(height: 1),
          Flexible(
            child: _hits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matching files'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _hits.length,
                    itemBuilder: (_, i) {
                      final h = _hits[i];
                      return ListTile(
                        key: Key('quick-open-${h.file.path}'),
                        dense: true,
                        leading: Icon(
                          h.kind == FileKind.mongo
                              ? Icons.terminal
                              : Icons.code,
                          size: 18,
                        ),
                        title: Text(
                          h.meta.title.isNotEmpty ? h.meta.title : h.file.name,
                        ),
                        subtitle: Text(h.file.path),
                        onTap: () => Navigator.pop(context, h.file),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
