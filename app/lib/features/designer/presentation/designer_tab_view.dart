import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/domain/admin_models.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/designer_controller.dart';
import '../domain/design_models.dart';
import 'constraints_section.dart';

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
        builder: (_) => DdlPreviewDialog(tabId: tab.id),
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
                _ColumnRow(
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

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    super.key,
    required this.index,
    required this.column,
    required this.existing,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ColumnDraft column;
  final bool existing;
  final ValueChanged<ColumnDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final added = column.originalName == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextFormField(
                key: Key('col-name-$index'),
                initialValue: column.name,
                onChanged: (v) => onChanged(column.copyWith(name: v)),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextFormField(
                key: Key('col-type-$index'),
                initialValue: column.typeName,
                onChanged: (v) => onChanged(column.copyWith(typeName: v)),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextFormField(
                key: Key('col-default-$index'),
                initialValue: column.defaultExpression ?? '',
                onChanged: (v) => onChanged(
                  v.isEmpty
                      ? column.copyWith(clearDefault: true)
                      : column.copyWith(defaultExpression: v),
                ),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Checkbox(
              key: Key('col-nullable-$index'),
              value: column.nullable,
              onChanged: (v) => onChanged(column.copyWith(nullable: v ?? true)),
            ),
          ),
          SizedBox(
            width: 56,
            child: Checkbox(
              key: Key('col-pk-$index'),
              value: column.primaryKey,
              onChanged: existing
                  ? null
                  : (v) => onChanged(column.copyWith(primaryKey: v ?? false)),
            ),
          ),
          SizedBox(
            width: 56,
            child: Checkbox(
              key: Key('col-identity-$index'),
              value: column.identity,
              onChanged: existing && !added
                  ? null
                  : (v) => onChanged(column.copyWith(identity: v ?? false)),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              key: Key('col-remove-$index'),
              tooltip: 'Remove column',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class DdlPreviewDialog extends ConsumerStatefulWidget {
  const DdlPreviewDialog({super.key, required this.tabId});

  final String tabId;

  @override
  ConsumerState<DdlPreviewDialog> createState() => _DdlPreviewDialogState();
}

class _DdlPreviewDialogState extends ConsumerState<DdlPreviewDialog> {
  late final Future<AdminResult<DdlPreview>> _preview;

  @override
  void initState() {
    super.initState();
    _preview = Future.microtask(
      () => ref.read(designerProvider(widget.tabId).notifier).preview(),
    );
  }

  bool _busy = false;
  AdminError? _error;

  Future<void> _apply() async {
    setState(() => _busy = true);
    final result = await ref
        .read(designerProvider(widget.tabId).notifier)
        .apply(confirmed: true);
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Review changes'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            final result = snap.data;
            if (result == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (result.error != null) {
              return Text(
                result.error!.message,
                key: const Key('ddl-error'),
                style: TextStyle(color: scheme.error),
              );
            }
            final preview = result.value!;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in preview.statements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.summary,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (s.destructive) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'destructive',
                                  key: const Key('ddl-destructive'),
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          StatementBox(statement: s.sql),
                        ],
                      ),
                    ),
                  for (final w in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 14,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    preview.transactional
                        ? 'Runs in one transaction: a failure rolls everything back.'
                        : 'Each statement commits as it runs: a failure leaves earlier ones applied.',
                    key: const Key('ddl-transactional'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!.message,
                        key: const Key('ddl-error'),
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            final preview = snap.data?.value;
            return FilledButton(
              key: const Key('ddl-apply'),
              style: preview != null && preview.hasDestructive
                  ? FilledButton.styleFrom(backgroundColor: scheme.error)
                  : null,
              onPressed: preview == null || _busy ? null : _apply,
              child: Text(
                preview != null && preview.hasDestructive
                    ? 'Apply (destructive)'
                    : 'Apply',
              ),
            );
          },
        ),
      ],
    );
  }
}
