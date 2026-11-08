import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../application/completion_engine.dart';
import '../domain/completion_models.dart';

/// A prompt backed by a [Suggestion]. The editor inserts [Suggestion.insertText]
/// in place of the typed prefix.
class SuggestionPrompt extends CodePrompt {
  SuggestionPrompt(this.suggestion) : super(word: suggestion.label);

  final Suggestion suggestion;

  @override
  CodeAutocompleteResult get autocomplete => CodeAutocompleteResult(
    input: '',
    word: suggestion.insertText,
    selection: TextSelection.collapsed(offset: suggestion.caret),
  );

  @override
  bool match(String input) => true;
}

CodeAutocompleteEditingValue editingValueOf(Suggestions s) =>
    CodeAutocompleteEditingValue(
      input: s.input,
      prompts: [for (final e in s.entries) SuggestionPrompt(e)],
      index: 0,
    );

const _rowHeight = 24.0;
const _visibleRows = 8;
const popupWidth = 400.0;

IconData iconOf(CompletionKind kind) => switch (kind) {
  CompletionKind.table => Icons.table_chart_outlined,
  CompletionKind.view => Icons.visibility_outlined,
  CompletionKind.column || CompletionKind.field => Icons.view_column_outlined,
  CompletionKind.schema || CompletionKind.database => Icons.folder_outlined,
  CompletionKind.alias => Icons.label_outline,
  CompletionKind.collection => Icons.dataset_outlined,
  CompletionKind.function || CompletionKind.method => Icons.functions,
  CompletionKind.operator => Icons.percent,
  CompletionKind.snippet => Icons.bolt_outlined,
  _ => Icons.text_fields,
};

/// The completion list. It resizes with its content, shows [engineState] as a
/// hint while the catalog loads, and keeps the selected row in view.
class CompletionList extends StatefulWidget {
  const CompletionList({
    super.key,
    required this.notifier,
    required this.onSelected,
    required this.catalogState,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;
  final CatalogState Function() catalogState;

  @override
  State<CompletionList> createState() => _CompletionListState();
}

class _CompletionListState extends State<CompletionList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_keepSelectedVisible);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_keepSelectedVisible);
    _scroll.dispose();
    super.dispose();
  }

  void _keepSelectedVisible() {
    if (!_scroll.hasClients) return;
    final top = widget.notifier.value.index * _rowHeight;
    final bottom = top + _rowHeight;
    final view = _scroll.position;
    if (top < view.pixels) {
      _scroll.jumpTo(top);
    } else if (bottom > view.pixels + view.viewportDimension) {
      _scroll.jumpTo(bottom - view.viewportDimension);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, value, _) {
        final rows = value.prompts.length;
        final warming =
            widget.catalogState() == CatalogState.warming ||
            widget.catalogState() == CatalogState.cold;
        return Container(
          key: const Key('completion-popup'),
          width: popupWidth,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(blurRadius: 8, color: Color(0x33000000)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _rowHeight * _visibleRows,
                ),
                child: SizedBox(
                  height:
                      _rowHeight * (rows < _visibleRows ? rows : _visibleRows),
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: _rowHeight,
                    itemCount: rows,
                    itemBuilder: (context, i) =>
                        _row(context, value, i, scheme),
                  ),
                ),
              ),
              if (warming)
                Container(
                  key: const Key('completion-loading'),
                  height: 20,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'loading columns…',
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    CodeAutocompleteEditingValue value,
    int i,
    ColorScheme scheme,
  ) {
    final prompt = value.prompts[i] as SuggestionPrompt;
    final s = prompt.suggestion;
    final selected = i == value.index;
    return InkWell(
      key: Key('completion-item-$i'),
      onTap: () => widget.onSelected(value.copyWith(index: i).autocomplete),
      child: Container(
        color: selected ? scheme.primaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(iconOf(s.kind), size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
              ),
            ),
            if (s.detail.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  s.detail,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
