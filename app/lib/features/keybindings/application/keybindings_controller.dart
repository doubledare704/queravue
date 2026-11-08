import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/actions/action_registry.dart';
import '../../../shared/actions/key_chord.dart';
import '../../command_palette/application/builtin_actions.dart';
import '../../workspace/data/workspace_repository.dart';
import '../../workspace/domain/workspace_models.dart';

const keybindingsDir = '.queravue';
const keybindingsPath = '$keybindingsDir/keybindings.json';

/// The user's chords from `.queravue/keybindings.json` in the first workspace
/// root. A missing or unreadable file means the defaults.
final keybindingsProvider =
    AsyncNotifierProvider<KeybindingsController, KeybindingOverrides>(
      KeybindingsController.new,
    );

class KeybindingsController extends AsyncNotifier<KeybindingOverrides> {
  WorkspaceRepository get _repo => ref.read(workspaceRepositoryProvider);

  @override
  Future<KeybindingOverrides> build() async {
    try {
      final roots = await _repo.roots();
      if (roots.isEmpty) return const KeybindingOverrides();
      final file = await _repo.read(FilePath(roots.first.id, keybindingsPath));
      return parseKeybindingOverrides(file.content);
    } on Object {
      return const KeybindingOverrides();
    }
  }

  KeybindingOverrides get _current =>
      state.value ?? const KeybindingOverrides();

  Future<void> setChord(String actionId, KeyChord? chord) =>
      _apply(_current.setChord(actionId, chord));

  Future<void> reset(String actionId) => _apply(_current.reset(actionId));

  Future<void> resetAll() => _apply(const KeybindingOverrides());

  Future<void> _apply(KeybindingOverrides next) async {
    state = AsyncData(next);
    final roots = await _repo.roots();
    if (roots.isEmpty) return;
    final file = FilePath(roots.first.id, keybindingsPath);
    final content = '${next.toJson()}\n';
    try {
      await _repo.read(file);
      await _repo.write(file, content, force: true);
    } on Object {
      try {
        await _repo.create(
          FilePath(roots.first.id, keybindingsDir),
          isDir: true,
        );
      } on Object {
        // The folder may already exist; creating the file reports real errors.
      }
      await _repo.create(file, content: content);
    }
  }
}

/// Actions with the user's chords applied.
final actionRegistryProvider = Provider<ActionRegistry>((ref) {
  final overrides =
      ref.watch(keybindingsProvider).value ?? const KeybindingOverrides();
  return ActionRegistry(ref.watch(builtinActionsProvider), overrides);
});
