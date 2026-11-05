import 'dart:typed_data';

/// Longest preview rendered inside a grid cell.
const int kCellPreviewChars = 200;

/// Text of a cell value. With [forCopy], NULL is empty (matching the core's
/// TSV/CSV output); otherwise it is `NULL`.
String formatCell(Object? v, {bool forCopy = false}) {
  switch (v) {
    case null:
      return forCopy ? '' : 'NULL';
    case String():
      return v;
    case bool() || int():
      return '$v';
    case double():
      if (v.isNaN) return 'NaN';
      if (v.isInfinite) return v.isNegative ? '-Infinity' : 'Infinity';
      return '$v';
    case DateTime():
      return _formatTimestamp(v);
    case Uint8List():
      return '\\x${_hex(v)}';
    case List<Object?>():
      return '[${v.map(_formatNested).join(',')}]';
  }
  return '$v';
}

String _formatNested(Object? v) {
  if (v == null) return 'null';
  if (v is String) {
    return '"${v.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
  return formatCell(v);
}

String _two(int n) => n.toString().padLeft(2, '0');

String _formatTimestamp(DateTime t) {
  final u = t.toUtc();
  final frac = u.microsecond != 0 || u.millisecond != 0
      ? '.${(u.millisecond * 1000 + u.microsecond).toString().padLeft(6, '0')}'
            .replaceFirst(RegExp(r'0+$'), '')
      : '';
  return '${u.year.toString().padLeft(4, '0')}-${_two(u.month)}-${_two(u.day)} '
      '${_two(u.hour)}:${_two(u.minute)}:${_two(u.second)}$frac+00';
}

String _hex(Uint8List b) {
  final sb = StringBuffer();
  for (final x in b) {
    sb.write(x.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// Single-line, bounded text for a grid cell: control whitespace collapsed,
/// cut at [kCellPreviewChars]. Painting a 1 MB string per cell would stall
/// text layout, so values are cut before they reach a `Text` widget.
String cellPreview(Object? v) {
  if (v == null) return 'NULL';
  var s = formatCell(v);
  if (s.length > kCellPreviewChars) {
    // Don't split a surrogate pair.
    var end = kCellPreviewChars;
    if (s.codeUnitAt(end - 1) & 0xFC00 == 0xD800) end--;
    s = '${s.substring(0, end)}…';
  }
  return s.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
}

/// Whether a cell's full value differs from its preview, so the value viewer
/// shows more than the cell does.
bool isTruncatedInCell(Object? v) {
  if (v == null) return false;
  final s = formatCell(v);
  return s.length > kCellPreviewChars || s.contains('\n') || s.contains('\r');
}

/// Quotes [s] for TSV/CSV the way the core does: only when needed.
String delimitedField(String s, String sep) {
  if (!s.contains('"') &&
      !s.contains('\n') &&
      !s.contains('\r') &&
      !s.contains(sep)) {
    return s;
  }
  return '"${s.replaceAll('"', '""')}"';
}
