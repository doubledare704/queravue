import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_layout_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/editor_layout.dart';
import 'package:queravue/features/editor/presentation/query_tab_view.dart';
import 'package:queravue/features/editor/presentation/sql_editor.dart';

import 'package:queravue/features/workspace/presentation/left_sidebar.dart';
import 'package:queravue/shared/panes/pane_sizes.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/fake_query_repository.dart';
import '../../support/providers.dart';

const _conn = ConnectionProfile(
  id: 'c1',
  name: 'Local PG',
  engineId: 'postgres',
);

class _Connected extends CoreStatusController {
  @override
  CoreStatus build() => const CoreConnected(
    CoreInfo(version: '0.1.0-dev', protocolVersion: 3, capabilities: {'query'}),
  );
}

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      ...fakeCoreOverrides(FakeConnectionsRepository(initial: const [_conn])),
      queryRepositoryProvider.overrideWithValue(FakeQueryRepository()),
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
  await tester.pumpAndSettle();
  return container;
}

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool alt = false,
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pumpAndSettle();
}

EditorLayout layoutOf(ProviderContainer c) =>
    c.read(editorLayoutProvider).of('c1');

void main() {
  testWidgets('only the shown tab of a group is built', (tester) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    tabs.open('c1');
    tabs.open('c1');
    await tester.pumpAndSettle();
    expect(find.byType(QueryTabView), findsOneWidget);
  });

  testWidgets('the tab menu splits the editor into two groups', (tester) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    final second = tabs.open('c1');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('tab-${second.id}')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Split right'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-bar-0')), findsOneWidget);
    expect(find.byKey(const Key('group-bar-1')), findsOneWidget);
    expect(find.byType(QueryTabView), findsNWidgets(2));
  });

  testWidgets('dragging the divider resizes the groups', (tester) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    final before = layoutOf(c).fractions[0];
    await tester.drag(
      find.byKey(const Key('group-divider-0')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(layoutOf(c).fractions[0], greaterThan(before));
  });

  testWidgets('shortcuts split, move focus and move tabs', (tester) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    tabs.open('c1');
    await tester.pumpAndSettle();
    await chord(tester, LogicalKeyboardKey.backslash);
    expect(layoutOf(c).groups.length, 2);
    expect(layoutOf(c).focused, 1);
    await chord(tester, LogicalKeyboardKey.arrowLeft, alt: true);
    expect(layoutOf(c).focused, 0);
    await chord(tester, LogicalKeyboardKey.arrowRight, alt: true);
    expect(layoutOf(c).focused, 1);
  });

  testWidgets('clicking a group focuses it and shows its tab as active', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    final first = tabs.open('c1');
    tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('tab-${first.id}')));
    await tester.pumpAndSettle();
    expect(layoutOf(c).focused, 0);
    expect(c.read(editorTabsProvider).activeByConnection['c1'], first.id);
  });

  Future<void> mouseDrag(WidgetTester tester, Finder from, Finder to) async {
    final gesture = await tester.startGesture(
      tester.getCenter(from),
      kind: PointerDeviceKind.mouse,
    );
    final end = tester.getCenter(to);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(end - const Offset(4, 0));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a tab onto another group moves it there', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    final first = tabs.open('c1');
    final second = tabs.open('c1');
    final third = tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    await mouseDrag(
      tester,
      find.byKey(Key('tab-${first.id}')),
      find.byKey(const Key('group-1')),
    );
    expect(layoutOf(c).groups.map((g) => g.tabIds), [
      [second.id],
      [third.id, first.id],
    ]);
    expect(c.read(editorTabsProvider).activeByConnection['c1'], first.id);
  });

  testWidgets('dragging a tab onto a tab puts it in front of that tab', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    final first = tabs.open('c1');
    final second = tabs.open('c1');
    final third = tabs.open('c1');
    await tester.pumpAndSettle();
    await mouseDrag(
      tester,
      find.byKey(Key('tab-${third.id}')),
      find.byKey(Key('tab-${first.id}')),
    );
    expect(layoutOf(c).groups.single.tabIds, [third.id, first.id, second.id]);
  });

  testWidgets('dragging the only tab of a group away closes the group', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    final second = tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    await mouseDrag(
      tester,
      find.byKey(Key('tab-${second.id}')),
      find.byKey(const Key('group-0')),
    );
    expect(layoutOf(c).groups, hasLength(1));
    expect(find.byKey(const Key('group-bar-1')), findsNothing);
  });

  testWidgets('maximize shows only the focused group and no sidebar', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    final fullWidth = tester.getSize(find.byType(HomeScreen)).width;

    await tester.tap(find.byKey(const Key('maximize-group-1')));
    await tester.pumpAndSettle();
    expect(find.byType(LeftSidebar), findsNothing);
    expect(find.byKey(const Key('group-bar-0')), findsNothing);
    expect(find.byKey(const Key('group-divider-0')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('group-1'))).width, fullWidth);
    expect(layoutOf(c).groups, hasLength(2));

    await chord(tester, LogicalKeyboardKey.keyM, shift: true);
    expect(find.byType(LeftSidebar), findsOneWidget);
    expect(find.byKey(const Key('group-bar-0')), findsOneWidget);
  });

  testWidgets('the sidebar resizes by its edge and collapses', (tester) async {
    final c = await pumpApp(tester);
    await tester.drag(
      find.byKey(const Key('sidebar-divider')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();
    expect(c.read(paneSizesProvider).sidebarWidth, greaterThan(260));
    expect(
      tester.getSize(find.byType(LeftSidebar)).width,
      c.read(paneSizesProvider).sidebarWidth,
    );
    await chord(tester, LogicalKeyboardKey.keyB);
    expect(find.byType(LeftSidebar), findsNothing);
    await chord(tester, LogicalKeyboardKey.keyB);
    expect(find.byType(LeftSidebar), findsOneWidget);
  });

  testWidgets('the results pane resizes and collapses under the editor', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    c.read(editorTabsProvider.notifier).open('c1');
    await tester.pumpAndSettle();
    final before = c.read(paneSizesProvider).editorShare;
    await tester.drag(
      find.byKey(const Key('output-divider')),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    expect(c.read(paneSizesProvider).editorShare, greaterThan(before));
    final editorHeight = tester.getSize(find.byType(SqlEditor)).height;
    await chord(tester, LogicalKeyboardKey.keyJ);
    expect(
      tester.getSize(find.byType(SqlEditor)).height,
      greaterThan(editorHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary+digit focuses that group', (tester) async {
    final c = await pumpApp(tester);
    final tabs = c.read(editorTabsProvider.notifier);
    tabs.open('c1');
    tabs.open('c1');
    c.read(editorLayoutProvider.notifier).split('c1', Axis.horizontal);
    await tester.pumpAndSettle();
    await chord(tester, LogicalKeyboardKey.digit1);
    expect(layoutOf(c).focused, 0);
    await chord(tester, LogicalKeyboardKey.digit2);
    expect(layoutOf(c).focused, 1);
  });
}
