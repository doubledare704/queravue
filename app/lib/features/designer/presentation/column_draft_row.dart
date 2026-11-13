import 'package:flutter/material.dart';

import '../domain/design_models.dart';

/// One editable column: name, type, default, nullable, key and auto-increment.
class ColumnDraftRow extends StatelessWidget {
  const ColumnDraftRow({
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
