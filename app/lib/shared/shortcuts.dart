import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

/// Cmd on macOS, Ctrl elsewhere.
SingleActivator primaryShortcut(LogicalKeyboardKey key, {bool shift = false}) {
  final mac = defaultTargetPlatform == TargetPlatform.macOS;
  return SingleActivator(key, meta: mac, control: !mac, shift: shift);
}

/// Display text of the primary modifier: ⌘ or Ctrl+.
String get primaryLabel =>
    defaultTargetPlatform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';
