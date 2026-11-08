import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaletteMode { all, actions, tabs, objects }

/// Declaration order is the order groups appear in for equal scores.
enum PaletteGroup {
  action('Actions'),
  tab('Tabs'),
  connection('Connections'),
  object('Objects'),
  file('Files');

  const PaletteGroup(this.label);
  final String label;
}

class PaletteQuery {
  const PaletteQuery(this.mode, this.text);
  final PaletteMode mode;
  final String text;
}

/// `>` limits the palette to actions, `@` to tabs and `#` to database objects.
PaletteQuery parsePaletteQuery(String raw) {
  if (raw.isEmpty) return const PaletteQuery(PaletteMode.all, '');
  final rest = raw.substring(1).trim();
  return switch (raw[0]) {
    '>' => PaletteQuery(PaletteMode.actions, rest),
    '@' => PaletteQuery(PaletteMode.tabs, rest),
    '#' => PaletteQuery(PaletteMode.objects, rest),
    _ => PaletteQuery(PaletteMode.all, raw.trim()),
  };
}

bool _isWordChar(String c) => RegExp('[a-z0-9]').hasMatch(c);

/// Scores [text] against [query]: a prefix beats a substring, a substring
/// starting a word beats one inside a word, and any subsequence beats
/// nothing. Null means no match. Case and spaces in [query] are ignored.
int? fuzzyScore(String query, String text) {
  final q = query.toLowerCase().replaceAll(' ', '');
  final t = text.toLowerCase();
  if (q.isEmpty) return 0;
  if (t.startsWith(q)) return 1000 - t.length;
  final at = t.indexOf(q);
  if (at >= 0) {
    final startsWord = !_isWordChar(t[at - 1]);
    return (startsWord ? 800 : 600) - at;
  }
  var i = 0;
  int? first;
  int last = 0;
  for (var j = 0; j < t.length && i < q.length; j++) {
    if (t[j] == q[i]) {
      first ??= j;
      last = j;
      i++;
    }
  }
  if (i < q.length) return null;
  return 400 - (last - first!);
}

/// Case-insensitive subsequence match, so "lpg" finds "Local PG".
bool fuzzyMatch(String query, String text) => fuzzyScore(query, text) != null;

@immutable
class PaletteItem {
  const PaletteItem({
    required this.id,
    required this.title,
    required this.group,
    required this.run,
    this.subtitle = '',
    this.trailing = '',
    this.conflicted = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String trailing;
  final PaletteGroup group;
  final bool conflicted;
  final Future<void> Function(BuildContext context, WidgetRef ref) run;
}

/// Items matching [query], best first; ties keep group then source order.
List<PaletteItem> rankPaletteItems(
  List<PaletteItem> items,
  String query, {
  int limit = 60,
}) {
  final scored = <(int, int, PaletteItem)>[];
  for (var i = 0; i < items.length; i++) {
    final score = fuzzyScore(query, items[i].title);
    if (score != null) scored.add((score, i, items[i]));
  }
  scored.sort((a, b) {
    final byScore = b.$1.compareTo(a.$1);
    if (byScore != 0) return byScore;
    final byGroup = a.$3.group.index.compareTo(b.$3.group.index);
    return byGroup != 0 ? byGroup : a.$2.compareTo(b.$2);
  });
  return [for (final s in scored.take(limit)) s.$3];
}
