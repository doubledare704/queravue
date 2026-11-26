final _tokens = RegExp(
  r"""--[^\n]*|/\*[\s\S]*?(?:\*/|$)|'(?:''|[^'])*(?:'|$)|"(?:""|[^"])*(?:"|$)|`(?:``|[^`])*(?:`|$)|[\p{L}_$][\p{L}\p{N}_$]*|[^\s]""",
  unicode: true,
);
final _bareIdentifier = RegExp(r'^[\p{L}_$][\p{L}\p{N}_$]*$', unicode: true);
const _clauses = {
  'FROM',
  'JOIN',
  'INNER',
  'LEFT',
  'RIGHT',
  'FULL',
  'CROSS',
  'ON',
  'WHERE',
  'GROUP',
  'HAVING',
  'ORDER',
  'LIMIT',
  'OFFSET',
  'UNION',
};

typedef MongoSqlCompletionContext = ({
  int start,
  int end,
  bool collections,
  String? collection,
});

MongoSqlCompletionContext? mongoSqlCompletionContext(String sql, int cursor) {
  final all = _tokens.allMatches(sql).toList();
  final token = all
      .where((t) => t.start < cursor && cursor <= t.end)
      .firstOrNull;
  final text = token?.group(0) ?? '';
  if (text.startsWith("'") || _comment(text)) {
    return null;
  }

  final tokens = all.where((t) => !_comment(t.group(0)!)).toList();
  final inName = _name(text) != null;
  final start = inName ? token!.start : cursor;
  final end = inName ? token!.end : cursor;
  final before = tokens.where((t) => t.end <= start).toList();
  final previous = before.lastOrNull?.group(0)?.toUpperCase();
  if (previous == 'FROM' || previous == 'JOIN') {
    return (start: start, end: end, collections: true, collection: null);
  }

  final sources = <(String, String?)>[];
  for (var i = 0; i + 1 < tokens.length; i++) {
    final keyword = tokens[i].group(0)?.toUpperCase();
    if (keyword != 'FROM' && keyword != 'JOIN') continue;
    final collection = _name(tokens[i + 1].group(0)!);
    if (collection == null) continue;
    var aliasIndex = i + 2;
    if (aliasIndex < tokens.length &&
        tokens[aliasIndex].group(0)?.toUpperCase() == 'AS') {
      aliasIndex++;
    }
    final alias = aliasIndex < tokens.length
        ? tokens[aliasIndex].group(0)!
        : '';
    sources.add((
      collection,
      _clauses.contains(alias.toUpperCase()) ? null : _name(alias),
    ));
  }

  final path = <(String, int)>[];
  var pathStart = start;
  for (var i = before.length - 1; i >= 1; i -= 2) {
    if (before[i].group(0) != '.' ||
        before[i].end != pathStart ||
        before[i - 1].end != before[i].start) {
      break;
    }
    final part = _name(before[i - 1].group(0)!);
    if (part == null) break;
    pathStart = before[i - 1].start;
    path.insert(0, (part, pathStart));
  }

  final source = path.isEmpty
      ? null
      : sources
            .where((s) => s.$1 == path.first.$1 || s.$2 == path.first.$1)
            .firstOrNull;
  final fieldStart = source == null
      ? pathStart
      : path.length == 1
      ? start
      : path[1].$2;
  return (
    start: fieldStart,
    end: end,
    collections: false,
    collection: source?.$1 ?? sources.firstOrNull?.$1,
  );
}

bool _comment(String text) => text.startsWith('--') || text.startsWith('/*');

String? _name(String token) {
  if (token.startsWith('"') || token.startsWith('`')) {
    final quote = token[0];
    final end = token.length > 1 && token.endsWith(quote)
        ? token.length - 1
        : token.length;
    return token.substring(1, end).replaceAll(quote + quote, quote);
  }
  return _bareIdentifier.hasMatch(token) ? token : null;
}

bool isBareMongoSqlIdentifier(String name) =>
    _bareIdentifier.hasMatch(name) && !_clauses.contains(name.toUpperCase());
