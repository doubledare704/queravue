import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/querybuilder.pb.dart' as pb;
import '../../../shared/shortcuts.dart';
import '../application/document_preview_controller.dart';
import '../application/document_tab_controller.dart';
import '../presentation/document_preview_pane.dart';
import 'filter_builder_controller.dart';

class FilterBuilderPanel extends ConsumerWidget {
  const FilterBuilderPanel({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builder = filterBuilderProvider(tabId);
    final state = ref.watch(builder);
    final sessionId = ref.watch(
      documentTabProvider(tabId).select((state) => state.sessionId),
    );
    ref.listen(builder.select((state) => state.previewQuery), (_, _) {
      ref.read(documentPreviewProvider(tabId).notifier).reset();
    });
    final run = state.previewQuery != null && sessionId != null
        ? ref.read(builder.notifier).runPreview
        : null;
    return CallbackShortcuts(
      bindings: {primaryShortcut(LogicalKeyboardKey.enter): () => run?.call()},
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: FilterBuilderView(
                key: ValueKey(state.revision),
                tabId: tabId,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: DocumentPreviewPane(
              previewKey: tabId,
              showRun: true,
              onRun: run,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBuilderView extends ConsumerWidget {
  const FilterBuilderView({super.key, required this.tabId});
  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filterBuilderProvider(tabId));
    final controller = ref.read(filterBuilderProvider(tabId).notifier);
    if (state.loading) return const Center(child: CircularProgressIndicator());
    final model = state.model;
    if (model == null) {
      return Text(
        state.cannotShow
            ? 'Cannot be shown visually: ${state.error}'
            : (state.error ?? 'No model'),
      );
    }
    void change(
      void Function(pb.MongoFindModel) edit, {
      bool resetFields = false,
    }) {
      final next = model.deepCopy();
      edit(next);
      controller.update(next, resetFields: resetFields);
    }

    pb.MongoCondition at(pb.MongoFindModel m, List<int> path) {
      var node = m.filter;
      for (final index in path) {
        node = node.group.children[index];
      }
      return node;
    }

    pb.MongoCondition newField() => pb.MongoCondition(
      field_1: pb.MongoFieldCondition(
        path: 'field',
        op: pb.MongoOperator.MONGO_OPERATOR_EQ,
        valueEjson: 'null',
      ),
    );
    Widget tree(pb.MongoCondition node, List<int> path) {
      if (node.hasGroup()) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DropdownButton<pb.MongoBoolOp>(
                      value:
                          node.group.op ==
                              pb.MongoBoolOp.MONGO_BOOL_OP_UNSPECIFIED
                          ? pb.MongoBoolOp.MONGO_BOOL_OP_AND
                          : node.group.op,
                      items: [
                        for (final op in [
                          pb.MongoBoolOp.MONGO_BOOL_OP_AND,
                          pb.MongoBoolOp.MONGO_BOOL_OP_OR,
                          pb.MongoBoolOp.MONGO_BOOL_OP_NOR,
                        ])
                          DropdownMenuItem(
                            value: op,
                            child: Text(op.name.split('_').last),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) change((m) => at(m, path).group.op = v);
                      },
                    ),
                    TextButton(
                      onPressed: () => change(
                        (m) => at(m, path).group.children.add(newField()),
                      ),
                      child: const Text('Add condition'),
                    ),
                    TextButton(
                      onPressed: () => change(
                        (m) => at(m, path).group.children.add(
                          pb.MongoCondition(
                            group: pb.MongoConditionGroup(
                              op: pb.MongoBoolOp.MONGO_BOOL_OP_AND,
                              children: [newField()],
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Add group'),
                    ),
                    if (path.isNotEmpty &&
                        at(
                              model,
                              path.sublist(0, path.length - 1),
                            ).group.children.length >
                            1)
                      IconButton(
                        onPressed: () => change(
                          (m) => at(
                            m,
                            path.sublist(0, path.length - 1),
                          ).group.children.removeAt(path.last),
                          resetFields: true,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove group',
                      ),
                  ],
                ),
                for (var i = 0; i < node.group.children.length; i++)
                  tree(node.group.children[i], [...path, i]),
              ],
            ),
          ),
        );
      }
      if (node.hasRawEjson()) {
        return Row(
          children: [
            const Text('Raw EJSON'),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('${state.revision}raw$path'),
                initialValue: node.rawEjson,
                onChanged: (v) => change((m) => at(m, path).rawEjson = v),
              ),
            ),
            if (path.isNotEmpty &&
                at(
                      model,
                      path.sublist(0, path.length - 1),
                    ).group.children.length >
                    1)
              IconButton(
                onPressed: () => change(
                  (m) => at(
                    m,
                    path.sublist(0, path.length - 1),
                  ).group.children.removeAt(path.last),
                  resetFields: true,
                ),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        );
      }
      final field = node.field_1;
      final types = state.fields
          .where((f) => f.path.replaceAll('.[]', '') == field.path)
          .expand((f) => f.types)
          .map((t) => t.type)
          .toSet();
      final ordered =
          types.isEmpty ||
          types.any(
            (t) => {
              'string',
              'int',
              'long',
              'double',
              'decimal',
              'date',
              'timestamp',
            }.contains(t),
          );
      final string = types.isEmpty || types.contains('string');
      final operators = pb.MongoOperator.values.where((o) {
        if (o == pb.MongoOperator.MONGO_OPERATOR_UNSPECIFIED) return false;
        if (o == field.op) return true;
        if (o == pb.MongoOperator.MONGO_OPERATOR_REGEX) return string;
        if ([
          pb.MongoOperator.MONGO_OPERATOR_GT,
          pb.MongoOperator.MONGO_OPERATOR_GTE,
          pb.MongoOperator.MONGO_OPERATOR_LT,
          pb.MongoOperator.MONGO_OPERATOR_LTE,
        ].contains(o)) {
          return ordered;
        }
        return true;
      }).toList();
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('${state.revision}path$path'),
              initialValue: field.path,
              decoration: const InputDecoration(labelText: 'Field'),
              onChanged: (v) => change((m) => at(m, path).field_1.path = v),
            ),
          ),
          if (state.fields.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Choose sampled field',
              icon: const Icon(Icons.arrow_drop_down),
              itemBuilder: (_) => [
                for (final f in state.fields)
                  PopupMenuItem(value: f.path, child: Text(f.path)),
              ],
              onSelected: (value) => change(
                (m) => at(m, path).field_1.path = value.replaceAll('.[]', ''),
                resetFields: true,
              ),
            ),
          const SizedBox(width: 8),
          DropdownButton<pb.MongoOperator>(
            value: field.op == pb.MongoOperator.MONGO_OPERATOR_UNSPECIFIED
                ? pb.MongoOperator.MONGO_OPERATOR_EQ
                : field.op,
            items: [
              for (final op in operators)
                DropdownMenuItem(
                  value: op,
                  child: Text(op.name.split('_').last),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                change((m) {
                  final next = at(m, path).field_1;
                  next.op = v;
                  next.regexOptions = '';
                  if (v == pb.MongoOperator.MONGO_OPERATOR_IN ||
                      v == pb.MongoOperator.MONGO_OPERATOR_NIN) {
                    next.valueEjson = '[]';
                  } else if (v == pb.MongoOperator.MONGO_OPERATOR_EXISTS) {
                    next.valueEjson = 'true';
                  } else if (v == pb.MongoOperator.MONGO_OPERATOR_REGEX) {
                    next.valueEjson = '""';
                  } else if (v == pb.MongoOperator.MONGO_OPERATOR_TYPE) {
                    next.valueEjson = '"string"';
                  }
                }, resetFields: true);
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('${state.revision}value$path'),
              initialValue: field.valueEjson,
              decoration: const InputDecoration(labelText: 'Value (EJSON)'),
              onChanged: (v) =>
                  change((m) => at(m, path).field_1.valueEjson = v),
            ),
          ),
          if (field.op == pb.MongoOperator.MONGO_OPERATOR_REGEX)
            SizedBox(
              width: 70,
              child: TextFormField(
                key: ValueKey('${state.revision}options$path'),
                initialValue: field.regexOptions,
                decoration: const InputDecoration(labelText: 'Options'),
                onChanged: (v) =>
                    change((m) => at(m, path).field_1.regexOptions = v),
              ),
            ),
          Checkbox(
            value: field.negated,
            onChanged: (v) =>
                change((m) => at(m, path).field_1.negated = v ?? false),
          ),
          const Text('Not'),
          if (path.isNotEmpty &&
              at(
                    model,
                    path.sublist(0, path.length - 1),
                  ).group.children.length >
                  1)
            IconButton(
              onPressed: () => change(
                (m) => at(
                  m,
                  path.sublist(0, path.length - 1),
                ).group.children.removeAt(path.last),
                resetFields: true,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error != null)
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (model.hasFilter())
          tree(model.filter, [])
        else
          TextButton(
            onPressed: () => change((m) => m.filter = newField()),
            child: const Text('Add filter'),
          ),
        if (model.hasFilter())
          Row(
            children: [
              TextButton(
                onPressed: () => change((m) {
                  final old = m.filter.deepCopy();
                  m.filter = pb.MongoCondition(
                    group: pb.MongoConditionGroup(
                      op: pb.MongoBoolOp.MONGO_BOOL_OP_AND,
                      children: [old],
                    ),
                  );
                }),
                child: const Text('Group filter'),
              ),
              TextButton(
                onPressed: () => change((m) => m.clearFilter()),
                child: const Text('Clear filter'),
              ),
            ],
          ),
        const Text('Projection'),
        for (var i = 0; i < model.projection.length; i++)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('${state.revision}projection$i'),
                  initialValue: model.projection[i].path,
                  decoration: const InputDecoration(labelText: 'Field'),
                  onChanged: (v) => change((m) => m.projection[i].path = v),
                ),
              ),
              if (state.fields.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Choose sampled field',
                  icon: const Icon(Icons.arrow_drop_down),
                  itemBuilder: (_) => [
                    for (final f in state.fields)
                      PopupMenuItem(value: f.path, child: Text(f.path)),
                  ],
                  onSelected: (value) => change(
                    (m) => m.projection[i].path = value.replaceAll('.[]', ''),
                    resetFields: true,
                  ),
                ),
              DropdownButton<pb.MongoProjectionMode>(
                value:
                    model.projection[i].mode ==
                        pb.MongoProjectionMode.MONGO_PROJECTION_MODE_EXCLUDE
                    ? pb.MongoProjectionMode.MONGO_PROJECTION_MODE_EXCLUDE
                    : pb.MongoProjectionMode.MONGO_PROJECTION_MODE_INCLUDE,
                items: const [
                  DropdownMenuItem(
                    value: pb.MongoProjectionMode.MONGO_PROJECTION_MODE_INCLUDE,
                    child: Text('Include'),
                  ),
                  DropdownMenuItem(
                    value: pb.MongoProjectionMode.MONGO_PROJECTION_MODE_EXCLUDE,
                    child: Text('Exclude'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) change((m) => m.projection[i].mode = v);
                },
              ),
              IconButton(
                onPressed: () =>
                    change((m) => m.projection.removeAt(i), resetFields: true),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        TextButton(
          onPressed: () => change(
            (m) => m.projection.add(
              pb.MongoProjectionField(
                path: 'field',
                mode: pb.MongoProjectionMode.MONGO_PROJECTION_MODE_INCLUDE,
              ),
            ),
          ),
          child: const Text('Add projection'),
        ),
        const Text('Sort'),
        for (var i = 0; i < model.sort.length; i++)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('${state.revision}sort$i'),
                  initialValue: model.sort[i].path,
                  decoration: const InputDecoration(labelText: 'Field'),
                  onChanged: (v) => change((m) => m.sort[i].path = v),
                ),
              ),
              if (state.fields.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Choose sampled field',
                  icon: const Icon(Icons.arrow_drop_down),
                  itemBuilder: (_) => [
                    for (final f in state.fields)
                      PopupMenuItem(value: f.path, child: Text(f.path)),
                  ],
                  onSelected: (value) => change(
                    (m) => m.sort[i].path = value.replaceAll('.[]', ''),
                    resetFields: true,
                  ),
                ),
              Checkbox(
                value: model.sort[i].descending,
                onChanged: (v) =>
                    change((m) => m.sort[i].descending = v ?? false),
              ),
              const Text('Descending'),
              IconButton(
                onPressed: () =>
                    change((m) => m.sort.removeAt(i), resetFields: true),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        TextButton(
          onPressed: () =>
              change((m) => m.sort.add(pb.MongoSortField(path: 'field'))),
          child: const Text('Add sort'),
        ),
      ],
    );
  }
}
