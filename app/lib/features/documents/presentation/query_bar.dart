import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shortcuts.dart';
import '../../completion/presentation/completion_field.dart';
import '../application/document_tab_controller.dart';
import '../domain/models.dart';

/// Filter, sort, projection, skip and limit inputs of a collection tab, with
/// the parse errors reported by the core shown under the offending field.
class DocumentQueryBar extends ConsumerStatefulWidget {
  const DocumentQueryBar({super.key, required this.tabId});

  final String tabId;

  @override
  ConsumerState<DocumentQueryBar> createState() => _DocumentQueryBarState();
}

class _DocumentQueryBarState extends ConsumerState<DocumentQueryBar> {
  final _filter = TextEditingController();
  final _sort = TextEditingController();
  final _projection = TextEditingController();
  final _skip = TextEditingController();
  final _limit = TextEditingController();
  final _filterFocus = FocusNode();
  final _sortFocus = FocusNode();
  final _projectionFocus = FocusNode();

  DocumentTabController get _c =>
      ref.read(documentTabProvider(widget.tabId).notifier);

  @override
  void dispose() {
    for (final c in [_filter, _sort, _projection, _skip, _limit]) {
      c.dispose();
    }
    _filterFocus.dispose();
    _sortFocus.dispose();
    _projectionFocus.dispose();
    super.dispose();
  }

  void _changed() => _c.setDraft(
    FindQuery(
      filter: _filter.text,
      sort: _sort.text,
      projection: _projection.text,
      skip: int.tryParse(_skip.text.trim()) ?? 0,
      limit: int.tryParse(_limit.text.trim()) ?? 0,
    ),
  );

  void _run() {
    _changed();
    _c.runDraft();
  }

  /// Puts the caret at the position of a parse error in its field.
  void _showError(DocumentError e) {
    final field = switch (e.input) {
      DocInput.filter => _filter,
      DocInput.sort => _sort,
      DocInput.projection => _projection,
      _ => null,
    };
    if (field == null) return;
    final pos = (e.position ?? 0).clamp(0, field.text.length);
    field.selection = TextSelection.collapsed(offset: pos);
    if (e.input == DocInput.filter) _filterFocus.requestFocus();
  }

  String? _errorFor(DocumentError? e, DocInput input) {
    if (e == null || e.input != input) return null;
    final at = e.position == null ? '' : ' (at character ${e.position! + 1})';
    return '${e.message}$at';
  }

  Widget _completing(
    TextEditingController controller,
    FocusNode focus,
    DocumentTabState state,
    Widget field,
  ) => CompletionField(
    controller: controller,
    focusNode: focus,
    sessionId: () => ref.read(documentTabProvider(widget.tabId)).sessionId,
    database: state.database,
    collection: state.collection,
    child: field,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(documentTabProvider(widget.tabId).select((s) => s.queryError), (
      prev,
      next,
    ) {
      if (next != null && next != prev) _showError(next);
    });
    final state = ref.watch(documentTabProvider(widget.tabId));
    final err = state.queryError;

    InputDecoration deco(String label, String hint, DocInput input) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          errorText: _errorFor(err, input),
          errorMaxLines: 2,
        );

    return CallbackShortcuts(
      bindings: {
        primaryShortcut(LogicalKeyboardKey.enter): _run,
        const SingleActivator(LogicalKeyboardKey.escape): () => _c.cancel(),
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _completing(
                _filter,
                _filterFocus,
                state,
                TextField(
                  key: const Key('doc-filter'),
                  controller: _filter,
                  focusNode: _filterFocus,
                  onChanged: (_) => _changed(),
                  decoration: deco(
                    'Filter',
                    '{ "status": "paid" }',
                    DocInput.filter,
                  ),
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _completing(
                _sort,
                _sortFocus,
                state,
                TextField(
                  key: const Key('doc-sort'),
                  controller: _sort,
                  focusNode: _sortFocus,
                  onChanged: (_) => _changed(),
                  decoration: deco('Sort', '{ "_id": -1 }', DocInput.sort),
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _completing(
                _projection,
                _projectionFocus,
                state,
                TextField(
                  key: const Key('doc-projection'),
                  controller: _projection,
                  focusNode: _projectionFocus,
                  onChanged: (_) => _changed(),
                  decoration: deco(
                    'Projection',
                    '{ "name": 1 }',
                    DocInput.projection,
                  ),
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: TextField(
                key: const Key('doc-skip'),
                controller: _skip,
                onChanged: (_) => _changed(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: deco('Skip', '0', DocInput.none),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: TextField(
                key: const Key('doc-limit'),
                controller: _limit,
                onChanged: (_) => _changed(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: deco('Limit', 'all', DocInput.none),
              ),
            ),
            const SizedBox(width: 8),
            if (state.isLoading && state.showCancel)
              OutlinedButton.icon(
                key: const Key('doc-cancel'),
                onPressed: () => _c.cancel(),
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Cancel'),
              )
            else
              FilledButton.icon(
                key: const Key('doc-run'),
                onPressed: _run,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text('Run  $primaryLabel↵'),
              ),
          ],
        ),
      ),
    );
  }
}
