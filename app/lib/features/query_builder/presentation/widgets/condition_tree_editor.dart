import 'package:flutter/material.dart';

import '../../domain/sql_query_models.dart';

enum LiteralKind { text, integer, decimal, boolean, nullValue }

class ConditionTreeEditor extends StatelessWidget {
  const ConditionTreeEditor({
    super.key,
    required this.keyPrefix,
    required this.root,
    required this.columns,
    required this.onChanged,
    this.allowAggregates = false,
    this.addLabel = 'Add condition',
  });

  final String keyPrefix;
  final SqlConditionNode? root;
  final List<SqlColumnRefModel> columns;
  final ValueChanged<SqlConditionNode?> onChanged;
  final bool allowAggregates;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final node = root;
    if (node == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: Key('$keyPrefix-add-condition'),
          onPressed: () => onChanged(_defaultComparison()),
          icon: const Icon(Icons.add, size: 16),
          label: Text(addLabel),
        ),
      );
    }
    return _NodeEditor(
      keyPrefix: keyPrefix,
      node: node,
      columns: columns,
      allowAggregates: allowAggregates,
      defaultComparison: _defaultComparison,
      onChanged: onChanged,
    );
  }

  SqlComparisonModel _defaultComparison() {
    final firstCol = columns.isNotEmpty
        ? columns.first
        : const SqlColumnRefModel(column: 'id');
    return SqlComparisonModel(
      left: SqlColumnOperand(firstCol),
      op: SqlOperatorKind.eq,
      operands: const [SqlLiteralOperand(SqlStringLiteral(''))],
    );
  }
}

class _NodeEditor extends StatelessWidget {
  const _NodeEditor({
    required this.keyPrefix,
    required this.node,
    required this.columns,
    required this.allowAggregates,
    required this.defaultComparison,
    required this.onChanged,
  });

  final String keyPrefix;
  final SqlConditionNode node;
  final List<SqlColumnRefModel> columns;
  final bool allowAggregates;
  final SqlComparisonModel Function() defaultComparison;
  final ValueChanged<SqlConditionNode?> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      final SqlComparisonModel cmp => _ComparisonRow(
        keyPrefix: keyPrefix,
        comparison: cmp,
        columns: columns,
        allowAggregates: allowAggregates,
        onChanged: onChanged,
      ),
      final SqlConditionGroupModel grp => _GroupEditor(
        keyPrefix: keyPrefix,
        group: grp,
        columns: columns,
        allowAggregates: allowAggregates,
        defaultComparison: defaultComparison,
        onChanged: onChanged,
      ),
    };
  }
}

class _GroupEditor extends StatelessWidget {
  const _GroupEditor({
    required this.keyPrefix,
    required this.group,
    required this.columns,
    required this.allowAggregates,
    required this.defaultComparison,
    required this.onChanged,
  });

  final String keyPrefix;
  final SqlConditionGroupModel group;
  final List<SqlColumnRefModel> columns;
  final bool allowAggregates;
  final SqlComparisonModel Function() defaultComparison;
  final ValueChanged<SqlConditionNode?> onChanged;

