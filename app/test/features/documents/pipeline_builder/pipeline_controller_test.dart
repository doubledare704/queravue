import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/pipeline_builder/application/pipeline_builder_controller.dart';

import 'pipeline_harness.dart';

void main() {
  late PipelineHarness h;

  setUp(() {
    h = PipelineHarness();
    addTearDown(h.container.dispose);
    h.container.listen(pipelineBuilderProvider(pipelineTarget), (_, _) {});
  });

  List<String> operators() => [for (final s in h.state.stages) s.operator];

  test('adds, duplicates, disables, removes and reorders stages', () {
    h.controller
      ..addStage(r'$match')
      ..addStage(r'$sort')
      ..addStage(r'$limit');
    expect(operators(), [r'$match', r'$sort', r'$limit']);

    h.controller.duplicateStage(h.state.stages[0].id);
    expect(operators(), [r'$match', r'$match', r'$sort', r'$limit']);

    h.controller.moveStage(3, 0);
    expect(operators(), [r'$limit', r'$match', r'$match', r'$sort']);

    h.controller.setEnabled(h.state.stages[1].id, false);
    expect(h.state.stages[1].enabled, isFalse);

    h.controller.removeStage(h.state.stages[0].id);
    expect(operators(), [r'$match', r'$match', r'$sort']);
  });

  test('new stages start with the default body of their operator', () {
    h.controller
      ..addStage(r'$limit')
      ..addStage(r'$out');
    expect(h.state.stages[0].body, 20);
    expect(h.state.stages[1].body, isEmpty);
  });

  test('raw text turns into a stage once it parses', () {
    h.controller.importText(r'[{ $limit: ??? }]');
    final id = h.state.stages.single.id;
    expect(h.state.stages.single.isUnparsed, isTrue);

    h.controller.setRawText(id, r'{ $limit: 5 }');
    expect(h.state.stages.single.operator, r'$limit');
    expect(h.state.stages.single.body, 5);
    expect(h.state.stages.single.id, id);
  });

  test('import reports stages kept as raw text', () {
    expect(h.controller.importText(r'[{ $match: {} }, { nope: 1 }]'), isTrue);
    expect(h.state.notice, contains('1 stage'));
  });

  test('import of text without an array fails and keeps the stages', () {
    h.controller.addStage(r'$match');
    expect(h.controller.importText('hello'), isFalse);
    expect(h.state.stages, hasLength(1));
    expect(h.state.notice, isNotNull);
  });

  test('loads field and collection suggestions', () async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(h.state.fieldNames, ['_id', 'name', 'big']);
  });

  group('preview', () {
    test(
      'runs the enabled stages up to the selected one plus a limit',
      () async {
        h.controller.importText(
          r'[{ $match: { a: 1 } }, { $sort: { a: 1 } }, { $skip: 2 }, { $limit: 9 }]',
        );
        h.controller.setEnabled(h.state.stages[1].id, false);
        h.queueCursor();

        await h.controller.runPreview(h.state.stages[2].id);

        expect(h.shell.opened.single.database, 'shop');
        expect(
          h.shell.evals.single.code,
          'db.orders.aggregate([\n  { \$match: { a: 1 } },\n  { \$skip: 2 },\n  { \$limit: 20 }\n])',
        );
        expect(h.shell.fetches.single.limit, kDefaultPreviewLimit);
        expect(h.state.preview.phase, PreviewPhase.done);
        expect(h.state.preview.documents, hasLength(2));
      },
    );

    test('honours the preview limit', () async {
      h.controller.importText(r'[{ $match: {} }]');
      h.controller.setPreviewLimit(5);
      h.queueCursor();
      await h.controller.runPreview(h.state.stages.single.id);
      expect(h.shell.evals.single.code, contains(r'{ $limit: 5 }'));
      expect(h.shell.fetches.single.limit, 5);
    });

    test('never runs a pipeline that contains out or merge', () async {
      h.controller.importText(
        r'[{ $match: {} }, { $out: "x" }, { $limit: 1 }]',
      );
      await h.controller.runPreview(h.state.stages[2].id);
      expect(h.shell.evals, isEmpty);
      expect(h.state.preview.phase, PreviewPhase.failed);
      expect(h.state.preview.error, contains(r'$out'));

      await h.controller.runPreview(h.state.stages[0].id);
      expect(h.shell.evals, hasLength(1));
    });

    test('refuses to run through a stage that is raw text', () async {
      h.controller.importText(r'[{ $limit: ??? }, { $match: {} }]');
      await h.controller.runPreview(h.state.stages[1].id);
      expect(h.shell.evals, isEmpty);
      expect(h.state.preview.phase, PreviewPhase.failed);
    });

    test('reports a script error', () async {
      h.controller.importText(r'[{ $match: {} }]');
      h.shell.evalError = 'boom';
      await h.controller.runPreview(h.state.stages.single.id);
      expect(h.state.preview.phase, PreviewPhase.failed);
      expect(h.state.preview.error, contains('boom'));
    });

    test('can be cancelled', () async {
      h.controller.importText(r'[{ $match: {} }]');
      h.shell.holdOpen = Completer<void>();
      h.queueCursor();
      final run = h.controller.runPreview(h.state.stages.single.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.state.preview.phase, PreviewPhase.running);

      await h.controller.cancelPreview();
      await run;

      expect(h.shell.cancelled, isNotEmpty);
      expect(h.state.preview.phase, PreviewPhase.idle);
    });

    test('closes its shell when the builder goes away', () async {
      h.controller.importText(r'[{ $match: {} }]');
      h.queueCursor();
      await h.controller.runPreview(h.state.stages.single.id);
      h.container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(h.shell.closed, ['shell-1']);
    });
  });
}
