import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../presentation/document_dialogs.dart';
import 'document_tab_controller.dart';

/// The active tab of the selected connection, if it is a collection tab.
EditorTab? _activeCollectionTab(WidgetRef ref) {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  return tab != null && tab.isCollection ? tab : null;
}

/// Runs the query bar of the active collection tab (command palette).
Future<void> runDocumentQuery(WidgetRef ref) async {
  final tab = _activeCollectionTab(ref);
  if (tab != null) {
    await ref.read(documentTabProvider(tab.id).notifier).runDraft();
  }
}

/// Re-runs the current query of the active collection tab.
Future<void> refreshDocuments(WidgetRef ref) async {
  final tab = _activeCollectionTab(ref);
  if (tab != null) {
    await ref.read(documentTabProvider(tab.id).notifier).refresh();
  }
}

/// Opens the insert dialog on the active collection tab.
void insertDocument(BuildContext context, WidgetRef ref) {
  final tab = _activeCollectionTab(ref);
  if (tab != null) showDocumentEditor(context, tabId: tab.id);
}
