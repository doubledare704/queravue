import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';
import 'package:queravue/features/documents/application/document_tab_controller.dart';
import 'package:queravue/features/documents/domain/ejson.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/documents/presentation/doc_views.dart';
import 'package:queravue/features/documents/presentation/document_tab_view.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';

import '../../support/document_harness.dart';
import '../../support/fake_document_repository.dart';

Future<ProviderContainer> pumpTab(
  WidgetTester tester,
  FakeDocumentRepository repo, {
  bool production = false,
  String? tabIdOut,
}) async {
  tester.view.physicalSize = const Size(1500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(
    overrides: documentOverrides(repo, production: production),
  );
  addTearDown(c.dispose);
  final id = openUsersTab(c);
  final tab = c.read(editorTabsProvider).tabs.firstWhere((t) => t.id == id);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: Scaffold(body: DocumentTabView(tab: tab)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
  return c;
}

String get tabId => 'tab-1';

/// Taps and lets the double-tap window close, so no timer stays pending.
Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 400));
}

CodeLineEditingController editorController(WidgetTester tester) => tester
    .widget<CodeEditor>(find.byKey(const Key('doc-code-editor')))
    .controller!;

Future<void> pressCtrlEnter(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  group('table view', () {
    testWidgets('shows sampled columns and cell values', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 5));
      expect(find.byKey(const Key('doc-table')), findsOneWidget);
      expect(find.textContaining('_id'), findsWidgets);
      expect(find.textContaining('name', findRichText: true), findsWidgets);
      expect(find.text('"doc-0"'), findsOneWidget);
      // Int64 renders as NumberLong, an Int32 _id as a plain number.
      expect(
        find.textContaining('NumberLong("9007199254740000")'),
        findsOneWidget,
      );
      expect(find.text('1–5 of ~120'), findsOneWidget);
    });

    testWidgets('builds only the cells on screen', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 600));
      await tester.tap(find.byKey(const Key('doc-page-size')));
      await tester.pump();
      await tester.tap(find.text('500 / page').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      final cells = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('doc-cell-'),
      );
      expect(cells.evaluate().length, greaterThan(0));
      expect(cells.evaluate().length, lessThan(150)); // not 500 x 3
    });

    testWidgets('missing fields show a dash and row headers select', (
      tester,
    ) async {
      final repo = FakeDocumentRepository(count: 0)
        ..docs = [
          '{"_id":{"\$numberInt":"1"},"name":"a"}',
          '{"_id":{"\$numberInt":"2"}}',
        ];
      final c = await pumpTab(tester, repo);
      expect(find.text('—'), findsWidgets);
      await tapKey(tester, const Key('doc-row-header-1'));
      await tester.pump();
      expect(c.read(documentTabProvider(tabId)).selected, {1});
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      expect(c.read(documentTabProvider(tabId)).selected, {0, 1});
    });

    testWidgets('empty result shows a message', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 0));
      expect(find.byKey(const Key('doc-empty')), findsOneWidget);
    });
  });

  group('tree view', () {
    testWidgets('expands fields and shows type badges', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 3));
      await tester.tap(find.text('Tree'));
      await tester.pump();
      expect(find.byKey(const Key('doc-tree')), findsOneWidget);
      // Collapsed: only documents (labelled by _id), no field rows yet.
      expect(find.byKey(const Key('doc-tree-row-0/name')), findsNothing);
      await tapKey(tester, const Key('doc-tree-row-0'));
      await tester.pump();
      expect(find.byKey(const Key('doc-tree-row-0/name')), findsOneWidget);
      expect(find.text('String'), findsWidgets);
      expect(find.text('Int64'), findsWidgets);
      expect(find.text('Int32'), findsWidgets);
    });

    testWidgets('is virtualized: 500 documents build a handful of rows', (
      tester,
    ) async {
      await pumpTab(tester, FakeDocumentRepository(count: 600));
      await tester.tap(find.text('Tree'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-page-size')));
      await tester.pump();
      await tester.tap(find.text('500 / page').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      final rows = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('doc-tree-row-'),
      );
      expect(rows.evaluate().length, lessThan(60));
      expect(rows.evaluate().length, greaterThan(5));
    });
  });

  group('json view', () {
    testWidgets('shows shell-style documents', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 3));
      await tester.tap(find.text('JSON'));
      await tester.pump();
      expect(find.byKey(const Key('doc-json')), findsOneWidget);
      expect(
        find.textContaining('big: NumberLong("9007199254740001")'),
        findsOneWidget,
      );
    });
  });

  group('query bar', () {
    testWidgets('Ctrl+Enter runs the typed filter, sort and projection', (
      tester,
    ) async {
      final repo = FakeDocumentRepository(count: 5);
      await pumpTab(tester, repo);
      await tester.enterText(
        find.byKey(const Key('doc-filter')),
        '{"name": "doc-1"}',
      );
      await tester.enterText(find.byKey(const Key('doc-sort')), '{"_id": -1}');
      await tester.enterText(
        find.byKey(const Key('doc-projection')),
        '{"name": 1}',
      );
      await tester.enterText(find.byKey(const Key('doc-skip')), '2');
      await tester.enterText(find.byKey(const Key('doc-limit')), '3');
      await pressCtrlEnter(tester);
      await tester.pump(const Duration(milliseconds: 50));
      final q = repo.finds.last;
      expect(q.filter, '{"name": "doc-1"}');
      expect(q.sort, '{"_id": -1}');
      expect(q.projection, '{"name": 1}');
      expect(repo.finds.last.skip, 2);
      expect(repo.finds.last.limit, 3);
    });

    testWidgets('the Run button runs too', (tester) async {
      final repo = FakeDocumentRepository(count: 5);
      await pumpTab(tester, repo);
      await tester.enterText(find.byKey(const Key('doc-filter')), '{"a":1}');
      await tester.tap(find.byKey(const Key('doc-run')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.finds.last.filter, '{"a":1}');
    });

    testWidgets(
      'a parse error from the core shows under the filter, with its position',
      (tester) async {
        final repo = FakeDocumentRepository(count: 5);
        await pumpTab(tester, repo);
        repo.findError = const DocumentError(
          kind: DocErrorKind.parse,
          message: "invalid character ']' looking for beginning of value",
          input: DocInput.filter,
          position: 6,
        );
        await tester.enterText(find.byKey(const Key('doc-filter')), '{"a": ]}');
        await tester.tap(find.byKey(const Key('doc-run')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();
        expect(find.textContaining('invalid character'), findsOneWidget);
        expect(find.textContaining('at character 7'), findsOneWidget);
        // The caret sits where the error is.
        final field = tester.widget<TextField>(
          find.byKey(const Key('doc-filter')),
        );
        expect(field.controller!.selection.baseOffset, 6);
      },
    );

    testWidgets('Cancel appears for a slow query and stops it', (tester) async {
      final repo = FakeDocumentRepository(count: 5);
      final c = await pumpTab(tester, repo);
      repo.holdFind = Completer<void>();
      await tester.tap(find.byKey(const Key('doc-run')));
      await tester.pump();
      expect(find.byKey(const Key('doc-cancel')), findsNothing);
      await tester.pump(kCancelDelay + const Duration(milliseconds: 50));
      expect(find.byKey(const Key('doc-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const Key('doc-cancel')));
      await tester.pump();
      expect(repo.findCancelled, greaterThan(0));
      expect(c.read(documentTabProvider(tabId)).isLoading, isFalse);
      expect(find.byKey(const Key('doc-run')), findsOneWidget);
    });
  });

  group('paging controls', () {
    testWidgets('next and previous move through pages', (tester) async {
      final repo = FakeDocumentRepository(count: 120);
      await pumpTab(tester, repo);
      expect(find.text('1–50 of ~120'), findsOneWidget);
      await tester.tap(find.byKey(const Key('doc-next')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('51–100 of ~120'), findsOneWidget);
      await tester.tap(find.byKey(const Key('doc-prev')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('1–50 of ~120'), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets(
      'edit shows a type-preserving diff and saves with expected_document',
      (tester) async {
        final repo = FakeDocumentRepository(count: 3);
        await pumpTab(tester, repo);
        await tapKey(tester, const Key('doc-row-header-1'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('doc-edit')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('doc-editor-dialog')), findsOneWidget);
        final code = editorController(tester);
        expect(code.text, contains('"\$numberLong"'));
        code.text = code.text.replaceFirst(
          '"\$numberLong"',
          '"\$numberDouble"',
        );
        await tester.pump();

        await tester.tap(find.text('Changes'));
        await tester.pumpAndSettle();
        expect(find.textContaining('numberLong'), findsWidgets); // removed line
        expect(find.textContaining('numberDouble'), findsWidgets); // added line
        expect(find.textContaining('2 changed lines'), findsOneWidget);

        await tester.tap(find.byKey(const Key('doc-editor-save')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('doc-editor-dialog')), findsNothing);
        final r = repo.replaced.single;
        expect(r.id, '{"\$numberInt":"1"}');
        expect(r.expected, fakeDoc(1));
        expect(r.doc, contains('numberDouble'));
      },
    );

    testWidgets('invalid JSON disables Save and explains', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 3));
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-edit')));
      await tester.pumpAndSettle();
      editorController(tester).text = '{"a": ';
      await tester.pump();
      expect(find.byKey(const Key('doc-editor-error')), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('doc-editor-save')),
      );
      expect(save.onPressed, isNull);
      await tester.tap(find.byKey(const Key('doc-editor-cancel')));
      await tester.pumpAndSettle();
    });

    testWidgets('Save is disabled until something changed', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 3));
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-edit')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('doc-editor-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets(
      'a conflict offers reload or overwrite; overwrite resends without expected',
      (tester) async {
        final repo = FakeDocumentRepository(count: 3);
        await pumpTab(tester, repo);
        await tapKey(tester, const Key('doc-row-header-0'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('doc-edit')));
        await tester.pumpAndSettle();
        final code = editorController(tester);
        code.text = code.text.replaceFirst('doc-0', 'mine');
        await tester.pump();

        repo.replaceError = const DocumentError(
          kind: DocErrorKind.conflict,
          message: 'document changed on server',
          currentDocument: '{"_id":{"\$numberInt":"0"},"name":"theirs"}',
        );
        await tester.tap(find.byKey(const Key('doc-editor-save')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('doc-conflict-dialog')), findsOneWidget);
        expect(find.text('Document changed on server'), findsOneWidget);

        await tester.tap(find.byKey(const Key('doc-conflict-overwrite')));
        await tester.pumpAndSettle();
        expect(repo.replaced.length, 2);
        expect(repo.replaced.first.expected, fakeDoc(0));
        expect(repo.replaced.last.expected, isNull);
        expect(find.byKey(const Key('doc-editor-dialog')), findsNothing);
      },
    );

    testWidgets('a conflict can be resolved by reloading', (tester) async {
      final repo = FakeDocumentRepository(count: 3);
      await pumpTab(tester, repo);
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-edit')));
      await tester.pumpAndSettle();
      final code = editorController(tester);
      code.text = code.text.replaceFirst('doc-0', 'mine');
      await tester.pump();
      repo.replaceError = const DocumentError(
        kind: DocErrorKind.conflict,
        message: 'x',
        currentDocument: '{}',
      );
      await tester.tap(find.byKey(const Key('doc-editor-save')));
      await tester.pumpAndSettle();
      final before = repo.finds.length;
      await tester.tap(find.byKey(const Key('doc-conflict-reload')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('doc-editor-dialog')), findsNothing);
      expect(repo.finds.length, greaterThan(before));
      expect(repo.replaced.length, 1);
    });

    testWidgets('a deleted document cannot be overwritten', (tester) async {
      final repo = FakeDocumentRepository(count: 3);
      await pumpTab(tester, repo);
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-edit')));
      await tester.pumpAndSettle();
      final code = editorController(tester);
      code.text = code.text.replaceFirst('doc-0', 'mine');
      await tester.pump();
      repo.replaceError = const DocumentError(
        kind: DocErrorKind.conflict,
        message: 'gone',
      );
      await tester.tap(find.byKey(const Key('doc-editor-save')));
      await tester.pumpAndSettle();
      expect(find.text('Document deleted on server'), findsOneWidget);
      expect(find.byKey(const Key('doc-conflict-overwrite')), findsNothing);
    });

    testWidgets('insert sends the typed text', (tester) async {
      final repo = FakeDocumentRepository(count: 1);
      await pumpTab(tester, repo);
      await tester.tap(find.byKey(const Key('doc-insert')));
      await tester.pumpAndSettle();
      final code = editorController(tester);
      code.text = '{"n": 1}';
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-editor-save')));
      await tester.pumpAndSettle();
      expect(repo.inserted.single, '{"n": 1}');
    });

    testWidgets('insert opens with a template', (tester) async {
      await pumpTab(tester, FakeDocumentRepository(count: 1));
      await tester.tap(find.byKey(const Key('doc-insert')));
      await tester.pumpAndSettle();
      expect(editorController(tester).text, '{\n  \n}');
      expect(find.text('Insert document'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('always asks, then deletes the selected ids', (tester) async {
      final repo = FakeDocumentRepository(count: 4);
      await pumpTab(tester, repo);
      await tapKey(tester, const Key('doc-row-header-0'));
      await tapKey(tester, const Key('doc-row-header-2'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete 2 documents?'), findsOneWidget);
      expect(find.textContaining('PRODUCTION'), findsNothing);

      await tester.tap(find.byKey(const Key('doc-delete-cancel')));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);

      await tester.tap(find.byKey(const Key('doc-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('doc-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repo.deleted.single, [
        '{"\$numberInt":"0"}',
        '{"\$numberInt":"2"}',
      ]);
    });

    testWidgets('production connections say so and need the explicit button', (
      tester,
    ) async {
      final repo = FakeDocumentRepository(count: 2);
      await pumpTab(tester, repo, production: true);
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // connections list loads
      await tapKey(tester, const Key('doc-row-header-0'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('doc-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PRODUCTION'), findsOneWidget);
      expect(find.text('Delete from production'), findsOneWidget);
      await tester.tap(find.byKey(const Key('doc-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repo.deleted.length, 1);
      expect(repo.deleteConfirmed.single, isTrue);
    });
  });

  test('formatCount groups thousands', () {
    expect(formatCount(7), '7');
    expect(formatCount(1234), '1,234');
    expect(formatCount(1000000), '1,000,000');
  });

  test('typeColor handles every type', () {
    final cs = ColorScheme.fromSeed(seedColor: Colors.indigo);
    for (final t in EjsonType.values) {
      expect(typeColor(t, cs), isA<Color>());
    }
  });
}
