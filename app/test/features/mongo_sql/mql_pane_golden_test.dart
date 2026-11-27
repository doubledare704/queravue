import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/mongo_sql/domain/mongo_sql_translation.dart';
import 'package:queravue/features/mongo_sql/presentation/mql_pane.dart';
import 'package:queravue/shared/theme.dart';

import '../../support/builder_golden_comparator.dart';
import 'fixtures.dart';

void main() {
  testWidgets('generated MQL pane in EJSON format', (tester) async {
    useBuilderGoldenComparator();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: const Key('mql-golden'),
              child: SizedBox(
                width: 650,
                height: 260,
                child: MqlPane(
                  translation: aggregate,
                  format: MqlFormat.ejson,
                  onFormat: (_) {},
                  onCopy: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('mql-golden')),
      matchesGoldenFile('goldens/mql_pane.png'),
    );
  });
}
