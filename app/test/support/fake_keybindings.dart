import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';

import 'package:queravue/shared/actions/action_registry.dart';
import 'package:queravue/shared/actions/key_chord.dart';

class FakeKeybindings extends KeybindingsController {
  FakeKeybindings([this.initial = const KeybindingOverrides()]);

  final KeybindingOverrides initial;

  @override
  Future<KeybindingOverrides> build() async => initial;

  KeybindingOverrides get _now => state.value ?? initial;

  @override
  Future<void> setChord(String actionId, KeyChord? chord) async =>
      state = AsyncData(_now.setChord(actionId, chord));

  @override
  Future<void> reset(String actionId) async =>
      state = AsyncData(_now.reset(actionId));

  @override
  Future<void> resetAll() async =>
      state = const AsyncData(KeybindingOverrides());
}
