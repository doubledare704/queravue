import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/domain/doc_diff.dart';
import 'package:queravue/features/documents/domain/ejson.dart';
import 'package:queravue/features/documents/domain/models.dart';

void main() {
  group('ejsonTypeOf', () {
    final cases = <String, EjsonType>{
      'null': EjsonType.nullValue,
      'true': EjsonType.boolean,
      '"x"': EjsonType.string,
      '{"\$numberInt":"1"}': EjsonType.int32,
      '{"\$numberLong":"1"}': EjsonType.int64,
      '{"\$numberDouble":"1.5"}': EjsonType.double_,
      '{"\$numberDecimal":"1.5"}': EjsonType.decimal128,
      '{"\$oid":"650000000000000000000001"}': EjsonType.objectId,
      '{"\$date":{"\$numberLong":"0"}}': EjsonType.date,
      '{"\$binary":{"base64":"aGk=","subType":"00"}}': EjsonType.binary,
      '{"\$binary":{"base64":"aGk=","subType":"04"}}': EjsonType.uuid,
      '{"\$timestamp":{"t":1,"i":2}}': EjsonType.timestamp,
      '{"\$regularExpression":{"pattern":"a","options":"i"}}': EjsonType.regex,
      '{"\$minKey":1}': EjsonType.minKey,
      '{"\$maxKey":1}': EjsonType.maxKey,
      '{"a":1}': EjsonType.object,
      '[1]': EjsonType.array,
      '{}': EjsonType.object,
    };
    cases.forEach((text, want) {
      test(
        '$text -> $want',
        () => expect(ejsonTypeOf(decodeEjson(text)), want),
      );
    });
  });

  group('shell text', () {
    test('typed scalars', () {
      String s(String t) => shellScalar(decodeEjson(t));
      expect(s('{"\$numberInt":"7"}'), '7');
      expect(
        s('{"\$numberLong":"9007199254740993"}'),
        'NumberLong("9007199254740993")',
      );
      expect(s('{"\$numberDecimal":"1.50"}'), 'NumberDecimal("1.50")');
      expect(
        s('{"\$oid":"650000000000000000000001"}'),
        'ObjectId("650000000000000000000001")',
      );
      expect(
        s('{"\$date":{"\$numberLong":"1700000000000"}}'),
        'ISODate("2023-11-14T22:13:20.000Z")',
      );
      expect(
        s('{"\$binary":{"base64":"D4+tW9nLRp+hZXCGdyiVDg==","subType":"04"}}'),
        'UUID("0f8fad5b-d9cb-469f-a165-70867728950e")',
      );
      expect(
        s('{"\$binary":{"base64":"aGk=","subType":"80"}}'),
        'BinData(128, "aGk=")',
      );
      expect(s('{"\$timestamp":{"t":5,"i":2}}'), 'Timestamp(5, 2)');
      expect(
        s('{"\$regularExpression":{"pattern":"^a","options":"i"}}'),
        '/^a/i',
      );
      expect(s('"héllo"'), '"héllo"');
    });

    test('an Int64 and a Double stay distinguishable', () {
      final doc = decodeEjson(
        '{"a":{"\$numberLong":"5"},"b":{"\$numberDouble":"5.0"},"c":{"\$numberInt":"5"}}',
      ) as Map;
      expect(shellScalar(doc['a']), 'NumberLong("5")');
      expect(shellScalar(doc['b']), '5.0');
      expect(shellScalar(doc['c']), '5');
      expect(ejsonTypeOf(doc['a']), isNot(ejsonTypeOf(doc['b'])));
    });

    test('compact and pretty render nested values', () {
      final doc = decodeEjson(
        '{"_id":{"\$numberInt":"1"},"tags":["a","b"],"geo":{"lat":{"\$numberDouble":"1.5"}}}',
      );
      expect(shellCompact(doc), '{_id: 1, tags: ["a", "b"], geo: {lat: 1.5}}');
      expect(shellCompact(doc, maxChars: 10).endsWith('…'), isTrue);
      expect(shellPretty(doc), contains('  tags: [\n    "a",\n    "b"\n  ]'));
    });
  });

  test('prettyEjson changes layout only, never values', () {
    const text =
        '{"n":{"\$numberLong":"9007199254740993"},"d":{"\$numberDecimal":"0.10"}}';
    final pretty = prettyEjson(text);
    expect(pretty, contains('\n'));
    expect(decodeEjson(pretty), decodeEjson(text));
    expect(pretty, contains('"9007199254740993"'));
  });

  group('flattenTree', () {
    final docs = [
      decodeEjson(
        '{"_id":{"\$numberInt":"1"},"a":{"b":[{"\$numberInt":"1"},2]},"s":"x"}',
      ),
      decodeEjson('{"_id":"k"}'),
    ];

    test('collapsed shows only documents', () {
      final rows = flattenTree(docs, {});
      expect(rows.map((r) => r.path), ['0', '1']);
      expect(rows.first.expandable, isTrue);
      expect(rows.first.label, '1');
    });

    test('expanding builds only that branch', () {
      final rows = flattenTree(docs, {'0', '0/a', '0/a/b'});
      expect(rows.map((r) => r.path), [
        '0',
        '0/_id',
        '0/a',
        '0/a/b',
        '0/a/b/0',
        '0/a/b/1',
        '0/s',
        '1',
      ]);
      expect(rows.firstWhere((r) => r.path == '0/_id').type, EjsonType.int32);
      expect(rows.firstWhere((r) => r.path == '0/a/b').depth, 2);
    });

    test('very wide containers collapse into a "more" row', () {
      final big = {for (var i = 0; i < kTreeMaxChildren + 25; i++) 'k$i': 'v'};
      final rows = flattenTree([big], {'0'});
      expect(rows.length, 1 + kTreeMaxChildren + 1);
      expect(rows.last.more, 25);
    });
  });

  group('DocItem', () {
    test('keeps the text verbatim and extracts _id', () {
      final d = DocItem('{"_id":{"\$oid":"650000000000000000000001"},"x":1}');
      expect(d.idText, '{"\$oid":"650000000000000000000001"}');
      expect(d.text, contains('"x":1'));
      expect(DocItem('{"x":1}').idText, isNull);
      expect(DocItem('not json').value, isNull);
    });
  });

  group('diff', () {
    test('a type change is a visible change', () {
      final d = diffDocuments(
        '{"_id":{"\$numberInt":"1"},"n":{"\$numberInt":"5"}}',
        '{"_id":{"\$numberInt":"1"},"n":{"\$numberLong":"5"}}',
      );
      final changed = d.where((l) => l.kind != DiffKind.same).toList();
      expect(changed.length, 2);
      expect(changed[0].kind, DiffKind.removed);
      expect(changed[0].text, contains('numberInt'));
      expect(changed[1].kind, DiffKind.added);
      expect(changed[1].text, contains('numberLong'));
    });

    test('identical documents have no changes', () {
      const t = '{"a":"b"}';
      expect(diffDocuments(t, t).every((l) => l.kind == DiffKind.same), isTrue);
    });

    test('added and removed fields', () {
      final d = diffDocuments('{"a":"1","b":"2"}', '{"a":"1","c":"3"}');
      expect(
        d.where((l) => l.kind == DiffKind.removed).single.text,
        contains('"b"'),
      );
      expect(
        d.where((l) => l.kind == DiffKind.added).single.text,
        contains('"c"'),
      );
    });

    test('line diff keeps order and context', () {
      final d = diffLines('a\nb\nc\nd', 'a\nx\nc\nd');
      expect(d.map((l) => l.toString()).toList(), [
        '  a',
        '- b',
        '+ x',
        '  c',
        '  d',
      ]);
    });
  });
}
