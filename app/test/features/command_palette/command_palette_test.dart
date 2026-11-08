import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/command_palette/application/palette_items.dart';
import 'package:queravue/features/command_palette/domain/palette_search.dart';
import 'package:queravue/features/command_palette/presentation/command_palette.dart';
import 'package:queravue/features/workspace/data/workspace_repository.dart';

import '../../support/shell_workspace_fakes.dart';

void main() {
  late List<String> ran;

  PaletteItem item(String title, PaletteGroup group, {String shortcut = ''}) =>
      PaletteItem(
        id: '${group.name}.$title',
        title: title,
        group: group,
        trailing: shortcut,
        run: (_, _) async => ran.add(title),
      );

  Future<void> pumpPalette(
    WidgetTester tester, {
    String initialQuery = '',
    Map<String, String> files = const {},
  }) async {
    ran = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paletteItemsProvider.overrideWithValue([
            item('New query tab', PaletteGroup.action, shortcut: '⌘T'),
            item('Run statement', PaletteGroup.action, shortcut: '⌘↵'),
            item('orders', PaletteGroup.tab),
            item('orders', PaletteGroup.object),
            item('users', PaletteGroup.object),
          ]),
          workspaceRepositoryProvider.overrideWithValue(
            FakeWorkspaceRepository(files: files),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showCommandPalette(
                  context,
                  ref,
                  initialQuery: initialQuery,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('actions show their shortcut; objects wait for a query', (
    tester,
  ) async {
    await pumpPalette(tester);
    expect(find.text('⌘T'), findsOneWidget);
    expect(find.text('⌘↵'), findsOneWidget);
    expect(find.text('users'), findsNothing);
  });

  testWidgets('a > prefix hides tabs and objects', (tester) async {
    await pumpPalette(tester, initialQuery: '>run');
    expect(find.text('orders'), findsNothing);
    expect(find.text('New query tab'), findsNothing);
    expect(find.text('Run statement'), findsOneWidget);
  });

  testWidgets('a @ prefix lists tabs only', (tester) async {
    await pumpPalette(tester, initialQuery: '@');
    expect(find.text('orders'), findsOneWidget);
    expect(find.text('Run statement'), findsNothing);
  });

  testWidgets('a # prefix lists objects and Enter opens the best match', (
    tester,
  ) async {
    await pumpPalette(tester, initialQuery: '#ord');
    expect(find.text('orders'), findsOneWidget);
    expect(find.text('users'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(ran, ['orders']);
  });

  testWidgets('typing finds workspace files too', (tester) async {
    await pumpPalette(tester, files: {'reports/monthly.sql': 'select 1'});
    await tester.enterText(find.byKey(const Key('palette-query')), 'monthly');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('monthly.sql'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
  });
}
