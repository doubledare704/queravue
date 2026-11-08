import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/command_palette/presentation/command_palette.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/connections/presentation/connection_sidebar.dart';

import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

const _prod = ConnectionProfile(
  id: 'p',
  name: 'Prod DB',
  engineId: 'postgres',
  folder: 'Work',
  color: ColorTag.red,
  production: true,
  hasPassword: true,
);
const _local = ConnectionProfile(
  id: 'l',
  name: 'Local file',
  engineId: 'sqlite',
);

Future<void> pumpSidebar(
  WidgetTester tester,
  FakeConnectionsRepository repo, {
  bool ready = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeCoreOverrides(repo, ready: ready),
      child: const MaterialApp(
        home: Scaffold(body: SizedBox(width: 260, child: ConnectionSidebar())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows folders, color dot and PROD badge', (tester) async {
    await pumpSidebar(
      tester,
      FakeConnectionsRepository(initial: [_prod, _local]),
    );
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Prod DB'), findsOneWidget);
    expect(find.text('Local file'), findsOneWidget);
    expect(find.byKey(const Key('prod-badge')), findsOneWidget);

    final dot = tester.widget<Container>(find.byKey(const Key('color-dot-p')));
    expect((dot.decoration! as BoxDecoration).color, Colors.red);

    await tester.tap(find.byKey(const Key('folder-Work')));
    await tester.pumpAndSettle();
    expect(find.text('Prod DB'), findsNothing, reason: 'folder collapsed');
  });

  testWidgets('empty state offers New connection', (tester) async {
    await pumpSidebar(tester, FakeConnectionsRepository());
    expect(find.text('No connections yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'New connection'), findsOneWidget);
  });

  testWidgets('core not connected shows an error with retry', (tester) async {
    await pumpSidebar(tester, FakeConnectionsRepository(), ready: false);
    expect(find.text('Core not connected'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation', (tester) async {
    final repo = FakeConnectionsRepository(initial: [_prod, _local]);
    await pumpSidebar(tester, repo);

    Future<void> openDelete() async {
      await tester.tap(find.byKey(const Key('connection-menu-p')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete…'));
      await tester.pumpAndSettle();
    }

    await openDelete();
    expect(find.text('Delete "Prod DB"?'), findsOneWidget);
    expect(find.textContaining('saved password'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.items, hasLength(2));

    await openDelete();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(repo.items.map((c) => c.id), ['l']);
    expect(find.text('Prod DB'), findsNothing);
  });

  testWidgets('double-click connects and shows the result', (tester) async {
    final repo = FakeConnectionsRepository(initial: [_local]);
    await pumpSidebar(tester, repo);
    await tester.tap(find.byKey(const Key('connection-l')));
    await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 1));
    await tester.tap(find.byKey(const Key('connection-l')));
    await tester.pumpAndSettle();
    expect(repo.testCalls.single.id, 'l');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  test('palette fuzzy match', () {
    expect(fuzzyMatch('lpg', 'Connect: Local PG'), isTrue);
    expect(fuzzyMatch('new', 'New connection'), isTrue);
    expect(fuzzyMatch('xyz', 'New connection'), isFalse);
    expect(fuzzyMatch('', 'anything'), isTrue);
  });
}
