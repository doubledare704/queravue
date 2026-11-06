import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/document_tab_controller.dart';
import 'doc_views.dart';
import 'document_dialogs.dart';
import 'query_bar.dart';

/// Formats a document count, e.g. `1,234,567`.
String formatCount(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// A collection opened in a tab: query bar, the three document views over one
/// page, paging, and insert / edit / delete.
class DocumentTabView extends ConsumerWidget {
  const DocumentTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentTabProvider(tab.id));
    final c = ref.read(documentTabProvider(tab.id).notifier);
    final cs = Theme.of(context).colorScheme;
    final production = ref.watch(
      connectionsControllerProvider.select(
        (v) =>
            v.value
                ?.where((p) => p.id == tab.connectionId)
                .firstOrNull
                ?.production ??
            false,
      ),
    );

    void edit(int row) {
      if (row < state.docs.length) {
        showDocumentEditor(context, tabId: tab.id, original: state.docs[row]);
      }
    }

    Future<void> delete() async {
      final n = state.selected.length;
      if (n == 0) return;
      final ok = await confirmDelete(context, count: n, production: production);
      if (!ok || !context.mounted) return;
      final out = await c.deleteSelected(confirmed: true);
      if (out is WriteFailed && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Delete failed: ${out.error.message}')),
        );
      }
    }

    final from = state.docs.isEmpty ? 0 : state.firstIndex + 1;
    final to = state.firstIndex + state.docs.length;
    final countText = state.count == null
        ? (state.isCounting ? 'counting…' : '')
        : ' of ${state.count!.exact ? '' : '~'}${formatCount(state.count!.count)}';

    final Widget body;
    if (state.error != null && state.docs.isEmpty) {
      body = Center(
        child: Text(
          state.error!,
          key: const Key('doc-error'),
          style: TextStyle(color: cs.error),
        ),
      );
    } else if (!state.loaded && state.docs.isEmpty) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (state.docs.isEmpty) {
      body = const Center(
        child: Text('No documents match.', key: Key('doc-empty')),
      );
    } else {
      body = switch (state.view) {
        DocView.table => DocTableView(
          key: const Key('doc-table'),
          docs: state.docs,
          columns: state.columns,
          selected: state.selected,
          firstIndex: state.firstIndex,
          onSelect: c.select,
          onEdit: edit,
        ),
        DocView.tree => DocTreeView(
          key: const Key('doc-tree'),
          docs: state.docs,
          selected: state.selected,
          onSelect: c.select,
          onEdit: edit,
        ),
        DocView.json => DocJsonView(
          key: const Key('doc-json'),
          docs: state.docs,
          selected: state.selected,
          onSelect: c.select,
          onEdit: edit,
        ),
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentQueryBar(tabId: tab.id),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<DocView>(
                key: const Key('doc-view-switch'),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                    value: DocView.table,
                    icon: Icon(Icons.table_rows_outlined, size: 16),
                    label: Text('Table'),
                  ),
                  ButtonSegment(
                    value: DocView.tree,
                    icon: Icon(Icons.account_tree_outlined, size: 16),
                    label: Text('Tree'),
                  ),
                  ButtonSegment(
                    value: DocView.json,
                    icon: Icon(Icons.data_object, size: 16),
                    label: Text('JSON'),
                  ),
                ],
                selected: {state.view},
                onSelectionChanged: (s) => c.setView(s.first),
              ),
              Text(
                state.docs.isEmpty ? countText : '$from–$to$countText',
                key: const Key('doc-range'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              IconButton(
                key: const Key('doc-prev'),
                tooltip: 'Previous page',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left),
                onPressed: state.page > 0 && !state.isLoading
                    ? c.prevPage
                    : null,
              ),
              IconButton(
                key: const Key('doc-next'),
                tooltip: 'Next page',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right),
                onPressed: state.hasNext && !state.isLoading
                    ? c.nextPage
                    : null,
              ),
              DropdownButton<int>(
                key: const Key('doc-page-size'),
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
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('doc-insert'),
                onPressed: () => showDocumentEditor(context, tabId: tab.id),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Insert'),
              ),
              OutlinedButton.icon(
                key: const Key('doc-edit'),
                onPressed: state.selected.length == 1
                    ? () => edit(state.selected.first)
                    : null,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                key: const Key('doc-delete'),
                onPressed: state.selected.isEmpty || state.isWriting
                    ? null
                    : delete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(
                  state.selected.isEmpty
                      ? 'Delete'
                      : 'Delete (${state.selected.length})',
                ),
              ),
              IconButton(
                key: const Key('doc-refresh'),
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: state.isLoading ? null : c.refresh,
              ),
            ],
          ),
        ),
        if (state.error != null && state.docs.isNotEmpty)
          MaterialBanner(
            content: Text(state.error!),
            actions: const [SizedBox.shrink()],
          ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}
