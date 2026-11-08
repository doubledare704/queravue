import 'dart:async';

import '../data/completion_repository.dart';
import '../domain/completion_models.dart';
import '../domain/local_filter.dart';
import '../domain/snippets.dart';
import '../domain/statement_window.dart';

/// One row of the popup.
class Suggestion {
  const Suggestion({
    required this.label,
    required this.kind,
    required this.detail,
    required this.insertText,
    required this.caret,
  });

  final String label;
  final CompletionKind kind;
  final String detail;

  /// Text that replaces [Suggestions.input].
  final String insertText;

  /// Caret position inside [insertText] after the insertion.
  final int caret;
}

class Suggestions {
  const Suggestions({
    required this.input,
    required this.entries,
    required this.catalogState,
  });

  /// The text before the caret that the chosen entry replaces.
  final String input;
  final List<Suggestion> entries;
  final CatalogState catalogState;
}

class _Cache {
  _Cache(
    this.windowStart,
    this.windowText,
    this.replaceStart,
    this.prefix,
    this.result,
  );

  final int windowStart;
  final String windowText;
  final int replaceStart;
  final String prefix;
  final CompletionResult result;
}

/// Keeps the newest answer of the core and turns edits into suggestions
/// without waiting for the network (ADR 0015).
///
/// Every edit asks the core in the background and cancels the previous
/// question. [suggest] is synchronous: while the user extends the same
/// identifier it filters the last answer locally, so the popup appears
/// within the frame of the keystroke. The answer for the context a keystroke
/// opens (a space after FROM, a dot) was asked for by the previous edit.
class CompletionEngine {
  CompletionEngine({
    required this.repositoryOf,
    required this.context,
    required this.sessionId,
    this.database = _empty,
    this.collection = _empty,
    this.snippetsOf = _noSnippets,
    this.maxItems = 1000,
    this.maxRows = 200,
  });

  static String _empty() => '';
  static List<Snippet> _noSnippets() => const [];

  /// Resolved when a question is asked, so creating the engine never starts
  /// the core.
  final CompletionRepository Function() repositoryOf;
  final CompletionContext context;
  final String? Function() sessionId;
  final String Function() database;
  final String Function() collection;
  final List<Snippet> Function() snippetsOf;
  final int maxItems;
  final int maxRows;

  /// Called when a newer answer arrived.
  void Function()? onUpdated;

  Completer<void>? _cancel;
  _Cache? _cache;
  String? _lastText;
  int _lastCursor = -1;
  int _seq = 0;
  bool _disposed = false;

  CatalogState get catalogState =>
      _cache?.result.catalogState ?? CatalogState.unspecified;

  void dispose() {
    _disposed = true;
    _cancelPending();
  }

  void _cancelPending() {
    final c = _cancel;
    if (c != null && !c.isCompleted) c.complete();
  }

  StatementWindow _window(String text, int cursor) =>
      context == CompletionContext.sql
      ? sqlStatementWindow(text, cursor)
      : plainWindow(text, cursor);

  /// Asks the core about the caret position, if text or caret changed.
  void onEdit(String text, int cursor) {
    if (_disposed || (text == _lastText && cursor == _lastCursor)) return;
    _lastText = text;
    _lastCursor = cursor;
    unawaited(_ask(text, cursor));
  }

  Future<void> _ask(String text, int cursor) async {
    final id = sessionId();
    if (id == null) return;
    _cancelPending();
    final cancel = _cancel = Completer<void>();
    final seq = ++_seq;
    final window = _window(text, cursor);
    final result = await repositoryOf().complete(
      CompletionRequest(
        sessionId: id,
        context: context,
        text: window.text,
        cursorOffset: cursor - window.start,
        maxItems: maxItems,
        database: database(),
        collection: collection(),
      ),
      cancel: cancel.future,
    );
    if (_disposed || seq != _seq) return;
    if (result.error != null) {
      _cache = null;
      return;
    }
    final rel = cursor - window.start;
    final replaceStart = result.items.isNotEmpty
        ? result.items.first.replaceStart
        : _identifierStart(window.text, rel);
    _cache = _Cache(
      window.start,
      window.text,
      window.start + replaceStart,
      window.text.substring(replaceStart.clamp(0, rel).toInt(), rel),
      result,
    );
    onUpdated?.call();
  }

