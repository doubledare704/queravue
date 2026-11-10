import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/command_palette/domain/palette_search.dart';

PaletteItem item(String title, PaletteGroup group) =>
    PaletteItem(id: title, title: title, group: group, run: (_, _) async {});

void main() {
  test('prefixes pick the source', () {
    expect(parsePaletteQuery('>run').mode, PaletteMode.actions);
    expect(parsePaletteQuery('@ users').mode, PaletteMode.objects);
    expect(parsePaletteQuery('#acc').mode, PaletteMode.files);
    expect(parsePaletteQuery(':q').mode, PaletteMode.tabs);
    expect(parsePaletteQuery('#acc').text, 'acc');
    expect(parsePaletteQuery('@ users').text, 'users');
    expect(parsePaletteQuery('plain').mode, PaletteMode.all);
    expect(parsePaletteQuery('').mode, PaletteMode.all);
  });

  test('a prefix beats a word start beats a subsequence', () {
    final prefix = fuzzyScore('new', 'New connection')!;
    final word = fuzzyScore('con', 'New connection')!;
    final inside = fuzzyScore('onn', 'New connection')!;
    final gaps = fuzzyScore('ncn', 'New connection')!;
    expect(prefix, greaterThan(word));
    expect(word, greaterThan(inside));
    expect(inside, greaterThan(gaps));
    expect(fuzzyScore('xyz', 'New connection'), isNull);
    expect(fuzzyScore('', 'anything'), 0);
  });

  test('ranking puts the best title first and keeps groups for ties', () {
    final ranked = rankPaletteItems([
      item('Open workspace file', PaletteGroup.action),
      item('orders', PaletteGroup.object),
      item('orders', PaletteGroup.tab),
      item('Tabs of orders', PaletteGroup.tab),
    ], 'ord');
    expect(ranked.map((i) => i.group), [
      PaletteGroup.tab,
      PaletteGroup.object,
      PaletteGroup.tab,
    ]);
    expect(ranked.first.title, 'orders');
  });

  test('ranking caps the list', () {
    final many = [
      for (var i = 0; i < 100; i++) item('item $i', PaletteGroup.object),
    ];
    expect(rankPaletteItems(many, 'item', limit: 10), hasLength(10));
  });

  test('disabled items rank after enabled ones whatever their score', () {
    final ranked = rankPaletteItems([
      PaletteItem(
        id: 'off',
        title: 'Run',
        group: PaletteGroup.action,
        enabled: false,
        run: (_, _) async {},
      ),
      item('Rerun last', PaletteGroup.action),
    ], 'run');
    expect(ranked.map((i) => i.id), ['Rerun last', 'off']);
  });
}
