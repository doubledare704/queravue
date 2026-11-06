import 'package:flutter/material.dart';

import '../../schema/domain/schema_models.dart';
import '../domain/table_models.dart';

/// Filter bar widget: builder UI for column predicates, generated WHERE preview,
/// and a raw WHERE escape hatch with a warning.
class FilterBar extends StatefulWidget {
  const FilterBar({
    super.key,
    required this.filter,
    required this.columns,
    required this.onApply,
    required this.onClear,
  });

  final TableFilter filter;
  final List<ColumnDetails> columns;
  final ValueChanged<TableFilter> onApply;
  final VoidCallback onClear;

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  bool _expanded = false;
  bool _rawMode = false;
  late TextEditingController _rawController;
  late LogicalOp _groupOp;
  late List<_DraftCondition> _conditions;

  @override
  void initState() {
    super.initState();
    _rawMode = widget.filter.rawWhere.trim().isNotEmpty;
    _rawController = TextEditingController(text: widget.filter.rawWhere);
    _groupOp = widget.filter.root.op;
    _conditions = [
      for (final c in widget.filter.root.conditions)
        _DraftCondition(
          column: c.column,
          op: c.op,
          value1: c.values.isNotEmpty ? c.values[0] : '',
          value2: c.values.length > 1 ? c.values[1] : '',
        ),
    ];
  }

  @override
  void didUpdateWidget(FilterBar old) {
    super.didUpdateWidget(old);
    if (widget.filter != old.filter) {
      _rawMode = widget.filter.rawWhere.trim().isNotEmpty;
      _rawController.text = widget.filter.rawWhere;
      _groupOp = widget.filter.root.op;
      _conditions = [
        for (final c in widget.filter.root.conditions)
          _DraftCondition(
            column: c.column,
            op: c.op,
            value1: c.values.isNotEmpty ? c.values[0] : '',
            value2: c.values.length > 1 ? c.values[1] : '',
          ),
      ];
    }
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  TableFilter _buildFilter() {
    if (_rawMode) {
      return TableFilter(rawWhere: _rawController.text.trim());
    }
    final conds = <FilterCondition>[];
    for (final c in _conditions) {
      if (c.column.isEmpty) continue;
      final vals = <String>[];
      if (c.op.requiresNoValue) {
        // no values
      } else if (c.op.requiresTwoValues) {
        vals.addAll([c.value1, c.value2]);
      } else if (c.op.requiresList) {
        vals.addAll(
          c.value1.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      } else {
        vals.add(c.value1);
      }
      conds.add(FilterCondition(column: c.column, op: c.op, values: vals));
    }
    return TableFilter(
      root: FilterGroup(op: _groupOp, conditions: conds),
    );
  }

  void _apply() {
    widget.onApply(_buildFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wherePreview = widget.filter.toWherePreview();
    final hasActiveFilter = !widget.filter.isEmpty;

    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('filter-expand-btn'),
                  icon: Icon(
                    _expanded ? Icons.filter_list_off : Icons.filter_list,
                    size: 18,
                    color: hasActiveFilter
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  tooltip: _expanded ? 'Hide filter builder' : 'Filter builder',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    key: const Key('filter-preview-chip'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hasActiveFilter
                            ? scheme.primary.withValues(alpha: 0.5)
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'WHERE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasActiveFilter
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            wherePreview.isEmpty ? '(No filter)' : wherePreview,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: wherePreview.isEmpty
                                  ? scheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    )
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                        if (hasActiveFilter)
                          IconButton(
                            key: const Key('filter-clear-btn'),
                            icon: const Icon(Icons.close, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            tooltip: 'Clear filter',
                            onPressed: () {
                              setState(() {
                                _conditions.clear();
                                _rawController.clear();
                              });
                              widget.onClear();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: const Key('filter-apply-btn'),
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(60, 28),
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: scheme.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Filter Builder', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Row(
                        children: [
                          const Text(
                            'Raw WHERE:',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            key: const Key('filter-raw-switch'),
                            value: _rawMode,
                            onChanged: (v) => setState(() => _rawMode = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_rawMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: Raw WHERE queries bypass parameter binding and can be vulnerable to SQL injection.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('filter-raw-input'),
                      controller: _rawController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. status = \'active\' AND total > 100',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    if (_conditions.isNotEmpty)
                      Row(
                        children: [
                          const Text('Match: ', style: TextStyle(fontSize: 12)),
                          SegmentedButton<LogicalOp>(
                            segments: const [
                              ButtonSegment(
                                value: LogicalOp.and,
                                label: Text('AND (All)'),
                              ),
                              ButtonSegment(
                                value: LogicalOp.or,
                                label: Text('OR (Any)'),
                              ),
                            ],
                            selected: {_groupOp},
                            onSelectionChanged: (s) =>
                                setState(() => _groupOp = s.first),
                            style: SegmentedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 11),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _conditions.length; i++)
                      _buildConditionRow(context, i, _conditions[i]),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('filter-add-cond-btn'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add condition',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            final defaultCol = widget.columns.isNotEmpty
                                ? widget.columns.first.name
                                : '';
                            _conditions.add(
                              _DraftCondition(column: defaultCol),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionRow(
    BuildContext context,
    int index,
    _DraftCondition cond,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cols = widget.columns.map((c) => c.name).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Column dropdown
          SizedBox(
            width: 140,
            height: 32,
            child: DropdownButtonFormField<String>(
              key: Key('filter-col-$index'),
              initialValue: cols.contains(cond.column)
                  ? cond.column
                  : (cols.isNotEmpty ? cols.first : ''),
              isExpanded: true,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final c in cols)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => cond.column = v);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Operator dropdown
          SizedBox(
            width: 130,
            height: 32,
            child: DropdownButtonFormField<FilterOp>(
              key: Key('filter-op-$index'),
              initialValue: cond.op,
              isExpanded: true,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final op in FilterOp.values)
                  DropdownMenuItem(value: op, child: Text(op.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => cond.op = v);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Value inputs
          if (cond.op.requiresNoValue)
            const Expanded(child: SizedBox.shrink())
          else if (cond.op.requiresTwoValues) ...[
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextFormField(
                  key: Key('filter-val1-$index'),
                  initialValue: cond.value1,
                  style: theme.textTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'From',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => cond.value1 = v,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextFormField(
                  key: Key('filter-val2-$index'),
                  initialValue: cond.value2,
                  style: theme.textTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'To',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => cond.value2 = v,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextFormField(
                  key: Key('filter-val1-$index'),
                  initialValue: cond.value1,
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: cond.op.requiresList
                        ? 'val1, val2, ...'
                        : 'Value',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => cond.value1 = v,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            key: Key('filter-del-$index'),
            icon: Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: scheme.error,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Remove condition',
            onPressed: () {
              setState(() => _conditions.removeAt(index));
            },
          ),
        ],
      ),
    );
  }
}

class _DraftCondition {
  _DraftCondition({
    required this.column,
    this.op = FilterOp.equals,
    this.value1 = '',
    this.value2 = '',
  });

  String column;
  FilterOp op;
  String value1;
  String value2;
}
