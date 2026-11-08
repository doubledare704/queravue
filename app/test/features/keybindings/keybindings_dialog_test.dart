import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';
import 'package:queravue/features/keybindings/presentation/keybindings_dialog.dart';
import 'package:queravue/shared/actions/action_registry.dart';
import 'package:queravue/shared/actions/key_chord.dart';

import '../../support/fake_keybindings.dart';

Future<ProviderContainer> pumpDialog(
  WidgetTester tester, {
  KeybindingOverrides initial = const KeybindingOverrides(),
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      keybindingsProvider.overrideWith(() => FakeKeybindings(initial)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: KeybindingsDialog())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('lists actions with their shortcuts and no conflicts', (
    tester,
  ) async {
    await pumpDialog(tester);
    expect(find.byKey(const Key('keybinding-editor.run')), findsOneWidget);
    expect(find.byKey(const Key('keybindings-conflicts')), findsNothing);
  });

  testWidgets('a clashing override shows the conflict screen', (tester) async {
    final container = await pumpDialog(
      tester,
      initial: const KeybindingOverrides().setChord(
        'editor.new',
        const KeyChord(LogicalKeyboardKey.keyW, primary: true),
      ),
    );
    expect(find.byKey(const Key('keybindings-conflicts')), findsOneWidget);
    final registry = container.read(actionRegistryProvider);
    expect(registry.isConflicted('editor.new'), isTrue);
    expect(registry.isConflicted('editor.close'), isTrue);
  });

  testWidgets('changing a shortcut captures the next key combination', (
    tester,
  ) async {
    final container = await pumpDialog(tester);
    await tester.tap(find.byKey(const Key('keybinding-change-editor.new')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    final chord = container.read(actionRegistryProvider).chordOf('editor.new');
    expect(chord?.id, 'primary+j');
  });

  testWidgets('clear and reset', (tester) async {
    final container = await pumpDialog(tester);
    await tester.tap(find.byKey(const Key('keybinding-clear-editor.new')));
    await tester.pumpAndSettle();
    expect(
      container.read(actionRegistryProvider).chordOf('editor.new'),
      isNull,
    );
    expect(find.text('Unbound'), findsOneWidget);
    await tester.tap(find.byKey(const Key('keybinding-reset-editor.new')));
    await tester.pumpAndSettle();
    expect(
      container.read(actionRegistryProvider).chordOf('editor.new'),
      isNotNull,
    );
  });

  testWidgets('bad entries in the file are reported', (tester) async {
    await pumpDialog(
      tester,
      initial: parseKeybindingOverrides('{"editor.new": "hyper+q"}'),
    );
    expect(find.byKey(const Key('keybindings-problems')), findsOneWidget);
  });
}
