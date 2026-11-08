import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'completion_models.dart';

/// A text template. `$0` marks where the caret lands after insertion.
@immutable
class Snippet {
  const Snippet({
    required this.trigger,
    required this.body,
    this.description = '',
    this.contexts = const {},
  });

  final String trigger;
  final String body;
  final String description;

  /// Empty means every context.
  final Set<CompletionContext> contexts;

  bool appliesTo(CompletionContext c) =>
      contexts.isEmpty || contexts.contains(c);

  /// The text to insert and the caret position inside it. The editor can
  /// only place the caret on the line where the insertion starts, so a `$0`
  /// on a later line puts the caret at the end of the first line.
  (String text, int caret) expand() {
    final at = body.indexOf(r'$0');
    final text = body.replaceFirst(r'$0', '');
    if (at < 0) return (text, firstLineEnd(text));
    return (text, at.clamp(0, firstLineEnd(text)).toInt());
  }

  static int firstLineEnd(String text) {
    final nl = text.indexOf('\n');
    return nl < 0 ? text.length : nl;
  }
}

const builtInSnippets = <Snippet>[
  Snippet(
    trigger: 'sel',
    body: 'SELECT \$0\nFROM ',
    description: 'select from a table',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'selw',
    body: 'SELECT * FROM \$0\nWHERE ',
    description: 'select with a filter',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'selc',
    body: 'SELECT count(*) FROM \$0',
    description: 'count rows',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'ins',
    body: 'INSERT INTO \$0 ()\nVALUES ()',
    description: 'insert a row',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'upd',
    body: 'UPDATE \$0\nSET \nWHERE ',
    description: 'update rows',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'del',
    body: 'DELETE FROM \$0\nWHERE ',
    description: 'delete rows',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'cte',
    body: 'WITH \$0 AS (\n  SELECT \n)\nSELECT *\nFROM ',
    description: 'common table expression',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'join',
    body: 'JOIN \$0 ON ',
    description: 'join a table',
    contexts: {CompletionContext.sql},
  ),
  Snippet(
    trigger: 'find',
    body: 'db.\$0.find({})',
    description: 'find documents',
    contexts: {CompletionContext.shell},
  ),
  Snippet(
    trigger: 'agg',
    body: 'db.\$0.aggregate([\n  { \$match: {} }\n])',
    description: 'aggregation pipeline',
    contexts: {CompletionContext.shell},
  ),
  Snippet(
    trigger: 'upd1',
    body: 'db.\$0.updateOne({}, { \$set: {} })',
    description: 'update one document',
    contexts: {CompletionContext.shell},
  ),
  Snippet(
    trigger: 'ins1',
    body: 'db.\$0.insertOne({})',
    description: 'insert one document',
    contexts: {CompletionContext.shell},
  ),
];

/// Reads the contents of `.queravue/snippets.json`:
/// `[{"trigger": "ord", "body": "SELECT * FROM orders WHERE \$0",
///    "description": "...", "contexts": ["sql"]}]`.
/// Entries that are not valid are skipped; a file that is not a JSON array
/// yields no snippets.
List<Snippet> parseUserSnippets(String json) {
  final Object? data;
  try {
    data = jsonDecode(json);
  } on FormatException {
    return const [];
  }
  if (data is! List) return const [];
  final out = <Snippet>[];
  for (final entry in data) {
    if (entry is! Map) continue;
    final trigger = entry['trigger'];
    final body = entry['body'];
    if (trigger is! String || trigger.trim().isEmpty || body is! String) {
      continue;
    }
    final contexts = <CompletionContext>{};
    final raw = entry['contexts'];
    if (raw is List) {
      for (final c in raw) {
        switch (c) {
          case 'sql':
            contexts.add(CompletionContext.sql);
          case 'shell':
            contexts.add(CompletionContext.shell);
          case 'mongoQuery' || 'mongo_query':
            contexts.add(CompletionContext.mongoQuery);
        }
      }
    }
    out.add(
      Snippet(
        trigger: trigger.trim(),
        body: body,
        description: entry['description'] is String
            ? entry['description'] as String
            : '',
        contexts: contexts,
      ),
    );
  }
  return out;
}