  void _updateChild(int index, SqlConditionNode? updated) {
    final next = [...group.children];
    if (updated == null) {
      next.removeAt(index);
    } else {
      next[index] = updated;
    }
    if (next.isEmpty) {
      onChanged(null);
    } else if (next.length == 1 && !group.negated) {
      onChanged(next.first);
    } else {
      onChanged(group.copyWith(children: next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: cs.primary, width: 2)),
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<SqlBoolOpKind>(
                key: Key('$keyPrefix-bool-op'),
                value: group.op,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  for (final op in SqlBoolOpKind.values)
                    DropdownMenuItem(value: op, child: Text(op.label)),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(group.copyWith(op: v));
                },
              ),
              FilterChip(
                key: Key('$keyPrefix-group-not'),
                label: const Text('NOT'),
                selected: group.negated,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => onChanged(group.copyWith(negated: v)),
              ),
              TextButton.icon(
                key: Key('$keyPrefix-group-add-cond'),
                onPressed: () => onChanged(
                  group.copyWith(
                    children: [...group.children, defaultComparison()],
                  ),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Condition'),
              ),
              TextButton.icon(
                key: Key('$keyPrefix-group-add-group'),
                onPressed: () {
                  final altOp = group.op == SqlBoolOpKind.and
                      ? SqlBoolOpKind.or
                      : SqlBoolOpKind.and;
                  onChanged(
                    group.copyWith(
                      children: [
                        ...group.children,
                        SqlConditionGroupModel(
                          op: altOp,
                          children: [defaultComparison()],
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.account_tree_outlined, size: 14),
                label: const Text('Group'),
              ),
              IconButton(
                key: Key('$keyPrefix-group-remove'),
                tooltip: 'Remove group',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onChanged(null),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < group.children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _NodeEditor(
              keyPrefix: '$keyPrefix-$i',
              node: group.children[i],
              columns: columns,
              allowAggregates: allowAggregates,
              defaultComparison: defaultComparison,
              onChanged: (updated) => _updateChild(i, updated),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.keyPrefix,
    required this.comparison,
    required this.columns,
    required this.allowAggregates,
    required this.onChanged,
  });

  final String keyPrefix;
  final SqlComparisonModel comparison;
  final List<SqlColumnRefModel> columns;
  final bool allowAggregates;
  final ValueChanged<SqlConditionNode?> onChanged;

  void _changeOperator(SqlOperatorKind nextOp) {
    final ops = switch (nextOp) {
      SqlOperatorKind.isNull => const <SqlOperandModel>[],
      SqlOperatorKind.between => [
        comparison.operands.isNotEmpty
            ? comparison.operands.first
            : const SqlLiteralOperand(SqlStringLiteral('')),
        comparison.operands.length >= 2
            ? comparison.operands[1]
            : const SqlLiteralOperand(SqlStringLiteral('')),
      ],
      SqlOperatorKind.inList =>
        comparison.operands.isNotEmpty
            ? comparison.operands
            : const [SqlLiteralOperand(SqlStringLiteral(''))],
      _ => [
        comparison.operands.isNotEmpty
            ? comparison.operands.first
            : const SqlLiteralOperand(SqlStringLiteral('')),
      ],
    };
    onChanged(comparison.copyWith(op: nextOp, operands: ops));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LeftOperandEditor(
            keyPrefix: keyPrefix,
            operand: comparison.left,
            columns: columns,
            allowAggregates: allowAggregates,
            onChanged: (left) => onChanged(comparison.copyWith(left: left)),
          ),
          FilterChip(
            key: Key('$keyPrefix-not'),
            label: const Text('NOT'),
            selected: comparison.negated,
            visualDensity: VisualDensity.compact,
            onSelected: (v) => onChanged(comparison.copyWith(negated: v)),
          ),
          DropdownButton<SqlOperatorKind>(
            key: Key('$keyPrefix-op'),
            value: comparison.op,
            isDense: true,
            items: [
              for (final op in SqlOperatorKind.values)
                DropdownMenuItem(value: op, child: Text(op.label)),
            ],
            onChanged: (v) {
              if (v != null) _changeOperator(v);
            },
          ),
          ..._buildRightOperands(),
          IconButton(
            key: Key('$keyPrefix-remove'),
            tooltip: 'Remove condition',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(Icons.close),
            onPressed: () => onChanged(null),
          ),
          IconButton(
            key: Key('$keyPrefix-wrap-and'),
            tooltip: 'Combine with AND',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(Icons.playlist_add),
            onPressed: () => onChanged(
              SqlConditionGroupModel(
                op: SqlBoolOpKind.and,
                children: [
                  comparison,
                  SqlComparisonModel(
                    left: comparison.left,
                    op: SqlOperatorKind.eq,
                    operands: const [SqlLiteralOperand(SqlStringLiteral(''))],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRightOperands() {
    switch (comparison.op) {
      case SqlOperatorKind.isNull:
        return const [];
      case SqlOperatorKind.between:
        final first = comparison.operands.isNotEmpty
            ? comparison.operands[0]
            : const SqlLiteralOperand(SqlStringLiteral(''));
        final second = comparison.operands.length >= 2
            ? comparison.operands[1]
            : const SqlLiteralOperand(SqlStringLiteral(''));
        return [
          _ValueOperandEditor(
            keyPrefix: '$keyPrefix-rhs-0',
            operand: first,
            columns: columns,
            onChanged: (v) => onChanged(comparison.copyWith(operands: [v, second])),
          ),
          const Text('AND'),
          _ValueOperandEditor(
            keyPrefix: '$keyPrefix-rhs-1',
            operand: second,
            columns: columns,
            onChanged: (v) => onChanged(comparison.copyWith(operands: [first, v])),
          ),
        ];
      case SqlOperatorKind.inList:
        return [
          _InListEditor(
            keyPrefix: '$keyPrefix-in',
            operands: comparison.operands,
            onChanged: (ops) => onChanged(comparison.copyWith(operands: ops)),
          ),
        ];
      default:
        final first = comparison.operands.isNotEmpty
            ? comparison.operands.first
            : const SqlLiteralOperand(SqlStringLiteral(''));
        return [
          _ValueOperandEditor(
            keyPrefix: '$keyPrefix-rhs',
            operand: first,
            columns: columns,
            onChanged: (v) => onChanged(comparison.copyWith(operands: [v])),
          ),
        ];
    }
  }
}

class _LeftOperandEditor extends StatelessWidget {
  const _LeftOperandEditor({
    required this.keyPrefix,
    required this.operand,
    required this.columns,
    required this.allowAggregates,
    required this.onChanged,
  });

  final String keyPrefix;
  final SqlOperandModel operand;
  final List<SqlColumnRefModel> columns;
  final bool allowAggregates;
  final ValueChanged<SqlOperandModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAgg = operand is SqlAggregateOperand;
    if (isAgg) {
      final agg = (operand as SqlAggregateOperand).aggregate;
      final colItems = _columnChoices(columns, agg.column, includeWildcard: agg.function == SqlAggregateFn.count);
      return Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<SqlAggregateFn>(
            key: Key('$keyPrefix-lhs-agg-fn'),
            value: agg.function,
            isDense: true,
            items: [
              for (final fn in SqlAggregateFn.values)
                DropdownMenuItem(value: fn, child: Text(fn.label)),
            ],
            onChanged: (fn) {
              if (fn != null) {
                onChanged(SqlAggregateOperand(agg.copyWith(function: fn)));
              }
            },
          ),
          DropdownButton<SqlColumnRefModel>(
            key: Key('$keyPrefix-lhs-agg-col'),
            value: agg.column,
            isDense: true,
            items: [
              for (final c in colItems)
                DropdownMenuItem(value: c, child: Text(c.display)),
            ],
            onChanged: (c) {
              if (c != null) {
                onChanged(SqlAggregateOperand(agg.copyWith(column: c)));
              }
            },
          ),
          if (allowAggregates)
            TextButton(
              onPressed: () => onChanged(
                SqlColumnOperand(
                  columns.isNotEmpty
                      ? columns.first
                      : const SqlColumnRefModel(column: 'id'),
                ),
              ),
              child: const Text('Col'),
            ),
        ],
      );
    }

    final current = operand is SqlColumnOperand
        ? (operand as SqlColumnOperand).column
        : const SqlColumnRefModel(column: 'id');
    final colItems = _columnChoices(columns, current);
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<SqlColumnRefModel>(
          key: Key('$keyPrefix-lhs-col'),
          value: current,
          isDense: true,
          items: [
            for (final c in colItems)
              DropdownMenuItem(value: c, child: Text(c.display)),
          ],
          onChanged: (c) {
            if (c != null) onChanged(SqlColumnOperand(c));
          },
        ),
        if (allowAggregates)
          TextButton(
            key: Key('$keyPrefix-lhs-to-agg'),
            onPressed: () => onChanged(
              const SqlAggregateOperand(
                SqlAggregateExprModel(function: SqlAggregateFn.count),
              ),
            ),
            child: const Text('Agg'),
          ),
      ],
    );
  }
}

class _ValueOperandEditor extends StatelessWidget {
  const _ValueOperandEditor({
    required this.keyPrefix,
    required this.operand,
    required this.columns,
    required this.onChanged,
  });

  final String keyPrefix;
  final SqlOperandModel operand;
  final List<SqlColumnRefModel> columns;
  final ValueChanged<SqlOperandModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCol = operand is SqlColumnOperand;
    if (isCol) {
      final current = (operand as SqlColumnOperand).column;
      final items = _columnChoices(columns, current);
      return Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            key: Key('$keyPrefix-mode'),
            value: 'col',
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'col', child: Text('Column')),
              DropdownMenuItem(value: 'lit', child: Text('Value')),
            ],
            onChanged: (mode) {
              if (mode == 'lit') {
                onChanged(const SqlLiteralOperand(SqlStringLiteral('')));
              }
            },
          ),
          DropdownButton<SqlColumnRefModel>(
            key: Key('$keyPrefix-col'),
            value: current,
            isDense: true,
            items: [
              for (final c in items)
                DropdownMenuItem(value: c, child: Text(c.display)),
            ],
            onChanged: (c) {
              if (c != null) onChanged(SqlColumnOperand(c));
            },
          ),
        ],
      );
    }

    final lit = operand is SqlLiteralOperand
        ? (operand as SqlLiteralOperand).literal
        : const SqlStringLiteral('');
    final kind = _kindOf(lit);
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<String>(
          key: Key('$keyPrefix-mode'),
          value: 'lit',
          isDense: true,
          items: [
            if (columns.isNotEmpty)
              const DropdownMenuItem(value: 'col', child: Text('Column')),
            const DropdownMenuItem(value: 'lit', child: Text('Value')),
          ],
          onChanged: (mode) {
            if (mode == 'col' && columns.isNotEmpty) {
              onChanged(SqlColumnOperand(columns.first));
            }
          },
        ),
        DropdownButton<LiteralKind>(
          key: Key('$keyPrefix-kind'),
          value: kind,
          isDense: true,
          items: const [
            DropdownMenuItem(value: LiteralKind.text, child: Text('Text')),
            DropdownMenuItem(value: LiteralKind.integer, child: Text('Int')),
            DropdownMenuItem(value: LiteralKind.decimal, child: Text('Float')),
            DropdownMenuItem(value: LiteralKind.boolean, child: Text('Bool')),
            DropdownMenuItem(value: LiteralKind.nullValue, child: Text('NULL')),
          ],
          onChanged: (nextKind) {
            if (nextKind == null) return;
            onChanged(SqlLiteralOperand(_convertLiteral(lit, nextKind)));
          },
        ),
        if (kind == LiteralKind.boolean)
          DropdownButton<bool>(
            key: Key('$keyPrefix-bool'),
            value: lit is SqlBoolLiteral && lit.value,
            isDense: true,
            items: const [
              DropdownMenuItem(value: true, child: Text('TRUE')),
              DropdownMenuItem(value: false, child: Text('FALSE')),
            ],
            onChanged: (b) {
              if (b != null) onChanged(SqlLiteralOperand(SqlBoolLiteral(b)));
            },
          )
        else if (kind != LiteralKind.nullValue)
          SizedBox(
            width: 140,
            child: SyncedTextField(
              fieldKey: Key('$keyPrefix-input'),
              value: _literalText(lit),
              hintText: 'value',
              onChanged: (raw) => onChanged(
                SqlLiteralOperand(_parseLiteralForKind(raw, kind)),
              ),
            ),
          ),
      ],
    );
  }
}

