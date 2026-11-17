import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/document_tab_controller.dart';
import 'filter_builder_controller.dart';

Future<void> toggleFilterBuilder(BuildContext context, WidgetRef ref) async {
  final tab = ref
      .read(editorTabsProvider)
      .activeFor(ref.read(selectedConnectionProvider));
  if (tab == null || !tab.isCollection) return;
  final builder = ref.read(filterBuilderProvider(tab.id));
  final controller = ref.read(filterBuilderProvider(tab.id).notifier);
  if (builder.open) {
    controller.close();
    return;
  }
  final state = ref.read(documentTabProvider(tab.id));
  await controller.open(
    state.draft.filter,
    state.draft.projection,
    state.draft.sort,
    state.sessionId,
    state.database,
    state.collection,
  );
}
