import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/actions/app_action.dart';
import '../../../connections/application/connection_session.dart';
import '../../../connections/application/connections_controller.dart';
import '../../../editor/application/editor_tabs.dart';
import '../presentation/pipeline_builder_view.dart';
import 'pipeline_builder_controller.dart';

bool connectionHasDocumentStore(Set<String>? capabilities) =>
    capabilities?.contains('document_store') ?? false;

bool canBuildPipelineForActiveTab(ActionWatch watch) {
  final connection = watch(selectedConnectionProvider);
  final tab = watch(editorTabsProvider).activeFor(connection);
  return connection != null &&
      tab != null &&
      tab.isCollection &&
      connectionHasDocumentStore(
        watch(connectionCapabilitiesProvider(connection)),
      );
}

Future<void> openPipelineBuilderForActiveTab(
  BuildContext context,
  WidgetRef ref,
) async {
  final connection = ref.read(selectedConnectionProvider);
  final tab = ref.read(editorTabsProvider).activeFor(connection);
  final collection = tab?.tableRef;
  if (connection == null || collection == null) {
    return;
  }
  await showPipelineBuilder(
    context,
    PipelineTarget(
      connectionId: connection,
      database: collection.database,
      collection: collection.table,
    ),
  );
}
