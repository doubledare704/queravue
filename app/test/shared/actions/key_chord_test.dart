import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/shared/actions/key_chord.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('an id parses back to the same chord', () {
    for (final id in [
      'primary+enter',
      'primary+shift+enter',
      'alt+shift+f',
      'escape',
      'primary+k',
      'f5',
      'primary+1',
    ]) {
      expect(KeyChord.parse(id)?.id, id);
    }
  });

  test('text that is not a chord is rejected', () {
    for (final bad in ['', 'primary+', 'hyper+k', 'primary+nonsense', '+k']) {
      expect(KeyChord.parse(bad), isNull, reason: bad);
    }
  });

  test('labels follow the platform', () {
    const chord = KeyChord(
      LogicalKeyboardKey.keyF,
      primary: true,
      shift: true,
      alt: true,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(chord.label, '⌥⇧⌘F');
    expect(const KeyChord(LogicalKeyboardKey.enter, primary: true).label, '⌘↵');
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(chord.label, 'Ctrl+Alt+Shift+F');
  });

  test('primary maps to Cmd on macOS and Ctrl elsewhere', () {
    const chord = KeyChord(LogicalKeyboardKey.keyK, primary: true);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(chord.activator.meta, isTrue);
    expect(chord.activator.control, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(chord.activator.control, isTrue);
    expect(chord.activator.meta, isFalse);
  });
}
