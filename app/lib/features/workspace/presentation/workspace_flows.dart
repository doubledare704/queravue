import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/sidebar_mode.dart';
import '../application/tab_files.dart';
import '../application/workspace_controller.dart';
import '../domain/workspace_models.dart';
import 'workspace_dialogs.dart';

void _say(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// Opens [file] in an editor tab and says why if that is not possible.
Future<void> openFileFlow(
  BuildContext context,
  WidgetRef ref,
  FilePath file,
) async {
  final out = await ref.read(fileOpenerProvider).open(file);
  if (out is OpenFailed && context.mounted) _say(context, out.message);
}

/// ⌘O: pick a workspace file by searching.
Future<void> quickOpenFlow(BuildContext context, WidgetRef ref) async {
  final file = await showQuickOpen(context);
  if (file != null && context.mounted) await openFileFlow(context, ref, file);
}

/// Shows the workspace panel and focuses its search box.
void searchWorkspaceFlow(WidgetRef ref) {
  ref.read(sidebarModeProvider.notifier).show(SidebarMode.workspace);
  ref.read(workspaceSearchFocusProvider.notifier).request();
}

/// Creates a new script file (asking for its name) and opens it.
Future<void> newScriptFlow(
  BuildContext context,
  WidgetRef ref,
  FileKind kind, {
  FilePath? dir,
}) async {
  await ref.read(workspaceProvider.notifier).ensureLoaded();
  if (!context.mounted) return;
  final ws = ref.read(workspaceProvider);
  final target =
      dir ?? (ws.roots.isEmpty ? null : FilePath(ws.roots.first.id, ''));
  if (target == null) {
    _say(context, 'No workspace folder is available.');
    return;
  }
  final name = await promptText(
    context,
    title: kind == FileKind.sql ? 'New SQL file' : 'New Mongo script',
    label: 'File name',
    initial: kind == FileKind.sql ? 'query.sql' : 'script.mongo.js',
    confirm: 'Create',
  );
  if (name == null || !context.mounted) return;
  try {
    final file = await ref
        .read(workspaceProvider.notifier)
        .createFile(target, name, kind);
    if (context.mounted) await openFileFlow(context, ref, file);
  } on WorkspaceFailure catch (e) {
    if (context.mounted) _say(context, e.message);
  }
}

/// ⌘S: saves the active tab to its file, or asks where to save it.
Future<void> saveActiveTabFlow(BuildContext context, WidgetRef ref) async {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab == null || !(tab.isQuery || tab.isShell)) return;
  final c = ref.read(tabFileProvider(tab.id).notifier);
  var out = await c.save();
  if (out is NotBound) {
    if (context.mounted) await saveTabAsFlow(context, ref, tab);
    return;
  }
  if (out is SaveConflict && context.mounted) {
    final choice = await showConflictDialog(
      context,
      deleted: out.current == null,
      name: tab.title,
    );
    if (choice == ConflictChoice.reload) {
      await c.reload();
      return;
    }
    if (choice == null) return;
    out = await c.save(force: true);
  }
  if (out is SaveFailed && context.mounted) {
    _say(context, 'Save failed: ${out.message}');
  }
}

/// Save as…: writes the tab's text to a new workspace file.
Future<void> saveTabAsFlow(
  BuildContext context,
  WidgetRef ref,
  EditorTab tab,
) async {
  if (!(tab.isQuery || tab.isShell)) return;
  final kind = tab.isShell ? FileKind.mongo : FileKind.sql;
  final req = await showSaveAsDialog(
    context,
    kind: kind,
    suggested: kind == FileKind.sql ? 'query.sql' : 'script.mongo.js',
  );
  if (req == null || !context.mounted) return;
  final connection = req.rememberConnection
      ? ref.read(fileOpenerProvider).headerFor(tab.connectionId)
      : '';
  final content = bodyForNewFile(
    kind,
    tab.controller.text,
    title: req.title,
    connection: connection,
  );
  final c = ref.read(tabFileProvider(tab.id).notifier);
  var out = await c.saveAs(req.file, content);
  if (out is SaveFailed && out.exists && context.mounted) {
    final choice = await showConflictDialog(
      context,
      deleted: false,
      name: req.file.name,
    );
    if (choice != ConflictChoice.keepMine) return;
    out = await c.saveAs(req.file, content, overwrite: true);
  }
  if (!context.mounted) return;
  if (out is SaveFailed) {
    _say(context, 'Save failed: ${out.message}');
    return;
  }
  unawaited(
    ref
        .read(workspaceProvider.notifier)
        .reveal(FilePath(req.file.root, req.file.parent)),
  );
}

/// Save as… for the active tab.
Future<void> saveActiveTabAsFlow(BuildContext context, WidgetRef ref) async {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab != null) await saveTabAsFlow(context, ref, tab);
}
