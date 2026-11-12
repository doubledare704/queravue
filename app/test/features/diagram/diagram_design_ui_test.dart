import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/designer/domain/design_models.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';

import '../../support/diagram_harness.dart';
import '../../support/fake_diagram.dart';
import 'diagram_files_ui_test.dart' show answerPrompt, chord;

Future<void> draftTable(
  WidgetTester tester,
  String name, {
  List<(String, String)> extraColumns = const [],
}) async {
  await tester.tap(find.byKey(const Key('diagram-new-table')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('draft-table-name')), name);
  for (final (i, (column, type)) in extraColumns.indexed) {
    await tester.tap(find.byKey(const Key('draft-add-column')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('col-name-${i + 1}')), column);
    await tester.enterText(find.byKey(Key('col-type-${i + 1}')), type);
  }
  await tester.tap(find.byKey(const Key('draft-table-save')));
  await tester.pumpAndSettle();
}

Future<void> openTableMenu(
  WidgetTester tester,
  DiagramEnv env,
  String table,
) async {
  await tester.tapAt(
    onScreen(tester, ready(env).rects[table]!.center),
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pumpAndSettle();
}

Future<void> drawRelation(
  WidgetTester tester,
  DiagramEnv env,
  String from,
  String to,
) async {
  await openTableMenu(tester, env, from);
  await tester.tap(find.byKey(const Key('diagram-menu-relation')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('draft-relation-target')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, to).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('draft-relation-add')));
  await tester.pumpAndSettle();
}

