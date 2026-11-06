import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../../shared/shortcuts.dart';
import '../../editor/domain/text_offsets.dart';
import '../application/document_tab_controller.dart';
import '../domain/doc_diff.dart';
import '../domain/ejson.dart';
import '../domain/models.dart';

/// Template for a new document.
const String kNewDocumentTemplate = '{\n  \n}';

/// Confirms deleting [count] documents. Always asks; on a production
/// connection the wording and button say so.
Future<bool> confirmDelete(
  BuildContext context, {
  required int count,
  required bool production,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('doc-delete-dialog'),
      title: Text(count == 1 ? 'Delete document?' : 'Delete $count documents?'),
      content: Text(
        production
            ? 'This connection is flagged as PRODUCTION. The '
                  '${count == 1 ? 'document' : 'documents'} will be removed '
                  'permanently.'
            : 'The ${count == 1 ? 'document' : 'documents'} will be removed '
                  'permanently.',
      ),
      actions: [
        TextButton(
          key: const Key('doc-delete-cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('doc-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(production ? 'Delete from production' : 'Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// What the user chose after a write conflict.
enum ConflictChoice { reload, overwrite, cancel }

/// "Document changed on server — reload / overwrite". When the document was
/// deleted, overwriting is not offered.
Future<ConflictChoice> showConflictDialog(
  BuildContext context, {
  required bool deleted,
}) async {
  final c = await showDialog<ConflictChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('doc-conflict-dialog'),
      title: Text(
        deleted ? 'Document deleted on server' : 'Document changed on server',
      ),
      content: Text(
        deleted
            ? 'Someone deleted this document while you were editing it. '
                  'Nothing was saved.'
            : 'The stored document differs from the version you started '
                  'from. Nothing was saved. Reload to see the current '
                  'version, or overwrite it with your edits.',
      ),
      actions: [
        TextButton(
          key: const Key('doc-conflict-cancel'),
          onPressed: () => Navigator.pop(ctx, ConflictChoice.cancel),
          child: const Text('Keep editing'),
        ),
        TextButton(
          key: const Key('doc-conflict-reload'),
          onPressed: () => Navigator.pop(ctx, ConflictChoice.reload),
          child: const Text('Reload'),
        ),
        if (!deleted)
          FilledButton(
            key: const Key('doc-conflict-overwrite'),
            onPressed: () => Navigator.pop(ctx, ConflictChoice.overwrite),
            child: const Text('Overwrite'),
          ),
      ],
    ),
  );
  return c ?? ConflictChoice.cancel;
}

/// Opens the document editor: [original] edits that document, null inserts a
/// new one.
Future<void> showDocumentEditor(
  BuildContext context, {
  required String tabId,
  DocItem? original,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => DocumentEditorDialog(tabId: tabId, original: original),
);

/// Code editor for one document's canonical EJSON, with a type-preserving
/// diff of the changes and conflict handling on save.
class DocumentEditorDialog extends ConsumerStatefulWidget {
  const DocumentEditorDialog({super.key, required this.tabId, this.original});

  final String tabId;
  final DocItem? original;

  @override
  ConsumerState<DocumentEditorDialog> createState() => _EditorState();
}

class _EditorState extends ConsumerState<DocumentEditorDialog> {
  late final CodeLineEditingController _code;
  late final String _initial;
  bool _showDiff = false;
  bool _saving = false;
  String? _serverError;
  late String _lastText;

  bool get _isEdit => widget.original != null;

  @override
  void initState() {
    super.initState();
    _initial = _isEdit
        ? prettyEjson(widget.original!.text)
        : kNewDocumentTemplate;
    _lastText = _initial;
    _code = CodeLineEditingController.fromText(_initial)..addListener(_onEdit);
  }

  @override
  void dispose() {
    _code.removeListener(_onEdit);
    _code.dispose();
    super.dispose();
  }

  void _onEdit() {
    // The editor also notifies on mount and on caret moves, possibly while
    // the tree is building; only a real text change needs a rebuild.
    final t = _code.text;
    if (t == _lastText) return;
    _lastText = t;
    if (mounted) setState(() => _serverError = null);
  }

  /// Local syntax check; null when the text is valid JSON.
  String? get _syntaxError {
    try {
      final v = jsonDecode(_code.text);
      if (v is! Map) return 'A document must be a JSON object.';
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  bool get _changed => _code.text != _initial;

  Future<void> _save({bool overwrite = false}) async {
    if (_syntaxError != null || (_isEdit && !_changed) || _saving) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final c = ref.read(documentTabProvider(widget.tabId).notifier);
    final text = _code.text;
    final outcome = _isEdit
        ? await c.replace(widget.original!, text, overwrite: overwrite)
        : await c.insert(text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case WriteOk():
        Navigator.pop(context);
      case WriteFailed(:final error):
        _showServerError(error, text);
      case WriteConflict(:final current):
        final choice = await showConflictDialog(
          context,
          deleted: current == null,
        );
        if (!mounted) return;
        switch (choice) {
          case ConflictChoice.overwrite:
            await _save(overwrite: true);
          case ConflictChoice.reload:
            Navigator.pop(context);
            await c.refresh();
          case ConflictChoice.cancel:
            break;
        }
    }
  }

  void _showServerError(DocumentError e, String text) {
    setState(() {
      final at = e.position == null ? '' : ' (at character ${e.position! + 1})';
      _serverError = '${e.message}$at';
    });
    final pos = e.position;
    if (e.kind == DocErrorKind.parse && pos != null && pos <= text.length) {
      final (line, col) = positionOfOffset(text, pos);
      _code.selection = CodeLineSelection.collapsed(index: line, offset: col);
      _code.makeCursorCenterIfInvisible();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final syntax = _syntaxError;
    final err = _serverError ?? syntax;
    final canSave = syntax == null && (!_isEdit || _changed) && !_saving;

    Widget body;
    if (_showDiff) {
      List<DiffLine> lines;
      try {
        lines = diffDocuments(widget.original!.text, _code.text);
      } on FormatException {
        lines = const [];
      }
      final changes = lines.where((l) => l.kind != DiffKind.same).length;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              changes == 0
                  ? 'No changes.'
                  : '$changes changed line${changes == 1 ? '' : 's'} · types '
                        'are compared in canonical form (an Int32 turned into '
                        'an Int64 shows as a change)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              key: const Key('doc-diff-list'),
              itemCount: lines.length,
              itemBuilder: (_, i) {
                final l = lines[i];
                final color = switch (l.kind) {
                  DiffKind.added => Colors.green.withValues(alpha: 0.18),
                  DiffKind.removed => cs.error.withValues(alpha: 0.18),
                  DiffKind.same => null,
                };
                return Container(
                  color: color,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${switch (l.kind) {
                      DiffKind.added => '+ ',
                      DiffKind.removed => '- ',
                      DiffKind.same => '  ',
                    }}${l.text}',
                    style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      body = CodeEditor(
        key: const Key('doc-code-editor'),
        controller: _code,
        autofocus: true,
        wordWrap: false,
        style: CodeEditorStyle(
          fontSize: 13,
          fontFamily: 'Menlo',
          backgroundColor: cs.surface,
          codeTheme: CodeHighlightTheme(
            languages: {'json': CodeHighlightThemeMode(mode: langJson)},
            theme: dark ? atomOneDarkTheme : atomOneLightTheme,
          ),
        ),
        indicatorBuilder: (context, editing, chunk, notifier) => Row(
          children: [
            DefaultCodeLineNumber(
              controller: editing,
              notifier: notifier,
              minNumberCount: 2,
            ),
            DefaultCodeChunkIndicator(
              width: 18,
              controller: chunk,
              notifier: notifier,
            ),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {primaryShortcut(LogicalKeyboardKey.keyS): _save},
      child: AlertDialog(
        key: const Key('doc-editor-dialog'),
        title: Row(
          children: [
            Expanded(
              child: Text(_isEdit ? 'Edit document' : 'Insert document'),
            ),
            if (_isEdit)
              SegmentedButton<bool>(
                key: const Key('doc-editor-mode'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Edit')),
                  ButtonSegment(value: true, label: Text('Changes')),
                ],
                selected: {_showDiff},
                onSelectionChanged: (s) => setState(() => _showDiff = s.first),
              ),
          ],
        ),
        content: SizedBox(
          width: 720,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: body),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    err,
                    key: const Key('doc-editor-error'),
                    style: TextStyle(color: cs.error, fontSize: 12),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Canonical Extended JSON: numbers need a type, e.g. '
                    '{"\$numberInt": "5"}, {"\$numberLong": "5"}, '
                    '{"\$numberDouble": "5"}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('doc-editor-cancel'),
            onPressed: _saving ? null : Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('doc-editor-save'),
            onPressed: canSave ? _save : null,
            child: Text(_isEdit ? 'Save  ${primaryLabel}S' : 'Insert'),
          ),
        ],
      ),
    );
  }
}
