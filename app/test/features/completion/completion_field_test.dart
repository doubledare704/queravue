import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/application/user_snippets.dart';
import 'package:queravue/features/completion/data/completion_repository.dart';
import 'package:queravue/features/completion/domain/snippets.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:queravue/features/completion/presentation/completion_field.dart';

import '../../support/fake_completion.dart';

CompletionItem field(String label, int start, int end) => CompletionItem(
  label: label,
  kind: CompletionKind.field,
  insertText: '"$label"',
  replaceStart: start,
  replaceEnd: end,
  sortKey: '10100$label',
  detail: 'string · 100%',
);

CompletionResult fields(CompletionRequest r) {
  var start = r.cursorOffset;
  while (start > 0 && RegExp('[a-z"_]').hasMatch(r.text[start - 1])) {
    start--;
  }
  return CompletionResult(
    items: [
      for (final n in const ['name', 'age', 'address.city'])
        field(n, start, r.cursorOffset),
    ],
  );
}

Future<(FakeCompletionRepository, TextEditingController)> pumpField(
  WidgetTester tester,
) async {
  final repo = FakeCompletionRepository(answer: fields);
  final controller = TextEditingController();
  final focus = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focus.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        completionRepositoryProvider.overrideWithValue(repo),
        userSnippetsProvider.overrideWith((ref) async => const <Snippet>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: CompletionField(
                controller: controller,
                focusNode: focus,
                sessionId: () => 's1',
                database: 'app',
                collection: 'users',
                child: TextField(controller: controller, focusNode: focus),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pump();
  return (repo, controller);
}

Future<void> type(WidgetTester tester, String text) async {
  tester.testTextInput.enterText(text);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the popup opens under the field and filters while typing', (
    tester,
  ) async {
    final (repo, _) = await pumpField(tester);
    await type(tester, '{ ');
    await type(tester, '{ n');
    expect(find.byKey(const Key('completion-popup')), findsOneWidget);
    expect(find.text('name'), findsOneWidget);
    expect(repo.requests.first.collection, 'users');
    expect(repo.requests.first.database, 'app');
    expect(repo.requests.first.context, CompletionContext.mongoQuery);
    await type(tester, '{ na');
    expect(find.text('age'), findsNothing);
  });

  testWidgets('Enter inserts the quoted key in place of the typed prefix', (
    tester,
  ) async {
    final (_, controller) = await pumpField(tester);
    await type(tester, '{ ');
    await type(tester, '{ n');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, '{ "name"');
    expect(controller.selection.baseOffset, '{ "name"'.length);
    expect(find.byKey(const Key('completion-popup')), findsNothing);
  });

  testWidgets('arrows choose, Escape closes', (tester) async {
    final (_, controller) = await pumpField(tester);
    await type(tester, '{ ');
    await type(tester, '{ a');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(controller.text, '{ "age"');
    await type(tester, '{ "age", ');
    await type(tester, '{ "age", a');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(const Key('completion-popup')), findsNothing);
  });

  testWidgets('clicking a row inserts it', (tester) async {
    final (_, controller) = await pumpField(tester);
    await type(tester, '{ ');
    await type(tester, '{ a');
    await tester.tap(find.text('age'));
    await tester.pump();
    expect(controller.text, '{ "age"');
  });

  testWidgets('losing focus closes the popup', (tester) async {
    await pumpField(tester);
    await type(tester, '{ ');
    await type(tester, '{ a');
    expect(find.byKey(const Key('completion-popup')), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.byKey(const Key('completion-popup')), findsNothing);
  });
}