class _InListEditor extends StatelessWidget {
  const _InListEditor({
    required this.keyPrefix,
    required this.operands,
    required this.onChanged,
  });

  final String keyPrefix;
  final List<SqlOperandModel> operands;
  final ValueChanged<List<SqlOperandModel>> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = operands.map(_formatInToken).join(', ');
    return SizedBox(
      width: 210,
      child: SyncedTextField(
        fieldKey: Key('$keyPrefix-input'),
        value: text,
        hintText: 'a, b, 123',
        onChanged: (raw) {
          final parts = raw
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isEmpty) {
            onChanged(const [SqlLiteralOperand(SqlStringLiteral(''))]);
            return;
          }
          onChanged([
            for (final part in parts) SqlLiteralOperand(_smartLiteral(part)),
          ]);
        },
      ),
    );
  }

  String _formatInToken(SqlOperandModel op) {
    if (op is SqlColumnOperand) return op.column.display;
    if (op is SqlLiteralOperand) return _literalText(op.literal);
    return '';
  }

  SqlLiteralModel _smartLiteral(String raw) {
    final intVal = int.tryParse(raw);
    if (intVal != null) return SqlIntLiteral(intVal);
    final dblVal = double.tryParse(raw);
    if (dblVal != null) return SqlDoubleLiteral(dblVal);
    return SqlStringLiteral(raw);
  }
}

