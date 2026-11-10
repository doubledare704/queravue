import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/shared/actions/action_registry.dart';
import 'package:queravue/shared/actions/action_shortcuts.dart';
import 'package:queravue/shared/actions/app_action.dart';
import 'package:queravue/shared/actions/key_chord.dart';

const k = KeyChord(LogicalKeyboardKey.keyK, primary: true);
const j = KeyChord(LogicalKeyboardKey.keyJ, primary: true);

void main() {
  late List<String> ran;

  AppAction action(String id, KeyChord? chord) => AppAction(
    id: id,
    title: id,
    category: ActionCategory.editor,
    defaultChord: chord,
    run: (_, _) async => ran.add(id),
  );

  Future<void> press(
    WidgetTester tester,
    ActionRegistry registry, {
    Set<String> enabled = const {'a', 'b'},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ActionShortcuts(
            registry: registry,
            enabledActionIds: Provider((_) => enabled),
            child: const Focus(autofocus: true, child: SizedBox()),
          ),
        ),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  }

  testWidgets('a chord runs its action, a rebound chord follows the user', (
    tester,
  ) async {
    ran = [];
    await press(
      tester,
      ActionRegistry([
        action('a', k),
        action('b', null),
      ], const KeybindingOverrides().setChord('b', j)),
    );
    expect(ran, ['a', 'b']);
  });

  testWidgets('a conflicted chord runs nothing', (tester) async {
    ran = [];
    await press(tester, ActionRegistry([action('a', k), action('b', k)]));
    expect(ran, isEmpty);
  });

  testWidgets('the chord of a disabled action runs nothing', (tester) async {
    ran = [];
    await press(
      tester,
      ActionRegistry([action('a', k), action('b', j)]),
      enabled: {'b'},
    );
    expect(ran, ['b']);
  });
}
