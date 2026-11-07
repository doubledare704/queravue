import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/admin/application/admin_controllers.dart';
import 'package:queravue/features/admin/data/admin_repository.dart';
import 'package:queravue/features/admin/domain/admin_models.dart';
import 'package:queravue/features/admin/presentation/indexes_panel.dart';
import 'package:queravue/features/admin/presentation/index_dialogs.dart';
import 'package:queravue/features/admin/presentation/stats_panel.dart';
import 'package:queravue/features/admin/presentation/validation_panel.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_admin_repository.dart';
import '../../support/fake_connections_repository.dart';
import '../../support/providers.dart';

const _target = AdminTarget('c1', TableRef(table: 'orders'));

Widget _host(
  Widget child,
  FakeAdminRepository repo, {
  bool production = false,
}) {
  final List<Override> overrides = [
    adminRepositoryProvider.overrideWithValue(repo),
    adminSessionIdProvider.overrideWith((ref, id) => Future.value('s1')),
    ...fakeCoreOverrides(
      FakeConnectionsRepository(
        initial: [
          ConnectionProfile(
            id: 'c1',
            name: 'DB',
            engineId: 'postgres',
            production: production,
          ),
        ],
      )..engines = [pgEngine],
    ),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('indexes panel lists indexes and shows n/a without usage', (
    tester,
  ) async {
    final repo = FakeAdminRepository()
      ..indexes = [
        const IndexEntry(
          name: 'orders_pkey',
          keys: [IndexKeyModel('id')],
          primary: true,
          unique: true,
          sizeBytes: 16384,
        ),
        const IndexEntry(
          name: 'orders_customer',
          keys: [
            IndexKeyModel('customer'),
            IndexKeyModel('at', descending: true),
          ],
        ),
      ];
    await tester.pumpWidget(_host(const IndexesPanel(target: _target), repo));
    await tester.pumpAndSettle();

    expect(find.text('orders_customer'), findsOneWidget);
    expect(find.text('customer, at desc'), findsOneWidget);
    expect(find.text('16.0 KB'), findsOneWidget);
    expect(find.text('n/a'), findsWidgets);
    expect(find.byKey(const Key('drop-index-orders_pkey')), findsNothing);
    expect(find.byKey(const Key('drop-index-orders_customer')), findsOneWidget);
  });

  testWidgets('creating an index needs a preview first', (tester) async {
    final repo = FakeAdminRepository();
    await tester.pumpWidget(_host(const IndexesPanel(target: _target), repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-index')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('index-name')), 'ix_note');
    await tester.enterText(find.byKey(const Key('index-keys')), 'note');
    await tester.pump();

    FilledButton create() =>
        tester.widget<FilledButton>(find.byKey(const Key('index-create')));
    expect(create().onPressed, isNull);

    await tester.tap(find.byKey(const Key('index-preview')));
    await tester.pumpAndSettle();
    expect(find.text('CREATE INDEX ix_note ON orders (note);'), findsOneWidget);
    expect(find.text('Blocks writes.'), findsOneWidget);
    expect(repo.calls, contains('create-dry'));
    expect(repo.indexes, isEmpty);

    await tester.tap(find.byKey(const Key('index-create')));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'list');
    expect(find.text('ix_note'), findsOneWidget);
    expect(repo.confirmations, [false]);
  });

  testWidgets('production create sends the confirmation', (tester) async {
    final repo = FakeAdminRepository();
    await tester.pumpWidget(
      _host(const IndexesPanel(target: _target), repo, production: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-index')));
    await tester.pumpAndSettle();
    expect(find.text('This is a production connection.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('index-keys')), 'a');
    await tester.pump();
    await tester.tap(find.byKey(const Key('index-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statement-preview')), findsOneWidget);
    expect(find.text('Create on production'), findsOneWidget);
    await tester.tap(find.byKey(const Key('index-create')));
    await tester.pumpAndSettle();
    expect(repo.confirmations, [true]);
  });

  testWidgets('dropping an index shows the statement then drops', (
    tester,
  ) async {
    final repo = FakeAdminRepository()
      ..indexes = [
        const IndexEntry(name: 'ix_old', keys: [IndexKeyModel('a')]),
      ];
    await tester.pumpWidget(_host(const IndexesPanel(target: _target), repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drop-index-ix_old')));
    await tester.pumpAndSettle();
    expect(find.text('DROP INDEX ix_old;'), findsOneWidget);
    expect(repo.indexes, isNotEmpty);
    await tester.tap(find.byKey(const Key('index-drop-confirm')));
    await tester.pumpAndSettle();
    expect(repo.indexes, isEmpty);
    expect(find.text('No indexes.'), findsOneWidget);
  });

  testWidgets('an unsupported server is reported, not retried', (tester) async {
    final repo = FakeAdminRepository()
      ..statsError = const AdminError(
        kind: AdminErrorKind.unsupported,
        message: 'collStats is not implemented',
      );
    await tester.pumpWidget(_host(const StatsPanel(target: _target), repo));
    await tester.pumpAndSettle();
    expect(find.text('Not supported by this server'), findsOneWidget);
    expect(find.text('collStats is not implemented'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('stats panel formats figures and extras', (tester) async {
    final repo = FakeAdminRepository()
      ..stats = const StatsModel(
        estimatedRows: 1234567,
        dataBytes: 5 * 1024 * 1024,
        extras: [(label: 'Fill factor', value: '90')],
      );
    await tester.pumpWidget(_host(const StatsPanel(target: _target), repo));
    await tester.pumpAndSettle();
    expect(find.text('1,234,567'), findsOneWidget);
    expect(find.text('5.0 MB'), findsOneWidget);
    expect(find.text('Fill factor'), findsOneWidget);
    expect(find.text('Index size'), findsNothing);
  });

  testWidgets('validation panel shows the error position as line and column', (
    tester,
  ) async {
    final repo = FakeAdminRepository()
      ..validation = const ValidationModel(
        validator: '{"\$jsonSchema":{"required":["a"]}}',
        level: 'strict',
        action: 'error',
      )
      ..setValidationError = const AdminError(
        kind: AdminErrorKind.invalid,
        message: 'unexpected end',
        position: 8,
      );
    await tester.pumpWidget(
      _host(const ValidationPanel(target: _target), repo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('validation-text')),
      '{\n  "a": ',
    );
    await tester.tap(find.byKey(const Key('validation-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Line 2, column 7: unexpected end'), findsOneWidget);
  });

  testWidgets('validation panel applies, and production asks first', (
    tester,
  ) async {
    final repo = FakeAdminRepository();
    await tester.pumpWidget(
      _host(const ValidationPanel(target: _target), repo, production: true),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('validation-text')),
      '{"\$jsonSchema":{}}',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('validation-apply')));
    await tester.pumpAndSettle();
    expect(repo.calls, isNot(contains('set')));
    await tester.tap(find.byKey(const Key('validation-confirm')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('set'));
    expect(repo.confirmations, [true]);
    expect(repo.validation.validator, '{"\$jsonSchema":{}}');
  });

  test('parseIndexKeys reads names and desc', () {
    final keys = parseIndexKeys('a, b desc ,  c DESC');
    expect(keys.map((k) => k.name), ['a', 'b', 'c']);
    expect(keys.map((k) => k.descending), [false, true, true]);
    expect(parseIndexKeys(' , '), isEmpty);
  });

  test('lineAndColumn counts lines in UTF-16 units', () {
    expect(lineAndColumn('ab\ncd', 4), (line: 2, column: 2));
    expect(lineAndColumn('x', 99), (line: 1, column: 2));
  });
}
