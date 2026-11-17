import 'package:flutter/material.dart';

import '../domain/stage_forms.dart';
import 'form_cells.dart';

class StageFormView extends StatelessWidget {
  const StageFormView({
    super.key,
    required this.stageId,
    required this.form,
    required this.onChanged,
    required this.fieldNames,
    required this.collectionNames,
  });

  final int stageId;
  final StageForm form;
  final ValueChanged<StageForm> onChanged;
  final List<String> fieldNames;
  final List<String> collectionNames;

  @override
  Widget build(BuildContext context) => switch (form) {
    final CountLimitForm f => SizedBox(
      width: 160,
      child: TextCell(
        key: ValueKey('$stageId-n'),
        initial: '${f.value}',
        label: 'Number',
        onChanged: (t) =>
            onChanged(CountLimitForm(int.tryParse(t.trim()) ?? f.value)),
      ),
    ),
    final CountForm f => SizedBox(
      width: 220,
      child: TextCell(
        key: ValueKey('$stageId-count'),
        initial: f.field,
        label: 'Output field',
        onChanged: (t) => onChanged(CountForm(t)),
      ),
    ),
    final UnwindForm f => _unwind(f),
    final SortForm f => _sort(f),
    final ProjectForm f => _project(f),
    final AddFieldsForm f => _addFields(f),
    final GroupForm f => _group(f),
    final MatchForm f => _match(f),
    final LookupForm f => _lookup(f),
  };

  Widget _suggest(
    String key,
    String initial,
    String label,
    ValueChanged<String> onChanged,
  ) => SuggestCell(
    key: ValueKey('$stageId-$key'),
    initial: initial,
    label: label,
    suggestions: fieldNames,
    onChanged: onChanged,
  );

  List<T> _replaced<T>(List<T> rows, int i, T row) => [...rows]..[i] = row;

  List<T> _without<T>(List<T> rows, int i) => [...rows]..removeAt(i);

