import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schema/domain/schema_models.dart';
import '../application/designer_controller.dart';
import '../domain/design_models.dart';

List<String> splitNames(String text) => [
  for (final part in text.split(','))
    if (part.trim().isNotEmpty) part.trim(),
];

class ConstraintsSection extends ConsumerWidget {
  const ConstraintsSection({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designerProvider(tabId));
    final c = ref.read(designerProvider(tabId).notifier);
    final scheme = Theme.of(context).colorScheme;
    final dropped = state.constraints.dropped;
    final existing = state.original?.foreignKeys ?? const [];

    Widget header(String title, Key addKey, VoidCallback onAdd) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          TextButton.icon(
            key: addKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ],
      ),
    );

    Widget row(String text, Widget action, {bool struck = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                decoration: struck ? TextDecoration.lineThrough : null,
                color: struck ? scheme.outline : null,
              ),
            ),
          ),
          action,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          header(
            'Foreign keys',
            const Key('add-fk'),
            () => showDialog<void>(
              context: context,
              builder: (_) => _ForeignKeyDialog(onSave: c.addForeignKey),
            ),
          ),
          for (final fk in existing)
            dropped.contains(fk.name)
                ? row(
                    '${fk.name}  (${fk.columns.join(', ')}) → ${fk.referencedTable}',
                    TextButton(
                      key: Key('keep-fk-${fk.name}'),
                      onPressed: () => c.keepConstraint(fk.name),
                      child: const Text('Keep'),
                    ),
                    struck: true,
                  )
                : row(
                    '${fk.name}  (${fk.columns.join(', ')}) → ${fk.referencedTable} (${fk.referencedColumns.join(', ')})'
                    '${fk.onDelete == ReferentialAction.unspecified ? '' : '  ON DELETE ${fk.onDelete.label}'}'
                    '${fk.onUpdate == ReferentialAction.unspecified ? '' : '  ON UPDATE ${fk.onUpdate.label}'}',
                    IconButton(
                      key: Key('drop-fk-${fk.name}'),
                      tooltip: 'Drop foreign key',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => c.dropConstraint(fk.name),
                    ),
                  ),
          for (final (i, fk) in state.constraints.foreignKeys.indexed)
            row(
              'new  ${fk.name.isEmpty ? '' : '${fk.name}  '}${fk.summary}',
              IconButton(
                key: Key('remove-staged-fk-$i'),
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => c.removeStagedForeignKey(i),
              ),
            ),
          header(
            'Unique constraints',
            const Key('add-unique'),
            () => showDialog<void>(
              context: context,
              builder: (_) => _UniqueDialog(onSave: c.addUnique),
            ),
          ),
          for (final (i, u) in state.constraints.uniques.indexed)
            row(
              'new  ${u.name.isEmpty ? '' : '${u.name}  '}(${u.columns.join(', ')})',
              IconButton(
                key: Key('remove-staged-unique-$i'),
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => c.removeStagedUnique(i),
              ),
            ),
          header(
            'Check constraints',
            const Key('add-check'),
            () => showDialog<void>(
              context: context,
              builder: (_) => _CheckDialog(onSave: c.addCheck),
            ),
          ),
          for (final (i, ck) in state.constraints.checks.indexed)
            row(
              'new  ${ck.name.isEmpty ? '' : '${ck.name}  '}CHECK (${ck.expression})',
              IconButton(
                key: Key('remove-staged-check-$i'),
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => c.removeStagedCheck(i),
              ),
            ),
          if (!state.isNew)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Existing unique and check constraints are not listed here; unique indexes are in the Indexes section.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _field(Key key, String label, TextEditingController c, {String? hint}) =>
    TextField(
      key: key,
      controller: c,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );

List<Widget> _dialogActions(
  BuildContext context,
  Key saveKey,
  bool Function() valid,
  VoidCallback onSave,
) => [
  TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const Text('Cancel'),
  ),
  FilledButton(
    key: saveKey,
    onPressed: () {
      if (!valid()) return;
      onSave();
      Navigator.of(context).pop();
    },
    child: const Text('Add'),
  ),
];

class _ForeignKeyDialog extends StatefulWidget {
  const _ForeignKeyDialog({required this.onSave});

  final ValueChanged<ForeignKeyDraft> onSave;

