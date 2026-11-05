import 'package:flutter/widgets.dart';

/// Uniform control surface for both editors.
abstract class EditorHandle {
  int get lineCount;
  void moveCursorTo(int line, int column);

  /// Inserts [text] at the cursor through the editor's own editing path.
  void insert(String text);

  /// Runs a case-insensitive find; completes with the number of matches.
  Future<int> find(String pattern);

  /// Replaces all matches of the current find; null if unsupported.
  Future<int?> replaceAll(String pattern, String replacement);

  /// Whether more than one caret/selection can exist at once.
  bool get supportsMultiCursor;

  /// Whether our own popup widget is used for completions.
  bool get customPopupVisible;
}

class EditorArgs {
  EditorArgs({required this.text, required this.dark, required this.onHandle});
  final String text;
  final bool dark;
  final ValueChanged<EditorHandle> onHandle;
}

const kCustomPopupKey = ValueKey('custom-autocomplete-popup');
