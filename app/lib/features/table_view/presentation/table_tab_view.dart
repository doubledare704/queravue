import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/query_models.dart';
import '../../grid/application/result_window.dart';
import '../../grid/presentation/result_grid.dart';
import '../../schema/domain/schema_models.dart';
import '../application/pending_changes_controller.dart';
import '../application/table_tab_controller.dart';
import '../domain/table_models.dart';
import 'commit_preview_dialog.dart';
import 'filter_bar.dart';

/// Table tab: filter bar, click-to-sort headers, page size selector,
/// read-only badge when no PK, inline editing, and commit workflow.
class TableTabView extends ConsumerStatefulWidget {
  const TableTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<TableTabView> createState() => _TableTabViewState();
}

class _TableTabViewState extends ConsumerState<TableTabView> {
  int? _selectedRowIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableTabProvider(widget.tab.id));
    final controller = ref.read(tableTabProvider(widget.tab.id).notifier);
    final pendingChanges = ref.watch(pendingChangesProvider(widget.tab.id));
    final pendingController = ref.read(
      pendingChangesProvider(widget.tab.id).notifier,
    );

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = state.tableDetails;
    final columns = details?.columns ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Toolbar: Filter Bar
        FilterBar(
          filter: state.filter,
          columns: columns,
          onApply: controller.setFilter,
          onClear: () => controller.setFilter(const TableFilter()),
        ),
        // Secondary Toolbar: Controls & Edit Actions
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              // Page size selector
              const Text('Page size:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              DropdownButton<int>(
                key: const Key('page-size-dropdown'),
                value: state.pageSize,
                underline: const SizedBox.shrink(),
                style: theme.textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: 500, child: Text('500')),
                  DropdownMenuItem(value: 1000, child: Text('1,000')),
                  DropdownMenuItem(value: 5000, child: Text('5,000')),
                  DropdownMenuItem(value: 1000000, child: Text('All')),
                ],
                onChanged: (v) {
                  if (v != null) controller.setPageSize(v);
                },
              ),
              const SizedBox(width: 12),
              // Open in Editor button
              OutlinedButton.icon(
                key: const Key('open-sql-in-editor-btn'),
                icon: const Icon(Icons.code, size: 16),
                label: const Text(
                  'Open SQL in editor',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 28),
                ),
                onPressed: state.generatedSql != null
                    ? controller.openInEditor
                    : null,
              ),
              const Spacer(),
              // Edit controls
              if (!state.canEdit && details != null) ...[
                Tooltip(
                  message:
                      state.readOnlyReason ?? 'Table cannot be edited directly',
                  child: Container(
                    key: const Key('table-readonly-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Read-only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (state.canEdit) ...[
                TextButton.icon(
                  key: const Key('add-row-btn'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add row', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      _showAddRowDialog(context, columns, pendingController),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  key: const Key('delete-row-btn'),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text(
                    'Delete row',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _selectedRowIndex != null
                      ? () => _deleteSelectedRow(state, pendingController)
                      : null,
                ),
                const SizedBox(width: 4),
                if (pendingChanges.hasChanges) ...[
                  TextButton(
                    key: const Key('discard-changes-btn'),
                    onPressed: pendingController.discard,
                    child: const Text(
                      'Discard',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    key: const Key('review-commit-btn'),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'Review & Commit (${pendingChanges.changeCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () =>
                        CommitPreviewDialog.show(context, widget.tab.id),
                  ),
                ],
              ],
            ],
          ),
        ),
        // Error banner if any
        if (state.errorMessage != null)
          Container(
            color: scheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        // Result Grid
        Expanded(
          child: state.isLoading && state.resultId == null
              ? const Center(child: CircularProgressIndicator())
              : state.resultId != null
              ? ResultGrid(
                  key: ValueKey(state.resultId),
                  resultId: state.resultId!,
                  sorts: state.sorts,
                  onSort: controller.toggleSort,
                  canEdit: state.canEdit,
                  tableDetails: details,
                  pendingChanges: pendingChanges,
                  onRowSelected: (r) {
                    setState(() => _selectedRowIndex = r);
                  },
                  onCellDoubleTap: state.canEdit
                      ? (r, c, val) => _openCellEditor(
                          context,
                          r,
                          c,
                          val,
                          state,
                          pendingChanges,
                          pendingController,
                        )
                      : null,
                )
              : const Center(child: Text('No table data loaded')),
        ),
      ],
    );
  }

  void _deleteSelectedRow(
    TableTabState state,
    PendingChangesController pending,
  ) {
    if (_selectedRowIndex == null || state.resultId == null) return;
    final win = ref.read(resultWindowProvider(state.resultId!));
    final row = ref
        .read(resultWindowProvider(state.resultId!).notifier)
        .rowAt(_selectedRowIndex!);
    final details = state.tableDetails;
    if (row == null || details == null) return;

    final pkCols = details.primaryKeyColumns;
    final pkValues = <String, Object?>{};
    for (final pk in pkCols) {
      final colIdx = win.columns.indexWhere((c) => c.name == pk.name);
      if (colIdx >= 0 && colIdx < row.length) {
        pkValues[pk.name] = row[colIdx];
      }
    }
    if (pkValues.length == pkCols.length) {
      pending.deleteRow(pkValues);
    }
  }

  Future<void> _openCellEditor(
    BuildContext context,
    int rowIndex,
    int colIndex,
    Object? currentValue,
    TableTabState state,
    PendingChangesState pending,
    PendingChangesController pendingController,
  ) async {
    if (state.resultId == null || state.tableDetails == null) return;
    final win = ref.read(resultWindowProvider(state.resultId!));
    final cols = win.columns;
    if (colIndex >= cols.length) return;
    final col = cols[colIndex];

    final row = ref
        .read(resultWindowProvider(state.resultId!).notifier)
        .rowAt(rowIndex);
    if (row == null) return;

    final pkCols = state.tableDetails!.primaryKeyColumns;
    final pkValues = <String, Object?>{};
    for (final pk in pkCols) {
      final idx = cols.indexWhere((c) => c.name == pk.name);
      if (idx >= 0 && idx < row.length) {
        pkValues[pk.name] = row[idx];
      }
    }
    if (pkValues.length != pkCols.length) return;

    final colDef = state.tableDetails!.columns
        .where((c) => c.name == col.name)
        .firstOrNull;
    final isNullable = colDef?.nullable ?? true;

    final updatedVal = await _showCellEditDialog(
      context,
      col.name,
      col.kind,
      col.typeName,
      currentValue,
      isNullable,
    );

    if (updatedVal != null) {
      pendingController.updateCell(
        pkValues: pkValues,
        column: col.name,
        newValue: updatedVal.$1 ? null : updatedVal.$2,
      );
    }
  }

  Future<(bool isNull, Object? value)?> _showCellEditDialog(
    BuildContext context,
    String colName,
    ColumnKind kind,
    String typeName,
    Object? initialValue,
    bool isNullable,
  ) {
    return showDialog<(bool, Object?)>(
      context: context,
      builder: (ctx) => _CellEditDialog(
        columnName: colName,
        kind: kind,
        typeName: typeName,
        initialValue: initialValue,
        isNullable: isNullable,
      ),
    );
  }

  Future<void> _showAddRowDialog(
    BuildContext context,
    List<ColumnDetails> columns,
    PendingChangesController pendingController,
  ) async {
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => _AddRowDialog(columns: columns),
    );
    if (values != null && values.isNotEmpty) {
      pendingController.addRow(values);
    }
  }
}

