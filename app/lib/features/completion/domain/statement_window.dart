/// The part of a document the core needs to complete at a cursor: the
/// statement around it. [start] is the offset of the window in the document.
class StatementWindow {
  const StatementWindow(this.text, this.start);

  final String text;
  final int start;
}

const _maxWindow = 20000;

/// Statement around [cursor] for SQL: bounded by semicolons that are outside
/// quotes and comments. Only an approximation of the core's splitter; a wrong
/// guess costs worse completions, never a wrong edit.
StatementWindow sqlStatementWindow(String doc, int cursor) {
  var start = 0;
  var end = doc.length;
  var i = 0;
  while (i < doc.length) {
    final c = doc.codeUnitAt(i);
    if (c == 0x27 || c == 0x22 || c == 0x60) {
      i = _skipQuoted(doc, i, c);
      continue;
    }
    if (c == 0x2D && i + 1 < doc.length && doc.codeUnitAt(i + 1) == 0x2D) {
      i = _skipLine(doc, i);
      continue;
    }
    if (c == 0x2F && i + 1 < doc.length && doc.codeUnitAt(i + 1) == 0x2A) {
      final close = doc.indexOf('*/', i + 2);
      i = close < 0 ? doc.length : close + 2;
      continue;
    }
    if (c == 0x3B) {
      if (i < cursor) {
        start = i + 1;
      } else {
        end = i;
        break;
      }
    }
    i++;
  }
  return _bounded(doc, start, end, cursor);
}

/// The text around [cursor], at most 20,000 code units.
StatementWindow plainWindow(String doc, int cursor) =>
    _bounded(doc, 0, doc.length, cursor);

StatementWindow _bounded(String doc, int start, int end, int cursor) {
  if (end - start > _maxWindow) {
    final from = (cursor - _maxWindow ~/ 2).clamp(start, end).toInt();
    final to = (from + _maxWindow).clamp(start, end).toInt();
    return StatementWindow(doc.substring(from, to), from);
  }
  return StatementWindow(doc.substring(start, end), start);
}

int _skipQuoted(String doc, int from, int quote) {
  var i = from + 1;
  while (i < doc.length) {
    final c = doc.codeUnitAt(i);
    if (c == 0x5C && quote != 0x60) {
      i += 2;
      continue;
    }
    if (c == quote) {
      if (i + 1 < doc.length && doc.codeUnitAt(i + 1) == quote) {
        i += 2;
        continue;
      }
      return i + 1;
    }
    i++;
  }
  return doc.length;
}

int _skipLine(String doc, int from) {
  final nl = doc.indexOf('\n', from);
  return nl < 0 ? doc.length : nl + 1;
}
