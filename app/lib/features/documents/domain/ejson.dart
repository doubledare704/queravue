import 'dart:convert';

import 'package:flutter/foundation.dart';

/// BSON type of an Extended JSON value, for badges and shell-style text
/// (ADR 0009). Values are the decoded canonical EJSON: wrapper objects such as
/// `{"$numberLong": "5"}` are kept as maps and never coerced to Dart numbers,
/// so an Int64 cannot silently become a double.
enum EjsonType {
  nullValue('Null'),
  boolean('Bool'),
  string('String'),
  object('Object'),
  array('Array'),
  int32('Int32'),
  int64('Int64'),
  double_('Double'),
  decimal128('Decimal128'),
  objectId('ObjectId'),
  date('Date'),
  binary('Binary'),
  uuid('UUID'),
  timestamp('Timestamp'),
  regex('Regex'),
  minKey('MinKey'),
  maxKey('MaxKey'),
  undefined('Undefined'),
  javascript('Code'),
  symbol('Symbol'),
  dbPointer('DBPointer');

  const EjsonType(this.label);

  /// Short name shown in type badges.
  final String label;

  /// Whether the type is a container.
  bool get isContainer => this == object || this == array;
}

/// Wrapper keys that make a one-key object a typed scalar.
const _wrapperTypes = <String, EjsonType>{
  r'$oid': EjsonType.objectId,
  r'$numberInt': EjsonType.int32,
  r'$numberLong': EjsonType.int64,
  r'$numberDouble': EjsonType.double_,
  r'$numberDecimal': EjsonType.decimal128,
  r'$date': EjsonType.date,
  r'$binary': EjsonType.binary,
  r'$timestamp': EjsonType.timestamp,
  r'$regularExpression': EjsonType.regex,
  r'$minKey': EjsonType.minKey,
  r'$maxKey': EjsonType.maxKey,
  r'$undefined': EjsonType.undefined,
  r'$symbol': EjsonType.symbol,
  r'$dbPointer': EjsonType.dbPointer,
  r'$code': EjsonType.javascript,
};

/// The BSON type of decoded EJSON [v].
EjsonType ejsonTypeOf(Object? v) {
  switch (v) {
    case null:
      return EjsonType.nullValue;
    case bool():
      return EjsonType.boolean;
    case String():
      return EjsonType.string;
    case int():
      return EjsonType.int32; // bare numbers only appear in relaxed input
    case double():
      return EjsonType.double_;
    case List():
      return EjsonType.array;
    case Map():
      if (v.length == 1) {
        final t = _wrapperTypes[v.keys.first];
        if (t == EjsonType.binary) {
          return _binaryType(v.values.first);
        }
        if (t != null) {
          return t;
        }
      } else if (v.length == 2 && v.containsKey(r'$code')) {
        return EjsonType.javascript;
      }
      return EjsonType.object;
  }
  return EjsonType.object;
}

EjsonType _binaryType(Object? body) {
  if (body is Map && body['subType'] == '04') return EjsonType.uuid;
  return EjsonType.binary;
}

/// Decodes canonical EJSON text. Throws [FormatException] on bad syntax.
Object? decodeEjson(String text) => jsonDecode(text);

/// Pretty-prints canonical EJSON (2-space indent) without changing any value.
/// Every number in canonical EJSON sits inside a string wrapper, so this
/// round trip is lossless.
String prettyEjson(String text) =>
    const JsonEncoder.withIndent('  ').convert(jsonDecode(text));

/// Single-line canonical EJSON of a decoded value.
String compactEjson(Object? v) => jsonEncode(v);

/// Shell-style text of a scalar (or a short summary of a container).
String shellScalar(Object? v) {
  switch (ejsonTypeOf(v)) {
    case EjsonType.nullValue:
      return 'null';
    case EjsonType.boolean:
      return '$v';
    case EjsonType.string:
      return jsonEncode(v);
    case EjsonType.int32:
      return v is Map ? '${v[r'$numberInt']}' : '$v';
    case EjsonType.int64:
      return 'NumberLong("${(v as Map)[r'$numberLong']}")';
    case EjsonType.double_:
      return v is Map ? '${v[r'$numberDouble']}' : '$v';
    case EjsonType.decimal128:
      return 'NumberDecimal("${(v as Map)[r'$numberDecimal']}")';
    case EjsonType.objectId:
      return 'ObjectId("${(v as Map)[r'$oid']}")';
    case EjsonType.date:
      return _dateText((v as Map)[r'$date']);
    case EjsonType.uuid:
      return 'UUID("${_uuidText((((v as Map)[r'$binary']) as Map)['base64'] as String)}")';
    case EjsonType.binary:
      final b = (v as Map)[r'$binary'];
      if (b is Map) {
        return 'BinData(${int.tryParse('${b['subType']}', radix: 16) ?? 0}, "${b['base64']}")';
      }
      return 'BinData(0, "$b")';
    case EjsonType.timestamp:
      final t = (v as Map)[r'$timestamp'];
      return t is Map ? 'Timestamp(${t['t']}, ${t['i']})' : 'Timestamp()';
    case EjsonType.regex:
      final r = (v as Map)[r'$regularExpression'];
      return r is Map ? '/${r['pattern']}/${r['options']}' : '/?/';
    case EjsonType.minKey:
      return 'MinKey()';
    case EjsonType.maxKey:
      return 'MaxKey()';
    case EjsonType.undefined:
      return 'undefined';
    case EjsonType.javascript:
      final c = v is Map ? v[r'$code'] : '';
      return 'Code(${jsonEncode(c)})';
    case EjsonType.symbol:
      return 'Symbol(${jsonEncode((v as Map)[r'$symbol'])})';
    case EjsonType.dbPointer:
      return 'DBPointer(…)';
    case EjsonType.object:
      return '{…${(v as Map).length}}';
    case EjsonType.array:
      return '[…${(v as List).length}]';
  }
}

