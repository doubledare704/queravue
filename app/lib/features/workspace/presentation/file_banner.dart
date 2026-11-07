import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/application/editor_tabs.dart';
import '../application/tab_files.dart';

/// Offers reload or keep-mine when the tab's file changed outside the app.
class FileChangeBanner extends ConsumerWidget {
  const FileChangeBanner({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = ref.watch(tabFileProvider(tab.id).select((s) => s?.external));
    if (ext == null) return const SizedBox.shrink();
    final c = ref.read(tabFileProvider(tab.id).notifier);
    final deleted = ext.kind == ExternalKind.deleted;
    return MaterialBanner(
      key: const Key('file-change-banner'),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      content: Text(
        deleted
            ? '${tab.title} was deleted on disk.'
            : '${tab.title} changed on disk.',
      ),
      actions: [
        if (!deleted)
          TextButton(
            key: const Key('banner-reload'),
            onPressed: c.reload,
            child: const Text('Reload'),
          ),
        TextButton(
          key: const Key('banner-keep'),
          onPressed: c.keepMine,
          child: const Text('Keep mine'),
        ),
      ],
    );
  }
}
