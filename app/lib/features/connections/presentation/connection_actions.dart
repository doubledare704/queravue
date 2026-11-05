import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/connection_form_controller.dart';
import '../application/connections_controller.dart';
import '../domain/models.dart';
import 'connection_dialog.dart';

/// Picks a local file; returns its path or null. Override in tests.
final filePickerProvider = Provider<Future<String?> Function()>(
  (ref) =>
      () async => (await openFile())?.path,
);

/// Color of a [ColorTag] dot, or null for none.
Color? colorTagColor(ColorTag tag) => switch (tag) {
  ColorTag.none => null,
  ColorTag.red => Colors.red,
  ColorTag.orange => Colors.orange,
  ColorTag.yellow => Colors.amber,
  ColorTag.green => Colors.green,
  ColorTag.blue => Colors.blue,
  ColorTag.purple => Colors.purple,
  ColorTag.gray => Colors.blueGrey,
};

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// Opens the connection dialog. With [initial], edits it (or duplicates it
/// when [duplicate]). Returns the saved profile, or null if cancelled.
Future<ConnectionProfile?> showConnectionDialog(
  BuildContext context,
  WidgetRef ref, {
  ConnectionProfile? initial,
  bool duplicate = false,
}) async {
  final List<EngineSpec> engines;
  try {
    engines = await ref.read(enginesProvider.future);
  } on Object catch (e) {
    if (context.mounted) _snack(context, 'Cannot open connection dialog: $e');
    return null;
  }
  if (!context.mounted || engines.isEmpty) return null;
  final args = ConnectionFormArgs(
    engines: engines,
    initial: initial,
    duplicate: duplicate,
  );
  final saved = await showDialog<ConnectionProfile>(
    context: context,
    builder: (_) => ConnectionDialog(args: args),
  );
  if (saved != null) {
    ref.read(selectedConnectionProvider.notifier).select(saved.id);
  }
  return saved;
}

/// Asks for confirmation, then deletes [profile].
Future<void> confirmDeleteConnection(
  BuildContext context,
  WidgetRef ref,
  ConnectionProfile profile,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete "${profile.name}"?'),
      content: Text(
        profile.hasPassword
            ? 'The connection and its saved password are removed. '
                  'This cannot be undone.'
            : 'The connection is removed. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-delete'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(connectionsControllerProvider.notifier).delete(profile.id);
  } on ConnectionsException catch (e) {
    if (context.mounted) _snack(context, 'Delete failed: ${e.message}');
  }
}

/// "Connect": tests the saved connection with its keychain password.
Future<void> connectTo(WidgetRef ref, ConnectionProfile profile) async {
  ref.read(selectedConnectionProvider.notifier).select(profile.id);
  await ref.read(connectionTestsProvider.notifier).connect(profile.id);
}
