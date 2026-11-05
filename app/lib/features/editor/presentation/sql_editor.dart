import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../application/editor_tabs.dart';
import '../application/query_run.dart';
import '../domain/text_offsets.dart';

/// The SQL editor of one tab: re_editor with SQL highlighting, run and
/// cancel shortcuts, and gutter marks for the statement that ran or failed.
///
/// re_editor has no range decorations, so the statement is marked in the
/// gutter (▸ ran, ✕ failed) and a failure moves the caret to the position
/// the server reported.
class SqlEditor extends ConsumerStatefulWidget {
  const SqlEditor({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<SqlEditor> createState() => _SqlEditorState();
}

class _SqlEditorState extends ConsumerState<SqlEditor> {
  CodeLines? _lastLines;

  CodeLineEditingController get _c => widget.tab.controller;

  @override
  void initState() {
    super.initState();
    _lastLines = _c.codeLines;
    _c.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(SqlEditor old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      old.tab.controller.removeListener(_onEdit);
      _lastLines = _c.codeLines;
      _c.addListener(_onEdit);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onEdit);
    super.dispose();
  }

  /// The marked statement no longer matches the text once it is edited.
  void _onEdit() {
    final lines = _c.codeLines;
    if (identical(lines, _lastLines)) return;
    _lastLines = lines;
    final run = ref.read(queryRunProvider(widget.tab.id));
    if (run.plan.isNotEmpty || run.failedStatement != null) {
      // Not while the run is in flight: its events still refer to this text.
      if (!run.busy) {
        ref.read(queryRunProvider(widget.tab.id).notifier).clearHighlight();
      }
    }
  }

  void _showError(QueryRunState run) {
    final off = run.errorOffset;
    if (off == null || run.failedStatement == null) return;
    final (line, col) = positionOfOffset(_c.text, off);
    _c.selection = CodeLineSelection.collapsed(index: line, offset: col);
    _c.makeCursorCenterIfInvisible();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(queryRunProvider(widget.tab.id), (prev, next) {
      if (prev?.phase != RunPhase.failed && next.phase == RunPhase.failed) {
        _showError(next);
      }
    });
    final run = ref.watch(queryRunProvider(widget.tab.id));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // Lines of the statement that ran or failed.
    var markFirst = -1, markLast = -2;
    final range = run.highlight;
    if (range != null) {
      (markFirst, markLast) = linesOfRange(_c.text, range.start, range.end);
    }
    final failed = run.failedStatement != null && run.phase == RunPhase.failed;

    return CodeEditor(
      key: Key('sql-editor-${widget.tab.id}'),
      controller: _c,
      autofocus: true,
      wordWrap: false,
      style: CodeEditorStyle(
        fontSize: 13,
        fontFamily: 'Menlo',
        backgroundColor: scheme.surface,
        codeTheme: CodeHighlightTheme(
          languages: {'sql': CodeHighlightThemeMode(mode: langSql)},
          theme: dark ? atomOneDarkTheme : atomOneLightTheme,
        ),
      ),
      indicatorBuilder: (context, editing, chunk, notifier) => Row(
        children: [
          DefaultCodeLineNumber(
            controller: editing,
            notifier: notifier,
            minNumberCount: 3,
            customLineIndex2Text: (i) {
              final mark = i >= markFirst && i <= markLast
                  ? (failed ? '✕' : '▸')
                  : ' ';
              return '$mark${i + 1}';
            },
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
