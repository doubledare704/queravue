import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../domain/query_models.dart';
import '../../documents/application/document_tab_controller.dart';
import '../../shell/application/shell_actions.dart';
import '../../shell/application/shell_tab_controller.dart';
import 'editor_layout_controller.dart';
import 'editor_tabs.dart';

/// Opens an editor tab for the selected connection (⌘T).
void openQueryTab(WidgetRef ref) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null && !ref.read(connectionIsDocumentOnlyProvider(id))) {
    ref.read(editorTabsProvider.notifier).open(id);
  }
}

/// Opens a Mongo shell tab for the selected connection (⌘⇧T).
void openShellTab(WidgetRef ref) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null && ref.read(connectionHasShellProvider(id))) {
    final active = ref.read(editorTabsProvider).activeFor(id);
    final database = active != null && active.isCollection
        ? active.tableRef?.database ?? ''
        : '';
    ref.read(editorTabsProvider.notifier).openShell(id, database: database);
  }
}

/// Closes the active editor tab of the selected connection (⌘W).
void closeQueryTab(WidgetRef ref) {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab != null) ref.read(editorTabsProvider.notifier).close(tab.id);
}

/// Runs in the active tab of the selected connection. In a collection tab it
/// runs the document query instead.
Future<void> runActiveTab(WidgetRef ref, ExecuteMode mode) async {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab != null && tab.isCollection) {
    await ref.read(documentTabProvider(tab.id).notifier).runDraft();
  } else if (tab != null && tab.isShell) {
    await runShellTab(ref, tab);
  } else if (tab != null) {
    await ref.read(editorTabsProvider.notifier).run(tab.id, mode);
  }
}

/// Cancels the running statement of the active tab.
Future<void> cancelActiveTab(WidgetRef ref) async {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab != null && tab.isCollection) {
    await ref.read(documentTabProvider(tab.id).notifier).cancel();
  } else if (tab != null && tab.isShell) {
    await ref.read(shellTabProvider(tab.id).notifier).cancel();
  } else if (tab != null) {
    await ref.read(editorTabsProvider.notifier).cancel(tab.id);
  }
}

/// Splits the focused group, moving its active tab into a new group.
void splitEditor(WidgetRef ref, Axis along) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null) ref.read(editorLayoutProvider.notifier).split(id, along);
}

/// Focuses the group [delta] places from the focused one, wrapping around.
void focusEditorGroup(WidgetRef ref, int delta) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null) {
    ref.read(editorLayoutProvider.notifier).focusRelative(id, delta);
  }
}

/// Moves the active tab into the group [delta] places away.
void moveTabToGroup(WidgetRef ref, int delta) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null) ref.read(editorLayoutProvider.notifier).moveActive(id, delta);
}

/// Focuses the editor group at [index], counted from 0.
void focusEditorGroupAt(WidgetRef ref, int index) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null) ref.read(editorLayoutProvider.notifier).focusGroup(id, index);
}