class _CellEditDialog extends StatefulWidget {
  const _CellEditDialog({
    required this.columnName,
    required this.kind,
    required this.typeName,
    required this.initialValue,
    required this.isNullable,
  });

  final String columnName;
  final ColumnKind kind;
  final String typeName;
  final Object? initialValue;
  final bool isNullable;

  @override
  State<_CellEditDialog> createState() => _CellEditDialogState();
}

class _CellEditDialogState extends State<_CellEditDialog> {
  late bool _isNull;
  late TextEditingController _textController;
  bool _boolValue = false;

  @override
  void initState() {
    super.initState();
    _isNull = widget.initialValue == null;
    if (widget.kind == ColumnKind.boolean) {
      _boolValue = widget.initialValue is bool
          ? (widget.initialValue as bool)
          : false;
      _textController = TextEditingController();
    } else {
      _textController = TextEditingController(
        text: widget.initialValue != null ? '${widget.initialValue}' : '',
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Object? _parseValue() {
    if (_isNull) return null;
    final t = _textController.text.trim();
    switch (widget.kind) {
      case ColumnKind.boolean:
        return _boolValue;
      case ColumnKind.integer:
        return int.tryParse(t) ?? t;
      case ColumnKind.float:
      case ColumnKind.decimal:
        return double.tryParse(t) ?? t;
      default:
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit "${widget.columnName}" (${widget.typeName})'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isNullable)
              CheckboxListTile(
                title: const Text('Set to NULL'),
                value: _isNull,
                onChanged: (v) => setState(() => _isNull = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            if (!_isNull) ...[
              const SizedBox(height: 8),
              if (widget.kind == ColumnKind.boolean)
                Row(
                  children: [
                    const Text('Value: '),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('TRUE')),
                        ButtonSegment(value: false, label: Text('FALSE')),
                      ],
                      selected: {_boolValue},
                      onSelectionChanged: (s) =>
                          setState(() => _boolValue = s.first),
                    ),
                  ],
                )
              else
                TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: widget.kind == ColumnKind.json ? 6 : 1,
                  style: widget.kind == ColumnKind.json
                      ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Value',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-cell-edit-btn'),
          onPressed: () {
            Navigator.of(context).pop((_isNull, _parseValue()));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddRowDialog extends StatefulWidget {
  const _AddRowDialog({required this.columns});

  final List<ColumnDetails> columns;

  @override
  State<_AddRowDialog> createState() => _AddRowDialogState();
}

class _AddRowDialogState extends State<_AddRowDialog> {
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final c in widget.columns) {
      _controllers[c.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Row'),
      content: SizedBox(
        width: 480,
        height: 380,
        child: ListView(
          children: [
            for (final col in widget.columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _controllers[col.name],
                  decoration: InputDecoration(
                    labelText:
                        '${col.name} (${col.typeName})'
                        '${col.isPrimaryKey ? ' [PK]' : ''}'
                        '${col.nullable ? ' (nullable)' : ' *'}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-add-row-btn'),
          onPressed: () {
            final result = <String, Object?>{};
            for (final col in widget.columns) {
              final text = _controllers[col.name]?.text.trim() ?? '';
              if (text.isNotEmpty) {
                if (col.kind == ColumnKind.integer) {
                  result[col.name] = int.tryParse(text) ?? text;
                } else if (col.kind == ColumnKind.float ||
                    col.kind == ColumnKind.decimal) {
                  result[col.name] = double.tryParse(text) ?? text;
                } else if (col.kind == ColumnKind.boolean) {
                  result[col.name] = text.toLowerCase() == 'true';
                } else {
                  result[col.name] = text;
                }
              } else if (!col.nullable && col.defaultValue == null) {
                // Keep empty string
                result[col.name] = '';
              }
            }
            Navigator.of(context).pop(result);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
