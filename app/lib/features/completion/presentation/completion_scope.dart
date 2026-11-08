import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import '../application/completion_engine.dart';
import 'completion_popup.dart';

/// Wraps a [CodeEditor] with the completion popup driven by [engine].
class CompletionScope extends StatefulWidget {
  const CompletionScope({
    super.key,
    required this.controller,
    required this.engine,
    required this.child,
  });

  final CodeLineEditingController controller;
  final CompletionEngine engine;
  final Widget child;

  @override
  State<CompletionScope> createState() => _CompletionScopeState();
}

class _CompletionScopeState extends State<CompletionScope> {
  ValueNotifier<CodeAutocompleteEditingValue>? _open;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    widget.engine.onUpdated = _refresh;
  }

  @override
  void didUpdateWidget(CompletionScope old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
    if (old.engine != widget.engine) {
      old.engine.onUpdated = null;
      widget.engine.onUpdated = _refresh;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    widget.engine.onUpdated = null;
    super.dispose();
  }

  (String, int) _snapshot() {
    final c = widget.controller;
    final lines = c.codeLines;
    final sel = c.selection;
    var offset = 0;
    for (var i = 0; i < sel.extentIndex && i < lines.length; i++) {
      offset += lines[i].text.length + 1;
    }
    return (c.text, offset + sel.extentOffset);
  }

  void _onChange() {
    final c = widget.controller;
    if (c.isComposing || !c.selection.isCollapsed) return;
    final (text, cursor) = _snapshot();
    widget.engine.onEdit(text, cursor);
  }

  void _refresh() {
    final open = _open;
    if (open == null || !mounted) return;
    final (text, cursor) = _snapshot();
    final s = widget.engine.suggest(text, cursor);
    if (s != null) open.value = editingValueOf(s);
  }

  @override
  Widget build(BuildContext context) {
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        _open = notifier;
        return PreferredSize(
          preferredSize: const Size(popupWidth, 200),
          child: CompletionList(
            notifier: notifier,
            onSelected: onSelected,
            catalogState: () => widget.engine.catalogState,
          ),
        );
      },
      promptsBuilder: _Prompts(this),
      child: widget.child,
    );
  }
}

class _Prompts implements CodeAutocompletePromptsBuilder {
  _Prompts(this._state);

  final _CompletionScopeState _state;

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    final (text, cursor) = _state._snapshot();
    final s = _state.widget.engine.suggest(text, cursor);
    return s == null ? null : editingValueOf(s);
  }
}