  @override
  State<_ForeignKeyDialog> createState() => _ForeignKeyDialogState();
}

class _ForeignKeyDialogState extends State<_ForeignKeyDialog> {
  final _name = TextEditingController();
  final _columns = TextEditingController();
  final _schema = TextEditingController();
  final _table = TextEditingController();
  final _refColumns = TextEditingController();
  var _onDelete = ReferentialAction.unspecified;
  var _onUpdate = ReferentialAction.unspecified;

  @override
  void dispose() {
    for (final c in [_name, _columns, _schema, _table, _refColumns]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _actionPicker(
    Key key,
    String label,
    ReferentialAction value,
    ValueChanged<ReferentialAction> onChanged,
  ) => Row(
    children: [
      Expanded(child: Text(label)),
      DropdownButton<ReferentialAction>(
        key: key,
        value: value,
        items: [
          for (final a in ReferentialAction.values)
            DropdownMenuItem(value: a, child: Text(a.label)),
        ],
        onChanged: (v) => onChanged(v ?? ReferentialAction.unspecified),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add foreign key'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(const Key('fk-name'), 'Name (optional)', _name),
            _field(
              const Key('fk-columns'),
              'Columns in this table',
              _columns,
              hint: 'a, b',
            ),
            _field(
              const Key('fk-ref-schema'),
              'Referenced schema (optional)',
              _schema,
            ),
            _field(const Key('fk-ref-table'), 'Referenced table', _table),
            _field(
              const Key('fk-ref-columns'),
              'Referenced columns',
              _refColumns,
              hint: 'id',
            ),
            _actionPicker(
              const Key('fk-on-delete'),
              'On delete',
              _onDelete,
              (v) => setState(() => _onDelete = v),
            ),
            _actionPicker(
              const Key('fk-on-update'),
              'On update',
              _onUpdate,
              (v) => setState(() => _onUpdate = v),
            ),
          ],
        ),
      ),
    ),
    actions: _dialogActions(
      context,
      const Key('fk-save'),
      () {
        final cols = splitNames(_columns.text);
        return cols.isNotEmpty &&
            cols.length == splitNames(_refColumns.text).length &&
            _table.text.trim().isNotEmpty;
      },
      () => widget.onSave(
        ForeignKeyDraft(
          name: _name.text.trim(),
          columns: splitNames(_columns.text),
          referencedSchema: _schema.text.trim(),
          referencedTable: _table.text.trim(),
          referencedColumns: splitNames(_refColumns.text),
          onDelete: _onDelete,
          onUpdate: _onUpdate,
        ),
      ),
    ),
  );
}

class _UniqueDialog extends StatefulWidget {
  const _UniqueDialog({required this.onSave});

  final ValueChanged<UniqueDraft> onSave;

  @override
  State<_UniqueDialog> createState() => _UniqueDialogState();
}

class _UniqueDialogState extends State<_UniqueDialog> {
  final _name = TextEditingController();
  final _columns = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _columns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add unique constraint'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(const Key('unique-name'), 'Name (optional)', _name),
          _field(
            const Key('unique-columns'),
            'Columns',
            _columns,
            hint: 'a, b',
          ),
        ],
      ),
    ),
    actions: _dialogActions(
      context,
      const Key('unique-save'),
      () => splitNames(_columns.text).isNotEmpty,
      () => widget.onSave(
        UniqueDraft(
          name: _name.text.trim(),
          columns: splitNames(_columns.text),
        ),
      ),
    ),
  );
}

class _CheckDialog extends StatefulWidget {
  const _CheckDialog({required this.onSave});

  final ValueChanged<CheckDraft> onSave;

  @override
  State<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends State<_CheckDialog> {
  final _name = TextEditingController();
  final _expression = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _expression.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add check constraint'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(const Key('check-name'), 'Name (optional)', _name),
          _field(
            const Key('check-expression'),
            'Expression',
            _expression,
            hint: 'price > 0',
          ),
        ],
      ),
    ),
    actions: _dialogActions(
      context,
      const Key('check-save'),
      () => _expression.text.trim().isNotEmpty,
      () => widget.onSave(
        CheckDraft(
          name: _name.text.trim(),
          expression: _expression.text.trim(),
        ),
      ),
    ),
  );
}
