import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../editor/domain/query_models.dart';
import '../domain/cell_format.dart';

/// Longest text the viewer lays out. Longer values show a note; Copy still
/// copies the whole value.
const int kViewerMaxChars = 200000;

/// Text shown for [value]: JSON documents pretty-printed, everything else as
/// [formatCell] renders it.
String viewerText(Object? value, ColumnKind kind) {
  final raw = formatCell(value);
  if (value is String && (kind == ColumnKind.json || _looksLikeJson(raw))) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } on FormatException {
      return raw;
    }
  }
  return raw;
}

bool _looksLikeJson(String s) {
  final t = s.trimLeft();
  return t.startsWith('{') || t.startsWith('[');
}

/// Side panel with the full value of one cell.
class ValueViewerPanel extends StatelessWidget {
  const ValueViewerPanel({
    super.key,
    required this.value,
    required this.column,
    required this.row,
    required this.onClose,
  });

  final Object? value;
  final ResultColumn column;

  /// Zero-based row of the cell, shown one-based.
  final int row;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final full = viewerText(value, column.kind);
    final shown = full.length > kViewerMaxChars
        ? full.substring(0, kViewerMaxChars)
        : full;
    return Material(
      key: const Key('value-viewer'),
      color: cs.surfaceContainerLow,
      child: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${column.name} · row ${row + 1}'
                      '${column.typeName.isEmpty ? '' : ' · ${column.typeName}'}',
                      style: text.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy value',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: formatCell(value, forCopy: true)),
                    ),
                  ),
                  IconButton(
                    key: const Key('value-viewer-close'),
                    tooltip: 'Close (Esc)',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: value == null
                  ? Center(child: Text('NULL', style: text.bodyMedium))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        shown,
                        style: text.bodySmall!.copyWith(fontFamily: 'Menlo'),
                      ),
                    ),
            ),
            if (full.length > kViewerMaxChars)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Showing the first $kViewerMaxChars of ${full.length} '
                  'characters. Copy takes the whole value.',
                  style: text.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
