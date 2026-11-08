import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/command_palette/application/builtin_actions.dart';
import 'package:queravue/shared/actions/action_registry.dart';
import 'package:queravue/shared/actions/app_action.dart';
import 'package:queravue/shared/actions/key_chord.dart';

AppAction action(String id, [KeyChord? chord]) => AppAction(
  id: id,
  title: id,
  category: ActionCategory.editor,
  defaultChord: chord,
  run: (_, _) async {},
);

const k = KeyChord(LogicalKeyboardKey.keyK, primary: true);
const j = KeyChord(LogicalKeyboardKey.keyJ, primary: true);

void main() {
  test('defaults apply until the user overrides them', () {
    final actions = [action('a', k), action('b')];
    final plain = ActionRegistry(actions);
    expect(plain.chordOf('a'), k);
    expect(plain.bindings[k]?.id, 'a');

    final moved = ActionRegistry(
      actions,
      const KeybindingOverrides().setChord('a', j).setChord('b', k),
    );
    expect(moved.chordOf('a'), j);
    expect(moved.chordOf('b'), k);
    expect(moved.conflicts, isEmpty);
  });

  test('null unbinds, reset restores the default', () {
    final actions = [action('a', k)];
    final overrides = const KeybindingOverrides().setChord('a', null);
    expect(ActionRegistry(actions, overrides).chordOf('a'), isNull);
    expect(ActionRegistry(actions, overrides).bindings, isEmpty);
    expect(ActionRegistry(actions, overrides.reset('a')).chordOf('a'), k);
  });

  test('two actions on one chord conflict and neither fires', () {
    final registry = ActionRegistry([
      action('a', k),
      action('b', j),
    ], const KeybindingOverrides().setChord('b', k));
    expect(registry.conflicts.single.chord, k);
    expect(registry.conflicts.single.actions.map((a) => a.id), ['a', 'b']);
    expect(registry.isConflicted('a'), isTrue);
    expect(registry.bindings, isEmpty);
  });

  test('overrides file: valid, unbound, bad and unknown entries', () {
    final overrides = parseKeybindingOverrides(
      '{"a": "primary+j", "b": null, "c": "hyper+q", "d": 5}',
    );
    expect(overrides.chords['a'], j);
    expect(overrides.chords.containsKey('b'), isTrue);
    expect(overrides.chords['b'], isNull);
    expect(overrides.chords.containsKey('c'), isFalse);
    expect(overrides.problems, hasLength(2));

    final registry = ActionRegistry([action('a', k)], overrides);
    expect(registry.problems, contains('b: no such action'));
  });

  test('broken JSON keeps the defaults', () {
    expect(parseKeybindingOverrides('{nope').problems, hasLength(1));
    expect(parseKeybindingOverrides('[1]').problems, hasLength(1));
    expect(parseKeybindingOverrides('  ').chords, isEmpty);
  });

  test('overrides survive a write and read', () {
    final overrides = const KeybindingOverrides()
        .setChord('a', j)
        .setChord('b', null);
    final again = parseKeybindingOverrides(overrides.toJson());
    expect(again.chords['a'], j);
    expect(again.chords.containsKey('b'), isTrue);
  });

  test('built-in actions have unique ids and no default conflicts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final actions = container.read(builtinActionsProvider);
    expect({for (final a in actions) a.id}, hasLength(actions.length));
    expect(ActionRegistry(actions).conflicts, isEmpty);
  });

  test('every main action has a shortcut', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final registry = ActionRegistry(container.read(builtinActionsProvider));
    for (final id in [
      'connection.new',
      'editor.new',
      'editor.close',
      'editor.run',
      'editor.runAll',
      'editor.format',
      'editor.cancel',
      'history.open',
      'shell.new',
      'workspace.open',
      'workspace.search',
      'workspace.save',
      'workspace.saveAs',
      'palette.open',
    ]) {
      expect(registry.chordOf(id), isNotNull, reason: id);
    }
  });
}
