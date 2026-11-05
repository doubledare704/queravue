import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_actions.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/query_models.dart';
import '../data/history_repository.dart';
import '../domain/history_models.dart';

/// Opens the history dialog (Cmd+Y).
Future<void> showHistoryDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const HistoryDialog(),
  );
}

class HistoryDialog extends ConsumerStatefulWidget {
  const HistoryDialog({super.key});

  @override
  ConsumerState<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends ConsumerState<HistoryDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedConnectionId;
  bool _isLoading = true;
  HistoryPage? _page;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedConnectionId = ref.read(selectedConnectionProvider);
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(historyRepositoryProvider);
      final page = await repo.listHistory(
        connectionId: _selectedConnectionId,
        searchQuery: _searchQuery,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _searchQuery = text.trim());
      _loadHistory();
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Query History?'),
        content: const Text(
          'This will delete saved query history entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-clear-history-btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(historyRepositoryProvider)
          .clearHistory(_selectedConnectionId);
      await _loadHistory();
    }
  }

  void _openInEditor(HistoryItem item) {
    Navigator.of(context).pop();
    final connId = item.connectionId.isNotEmpty
        ? item.connectionId
        : (ref.read(selectedConnectionProvider) ?? '');
    if (connId.isNotEmpty) {
      ref
          .read(editorTabsProvider.notifier)
          .openQueryWithSql(connId, item.queryText);
    }
  }

  Future<void> _reRun(HistoryItem item) async {
    Navigator.of(context).pop();
    final connId = item.connectionId.isNotEmpty
        ? item.connectionId
        : (ref.read(selectedConnectionProvider) ?? '');
    if (connId.isNotEmpty) {
      ref
          .read(editorTabsProvider.notifier)
          .openQueryWithSql(connId, item.queryText);
      await runActiveTab(ref, ExecuteMode.all);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _page?.items ?? const [];
    final connections = ref.watch(connectionsControllerProvider).value ?? [];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history, size: 22),
          const SizedBox(width: 8),
          const Text('Query History'),
          const Spacer(),
          IconButton(
            key: const Key('history-clear-btn'),
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            tooltip: 'Clear history',
            onPressed: items.isNotEmpty ? _clearHistory : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 520,
        child: Column(
          children: [
            // Search and connection filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('history-search-input'),
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search executed queries…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    key: const Key('history-connection-dropdown'),
                    initialValue: _selectedConnectionId,
                    isExpanded: true,
                    style: theme.textTheme.bodySmall,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All connections'),
                      ),
                      for (final c in connections)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedConnectionId = v);
                      _loadHistory();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // History items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No queries matched your search.'
                            : 'No query history recorded yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _HistoryItemTile(
                          item: item,
                          onOpenInEditor: () => _openInEditor(item),
                          onReRun: () => _reRun(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({
    required this.item,
    required this.onOpenInEditor,
    required this.onReRun,
  });

  final HistoryItem item;
  final VoidCallback onOpenInEditor;
  final VoidCallback onReRun;

  String _formatDuration(Duration d) {
    if (d.inMilliseconds < 1000) {
      return '${d.inMilliseconds} ms';
    }
    return '${(d.inMilliseconds / 1000.0).toStringAsFixed(2)} s';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(
              item.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              size: 16,
              color: item.isSuccess ? Colors.green : scheme.error,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  item.queryText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!item.isSuccess && item.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTime(item.startedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(item.duration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.rowsAffected} rows',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy SQL',
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.queryText));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Copied SQL to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Open in editor',
            icon: const Icon(Icons.edit_note, size: 18),
            onPressed: onOpenInEditor,
          ),
          IconButton(
            tooltip: 'Re-run',
            icon: const Icon(Icons.play_arrow, size: 18),
            onPressed: onReRun,
          ),
        ],
      ),
    );
  }
}
