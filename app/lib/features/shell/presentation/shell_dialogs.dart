import 'package:flutter/material.dart';

/// Asks before a gated operation runs on a production connection.
Future<bool> confirmShellOperation(
  BuildContext context, {
  required String operation,
  required String connectionName,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('shell-confirm'),
      title: const Text('Confirm destructive operation'),
      content: Text(
        '$connectionName is marked production.\n\n$operation\n\n'
        'Nothing has been changed yet. Run the script anyway?',
      ),
      actions: [
        TextButton(
          key: const Key('shell-confirm-cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('shell-confirm-run'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Run on production'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