String _dateText(Object? d) {
  Object? ms = d;
  if (d is Map) ms = d[r'$numberLong'];
  if (ms is String && int.tryParse(ms) == null) return 'ISODate("$ms")';
  final n = ms is int ? ms : int.tryParse('$ms');
  if (n == null) return 'ISODate("?")';
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
    return 'ISODate("${dt.toIso8601String()}")';
  } on Object {
    return 'new Date($n)';
  }
}

String _uuidText(String base64) {
  try {
    final bytes = base64Decode(base64);
    final h = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
        .join();
    if (h.length != 32) return h;
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  } on FormatException {
    return base64;
  }
}

/// Shell-style, single-line text of any value, cut at [maxChars].
String shellCompact(Object? v, {int maxChars = 160}) {
  final b = StringBuffer();
  _write(b, v, maxChars: maxChars);
  final s = b.toString();
  return s.length > maxChars ? '${s.substring(0, maxChars)}…' : s;
}

void _write(StringBuffer b, Object? v, {required int maxChars}) {
  if (b.length > maxChars) return;
  final t = ejsonTypeOf(v);
  if (t == EjsonType.object && v is Map) {
    b.write('{');
    var first = true;
    for (final e in v.entries) {
      if (b.length > maxChars) break;
      if (!first) b.write(', ');
      first = false;
      b
        ..write(e.key)
        ..write(': ');
      _write(b, e.value, maxChars: maxChars);
    }
    b.write('}');
  } else if (t == EjsonType.array && v is List) {
    b.write('[');
    for (var i = 0; i < v.length && b.length <= maxChars; i++) {
      if (i > 0) b.write(', ');
      _write(b, v[i], maxChars: maxChars);
    }
    b.write(']');
  } else {
    b.write(shellScalar(v));
  }
}

/// Shell-style pretty text of a whole document (2-space indent).
String shellPretty(Object? v, {int indent = 0}) {
  final pad = '  ' * indent;
  final t = ejsonTypeOf(v);
  if (t == EjsonType.object && v is Map) {
    if (v.isEmpty) return '{}';
    final inner = [
      for (final e in v.entries)
        '$pad  ${e.key}: ${shellPretty(e.value, indent: indent + 1)}',
    ];
    return '{\n${inner.join(',\n')}\n$pad}';
  }
  if (t == EjsonType.array && v is List) {
    if (v.isEmpty) return '[]';
    final inner = [
      for (final e in v) '$pad  ${shellPretty(e, indent: indent + 1)}',
    ];
    return '[\n${inner.join(',\n')}\n$pad]';
  }
  return shellScalar(v);
}

/// One visible row of the tree view.
@immutable
class TreeRow {
  const TreeRow({
    required this.path,
    required this.depth,
    required this.label,
    required this.value,
    required this.type,
    required this.expandable,
    required this.expanded,
    this.more = 0,
  });

  /// Unique path, e.g. `3/address/geo`; the first segment is the document
  /// index in the page.
  final String path;
  final int depth;
  final String label;
  final Object? value;
  final EjsonType type;
  final bool expandable;
  final bool expanded;

  /// For a placeholder row: how many children are not shown.
  final int more;
}

/// Most children shown per container; the rest collapse into a "more" row.
const int kTreeMaxChildren = 500;

/// Flattens [docs] into the rows visible given the [expanded] paths, so the
/// view only builds widgets for rows on screen and only expanded nodes cost
/// anything.
List<TreeRow> flattenTree(List<Object?> docs, Set<String> expanded) {
  final out = <TreeRow>[];
  void walk(String path, int depth, String label, Object? v) {
    final t = ejsonTypeOf(v);
    final container = t.isContainer;
    final open = container && expanded.contains(path);
    out.add(
      TreeRow(
        path: path,
        depth: depth,
        label: label,
        value: v,
        type: t,
        expandable:
            container && (v is Map ? v.isNotEmpty : (v as List).isNotEmpty),
        expanded: open,
      ),
    );
    if (!open) return;
    if (v is Map) {
      var i = 0;
      for (final e in v.entries) {
        if (i++ >= kTreeMaxChildren) {
          out.add(_more(path, depth + 1, v.length - kTreeMaxChildren));
          break;
        }
        walk('$path/${e.key}', depth + 1, '${e.key}', e.value);
      }
    } else if (v is List) {
      for (var i = 0; i < v.length; i++) {
        if (i >= kTreeMaxChildren) {
          out.add(_more(path, depth + 1, v.length - kTreeMaxChildren));
          break;
        }
        walk('$path/$i', depth + 1, '[$i]', v[i]);
      }
    }
  }

  for (var i = 0; i < docs.length; i++) {
    walk('$i', 0, _docLabel(i, docs[i]), docs[i]);
  }
  return out;
}

TreeRow _more(String path, int depth, int n) => TreeRow(
  path: '$path/…',
  depth: depth,
  label: '… $n more',
  value: null,
  type: EjsonType.nullValue,
  expandable: false,
  expanded: false,
  more: n,
);

String _docLabel(int i, Object? doc) {
  if (doc is Map && doc.containsKey('_id')) return shellScalar(doc['_id']);
  return '(document ${i + 1})';
}
