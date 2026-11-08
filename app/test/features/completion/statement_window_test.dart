import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/completion/domain/statement_window.dart';

void main() {
  test('the window is the statement around the cursor', () {
    const doc = 'select 1; select a, b from t; select 3';
    final cursor = doc.indexOf('b from');
    final w = sqlStatementWindow(doc, cursor);
    expect(w.text, ' select a, b from t');
    expect(w.start, 9);
    expect(cursor - w.start, ' select a, '.length);
  });

  test('semicolons in strings, quoted names and comments do not split', () {
    const doc = "select 'a;b', \"c;d\", `e;f` -- x;y\n, /* ;; */ g from t";
    final w = sqlStatementWindow(doc, doc.length);
    expect(w.text, doc);
    expect(w.start, 0);
  });

  test('a cursor right after a semicolon belongs to the next statement', () {
    const doc = 'select 1;select 2';
    final w = sqlStatementWindow(doc, 9);
    expect(w.text, 'select 2');
    expect(w.start, 9);
  });

  test('an unterminated string swallows the rest', () {
    const doc = "select 'abc; select 2";
    expect(sqlStatementWindow(doc, doc.length).text, doc);
  });

  test('long text is cut around the cursor', () {
    final doc = 'x' * 50000;
    final w = plainWindow(doc, 25000);
    expect(w.text.length, 20000);
    expect(w.start, lessThanOrEqualTo(25000));
    expect(w.start + w.text.length, greaterThanOrEqualTo(25000));
  });

  test('offsets are UTF-16 code units', () {
    const doc = "select '😀'; select x";
    final cursor = doc.length;
    final w = sqlStatementWindow(doc, cursor);
    expect(w.text, ' select x');
    expect(w.start, doc.indexOf(';') + 1);
  });
}
