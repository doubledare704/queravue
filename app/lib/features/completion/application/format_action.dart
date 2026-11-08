import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/text_offsets.dart';
import '../data/completion_repository.dart';
import '../domain/completion_models.dart';
import '../domain/statement_window.dart';

/// Formats the selection, or the statement at the caret, in [controller].
/// Returns a message when nothing was changed because of a problem, null
/// otherwise (including when the text is already formatted).
Future<String?> formatEditorText({
  required CompletionRepository repository,
  required String sessionId,
  required CodeLineEditingController controller,
  FormatSqlOptions options = const FormatSqlOptions(),
}) async {
  final text = controller.text;
  final codeLines = controller.codeLines;
  final lines = [for (var i = 0; i < codeLines.length; i++) codeLines[i].text];
  final sel = controller.selection;
  final extent = offsetOfPosition(lines, sel.extentIndex, sel.extentOffset);
  var start = extent;
  var end = extent;
  if (sel.isCollapsed) {
    final w = sqlStatementWindow(text, extent);
    start = w.start;
    end = w.start + w.text.length;
  } else {
    final base = offsetOfPosition(lines, sel.baseIndex, sel.baseOffset);
    start = base < extent ? base : extent;
    end = base < extent ? extent : base;
  }
  while (start < end && text[start].trim().isEmpty) {
    start++;
  }
  while (end > start && text[end - 1].trim().isEmpty) {
    end--;
  }
  if (start >= end) return null;

  final original = text.substring(start, end);
  final result = await repository.formatSql(
    sessionId: sessionId,
    text: original,
    options: options,
  );
  if (controller.text != text) return 'The text changed while formatting.';
  final failure = result.error;
  if (failure != null) {
    final at = result.errorPosition;
    if (at != null) {
      final (line, col) = positionOfOffset(text, start + at);
      controller.selection = CodeLineSelection.collapsed(
        index: line,
        offset: col,
      );
    }
    return failure;
  }
  if (result.formattedText == original) return null;

  final (startLine, startCol) = positionOfOffset(text, start);
  final (endLine, endCol) = positionOfOffset(text, end);
  controller.selection = CodeLineSelection(
    baseIndex: startLine,
    baseOffset: startCol,
    extentIndex: endLine,
    extentOffset: endCol,
  );
  controller.replaceSelection(result.formattedText);
  return null;
}

/// Formats the active SQL tab of the selected connection (⌥⇧F).
Future<void> formatActiveTab(BuildContext context, WidgetRef ref) async {
  final connectionId = ref.read(selectedConnectionProvider);
  final tab = ref.read(editorTabsProvider).activeFor(connectionId);
  if (connectionId == null || tab == null || !tab.isQuery) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final session = ref.read(connectionSessionProvider(connectionId)).session;
  if (session == null || !session.capabilities.contains('format')) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Formatting is not available for this connection.'),
      ),
    );
    return;
  }
  final problem = await formatEditorText(
    repository: ref.read(completionRepositoryProvider),
    sessionId: session.id,
    controller: tab.controller,
  );
  if (problem != null) {
    messenger?.showSnackBar(SnackBar(content: Text(problem)));
  }
}
