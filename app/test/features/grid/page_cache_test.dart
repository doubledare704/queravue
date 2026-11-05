import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/grid/application/page_cache.dart';

import '../../support/fake_query_repository.dart';

List<List<Object?>> page(int p, [int n = 4]) => [
  for (var i = 0; i < n; i++) fakeRow(p * 4 + i),
];

void main() {
  test('stores pages and reads rows by index', () {
    final c = PageCache(pageSize: 4, maxPages: 3)..put(1, page(1));
    expect(c.rowAt(5)![0], 5);
    expect(c.rowAt(0), isNull, reason: 'page 0 is not resident');
    expect(c.has(1), isTrue);
  });

  test('evicts the least recently used page beyond maxPages', () {
    final c = PageCache(pageSize: 4, maxPages: 3);
    for (var p = 0; p < 3; p++) {
      c.put(p, page(p));
    }
    c.rowAt(0); // touch page 0: page 1 is now the oldest
    c.put(3, page(3));
    expect(c.pageIndexes, [2, 0, 3]);
    expect(c.length, 3);
  });

  test('never evicts protected pages, even when they are the oldest', () {
    final c = PageCache(pageSize: 4, maxPages: 3);
    for (var p = 0; p < 3; p++) {
      c.put(p, page(p));
    }
    c.put(3, page(3), protect: {0, 1});
    expect(c.has(0), isTrue);
    expect(c.has(1), isTrue);
    expect(c.has(2), isFalse);
    expect(c.length, 3);
  });

  test('may exceed maxPages if every page is protected', () {
    final c = PageCache(pageSize: 4, maxPages: 2);
    c.put(0, page(0), protect: {0, 1, 2});
    c.put(1, page(1), protect: {0, 1, 2});
    c.put(2, page(2), protect: {0, 1, 2});
    expect(c.length, 3);
  });

  test('a partial page serves only the rows it holds', () {
    final c = PageCache(pageSize: 4, maxPages: 3)..put(0, page(0, 2));
    expect(c.rowAt(1), isNotNull);
    expect(c.rowAt(2), isNull);
    expect(c.lengthOf(0), 2);
    expect(c.residentRows, 2);
  });

  test('replacing a page keeps one entry', () {
    final c = PageCache(pageSize: 4, maxPages: 3)
      ..put(0, page(0, 2))
      ..put(0, page(0));
    expect(c.length, 1);
    expect(c.lengthOf(0), 4);
  });
}
