// ignore_for_file: invalid_use_of_internal_member
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:highlight/languages/sql.dart';

import 'editor_handle.dart';

class FceVariant extends StatefulWidget {
  const FceVariant({super.key, required this.args});
  final EditorArgs args;
  @override
  State<FceVariant> createState() => _FceVariantState();
}

class _FceVariantState extends State<FceVariant> implements EditorHandle {
  late final CodeController _c = CodeController(text: widget.args.text, language: sql);

  @override
  void initState() {
    super.initState();
    _c.autocompleter.setCustomWords(const ['customers', 'customer_id', 'created_at', 'revenue']);
    widget.args.onHandle(this);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  int get lineCount => '\n'.allMatches(_c.fullText).length + 1;

  @override
  void moveCursorTo(int line, int column) {
    final t = _c.text;
    var off = 0;
    for (var l = 0; l < line; l++) {
      off = t.indexOf('\n', off) + 1;
    }
    _c.selection = TextSelection.collapsed(offset: off + column);
  }

  /// Goes through the controller's value setter, the same path IME input uses.
  @override
  void insert(String text) {
    final v = _c.value;
    final s = v.selection;
    _c.value = TextEditingValue(
      text: v.text.replaceRange(s.start, s.end, text),
      selection: TextSelection.collapsed(offset: s.start + text.length),
    );
  }

  @override
  Future<int> find(String pattern) async {
    _c.showSearch();
    _c.searchController.settingsController.patternController.text = pattern;
    await Future<void>.delayed(Duration.zero);
    return _c.fullSearchResult.matches.length;
  }

  @override
  Future<int?> replaceAll(String pattern, String replacement) async => null; // no replace

  @override
  bool get supportsMultiCursor => false; // single TextSelection (TextField)

  @override
  bool get customPopupVisible => false; // popup is a private built-in widget

  @override
  Widget build(BuildContext context) {
    final dark = widget.args.dark;
    return CodeTheme(
      data: CodeThemeData(styles: dark ? atomOneDarkTheme : atomOneLightTheme),
      child: CodeField(
        controller: _c,
        expands: true,
        wrap: false,
        textStyle: const TextStyle(fontFamily: 'Menlo', fontSize: 13),
      ),
    );
  }
}
