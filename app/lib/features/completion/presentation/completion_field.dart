import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../application/completion_engine.dart';
import '../application/user_snippets.dart';
import '../data/completion_repository.dart';
import '../domain/completion_models.dart';
import '../domain/snippets.dart';
import 'completion_popup.dart';

/// Completion for a single-line [TextField] (the Mongo query bar). The popup
/// opens under the field; ↑ ↓ choose, Enter or Tab accept, Esc closes.
class CompletionField extends ConsumerStatefulWidget {
  const CompletionField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sessionId,
    required this.database,
    required this.collection,
    required this.child,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function() sessionId;
  final String database;
  final String collection;
  final Widget child;

  @override
  ConsumerState<CompletionField> createState() => _CompletionFieldState();
}

class _CompletionFieldState extends ConsumerState<CompletionField> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final CompletionEngine _engine;
  ValueNotifier<CodeAutocompleteEditingValue>? _value;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _engine = CompletionEngine(
      repositoryOf: () => ref.read(completionRepositoryProvider),
      context: CompletionContext.mongoQuery,
      sessionId: widget.sessionId,
      database: () => widget.database,
      collection: () => widget.collection,
      snippetsOf: () => [
        ...builtInSnippets,
        ...ref.read(userSnippetsProvider).value ?? const <Snippet>[],
      ],
    )..onUpdated = _refresh;
    widget.controller.addListener(_onChange);
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    widget.focusNode.removeListener(_onFocus);
    _engine.dispose();
    _value?.dispose();
    super.dispose();
  }

  int? get _cursor {
    final sel = widget.controller.selection;
    return sel.isValid && sel.isCollapsed ? sel.baseOffset : null;
  }

  void _onFocus() {
    if (!widget.focusNode.hasFocus) _hide();
  }

  void _onChange() {
    final cursor = _cursor;
    if (cursor == null) return _hide();
    final text = widget.controller.text;
    _engine.onEdit(text, cursor);
    final edited = text != _lastText;
    _lastText = text;
    if (!edited) return _hide();
    _show(text, cursor);
  }

  void _refresh() {
    final cursor = _cursor;
    if (!mounted || cursor == null || !_portal.isShowing) return;
    _show(widget.controller.text, cursor);
  }

  void _show(String text, int cursor) {
    if (!widget.focusNode.hasFocus) return;
    final s = _engine.suggest(text, cursor);
    if (s == null) return _hide();
    final next = editingValueOf(s);
    final value = _value;
    if (value == null) {
      _value = ValueNotifier(next);
    } else {
      value.value = next;
    }
    if (!_portal.isShowing) _portal.show();
  }

  void _hide() {
    if (_portal.isShowing) _portal.hide();
  }

  void _accept(CodeAutocompleteResult result) {
    final cursor = _cursor;
    if (cursor == null) return;
    final text = widget.controller.text;
    final start = cursor - result.input.length;
    if (start < 0) return;
    final next = text.replaceRange(start, cursor, result.word);
    _lastText = next;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: cursor + result.selection.baseOffset,
      ),
    );
    _hide();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final value = _value;
    if (!_portal.isShowing || value == null || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final v = value.value;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final n = v.prompts.length;
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      value.value = v.copyWith(index: (v.index + step + n) % n);
      return KeyEventResult.handled;
    }
    final plain =
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isControlPressed;
    if (plain &&
        (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab)) {
      _accept(v.autocomplete);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 2),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: CompletionList(
              notifier: _value!,
              onSelected: _accept,
              catalogState: () => _engine.catalogState,
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Focus(
          onKeyEvent: _onKey,
          skipTraversal: true,
          canRequestFocus: false,
          child: widget.child,
        ),
      ),
    );
  }
}
