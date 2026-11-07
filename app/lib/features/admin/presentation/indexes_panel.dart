import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_controllers.dart';
import '../domain/admin_models.dart';
import 'admin_widgets.dart';
import 'index_dialogs.dart';

class IndexesPanel extends ConsumerWidget {
  const IndexesPanel({super.key, required this.target});

  final AdminTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(indexesProvider(target));
    final controller = ref.read(indexesProvider(target).notifier);
    final indexes = load.value;

    Widget body;
    if (load.error != null) {
      body = AdminErrorView(error: load.error!, onRetry: controller.reload);
    } else if (indexes == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (indexes.isEmpty) {
      body = const Center(child: Text('No indexes.'));
    } else {
      body = SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 36,
            dataRowMaxHeight: 52,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Keys')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Size'), numeric: true),
              DataColumn(label: Text('Usage')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final ix in indexes)
                DataRow(
                  key: ValueKey('index-row-${ix.name}'),
                  cells: [
                    DataCell(Text(ix.name)),
                    DataCell(Text(ix.keys.map((k) => k.label).join(', '))),
                    DataCell(Text(_typeLabel(ix))),
                    DataCell(
                      Text(
                        ix.sizeBytes == null
                            ? 'n/a'
                            : formatBytes(ix.sizeBytes!),
                      ),
                    ),
                    DataCell(Text(_usageLabel(ix))),
                    DataCell(
                      ix.primary
                          ? const SizedBox.shrink()
                          : IconButton(
                              key: Key('drop-index-${ix.name}'),
                              tooltip: 'Drop index',
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => showDropIndexDialog(
                                context,
                                target: target,
                                name: ix.name,
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              FilledButton.icon(
                key: const Key('new-index'),
                onPressed: indexes == null
                    ? null
                    : () => showCreateIndexDialog(context, target: target),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New index'),
              ),
              const Spacer(),
              IconButton(
                key: const Key('indexes-refresh'),
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: controller.reload,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}

String _typeLabel(IndexEntry ix) {
  final parts = [
    if (ix.primary) 'primary',
    if (ix.unique && !ix.primary) 'unique',
    if (ix.method.isNotEmpty) ix.method,
    if (ix.partialPredicate.isNotEmpty) 'partial',
  ];
  return parts.isEmpty ? 'index' : parts.join(', ');
}

String _usageLabel(IndexEntry ix) {
  if (!ix.usageAvailable || ix.scans == null) return 'n/a';
  final last = ix.lastUsed;
  final scans = '${ix.scans} scans';
  return last == null
      ? scans
      : '$scans, last ${last.toLocal()}'.split('.').first;
}
