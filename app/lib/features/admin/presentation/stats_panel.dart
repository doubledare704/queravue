import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_controllers.dart';
import '../domain/admin_models.dart';
import 'admin_widgets.dart';

class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key, required this.target});

  final AdminTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(statsProvider(target));
    final controller = ref.read(statsProvider(target).notifier);
    final stats = load.value;
    if (load.error != null) {
      return AdminErrorView(error: load.error!, onRetry: controller.reload);
    }
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = <(String, String)>[
      if (stats.estimatedRows != null)
        ('Estimated rows', _count(stats.estimatedRows!)),
      if (stats.dataBytes != null) ('Data size', formatBytes(stats.dataBytes!)),
      if (stats.indexBytes != null)
        ('Index size', formatBytes(stats.indexBytes!)),
      if (stats.totalBytes != null)
        ('Total size', formatBytes(stats.totalBytes!)),
      for (final e in stats.extras) (e.label, e.value),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const Key('stats-refresh'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: controller.reload,
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('The server reports no statistics.'))
              : ListView(
                  children: [
                    for (final (label, value) in rows)
                      ListTile(
                        dense: true,
                        title: Text(label),
                        trailing: SelectableText(
                          value,
                          key: Key('stat-$label'),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _count(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
