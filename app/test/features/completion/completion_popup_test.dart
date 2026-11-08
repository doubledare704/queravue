import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/data/completion_repository.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:queravue/features/completion/presentation/completion_host.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:re_editor/re_editor.dart';

import '../../support/editor_typing.dart';
import '../../support/fake_completion.dart';

class _Connected extends ConnectionSessionController {
  _Connected(super.connectionId, this.capabilities);

  final Set<String> capabilities;

  @override
  ConnectionSessionState build() => ConnectionSessionState(
    session: SessionInfo(id: 's1', capabilities: capabilities),
  );
}

CompletionItem table(String label, int start, int end) => CompletionItem(
  label: label,
  kind: CompletionKind.table,
  insertText: label,
  replaceStart: start,
  replaceEnd: end,
  sortKey: '10100$label',
  detail: 'table',
);

CompletionResult tables(CompletionRequest r) {
  var start = r.cursorOffset;
  while (start > 0 && RegExp('[a-z_]').hasMatch(r.text[start - 1])) {
    start--;
  }
  return CompletionResult(
    items: [
      for (final t in const ['orders', 'order_items', 'customers'])
        table(t, start, r.cursorOffset),
    ],
    catalogState: CatalogState.ready,
  );
}

Future<(FakeCompletionRepository, CodeLineEditingController)> pumpEditor(
  WidgetTester tester, {
  Set<String> capabilities = const {'completion'},
}) async {
  final repo = FakeCompletionRepository(answer: tables);
  final controller = CodeLineEditingController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        completionRepositoryProvider.overrideWithValue(repo),
        connectionSessionProvider('c')
            .overrideWith(() => _Connected('c', capabilities)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CompletionHost(
            connectionId: 'c',
            context: CompletionContext.sql,
            controller: controller,
            child: CodeEditor(controller: controller, autofocus: true),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byType(CodeEditor));
  await tester.pump();
  return (repo, controller);
}

void editorTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await body(tester);
    debugDefaultTargetPlatformOverride = null;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

void main() {
  editorTest(
    'typing after a context change shows the popup in the same frame',
    (tester) async {
      final (repo, _) = await pumpEditor(tester);
      await typeInEditor(tester, 'select * from ');
      await tester.pump(const Duration(milliseconds: 10));
      expect(repo.requests, isNotEmpty);

      await typeInEditor(tester, 'o');
      expect(find.byKey(const Key('completion-popup')), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
      expect(find.text('order_items'), findsOneWidget);
      expect(find.text('customers'), findsOneWidget);
    },
  );

  editorTest('narrowing the prefix filters the open popup', (tester) async {
    await pumpEditor(tester);
    await typeInEditor(tester, 'select * from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    await typeInEditor(tester, 'r');
    await typeInEditor(tester, 'd');
    expect(find.text('customers'), findsNothing);
    expect(find.text('orders'), findsOneWidget);
  });

  editorTest('Enter inserts the selected item in place of the prefix', (
    tester,
  ) async {
    final (_, controller) = await pumpEditor(tester);
    await typeInEditor(tester, 'select * from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    await typeInEditor(tester, 'r');
    await typeInEditor(tester, 'd');
    expect(find.byKey(const Key('completion-popup')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, 'select * from order_items');
    expect(find.byKey(const Key('completion-popup')), findsNothing);
  });

  editorTest('arrow keys move the selection', (tester) async {
    final (_, controller) = await pumpEditor(tester);
    await typeInEditor(tester, 'from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, 'from orders');
  });

  editorTest('clicking a row inserts it', (tester) async {
    final (_, controller) = await pumpEditor(tester);
    await typeInEditor(tester, 'from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'c');
    await tester.tap(find.text('customers'));
    await tester.pump();
    expect(controller.text, 'from customers');
  });

  editorTest('a session without the capability asks nothing', (tester) async {
    final (repo, _) = await pumpEditor(tester, capabilities: {'execute'});
    await typeInEditor(tester, 'from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    expect(repo.requests, isEmpty);
    expect(find.byKey(const Key('completion-popup')), findsNothing);
  });

  editorTest('a warming catalog shows the loading hint', (tester) async {
    final (repo, _) = await pumpEditor(tester);
    repo.answer = (r) => CompletionResult(
      items: tables(r).items,
      catalogState: CatalogState.warming,
    );
    await typeInEditor(tester, 'from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    expect(find.byKey(const Key('completion-loading')), findsOneWidget);
  });

  editorTest('a snippet is inserted with the caret at its marker', (
    tester,
  ) async {
    final (_, controller) = await pumpEditor(tester);
    await typeInEditor(tester, 's');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'e');
    await typeInEditor(tester, 'l');
    expect(find.text('select from a table'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, 'SELECT \nFROM ');
    expect(controller.selection.extentIndex, 0);
    expect(controller.selection.extentOffset, 'SELECT '.length);
  });

  editorTest('a late answer refreshes the popup that is already open', (
    tester,
  ) async {
    final (repo, _) = await pumpEditor(tester);
    await typeInEditor(tester, 'from ');
    await tester.pump(const Duration(milliseconds: 10));
    await typeInEditor(tester, 'o');
    expect(find.text('customers'), findsOneWidget);
    repo.answer = (r) => CompletionResult(
      items: [table('orders', r.cursorOffset - 1, r.cursorOffset)],
    );
    await typeInEditor(tester, 'r');
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('customers'), findsNothing);
  });
}
