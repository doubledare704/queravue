import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/documents/pipeline_builder/domain/pipeline_codec.dart';
import 'package:queravue/features/documents/pipeline_builder/domain/pipeline_stage.dart';
import 'package:queravue/features/documents/pipeline_builder/domain/stage_forms.dart';

import 'fixtures/pipeline_corpus.dart';

void main() {
  test('the corpus holds at least 30 pipelines', () {
    expect(pipelineCorpus.length, greaterThanOrEqualTo(30));
  });

  group('corpus round trip', () {
    for (var i = 0; i < pipelineCorpus.length; i++) {
      final text = pipelineCorpus[i];
      test(
        '#$i ${text.replaceAll('\n', ' ').substring(0, text.length.clamp(0, 60))}',
        () {
          final imported = importPipeline(text);
          final viaShell = importPipeline(
            pipelineToShell(imported.collection ?? 'c', imported.stages),
          );
          expect(samePipeline(viaShell.stages, imported.stages), isTrue);

          final viaJson = importPipeline(pipelineToJson(imported.stages));
          expect(samePipeline(viaJson.stages, imported.stages), isTrue);

          if (imported.keptAsRaw == 0) {
            expect(
              () => jsonDecode(pipelineToJson(imported.stages)),
              returnsNormally,
            );
          }
        },
      );
    }

    test('typed forms regenerate the body they were decoded from', () {
      var decoded = 0;
      for (final text in pipelineCorpus) {
        for (final stage in importPipeline(text).stages) {
          final form = decodeStageForm(stage.operator, stage.body);
          if (form == null) continue;
          decoded++;
          expect(
            jsonEncode(form.toBody()),
            jsonEncode(stage.body),
            reason: text,
          );
        }
      }
      expect(decoded, greaterThan(40));
    });
  });

  group('import', () {
    test('keeps a broken stage as raw text', () {
      final r = importPipeline(
        r'[{ $match: { a: 1 } }, { $limit: ??? }, { $skip: 2 }]',
      );
      expect(r.stages.map((s) => s.operator), [r'$match', '', r'$skip']);
      expect(r.stages[1].unparsedText, r'{ $limit: ??? }');
      expect(r.keptAsRaw, 1);
    });

    test('keeps a document that is not a one-key stage as raw text', () {
      final r = importPipeline(r'[{ notAStage: 1 }, { $a: 1, $b: 2 }]');
      expect(r.stages.every((s) => s.isUnparsed), isTrue);
    });

    test('reads the collection of a shell call', () {
      expect(importPipeline('db.orders.aggregate([])').collection, 'orders');
      expect(importPipeline('db["a-b"].aggregate([])').collection, 'a-b');
    });

    test('rejects text without an array', () {
      expect(() => importPipeline('{ a: 1 }'), throwsFormatException);
    });

    test('reports ignored trailing options', () {
      final r = importPipeline('db.c.aggregate([], { allowDiskUse: true })');
      expect(r.ignoredTrailing, isTrue);
    });
  });

  group('export', () {
    final stages = [
      PipelineStage.of(r'$match', {'a': 1}),
      PipelineStage.of(r'$limit', 5, enabled: false),
      PipelineStage.of(r'$sort', {'a.b': -1}),
    ];

    test('skips disabled stages', () {
      expect(
        pipelineToJson(stages),
        '[\n  {"\$match":{"a":1}},\n  {"\$sort":{"a.b":-1}}\n]',
      );
    });

    test('quotes keys that are not identifiers in shell code', () {
      expect(
        pipelineToShell('my coll', stages),
        'db["my coll"].aggregate([\n  { \$match: { a: 1 } },\n  { \$sort: { "a.b": -1 } }\n])',
      );
    });

    test('writes typed values as shell constructors', () {
      final s = [
        PipelineStage.of(r'$match', {
          '_id': {r'$oid': '507f1f77bcf86cd799439011'},
        }),
      ];
      expect(
        pipelineToShellArray(s),
        contains('ObjectId("507f1f77bcf86cd799439011")'),
      );
    });
  });

  group('forms', () {
    test('a match with an expression stays unrepresentable', () {
      expect(
        decodeStageForm(r'$match', {r'$expr': <String, Object?>{}}),
        isNull,
      );
      expect(
        decodeStageForm(r'$match', {
          'a': {r'$regex': 'x', r'$options': 'i'},
        }),
        isNull,
      );
    });

    test('a match merges operators of one field', () {
      final form = MatchForm(const [
        MatchRow('age', r'$gte', '18'),
        MatchRow('age', r'$lt', '65'),
        MatchRow('name', 'eq', '"x"'),
      ]);
      expect(form.toBody(), {
        'age': {r'$gte': 18, r'$lt': 65},
        'name': 'x',
      });
    });

    test('text that is not a literal becomes a string', () {
      expect(const MatchForm([MatchRow('a', 'eq', 'abc')]).toBody(), {
        'a': 'abc',
      });
    });

    test('limit refuses an expression', () {
      expect(
        decodeStageForm(r'$limit', {
          r'$add': [1, 2],
        }),
        isNull,
      );
    });
  });
}
