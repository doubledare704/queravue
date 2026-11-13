import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/diagram/domain/diagram_layout.dart';
import 'package:queravue/features/diagram/domain/diagram_models.dart';
import 'package:queravue/features/diagram/domain/diagram_scene.dart';
import 'package:queravue/features/diagram/domain/saved_diagram.dart';
import 'package:queravue/features/diagram/presentation/diagram_export.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import '../../support/diagram_harness.dart';
import '../../support/fake_diagram.dart';
import 'diagram_files_ui_test.dart' show answerPrompt, chord;

DiagramTable _collection(
  String name, {
  List<String> fields = const [],
  Map<String, (String, double)> guesses = const {},
}) => DiagramTable(
  name: name,
  type: SchemaObjectType.collection,
  columns: [
    const DiagramColumn(
      name: '_id',
      typeName: 'objectId',
      nullable: false,
      primaryKeyOrder: 1,
    ),
    for (final f in fields) DiagramColumn(name: f, typeName: 'objectId'),
  ],
  relations: [
    for (final e in guesses.entries)
      DiagramRelation(
        columns: [e.key],
        referencedTable: e.value.$1,
        referencedColumns: const ['_id'],
        inferred: true,
        confidence: e.value.$2,
      ),
  ],
);

final library = SchemaGraph([
  _collection('authors'),
  _collection(
    'books',
    fields: ['authorId', 'editor'],
    guesses: {'authorId': ('authors', 0.9), 'editor': ('authors', 0.5)},
  ),
]);

void main() {
  testWidgets('inferred relations are counted and can be hidden and shown', (
    tester,
  ) async {
    final env = await openDiagram(
      tester,
      FakeDiagramRepository(library),
      capabilities: const {'connect', 'schema_graph', 'document_store'},
    );
    expect(find.text('2 tables · 2 relations · 2 inferred'), findsOneWidget);
    expect(find.byKey(const Key('diagram-new-table')), findsNothing);
    expect(ready(env).visibleGraph.relationCount, 2);

    await tester.tap(find.byKey(const Key('diagram-toggle-inferred')));
    await tester.pumpAndSettle();
    expect(ready(env).showInferred, isFalse);
    expect(ready(env).visibleGraph.relationCount, 0);
    expect(ready(env).graph.relationCount, 2);
    expect(ready(env).dirty, isTrue);
    expect(find.text('Show inferred'), findsOneWidget);

    await chord(tester, LogicalKeyboardKey.keyS);
    await answerPrompt(tester, 'library');
    final saved = SavedDiagram.fromJson(
      env.workspace.contents['.queravue/diagrams/library.json']!,
    )!;
    expect(saved.hideInferred, isTrue);

    await tester.tap(find.byKey(const Key('diagram-toggle-inferred')));
    await tester.pumpAndSettle();
    expect(ready(env).visibleGraph.relationCount, 2);
  });

  testWidgets('a schema without inferred relations has no toggle', (
    tester,
  ) async {
    await openDiagram(tester, FakeDiagramRepository(shop));
    expect(find.byKey(const Key('diagram-toggle-inferred')), findsNothing);
    expect(find.text('3 tables · 2 relations'), findsOneWidget);
  });

  test('hideInferred is written only when set and read back', () {
    const plain = SavedDiagram(connectionId: 'c1');
    expect(plain.toJson(), isNot(contains('hideInferred')));
    expect(SavedDiagram.fromJson(plain.toJson())!.hideInferred, isFalse);
    const hiding = SavedDiagram(connectionId: 'c1', hideInferred: true);
    expect(SavedDiagram.fromJson(hiding.toJson())!.hideInferred, isTrue);
  });

  test('without inferred relations only constraints are left', () {
    final mixed = SchemaGraph([
      ...library.tables,
      table('orders', references: {'customer_id': 'customers'}),
    ]);
    final left = mixed.withoutInferredRelations();
    expect(mixed.inferredRelationCount, 2);
    expect(left.inferredRelationCount, 0);
    expect(left.relationCount, 1);
    expect(left.tables.map((t) => t.name), mixed.tables.map((t) => t.name));
  });

  test('collections are drawn as tables, views as views', () {
    expect(_collection('c').isView, isFalse);
    expect(
      const DiagramTable(name: 'v', type: SchemaObjectType.view).isView,
      isTrue,
    );
    expect(
      const DiagramTable(
        name: 'm',
        type: SchemaObjectType.materializedView,
      ).isView,
      isTrue,
    );
  });

  test('less sure guesses are fainter, in the SVG too', () {
    expect(inferredOpacity(1), 1);
    expect(inferredOpacity(0.5), closeTo(0.65, 1e-9));
    expect(inferredOpacity(0), 0.3);
    final svg = diagramToSvg(
      graph: library,
      rects: layoutGraph(library).rects,
      colors: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    expect(svg, contains('<g opacity="0.93">'));
    expect(svg, contains('<g opacity="0.65">'));
    expect('<g opacity='.allMatches(svg).length, 2);
  });
}
