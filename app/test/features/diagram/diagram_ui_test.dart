import 'dart:async';

import 'package:flutter/gestures.dart';
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
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/presentation/diagram_canvas.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_diagram.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';
import '../../support/shell_workspace_fakes.dart';

const _conn = ConnectionProfile(
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
  String tabId,
});

Future<DiagramEnv> openDiagram(
  WidgetTester tester,
  FakeDiagramRepository repo, {
  Set<String> capabilities = const {'connect', 'execute', 'schema_graph'},
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(FakeConnectionsRepository(initial: const [_conn])),
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
  final tab = container
      .read(editorTabsProvider.notifier)
      .openDiagram('c1', schema: 'public');
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return (container: container, repo: repo, tabId: tab.id);
}

DiagramReady ready(DiagramEnv env) =>
    env.container.read(diagramProvider(env.tabId)) as DiagramReady;

DiagramCanvasState canvasOf(WidgetTester tester) =>
    tester.state<DiagramCanvasState>(find.byType(DiagramCanvas));

Offset onScreen(WidgetTester tester, Offset diagramPoint) =>
    tester.getTopLeft(find.byType(DiagramCanvas)) +
    canvasOf(tester).toScreen(diagramPoint);

void main() {
  testWidgets('a loaded schema is summarised and fits the view', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    expect(find.text('3 tables · 2 relations'), findsOneWidget);
    expect(env.repo.requests.single, (
      database: '',
      schema: 'public',
      refresh: false,
    ));
    final canvas = canvasOf(tester);
    final size = tester.getSize(find.byType(DiagramCanvas));
    expect(canvas.scale, lessThanOrEqualTo(1));
    for (final rect in ready(env).rects.values) {
      final shown = Rect.fromPoints(
        canvas.toScreen(rect.topLeft),
        canvas.toScreen(rect.bottomRight),
      );
      expect((Offset.zero & size).contains(shown.topLeft), isTrue);
      expect((Offset.zero & size).contains(shown.bottomRight), isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging a table moves it and selects it', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final before = ready(env).rects['orders']!;
    final others = ready(env).rects['customers']!;
    final scale = canvasOf(tester).scale;
    await tester.dragFrom(
      onScreen(tester, before.center),
      const Offset(60, 40),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    final after = ready(env).rects['orders']!;
    expect(after.left, closeTo(before.left + 60 / scale, 0.5));
    expect(after.top, closeTo(before.top + 40 / scale, 0.5));
    expect(ready(env).rects['customers'], others);
    expect(ready(env).selected, 'orders');
  });

  testWidgets('dragging the background pans and clears the selection', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    env.container.read(diagramProvider(env.tabId).notifier).select('orders');
    final offset = canvasOf(tester).offset;
    final rects = ready(env).rects;
    final corner =
        tester.getTopLeft(find.byType(DiagramCanvas)) + const Offset(6, 6);
    await tester.dragFrom(
      corner,
      const Offset(30, 20),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(canvasOf(tester).offset, offset + const Offset(30, 20));
    expect(ready(env).rects, rects);
    expect(ready(env).selected, isNull);
  });

  testWidgets('zoom buttons, fit and automatic arrangement', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final fitted = canvasOf(tester).scale;
    await tester.tap(find.byKey(const Key('diagram-zoom-in')));
    await tester.pump();
    expect(canvasOf(tester).scale, closeTo(fitted * 1.25, 1e-9));
    expect(find.text('${(fitted * 125).round()}%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('diagram-fit')));
    await tester.pump();
    expect(canvasOf(tester).scale, closeTo(fitted, 1e-9));

    final arranged = ready(env).rects;
    env.container
        .read(diagramProvider(env.tabId).notifier)
        .moveTable('orders', const Offset(500, 500));
    await tester.pump();
    await tester.tap(find.byKey(const Key('diagram-relayout')));
    await tester.pumpAndSettle();
    expect(ready(env).rects, arranged);
  });

  testWidgets('scrolling pans, scrolling with Ctrl zooms at the pointer', (
    tester,
  ) async {
    await openDiagram(tester, FakeDiagramRepository(shop));
    final centre = tester.getCenter(find.byType(DiagramCanvas));
    final pointer = TestPointer(1, PointerDeviceKind.mouse)..hover(centre);
    final offset = canvasOf(tester).offset;
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 50)));
    await tester.pump();
    expect(canvasOf(tester).offset, offset - const Offset(0, 50));

    final local = centre - tester.getTopLeft(find.byType(DiagramCanvas));
    final fixed = canvasOf(tester).toDiagram(local);
    final scale = canvasOf(tester).scale;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();
    expect(canvasOf(tester).scale, greaterThan(scale));
    final stillThere = canvasOf(tester).toDiagram(local);
    expect(stillThere.dx, closeTo(fixed.dx, 0.01));
    expect(stillThere.dy, closeTo(fixed.dy, 0.01));
  });

  testWidgets('a double click opens the table', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final at = onScreen(tester, ready(env).rects['customers']!.center);
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    final active = env.container.read(editorTabsProvider).activeFor('c1')!;
    expect(active.isTable, isTrue);
    expect(active.tableRef!.table, 'customers');
    expect(active.tableRef!.schema, 'public');
  });

  testWidgets('an empty schema says so', (tester) async {
    await openDiagram(tester, FakeDiagramRepository());
    expect(find.byKey(const Key('diagram-empty')), findsOneWidget);
    expect(find.byType(DiagramCanvas), findsNothing);
  });

  testWidgets('a failure is shown and Retry reloads', (tester) async {
    final repo = FakeDiagramRepository(shop)..failure = 'permission denied';
    await openDiagram(tester, repo);
    expect(find.text('permission denied'), findsOneWidget);
    repo.failure = null;
    await tester.tap(find.byKey(const Key('diagram-retry')));
    await tester.pumpAndSettle();
    expect(find.byType(DiagramCanvas), findsOneWidget);
    expect(repo.requests.last.refresh, isTrue);
  });

  testWidgets('loading shows progress and can be cancelled', (tester) async {
    final repo = FakeDiagramRepository(generatedGraph(120))
      ..hold = Completer<void>();
    await openDiagram(tester, repo, settle: false);
    expect(find.text('Loading tables 120 / 120'), findsOneWidget);
    await tester.tap(find.byKey(const Key('diagram-cancel')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(repo.cancelled, 1);
    repo.hold!.complete();
  });

  testWidgets('500 tables open without building a widget per table', (
    tester,
  ) async {
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(generatedGraph(500)),
    );
    expect(ready(env).graph.tables, hasLength(500));
    expect(find.text('500 tables · 480 relations'), findsOneWidget);
    expect(find.text('t000'), findsNothing);
    expect(canvasOf(tester).scale, lessThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the palette action needs the schema_graph capability', (
    tester,
  ) async {
    final without = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      capabilities: const {'connect', 'execute'},
    );
    expect(
      without.container.read(enabledActionIdsProvider),
      isNot(contains('diagram.open')),
    );
  });

  testWidgets('the palette action is enabled with the capability', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    expect(
      env.container.read(enabledActionIdsProvider),
      contains('diagram.open'),
    );
  });
}
