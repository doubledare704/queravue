import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/domain/admin_models.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/designer_controller.dart';
import 'column_draft_row.dart';
import 'constraints_section.dart';
import 'ddl_preview_dialog.dart';

class DesignerTabView extends ConsumerWidget {
  const DesignerTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designerProvider(tab.id));
    final controller = ref.read(designerProvider(tab.id).notifier);
    final scheme = Theme.of(context).colorScheme;

    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return AdminErrorView(
        error: AdminError(kind: AdminErrorKind.server, message: state.error!),
        onRetry: controller.load,
      );
    }

    Future<void> review() async {
      final problem = controller.validate();
      if (problem != null) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(problem)));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => DdlPreviewDialog(
          preview: controller.preview,
          apply: () => controller.apply(confirmed: true),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (state.isNew)
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('designer-table-name'),
                    onChanged: controller.setTableName,
                    decoration: const InputDecoration(
                      labelText: 'Table name',
                      isDense: true,
                    ),
                  ),
                )
              else
                Text(
                  state.tableRef.qualifiedName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const Spacer(),
              OutlinedButton.icon(
                key: const Key('designer-add-column'),
                onPressed: controller.addColumn,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add column'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('designer-review'),
                onPressed: state.hasChanges ? review : null,
                child: const Text('Review changes'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Name')),
                Expanded(flex: 3, child: Text('Type')),
                Expanded(flex: 3, child: Text('Default')),
                SizedBox(width: 56, child: Text('Null')),
                SizedBox(width: 56, child: Text('Key')),
                SizedBox(width: 56, child: Text('Auto')),
                SizedBox(width: 40),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < state.columns.length; i++)
                ColumnDraftRow(
                  key: ValueKey('col-$i-${state.columns[i].originalName}'),
                  index: i,
                  column: state.columns[i],
                  existing: !state.isNew,
                  onChanged: (c) => controller.updateColumn(i, c),
                  onRemove: () => controller.removeColumn(i),
                ),
              ConstraintsSection(tabId: tab.id),
            ],
          ),
        ),
      ],
    );
  }
}
