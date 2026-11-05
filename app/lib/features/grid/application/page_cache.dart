import 'dart:collection';

import '../../editor/domain/query_models.dart';

/// A bounded LRU cache of fixed-size row pages. Plain Dart: no Flutter, no
/// Riverpod, so it is trivial to test.
class PageCache {
  PageCache({this.pageSize = 500, this.maxPages = 40})
    : assert(pageSize > 0 && maxPages > 0);

  final int pageSize;
  final int maxPages;

  // Insertion order is recency order: the first key is the least recent.
  final LinkedHashMap<int, List<ResultRow>> _pages = LinkedHashMap();

  /// Number of resident pages.
  int get length => _pages.length;

  /// Resident page indexes, least recently used first.
  List<int> get pageIndexes => _pages.keys.toList(growable: false);

  /// Rows held (a partial page counts what it holds).
  int get residentRows => _pages.values.fold(0, (n, p) => n + p.length);

  /// Returns page [p] and marks it recently used.
  List<ResultRow>? page(int p) {
    final rows = _pages.remove(p);
    if (rows != null) _pages[p] = rows;
    return rows;
  }

  /// Whether page [p] is resident, without touching recency.
  bool has(int p) => _pages.containsKey(p);

  /// Length of resident page [p], or 0.
  int lengthOf(int p) => _pages[p]?.length ?? 0;

  /// Row [r], or null if its page is missing or does not reach [r].
  ResultRow? rowAt(int r) {
    final rows = page(r ~/ pageSize);
    final i = r % pageSize;
    return rows != null && i < rows.length ? rows[i] : null;
  }

  /// Stores page [p] and evicts least recently used pages beyond [maxPages],
  /// skipping pages in [protect] (the pages on screen).
  void put(int p, List<ResultRow> rows, {Set<int> protect = const {}}) {
    _pages.remove(p);
    _pages[p] = rows;
    if (_pages.length <= maxPages) return;
    final victims = <int>[];
    var excess = _pages.length - maxPages;
    for (final k in _pages.keys) {
      if (excess == 0) break;
      if (k == p || protect.contains(k)) continue;
      victims.add(k);
      excess--;
    }
    victims.forEach(_pages.remove);
  }

  void clear() => _pages.clear();
}
