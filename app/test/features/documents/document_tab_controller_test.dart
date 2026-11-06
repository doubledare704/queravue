import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/application/document_tab_controller.dart';
import 'package:queravue/features/documents/domain/models.dart';

import '../../support/document_harness.dart';
import '../../support/fake_document_repository.dart';

void main() {
  group('paging', () {
    test('loads the first page, knows there is another, and counts', () async {
      final repo = FakeDocumentRepository(count: 120);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      var s = c.read(documentTabProvider(id));
      expect(s.docs.length, 50);
      expect(s.hasNext, isTrue);
      expect(s.page, 0);
      // One extra document is requested to learn that a next page exists.
      expect(repo.finds.single.limit, 51);
      await waitFor(() => c.read(documentTabProvider(id)).count != null);
      s = c.read(documentTabProvider(id));
      expect(s.count!.count, 120);
      expect(s.columns.map((f) => f.name), ['_id', 'name', 'big']);
    });

    test('next and previous page re-query with skip', () async {
      final repo = FakeDocumentRepository(count: 120);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final n = c.read(documentTabProvider(id).notifier);

      await n.nextPage();
      await loaded(c, id);
      expect(c.read(documentTabProvider(id)).docs.first.text, fakeDoc(50));
      expect(repo.finds.last.skip, 50);

      await n.nextPage();
      await loaded(c, id);
      var s = c.read(documentTabProvider(id));
      expect(s.docs.length, 20);
      expect(s.hasNext, isFalse);
      expect(s.firstIndex, 100);

      await n.prevPage();
      await loaded(c, id);
      s = c.read(documentTabProvider(id));
      expect(s.page, 1);
      expect(s.docs.first.text, fakeDoc(50));
    });

    test('page size change returns to page 0', () async {
      final repo = FakeDocumentRepository(count: 120);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final n = c.read(documentTabProvider(id).notifier);
      await n.nextPage();
      await loaded(c, id);
      await n.setPageSize(100);
      await loaded(c, id);
      final s = c.read(documentTabProvider(id));
      expect(s.page, 0);
      expect(s.docs.length, 100);
    });

    test('the user limit caps the total across pages', () async {
      final repo = FakeDocumentRepository(count: 120);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final n = c.read(documentTabProvider(id).notifier);
      await n.setPageSize(20);
      await loaded(c, id);
      await n.run(const FindQuery(skip: 5, limit: 30));
      await loaded(c, id);
      var s = c.read(documentTabProvider(id));
      expect(s.docs.length, 20);
      expect(s.hasNext, isTrue);
      expect(s.docs.first.text, fakeDoc(5));
      await n.nextPage();
      await loaded(c, id);
      s = c.read(documentTabProvider(id));
      expect(s.docs.length, 10); // 30 - 20
      expect(s.hasNext, isFalse);
    });
  });

  group('query errors and cancel', () {
    test(
      'a parse error is kept next to the input and the page survives',
      () async {
        final repo = FakeDocumentRepository(count: 5);
        final c = makeDocContainer(repo);
        final id = openUsersTab(c);
        await loaded(c, id);
        repo.findError = const DocumentError(
          kind: DocErrorKind.parse,
          message: 'invalid character',
          input: DocInput.filter,
          position: 6,
        );
        await c
            .read(documentTabProvider(id).notifier)
            .run(const FindQuery(filter: '{"a": ]}'));
        await loaded(c, id);
        final s = c.read(documentTabProvider(id));
        expect(s.queryError!.input, DocInput.filter);
        expect(s.queryError!.position, 6);
        expect(s.error, isNull);
        expect(s.isLoading, isFalse);
      },
    );

    test('a server error becomes a banner message', () async {
      final repo = FakeDocumentRepository(count: 5);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      repo.findError = const DocumentError(
        kind: DocErrorKind.timeout,
        message: 'timed out',
      );
      await c.read(documentTabProvider(id).notifier).refresh();
      await loaded(c, id);
      expect(c.read(documentTabProvider(id)).error, 'timed out');
    });

    test('Cancel shows after 300 ms and cancels the stream', () async {
      final repo = FakeDocumentRepository(count: 5)
        ..holdFind = Completer<void>();
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      c.read(
        documentTabProvider(id),
      ); // builds the controller, which starts the query
      await waitFor(() => repo.finds.isNotEmpty);
      expect(c.read(documentTabProvider(id)).showCancel, isFalse);
      await Future<void>.delayed(
        kCancelDelay + const Duration(milliseconds: 60),
      );
      var s = c.read(documentTabProvider(id));
      expect(s.isLoading, isTrue);
      expect(s.showCancel, isTrue);

      await c.read(documentTabProvider(id).notifier).cancel();
      s = c.read(documentTabProvider(id));
      expect(s.isLoading, isFalse);
      expect(s.showCancel, isFalse);
      expect(repo.findCancelled, 1);
    });

    test('a fast query never shows Cancel', () async {
      final repo = FakeDocumentRepository(count: 5);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      var sawCancel = false;
      c.listen(documentTabProvider(id), (_, n) => sawCancel |= n.showCancel);
      await loaded(c, id);
      expect(sawCancel, isFalse);
    });
  });

  group('edits', () {
    test('replace sends the loaded text as expected_document', () async {
      final repo = FakeDocumentRepository(count: 3);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final doc = c.read(documentTabProvider(id)).docs[1];
      final out = await c
          .read(documentTabProvider(id).notifier)
          .replace(doc, '{"_id":{"\$numberInt":"1"},"name":"new"}');
      expect(out, isA<WriteOk>());
      expect(repo.replaced.single.id, '{"\$numberInt":"1"}');
      expect(repo.replaced.single.expected, doc.text);
      expect(repo.finds.length, 2); // reloaded after the write
    });

    test('a conflict is reported with the stored document; overwrite drops expected', () async {
      final repo = FakeDocumentRepository(count: 3);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final n = c.read(documentTabProvider(id).notifier);
      final doc = c.read(documentTabProvider(id)).docs[1];
      repo.replaceError = const DocumentError(
        kind: DocErrorKind.conflict,
        message: 'document changed on server',
        currentDocument: '{"_id":{"\$numberInt":"1"},"name":"theirs"}',
      );
      final out = await n.replace(
        doc,
        '{"_id":{"\$numberInt":"1"},"name":"mine"}',
      );
      expect(out, isA<WriteConflict>());
      expect((out as WriteConflict).current, contains('theirs'));
      expect(repo.finds.length, 1); // nothing reloaded on conflict

      final again = await n.replace(
        doc,
        '{"_id":{"\$numberInt":"1"},"name":"mine"}',
        overwrite: true,
      );
      expect(again, isA<WriteOk>());
      expect(repo.replaced.last.expected, isNull);
    });

    test('a document without _id cannot be replaced', () async {
      final repo = FakeDocumentRepository(count: 1);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final out = await c
          .read(documentTabProvider(id).notifier)
          .replace(DocItem('{"name":"x"}'), '{}');
      expect(out, isA<WriteFailed>());
      expect(repo.replaced, isEmpty);
    });

    test('a write failure from the server is returned, not thrown', () async {
      final repo = FakeDocumentRepository(count: 1);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      repo.replaceError = const DocumentError(
        kind: DocErrorKind.parse,
        message: 'bad',
        input: DocInput.document,
        position: 3,
      );
      final out = await c
          .read(documentTabProvider(id).notifier)
          .replace(c.read(documentTabProvider(id)).docs.first, '{');
      expect(out, isA<WriteFailed>());
      expect((out as WriteFailed).error.position, 3);
    });

    test('insert sends the text and reloads', () async {
      final repo = FakeDocumentRepository(count: 1);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final out = await c
          .read(documentTabProvider(id).notifier)
          .insert('{"name":"n"}');
      expect(out, isA<WriteOk>());
      expect(repo.inserted, ['{"name":"n"}']);
    });

    test('delete selected passes the ids and the confirmation', () async {
      final repo = FakeDocumentRepository(count: 5);
      final c = makeDocContainer(repo);
      final id = openUsersTab(c);
      await loaded(c, id);
      final n = c.read(documentTabProvider(id).notifier);
      n
        ..select(1)
        ..select(3, toggle: true);
      expect(c.read(documentTabProvider(id)).selected, {1, 3});
      final out = await n.deleteSelected(confirmed: true);
      expect(out, isA<WriteOk>());
      expect(repo.deleted.single, [
        '{"\$numberInt":"1"}',
        '{"\$numberInt":"3"}',
      ]);
      expect(repo.deleteConfirmed.single, isTrue);
      expect(c.read(documentTabProvider(id)).selected, isEmpty);
    });
  });
}
