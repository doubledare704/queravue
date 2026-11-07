import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

/// JavaScript editor of a shell tab. [errorLine] (0-based) is marked in the
/// gutter with ✕.
class JsEditor extends StatelessWidget {
  const JsEditor({
    super.key,
    required this.controller,
    this.errorLine,
    this.autofocus = true,
  });

  final CodeLineEditingController controller;
  final int? errorLine;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return CodeEditor(
      controller: controller,
      autofocus: autofocus,
      wordWrap: false,
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: 'Menlo',
        backgroundColor: scheme.surface,
        codeTheme: CodeHighlightTheme(
          languages: {
            'javascript': CodeHighlightThemeMode(mode: langJavascript),
          },
          theme: dark ? atomOneDarkTheme : atomOneLightTheme,
        ),
      ),
      indicatorBuilder: (context, editing, chunk, notifier) => Row(
        children: [
          DefaultCodeLineNumber(
            controller: editing,
            notifier: notifier,
            minNumberCount: 3,
            customLineIndex2Text: (i) =>
                '${i == errorLine ? '✕' : ' '}${i + 1}',
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
}
