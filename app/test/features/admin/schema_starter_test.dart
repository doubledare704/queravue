import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/admin/application/admin_controllers.dart';
import 'package:queravue/features/admin/data/admin_repository.dart';
import 'package:queravue/features/admin/domain/schema_starter.dart';
import 'package:queravue/features/admin/presentation/validation_panel.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
import 'package:queravue/features/documents/domain/models.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/fake_admin_repository.dart';
import '../../support/fake_connections_repository.dart';
import '../../support/fake_document_repository.dart';
import '../../support/providers.dart';

void main() {
  group('starterValidator', () {
    Map<String, dynamic> schemaOf(List<FieldStat> fields) =>
        (jsonDecode(starterValidator(fields))
                as Map<String, dynamic>)[r'$jsonSchema']
            as Map<String, dynamic>;

    test('requires fields every document had and keeps their types', () {
      final schema = schemaOf(const [
        FieldStat(name: '_id', types: ['objectId']),
        FieldStat(name: 'name', types: ['string']),
        FieldStat(name: 'age', types: ['int', 'double']),
        FieldStat(name: 'nick', types: ['string'], frequency: 0.4),
      ]);
      expect(schema['bsonType'], 'object');
      expect(schema['required'], ['name', 'age']);
      final props = schema['properties'] as Map<String, dynamic>;
      expect(props.keys, ['name', 'age', 'nick']);
      expect((props['name'] as Map)['bsonType'], 'string');
      expect((props['age'] as Map)['bsonType'], ['int', 'double']);
    });

    test('an empty sample is just an object schema', () {
      expect(schemaOf(const []), {'bsonType': 'object'});
    });
  });

  group('Start from sample', () {
    late FakeAdminRepository admin;
    late FakeDocumentRepository documents;

    Future<void> pump(WidgetTester tester) async {
      admin = FakeAdminRepository();
      documents = FakeDocumentRepository()
        ..sampled = const [
          FieldStat(name: '_id', types: ['objectId']),
          FieldStat(name: 'name', types: ['string']),
        ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(admin),
            documentRepositoryProvider.overrideWithValue(documents),
            adminSessionIdProvider.overrideWith(
              (ref, id) => Future.value('s1'),
            ),
            ...fakeCoreOverrides(
              FakeConnectionsRepository(
                initial: [
                  const ConnectionProfile(
                    id: 'c1',
                    name: 'M',
                    engineId: 'mongodb',
                  ),
                ],
              )..engines = [pgEngine],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ValidationPanel(
                target: AdminTarget(
                  'c1',
                  TableRef(database: 'shop', table: 'users'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String text(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(const Key('validation-text')))
        .controller!
        .text;

    testWidgets('fills an empty editor and applies nothing', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('validation-starter')));
      await tester.pumpAndSettle();
      expect(text(tester), contains('"required"'));
      expect(text(tester), contains('"name"'));
      expect(find.byKey(const Key('validation-starter-note')), findsOneWidget);
      expect(find.textContaining('3 sampled documents'), findsOneWidget);
      expect(admin.calls, isNot(contains('set')));
    });

    testWidgets('asks before replacing existing text', (tester) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('validation-text')),
        '{"mine":1}',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('validation-starter')));
      await tester.pumpAndSettle();
      expect(text(tester), '{"mine":1}');
      await tester.tap(find.byKey(const Key('validation-starter-confirm')));
      await tester.pumpAndSettle();
      expect(text(tester), contains(r'$jsonSchema'));
    });
  });
}
