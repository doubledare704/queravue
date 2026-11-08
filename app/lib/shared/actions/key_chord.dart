import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

final _namedKeys = <String, LogicalKeyboardKey>{
  'enter': LogicalKeyboardKey.enter,
  'escape': LogicalKeyboardKey.escape,
  'tab': LogicalKeyboardKey.tab,
  'space': LogicalKeyboardKey.space,
  'backspace': LogicalKeyboardKey.backspace,
  'delete': LogicalKeyboardKey.delete,
  'up': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
  'comma': LogicalKeyboardKey.comma,
  'period': LogicalKeyboardKey.period,
  'slash': LogicalKeyboardKey.slash,
  'backslash': LogicalKeyboardKey.backslash,
  'bracketleft': LogicalKeyboardKey.bracketLeft,
  'bracketright': LogicalKeyboardKey.bracketRight,
  'minus': LogicalKeyboardKey.minus,
  'equal': LogicalKeyboardKey.equal,
  'f1': LogicalKeyboardKey.f1,
  'f2': LogicalKeyboardKey.f2,
  'f3': LogicalKeyboardKey.f3,
  'f4': LogicalKeyboardKey.f4,
  'f5': LogicalKeyboardKey.f5,
  'f6': LogicalKeyboardKey.f6,
  'f7': LogicalKeyboardKey.f7,
  'f8': LogicalKeyboardKey.f8,
  'f9': LogicalKeyboardKey.f9,
  'f10': LogicalKeyboardKey.f10,
  'f11': LogicalKeyboardKey.f11,
  'f12': LogicalKeyboardKey.f12,
};

final _namesByKey = {for (final e in _namedKeys.entries) e.value: e.key};

const _symbols = {
  'enter': '↵',
  'escape': 'Esc',
  'tab': '⇥',
  'space': 'Space',
  'backspace': '⌫',
  'delete': '⌦',
  'up': '↑',
  'down': '↓',
  'left': '←',
  'right': '→',
  'comma': ',',
  'period': '.',
  'slash': '/',
  'backslash': r'\',
  'bracketleft': '[',
  'bracketright': ']',
  'minus': '-',
  'equal': '=',
};

bool get _onMac => defaultTargetPlatform == TargetPlatform.macOS;

final _modifierKeys = {
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
};

/// A key plus modifiers. [primary] is Cmd on macOS and Ctrl elsewhere, so one
/// stored chord works on every platform.
@immutable
class KeyChord {
  const KeyChord(
    this.key, {
    this.primary = false,
    this.shift = false,
    this.alt = false,
  });

  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool alt;

  static bool isModifier(LogicalKeyboardKey key) => _modifierKeys.contains(key);

  /// The chord a key-down event spells, or null for a lone modifier or a key
  /// that has no name.
  static KeyChord? fromEvent(KeyEvent event) {
    final key = event.logicalKey;
    if (isModifier(key) || _nameOf(key) == null) return null;
    final keyboard = HardwareKeyboard.instance;
    return KeyChord(
      key,
      primary: _onMac ? keyboard.isMetaPressed : keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
    );
  }

  /// Parses `primary+shift+enter` style text; null if it is not a chord.
  static KeyChord? parse(String text) {
    final parts = text.toLowerCase().split('+').map((p) => p.trim()).toList();
    if (parts.isEmpty || parts.last.isEmpty) return null;
    var primary = false, shift = false, alt = false;
    for (final modifier in parts.take(parts.length - 1)) {
      switch (modifier) {
        case 'primary':
          primary = true;
        case 'shift':
          shift = true;
        case 'alt':
          alt = true;
        default:
          return null;
      }
    }
    final key = _keyNamed(parts.last);
    if (key == null) return null;
    return KeyChord(key, primary: primary, shift: shift, alt: alt);
  }

  static LogicalKeyboardKey? _keyNamed(String name) {
    final named = _namedKeys[name];
    if (named != null) return named;
    if (name.length != 1) return null;
    final unit = name.codeUnitAt(0);
    final isLetter = unit >= 0x61 && unit <= 0x7a;
    final isDigit = unit >= 0x30 && unit <= 0x39;
    return isLetter || isDigit ? LogicalKeyboardKey.findKeyByKeyId(unit) : null;
  }

  static String? _nameOf(LogicalKeyboardKey key) {
    final named = _namesByKey[key];
    if (named != null) return named;
    final label = key.keyLabel.toLowerCase();
    return _keyNamed(label) == null ? null : label;
  }

  /// Stable text, platform independent: what the keybindings file stores.
  String get id => [
    if (primary) 'primary',
    if (alt) 'alt',
    if (shift) 'shift',
    _nameOf(key) ?? key.keyLabel.toLowerCase(),
  ].join('+');

  SingleActivator get activator => SingleActivator(
    key,
    meta: _onMac && primary,
    control: !_onMac && primary,
    shift: shift,
    alt: alt,
  );

  /// What the user sees: `⌥⇧F` on macOS, `Ctrl+Alt+Shift+F` elsewhere.
  String get label {
    final name = _nameOf(key) ?? key.keyLabel.toLowerCase();
    final keyText = _symbols[name] ?? name.toUpperCase();
    if (_onMac) {
      return '${alt ? '⌥' : ''}${shift ? '⇧' : ''}${primary ? '⌘' : ''}'
          '$keyText';
    }
    return [
      if (primary) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      keyText,
    ].join('+');
  }

  @override
  bool operator ==(Object other) =>
      other is KeyChord &&
      other.key == key &&
      other.primary == primary &&
      other.shift == shift &&
      other.alt == alt;

  @override
  int get hashCode => Object.hash(key, primary, shift, alt);

  @override
  String toString() => id;
}
