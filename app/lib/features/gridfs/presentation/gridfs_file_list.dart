import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/domain/admin_models.dart' show formatBytes;
import '../../grid/presentation/fixed_grid_view.dart';
import '../application/gridfs_controller.dart';
import '../domain/gridfs_models.dart';

class GridFsFileList extends StatelessWidget {
  const GridFsFileList({
    super.key,
    required this.page,
    required this.onSelect,
    this.selectedId,
  });

  final GridFsPage page;
  final String? selectedId;
  final ValueChanged<GridFsEntry> onSelect;

  static const _headers = [
    '#',
    'Filename',
    'Length',
    'Upload date',
    'Content type',
    'ID',
  ];
  static const _widths = [48.0, 220.0, 92.0, 190.0, 176.0, 264.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedIndex = page.files.indexWhere(
      (file) => file.id == selectedId,
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (selectedIndex + 1 < page.files.length) {
            onSelect(page.files[selectedIndex + 1]);
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          if (selectedIndex > 0) onSelect(page.files[selectedIndex - 1]);
        },
      },
      child: Focus(
        child: Builder(
          builder: (gridContext) => FixedGridView(
            rowHeight: 30,
            columnWidths: _widths,
            colors: GridPaintColors(
              line: colors.outlineVariant,
              stripe: colors.surfaceContainerLowest,
            ),
            delegate: TwoDimensionalChildBuilderDelegate(
              maxXIndex: _headers.length - 1,
              maxYIndex: page.files.length,
              builder: (context, cell) {
                final column = cell.xIndex;
                final row = cell.yIndex;
                final header = row == 0;
                final file = header ? null : page.files[row - 1];
                final selected = file != null && file.id == selectedId;
                final value = file == null
                    ? _headers[column]
                    : switch (column) {
                        0 => '${page.index * gridFsPageSize + row}',
                        1 => file.filename,
                        2 => formatBytes(file.length),
                        3 => file.uploadDate.toUtc().toIso8601String(),
                        4 => file.contentType,
                        _ => file.id,
                      };
                final label = Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: header
                      ? colors.surfaceContainer
                      : selected
                      ? colors.secondaryContainer
                      : null,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: header
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.bodySmall,
                  ),
                );
                if (file == null) return label;
                return Semantics(
                  selected: selected,
                  child: InkWell(
                    canRequestFocus: column == 1,
                    onTap: () {
                      Focus.of(gridContext).requestFocus();
                      onSelect(file);
                    },
                    child: label,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
