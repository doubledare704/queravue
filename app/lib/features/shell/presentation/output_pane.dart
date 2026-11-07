import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/application/document_tab_controller.dart';
import '../../documents/domain/ejson.dart';
import '../../documents/presentation/doc_views.dart';
import '../application/cursor_page_controller.dart';
import '../application/shell_tab_controller.dart';
import '../domain/shell_models.dart';

/// The output of a shell tab: print lines, values, write results, cursors
/// and errors. Only visible entries are built.
class ShellOutputPane extends StatelessWidget {
  const ShellOutputPane({
    super.key,
    required this.entries,
    required this.shellId,
    required this.onJump,
  });

  final List<OutputEntry> entries;
  final String? shellId;

  /// Called with a 0-based buffer line and a 1-based column when an error is
  /// clicked.
  final void Function(int line, int column) onJump;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Output appears here.',
          key: const Key('shell-output-empty'),
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }
    return ListView.builder(
      key: const Key('shell-output'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: entries.length,
      itemBuilder: (_, i) =>
          OutputEntryView(entry: entries[i], shellId: shellId, onJump: onJump),
    );
  }
}

const _mono = TextStyle(fontFamily: 'Menlo', fontSize: 12.5, height: 1.35);

/// Text of a value as the shell shows it.
String valueText(String ejson) {
  try {
    return shellPretty(decodeEjson(ejson));
  } on FormatException {
    return ejson;
  }
}

/// One entry of the output.
class OutputEntryView extends StatelessWidget {
  const OutputEntryView({
    super.key,
    required this.entry,
    required this.shellId,
    required this.onJump,
  });

  final OutputEntry entry;
  final String? shellId;
  final void Function(int line, int column) onJump;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 1);
    switch (entry) {
      case OutputRun(:final summary):
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: Text(
            '▸ $summary',
            key: const Key('output-run'),
            style: _mono.copyWith(color: cs.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case OutputPrint(:final level, :final text):
        return Padding(
          padding: pad,
          child: SelectableText(
            text,
            key: const Key('output-print'),
            style: _mono.copyWith(
              color: switch (level) {
                PrintLevel.error => cs.error,
                PrintLevel.warn => Colors.orange.shade700,
                PrintLevel.info => cs.primary,
                PrintLevel.log => cs.onSurface,
              },
            ),
          ),
        );
      case OutputValue(:final kind, :final text, :final writeOp):
        return Padding(
          padding: pad,
          child: SelectableText(
            kind == ValueKind.write
                ? '$writeOp ${valueText(text)}'
                : valueText(text),
            key: Key(kind == ValueKind.write ? 'output-write' : 'output-value'),
            style: _mono.copyWith(
              color: kind == ValueKind.write ? cs.tertiary : cs.onSurface,
            ),
          ),
        );
      case OutputCursor(:final handle):
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: shellId == null
              ? const SizedBox.shrink()
              : CursorResultView(
                  key: Key('cursor-${handle.cursorId}'),
                  cursorKey: CursorKey(shellId!, handle.cursorId),
                  title:
                      '${handle.kind == CursorKind.find ? 'find' : 'aggregate'}'
                      ' on ${handle.collection}',
                ),
        );
      case OutputError(:final failure, :final line, :final column):
        final canJump = line >= 0 && failure.line > 0;
        return InkWell(
          key: const Key('output-error'),
          onTap: canJump ? () => onJump(line, column) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: failure.message,
                    style: _mono.copyWith(color: cs.error),
                  ),
                  if (canJump)
                    TextSpan(
                      text:
                          '   line ${line + 1}'
                          '${column > 0 ? ':$column' : ''} ↗',
                      style: _mono.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      case OutputDone(:final duration):
        return Padding(
          padding: pad,
          child: Text(
            'done in ${_duration(duration)}',
            key: const Key('output-done'),
            style: _mono.copyWith(color: cs.outline, fontSize: 11),
          ),
        );
    }
  }
}

String _duration(Duration d) => d.inMilliseconds < 1000
    ? '${d.inMilliseconds} ms'
    : '${(d.inMilliseconds / 1000).toStringAsFixed(2)} s';

/// A cursor result: the existing table, tree and JSON views over one page,
/// with paging. Read-only.
class CursorResultView extends ConsumerWidget {
  const CursorResultView({
    super.key,
    required this.cursorKey,
    required this.title,
    this.height = 320,
  });

  final CursorKey cursorKey;
  final String title;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cursorPageProvider(cursorKey));
    final c = ref.read(cursorPageProvider(cursorKey).notifier);
    final cs = Theme.of(context).colorScheme;
    void noEdit(int _) {}

    final Widget body;
    if (state.error != null) {
      body = Center(
        child: Text(
          state.error!,
          key: const Key('cursor-error'),
          style: TextStyle(color: cs.error),
        ),
      );
    } else if (state.isLoading && state.docs.isEmpty) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (state.docs.isEmpty) {
      body = const Center(
        child: Text('No documents.', key: Key('cursor-empty')),
      );
    } else {
      body = switch (state.view) {
        DocView.table => DocTableView(
          key: const Key('cursor-table'),
          docs: state.docs,
          columns: state.columns,
          selected: state.selected,
          firstIndex: state.firstIndex,
          onSelect: c.select,
          onEdit: noEdit,
        ),
        DocView.tree => DocTreeView(
          key: const Key('cursor-tree'),
          docs: state.docs,
          selected: state.selected,
          onSelect: c.select,
          onEdit: noEdit,
        ),
        DocView.json => DocJsonView(
          key: const Key('cursor-json'),
          docs: state.docs,
          selected: state.selected,
          onSelect: c.select,
          onEdit: noEdit,
        ),
      };
    }
    final from = state.docs.isEmpty ? 0 : state.firstIndex + 1;
    final to = state.firstIndex + state.docs.length;
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                SegmentedButton<DocView>(
                  key: const Key('cursor-view-switch'),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: DocView.table, label: Text('Table')),
                    ButtonSegment(value: DocView.tree, label: Text('Tree')),
                    ButtonSegment(value: DocView.json, label: Text('JSON')),
                  ],
                  selected: {state.view},
                  onSelectionChanged: (s) => c.setView(s.first),
                ),
                Text(
                  state.docs.isEmpty ? '' : '$from–$to',
                  key: const Key('cursor-range'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  key: const Key('cursor-prev'),
                  tooltip: 'Previous page',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: state.page > 0 && !state.isLoading
                      ? c.prevPage
                      : null,
                ),
                IconButton(
                  key: const Key('cursor-next'),
                  tooltip: 'Next page',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: state.hasNext && !state.isLoading
                      ? c.nextPage
                      : null,
                ),
                DropdownButton<int>(
                  key: const Key('cursor-page-size'),
                  value: state.pageSize,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final n in kDocPageSizes)
                      DropdownMenuItem(value: n, child: Text('$n / page')),
                  ],
                  onChanged: (n) {
                    if (n != null) c.setPageSize(n);
                  },
                ),
                if (state.isLoading)
                  const SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
