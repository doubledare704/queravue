import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_action.dart';
import 'key_chord.dart';

/// The user's changes to default chords. A key mapped to null unbinds the
/// action.
@immutable
class KeybindingOverrides {
  const KeybindingOverrides({this.chords = const {}, this.problems = const []});

  final Map<String, KeyChord?> chords;
  final List<String> problems;

  KeybindingOverrides setChord(String actionId, KeyChord? chord) =>
      KeybindingOverrides(chords: {...chords, actionId: chord});

  KeybindingOverrides reset(String actionId) =>
      KeybindingOverrides(chords: {...chords}..remove(actionId));

  String toJson() =>
      const JsonEncoder.withIndent('  ')
          .convert({for (final e in chords.entries) e.key: e.value?.id});
}

/// Reads the keybindings file. Bad entries are skipped and reported in
/// [KeybindingOverrides.problems]; they never break the defaults.
KeybindingOverrides parseKeybindingOverrides(String text) {
  if (text.trim().isEmpty) return const KeybindingOverrides();
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    return KeybindingOverrides(problems: ['Not valid JSON: ${e.message}']);
  }
  if (decoded is! Map<String, Object?>) {
    return const KeybindingOverrides(
      problems: ['Expected an object of action id to key'],
    );
  }
  final chords = <String, KeyChord?>{};
  final problems = <String>[];
  for (final e in decoded.entries) {
    final value = e.value;
    if (value == null) {
      chords[e.key] = null;
      continue;
    }
    final chord = value is String ? KeyChord.parse(value) : null;
    if (chord == null) {
      problems.add('${e.key}: "$value" is not a key');
    } else {
      chords[e.key] = chord;
    }
  }
  return KeybindingOverrides(chords: chords, problems: problems);
}

@immutable
class KeyConflict {
  const KeyConflict(this.chord, this.actions);
  final KeyChord chord;
  final List<AppAction> actions;
}

/// All actions with their effective chords. A chord that more than one action
/// uses is a conflict and fires nothing until the user resolves it.
class ActionRegistry {
  ActionRegistry(this.actions, [this.overrides = const KeybindingOverrides()]) {
    final byChord = <KeyChord, List<AppAction>>{};
    for (final a in actions) {
      final chord = chordOf(a.id);
      if (chord != null) byChord.putIfAbsent(chord, () => []).add(a);
    }
    for (final e in byChord.entries) {
      if (e.value.length > 1) {
        conflicts.add(KeyConflict(e.key, e.value));
        conflicted.addAll(e.value.map((a) => a.id));
      } else {
        bindings[e.key] = e.value.single;
      }
    }
    final known = {for (final a in actions) a.id};
    unknownIds = [
      for (final id in overrides.chords.keys)
        if (!known.contains(id)) id,
    ];
  }

  final List<AppAction> actions;
  final KeybindingOverrides overrides;

  final List<KeyConflict> conflicts = [];
  final Set<String> conflicted = {};
  final Map<KeyChord, AppAction> bindings = {};
  late final List<String> unknownIds;

  List<String> get problems => [
    ...overrides.problems,
    for (final id in unknownIds) '$id: no such action',
  ];

  AppAction? byId(String id) {
    for (final a in actions) {
      if (a.id == id) return a;
    }
    return null;
  }

  KeyChord? chordOf(String actionId) {
    if (overrides.chords.containsKey(actionId)) {
      return overrides.chords[actionId];
    }
    return byId(actionId)?.defaultChord;
  }

  bool isConflicted(String actionId) => conflicted.contains(actionId);

  String shortcutLabel(String actionId) => chordOf(actionId)?.label ?? '';
}
