import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../grid/presentation/fixed_grid_view.dart';
import '../domain/ejson.dart';
import '../domain/models.dart';

/// Row height of the table and tree views.
const double kDocRowHeight = 26;

/// Longest text one JSON-view entry lays out.
const int kJsonViewMaxChars = 20000;

Color typeColor(EjsonType t, ColorScheme cs) => switch (t) {
  EjsonType.string => cs.tertiary,
  EjsonType.int32 ||
  EjsonType.int64 ||
  EjsonType.double_ ||
  EjsonType.decimal128 => cs.primary,
  EjsonType.objectId || EjsonType.uuid || EjsonType.binary => cs.secondary,
  EjsonType.date || EjsonType.timestamp => Colors.teal,
  EjsonType.object || EjsonType.array => cs.onSurfaceVariant,
  EjsonType.nullValue || EjsonType.undefined => cs.outline,
  _ => cs.onSurface,
};

/// Small type label, e.g. `Int64`.
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});

  final EjsonType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = typeColor(type, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Shows one value in full, shell-style, with a copy button for the
/// canonical EJSON.
Future<void> showValueDialog(
  BuildContext context, {
  required String title,
  required Object? value,
}) {
  final pretty = shellPretty(value);
  final shown = pretty.length > 200000 ? pretty.substring(0, 200000) : pretty;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('doc-value-dialog'),
      title: Row(
        children: [
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
          TypeBadge(ejsonTypeOf(value)),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 360,
        child: SingleChildScrollView(
          child: SelectableText(
            shown,
            style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: compactEjson(value))),
          child: const Text('Copy EJSON'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Table view: one row per document, a column per sampled field. Built on
/// the virtualized [FixedGridView] (ADR 0004): only visible cells exist.
class DocTableView extends StatefulWidget {
  const DocTableView({
    super.key,
    required this.docs,
    required this.columns,
    required this.selected,
    required this.firstIndex,
    required this.onSelect,
    required this.onEdit,
  });

  final List<DocItem> docs;
  final List<FieldStat> columns;
  final Set<int> selected;

  /// Index of the first document in the collection, for the row numbers.
  final int firstIndex;
  final void Function(int row, {bool toggle}) onSelect;
  final void Function(int row) onEdit;

  @override
  State<DocTableView> createState() => _DocTableViewState();
}

class _DocTableViewState extends State<DocTableView> {
  final _v = ScrollController();
  final _h = ScrollController();
  final Map<String, double> _widths = {};

  @override
  void dispose() {
    _v.dispose();
    _h.dispose();
    super.dispose();
  }

  List<String> get _names {
    final names = [for (final c in widget.columns) c.name];
    if (names.isEmpty) {
      // No sample yet: use the keys of the loaded documents.
      final seen = <String>{};
      for (final d in widget.docs) {
        final v = d.value;
        if (v is Map) seen.addAll(v.keys.cast<String>());
      }
      return seen.toList();
    }
    return names;
  }

  double _widthOf(String name) =>
      _widths[name] ??
      (name == '_id' ? 220 : math.max(130, name.length * 9.0 + 28));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final names = _names;
    final style = Theme.of(context).textTheme.bodySmall!
        .copyWith(fontFamily: 'Menlo', fontSize: 11.5);
    final headerBg = cs.surfaceContainerHigh;
    final rowHeaderW = math.max(
      56.0,
      '${widget.firstIndex + widget.docs.length}'.length * 9.0 + 28,
    );
    final stats = {for (final c in widget.columns) c.name: c};

    Widget cell(int vr, int vc) {
      final r = vr - 1, c = vc - 1;
      if (vr == 0) {
        if (c < 0) return ColoredBox(color: headerBg);
        final f = stats[names[c]];
        return ColoredBox(
          color: headerBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: names[c],
                      style: style.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (f != null && f.types.isNotEmpty)
                      TextSpan(
                        text: '  ${f.types.first}',
                        style: style.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      final selected = widget.selected.contains(r);
      if (c < 0) {
        return GestureDetector(
          key: Key('doc-row-header-$r'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onSelect(r, toggle: true),
          onDoubleTap: () => widget.onEdit(r),
          child: ColoredBox(
            color: selected ? cs.primaryContainer : headerBg,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('${widget.firstIndex + r + 1}', style: style),
              ),
            ),
          ),
        );
      }
      final doc = widget.docs[r].value;
      final has = doc is Map && doc.containsKey(names[c]);
      final v = has ? doc[names[c]] : null;
      return GestureDetector(
        key: Key('doc-cell-$r-$c'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => widget.onSelect(
          r,
          toggle:
              HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed,
        ),
        onDoubleTap: () => showValueDialog(
          context,
          title: '${names[c]} · document ${widget.firstIndex + r + 1}',
          value: v,
        ),
        child: ColoredBox(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: has
                  ? Text(
                      shellCompact(v, maxChars: 120),
                      style: style.copyWith(
                        color: typeColor(ejsonTypeOf(v), cs),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text('—', style: style.copyWith(color: cs.outline)),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Documents table, ${widget.docs.length} documents',
      child: FixedGridView(
        verticalDetails: ScrollableDetails.vertical(controller: _v),
        horizontalDetails: ScrollableDetails.horizontal(controller: _h),
        rowHeight: kDocRowHeight,
        columnWidths: [rowHeaderW, for (final n in names) _widthOf(n)],
        colors: GridPaintColors(
          line: cs.outlineVariant,
          stripe: cs.surfaceContainerLowest,
        ),
        delegate: TwoDimensionalChildBuilderDelegate(
          maxXIndex: names.length,
          maxYIndex: widget.docs.length,
          builder: (_, v) => cell(v.yIndex, v.xIndex),
        ),
      ),
    );
  }
}

/// Tree view: documents with expandable fields and type badges. Only the
/// rows on screen are built; collapsed branches cost nothing.
class DocTreeView extends StatefulWidget {
  const DocTreeView({
    super.key,
    required this.docs,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    this.initiallyExpanded = const {},
  });

  final List<DocItem> docs;
  final Set<int> selected;
  final void Function(int row, {bool toggle}) onSelect;
  final void Function(int row) onEdit;

  /// Paths expanded at first (for tests and goldens).
  final Set<String> initiallyExpanded;

  @override
  State<DocTreeView> createState() => _DocTreeViewState();
}

class _DocTreeViewState extends State<DocTreeView> {
  late final Set<String> _expanded = {...widget.initiallyExpanded};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = Theme.of(context).textTheme.bodySmall!
        .copyWith(fontFamily: 'Menlo', fontSize: 12);
    final rows = flattenTree([for (final d in widget.docs) d.value], _expanded);
    return Semantics(
      container: true,
      label: 'Documents tree',
      child: ListView.builder(
        key: const Key('doc-tree-list'),
        itemExtent: kDocRowHeight,
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final row = rows[i];
          final docIndex = int.parse(row.path.split('/').first);
          final top = row.depth == 0;
          final selected = widget.selected.contains(docIndex);
          if (row.more > 0) {
            return Padding(
              padding: EdgeInsets.only(left: 12.0 + row.depth * 16 + 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(row.label, style: mono.copyWith(color: cs.outline)),
              ),
            );
          }
          return InkWell(
            key: Key('doc-tree-row-${row.path}'),
            onTapDown: (_) {
              if (row.expandable) {
                setState(() {
                  if (!_expanded.remove(row.path)) _expanded.add(row.path);
                });
              }
              if (top) widget.onSelect(docIndex);
            },
            onDoubleTap: top ? () => widget.onEdit(docIndex) : null,
            child: Container(
              color: top && selected
                  ? cs.primaryContainer.withValues(alpha: 0.5)
                  : null,
              padding: EdgeInsets.only(left: 8.0 + row.depth * 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: row.expandable
                        ? Icon(
                            row.expanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 16,
                          )
                        : null,
                  ),
                  Flexible(
                    flex: 0,
                    child: Text(
                      top ? row.label : '${row.label}:',
                      style: mono.copyWith(
                        fontWeight: top ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TypeBadge(row.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.type.isContainer
                          ? shellScalar(row.value)
                          : shellCompact(row.value, maxChars: 200),
                      style: mono.copyWith(color: typeColor(row.type, cs)),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// JSON view: read-only shell-style text, built per document as it scrolls
/// into view.
class DocJsonView extends StatelessWidget {
  const DocJsonView({
    super.key,
    required this.docs,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final List<DocItem> docs;
  final Set<int> selected;
  final void Function(int row, {bool toggle}) onSelect;
  final void Function(int row) onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      key: const Key('doc-json-list'),
      itemCount: docs.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, i) {
        var text = shellPretty(docs[i].value);
        final cut = text.length > kJsonViewMaxChars;
        if (cut) {
          text =
              '${text.substring(0, kJsonViewMaxChars)}\n… (cut; Edit shows the whole document)';
        }
        return GestureDetector(
          key: Key('doc-json-$i'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onSelect(i),
          onDoubleTap: () => onEdit(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected.contains(i)
                  ? cs.primaryContainer.withValues(alpha: 0.4)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
