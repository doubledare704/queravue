import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';
import 'package:queravue/features/shell/presentation/output_pane.dart';

import '../../support/fake_document_repository.dart';
import '../../support/shell_workspace_fakes.dart';

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= tolerance) return true;
    if (!result.passed) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return true;
  }
}

const _handle = CursorHandle(
  cursorId: 'cursor1',
  kind: CursorKind.find,
  database: 'shop',
  collection: 'users',
);

final _entries = <OutputEntry>[
  const OutputRun('db.users.insertOne({name: "ada"})'),
  const OutputValue(
    ValueKind.write,
    '{"acknowledged":true,"insertedId":{"\$oid":"650000000000000000000001"}}',
    writeOp: 'insertOne',
  ),
  const OutputPrint(PrintLevel.log, 'created 1 user'),
  const OutputPrint(PrintLevel.warn, 'no index on name'),
  const OutputPrint(PrintLevel.error, 'console.error line'),
  const OutputValue(
    ValueKind.document,
    '{"_id":{"\$numberInt":"1"},"n":{"\$numberLong":"5"},"at":{"\$date":{"\$numberLong":"1579084200000"}}}',
  ),
  const OutputValue(ValueKind.scalar, '{"\$numberInt":"42"}'),
  const OutputError(
    ShellFailure(
      kind: ShellErrorKind.runtime,
      message: 'ReferenceError: nope is not defined',
      line: 3,
      column: 7,
    ),
    line: 2,
    column: 7,
  ),
  const OutputDone(Duration(milliseconds: 12)),
];

Future<ShellEnv> _pump(
  WidgetTester tester,
  List<OutputEntry> entries, {
  void Function(int, int)? onJump,
  Brightness brightness = Brightness.light,
  Size size = const Size(760, 560),
  List<String> docs = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final env = await makeShellEnv();
  env.shell.cursorDocs = docs;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: env.container,
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('golden'),
            child: ShellOutputPane(
              entries: entries,
              shellId: 'shell-1',
              onJump: onJump ?? (_, _) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return env;
}

void main() {
  setUpAll(() {
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      goldenFileComparator = _TolerantComparator(
        Uri.parse('${current.basedir}output_pane_test.dart'),
        tolerance: 0.005,
      );
    }
  });

  testWidgets('shows a hint while there is no output', (tester) async {
    await _pump(tester, const []);
    expect(find.byKey(const Key('shell-output-empty')), findsOneWidget);
  });

  testWidgets('print lines, values, write results and timing', (tester) async {
    await _pump(tester, _entries);
    expect(find.text('created 1 user'), findsOneWidget);
    expect(find.text('no index on name'), findsOneWidget);
    expect(find.text('console.error line'), findsOneWidget);
    expect(
      find.text('42'),
      findsOneWidget,
      reason: 'Int32 shows as a plain number',
    );
    expect(find.textContaining('NumberLong("5")'), findsOneWidget);
    final write = tester.widget<SelectableText>(
      find.byKey(const Key('output-write')),
    );
    expect(write.data, startsWith('insertOne'));
    expect(write.data, contains('acknowledged: true'));
    expect(write.data, contains('ObjectId("650000000000000000000001")'));
    expect(find.text('done in 12 ms'), findsOneWidget);
    expect(find.textContaining('db.users.insertOne'), findsOneWidget);
  });

  testWidgets('print levels use different colors', (tester) async {
    await _pump(tester, _entries);
    final byText = {
      for (final w in tester.widgetList<SelectableText>(
        find.byKey(const Key('output-print')),
      ))
        w.data: w.style?.color,
    };
    final log = byText['created 1 user'];
    final warn = byText['no index on name'];
    final err = byText['console.error line'];
    expect({log, warn, err}.length, 3);
  });

  testWidgets('clicking an error jumps to its line and column', (tester) async {
    int? line, col;
    await _pump(
      tester,
      _entries,
      onJump: (l, c) {
        line = l;
        col = c;
      },
    );
    expect(
      find.textContaining('line 3:7'),
      findsOneWidget,
      reason: 'shown 1-based',
    );
    await tester.tap(find.byKey(const Key('output-error')));
    expect(line, 2);
    expect(col, 7);
  });

  testWidgets('an error without a position is not clickable', (tester) async {
    var jumped = false;
    await _pump(tester, const [
      OutputError(
        ShellFailure(kind: ShellErrorKind.server, message: 'duplicate key'),
      ),
    ], onJump: (_, _) => jumped = true);
    await tester.tap(find.byKey(const Key('output-error')));
    expect(jumped, isFalse);
    expect(find.textContaining('↗'), findsNothing);
  });

  group('cursor result', () {
    final docs = [for (var i = 0; i < 45; i++) fakeDoc(i)];

    testWidgets('opens in the table view with paging', (tester) async {
      await _pump(tester, const [OutputCursor(_handle)], docs: docs);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cursor-table')), findsOneWidget);
      expect(find.text('find on users'), findsOneWidget);
      expect(find.text('1–20'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cursor-next')));
      await tester.pumpAndSettle();
      expect(find.text('21–40'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cursor-prev')));
      await tester.pumpAndSettle();
      expect(find.text('1–20'), findsOneWidget);
    });

    testWidgets('switches between table, tree and JSON', (tester) async {
      await _pump(tester, const [OutputCursor(_handle)], docs: docs);
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSON'));
      await tester.pump();
      expect(find.byKey(const Key('cursor-json')), findsOneWidget);
      await tester.tap(find.text('Tree'));
      await tester.pump();
      expect(find.byKey(const Key('cursor-tree')), findsOneWidget);
      await tester.tap(find.text('Table'));
      await tester.pump();
      expect(find.byKey(const Key('cursor-table')), findsOneWidget);
    });

    testWidgets('an empty cursor says so', (tester) async {
      await _pump(tester, const [OutputCursor(_handle)]);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cursor-empty')), findsOneWidget);
    });

    testWidgets('a failed fetch shows the error', (tester) async {
      final env = await _pump(tester, const [], docs: docs);
      env.shell.fetchError = StateError('cursor handle not found');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: env.container,
          child: MaterialApp(
            home: Scaffold(
              body: ShellOutputPane(
                entries: const [OutputCursor(_handle)],
                shellId: 'shell-1',
                onJump: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cursor-error')), findsOneWidget);
    });
  });

  for (final b in Brightness.values) {
    testWidgets('golden: output pane, ${b.name} theme', (tester) async {
      await _pump(tester, _entries, brightness: b);
      await expectLater(
        find.byKey(const Key('golden')),
        matchesGoldenFile('goldens/output_pane_${b.name}.png'),
      );
    });
  }

  test('valueText shows shell style and survives bad input', () {
    expect(
      valueText('{"a":{"\$numberLong":"1"}}'),
      contains('NumberLong("1")'),
    );
    expect(valueText('not json'), 'not json');
  });
}
