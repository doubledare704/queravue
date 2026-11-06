import 'ejson.dart';

/// Kind of a diff line.
enum DiffKind { same, added, removed }

/// One line of a diff.
class DiffLine {
  const DiffLine(this.kind, this.text);
  final DiffKind kind;
  final String text;

  @override
  String toString() =>
      '${switch (kind) {
        DiffKind.same => ' ',
        DiffKind.added => '+',
        DiffKind.removed => '-',
      }} $text';
}

/// Line diff of the canonical, pretty-printed EJSON of two documents. Because
/// the text is canonical, a type change shows up: `"n": {"$numberInt": "5"}`
/// becomes `"n": {"$numberLong": "5"}`, which a relaxed rendering would hide.
/// Throws [FormatException] if either side is not valid JSON.
List<DiffLine> diffDocuments(String before, String after) =>
    diffLines(prettyEjson(before), prettyEjson(after));

/// Longest-common-subsequence line diff. Equal heads and tails are peeled off
/// first so typical edits (a few changed lines in a big document) stay cheap;
/// pathological inputs fall back to "all removed, all added".
List<DiffLine> diffLines(String before, String after) {
  final a = before.split('\n'), b = after.split('\n');
  var head = 0;
  while (head < a.length && head < b.length && a[head] == b[head]) {
    head++;
  }
  var tail = 0;
  while (tail < a.length - head &&
      tail < b.length - head &&
      a[a.length - 1 - tail] == b[b.length - 1 - tail]) {
    tail++;
  }
  final ma = a.sublist(head, a.length - tail);
  final mb = b.sublist(head, b.length - tail);
  final out = <DiffLine>[
    for (final l in a.take(head)) DiffLine(DiffKind.same, l),
  ];
  const maxCells = 4000000;
  if (ma.length * mb.length > maxCells) {
    out
      ..addAll(ma.map((l) => DiffLine(DiffKind.removed, l)))
      ..addAll(mb.map((l) => DiffLine(DiffKind.added, l)));
  } else {
    // lcs[i][j] = LCS length of ma[i:] and mb[j:]
    final lcs = List.generate(
      ma.length + 1,
      (_) => List.filled(mb.length + 1, 0),
    );
    for (var i = ma.length - 1; i >= 0; i--) {
      for (var j = mb.length - 1; j >= 0; j--) {
        lcs[i][j] = ma[i] == mb[j]
            ? lcs[i + 1][j + 1] + 1
            : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
      }
    }
    var i = 0, j = 0;
    while (i < ma.length && j < mb.length) {
      if (ma[i] == mb[j]) {
        out.add(DiffLine(DiffKind.same, ma[i]));
        i++;
        j++;
      } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        out.add(DiffLine(DiffKind.removed, ma[i++]));
      } else {
        out.add(DiffLine(DiffKind.added, mb[j++]));
      }
    }
    while (i < ma.length) {
      out.add(DiffLine(DiffKind.removed, ma[i++]));
    }
    while (j < mb.length) {
      out.add(DiffLine(DiffKind.added, mb[j++]));
    }
  }
  for (final l in a.skip(a.length - tail)) {
    out.add(DiffLine(DiffKind.same, l));
  }
  return out;
}
