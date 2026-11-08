import 'completion_models.dart';

const matchPrefix = 0;
const matchWord = 1;
const matchSubstring = 2;
const matchFuzzy = 3;

/// How [name] matches the typed [prefix], or null. Mirrors
/// core/internal/completion/match.go; test/features/completion/match_golden_test.dart
/// checks both against the same cases.
int? matchName(String prefix, String name) {
  if (prefix.isEmpty) return matchPrefix;
  final p = prefix.toLowerCase().runes.toList();
  final n = name.toLowerCase().runes.toList();
  if (_hasPrefix(n, p)) return matchPrefix;
  if (_wordMatch(p, _splitWords(name))) return matchWord;
  if (_hasSubstring(n, p)) return matchSubstring;
  if (_isSubsequence(p, n)) return matchFuzzy;
  return null;
}

bool _hasPrefix(List<int> s, List<int> prefix) {
  if (prefix.length > s.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (s[i] != prefix[i]) return false;
  }
  return true;
}

bool _hasSubstring(List<int> s, List<int> sub) {
  for (var i = 0; i + sub.length <= s.length; i++) {
    if (_hasPrefix(s.sublist(i), sub)) return true;
  }
  return false;
}

bool _isSubsequence(List<int> p, List<int> s) {
  var i = 0;
  for (final r in s) {
    if (i < p.length && r == p[i]) i++;
  }
  return i == p.length;
}

bool _isUpper(int r) {
  final c = String.fromCharCode(r);
  return c != c.toLowerCase() && c == c.toUpperCase();
}

bool _isLower(int r) {
  final c = String.fromCharCode(r);
  return c != c.toUpperCase() && c == c.toLowerCase();
}

bool _isDigit(int r) => r >= 0x30 && r <= 0x39;

List<List<int>> _splitWords(String name) {
  final words = <List<int>>[];
  var cur = <int>[];
  void flush() {
    if (cur.isNotEmpty) {
      words.add(cur);
      cur = <int>[];
    }
  }

  final rs = name.runes.toList();
  for (var i = 0; i < rs.length; i++) {
    final r = rs[i];
    if (r == 0x5F || r == 0x2D || r == 0x20 || r == 0x2E || r == 0x24) {
      flush();
      continue;
    }
    if (_isUpper(r) && i > 0 && (_isLower(rs[i - 1]) || _isDigit(rs[i - 1]))) {
      flush();
    } else if (_isDigit(r) && i > 0 && !_isDigit(rs[i - 1])) {
      flush();
    }
    cur.add(String.fromCharCode(r).toLowerCase().runes.first);
  }
  flush();
  return words;
}

bool _wordMatch(List<int> p, List<List<int>> words) {
  for (var start = 0; start < words.length; start++) {
    if (_consume(p, words, start)) return true;
  }
  return false;
}

bool _consume(List<int> p, List<List<int>> words, int at) {
  if (p.isEmpty) return true;
  if (at >= words.length) return false;
  final w = words[at];
  for (var k = w.length < p.length ? w.length : p.length; k >= 1; k--) {
    if (_hasPrefix(w, p.sublist(0, k)) &&
        _consume(p.sublist(k), words, at + 1)) {
      return true;
    }
  }
  return false;
}

/// Items matching [prefix], re-ranked with the core's sort key layout:
/// tier, match class, exact, then the core's own tie-breakers and the label.
List<CompletionItem> refilter(List<CompletionItem> items, String prefix) {
  final out = <CompletionItem>[];
  for (final item in items) {
    final cls = matchName(prefix, _matchLabel(item));
    if (cls == null) continue;
    final exact =
        prefix.isNotEmpty &&
            _matchLabel(item).toLowerCase() == prefix.toLowerCase()
        ? 0
        : 1;
    final key = item.sortKey;
    out.add(
      CompletionItem(
        label: item.label,
        kind: item.kind,
        detail: item.detail,
        insertText: item.insertText,
        replaceStart: item.replaceStart,
        replaceEnd: item.replaceEnd,
        sortKey: key.length > 3
            ? '${key[0]}$cls$exact${key.substring(3)}'
            : key,
      ),
    );
  }
  out.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return out;
}

String _matchLabel(CompletionItem item) => item.label;
