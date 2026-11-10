import 'package:flutter/painting.dart' show Axis;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/command_palette/application/builtin_actions.dart';
import 'package:queravue/features/command_palette/application/palette_items.dart';
import 'package:queravue/features/command_palette/domain/palette_search.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_layout_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';
import 'package:queravue/shared/actions/action_registry.dart';
import 'package:queravue/shared/actions/app_action.dart';
import 'package:queravue/shared/actions/key_chord.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

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

  test('every registered action has a palette entry with its shortcut', () {
    final container = makeContainer(FakeConnectionsRepository());
    final registry = container.read(actionRegistryProvider);
    final entries = {
      for (final item in container.read(paletteItemsProvider))
        if (item.group == PaletteGroup.action) item.id: item,
    };
    expect(registry.actions, isNotEmpty);
    for (final action in registry.actions) {
      final entry = entries[action.id];
      expect(entry, isNotNull, reason: action.id);
      expect(entry!.title, action.title);
      expect(entry.trailing, registry.shortcutLabel(action.id));
      if (action.defaultChord != null) {
        expect(entry.trailing, isNotEmpty, reason: action.id);
      }
    }
  });

  test('tab actions are disabled until a tab is open', () {
    final container = makeContainer(
      FakeConnectionsRepository(
        initial: const [
          ConnectionProfile(id: 'c1', name: 'Local PG', engineId: 'postgres'),
        ],
      ),
    );
    Set<String> enabled() => container.read(enabledActionIdsProvider);
    expect(enabled(), contains('connection.new'));
    expect(enabled(), isNot(contains('editor.close')));
    expect(enabled(), isNot(contains('editor.splitRight')));
    expect(enabled(), isNot(contains('documents.insert')));

    container.read(selectedConnectionProvider.notifier).select('c1');
    final tabs = container.read(editorTabsProvider.notifier)..open('c1');
    expect(enabled(), containsAll(['editor.close', 'editor.format']));
    expect(enabled(), isNot(contains('editor.splitRight')));
    expect(enabled(), isNot(contains('editor.focusGroup2')));

    tabs.open('c1');
    expect(enabled(), contains('editor.splitRight'));
    container.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    expect(
      enabled(),
      containsAll(['editor.focusGroup2', 'editor.moveToNextGroup']),
    );
    expect(enabled(), isNot(contains('editor.focusGroup3')));
  });
}
