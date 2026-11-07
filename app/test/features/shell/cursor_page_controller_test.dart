import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:queravue/features/documents/application/document_tab_controller.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/shell/application/cursor_page_controller.dart';

import '../../support/fake_document_repository.dart';
import '../../support/shell_workspace_fakes.dart';

const _key = CursorKey('shell-1', 'cursor1');

Future<ShellEnv> env({int docs = 120}) async {
  final e = await makeShellEnv();
  e.shell.cursorDocs = [for (var i = 0; i < docs; i++) fakeDoc(i)];
  return e;
}

Future<void> loaded(ShellEnv e) => settle(() {
  final s = e.container.read(cursorPageProvider(_key));
  return !s.isLoading;
});

void main() {
  test('loads a page and knows there is another', () async {
    final e = await env();
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    final s = e.container.read(cursorPageProvider(_key));
    expect(s.docs.length, 20);
    expect(s.hasNext, isTrue);
    expect(s.firstIndex, 0);
    expect(
      e.shell.fetches.single.limit,
      21,
      reason: 'one extra to learn hasNext',
    );
    expect(e.shell.fetches.single.skip, 0);
  });

  test('next and previous page re-fetch with skip', () async {
    final e = await env(docs: 45);
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    final c = e.container.read(cursorPageProvider(_key).notifier);

    c.nextPage();
    await loaded(e);
    var s = e.container.read(cursorPageProvider(_key));
    expect(s.docs.first.text, fakeDoc(20));
    expect(e.shell.fetches.last.skip, 20);

    c.nextPage();
    await loaded(e);
    s = e.container.read(cursorPageProvider(_key));
    expect(s.docs.length, 5);
    expect(s.hasNext, isFalse);
    expect(s.firstIndex, 40);

    c.nextPage();
    expect(
      e.container.read(cursorPageProvider(_key)).page,
      2,
      reason: 'no page past the end',
    );

    c.prevPage();
    await loaded(e);
    s = e.container.read(cursorPageProvider(_key));
    expect(s.page, 1);
    expect(s.docs.first.text, fakeDoc(20));
  });

  test('changing the page size returns to the first page', () async {
    final e = await env();
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    final c = e.container.read(cursorPageProvider(_key).notifier);
    c.nextPage();
    await loaded(e);
    c.setPageSize(50);
    await loaded(e);
    final s = e.container.read(cursorPageProvider(_key));
    expect(s.page, 0);
    expect(s.docs.length, 50);
    expect(e.shell.fetches.last.limit, 51);
  });

  test('a failed fetch is reported and keeps the controller usable', () async {
    final e = await env();
    e.shell.fetchError = const GrpcError.notFound('cursor handle not found');
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    var s = e.container.read(cursorPageProvider(_key));
    expect(s.error, contains('cursor handle not found'));
    expect(s.docs, isEmpty);

    e.shell.fetchError = null;
    e.container.read(cursorPageProvider(_key).notifier).refresh();
    await loaded(e);
    s = e.container.read(cursorPageProvider(_key));
    expect(s.error, isNull);
    expect(s.docs, isNotEmpty);
  });

  test('view and selection', () async {
    final e = await env();
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    final c = e.container.read(cursorPageProvider(_key).notifier);
    c.setView(DocView.json);
    expect(e.container.read(cursorPageProvider(_key)).view, DocView.json);
    c.select(2);
    c.select(4, toggle: true);
    expect(e.container.read(cursorPageProvider(_key)).selected, {2, 4});
    c.select(4, toggle: true);
    expect(e.container.read(cursorPageProvider(_key)).selected, {2});
  });

  test('an empty cursor has no documents and no next page', () async {
    final e = await env(docs: 0);
    e.container.read(cursorPageProvider(_key));
    await loaded(e);
    final s = e.container.read(cursorPageProvider(_key));
    expect(s.docs, isEmpty);
    expect(s.hasNext, isFalse);
  });

  group('columnsOf', () {
    test('_id first, then fields in order of appearance', () {
      final cols = columnsOf([
        DocItem('{"b":{"\$numberInt":"1"},"_id":{"\$numberInt":"1"},"a":"x"}'),
        DocItem('{"c":null,"a":"y"}'),
      ]);
      expect(cols.map((c) => c.name), ['_id', 'b', 'a', 'c']);
    });

    test('documents without _id (aggregation) work', () {
      final cols = columnsOf([DocItem('{"total":{"\$numberInt":"3"}}')]);
      expect(cols.map((c) => c.name), ['total']);
    });

    test('invalid documents are skipped', () {
      expect(
        columnsOf([DocItem('not json'), DocItem('{"a":1}')]).map((c) => c.name),
        ['a'],
      );
    });
  });
}
