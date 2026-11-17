import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/panes/editor_over_output.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/application/query_run.dart';
import '../../editor/presentation/query_tab_view.dart';
import '../application/sql_query_builder_controller.dart';
import '../domain/sql_query_models.dart';
import 'widgets/condition_tree_editor.dart';
import 'widgets/query_builder_sections.dart';

class SqlQueryBuilderView extends ConsumerWidget {
  const SqlQueryBuilderView({super.key, required this.tab});

  final EditorTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sqlQueryBuilderProvider(tab.id));
    final controller = ref.read(sqlQueryBuilderProvider(tab.id).notifier);
    final run = ref.watch(queryRunProvider(tab.id));
    final allColumns = _collectColumns(state);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BuilderToolbar(
          state: state,
          run: run,
          onPreview: () => unawaited(controller.runPreview()),
          onCancel: () => unawaited(controller.cancelPreview()),
          onOpenInEditor: () => controller.openInEditor(tab.controller),
          onToggleDistinct: (v) => unawaited(controller.setDistinct(v)),
          onChangeLimit: controller.setPreviewLimit,
          onClear: () => unawaited(controller.clearDraft()),
        ),
        const Divider(height: 1),
        if (state.commentsDropped)
          Material(
            key: const Key('qb-comments-dropped-banner'),
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SQL comments were dropped when opening the visual builder.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('qb-comments-dropped-dismiss'),
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    icon: const Icon(Icons.close),
                    onPressed: controller.dismissCommentsDropped,
                  ),
                ],
              ),
            ),
          ),
        if (state.builderError != null)
          Container(
            key: const Key('qb-builder-error'),
            color: cs.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              state.builderError!,
              style: textTheme.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        Expanded(
          child: EditorOverOutput(
            editor: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                FromAndJoinsSection(
                  state: state,
                  controller: controller,
                  allColumns: allColumns,
                ),
                const SizedBox(height: 10),
                SelectSection(
                  state: state,
                  controller: controller,
                  allColumns: allColumns,
                ),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Filters (WHERE)', style: textTheme.titleSmall),
                        const SizedBox(height: 10),
                        ConditionTreeEditor(
                          keyPrefix: 'qb-where',
                          root: state.draft.where,
                          columns: allColumns,
                          addLabel: 'Add WHERE condition',
                          onChanged: controller.setWhere,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GroupHavingSection(
                  state: state,
                  controller: controller,
                  allColumns: allColumns,
                ),
                const SizedBox(height: 10),
                OrderLimitSection(
                  state: state,
                  controller: controller,
                  allColumns: allColumns,
                ),
                const SizedBox(height: 10),
                _GeneratedSqlCard(sql: state.generatedSql),
              ],
            ),
            output: QueryResultArea(
              tabId: tab.id,
              run: run,
              idleHint: 'Click Preview to run (capped at ${state.previewLimit} rows)',
            ),
          ),
        ),
      ],
    );
  }

  List<SqlColumnRefModel> _collectColumns(SqlQueryBuilderState state) {
    final active = state.activeTables;
    final multiTable = active.length > 1;
    final out = <SqlColumnRefModel>[];
    for (final tbl in active) {
      final details = state.tableDetailsByKey[tableKey(tbl.schema, tbl.table)];
      if (details == null) continue;
      final alias = tbl.alias.isNotEmpty
          ? tbl.alias
          : (multiTable ? tbl.table : '');
      for (final c in details.columns) {
        out.add(SqlColumnRefModel(tableAlias: alias, column: c.name));
      }
    }
    return out;
  }
}

class _BuilderToolbar extends StatelessWidget {
  const _BuilderToolbar({
    required this.state,
    required this.run,
    required this.onPreview,
    required this.onCancel,
    required this.onOpenInEditor,
    required this.onToggleDistinct,
    required this.onChangeLimit,
    required this.onClear,
  });

  final SqlQueryBuilderState state;
  final QueryRunState run;
  final VoidCallback onPreview;
  final VoidCallback onCancel;
  final VoidCallback onOpenInEditor;
  final ValueChanged<bool> onToggleDistinct;
  final ValueChanged<int> onChangeLimit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!run.busy)
                  FilledButton.icon(
                    key: const Key('qb-preview-button'),
                    onPressed: state.generatedSql.isEmpty ? null : onPreview,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Preview'),
                  )
                else
                  FilledButton.icon(
                    key: const Key('qb-cancel-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                    onPressed: run.cancelling ? null : onCancel,
                    icon: const Icon(Icons.stop, size: 18),
                    label: Text(run.cancelling ? 'Cancelling…' : 'Cancel'),
                  ),
                DropdownButton<int>(
                  key: const Key('qb-preview-limit'),
                  value: state.previewLimit,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 25, child: Text('Cap: 25')),
                    DropdownMenuItem(value: 100, child: Text('Cap: 100')),
                    DropdownMenuItem(value: 500, child: Text('Cap: 500')),
                    DropdownMenuItem(value: 1000, child: Text('Cap: 1000')),
                  ],
                  onChanged: (v) {
                    if (v != null) onChangeLimit(v);
                  },
                ),
                OutlinedButton.icon(
                  key: const Key('qb-open-in-editor-button'),
                  onPressed: onOpenInEditor,
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('Open in editor'),
                ),
                FilterChip(
                  key: const Key('qb-distinct-chip'),
                  label: const Text('DISTINCT'),
                  selected: state.draft.distinct,
                  visualDensity: VisualDensity.compact,
                  onSelected: onToggleDistinct,
                ),
                TextButton(
                  key: const Key('qb-clear-button'),
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElapsedText(
            startedAt: run.startedAt,
            running: run.busy,
            finalDuration: run.totalDuration,
          ),
          if (run.serverLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                run.serverLabel,
                style: text.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratedSqlCard extends StatelessWidget {
  const _GeneratedSqlCard({required this.sql});

  final String sql;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                  child: Text('Generated SQL', style: text.titleSmall),
                ),
                IconButton(
                  key: const Key('qb-copy-sql-button'),
                  tooltip: 'Copy SQL',
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.copy),
                  onPressed: sql.isEmpty
                      ? null
                      : () => unawaited(
                          Clipboard.setData(ClipboardData(text: sql)),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                sql.isEmpty ? 'Select a table to generate SQL.' : sql,
                key: const Key('qb-generated-sql'),
                style: text.bodySmall?.copyWith(fontFamily: 'Menlo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
