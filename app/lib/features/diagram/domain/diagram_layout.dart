import 'dart:math' as math;
import 'dart:ui';

import 'diagram_models.dart';

const tableHeaderHeight = 30.0;
const tableRowHeight = 20.0;
const tableMinWidth = 150.0;
const tableMaxWidth = 320.0;
const maxRowsShown = 24;

const _charWidth = 7.0;
const _textPadding = 44.0;
const _columnGap = 96.0;
const _rowGap = 28.0;
const _nameTypeGap = 3;

/// Rows a table box shows: its columns, cut at [maxRowsShown] with one more
/// row that says how many are left out.
int shownRowCount(DiagramTable table) =>
    math.min(table.columns.length, maxRowsShown) +
    (hiddenColumnCount(table) > 0 ? 1 : 0);

int hiddenColumnCount(DiagramTable table) =>
    math.max(0, table.columns.length - maxRowsShown) +
    (table.columnsTruncated && table.columns.length <= maxRowsShown ? 1 : 0);

/// Box size from the text lengths, so no text is measured during layout.
Size tableSize(DiagramTable table) {
  var chars = table.name.length + 2;
  for (final c in table.columns.take(maxRowsShown)) {
    chars = math.max(chars, c.name.length + _nameTypeGap + c.typeName.length);
  }
  return Size(
    (chars * _charWidth + _textPadding).clamp(tableMinWidth, tableMaxWidth),
    tableHeaderHeight + shownRowCount(table) * tableRowHeight + 6,
  );
}

class DiagramLayout {
  const DiagramLayout(this.rects);

  /// Box of every table, by table name, in diagram coordinates.
  final Map<String, Rect> rects;

  Rect get bounds {
    if (rects.isEmpty) return Rect.zero;
    return rects.values.reduce((a, b) => a.expandToInclude(b));
  }
}

/// Lays tables out left to right by reference depth: a table sits to the
/// right of every table it references. A rank with many tables is split into
/// several columns, and tables without relations form a block at the end.
/// The result depends only on the graph, not on map iteration order.
DiagramLayout layoutGraph(SchemaGraph graph) {
  final tables = graph.tables;
  if (tables.isEmpty) return const DiagramLayout({});
  final index = {for (var i = 0; i < tables.length; i++) tables[i].name: i};
  final references = List.generate(tables.length, (_) => <int>{});
  final referencedBy = List.generate(tables.length, (_) => <int>{});
  for (var i = 0; i < tables.length; i++) {
    for (final r in tables[i].relations) {
      final target = index[r.referencedTable];
      if (target == null || target == i) continue;
      references[i].add(target);
      referencedBy[target].add(i);
    }
  }

  final rank = _ranks(references);
  final connected = <int>[];
  final lonely = <int>[];
  for (var i = 0; i < tables.length; i++) {
    (references[i].isEmpty && referencedBy[i].isEmpty ? lonely : connected).add(
      i,
    );
  }

  final sizes = [for (final t in tables) tableSize(t)];
  final perColumn = _tablesPerColumn(sizes);
  final columns = <List<int>>[];
  final slot = List<double>.filled(tables.length, 0);
  final maxRank = connected.fold(0, (m, i) => math.max(m, rank[i]));
  for (var r = 0; r <= maxRank; r++) {
    final members = [
      for (final i in connected)
        if (rank[i] == r) i,
    ];
    // Keep tables near the ones they reference, placed one rank earlier.
    double anchor(int i) {
      final placed = references[i].where((t) => rank[t] < r);
      if (placed.isEmpty) return 0;
      return placed.fold(0.0, (sum, t) => sum + slot[t]) / placed.length;
    }

    final anchors = {for (final i in members) i: anchor(i)};
    members.sort((a, b) {
      final byAnchor = anchors[a]!.compareTo(anchors[b]!);
      return byAnchor != 0
          ? byAnchor
          : tables[a].name.compareTo(tables[b].name);
    });
    for (final column in _evenColumns(members, perColumn)) {
      for (var k = 0; k < column.length; k++) {
        slot[column[k]] = k.toDouble();
      }
      columns.add(column);
    }
  }
  lonely.sort((a, b) => tables[a].name.compareTo(tables[b].name));
  columns.addAll(_evenColumns(lonely, perColumn));

  double heightOf(List<int> column) =>
      column.fold(0.0, (h, i) => h + sizes[i].height) +
      _rowGap * (column.length - 1);
  final tallest = columns.fold(0.0, (m, c) => math.max(m, heightOf(c)));

  final rects = <String, Rect>{};
  var x = 0.0;
  for (final column in columns) {
    final width = column.fold(0.0, (m, i) => math.max(m, sizes[i].width));
    var y = (tallest - heightOf(column)) / 2;
    for (final i in column) {
      rects[tables[i].name] = Rect.fromLTWH(
        x,
        y,
        sizes[i].width,
        sizes[i].height,
      );
      y += sizes[i].height + _rowGap;
    }
    x += width + _columnGap;
  }
  return DiagramLayout(rects);
}

/// Splits [members] into columns of about [perColumn], all the same height
/// but the last, so no column is left with one or two stragglers.
List<List<int>> _evenColumns(List<int> members, int perColumn) {
  if (members.isEmpty) return const [];
  final count = math.max(1, (members.length / perColumn).round());
  final each = (members.length / count).ceil();
  return [
    for (var start = 0; start < members.length; start += each)
      members.sublist(start, math.min(start + each, members.length)),
  ];
}

/// How many tables to stack so that the whole diagram is about as wide as a
/// window is, whatever the size of the tables.
int _tablesPerColumn(List<Size> sizes) {
  const wantedAspect = 1.6;
  final width =
      sizes.fold(0.0, (sum, s) => sum + s.width) / sizes.length + _columnGap;
  final height =
      sizes.fold(0.0, (sum, s) => sum + s.height) / sizes.length + _rowGap;
  return math.max(
    3,
    math.sqrt(sizes.length * width / (wantedAspect * height)).round(),
  );
}

/// Lays [tables] out on their own and puts the result to the right of
/// [occupied], top aligned; where [occupied] is empty, at the origin.
Map<String, Rect> layoutBeside(List<DiagramTable> tables, Rect occupied) {
  final own = layoutGraph(SchemaGraph(tables));
  if (occupied.isEmpty || own.rects.isEmpty) return own.rects;
  final shift = Offset(
    occupied.right + _columnGap - own.bounds.left,
    occupied.top - own.bounds.top,
  );
  return own.rects.map((name, rect) => MapEntry(name, rect.shift(shift)));
}

/// Longest chain of references below each table; a reference that closes a
/// cycle is ignored.
List<int> _ranks(List<Set<int>> references) {
  const unvisited = -1, visiting = -2;
  final rank = List<int>.filled(references.length, unvisited);
  for (var start = 0; start < references.length; start++) {
    if (rank[start] != unvisited) continue;
    final stack = [start];
    while (stack.isNotEmpty) {
      final node = stack.last;
      if (rank[node] == unvisited) {
        rank[node] = visiting;
        for (final t in references[node]) {
          if (rank[t] == unvisited) stack.add(t);
        }
      } else {
        stack.removeLast();
        if (rank[node] != visiting) continue;
        var depth = 0;
        for (final t in references[node]) {
          if (rank[t] >= 0) depth = math.max(depth, rank[t] + 1);
        }
        rank[node] = depth;
      }
    }
  }
  return rank;
}
