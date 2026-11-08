import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/application/completion_engine.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:queravue/features/completion/domain/snippets.dart';

import '../../support/fake_completion.dart';

CompletionItem item(
  String label, {
  int start = 0,
  int end = 0,
  CompletionKind kind = CompletionKind.table,
  String? insert,
  String key = '10100',
  String detail = '',
}) => CompletionItem(
  label: label,
  kind: kind,
  insertText: insert ?? label,
  replaceStart: start,
  replaceEnd: end,
  sortKey: '$key$label',
  detail: detail,
);

CompletionEngine engineWith(
  FakeCompletionRepository repo, {
  CompletionContext context = CompletionContext.sql,
  List<Snippet> snippets = const [],
}) => CompletionEngine(
  repositoryOf: () => repo,
  context: context,
  sessionId: () => 's1',
  snippetsOf: () => snippets,
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  const tables = ['orders', 'order_items', 'customers', 'invoices'];

  CompletionResult answerTables(CompletionRequest r) {
    final rel = r.cursorOffset;
    final start = rel - _prefixLength(r.text, rel);
    return CompletionResult(
      items: [for (final t in tables) item(t, start: start, end: rel)],
    );
  }

  test('an edit asks the core with the statement around the cursor', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    const doc = 'select 1; select * from ';
    engine.onEdit(doc, doc.length);
    await settle();
    final r = repo.requests.single;
    expect(r.text, ' select * from ');
    expect(r.cursorOffset, ' select * from '.length);
    expect(r.sessionId, 's1');
    expect(r.context, CompletionContext.sql);
    expect(r.maxItems, 1000);
  });

  test('typing extends the prefix and is answered from the cache', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    engine.onEdit('select * from ', 14);
    await settle();
    final o = engine.suggest('select * from o', 15)!;
    expect(o.entries.map((e) => e.label).take(2), ['order_items', 'orders']);
    expect(
      o.entries.map((e) => e.label),
      contains('customers'),
      reason: 'a substring still matches, below the prefix matches',
    );
    final s = engine.suggest('select * from ord', 17)!;
    expect(s.input, 'ord');
    expect(s.entries.map((e) => e.label), ['order_items', 'orders']);
    expect(repo.requests.length, 1, reason: 'suggest never asks the core');
  });

  test('word initials rank by the core rules', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    engine.onEdit('from ', 5);
    await settle();
    expect(engine.suggest('from oi', 7)!.entries.first.label, 'order_items');
  });

  test(
    'a shorter prefix, other text before it or another statement miss',
    () async {
      final repo = FakeCompletionRepository(answer: answerTables);
      final engine = engineWith(repo);
      engine.onEdit('select * from ord', 17);
      await settle();
      expect(engine.suggest('select * from ord', 17), isNotNull);
      expect(
        engine.suggest('select * from or', 16),
        isNull,
        reason: 'backspace',
      );
      expect(
        engine.suggest('select 1 from ord', 17),
        isNull,
        reason: 'text before changed',
      );
      expect(engine.suggest('select * from ord; select x', 27), isNull);
      expect(
        engine.suggest('select * from ord ', 18),
        isNull,
        reason: 'a space ends the word',
      );
    },
  );

  test('a new edit cancels the previous question', () async {
    final repo = FakeCompletionRepository(answer: answerTables)
      ..delay = const Duration(milliseconds: 20);
    final engine = engineWith(repo);
    engine.onEdit('from o', 6);
    engine.onEdit('from or', 7);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.requests.length, 2);
    expect(repo.cancelled, 1);
    expect(engine.suggest('from ord', 8), isNotNull);
  });

  test('an answer that arrives late for an older edit is dropped', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [item(r.text.trim(), start: 0, end: r.cursorOffset)],
      ),
    )..delay = const Duration(milliseconds: 5);
    final engine = engineWith(repo);
    engine.onEdit('ab', 2);
    engine.onEdit('abc', 3);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(
      engine.suggest('abcd', 4),
      isNull,
      reason: 'cache is for abc: label abc != prefix match abcd',
    );
  });

  test('onUpdated fires when a newer answer lands', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    var calls = 0;
    engine.onUpdated = () => calls++;
    engine.onEdit('from ', 5);
    await settle();
    expect(calls, 1);
  });

  test('identical edits do not ask again', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    engine.onEdit('from ', 5);
    engine.onEdit('from ', 5);
    await settle();
    expect(repo.requests.length, 1);
  });

  test('errors and a missing session give no suggestions', () async {
    final failing = FakeCompletionRepository(
      answer: (_) => const CompletionResult(error: 'boom'),
    );
    final engine = engineWith(failing);
    engine.onEdit('from ', 5);
    await settle();
    expect(engine.suggest('from o', 6), isNull);

    final repo = FakeCompletionRepository(answer: answerTables);
    final noSession = CompletionEngine(
      repositoryOf: () => repo,
      context: CompletionContext.sql,
      sessionId: () => null,
    );
    noSession.onEdit('from ', 5);
    await settle();
    expect(repo.requests, isEmpty);
  });

  test('an exact match of the typed word is not offered again', () async {
    final repo = FakeCompletionRepository(answer: answerTables);
    final engine = engineWith(repo);
    engine.onEdit('from orders', 11);
    await settle();
    expect(engine.suggest('from orders', 11)!.entries.map((e) => e.label), [
      'order_items',
    ]);
  });

  test('a swallowed closing quote is not inserted twice', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [
          item(
            'name',
            start: r.cursorOffset - 3,
            end: r.cursorOffset + 1,
            insert: '"name"',
            kind: CompletionKind.field,
          ),
        ],
      ),
    );
    final engine = engineWith(repo, context: CompletionContext.shell);
    const doc = 'find({ "na"})';
    engine.onEdit(doc, 10);
    await settle();
    final s = engine.suggest(doc, 10)!;
    expect(s.input, '"na');
    expect(s.entries.single.insertText, '"name');
  });

  test('snippets match a trigger prefix and sit above server items', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [
          item(
            'select',
            start: 0,
            end: r.cursorOffset,
            kind: CompletionKind.keyword,
          ),
        ],
      ),
    );
    final engine = engineWith(repo, snippets: builtInSnippets);
    engine.onEdit('s', 1);
    await settle();
    final s = engine.suggest('se', 2)!;
    expect(s.entries.first.kind, CompletionKind.snippet);
    expect(
      s.entries.map((e) => e.label),
      containsAll(['sel', 'selw', 'select']),
    );
    final sel = s.entries.firstWhere((e) => e.label == 'sel');
    expect(sel.insertText, 'SELECT \nFROM ');
    expect(sel.caret, 'SELECT '.length);
  });

  test('snippets are not offered after a dot or in other contexts', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [
          item('sel_col', start: r.cursorOffset - 2, end: r.cursorOffset),
        ],
      ),
    );
    final engine = engineWith(repo, snippets: builtInSnippets);
    engine.onEdit('t.se', 4);
    await settle();
    expect(
      engine.suggest('t.se', 4)!.entries.map((e) => e.kind),
      isNot(contains(CompletionKind.snippet)),
    );

    final shell = engineWith(
      repo,
      context: CompletionContext.shell,
      snippets: builtInSnippets,
    );
    shell.onEdit('se', 2);
    await settle();
    expect(
      shell.suggest('se', 2)?.entries.map((e) => e.label) ?? const <String>[],
      isNot(contains('sel')),
    );
  });

  test('the list is capped', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [
          for (var i = 0; i < 500; i++)
            item('t$i', start: 0, end: r.cursorOffset),
        ],
      ),
    );
    final engine = engineWith(repo);
    engine.onEdit('t', 1);
    await settle();
    expect(engine.suggest('t1', 2)!.entries.first.label, 't10');
    expect(engine.suggest('t', 1)!.entries.length, 200);
  });

  test('catalog state of the last answer is exposed', () async {
    final repo = FakeCompletionRepository(
      answer: (r) => CompletionResult(
        items: [item('a', start: 0, end: 0)],
        catalogState: CatalogState.warming,
      ),
    );
    final engine = engineWith(repo);
    engine.onEdit('', 0);
    await settle();
    expect(engine.catalogState, CatalogState.warming);
    expect(engine.suggest('', 0)!.catalogState, CatalogState.warming);
  });

  test('user snippets parse and bad entries are skipped', () {
    final list = parseUserSnippets(
      '[{"trigger":"ord","body":"SELECT * FROM orders WHERE \$0","description":"d","contexts":["sql"]},'
      '{"trigger":"","body":"x"},{"body":"y"},3,{"trigger":"m","body":"z","contexts":["mongo_query","shell"]}]',
    );
    expect(list.map((s) => s.trigger), ['ord', 'm']);
    expect(list.first.contexts, {CompletionContext.sql});
    expect(list.last.contexts, {
      CompletionContext.mongoQuery,
      CompletionContext.shell,
    });
    expect(parseUserSnippets('not json'), isEmpty);
    expect(parseUserSnippets('{"trigger":"a"}'), isEmpty);
  });

  test(
    'a snippet caret on a later line moves to the end of the first line',
    () {
      const s = Snippet(trigger: 't', body: 'ab\ncd\$0');
      expect(s.expand(), ('ab\ncd', 2));
    },
  );
}

int _prefixLength(String text, int at) {
  var i = at;
  while (i > 0 && RegExp(r'[A-Za-z0-9_$]').hasMatch(text[i - 1])) {
    i--;
  }
  return at - i;
}