class SyncedTextField extends StatefulWidget {
  const SyncedTextField({
    super.key,
    this.fieldKey,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.labelText,
  });

  final Key? fieldKey;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? labelText;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
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
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        hintText: widget.hintText,
        labelText: widget.labelText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}

List<SqlColumnRefModel> _columnChoices(
  List<SqlColumnRefModel> available,
  SqlColumnRefModel current, {
  bool includeWildcard = false,
}) {
  final out = <SqlColumnRefModel>[
    if (includeWildcard) const SqlColumnRefModel(),
    ...available,
  ];
  if (!out.contains(current)) {
    out.add(current);
  }
  return out;
}

LiteralKind _kindOf(SqlLiteralModel lit) => switch (lit) {
  SqlNullLiteral() => LiteralKind.nullValue,
  SqlBoolLiteral() => LiteralKind.boolean,
  SqlIntLiteral() => LiteralKind.integer,
  SqlDoubleLiteral() => LiteralKind.decimal,
  SqlStringLiteral() => LiteralKind.text,
};

String _literalText(SqlLiteralModel lit) => switch (lit) {
  SqlNullLiteral() => 'NULL',
  SqlBoolLiteral(:final value) => value ? 'true' : 'false',
  SqlIntLiteral(:final value) => '$value',
  SqlDoubleLiteral(:final value) => '$value',
  SqlStringLiteral(:final value) => value,
};

SqlLiteralModel _convertLiteral(SqlLiteralModel lit, LiteralKind kind) =>
    _parseLiteralForKind(_literalText(lit), kind);

SqlLiteralModel _parseLiteralForKind(String raw, LiteralKind kind) => switch (
  kind
) {
  LiteralKind.nullValue => const SqlNullLiteral(),
  LiteralKind.boolean => SqlBoolLiteral(raw.toLowerCase() == 'true'),
  LiteralKind.integer => SqlIntLiteral(int.tryParse(raw.trim()) ?? 0),
  LiteralKind.decimal => SqlDoubleLiteral(double.tryParse(raw.trim()) ?? 0.0),
  LiteralKind.text => SqlStringLiteral(raw),
};
