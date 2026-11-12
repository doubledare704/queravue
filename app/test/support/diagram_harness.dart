// Harness for diagram widget tests: the app with a fake core, one diagram tab.

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/diagram/application/diagram_controller.dart';
import 'package:queravue/features/diagram/data/diagram_repository.dart';
import 'package:queravue/features/diagram/data/export_target.dart';
import 'package:queravue/features/workspace/data/workspace_repository.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/presentation/diagram_canvas.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';

import 'fake_connections_repository.dart';
import 'fake_diagram.dart';
import 'fake_query_repository.dart';
import 'providers.dart';
import 'shell_workspace_fakes.dart';

const shopConnection = ConnectionProfile(
  id: 'c1',
  name: 'Local PG',
  engineId: 'postgres',
);

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(version: '0.1.0-dev', protocolVersion: 9, capabilities: {'query'}),
  );
}

final shop = SchemaGraph([
  table('customers', columns: ['id', 'name']),
  table(
    'orders',
    columns: ['id', 'customer_id'],
    references: {'customer_id': 'customers'},
  ),
  table(
    'order_items',
    columns: ['id', 'order_id'],
    references: {'order_id': 'orders'},
  ),
]);

typedef DiagramEnv = ({
  ProviderContainer container,
  FakeDiagramRepository repo,
  FakeWorkspaceRepository workspace,
  FakeExportTarget exports,
  String tabId,
});

/// Records exports instead of asking for a file; [path] null cancels.
class FakeExportTarget implements ExportTarget {
  String? path = '/exports/out';
  final written = <String, Uint8List>{};
  final asked = <String>[];

  @override
  Future<String?> chooseLocation(
    String suggestedName,
    ExportFormat format,
  ) async {
    asked.add(suggestedName);
    final p = path;
    return p == null ? null : '$p.${format.extension}';
  }

  @override
  Future<void> write(String path, Uint8List bytes) async =>
      written[path] = bytes;
}

Future<DiagramEnv> openDiagram(
  WidgetTester tester,
  FakeDiagramRepository repo, {
  Set<String> capabilities = const {'connect', 'execute', 'schema_graph'},
  bool settle = true,
  FakeWorkspaceRepository? workspace,
  List<ConnectionProfile> connections = const [shopConnection],
  bool openTab = true,
}) async {
  final files = workspace ?? FakeWorkspaceRepository();
  final exports = FakeExportTarget();
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(
        FakeConnectionsRepository(initial: connections)
          ..engines = [
            EngineSpec(
              id: pgEngine.id,
              displayName: pgEngine.displayName,
              family: pgEngine.family,
              capabilities: capabilities,
              fields: pgEngine.fields,
            ),
          ],
      ),
      workspaceRepositoryProvider.overrideWithValue(files),
      exportTargetProvider.overrideWithValue(exports),
      queryRepositoryProvider.overrideWithValue(
        FakeQueryRepository()..capabilities = capabilities,
      ),
      diagramRepositoryProvider.overrideWithValue(repo),
      schemaRepositoryProvider.overrideWithValue(EmptySchemaRepository()),
      coreStatusProvider.overrideWith(_Connected.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  container.read(selectedConnectionProvider.notifier).select('c1');
  final tabId = openTab
      ? container
            .read(editorTabsProvider.notifier)
            .openDiagram('c1', schema: 'public')
            .id
      : '';
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return (
    container: container,
    repo: repo,
    workspace: files,
    exports: exports,
    tabId: tabId,
  );
}

DiagramReady ready(DiagramEnv env) =>
    env.container.read(diagramProvider(env.tabId)) as DiagramReady;

DiagramCanvasState canvasOf(WidgetTester tester) =>
    tester.state<DiagramCanvasState>(find.byType(DiagramCanvas));

Offset onScreen(WidgetTester tester, Offset diagramPoint) =>
    tester.getTopLeft(find.byType(DiagramCanvas)) +
    canvasOf(tester).toScreen(diagramPoint);
