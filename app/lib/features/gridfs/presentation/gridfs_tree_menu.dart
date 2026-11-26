import 'package:flutter/material.dart';

import 'gridfs_dialogs.dart';

enum _TreeAction { backingCollections, openBucket, refresh }

class GridFsTreeMenu extends StatelessWidget {
  const GridFsTreeMenu({
    super.key,
    required this.showCollections,
    required this.onToggleCollections,
    required this.onOpenBucket,
    required this.onRefresh,
    this.error,
  });

  final bool showCollections;
  final VoidCallback onToggleCollections;
  final ValueChanged<String> onOpenBucket;
  final VoidCallback onRefresh;
  final Object? error;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_TreeAction>(
    tooltip: error == null
        ? 'GridFS options'
        : 'GridFS buckets unavailable: $error',
    icon: Icon(
      error == null ? Icons.more_horiz : Icons.error_outline,
      size: 16,
    ),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      minimumSize: const Size.square(24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: _TreeAction.openBucket,
        child: Text('Open bucket…'),
      ),
      PopupMenuItem(
        value: _TreeAction.backingCollections,
        child: Text(
          showCollections
              ? 'Hide backing collections'
              : 'Show backing collections',
        ),
      ),
      const PopupMenuItem(
        value: _TreeAction.refresh,
        child: Text('Refresh buckets'),
      ),
    ],
    onSelected: (action) async {
      switch (action) {
        case _TreeAction.backingCollections:
          onToggleCollections();
        case _TreeAction.openBucket:
          final bucket = await showGridFsNameDialog(
            context,
            title: 'Open GridFS bucket',
            initial: 'fs',
          );
          if (bucket != null && context.mounted) onOpenBucket(bucket);
        case _TreeAction.refresh:
          onRefresh();
      }
    },
  );
}
