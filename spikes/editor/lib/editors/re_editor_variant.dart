import 'dart:async';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import 'editor_handle.dart';

/// Identifiers a core-backed schema cache would provide; prompts are computed
/// synchronously from this cache (re_editor's prompt builder is sync).
const _schemaWords = [
  'customers', 'customer_id', 'created_at', 'crm', 'sales', 'orders_1',
  'status', 'amount', 'region', 'revenue', 'buyers', 'month',
];
const _keywords = [
  'SELECT', 'FROM', 'WHERE', 'JOIN', 'GROUP', 'ORDER', 'LIMIT', 'INSERT',
  'UPDATE', 'DELETE', 'RETURNING', 'PARTITION', 'OVER', 'DISTINCT',
];

class ReEditorVariant extends StatefulWidget {
  const ReEditorVariant({super.key, required this.args});
  final EditorArgs args;
  @override
  State<ReEditorVariant> createState() => _ReEditorVariantState();
}

class _ReEditorVariantState extends State<ReEditorVariant> implements EditorHandle {
  late final CodeLineEditingController _c = CodeLineEditingController.fromText(widget.args.text);
  late final CodeFindController _find = CodeFindController(_c);
  bool _popup = false;

  @override
  void initState() {
    super.initState();
    widget.args.onHandle(this);
  }

  @override
  void dispose() {
    _find.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  int get lineCount => _c.lineCount;

  @override
  void moveCursorTo(int line, int column) {
    _c.selection = CodeLineSelection.collapsed(index: line, offset: column);
    _c.makeCursorCenterIfInvisible();
  }

  @override
  void insert(String text) => _c.replaceSelection(text);

  Future<int> _waitForResult() async {
    for (var i = 0; i < 500; i++) {
      final v = _find.value;
      if (v != null && !v.searching && v.result != null) return v.result!.matches.length;
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    return -1;
  }

  @override
  Future<int> find(String pattern) async {
    _find.findMode();
    _find.findInputController.text = pattern;
    return _waitForResult();
  }

  @override
  Future<int?> replaceAll(String pattern, String replacement) async {
    _find.replaceMode();
    _find.findInputController.text = pattern;
    final n = await _waitForResult();
    _find.replaceInputController.text = replacement;
    _find.replaceAllMatches();
    _find.close();
    return n;
  }

  @override
  bool get supportsMultiCursor => false; // single CodeLineSelection only

  @override
  bool get customPopupVisible => _popup;

  @override
  Widget build(BuildContext context) {
    final dark = widget.args.dark;
    return CodeAutocomplete(
      viewBuilder: (context, notifier, onSelected) {
        scheduleMicrotask(() => _popup = true);
        return _CompletionPopup(notifier: notifier, onSelected: onSelected);
      },
      promptsBuilder: DefaultCodeAutocompletePromptsBuilder(
        language: langSql,
        keywordPrompts: [for (final k in _keywords) CodeKeywordPrompt(word: k)],
        directPrompts: [for (final w in _schemaWords) CodeFieldPrompt(word: w, type: 'column')],
      ),
      child: CodeEditor(
        controller: _c,
        findController: _find,
        autofocus: true,
        wordWrap: false,
        style: CodeEditorStyle(
          fontSize: 13,
          fontFamily: 'Menlo',
          codeTheme: CodeHighlightTheme(
            languages: {'sql': CodeHighlightThemeMode(mode: langSql)},
            theme: dark ? atomOneDarkTheme : atomOneLightTheme,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        indicatorBuilder: (context, editing, chunk, notifier) => Row(children: [
          DefaultCodeLineNumber(controller: editing, notifier: notifier),
          DefaultCodeChunkIndicator(width: 18, controller: chunk, notifier: notifier),
        ]),
        findBuilder: (context, controller, readOnly) => _FindPanel(controller: controller),
      ),
    );
  }
}

class _CompletionPopup extends StatelessWidget implements PreferredSizeWidget {
  const _CompletionPopup({required this.notifier, required this.onSelected});
  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  @override
  Size get preferredSize => Size(260, (notifier.value.prompts.length * 24.0).clamp(24, 192) + 2);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      key: kCustomPopupKey,
      elevation: 6,
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(6),
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, v, _) => ListView.builder(
          padding: EdgeInsets.zero,
          itemExtent: 24,
          itemCount: v.prompts.length,
          itemBuilder: (context, i) {
            final p = v.prompts[i];
            return InkWell(
              onTap: () => onSelected(v.copyWith(index: i).autocomplete),
              child: Container(
                color: i == v.index ? cs.primaryContainer : null,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Row(children: [
                  Icon(p is CodeFieldPrompt ? Icons.view_column : Icons.key, size: 14),
                  const SizedBox(width: 6),
                  Text(p.word, style: const TextStyle(fontFamily: 'Menlo', fontSize: 12)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FindPanel extends StatelessWidget implements PreferredSizeWidget {
  const _FindPanel({required this.controller});
  final CodeFindController controller;

  @override
  Size get preferredSize => Size.fromHeight(
      controller.value == null ? 0 : (controller.value!.replaceMode ? 72 : 36));

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    if (v == null) return const SizedBox.shrink();
    final n = v.result?.matches.length ?? 0;
    return Material(
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller: controller.findInputController, focusNode: controller.findInputFocusNode)),
          Text(' $n matches '),
          IconButton(onPressed: controller.previousMatch, icon: const Icon(Icons.arrow_upward, size: 16)),
          IconButton(onPressed: controller.nextMatch, icon: const Icon(Icons.arrow_downward, size: 16)),
        ]),
        if (v.replaceMode)
          Row(children: [
            Expanded(child: TextField(controller: controller.replaceInputController, focusNode: controller.replaceInputFocusNode)),
            TextButton(onPressed: controller.replaceAllMatches, child: const Text('Replace all')),
          ]),
      ]),
    );
  }
}
