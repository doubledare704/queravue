import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/application/diagram_controller.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/keybindings/application/keybindings_controller.dart';
import 'package:queravue/features/workspace/application/tab_files.dart';
import 'package:queravue/features/workspace/domain/workspace_models.dart';

import '../../support/diagram_harness.dart';
import '../../support/fake_diagram.dart';
import '../../support/shell_workspace_fakes.dart';

const _shopFile = '.queravue/diagrams/shop.json';

Future<void> chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
  bool alt = false,
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

Future<void> answerPrompt(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('prompt-field')), text);
  await tester.tap(find.byKey(const Key('prompt-ok')));
  await tester.pumpAndSettle();
}

EditorTab tabOf(DiagramEnv env, String id) =>
    env.container.read(editorTabsProvider).tabs.firstWhere((t) => t.id == id);

SavedDiagram savedIn(FakeWorkspaceRepository ws, String path) =>
    SavedDiagram.fromJson(ws.contents[path]!)!;

String savedState(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('diagram-saved-state'))).data!;

void main() {
  testWidgets('right-click hides a table; Show brings it back in place', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final rect = ready(env).rects['orders']!;
    await tester.tapAt(
      onScreen(tester, rect.center),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide from diagram'));
    await tester.pumpAndSettle();
    expect(ready(env).hidden, {'orders'});
    expect(ready(env).visibleGraph.tables.map((t) => t.name), [
      'customers',
      'order_items',
    ]);
    expect(ready(env).visibleRects.containsKey('orders'), isFalse);
    expect(savedState(tester), 'not saved');
    expect(
      env.container.read(enabledActionIdsProvider),
      contains('diagram.showHidden'),
    );

    await tester.tap(find.byKey(const Key('diagram-show-hidden')));
    await tester.pumpAndSettle();
    expect(ready(env).hidden, isEmpty);
    expect(ready(env).rects['orders'], rect);
    expect(find.byKey(const Key('diagram-show-hidden')), findsNothing);
  });

  testWidgets('a table that lost its spot while hidden comes back beside', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final controller = env.container.read(diagramProvider(env.tabId).notifier);
    final ordersAt = ready(env).rects['orders']!;
    controller.hide('orders');
    final customers = ready(env).rects['customers']!;
    controller.moveTable('customers', ordersAt.topLeft - customers.topLeft);
    controller.showAll();
    final back = ready(env).rects['orders']!;
    final others = ready(env).rects.entries.where((e) => e.key != 'orders');
    expect(others.any((e) => e.value.overlaps(back)), isFalse);
  });

  testWidgets('⌘S asks for a name, saves, and saves again without asking', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    env.container.read(diagramProvider(env.tabId).notifier).hide('order_items');
    await tester.pumpAndSettle();
    await chord(tester, LogicalKeyboardKey.keyS);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('prompt-field')))
          .controller!
          .text,
      'public',
    );
    await answerPrompt(tester, 'shop');

    final saved = savedIn(env.workspace, _shopFile);
    expect(saved.connectionId, 'c1');
    expect(saved.connectionName, 'Local PG');
    expect(saved.schema, 'public');
    expect(saved.hidden, {'order_items'});
    expect(
      saved.positions.keys,
      unorderedEquals(['customers', 'orders', 'order_items']),
    );
    expect(saved.positions['orders'], ready(env).rects['orders']!.topLeft);
    expect(tabOf(env, env.tabId).title, 'shop');
    expect(tabOf(env, env.tabId).diagramFile, const FilePath('ws', _shopFile));
    expect(savedState(tester), 'shop');

    env.container
        .read(diagramProvider(env.tabId).notifier)
        .moveTable('orders', const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(savedState(tester), 'shop · changed');
    await chord(tester, LogicalKeyboardKey.keyS);
    expect(find.byKey(const Key('prompt-field')), findsNothing);
    expect(
      savedIn(env.workspace, _shopFile).positions['orders'],
      ready(env).rects['orders']!.topLeft,
    );
    expect(savedState(tester), 'shop');
  });

  testWidgets('saving under a taken name asks before replacing it', (
    tester,
  ) async {
    final ws = FakeWorkspaceRepository(
      files: {_shopFile: const SavedDiagram(connectionId: 'other').toJson()},
    );
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      workspace: ws,
    );
    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, 'shop');
    expect(find.text('Replace "shop"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(savedIn(ws, _shopFile).connectionId, 'other');
    expect(tabOf(env, env.tabId).diagramFile, isNull);

    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, 'shop');
    await tester.tap(find.byKey(const Key('diagram-replace')));
    await tester.pumpAndSettle();
    expect(savedIn(ws, _shopFile).connectionId, 'c1');
  });

  testWidgets('a name that cannot be a file name is refused', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, '../escape');
    expect(find.textContaining('Use letters, digits'), findsOneWidget);
    expect(env.workspace.contents.keys, isEmpty);
  });

  testWidgets('a saved diagram opens with its arrangement on its connection', (
    tester,
  ) async {
    final ws = FakeWorkspaceRepository(
      files: {
        _shopFile: const SavedDiagram(
          connectionId: 'gone',
          connectionName: 'Local PG',
          schema: 'public',
          positions: {'customers': Offset(500, 500), 'orders': Offset(0, 0)},
          hidden: {'orders'},
        ).toJson(),
      },
    );
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      workspace: ws,
      openTab: false,
    );
    final out = await env.container
        .read(fileOpenerProvider)
        .open(const FilePath('ws', _shopFile));
    await tester.pumpAndSettle();
    expect(out, isA<Opened>(), reason: out is OpenFailed ? out.message : '');
    final tabId = (out as Opened).tabId;
    final tab = tabOf(env, tabId);
    expect(tab.title, 'shop');
    expect(tab.connectionId, 'c1');
    expect(tab.tableRef!.schema, 'public');
    final state = env.container.read(diagramProvider(tabId)) as DiagramReady;
    expect(state.rects['customers']!.topLeft, const Offset(500, 500));
    expect(state.hidden, {'orders'});
    expect(
      state.rects['order_items']!.left,
      greaterThan(state.rects['customers']!.right),
    );
    expect(state.dirty, isFalse);
    expect(env.repo.requests.single.schema, 'public');

    final again = await env.container
        .read(fileOpenerProvider)
        .open(const FilePath('ws', _shopFile));
    expect((again as Opened).tabId, tabId);
    expect(
      env.container.read(editorTabsProvider).tabs.where((t) => t.isDiagram),
      hasLength(1),
    );
  });

  testWidgets('a saved diagram of an unknown connection does not open', (
    tester,
  ) async {
    final ws = FakeWorkspaceRepository(
      files: {
        _shopFile: const SavedDiagram(
          connectionId: 'x',
          connectionName: 'Production',
        ).toJson(),
        '.queravue/diagrams/junk.json': '{"hello": 1}',
      },
    );
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      workspace: ws,
      openTab: false,
    );
    final opener = env.container.read(fileOpenerProvider);
    final missing = await opener.open(const FilePath('ws', _shopFile));
    expect((missing as OpenFailed).message, contains('"Production"'));
    final junk = await opener.open(
      const FilePath('ws', '.queravue/diagrams/junk.json'),
    );
    expect((junk as OpenFailed).message, contains('not a Queravue diagram'));
  });

  testWidgets('a bound file that is gone falls back to the automatic layout', (
    tester,
  ) async {
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      openTab: false,
    );
    final tab = env.container
        .read(editorTabsProvider.notifier)
        .openDiagram(
          'c1',
          schema: 'public',
          savedFile: const FilePath('ws', _shopFile),
          title: 'shop',
        );
    await tester.pumpAndSettle();
    final state = env.container.read(diagramProvider(tab.id)) as DiagramReady;
    expect(state.graph.tables, hasLength(3));
    expect(state.notice, contains('shop.json does not exist'));
    expect(find.byKey(const Key('diagram-notice')), findsOneWidget);
    expect(tabOf(env, tab.id).diagramFile, isNull);
  });

  testWidgets('Reload keeps the arrangement and the unsaved state', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    final controller = env.container.read(diagramProvider(env.tabId).notifier);
    controller
      ..moveTable('orders', const Offset(70, 30))
      ..hide('customers');
    final rects = ready(env).rects;
    await tester.tap(find.byKey(const Key('diagram-refresh')));
    await tester.pumpAndSettle();
    expect(env.repo.requests.last.refresh, isTrue);
    expect(ready(env).rects, rects);
    expect(ready(env).hidden, {'customers'});
    expect(ready(env).dirty, isTrue);
  });

  testWidgets('export writes the shown tables as SVG and PNG', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    env.container.read(diagramProvider(env.tabId).notifier).hide('customers');
    await tester.pumpAndSettle();
    expect(
      env.container.read(enabledActionIdsProvider),
      containsAll(['diagram.exportSvg', 'diagram.exportPng', 'workspace.save']),
    );

    await chord(tester, LogicalKeyboardKey.keyE, shift: true);
    final svg = utf8.decode(env.exports.written['/exports/out.svg']!);
    expect(env.exports.asked.last, 'Diagram public.svg');
    expect(svg, contains('>orders</text>'));
    expect(svg, isNot(contains('>customers</text>')));
    expect(find.textContaining('Exported out.svg'), findsOneWidget);

    await tester.runAsync(
      () => chord(tester, LogicalKeyboardKey.keyE, shift: true, alt: true),
    );
    for (var i = 0; i < 20 && env.exports.written.length < 2; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    final png = env.exports.written['/exports/out.png']!;
    expect(png.sublist(1, 4), utf8.encode('PNG'));

    env.exports.path = null;
    await tester.tap(find.byKey(const Key('diagram-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagram-export-svg')));
    await tester.pumpAndSettle();
    expect(env.exports.written, hasLength(2));
  });

  testWidgets('export and show-hidden are off outside a ready diagram', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository());
    final enabled = env.container.read(enabledActionIdsProvider);
    expect(enabled, isNot(contains('diagram.exportSvg')));
    expect(enabled, isNot(contains('diagram.showHidden')));
    expect(enabled, contains('workspace.save'));
    expect(enabled, contains('diagram.openSaved'));
  });

  testWidgets('Open saved diagram lists the workspace diagrams', (
    tester,
  ) async {
    final ws = FakeWorkspaceRepository(
      files: {
        _shopFile: const SavedDiagram(
          connectionId: 'c1',
          schema: 'public',
        ).toJson(),
        '.queravue/diagrams/notes.txt': 'not a diagram',
      },
    );
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      workspace: ws,
      openTab: false,
      connections: const [shopConnection],
    );
    await chord(tester, LogicalKeyboardKey.keyK);
    await tester.enterText(
      find.byKey(const Key('palette-query')),
      '>open saved',
    );
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('notes'), findsNothing);
    await tester.tap(find.byKey(const Key('saved-diagram-shop.json')));
    await tester.pumpAndSettle();
    final active = env.container.read(editorTabsProvider).activeFor('c1')!;
    expect(active.isDiagram, isTrue);
    expect(active.title, 'shop');
  });
}
