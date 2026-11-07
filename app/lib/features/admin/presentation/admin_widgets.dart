import 'package:flutter/material.dart';

import '../domain/admin_models.dart';

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({super.key, required this.error, this.onRetry});

  final AdminError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unsupported = error.isUnsupported;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unsupported ? Icons.block : Icons.error_outline,
              color: unsupported ? scheme.outline : scheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              unsupported ? 'Not supported by this server' : 'Failed to load',
              key: const Key('admin-error-title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              error.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            if (onRetry != null && !unsupported) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class StatementBox extends StatelessWidget {
  const StatementBox({
    super.key,
    required this.statement,
    this.warnings = const [],
  });

  final String statement;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            statement,
            key: const Key('statement-preview'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 14, color: scheme.tertiary),
                const SizedBox(width: 6),
                Expanded(child: Text(w, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
      ],
    );
  }
}
