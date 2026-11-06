import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../domain/query_models.dart';
import '../../documents/application/document_tab_controller.dart';
import 'editor_tabs.dart';

/// Opens an editor tab for the selected connection (⌘T).
void openQueryTab(WidgetRef ref) {
  final id = ref.read(selectedConnectionProvider);
  if (id != null && !ref.read(connectionIsDocumentOnlyProvider(id))) {
    ref.read(editorTabsProvider.notifier).open(id);
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
  } else if (tab != null) {
    await ref.read(editorTabsProvider.notifier).cancel(tab.id);
  }
}
