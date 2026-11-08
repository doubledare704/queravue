import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/application/format_action.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:re_editor/re_editor.dart';

import '../../support/fake_completion.dart';

CodeLineEditingController editor(String text, {int line = 0, int col = 0}) {
  final c = CodeLineEditingController.fromText(text);
  c.selection = CodeLineSelection.collapsed(index: line, offset: col);
  addTearDown(c.dispose);
  return c;
}

FakeCompletionRepository upper() =>
    FakeCompletionRepository()
      ..formatter = (text) =>
          FormatSqlResult(formattedText: text.toUpperCase());

void main() {
  test(
    'the statement at the caret is replaced, the rest is untouched',
    () async {
      final repo = upper();
      final c = editor(
        'select 1;\nselect  a from t;\nselect 3',
        line: 1,
        col: 4,
      );
      final problem = await formatEditorText(
        repository: repo,
        sessionId: 's',
        controller: c,
      );
      expect(problem, isNull);
      expect(repo.formatted, ['select  a from t']);
      expect(c.text, 'select 1;\nSELECT  A FROM T;\nselect 3');
    },
  );

  test('a selection is formatted instead of the statement', () async {
    final repo = upper();
    final c = editor('select a, b from t');
    c.selection = const CodeLineSelection(
      baseIndex: 0,
      baseOffset: 7,
      extentIndex: 0,
      extentOffset: 11,
    );
    await formatEditorText(repository: repo, sessionId: 's', controller: c);
    expect(repo.formatted, ['a, b']);
    expect(c.text, 'select A, B from t');
  });

  test(
    'a multi-line result replaces the statement and keeps the rest',
    () async {
      final repo = FakeCompletionRepository()
        ..formatter = (_) =>
            const FormatSqlResult(formattedText: 'SELECT a\nFROM t');
      final c = editor('select a from t;\nselect 2');
      await formatEditorText(repository: repo, sessionId: 's', controller: c);
      expect(c.text, 'SELECT a\nFROM t;\nselect 2');
    },
  );

  test('already formatted text is left alone', () async {
    final repo = FakeCompletionRepository();
    final c = editor('SELECT 1');
    expect(
      await formatEditorText(repository: repo, sessionId: 's', controller: c),
      isNull,
    );
    expect(c.text, 'SELECT 1');
  });

  test('an error is returned and the caret goes to its position', () async {
    final repo = FakeCompletionRepository()
      ..formatter = (_) =>
          const FormatSqlResult(error: 'unterminated string', errorPosition: 7);
    final c = editor("select 'abc");
    final problem = await formatEditorText(
      repository: repo,
      sessionId: 's',
      controller: c,
    );
    expect(problem, 'unterminated string');
    expect(c.text, "select 'abc");
    expect(c.selection.extentOffset, 7);
  });

  test('an empty editor or blank statement does nothing', () async {
    final repo = upper();
    expect(
      await formatEditorText(
        repository: repo,
        sessionId: 's',
        controller: editor(''),
      ),
      isNull,
    );
    expect(
      await formatEditorText(
        repository: repo,
        sessionId: 's',
        controller: editor('  \n '),
      ),
      isNull,
    );
    expect(repo.formatted, isEmpty);
  });

  test('text edited while the core formats is not overwritten', () async {
    final repo = upper();
    final c = editor('select a');
    final pending = formatEditorText(
      repository: repo,
      sessionId: 's',
      controller: c,
    );
    c.text = 'select b';
    expect(await pending, 'The text changed while formatting.');
    expect(c.text, 'select b');
  });
}
