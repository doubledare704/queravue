import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../schema/domain/schema_models.dart';
import '../../workspace/application/tab_files.dart';
import '../../workspace/domain/workspace_models.dart';
import '../../workspace/presentation/workspace_dialogs.dart';
import '../application/diagram_controller.dart';
import '../application/saved_diagram_opener.dart';
import '../data/diagram_files.dart';
import '../data/export_target.dart';
import '../domain/diagram_models.dart';
import '../../designer/presentation/ddl_preview_dialog.dart';
import 'diagram_export.dart';
import 'draft_dialogs.dart';

void _say(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

EditorTab? _tab(WidgetRef ref, String tabId) =>
    ref.read(editorTabsProvider).tabs.where((t) => t.id == tabId).firstOrNull;

/// The diagram tab the user is looking at, if any.
EditorTab? activeDiagramTab(WidgetRef ref) {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  return tab != null && tab.isDiagram ? tab : null;
}

/// ⌘S on a diagram: writes it to its file, or asks for a name first.
/// [saveAs] always asks.
Future<void> saveDiagramFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId, {
  bool saveAs = false,
}) async {
  final tab = _tab(ref, tabId);
  if (tab == null) return;
  if (ref.read(diagramProvider(tabId)) is! DiagramReady) {
    _say(context, 'The diagram is still loading.');
    return;
  }
  var file = saveAs ? null : tab.diagramFile;
  if (file == null) {
    final current = tab.diagramFile;
    final suggested = current != null
        ? '${diagramNameOf(current)} copy'
        : (tab.tableRef?.schema.isNotEmpty ?? false)
        ? tab.tableRef!.schema
        : 'diagram';
    final typed = await promptText(
      context,
      title: saveAs ? 'Save diagram as' : 'Save diagram',
      label: 'Name',
      initial: suggested,
      confirm: 'Save',
    );
    if (typed == null || !context.mounted) return;
    final name = validDiagramName(typed);
    if (name == null) {
      _say(
        context,
        'Use letters, digits, spaces, dots, dashes and underscores, '
        'starting with a letter or digit.',
      );
      return;
    }
    final files = ref.read(diagramFilesProvider);
    final FilePath? target;
    try {
      target = await files.pathFor(name);
      if (target == null) {
        if (context.mounted) _say(context, 'No workspace folder is available.');
        return;
      }
      if (target != current && await files.exists(target)) {
        if (!context.mounted || !await _confirmReplace(context, name)) return;
      }
    } on WorkspaceFailure catch (e) {
      if (context.mounted) _say(context, 'Save failed: ${e.message}');
      return;
    }
    file = target;
  }
  try {
    await ref
        .read(diagramProvider(tabId).notifier)
        .saveTo(file, diagramNameOf(file));
  } on DiagramFailure catch (e) {
    if (context.mounted) _say(context, 'Save failed: ${e.message}');
  }
}

