import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/admin/application/admin_controllers.dart';
import 'package:queravue/features/admin/data/admin_repository.dart';
import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/admin/presentation/admin_host.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_admin_repository.dart';
import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

EngineSpec _engine(Set<String> capabilities) => EngineSpec(
  id: 'postgres',
  displayName: 'PostgreSQL',
  family: 'postgres',
  supportsUri: false,
  capabilities: capabilities,
  fields: const [],
);

Future<void> _pump(
  WidgetTester tester,
  Set<String> capabilities,
  FakeAdminRepository repo,
) async {
  final tab = EditorTab(
    id: 't1',
    connectionId: 'c1',
    title: 'orders',
    kind: TabKind.table,
    tableRef: TableRef(table: 'orders'),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repo),
        adminSessionIdProvider.overrideWith((ref, id) => Future.value('s1')),
        ...fakeCoreOverrides(
          FakeConnectionsRepository(
            initial: [
              const ConnectionProfile(
                id: 'c1',
                name: 'DB',
                engineId: 'postgres',
              ),
            ],
          )..engines = [_engine(capabilities)],
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AdminHost(tab: tab, child: Text('the data view')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers only the sections the capabilities allow', (
    tester,
  ) async {
    await _pump(tester, {'index_manager', 'stats'}, FakeAdminRepository());
    expect(find.byKey(const Key('admin-section-data')), findsOneWidget);
    expect(find.byKey(const Key('admin-section-indexes')), findsOneWidget);
    expect(find.byKey(const Key('admin-section-stats')), findsOneWidget);
    expect(find.byKey(const Key('admin-section-validation')), findsNothing);
  });

  testWidgets('shows the data view alone without any capability', (
    tester,
  ) async {
    await _pump(tester, {'execute'}, FakeAdminRepository());
    expect(find.byKey(const Key('admin-sections')), findsNothing);
    expect(find.text('the data view'), findsOneWidget);
  });

  testWidgets('loads a section only when it is first opened', (tester) async {
    final repo = FakeAdminRepository()
      ..indexes = [
        const IndexEntry(name: 'ix', keys: [IndexKeyModel('a')]),
      ];
    await _pump(tester, {'index_manager'}, repo);
    expect(repo.calls, isEmpty);

    await tester.tap(find.byKey(const Key('admin-section-indexes')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['list']);
    expect(find.text('ix'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-section-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-section-indexes')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['list']);
  });
}
