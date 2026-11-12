import 'package:flutter/material.dart';

import '../../designer/domain/design_models.dart';
import '../../designer/presentation/column_draft_row.dart';
import '../../schema/domain/schema_models.dart';
import '../domain/diagram_draft.dart';
import '../domain/diagram_models.dart';

const _newTableColumns = [
  ColumnDraft(
    name: 'id',
    typeName: 'integer',
    nullable: false,
    primaryKey: true,
  ),
];

/// Asks for a drafted table's name and columns; null when cancelled.
/// [taken] holds the names of the other tables on the diagram.
Future<DraftTable?> showDraftTableDialog(
  BuildContext context, {
  DraftTable? initial,
  required Set<String> taken,
}) => showDialog<DraftTable>(
  context: context,
  builder: (_) => _DraftTableDialog(initial: initial, taken: taken),
);

class _DraftTableDialog extends StatefulWidget {
  const _DraftTableDialog({required this.initial, required this.taken});

  final DraftTable? initial;
  final Set<String> taken;

  @override
  State<_DraftTableDialog> createState() => _DraftTableDialogState();
}

class _DraftTableDialogState extends State<_DraftTableDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late List<ColumnDraft> _columns = [
    ...widget.initial?.columns ?? _newTableColumns,
  ];
  // Rows keep their own text, so a removed row must not hand it to the next.
  late List<int> _rowIds = [for (var i = 0; i < _columns.length; i++) i];
  late int _nextRowId = _columns.length;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final table = DraftTable(
      name: _name.text.trim(),
      columns: [
        for (final c in _columns)
          c.copyWith(name: c.name.trim(), typeName: c.typeName.trim()),
      ],
    );
    final problem = draftTableProblem(table, widget.taken);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    Navigator.of(context).pop(table);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.initial == null ? 'New table' : 'Edit table'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                key: const Key('draft-table-name'),
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Table name'),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < _columns.length; i++)
                    ColumnDraftRow(
                      key: ValueKey('draft-col-${_rowIds[i]}'),
                      index: i,
                      column: _columns[i],
                      existing: false,
                      onChanged: (c) =>
                          setState(() => _columns = [..._columns]..[i] = c),
                      onRemove: () => setState(() {
                        _columns = [..._columns]..removeAt(i);
                        _rowIds = [..._rowIds]..removeAt(i);
                      }),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('draft-add-column'),
                onPressed: () => setState(() {
                  _columns = [
                    ..._columns,
                    const ColumnDraft(name: '', typeName: 'text'),
                  ];
                  _rowIds = [..._rowIds, _nextRowId++];
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add column'),
              ),
            ),
            if (_problem != null)
              Text(
                _problem!,
                key: const Key('draft-table-problem'),
                style: TextStyle(color: scheme.error, fontSize: 12),
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
          key: const Key('draft-table-save'),
          onPressed: _save,
          child: Text(widget.initial == null ? 'Add to diagram' : 'Save'),
        ),
      ],
    );
  }
}

/// Asks which table [from] references and what happens on delete; null
/// when cancelled. [takenNames] holds the constraint names already drawn.
Future<DraftRelation?> showDraftRelationDialog(
  BuildContext context, {
  required DiagramTable from,
  required List<DiagramTable> targets,
  required Set<String> takenNames,
}) => showDialog<DraftRelation>(
  context: context,
  builder: (_) => _DraftRelationDialog(
    from: from,
    targets: targets,
    takenNames: takenNames,
  ),
);

class _DraftRelationDialog extends StatefulWidget {
  const _DraftRelationDialog({
    required this.from,
    required this.targets,
    required this.takenNames,
  });

  final DiagramTable from;
  final List<DiagramTable> targets;
  final Set<String> takenNames;

  @override
  State<_DraftRelationDialog> createState() => _DraftRelationDialogState();
}

class _DraftRelationDialogState extends State<_DraftRelationDialog> {
  DiagramTable? _target;
  ReferentialAction _onDelete = ReferentialAction.unspecified;

  String? get _problem => _target == null ? null : referenceProblem(_target!);

  DraftRelation? get _relation => _target == null || _problem != null
      ? null
      : suggestRelation(
          widget.from,
          _target!,
          takenNames: widget.takenNames,
          onDelete: _onDelete,
        );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final relation = _relation;
    final added = relation?.newColumn;
    return AlertDialog(
      title: Text('Relation from ${widget.from.name}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownMenu<String>(
              key: const Key('draft-relation-target'),
              width: 420,
              label: const Text('References'),
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 320,
              onSelected: (name) => setState(
                () => _target = widget.targets
                    .where((t) => t.name == name)
                    .firstOrNull,
              ),
              dropdownMenuEntries: [
                for (final t in widget.targets)
                  DropdownMenuEntry(value: t.name, label: t.name),
              ],
            ),
            const SizedBox(height: 12),
            DropdownMenu<ReferentialAction>(
              key: const Key('draft-relation-on-delete'),
              width: 420,
              label: const Text('On delete'),
              initialSelection: _onDelete,
              onSelected: (a) => setState(
                () => _onDelete = a ?? ReferentialAction.unspecified,
              ),
              dropdownMenuEntries: [
                for (final a in ReferentialAction.values)
                  DropdownMenuEntry(
                    value: a,
                    label: a == ReferentialAction.unspecified
                        ? 'Server default'
                        : a.label,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_problem != null)
              Text(
                _problem!,
                key: const Key('draft-relation-problem'),
                style: TextStyle(color: scheme.error, fontSize: 12),
              )
            else if (relation != null)
              Text(
                added != null
                    ? 'Adds column ${added.name} ${added.typeName} to ${widget.from.name}, '
                          'referencing ${relation.toTable}.${relation.toColumn}.'
                    : 'Uses column ${relation.column} of ${widget.from.name}, '
                          'referencing ${relation.toTable}.${relation.toColumn}.',
                key: const Key('draft-relation-summary'),
                style: const TextStyle(fontSize: 12),
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
          key: const Key('draft-relation-add'),
          onPressed: relation == null
              ? null
              : () => Navigator.of(context).pop(relation),
          child: const Text('Add relation'),
        ),
      ],
    );
  }
}
