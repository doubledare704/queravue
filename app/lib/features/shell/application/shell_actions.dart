import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../editor/application/editor_tabs.dart';
import 'shell_tab_controller.dart';

/// Runs the selection of a shell tab, or its whole buffer when nothing is
/// selected (⌘↵).
Future<void> runShellTab(WidgetRef ref, EditorTab tab) {
  final c = tab.controller;
  final selected = c.selectedText;
  if (selected.trim().isNotEmpty) {
    final sel = c.selection;
    final firstLine = sel.startIndex < sel.endIndex
        ? sel.startIndex
        : sel.endIndex;
    return ref
        .read(shellTabProvider(tab.id).notifier)
        .run(selected, lineOffset: firstLine);
  }
  return ref.read(shellTabProvider(tab.id).notifier).run(c.text);
}

/// Moves the caret of [tab] to the 0-based [line] and [column] (1-based, 0 if
/// unknown).
void jumpToLine(EditorTab tab, int line, int column) {
  final c = tab.controller;
  if (line < 0 || line >= c.codeLines.length) return;
  final offset = column > 0
      ? (column - 1).clamp(0, c.codeLines[line].length)
      : 0;
  c.selection = CodeLineSelection.collapsed(index: line, offset: offset);
  c.makeCursorCenterIfInvisible();
}