Future<bool> _confirmReplace(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace "$name"?'),
        content: const Text('A saved diagram with this name exists already.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('diagram-replace'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    ) ??
    false;

String _fileStem(String title) {
  final stem = title.trim().replaceAll(RegExp(r'[^A-Za-z0-9 _.\-]'), '_');
  return stem.isEmpty ? 'diagram' : stem;
}

/// Exports the shown tables of a diagram to a file the user picks. Exports
/// use the light theme, so they read well on paper and in documents.
Future<void> exportDiagramFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId,
  ExportFormat format,
) async {
  final tab = _tab(ref, tabId);
  final state = ref.read(diagramProvider(tabId));
  if (tab == null || state is! DiagramReady || state.isEmpty) return;
  final target = ref.read(exportTargetProvider);
  final path = await target.chooseLocation(
    '${_fileStem(tab.title)}.${format.extension}',
    format,
  );
  if (path == null || !context.mounted) return;
  final colors = lightTheme.colorScheme;
  try {
    final Uint8List bytes;
    var detail = '';
    switch (format) {
      case ExportFormat.svg:
        bytes = utf8.encode(
          diagramToSvg(
            graph: state.visibleGraph,
            rects: state.visibleRects,
            colors: colors,
            title: tab.title,
          ),
        );
      case ExportFormat.png:
        final png = await diagramToPng(
          graph: state.visibleGraph,
          rects: state.visibleRects,
          colors: colors,
        );
        bytes = png.bytes;
        detail = ', ${png.width} × ${png.height} px';
        if (png.pixelRatio < 1) {
          detail +=
              ', scaled to ${(png.pixelRatio * 100).round()} % to stay within '
              '${maxPngPixels ~/ 1000000} megapixels';
        }
    }
    await target.write(path, bytes);
    if (context.mounted) {
      _say(context, 'Exported ${path.split('/').last}$detail');
    }
  } on Object catch (e) {
    if (context.mounted) _say(context, 'Export failed: $e');
  }
}

/// Lists the saved diagrams of the workspace and opens the one picked.
Future<void> openSavedDiagramFlow(BuildContext context, WidgetRef ref) async {
  final List<FilePath> files;
  try {
    files = await ref.read(diagramFilesProvider).list();
  } on WorkspaceFailure catch (e) {
    if (context.mounted) _say(context, e.message);
    return;
  }
  if (!context.mounted) return;
  if (files.isEmpty) {
    _say(context, 'No saved diagrams in $diagramsDir yet.');
    return;
  }
  final picked = await showDialog<FilePath>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Open saved diagram'),
      children: [
        for (final f in files)
          SimpleDialogOption(
            key: Key('saved-diagram-${f.name}'),
            onPressed: () => Navigator.of(context).pop(f),
            child: Text(diagramNameOf(f)),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  final out = await openSavedDiagram(ref.read, picked);
  if (out is OpenFailed && context.mounted) _say(context, out.message);
}

DiagramReady? _ready(WidgetRef ref, String tabId) {
  final state = ref.read(diagramProvider(tabId));
  return state is DiagramReady ? state : null;
}

/// Drafts a new table and puts it at [at], in diagram coordinates.
Future<void> newDraftTableFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId, {
  Offset? at,
}) async {
  final controller = ref.read(diagramProvider(tabId).notifier);
  if (_ready(ref, tabId) == null) {
    _say(context, 'The diagram is still loading.');
    return;
  }
  final table = await showDraftTableDialog(
    context,
    taken: controller.tableNames,
  );
  if (table != null) controller.addDraftTable(table, at: at);
}

Future<void> editDraftTableFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId,
  String name,
) async {
  final ready = _ready(ref, tabId);
  final initial = ready?.draft.table(name);
  if (initial == null) return;
  final controller = ref.read(diagramProvider(tabId).notifier);
  final table = await showDraftTableDialog(
    context,
    initial: initial,
    taken: {...controller.tableNames}..remove(name),
  );
  if (table != null) controller.replaceDraftTable(name, table);
}

/// Drafts a reference from [from] to a table the user picks.
Future<void> addRelationFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId,
  String from,
) async {
  final ready = _ready(ref, tabId);
  final table = ready?.table(from);
  if (ready == null || table == null) return;
  final relation = await showDraftRelationDialog(
    context,
    from: table,
    targets: [
      for (final t in ready.drawnGraph.tables)
        if (t.type == SchemaObjectType.table && !t.isExternal) t,
    ],
    takenNames: {
      for (final t in ready.drawnGraph.tables)
        for (final r in t.relations) r.name,
    },
  );
  if (relation != null) {
    ref.read(diagramProvider(tabId).notifier).addDraftRelation(relation);
  }
}

/// Shows the DDL of the draft and applies it on the user's word.
Future<void> reviewDraftFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId,
) async {
  final ready = _ready(ref, tabId);
  if (ready == null || ready.draft.isEmpty) {
    _say(context, 'Nothing is drafted on this diagram.');
    return;
  }
  final controller = ref.read(diagramProvider(tabId).notifier);
  await showDialog<void>(
    context: context,
    builder: (_) => DdlPreviewDialog(
      preview: controller.previewDraft,
      apply: () => controller.applyDraft(confirmed: true),
    ),
  );
}

Future<void> discardDraftFlow(
  BuildContext context,
  WidgetRef ref,
  String tabId,
) async {
  final ready = _ready(ref, tabId);
  if (ready == null || ready.draft.isEmpty) return;
  final n = ready.draft.size;
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Discard the draft?'),
      content: Text(
        'The $n drafted ${n == 1 ? 'change' : 'changes'} on this diagram will be lost.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          key: const Key('diagram-discard-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  if (discard ?? false) {
    ref.read(diagramProvider(tabId).notifier).discardDraft();
  }
}

/// What the table menu offers in design mode for [table].
List<(String, String)> draftMenuItems(DiagramReady ready, String table) {
  final drawn = ready.table(table);
  return [
    if (drawn != null &&
        drawn.type == SchemaObjectType.table &&
        !drawn.isExternal)
      ('relation', 'Add relation…'),
    if (ready.draft.table(table) != null) ...[
      ('edit', 'Edit table…'),
      ('remove', 'Remove drafted table'),
    ],
    for (final (i, r) in ready.draft.relationsFrom(table).indexed)
      ('unrelate-$i', 'Remove relation to ${r.toTable}'),
  ];
}

Future<void> draftMenuAction(
  BuildContext context,
  WidgetRef ref,
  String tabId,
  String table,
  String choice,
) async {
  final controller = ref.read(diagramProvider(tabId).notifier);
  switch (choice) {
    case 'relation':
      await addRelationFlow(context, ref, tabId, table);
    case 'edit':
      await editDraftTableFlow(context, ref, tabId, table);
    case 'remove':
      controller.removeDraftTable(table);
    default:
      final i = int.tryParse(choice.replaceFirst('unrelate-', ''));
      final relations = _ready(ref, tabId)?.draft.relationsFrom(table) ?? [];
      if (i != null && i < relations.length) {
        controller.removeDraftRelation(relations[i]);
      }
  }
}