String reviewLabel(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('diagram-review-draft')),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  testWidgets('a drafted table and relation are reviewed and applied', (
    tester,
  ) async {
    final repo = FakeDiagramRepository(shop);
    final env = await openDiagram(tester, repo);
    expect(find.byKey(const Key('diagram-review-draft')), findsNothing);

    await draftTable(tester, 'invoices', extraColumns: [('total', 'numeric')]);
    final drafted = ready(env);
    expect(drafted.draft.tables.single.name, 'invoices');
    expect(drafted.table('invoices')!.draft, isTrue);
    final placed = drafted.rects['invoices']!;
    for (final e in drafted.rects.entries) {
      if (e.key != 'invoices') expect(placed.overlaps(e.value), isFalse);
    }
    expect(reviewLabel(tester), 'Review 1 change');

    await drawRelation(tester, env, 'invoices', 'customers');
    expect(
      find.textContaining('Adds column customers_id'),
      findsNothing,
      reason: 'the dialog closed',
    );
    expect(
      ready(env).table('invoices')!.relations.single.referencedTable,
      'customers',
    );
    expect(reviewLabel(tester), 'Review 2 changes');

    await tester.tap(find.byKey(const Key('diagram-review-draft')));
    await tester.pumpAndSettle();
    expect(find.text('Create table invoices'), findsOneWidget);
    expect(repo.ddl.single.apply, isFalse);
    final create =
        repo.ddl.single.tables.single.changes.single as CreateTableChange;
    expect(
      [for (final c in create.columns) c.name],
      ['id', 'total', 'customers_id'],
    );
    expect(create.constraints.foreignKeys.single.referencedTable, 'customers');
    expect(repo.ddl.single.tables.single.table.schema, 'public');

    await tester.tap(find.byKey(const Key('ddl-apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ddl-apply')), findsNothing);
    expect(repo.ddl.last.apply, isTrue);
    expect(repo.ddl.last.confirmed, isTrue);
    expect(repo.requests.last.refresh, isTrue);

    final applied = ready(env);
    expect(applied.draft.isEmpty, isTrue);
    expect(applied.graph.tables.map((t) => t.name), contains('invoices'));
    expect(applied.table('invoices')!.draft, isFalse);
    expect(applied.rects['invoices']!.topLeft, placed.topLeft);
    expect(find.byKey(const Key('diagram-review-draft')), findsNothing);
  });

  testWidgets('a failed apply keeps the draft and shows the error', (
    tester,
  ) async {
    final repo = FakeDiagramRepository(shop);
    final env = await openDiagram(tester, repo);
    await draftTable(tester, 'invoices');
    await tester.tap(find.byKey(const Key('diagram-review-draft')));
    await tester.pumpAndSettle();
    repo.ddlError = const AdminError(
      kind: AdminErrorKind.server,
      message: 'relation "invoices" already exists',
    );
    await tester.tap(find.byKey(const Key('ddl-apply')));
    await tester.pumpAndSettle();
    expect(find.text('relation "invoices" already exists'), findsOneWidget);
    expect(ready(env).draft.tables.single.name, 'invoices');
  });

  testWidgets('a drafted table is edited by double-click and renamed', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    await draftTable(tester, 'invoices');
    await drawRelation(tester, env, 'orders', 'invoices');
    expect(ready(env).table('orders')!.columns.last.name, 'invoices_id');

    final at = onScreen(tester, ready(env).rects['invoices']!.center);
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(find.text('Edit table'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('draft-table-name')), 'bills');
    await tester.tap(find.byKey(const Key('draft-table-save')));
    await tester.pumpAndSettle();

    final renamed = ready(env);
    expect(renamed.draft.tables.single.name, 'bills');
    expect(renamed.draft.relations.single.toTable, 'bills');
    expect(renamed.rects.containsKey('invoices'), isFalse);
    expect(renamed.rects.containsKey('bills'), isTrue);
  });

  testWidgets('a name already on the diagram is refused', (tester) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    await tester.tap(find.byKey(const Key('diagram-new-table')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('draft-table-name')), 'orders');
    await tester.tap(find.byKey(const Key('draft-table-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('A table named orders is already on the diagram.'),
      findsOneWidget,
    );
    expect(ready(env).draft.isEmpty, isTrue);
  });

  testWidgets('removing a relation, removing a table and discarding', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    await draftTable(tester, 'invoices');
    await drawRelation(tester, env, 'invoices', 'orders');
    final grown = ready(env).rects['invoices']!.height;

    await openTableMenu(tester, env, 'invoices');
    await tester.tap(find.byKey(const Key('diagram-menu-unrelate-0')));
    await tester.pumpAndSettle();
    expect(ready(env).draft.relations, isEmpty);
    expect(ready(env).rects['invoices']!.height, lessThan(grown));

    await openTableMenu(tester, env, 'invoices');
    await tester.tap(find.byKey(const Key('diagram-menu-remove')));
    await tester.pumpAndSettle();
    expect(ready(env).draft.isEmpty, isTrue);
    expect(ready(env).rects.containsKey('invoices'), isFalse);

    await draftTable(tester, 'invoices');
    await tester.tap(find.byKey(const Key('diagram-discard-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagram-discard-confirm')));
    await tester.pumpAndSettle();
    expect(ready(env).draft.isEmpty, isTrue);
    expect(find.byKey(const Key('diagram-review-draft')), findsNothing);
  });

  testWidgets('a relation can be added only once a target is picked', (
    tester,
  ) async {
    final repo = FakeDiagramRepository(shop);
    final env = await openDiagram(tester, repo);
    await openTableMenu(tester, env, 'orders');
    await tester.tap(find.byKey(const Key('diagram-menu-relation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('draft-relation-add')), findsOneWidget);
    final add = tester.widget<FilledButton>(
      find.byKey(const Key('draft-relation-add')),
    );
    expect(add.onPressed, isNull);
  });

  testWidgets('without the execute capability there is no design mode', (
    tester,
  ) async {
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(shop),
      capabilities: const {'connect', 'schema_graph'},
    );
    expect(find.byKey(const Key('diagram-new-table')), findsNothing);
    await openTableMenu(tester, env, 'orders');
    expect(find.byKey(const Key('diagram-menu-relation')), findsNothing);
  });

  testWidgets('an empty schema offers a new table; ⌘⌥T drafts one too', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository());
    await tester.tap(find.byKey(const Key('diagram-empty-new-table')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('draft-table-name')), 'first');
    await tester.tap(find.byKey(const Key('draft-table-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagram-empty')), findsNothing);
    expect(ready(env).draft.tables.single.name, 'first');

    await chord(tester, LogicalKeyboardKey.keyT, alt: true);
    expect(find.byKey(const Key('draft-table-name')), findsOneWidget);
  });

  testWidgets('a saved diagram keeps its draft across a reopen', (
    tester,
  ) async {
    final env = await openDiagram(tester, FakeDiagramRepository(shop));
    await draftTable(tester, 'invoices');
    await drawRelation(tester, env, 'invoices', 'customers');
    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, 'design');
    final saved = SavedDiagram.fromJson(
      env.workspace.contents['.queravue/diagrams/design.json']!,
    )!;
    expect(saved.draft.tables.single.name, 'invoices');
    expect(saved.draft.relations.single.toTable, 'customers');
    expect(saved.positions.containsKey('invoices'), isTrue);
  });
}
