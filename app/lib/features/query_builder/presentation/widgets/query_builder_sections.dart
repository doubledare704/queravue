import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../schema/domain/schema_models.dart';
import '../../application/sql_query_builder_controller.dart';
import '../../domain/sql_query_models.dart';
import 'condition_tree_editor.dart';

class FromAndJoinsSection extends StatelessWidget {
  const FromAndJoinsSection({
    super.key,
    required this.state,
    required this.controller,
    required this.allColumns,
  });

  final SqlQueryBuilderState state;
  final SqlQueryBuilderController controller;
  final List<SqlColumnRefModel> allColumns;

  @override
  Widget build(BuildContext context) {
    final from = state.draft.from;
    final fromKey = from == null || from.table.isEmpty
        ? null
        : (schema: from.schema, table: from.table);
    final tableChoices = _tableChoices(state.availableTables, fromKey);

    return _SectionCard(
      title: 'Tables & Joins',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'FROM table',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<({String schema, String table})>(
                      key: const Key('qb-from-table-picker'),
                      value: fromKey,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text('Select table'),
                      items: [
                        for (final t in tableChoices)
                          DropdownMenuItem(
                            value: (schema: t.schema, table: t.table),
                            child: Text(
                              t.qualifiedName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (picked) {
                        if (picked != null) {
                          controller.setFromTable(
                            TableRef(
                              schema: picked.schema,
                              table: picked.table,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: SyncedTextField(
                  fieldKey: const Key('qb-from-alias'),
                  value: from?.alias ?? '',
                  labelText: 'Alias',
                  hintText: 't',
                  onChanged: controller.setFromAlias,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('qb-add-join-button'),
                onPressed: from == null || from.table.isEmpty
                    ? null
                    : () => _addDefaultJoin(tableChoices),
                icon: const Icon(Icons.join_inner, size: 16),
                label: const Text('Add join'),
              ),
            ],
          ),
          if (state.joinSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Foreign-key join suggestions',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final s in state.joinSuggestions)
                  ActionChip(
                    key: Key('qb-fk-suggestion-${s.constraintName}'),
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text(s.displayLabel),
                    onPressed: () => controller.applyJoinSuggestion(s),
                  ),
              ],
            ),
          ],
          for (var i = 0; i < state.draft.joins.length; i++) ...[
            const SizedBox(height: 10),
            _JoinCard(
              index: i,
              join: state.draft.joins[i],
              availableTables: state.availableTables,
              allColumns: allColumns,
              onChanged: (j) => controller.updateJoin(i, j),
              onRemove: () => controller.removeJoin(i),
            ),
          ],
        ],
      ),
    );
  }

  void _addDefaultJoin(List<TableRef> tableChoices) {
    final fallback = tableChoices.isNotEmpty
        ? tableChoices.first
        : TableRef(
            schema: state.draft.from?.schema ?? '',
            table: state.draft.from?.table ?? 'table',
          );
    final alias = 'j${state.draft.joins.length + 1}';
    final leftCol = allColumns.isNotEmpty
        ? allColumns.first
        : const SqlColumnRefModel(column: 'id');
    controller.addJoin(
      SqlJoinModel(
        kind: SqlJoinKindModel.inner,
        table: SqlTableRefModel(
          schema: fallback.schema,
          table: fallback.table,
          alias: alias,
        ),
        on: SqlComparisonModel(
          left: SqlColumnOperand(leftCol),
          op: SqlOperatorKind.eq,
          operands: [
            SqlColumnOperand(
              SqlColumnRefModel(tableAlias: alias, column: 'id'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.index,
    required this.join,
    required this.availableTables,
    required this.allColumns,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final SqlJoinModel join;
  final List<TableRef> availableTables;
  final List<SqlColumnRefModel> allColumns;
  final ValueChanged<SqlJoinModel> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final currentKey = (schema: join.table.schema, table: join.table.table);
    final tableChoices = _tableChoices(availableTables, currentKey);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<SqlJoinKindModel>(
                key: Key('qb-join-kind-$index'),
                value: join.kind,
                isDense: true,
                items: [
                  for (final k in SqlJoinKindModel.values)
                    DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: (k) {
                  if (k != null) onChanged(join.copyWith(kind: k));
                },
              ),
              SizedBox(
                width: 210,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<({String schema, String table})>(
                      key: Key('qb-join-table-$index'),
                      value: currentKey,
                      isExpanded: true,
                      isDense: true,
                      items: [
                        for (final t in tableChoices)
                          DropdownMenuItem(
                            value: (schema: t.schema, table: t.table),
                            child: Text(
                              t.qualifiedName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (t) {
                        if (t != null) {
                          onChanged(
                            join.copyWith(
                              table: join.table.copyWith(
                                schema: t.schema,
                                table: t.table,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: SyncedTextField(
                  fieldKey: Key('qb-join-alias-$index'),
                  value: join.table.alias,
                  labelText: 'Alias',
                  onChanged: (alias) => onChanged(
                    join.copyWith(table: join.table.copyWith(alias: alias)),
                  ),
                ),
              ),
              IconButton(
                key: Key('qb-join-remove-$index'),
                tooltip: 'Remove join',
                iconSize: 18,
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConditionTreeEditor(
            keyPrefix: 'qb-join-$index-on',
            root: join.on,
            columns: allColumns,
            onChanged: (cond) {
              if (cond != null) onChanged(join.copyWith(on: cond));
            },
          ),
        ],
      ),
    );
  }
}

class SelectSection extends StatelessWidget {
  const SelectSection({
    super.key,
    required this.state,
    required this.controller,
    required this.allColumns,
  });

  final SqlQueryBuilderState state;
  final SqlQueryBuilderController controller;
  final List<SqlColumnRefModel> allColumns;

  @override
  Widget build(BuildContext context) {
    final items = state.draft.select;
    return _SectionCard(
      title: 'Columns & Aggregates (SELECT)',
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('qb-add-column-button'),
            onPressed: () {
              final first = allColumns.isNotEmpty
                  ? allColumns.first
                  : const SqlColumnRefModel();
              controller.addSelectItem(SqlSelectItemModel.column(first));
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Column'),
          ),
          OutlinedButton.icon(
            key: const Key('qb-add-aggregate-button'),
            onPressed: () => controller.addSelectItem(
              const SqlSelectItemModel.aggregate(
                SqlAggregateExprModel(function: SqlAggregateFn.count),
              ),
            ),
            icon: const Icon(Icons.functions, size: 16),
            label: const Text('Aggregate'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allColumns.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final col in allColumns)
                  FilterChip(
                    key: Key('qb-col-chip-${col.display}'),
                    label: Text(col.display),
                    selected: items.any((s) => !s.isAggregate && s.column == col),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => controller.toggleColumnSelect(col),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (items.isEmpty)
            Text(
              'All columns (*) selected.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _SelectItemRow(
                index: i,
                item: items[i],
                columns: allColumns,
                onChanged: (updated) => controller.updateSelectItem(i, updated),
                onRemove: () => controller.removeSelectItem(i),
              ),
            ],
        ],
      ),
    );
  }
}

class _SelectItemRow extends StatelessWidget {
  const _SelectItemRow({
    required this.index,
    required this.item,
    required this.columns,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final SqlSelectItemModel item;
  final List<SqlColumnRefModel> columns;
  final ValueChanged<SqlSelectItemModel> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final agg = item.aggregate;
    if (agg != null) {
      final choices = [
        if (agg.function == SqlAggregateFn.count) const SqlColumnRefModel(),
        ...columns,
        if (!columns.contains(agg.column) && agg.column.column.isNotEmpty)
          agg.column,
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<SqlAggregateFn>(
            key: Key('qb-select-agg-fn-$index'),
            value: agg.function,
            isDense: true,
            items: [
              for (final fn in SqlAggregateFn.values)
                DropdownMenuItem(value: fn, child: Text(fn.label)),
            ],
            onChanged: (fn) {
              if (fn != null) {
                var col = agg.column;
                var distinct = agg.distinct;
                if (fn != SqlAggregateFn.count && col.column.isEmpty) {
                  col = columns.isNotEmpty
                      ? columns.first
                      : const SqlColumnRefModel(column: 'id');
                }
                if (col.column.isEmpty) distinct = false;
                onChanged(
                  item.copyWith(
                    aggregate: agg.copyWith(
                      function: fn,
                      column: col,
                      distinct: distinct,
                    ),
                  ),
                );
              }
            },
          ),
          DropdownButton<SqlColumnRefModel>(
            key: Key('qb-select-agg-col-$index'),
            value: agg.column,
            isDense: true,
            items: [
              for (final c in choices)
                DropdownMenuItem(value: c, child: Text(c.display)),
            ],
            onChanged: (c) {
              if (c != null) {
                onChanged(
                  item.copyWith(
                    aggregate: agg.copyWith(
                      column: c,
                      distinct: c.column.isEmpty ? false : agg.distinct,
                    ),
                  ),
                );
              }
            },
          ),
          if (agg.column.column.isNotEmpty)
            FilterChip(
              key: Key('qb-select-agg-distinct-$index'),
              label: const Text('DISTINCT'),
              selected: agg.distinct,
              visualDensity: VisualDensity.compact,
              onSelected: (v) =>
                  onChanged(item.copyWith(aggregate: agg.copyWith(distinct: v))),
            ),
          SizedBox(
            width: 130,
            child: SyncedTextField(
              fieldKey: Key('qb-select-alias-$index'),
              value: item.alias,
              hintText: 'AS alias',
              onChanged: (alias) => onChanged(item.copyWith(alias: alias)),
            ),
          ),
          IconButton(
            key: Key('qb-select-remove-$index'),
            tooltip: 'Remove column',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      );
    }

    final col = item.column ?? const SqlColumnRefModel();
    final choices = [
      const SqlColumnRefModel(),
      ...columns,
      if (!columns.contains(col) && col.column.isNotEmpty) col,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<SqlColumnRefModel>(
          key: Key('qb-select-col-$index'),
          value: col,
          isDense: true,
          items: [
            for (final c in choices)
              DropdownMenuItem(value: c, child: Text(c.display)),
          ],
          onChanged: (c) {
            if (c != null) {
              onChanged(
                SqlSelectItemModel.column(
                  c,
                  alias: c.column.isEmpty ? '' : item.alias,
                ),
              );
            }
          },
        ),
        if (col.column.isNotEmpty)
          SizedBox(
            width: 130,
            child: SyncedTextField(
              fieldKey: Key('qb-select-alias-$index'),
              value: item.alias,
              hintText: 'AS alias',
              onChanged: (alias) => onChanged(item.copyWith(alias: alias)),
            ),
          ),
        IconButton(
          key: Key('qb-select-remove-$index'),
          tooltip: 'Remove column',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class GroupHavingSection extends StatelessWidget {
  const GroupHavingSection({
    super.key,
    required this.state,
    required this.controller,
    required this.allColumns,
  });

  final SqlQueryBuilderState state;
  final SqlQueryBuilderController controller;
  final List<SqlColumnRefModel> allColumns;

  @override
  Widget build(BuildContext context) {
    final groupBy = state.draft.groupBy;
    final availableForGroup = [
      for (final c in allColumns)
        if (!groupBy.contains(c)) c,
    ];
    return _SectionCard(
      title: 'GROUP BY & HAVING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < groupBy.length; i++)
                InputChip(
                  key: Key('qb-group-by-chip-$i'),
                  label: Text(groupBy[i].display),
                  onDeleted: () => controller.removeGroupBy(i),
                ),
              if (availableForGroup.isNotEmpty)
                PopupMenuButton<SqlColumnRefModel>(
                  key: const Key('qb-add-group-by-button'),
                  tooltip: 'Add GROUP BY column',
                  onSelected: controller.addGroupBy,
                  itemBuilder: (_) => [
                    for (final c in availableForGroup)
                      PopupMenuItem(value: c, child: Text(c.display)),
                  ],
                  child: const Chip(
                    avatar: Icon(Icons.add, size: 16),
                    label: Text('Group column'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ConditionTreeEditor(
            keyPrefix: 'qb-having',
            root: state.draft.having,
            columns: allColumns,
            allowAggregates: true,
            addLabel: 'Add HAVING condition',
            onChanged: controller.setHaving,
          ),
        ],
      ),
    );
  }
}

class OrderLimitSection extends StatelessWidget {
  const OrderLimitSection({
    super.key,
    required this.state,
    required this.controller,
    required this.allColumns,
  });

  final SqlQueryBuilderState state;
  final SqlQueryBuilderController controller;
  final List<SqlColumnRefModel> allColumns;

  @override
  Widget build(BuildContext context) {
    final orderBy = state.draft.orderBy;
    return _SectionCard(
      title: 'ORDER BY, LIMIT & OFFSET',
      trailing: OutlinedButton.icon(
        key: const Key('qb-add-order-button'),
        onPressed: () {
          final first = allColumns.isNotEmpty
              ? allColumns.first
              : const SqlColumnRefModel(column: 'id');
          controller.addOrderTerm(
            SqlOrderTermModel(expression: SqlColumnOperand(first)),
          );
        },
        icon: const Icon(Icons.sort, size: 16),
        label: const Text('Add sort'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < orderBy.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _OrderTermRow(
              index: i,
              term: orderBy[i],
              columns: allColumns,
              onChanged: (t) => controller.updateOrderTerm(i, t),
              onRemove: () => controller.removeOrderTerm(i),
            ),
          ],
          if (orderBy.isNotEmpty) const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 130,
                child: _NumericField(
                  fieldKey: const Key('qb-limit-field'),
                  label: 'LIMIT',
                  value: state.draft.limit,
                  onChanged: controller.setLimit,
                ),
              ),
              SizedBox(
                width: 130,
                child: _NumericField(
                  fieldKey: const Key('qb-offset-field'),
                  label: 'OFFSET',
                  value: state.draft.offset,
                  onChanged: controller.setOffset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTermRow extends StatelessWidget {
  const _OrderTermRow({
    required this.index,
    required this.term,
    required this.columns,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final SqlOrderTermModel term;
  final List<SqlColumnRefModel> columns;
  final ValueChanged<SqlOrderTermModel> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final expr = term.expression;
    final currentCol = expr is SqlColumnOperand
        ? expr.column
        : const SqlColumnRefModel(column: 'id');
    final colChoices = [
      ...columns,
      if (!columns.contains(currentCol)) currentCol,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (expr is SqlAggregateOperand)
          Chip(label: Text(expr.aggregate.display))
        else
          DropdownButton<SqlColumnRefModel>(
            key: Key('qb-order-col-$index'),
            value: currentCol,
            isDense: true,
            items: [
              for (final c in colChoices)
                DropdownMenuItem(value: c, child: Text(c.display)),
            ],
            onChanged: (c) {
              if (c != null) {
                onChanged(term.copyWith(expression: SqlColumnOperand(c)));
              }
            },
          ),
        DropdownButton<bool>(
          key: Key('qb-order-dir-$index'),
          value: term.descending,
          isDense: true,
          items: const [
            DropdownMenuItem(value: false, child: Text('ASC')),
            DropdownMenuItem(value: true, child: Text('DESC')),
          ],
          onChanged: (desc) {
            if (desc != null) onChanged(term.copyWith(descending: desc));
          },
        ),
        DropdownButton<SqlNullsPlacement>(
          key: Key('qb-order-nulls-$index'),
          value: term.nulls,
          isDense: true,
          items: [
            for (final n in SqlNullsPlacement.values)
              DropdownMenuItem(value: n, child: Text(n.label)),
          ],
          onChanged: (n) {
            if (n != null) onChanged(term.copyWith(nulls: n));
          },
        ),
        IconButton(
          key: Key('qb-order-remove-$index'),
          tooltip: 'Remove sort term',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _NumericField extends StatefulWidget {
  const _NumericField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == null ? '' : '${widget.value}',
    );
  }

  @override
  void didUpdateWidget(_NumericField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.value == null ? '' : '${widget.value}';
    if (nextText != _controller.text &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (raw) => widget.onChanged(int.tryParse(raw)),
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

List<TableRef> _tableChoices(
  List<TableRef> available,
  ({String schema, String table})? current,
) {
  final out = <TableRef>[];
  final seen = <({String schema, String table})>{};
  for (final t in available) {
    final key = (schema: t.schema, table: t.table);
    if (seen.add(key)) {
      out.add(TableRef(schema: t.schema, table: t.table));
    }
  }
  if (current != null && current.table.isNotEmpty && seen.add(current)) {
    out.add(TableRef(schema: current.schema, table: current.table));
  }
  return out;
}
