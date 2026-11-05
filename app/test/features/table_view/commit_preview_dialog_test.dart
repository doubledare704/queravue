import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/table_view/application/pending_changes_controller.dart';
import 'package:queravue/features/table_view/application/table_tab_controller.dart';
import 'package:queravue/features/table_view/domain/table_models.dart';
import 'package:queravue/features/table_view/presentation/commit_preview_dialog.dart';

class _TestTableTabController extends TableTabController {
  _TestTableTabController(super.tabId);

  @override
  TableTabState build() {
    return TableTabState(
      tabId: tabId,
      connectionId: 'prod_conn',
      tableRef: const TableRef(table: 'orders'),
    );
  }

  @override
  Future<ApplyChangesResult> applyChanges({
    bool dryRun = false,
    bool confirmProduction = false,
  }) async {
    return ApplyChangesResult(
      generatedSql:
          'UPDATE "orders" SET "status" = \'shipped\' WHERE "id" = 1;',
      rowsAffected: 1,
      dryRun: dryRun,
      success: true,
    );
  }
}

void main() {
  group('CommitPreviewDialog widget tests', () {
    testWidgets(
      'shows generated SQL and requires confirmation on production connection',
      (tester) async {
        const prodProfile = ConnectionProfile(
          id: 'prod_conn',
          name: 'Production DB',
          engineId: 'postgres',
          production: true,
        );

        final container = ProviderContainer(
          overrides: [
            connectionsControllerProvider.overrideWith(
              () => _MockConnectionsController([prodProfile]),
            ),
            tableTabProvider('tab1')
                .overrideWith(() => _TestTableTabController('tab1')),
            pendingChangesProvider('tab1')
                .overrideWith(() => _MockPendingChangesController('tab1')),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: CommitPreviewDialog(tabId: 'tab1')),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Should display PRODUCTION badge
        expect(find.text('PRODUCTION'), findsWidgets);

        // Should show generated SQL preview
        expect(
          find.text(
            'UPDATE "orders" SET "status" = \'shipped\' WHERE "id" = 1;',
          ),
          findsOneWidget,
        );

        // Commit button should initially be disabled because production confirmation is not checked
        final commitBtnFinder = find.byKey(const Key('commit-confirm-btn'));
        expect(tester.widget<FilledButton>(commitBtnFinder).onPressed, isNull);

        // Toggle production confirmation checkbox
        await tester.tap(find.byKey(const Key('confirm-prod-checkbox')));
        await tester.pumpAndSettle();

        // Now commit button should be enabled
        expect(
          tester.widget<FilledButton>(commitBtnFinder).onPressed,
          isNotNull,
        );

        // Tap Commit button
        await tester.tap(commitBtnFinder);
        await tester.pump();
      },
    );
  });
}

class _MockConnectionsController extends ConnectionsController {
  _MockConnectionsController(this._profiles);
  final List<ConnectionProfile> _profiles;

  @override
  Future<List<ConnectionProfile>> build() async => _profiles;
}

class _MockPendingChangesController extends PendingChangesController {
  _MockPendingChangesController(super.tableKey);

  @override
  List<RowChange> toRowChanges() => const [
    RowChange(
      type: RowChangeType.update,
      keys: {'id': 1},
      values: {'status': 'shipped'},
    ),
  ];
}
