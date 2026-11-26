import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../completion/application/completion_engine.dart';
import '../../completion/domain/completion_models.dart';
import '../../completion/presentation/completion_scope.dart';
import '../../connections/application/connection_session.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/text_offsets.dart';
import '../../editor/presentation/sql_editor.dart';
import '../application/mongo_sql_controller.dart';
import '../data/mongo_sql_completion_repository.dart';

final _completionEngineProvider = Provider.autoDispose
    .family<CompletionEngine, EditorTab>((ref, tab) {
      final repository = ref.watch(
        mongoSqlCompletionRepositoryProvider(tab.id),
      );
      final engine = CompletionEngine(
        repositoryOf: () => repository,
        context: CompletionContext.sql,
        sessionId: () {
          final session = ref
              .read(connectionSessionProvider(tab.connectionId))
              .session;
          return supportsMongoSql(session?.capabilities) ? session?.id : null;
        },
        database: () => tab.shellDatabase,
      );
      ref.onDispose(engine.dispose);
      return engine;
    });

class MongoSqlEditor extends ConsumerStatefulWidget {
  const MongoSqlEditor({
    super.key,
    required this.tab,
    required this.errorOffset,
    required this.focusNode,
  });

  final EditorTab tab;
  final int? errorOffset;
  final FocusNode focusNode;

  @override
  ConsumerState<MongoSqlEditor> createState() => _MongoSqlEditorState();
}

class _MongoSqlEditorState extends ConsumerState<MongoSqlEditor> {
  late final _DiagnosticEditingController _editor;

  @override
  void initState() {
    super.initState();
    _editor = _DiagnosticEditingController(widget.tab.controller)
      ..errorOffset = widget.errorOffset;
  }

  @override
  void didUpdateWidget(MongoSqlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorOffset != widget.errorOffset) {
      _editor.errorOffset = widget.errorOffset;
      _editor.forceRepaint();
    }
  }

  @override
  Widget build(BuildContext context) => CompletionScope(
    controller: _editor,
    engine: ref.watch(_completionEngineProvider(widget.tab)),
    child: SqlCodeEditor(
      editorKey: Key('mongo-sql-editor-${widget.tab.id}'),
      controller: _editor,
      focusNode: widget.focusNode,
    ),
  );
}

class _DiagnosticEditingController extends CodeLineEditingControllerDelegate {
  _DiagnosticEditingController(CodeLineEditingController controller)
    : super(delegate: controller);

  set errorOffset(int? offset) {
    if (offset == null) {
      _line = null;
      return;
    }
    final sql = text;
    if (offset >= sql.length || sql[offset] == '\n') {
      final before = sql.substring(0, offset.clamp(0, sql.length)).trimRight();
      if (before.isEmpty) {
        _line = null;
        return;
      }
      offset = before.length - 1;
      if (before.codeUnitAt(offset) & 0xFC00 == 0xDC00) offset--;
    }
    final (line, column) = positionOfOffset(sql, offset);
    _line = line;
    _column = column;
    _end = _column + (sql.codeUnitAt(offset) & 0xFC00 == 0xD800 ? 2 : 1);
  }

  int? _line;
  int _column = 0;
  int _end = 0;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required int index,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    if (index != _line) return textSpan;
    final underline = TextStyle(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: Theme.of(context).colorScheme.error,
    );
    var offset = 0;
    TextSpan decorate(TextSpan span) {
      final value = span.text ?? '';
      final start = (_column - offset).clamp(0, value.length);
      final end = (_end - offset).clamp(0, value.length);
      offset += value.length;
      return TextSpan(
        style: span.style,
        text: start == end ? span.text : null,
        children: [
          if (start < end) ...[
            if (start > 0) TextSpan(text: value.substring(0, start)),
            TextSpan(text: value.substring(start, end), style: underline),
            if (end < value.length) TextSpan(text: value.substring(end)),
          ],
          for (final child in span.children ?? const <InlineSpan>[])
            child is TextSpan ? decorate(child) : child,
        ],
      );
    }

    return decorate(textSpan);
  }
}
