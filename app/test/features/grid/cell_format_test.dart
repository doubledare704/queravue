import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/grid/application/copy_service.dart';
import 'package:queravue/features/grid/domain/cell_format.dart';
import 'package:queravue/features/grid/domain/selection.dart';
import 'package:queravue/features/grid/presentation/value_viewer.dart';

void main() {
  group('formatCell', () {
    test('renders each value type', () {
      expect(formatCell(null), 'NULL');
      expect(formatCell(null, forCopy: true), '');
      expect(formatCell(true), 'true');
      expect(formatCell(-7), '-7');
      expect(formatCell(1.5), '1.5');
      expect(formatCell(double.nan), 'NaN');
      expect(formatCell(double.negativeInfinity), '-Infinity');
      expect(formatCell('héllo 😀'), 'héllo 😀');
      expect(formatCell(Uint8List.fromList([0xde, 0xad, 1])), r'\xdead01');
      expect(
        formatCell(DateTime.utc(2024, 1, 2, 3, 4, 5)),
        '2024-01-02 03:04:05+00',
      );
      expect(
        formatCell(DateTime.utc(2024, 1, 2, 3, 4, 5, 123, 456)),
        '2024-01-02 03:04:05.123456+00',
      );
      expect(
        formatCell([
          1,
          null,
          'a"b',
          [2],
        ]),
        '[1,null,"a\\"b",[2]]',
      );
    });
  });

  group('cellPreview', () {
    test('collapses newlines and tabs to one line', () {
      expect(cellPreview('a\nb\r\nc\td'), 'a b c d');
    });

    test('cuts long values and never splits a surrogate pair', () {
      final long = '${'x' * 199}😀tail';
      final p = cellPreview(long);
      expect(p.endsWith('…'), isTrue);
      expect(p.length, lessThanOrEqualTo(kCellPreviewChars + 1));
      // The emoji straddles the cut: it is dropped whole, not halved.
      expect(p.runes.every((r) => r != 0xFFFD), isTrue);
      expect(p, '${'x' * 199}…');
    });

    test('NULL is NULL', () => expect(cellPreview(null), 'NULL'));

    test('flags values the cell cannot show in full', () {
      expect(isTruncatedInCell('short'), isFalse);
      expect(isTruncatedInCell('two\nlines'), isTrue);
      expect(isTruncatedInCell('y' * 500), isTrue);
      expect(isTruncatedInCell(null), isFalse);
    });
  });

  group('viewerText', () {
    test('pretty-prints JSON columns and JSON-looking text', () {
      expect(
        viewerText('{"a":[1,2]}', ColumnKind.json),
        contains('\n  "a": [\n    1,'),
      );
      expect(viewerText('[1]', ColumnKind.text), '[\n  1\n]');
      expect(viewerText('{not json', ColumnKind.json), '{not json');
      expect(viewerText('plain', ColumnKind.text), 'plain');
    });
  });

  group('delimited formats', () {
    final rows = <ResultRow>[
      [1, 'plain', null],
      [2, 'a\tb, "c"\nd', 3.5],
    ];
    const cols = [
      ResultColumn(name: 'id'),
      ResultColumn(name: 'note'),
      ResultColumn(name: 'x,y'),
    ];

    test('TSV matches the core: NULL empty, quote only when needed', () {
      expect(
        formatDelimited(rows, [0, 1, 2], format: CopyFormat.tsv),
        '1\tplain\t\n2\t"a\tb, ""c""\nd"\t3.5\n',
      );
    });

    test('CSV with header and a column subset in the given order', () {
      expect(
        formatDelimited(rows, [1, 0], format: CopyFormat.csv, header: cols),
        'note,id\nplain,1\n"a\tb, ""c""\nd",2\n',
      );
      expect(
        formatDelimited(rows, [2], format: CopyFormat.csv, header: cols),
        '"x,y"\n\n3.5\n',
      );
    });
  });

  group('GridSelection', () {
    test('normalises the rectangle whichever way it was dragged', () {
      const s = GridSelection(
        anchorRow: 9,
        anchorCol: 4,
        focusRow: 2,
        focusCol: 1,
      );
      expect((s.top, s.bottom, s.left, s.right), (2, 9, 1, 4));
      expect(s.rowCount, 8);
      expect(s.colCount, 4);
      expect(s.cellCount, 32);
      expect(s.contains(5, 2), isTrue);
      expect(s.contains(1, 2), isFalse);
      expect(s.contains(5, 5), isFalse);
    });

    test('moveFocus clamps, and collapses unless extending', () {
      const s = GridSelection.cell(3, 3);
      expect(
        s.moveFocus(-5, 99, extend: false, rows: 10, cols: 4),
        const GridSelection.cell(0, 3),
      );
      final ext = s.moveFocus(8, 0, extend: true, rows: 10, cols: 4);
      expect(
        (ext.anchorRow, ext.anchorCol, ext.focusRow, ext.focusCol),
        (3, 3, 8, 0),
      );
    });

    test('rows, column and all', () {
      const s = GridSelection.cell(2, 1);
      expect(
        s.rows(5, extend: false, cols: 3),
        const GridSelection(
          anchorRow: 5,
          anchorCol: 0,
          focusRow: 5,
          focusCol: 2,
        ),
      );
      expect(s.rows(5, extend: true, cols: 3).anchorRow, 2);
      expect(s.column(1, rows: 100).cellCount, 100);
      expect(const GridSelection.all(7, 3).cellCount, 21);
      expect(const GridSelection.all(0, 0).cellCount, 1);
    });
  });
}
