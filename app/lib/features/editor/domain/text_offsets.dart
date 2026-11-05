// Helpers between editor text offsets (UTF-16 code units, `\n` line breaks)
// and line numbers.

/// Zero-based line containing [offset] in [text].
int lineOfOffset(String text, int offset) {
  final end = offset.clamp(0, text.length).toInt();
  var line = 0;
  for (var i = 0; i < end; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

/// Inclusive range of zero-based lines covered by [start, end) in [text].
(int first, int last) linesOfRange(String text, int start, int end) {
  final first = lineOfOffset(text, start);
  final last = lineOfOffset(text, end > start ? end - 1 : end);
  return (first, last < first ? first : last);
}

/// Offset of ([line], [column]) given the text of each line.
int offsetOfPosition(List<String> lines, int line, int column) {
  var off = 0;
  final stop = line.clamp(0, lines.length).toInt();
  for (var i = 0; i < stop; i++) {
    off += lines[i].length + 1;
  }
  return off + column;
}

/// ([line], [column]) of [offset] in [text].
(int line, int column) positionOfOffset(String text, int offset) {
  final end = offset.clamp(0, text.length).toInt();
  var line = 0;
  var lineStart = 0;
  for (var i = 0; i < end; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, end - lineStart);
}
