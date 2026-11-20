import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';
import 'package:queravue/features/mongo_sql/data/mongo_sql_completion_repository.dart';
import 'package:queravue/features/mongo_sql/data/mongo_sql_repository.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:re_editor/re_editor.dart';

import '../../support/editor_typing.dart';
import '../../support/fake_document_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/shell_workspace_fakes.dart';
import 'fixtures.dart';

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(
      version: '0.1.0-dev',
      protocolVersion: 12,
      capabilities: {'query'},
    ),
  );
}

class _ShopSchema extends EmptySchemaRepository {
  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  }) async => const [
    SchemaObject(name: 'orders', type: SchemaObjectType.table),
  ];
}

class _SlowCursorShell extends FakeShellRepository {
  final cursor = StreamController<DocBatch>();

  Future<void> dispose() async => cursor.close();

  @override
  Stream<DocBatch> fetchCursor(
    String shellId,
    String cursorId, {
    int skip = 0,
    int limit = 0,
  }) => cursor.stream;
}

Future<ShellEnv> _pumpApp(
  WidgetTester tester, {
  Set<String> capabilities = const {'document_store', 'shell'},
  FakeShellRepository? shellRepository,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shell = shellRepository ?? FakeShellRepository();
  final workspace = FakeWorkspaceRepository();
  final query = FakeQueryRepository()..capabilities = capabilities;
  final container = ProviderContainer(
    overrides: [
      ...shellOverrides(
        shell: shell,
        workspace: workspace,
        query: query,
      ).where((override) => override.origin != schemaRepositoryProvider),
      schemaRepositoryProvider.overrideWithValue(_ShopSchema()),
      documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
      coreStatusProvider.overrideWith(_Connected.new),
      mongoSqlRepositoryProvider.overrideWithValue(FakeMongoSqlRepository()),
      mongoSqlCompletionRepositoryProvider.overrideWith(
        (ref, _) => MongoSqlCompletionRepository(
          listCollections: (_) async => ['orders', 'archived.orders'],
          sampleFields: (_) async => ['status', 'address.city'],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  container.read(selectedConnectionProvider.notifier).select('c1');
  await container.read(connectionSessionProvider('c1').notifier).connect();
  await tester.pumpAndSettle();
  return (
    container: container,
    shell: shell,
    workspace: workspace,
    query: query,
  );
}

Future<void> _shortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}

Finder _treeNode(String id) => find.byKey(Key('tree-node-$id'));

Future<void> _edit(WidgetTester tester, EditorTab tab, String sql) async {
  tab.controller.text = sql;
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Iterable<TextSpan> _spans(TextSpan root) sync* {
  yield root;
  for (final child
      in root.children?.whereType<TextSpan>() ?? const <TextSpan>[]) {
    yield* _spans(child);
  }
}

void main() {
  testWidgets('shortcut opens SQL mode and warnings jump to UTF-16 positions', (
    tester,
  ) async {
    final env = await _pumpApp(tester);
    expect(
      env.container.read(actionRegistryProvider).isConflicted('mongoSql.open'),
      isFalse,
    );
    await _shortcut(tester, LogicalKeyboardKey.keyG, shift: true);

    final tab = env.container.read(editorTabsProvider).tabs.single;
    expect(tab.kind, TabKind.mongoSql);
    expect(tab.shellDatabase, 'shop');
    await _edit(tester, tab, findSql);
    expect(find.text(findTranslation.shellCode), findsOneWidget);
    expect(find.text('Open in pipeline builder'), findsNothing);
    await tester.tap(find.text(warning.message));
    expect(tab.controller.selection.baseOffset, 50);

    await tester.tap(find.text('EJSON'));
    await tester.pumpAndSettle();
    expect(find.text(findTranslation.ejson), findsOneWidget);

    await _edit(tester, tab, parseSql);
    expect(find.text(parseError.diagnostic.message), findsOneWidget);
    expect(find.text('Stale'), findsOneWidget);
    expect(find.text(findTranslation.ejson), findsOneWidget);

    final editor = find.byKey(Key('mongo-sql-editor-${tab.id}'));
    final code = tester.widget<CodeEditor>(editor);
    final span = code.controller!.buildTextSpan(
      context: tester.element(editor),
      index: 1,
      textSpan: const TextSpan(
        children: [
          TextSpan(text: 'FROM '),
          TextSpan(text: '?'),
        ],
      ),
      style: const TextStyle(),
    );
    expect(
      _spans(span)
          .where((s) => s.style?.decoration == TextDecoration.underline)
          .single
          .text,
      '?',
    );
  });

  testWidgets(
    'collection menu seeds SQL and aggregate results page through the cursor',
    (tester) async {
      final env = await _pumpApp(tester);
      await tester.tap(_treeNode('db:shop'));
      await tester.pumpAndSettle();
      await tester.tap(
        _treeNode('coll:shop/orders'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Query with SQL'));
      await tester.pumpAndSettle();
      final tab = env.container.read(editorTabsProvider).tabs.single;
      expect(tab.controller.text, 'SELECT * FROM "orders";');

      await _edit(tester, tab, aggregateSql);
      env.shell.scripts.add(const [aggregateCursor]);
      env.shell.cursorDocs = List.generate(22, (i) => '{"name":"order-$i"}');
      await _shortcut(tester, LogicalKeyboardKey.enter);

      expect(env.shell.evals.single.code, aggregate.shellCode);
      expect(env.shell.fetches.single, (
        cursorId: 'orders-count',
        skip: 0,
        limit: 21,
      ));
      expect(find.byKey(const Key('cursor-table')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cursor-next')));
      await tester.pumpAndSettle();
      expect(env.shell.fetches.last.skip, 20);

      await tester.tap(find.text('Open in pipeline builder'));
      await tester.pumpAndSettle();
      expect(find.text(r'$group'), findsOneWidget);
    },
  );

  testWidgets('a slow full result can be cancelled while the cursor fetches', (
    tester,
  ) async {
    final shell = _SlowCursorShell();
    addTearDown(shell.dispose);
    final env = await _pumpApp(tester, shellRepository: shell);
    await _shortcut(tester, LogicalKeyboardKey.keyG, shift: true);
    final tab = env.container.read(editorTabsProvider).tabs.single;
    await _edit(tester, tab, aggregateSql);
    shell.scripts.add(const [aggregateCursor]);

    await tester.tap(find.byKey(const Key('mongo-sql-run')));
    for (var i = 0; i < 5 && !shell.cursor.hasListener; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(shell.cursor.hasListener, isTrue);
    expect(find.text('Cancel'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cancel'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(shell.cursor.hasListener, isFalse);
    expect(find.text('Results cancelled.'), findsOneWidget);
  });

  testWidgets('database context menu opens a tab in that database', (
    tester,
  ) async {
    final env = await _pumpApp(tester);
    await tester.tap(_treeNode('db:shop'), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Query with SQL'));
    await tester.pumpAndSettle();
    final tab = env.container.read(editorTabsProvider).tabs.single;
    expect(tab.isMongoSql, isTrue);
    expect(tab.shellDatabase, 'shop');
  });

  for (final capability in ['document_store', 'shell']) {
    testWidgets('SQL mode is hidden when the connection only has $capability', (
      tester,
    ) async {
      final env = await _pumpApp(tester, capabilities: {capability});
      await _shortcut(tester, LogicalKeyboardKey.keyG, shift: true);
      expect(env.container.read(editorTabsProvider).tabs, isEmpty);

      await tester.tap(_treeNode('db:shop'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.text('Query with SQL'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await _shortcut(tester, LogicalKeyboardKey.keyK);
      expect(find.text('Open SQL mode'), findsNothing);
    });
  }

  testWidgets('the command palette opens SQL mode on a supported connection', (
    tester,
  ) async {
    final env = await _pumpApp(tester);
    await _shortcut(tester, LogicalKeyboardKey.keyK);
    await tester.enterText(find.byType(TextField).last, '> Open SQL mode');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open SQL mode'));
    await tester.pumpAndSettle();
    expect(
      env.container.read(editorTabsProvider).tabs.single.isMongoSql,
      isTrue,
    );
  });

  testWidgets('editor completes collections and sampled field paths', (
    tester,
  ) async {
    final env = await _pumpApp(tester);
    await _shortcut(tester, LogicalKeyboardKey.keyG, shift: true);
    final tab = env.container.read(editorTabsProvider).tabs.single;
    final editor = find.byKey(Key('mongo-sql-editor-${tab.id}'));
    await tester.tap(editor);
    await tester.pumpAndSettle();

    await typeInEditor(tester, 'SELECT * FROM or');
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('orders'), findsOneWidget);
    await tester.tap(find.text('orders'));
    await tester.pump();
    expect(tab.controller.text, 'SELECT * FROM orders');

    await typeInEditor(tester, ' WHERE address.');
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('address.city'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  });

  testWidgets('MQL pane shows canonical pipeline and stale state', (
    tester,
  ) async {
    final env = await _pumpApp(tester);
    await _shortcut(tester, LogicalKeyboardKey.keyG, shift: true);
    final tab = env.container.read(editorTabsProvider).tabs.single;
    await _edit(tester, tab, aggregateSql);
    await tester.tap(find.text('EJSON'));
    await tester.pumpAndSettle();
    expect(find.text(aggregate.ejson), findsOneWidget);
    await _edit(tester, tab, unsupportedSql);
    expect(find.text('Stale'), findsOneWidget);
    expect(find.text(aggregate.ejson), findsOneWidget);
    expect(find.text('Open in pipeline builder'), findsNothing);
  });
}