  /// Suggestions for the current text, or null when the last answer does not
  /// apply and nothing useful can be shown.
  Suggestions? suggest(String text, int cursor) {
    final cache = _cache;
    if (cache == null) return null;
    final window = _window(text, cursor);
    final rs = cache.replaceStart;
    if (window.start != cache.windowStart || cursor < rs || rs < window.start) {
      return null;
    }
    final prefix = text.substring(rs, cursor);
    if (!prefix.startsWith(cache.prefix) || prefix.contains('\n')) return null;
    if (!_extendsWithWordChars(prefix, cache.prefix.length)) return null;
    final rel = rs - window.start;
    if (window.text.length < rel ||
        cache.windowText.length < rel ||
        window.text.substring(0, rel) != cache.windowText.substring(0, rel)) {
      return null;
    }
    final typed = _withoutOpeningQuote(prefix);
    final entries = <Suggestion>[
      ..._snippetEntries(text, rs, prefix),
      for (final item in refilter(cache.result.items, typed))
        if (item.insertText != prefix) _entry(item, text, cursor, window.start),
    ];
    if (entries.isEmpty) return null;
    return Suggestions(
      input: prefix,
      entries: entries.length > maxRows ? entries.sublist(0, maxRows) : entries,
      catalogState: cache.result.catalogState,
    );
  }

  Suggestion _entry(
    CompletionItem item,
    String text,
    int cursor,
    int windowStart,
  ) {
    var insert = item.insertText;
    final replaceEnd = windowStart + item.replaceEnd;
    if (replaceEnd > cursor && replaceEnd <= text.length) {
      final swallowed = text.substring(cursor, replaceEnd);
      if (insert.endsWith(swallowed)) {
        insert = insert.substring(0, insert.length - swallowed.length);
      }
    }
    return Suggestion(
      label: item.label,
      kind: item.kind,
      detail: item.detail,
      insertText: insert,
      caret: insert.length,
    );
  }

  Iterable<Suggestion> _snippetEntries(
    String text,
    int replaceStart,
    String prefix,
  ) {
    if (prefix.isEmpty || (replaceStart > 0 && text[replaceStart - 1] == '.')) {
      return const [];
    }
    final lower = prefix.toLowerCase();
    return [
      for (final s in snippetsOf())
        if (s.appliesTo(context) && s.trigger.toLowerCase().startsWith(lower))
          _snippetEntry(s),
    ];
  }

  Suggestion _snippetEntry(Snippet s) {
    final (body, caret) = s.expand();
    return Suggestion(
      label: s.trigger,
      kind: CompletionKind.snippet,
      detail: s.description,
      insertText: body,
      caret: caret,
    );
  }
}

String _withoutOpeningQuote(String prefix) =>
    prefix.isNotEmpty && '"\'`['.contains(prefix[0])
    ? prefix.substring(1)
    : prefix;

int _identifierStart(String text, int at) {
  var i = at.clamp(0, text.length).toInt();
  while (i > 0 && _isWordChar(text.codeUnitAt(i - 1))) {
    i--;
  }
  return i;
}

bool _isWordChar(int c) =>
    c == 0x5F ||
    c == 0x24 ||
    c >= 0x30 && c <= 0x39 ||
    c >= 0x41 && c <= 0x5A ||
    c >= 0x61 && c <= 0x7A ||
    c >= 0x80;

bool _extendsWithWordChars(String prefix, int from) {
  for (var i = from; i < prefix.length; i++) {
    final c = prefix.codeUnitAt(i);
    if (!(_isWordChar(c) || c == 0x2E || c == 0x2D)) return false;
  }
  return true;
}
