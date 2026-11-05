import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/grid/application/result_window.dart';

import '../../support/fake_query_repository.dart';

const _cfg = ResultWindowConfig(pageSize: 10, maxPages: 4, prefetchPages: 2);

({ProviderContainer container, FakeQueryRepository repo}) setup({
  int total = 1000,
  ResultWindowConfig cfg = _cfg,
}) {
  final repo = FakeQueryRepository(totalRows: total, pageSize: cfg.pageSize);
  final container = ProviderContainer(
    overrides: [
      queryRepositoryProvider.overrideWithValue(repo),
      resultWindowConfigProvider.overrideWithValue(cfg),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, repo: repo);
}

ResultWindow open(ProviderContainer c, {int total = 1000}) {
  const id = 'r1';
  // Keep the provider alive for the test.
  c.listen(resultWindowProvider(id), (_, _) {});
  final w = c.read(resultWindowProvider(id).notifier)
    ..onColumns(fakeColumns)
    ..onProgress(total, done: true);
  return w;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a miss returns null, fetches the page and repaints', () async {
    final s = setup();
    final w = open(s.container);
    final rev = s.container.read(resultWindowProvider('r1')).revision;

    expect(w.rowAt(25), isNull);
    expect(s.repo.fetches, [20]);
    await settle();

    expect(w.rowAt(25)![1], 'row-25');
    expect(
      s.container.read(resultWindowProvider('r1')).revision,
      greaterThan(rev),
    );
  });

  test('concurrent misses on one page fetch it once', () async {
    final s = setup();
    final w = open(s.container);
    s.repo.hold = true;
    for (var r = 30; r < 40; r++) {
      w.rowAt(r);
    }
    expect(s.repo.fetches, [30]);
    s.repo.releaseAll();
    await settle();
    expect(w.rowAt(39), isNotNull);
  });

  test('the first window seeds page 0 without a fetch', () async {
    final s = setup();
    final w = open(s.container, total: 0);
    w.onFirstWindow([for (var r = 0; r < 10; r++) fakeRow(r)]);
    w.onProgress(1000, done: false);
    expect(w.rowAt(7)![0], 7);
    expect(s.repo.fetches, isEmpty);
  });

  test('evicts least recently used pages beyond 4 pages', () async {
    final s = setup();
    final w = open(s.container);
    for (var p = 0; p < 6; p++) {
      w.rowAt(p * 10);
      await settle();
    }
    expect(w.residentPages.length, 4);
    expect(w.residentPages, [2, 3, 4, 5]);
    expect(w.residentRows, 40);
    // Evicted page is fetched again on demand.
    expect(w.rowAt(0), isNull);
    expect(s.repo.fetches.last, 0);
  });

  test('viewport pages are protected and ±2 pages are prefetched', () async {
    final s = setup();
    final w = open(s.container);
    w.setViewport(100, 119); // pages 10 and 11
    await settle();
    expect(s.repo.fetches.toSet(), {80, 90, 100, 110, 120, 130});
    // 6 pages were fetched into a 4-page cache: the on-screen pages stay and
    // the oldest prefetched ones (8, 9) are evicted.
    expect(w.residentPages.toSet(), {10, 11, 12, 13});
  });

  test('prefetch is clamped to the result', () async {
    final s = setup(total: 25);
    final w = open(s.container, total: 25);
    w.setViewport(0, 9);
    await settle();
    expect(s.repo.fetches.toSet(), {0, 10, 20});
    expect(w.rowAt(24), isNotNull);
    expect(w.rowAt(25), isNull, reason: 'past the end');
  });

  test('prefetch skips pages that are already resident', () async {
    final s = setup();
    final w = open(s.container);
    w.setViewport(0, 9);
    await settle();
    s.repo.fetches.clear();
    w.setViewport(0, 9);
    await settle();
    expect(s.repo.fetches, isEmpty);
  });

  test('pages arriving out of order all land', () async {
    final s = setup();
    final w = open(s.container);
    s.repo.hold = true;
    w.rowAt(0);
    w.rowAt(10);
    w.rowAt(20);
    expect(s.repo.heldOffsets, [0, 10, 20]);
    s.repo.release(20);
    await settle();
    s.repo.release(0);
    await settle();
    s.repo.release(10);
    await settle();
    expect(w.residentPages.toSet(), {0, 1, 2});
    for (final r in [3, 14, 25]) {
      expect(w.rowAt(r)![0], r);
    }
  });

  test(
    'a late page for an evicted viewport does not evict the on-screen pages',
    () async {
      final s = setup();
      final w = open(s.container);
      s.repo.hold = true;
      w.setViewport(0, 9); // page 0 on screen; prefetch 1, 2
      s.repo.releaseAll();
      await settle();
      s.repo.hold = false;
      // Scroll far away, filling the cache with other pages.
      for (var p = 30; p < 40; p++) {
        w.rowAt(p * 10);
        await settle();
      }
      expect(w.residentPages.length, lessThanOrEqualTo(4));
      // Now the viewport is back on page 0 and it is protected on arrival.
      w.setViewport(0, 9);
      await settle();
      expect(w.rowAt(5), isNotNull);
    },
  );

  test('a partial page is refetched once more rows are spooled', () async {
    final s = setup(total: 14);
    final w = open(s.container, total: 14);
    s.repo.done = false;
    w.rowAt(12);
    await settle();
    expect(w.rowAt(12), isNotNull);
    expect(w.rowAt(13), isNotNull);

    s.repo.totalRows = 30;
    w.onProgress(30, done: false);
    expect(w.rowAt(15), isNull, reason: 'cached page ends at row 13');
    await settle();
    expect(w.rowAt(15)![0], 15);
    expect(s.repo.fetches, [10, 10]);
  });

  test('rows beyond the spooled count are not fetched', () async {
    final s = setup();
    final w = open(s.container, total: 20);
    expect(w.rowAt(20), isNull);
    expect(w.rowAt(-1), isNull);
    expect(s.repo.fetches, isEmpty);
  });

  test('a fetch failure is surfaced and the page can be retried', () async {
    final repo = _FailingOnce();
    final c = ProviderContainer(
      overrides: [
        queryRepositoryProvider.overrideWithValue(repo),
        resultWindowConfigProvider.overrideWithValue(_cfg),
      ],
    );
    addTearDown(c.dispose);
    final w = open(c);
    w.rowAt(0);
    await settle();
    expect(c.read(resultWindowProvider('r1')).error, isNotNull);
    expect(w.rowAt(0), isNull); // schedules the retry
    await settle();
    expect(w.rowAt(0), isNotNull);
    expect(c.read(resultWindowProvider('r1')).error, isNull);
  });

  test('a fetch that completes after disposal is ignored', () async {
    final s = setup();
    final w = open(s.container);
    s.repo.hold = true;
    w.rowAt(0);
    s.container.invalidate(resultWindowProvider('r1'));
    s.repo.releaseAll();
    await settle(); // must not throw
  });

  test('the window holds at most 40 pages of 500 rows by default', () async {
    final s = setup(cfg: const ResultWindowConfig(), total: 1000000);
    final w = open(s.container, total: 1000000);
    for (var p = 0; p < 60; p++) {
      w.rowAt(p * 500);
      await settle();
    }
    expect(w.residentPages.length, 40);
    expect(w.residentRows, 20000);
  });
}

class _FailingOnce extends FakeQueryRepository {
  _FailingOnce() : super(totalRows: 1000);
  bool failed = false;

  @override
  Future<FetchedRows> fetchRows(String resultId, int offset, int limit) {
    if (!failed) {
      failed = true;
      throw QueryException('boom');
    }
    return super.fetchRows(resultId, offset, limit);
  }
}
