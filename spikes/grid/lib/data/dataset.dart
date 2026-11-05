// Synthetic 1M x 12 result set and two row stores.
//
// Values are a pure function of (row, col), so a "refetch from core" in the
// window store is just regeneration. Strings are freshly allocated per row so
// memory is comparable to rows decoded from a gRPC stream.
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

const int kTotalRows = int.fromEnvironment('ROWS', defaultValue: 1000000);
const int kBatchSize = 500;

const List<String> kColumns = [
  'id',
  'uuid',
  'name',
  'email',
  'qty',
  'price',
  'active',
  'created_at',
  'category',
  'city',
  'note',
  'score',
];

const _cats = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'eta'];
const _cities = ['Kyiv', 'Lviv', 'Berlin', 'Lisbon', 'Austin', 'Osaka', 'Oslo'];
const _first = ['Ada', 'Linus', 'Grace', 'Ken', 'Barbara', 'Dennis', 'Edsger'];

/// One row as the UI would hold it after decoding a batch.
List<Object?> generateRow(int r) {
  final h = (r * 2654435761) & 0xffffffff;
  return <Object?>[
    r,
    '${h.toRadixString(16).padLeft(8, '0')}-${(r & 0xffff).toRadixString(16)}-4a1b',
    '${_first[r % 7]} ${_first[(h >> 3) % 7]}son',
    'user$r@example.com',
    h % 1000,
    (h % 100000) / 100.0,
    h.isEven,
    '2026-${(1 + r % 12).toString().padLeft(2, '0')}-${(1 + r % 28).toString().padLeft(2, '0')} 12:${(r % 60).toString().padLeft(2, '0')}:00',
    _cats[h % 7],
    _cities[(h >> 5) % 7],
    r % 9 == 0 ? null : 'note for row $r',
    ((h % 2000) - 1000) / 10.0,
  ];
}

List<List<Object?>> generateBatch(int start, int count) =>
    List.generate(count, (i) => generateRow(start + i), growable: false);

String formatValue(Object? v) => v == null ? 'NULL' : v.toString();

/// Row storage seen by grids. [rowAt] returns null when the row is not
/// resident (window mode); the store then fetches it and notifies.
abstract class RowStore extends ChangeNotifier {
  int get rowCount;
  bool get done;
  List<Object?>? rowAt(int r);
  void appendBatch(int start, List<List<Object?>> rows);
  void finish();
  int get residentRows;
}

/// Keeps every row (what trina/pluto/syncfusion require by design).
class FullStore extends RowStore {
  final List<List<List<Object?>>> _batches = [];
  int _count = 0;
  bool _done = false;
  @override
  int get rowCount => _count;
  @override
  bool get done => _done;
  @override
  int get residentRows => _count;
  @override
  List<Object?>? rowAt(int r) =>
      r < _count ? _batches[r ~/ kBatchSize][r % kBatchSize] : null;
  @override
  void appendBatch(int start, List<List<Object?>> rows) {
    _batches.add(rows);
    _count += rows.length;
    notifyListeners();
  }

  @override
  void finish() {
    _done = true;
    notifyListeners();
  }
}

/// Keeps at most [maxPages] pages of [kBatchSize] rows (LRU). Missing pages are
/// "fetched" asynchronously, standing in for a core FetchRows(offset, limit) RPC
/// against a server-side spool.
class WindowStore extends RowStore {
  WindowStore({this.maxPages = 40, this.fetchLatency = Duration.zero});
  final int maxPages;
  final Duration fetchLatency;
  final LinkedHashMap<int, List<List<Object?>>> _pages = LinkedHashMap();
  final Set<int> _inflight = {};
  int _count = 0;
  bool _done = false;
  int fetches = 0;

  @override
  int get rowCount => _count;
  @override
  bool get done => _done;
  @override
  int get residentRows => _pages.length * kBatchSize;

  @override
  List<Object?>? rowAt(int r) {
    if (r >= _count) return null;
    final p = r ~/ kBatchSize;
    final page = _pages.remove(p);
    if (page != null) {
      _pages[p] = page; // touch for LRU
      return page[r % kBatchSize];
    }
    _fetch(p);
    return null;
  }

  void _fetch(int p) {
    if (!_inflight.add(p)) return;
    fetches++;
    Timer(fetchLatency, () {
      _inflight.remove(p);
      final start = p * kBatchSize;
      final n = (_count - start).clamp(0, kBatchSize);
      _put(p, generateBatch(start, n));
      notifyListeners();
    });
  }

  void _put(int p, List<List<Object?>> rows) {
    _pages.remove(p);
    _pages[p] = rows;
    while (_pages.length > maxPages) {
      _pages.remove(_pages.keys.first);
    }
  }

  @override
  void appendBatch(int start, List<List<Object?>> rows) {
    // Streamed batches beyond the window are dropped (core keeps them).
    _count += rows.length;
    final p = start ~/ kBatchSize;
    if (_pages.length < maxPages) _put(p, rows);
    notifyListeners();
  }

  @override
  void finish() {
    _done = true;
    notifyListeners();
  }
}

/// Simulates the gRPC server stream: 500-row batches, yielding to the event
/// loop between batches so the UI keeps rendering.
Future<Duration> feed(
  RowStore store, {
  int total = kTotalRows,
  void Function(int start, List<List<Object?>> b)? onBatch,
}) async {
  final sw = Stopwatch()..start();
  for (var start = 0; start < total; start += kBatchSize) {
    final n = (total - start).clamp(0, kBatchSize);
    final batch = generateBatch(start, n);
    store.appendBatch(start, batch);
    onBatch?.call(start, batch);
    await Future<void>.delayed(Duration.zero);
  }
  store.finish();
  return sw.elapsed;
}

/// Counts streamed rows without retaining them; used when the grid package
/// owns its own row models (trina/pluto/syncfusion full mode).
class CountingStore extends RowStore {
  int _count = 0;
  bool _done = false;
  @override
  int get rowCount => _count;
  @override
  bool get done => _done;
  @override
  int get residentRows => 0;
  @override
  List<Object?>? rowAt(int r) => null;
  @override
  void appendBatch(int start, List<List<Object?>> rows) {
    _count += rows.length;
    notifyListeners();
  }

  @override
  void finish() {
    _done = true;
    notifyListeners();
  }
}
