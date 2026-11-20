import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/application/document_preview_controller.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/mongo_sql/application/mongo_sql_controller.dart';
import 'package:queravue/features/mongo_sql/data/mongo_sql_repository.dart';
import 'package:queravue/features/mongo_sql/domain/mongo_sql_translation.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';

import '../../support/fake_document_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/shell_workspace_fakes.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late EditorTab tab;
  late FakeMongoSqlRepository repository;
  late FakeDocumentRepository documents;
  late FakeShellRepository shell;
  late MongoSqlController controller;

  MongoSqlState state() => container.read(mongoSqlControllerProvider(tab));

  setUp(() {
    repository = FakeMongoSqlRepository();
    documents = FakeDocumentRepository();
    shell = FakeShellRepository();
    container = ProviderContainer(
      overrides: [
        ...shellOverrides(
          shell: shell,
          workspace: FakeWorkspaceRepository(),
          query: FakeQueryRepository()
            ..capabilities = {'document_store', 'shell'},
        ),
        mongoSqlRepositoryProvider.overrideWithValue(repository),
        documentRepositoryProvider.overrideWithValue(documents),
      ],
    );
    addTearDown(container.dispose);
    tab = container
        .read(editorTabsProvider.notifier)
        .openMongoSql('c1', database: 'shop');
    container.listen(mongoSqlControllerProvider(tab), (_, _) {});
    container.listen(documentPreviewProvider(tab.id), (_, _) {});
    controller = container.read(mongoSqlControllerProvider(tab).notifier);
  });

  Future<void> edit(String sql) async {
    tab.controller.text = sql;
    await settle(() => !state().pending);
  }

  test(
    'debounces edits and previews FIND with its translated scope and cap',
    () async {
      tab.controller.text = 'SELECT';
      tab.controller.text = findSql;
      await settle(() => state().current != null);
      expect(repository.requests.single, (
        sessionId: 'session-1',
        database: 'shop',
        sql: findSql,
      ));
      expect(state().current, same(findTranslation));
      expect(state().translation!.warnings, [warning]);
      await controller.preview();
      expect(documents.findTargets.single.database, 'shop');
      expect(documents.findTargets.single.collection, 'orders');
      expect(
        documents.finds.single,
        findTranslation.query.copyWith(limit: kDefaultPreviewLimit),
      );
      expect(documents.findTimeouts.single, kPreviewMaxTimeMs);
      expect(
        container.read(documentPreviewProvider(tab.id)).docs,
        hasLength(kDefaultPreviewLimit),
      );
    },
  );

  test('previews and runs AGGREGATE via shell cursor handles', () async {
    shell.cursorDocs = documents.docs;
    shell.scripts.add(const [aggregateCursor]);
    await edit(aggregateSql);
    expect(state().current, same(aggregate));
    await controller.preview();
    expect(shell.evals.single.code, aggregate.shellCode);
    expect(shell.fetches.single, (
      cursorId: 'orders-count',
      skip: 0,
      limit: kDefaultPreviewLimit,
    ));
    expect(shell.closed, ['shell-1']);

    shell.scripts.add(const [aggregateCursor]);
    await controller.run();
    expect(state().showPreview, isFalse);
    expect(shell.evals.last.code, aggregate.shellCode);
    expect(shell.evals.last.confirmed, isFalse);
    expect(shell.fetches, hasLength(1));
    expect(
      cursorOf(container.read(shellTabProvider(tab.id)))?.cursorId,
      'orders-count',
    );
  });

  for (final (sql, failure, offset) in [
    (parseSql, parseError, 17),
    (unsupportedSql, unsupportedError, 0),
  ]) {
    test(
      '${failure.kind.name} keeps the last good translation stale and blocks execution',
      () async {
        await edit(findSql);
        tab.controller.text = sql;
        expect(state().pending, isTrue);
        expect(state().stale, isTrue);
        await settle(() => !state().pending);
        expect(state().failure, same(failure));
        expect(state().errorOffset, offset);
        expect(state().translation, same(findTranslation));
        expect(state().current, isNull);
        await controller.run();
        await controller.preview();
        expect(shell.evals, isEmpty);
        expect(documents.finds, isEmpty);
      },
    );
  }

  test('an obsolete reply cannot overwrite a newer translation', () async {
    final obsolete = Completer<MongoSqlTranslation>();
    repository.responses[findSql] = () => obsolete.future;
    tab.controller.text = findSql;
    await settle(() => repository.requests.isNotEmpty);

    await edit(aggregateSql);
    obsolete.complete(findTranslation);
    await Future<void>.delayed(Duration.zero);

    expect(repository.cancellations, [findSql]);
    expect(state().current, same(aggregate));
  });
}