  Widget _unwind(UnwindForm f) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 220,
        child: _suggest(
          'path',
          f.path,
          'Array field',
          (t) => onChanged(
            UnwindForm(
              path: t,
              preserveNullAndEmpty: f.preserveNullAndEmpty,
              indexField: f.indexField,
            ),
          ),
        ),
      ),
      SizedBox(
        width: 180,
        child: TextCell(
          key: ValueKey('$stageId-index'),
          initial: f.indexField,
          label: 'Index field (optional)',
          onChanged: (t) => onChanged(
            UnwindForm(
              path: f.path,
              preserveNullAndEmpty: f.preserveNullAndEmpty,
              indexField: t,
            ),
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            key: ValueKey('$stageId-preserve'),
            value: f.preserveNullAndEmpty,
            onChanged: (v) => onChanged(
              UnwindForm(
                path: f.path,
                preserveNullAndEmpty: v ?? false,
                indexField: f.indexField,
              ),
            ),
          ),
          const Text('Keep null and empty'),
        ],
      ),
    ],
  );

  Widget _sort(SortForm f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < f.rows.length; i++)
        FormRowShell(
          key: ValueKey('$stageId-sort-$i-${f.rows.length}'),
          onRemove: () => onChanged(SortForm(_without(f.rows, i))),
          children: [
            _suggest(
              'sf$i-${f.rows.length}',
              f.rows[i].field,
              'Field',
              (t) => onChanged(
                SortForm(
                  _replaced(
                    f.rows,
                    i,
                    SortRow(t, ascending: f.rows[i].ascending),
                  ),
                ),
              ),
            ),
            DropdownCell<bool>(
              value: f.rows[i].ascending,
              items: const [true, false],
              labelOf: (a) => a ? 'Ascending' : 'Descending',
              onChanged: (a) => onChanged(
                SortForm(
                  _replaced(f.rows, i, SortRow(f.rows[i].field, ascending: a)),
                ),
              ),
            ),
          ],
        ),
      AddRowButton(
        label: 'Add sort key',
        onPressed: () => onChanged(SortForm([...f.rows, const SortRow('')])),
      ),
    ],
  );

  Widget _project(ProjectForm f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < f.rows.length; i++)
        FormRowShell(
          key: ValueKey('$stageId-project-$i-${f.rows.length}'),
          onRemove: () => onChanged(ProjectForm(_without(f.rows, i))),
          children: [
            _suggest(
              'pf$i-${f.rows.length}',
              f.rows[i].field,
              'Field',
              (t) => onChanged(
                ProjectForm(
                  _replaced(
                    f.rows,
                    i,
                    ProjectRow(t, include: f.rows[i].include),
                  ),
                ),
              ),
            ),
            DropdownCell<bool>(
              value: f.rows[i].include,
              items: const [true, false],
              labelOf: (a) => a ? 'Include' : 'Exclude',
              onChanged: (a) => onChanged(
                ProjectForm(
                  _replaced(f.rows, i, ProjectRow(f.rows[i].field, include: a)),
                ),
              ),
            ),
          ],
        ),
      AddRowButton(
        label: 'Add field',
        onPressed: () =>
            onChanged(ProjectForm([...f.rows, const ProjectRow('')])),
      ),
    ],
  );

  Widget _addFields(AddFieldsForm f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < f.rows.length; i++)
        FormRowShell(
          key: ValueKey('$stageId-add-$i-${f.rows.length}'),
          onRemove: () => onChanged(AddFieldsForm(_without(f.rows, i))),
          children: [
            _suggest(
              'af$i-${f.rows.length}',
              f.rows[i].field,
              'New field',
              (t) => onChanged(
                AddFieldsForm(
                  _replaced(f.rows, i, ExpressionRow(t, f.rows[i].expression)),
                ),
              ),
            ),
            TextCell(
              key: ValueKey('$stageId-ae$i-${f.rows.length}'),
              initial: f.rows[i].expression,
              label: 'Expression',
              mono: true,
              onChanged: (t) => onChanged(
                AddFieldsForm(
                  _replaced(f.rows, i, ExpressionRow(f.rows[i].field, t)),
                ),
              ),
            ),
          ],
        ),
      AddRowButton(
        label: 'Add field',
        onPressed: () =>
            onChanged(AddFieldsForm([...f.rows, const ExpressionRow('', '')])),
      ),
    ],
  );

  Widget _group(GroupForm f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextCell(
          key: ValueKey('$stageId-gid'),
          initial: f.idExpression,
          label: '_id (group key expression)',
          mono: true,
          onChanged: (t) => onChanged(
            GroupForm(idExpression: t, accumulators: f.accumulators),
          ),
        ),
      ),
      for (var i = 0; i < f.accumulators.length; i++)
        FormRowShell(
          key: ValueKey('$stageId-acc-$i-${f.accumulators.length}'),
          onRemove: () => onChanged(
            GroupForm(
              idExpression: f.idExpression,
              accumulators: _without(f.accumulators, i),
            ),
          ),
          children: [
            TextCell(
              key: ValueKey('$stageId-an$i-${f.accumulators.length}'),
              initial: f.accumulators[i].field,
              label: 'Output field',
              onChanged: (t) => onChanged(
                GroupForm(
                  idExpression: f.idExpression,
                  accumulators: _replaced(
                    f.accumulators,
                    i,
                    AccumulatorRow(
                      t,
                      f.accumulators[i].accumulator,
                      f.accumulators[i].expression,
                    ),
                  ),
                ),
              ),
            ),
            DropdownCell<String>(
              value: f.accumulators[i].accumulator,
              items: groupAccumulators,
              labelOf: (a) => a,
              onChanged: (a) => onChanged(
                GroupForm(
                  idExpression: f.idExpression,
                  accumulators: _replaced(
                    f.accumulators,
                    i,
                    AccumulatorRow(
                      f.accumulators[i].field,
                      a,
                      f.accumulators[i].expression,
                    ),
                  ),
                ),
              ),
            ),
            if (f.accumulators[i].accumulator == r'$count')
              const SizedBox.shrink()
            else
              TextCell(
                key: ValueKey('$stageId-ax$i-${f.accumulators.length}'),
                initial: f.accumulators[i].expression,
                label: 'Expression',
                mono: true,
                onChanged: (t) => onChanged(
                  GroupForm(
                    idExpression: f.idExpression,
                    accumulators: _replaced(
                      f.accumulators,
                      i,
                      AccumulatorRow(
                        f.accumulators[i].field,
                        f.accumulators[i].accumulator,
                        t,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      AddRowButton(
        label: 'Add accumulator',
        onPressed: () => onChanged(
          GroupForm(
            idExpression: f.idExpression,
            accumulators: [
              ...f.accumulators,
              const AccumulatorRow('', r'$sum', '1'),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _match(MatchForm f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < f.rows.length; i++)
        FormRowShell(
          key: ValueKey('$stageId-match-$i-${f.rows.length}'),
          onRemove: () => onChanged(MatchForm(_without(f.rows, i))),
          children: [
            _suggest(
              'mf$i-${f.rows.length}',
              f.rows[i].field,
              'Field',
              (t) => onChanged(
                MatchForm(
                  _replaced(
                    f.rows,
                    i,
                    MatchRow(t, f.rows[i].operator, f.rows[i].value),
                  ),
                ),
              ),
            ),
            DropdownCell<String>(
              value: f.rows[i].operator,
              items: matchOperators,
              labelOf: (o) => o == 'eq' ? '=' : o,
              onChanged: (o) => onChanged(
                MatchForm(
                  _replaced(
                    f.rows,
                    i,
                    MatchRow(f.rows[i].field, o, f.rows[i].value),
                  ),
                ),
              ),
            ),
            TextCell(
              key: ValueKey('$stageId-mv$i-${f.rows.length}'),
              initial: f.rows[i].value,
              label: 'Value',
              mono: true,
              onChanged: (t) => onChanged(
                MatchForm(
                  _replaced(
                    f.rows,
                    i,
                    MatchRow(f.rows[i].field, f.rows[i].operator, t),
                  ),
                ),
              ),
            ),
          ],
        ),
      AddRowButton(
        label: 'Add condition',
        onPressed: () =>
            onChanged(MatchForm([...f.rows, const MatchRow('', 'eq', '')])),
      ),
    ],
  );

  Widget _lookup(LookupForm f) {
    LookupForm with_({
      String? from,
      String? local,
      String? foreign,
      String? as,
    }) => LookupForm(
      from: from ?? f.from,
      localField: local ?? f.localField,
      foreignField: foreign ?? f.foreignField,
      as: as ?? f.as,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 200,
          child: SuggestCell(
            key: ValueKey('$stageId-from'),
            initial: f.from,
            label: 'From collection',
            suggestions: collectionNames,
            onChanged: (t) => onChanged(with_(from: t)),
          ),
        ),
        SizedBox(
          width: 180,
          child: _suggest(
            'local',
            f.localField,
            'Local field',
            (t) => onChanged(with_(local: t)),
          ),
        ),
        SizedBox(
          width: 180,
          child: TextCell(
            key: ValueKey('$stageId-foreign'),
            initial: f.foreignField,
            label: 'Foreign field',
            onChanged: (t) => onChanged(with_(foreign: t)),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextCell(
            key: ValueKey('$stageId-as'),
            initial: f.as,
            label: 'Output array',
            onChanged: (t) => onChanged(with_(as: t)),
          ),
        ),
      ],
    );
  }
}
