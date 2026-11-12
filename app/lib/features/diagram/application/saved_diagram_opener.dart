import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../connections/domain/models.dart';
import '../../editor/application/editor_tabs.dart';
import '../../workspace/application/tab_files.dart';
import '../../workspace/domain/workspace_models.dart';
import '../data/diagram_files.dart';
import '../domain/diagram_models.dart';
import '../domain/saved_diagram.dart';

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Opens the saved diagram [file] on the connection it names, or focuses the
/// tab that shows it already.
Future<OpenOutcome> openSavedDiagram(ProviderReader read, FilePath file) async {
  final tabs = read(editorTabsProvider.notifier);
  final open = read(editorTabsProvider).tabs
      .where((t) => t.isDiagram && t.diagramFile == file)
      .firstOrNull;
  if (open != null) {
    read(selectedConnectionProvider.notifier).select(open.connectionId);
    tabs.select(open.id);
    return Opened(open.id);
  }
  final SavedDiagram saved;
  try {
    saved = await read(diagramFilesProvider).read(file);
  } on DiagramFailure catch (e) {
    return OpenFailed(e.message);
  }
  final List<ConnectionProfile> profiles;
  try {
    profiles = await read(connectionsControllerProvider.future);
  } catch (_) {
    return const OpenFailed('Connections are not available yet.');
  }
  final profile =
      profiles.where((p) => p.id == saved.connectionId).firstOrNull ??
      profiles
          .where(
            (p) =>
                saved.connectionName.isNotEmpty &&
                p.name == saved.connectionName,
          )
          .firstOrNull;
  if (profile == null) {
    final named = saved.connectionName.isEmpty
        ? 'its connection'
        : '"${saved.connectionName}"';
    return OpenFailed('${file.name} needs $named, which does not exist here.');
  }
  final connectionId = profile.id;
  if (!read(connectionHasSchemaGraphProvider(connectionId))) {
    return OpenFailed('${profile.name} cannot show schema diagrams.');
  }
  final tab = tabs.openDiagram(
    connectionId,
    database: saved.database,
    schema: saved.schema,
    savedFile: file,
    title: diagramNameOf(file),
  );
  read(selectedConnectionProvider.notifier).select(connectionId);
  return Opened(tab.id);
}
