import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/grid/application/result_window.dart';
import 'package:queravue/features/grid/presentation/result_grid.dart';

import '../../support/fake_query_repository.dart';

const _cols = [
  ResultColumn(name: 'id', typeName: 'int4', kind: ColumnKind.integer),
  ResultColumn(name: 'label', typeName: 'text', kind: ColumnKind.text),
  ResultColumn(name: 'doc', typeName: 'jsonb', kind: ColumnKind.json),
];

ResultRow _row(int r) => <Object?>[
  r,
  r % 5 == 0 ? null : 'row-$r',
  r == 3 ? '{"a":[1,2],"b":"x"}' : 'long ${'text ' * 80}',
];

class GridRepo extends FakeQueryRepository {
  GridRepo({super.totalRows});

  @override
  Future<FetchedRows> fetchRows(String resultId, int offset, int limit) async {
    fetches.add(offset);
    final end = (offset + limit).clamp(0, totalRows);
    return FetchedRows(
      offset: offset,
      rows: [for (var r = offset; r < end; r++) _row(r)],
      rowsSpooled: totalRows,
      done: true,
    );
  }
}

class GridEnv {
  GridEnv(this.repo, this.container, this.clipboard);

  final GridRepo repo;
  final ProviderContainer container;
  final List<String> clipboard;
}

Future<GridEnv> pumpGrid(
  WidgetTester tester, {
  int total = 1000,
  Brightness brightness = Brightness.light,
  Size size = const Size(900, 420),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final clipboard = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add(
          (call.arguments as Map<Object?, Object?>)['text']! as String,
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  final repo = GridRepo(totalRows: total);
  final container = ProviderContainer(
    overrides: [queryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container.read(resultWindowProvider('r1').notifier)
    ..onColumns(_cols)
    ..onFirstWindow([for (var r = 0; r < 500 && r < total; r++) _row(r)])
    ..onProgress(total, done: true);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: const Scaffold(body: ResultGrid(resultId: 'r1')),
      ),
    ),
  );
  await tester.pump();
  return GridEnv(repo, container, clipboard);
}

Future<void> key(
  WidgetTester tester,
  LogicalKeyboardKey k, {
  bool ctrl = false,
  bool shift = false,
}) async {
  if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(k);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

Future<void> tapCell(WidgetTester tester, Finder f) async {
  await tester.tapAt(tester.getCenter(f));
  // Let the double-tap window close so no timer is left pending.
  await tester.pump(const Duration(milliseconds: 400));
}

/// Goldens render slightly differently across macOS versions (anti-aliasing),
/// so allow a tiny pixel difference instead of requiring identical bytes.
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

void main() {
  setUpAll(() {
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      goldenFileComparator = _TolerantComparator(
        Uri.parse('${current.basedir}result_grid_test.dart'),
        tolerance: 0.005, // 0.5 % of pixels
      );
    }
  });

  testWidgets('renders header, row numbers, values and NULL', (tester) async {
    await pumpGrid(tester);
    expect(find.text('id'), findsOneWidget);
    expect(find.text('label'), findsOneWidget);
    expect(find.text('row-1'), findsOneWidget);
    expect(find.text('NULL'), findsWidgets, reason: 'row 0 has a NULL label');
    expect(find.text('1'), findsWidgets);
    expect(
      find.bySemanticsLabel('Result grid, 1000 rows, 3 columns'),
      findsOneWidget,
    );
  });

  testWidgets('long and multi-line values are truncated in the cell', (
    tester,
  ) async {
    await pumpGrid(tester);
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '');
    expect(texts.any((t) => t.endsWith('…') && t.length <= 201), isTrue);
    expect(texts.every((t) => !t.contains('\n')), isTrue);
  });

  testWidgets('only the visible cells are built', (tester) async {
    await pumpGrid(tester, total: 1000000);
    final cells = tester.widgetList<Text>(find.byType(Text)).length;
    expect(cells, lessThan(300), reason: 'viewport is ~14 rows × 3 columns');
  });

  testWidgets(
    'keyboard moves a rectangular selection and the status shows its size',
    (tester) async {
      await pumpGrid(tester);
      await tapCell(tester, find.text('row-1'));
      expect(find.text('1 × 1 selected'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
      await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
      await key(tester, LogicalKeyboardKey.arrowRight, shift: true);
      expect(find.text('3 × 2 selected'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.arrowDown); // collapses
      expect(find.text('1 × 1 selected'), findsOneWidget);
    },
  );

  testWidgets('Ctrl+A selects everything', (tester) async {
    await pumpGrid(tester, total: 1000);
    await tapCell(tester, find.text('row-1'));
    await key(tester, LogicalKeyboardKey.keyA, ctrl: true);
    expect(find.text('1000 × 3 selected'), findsOneWidget);
  });

  testWidgets('Ctrl+C copies a small resident selection locally as TSV', (
    tester,
  ) async {
    final env = await pumpGrid(tester);
    await tapCell(tester, find.text('row-1'));
    await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
    await key(tester, LogicalKeyboardKey.arrowLeft, shift: true);
    await key(tester, LogicalKeyboardKey.keyC, ctrl: true);
    await tester.pump();
    expect(env.clipboard.single, '1\trow-1\n2\trow-2\n');
    expect(env.repo.copyCancelled, 0);
  });

  testWidgets('Ctrl+Shift+C copies with the header', (tester) async {
    final env = await pumpGrid(tester);
    await tapCell(tester, find.text('row-1'));
    await key(tester, LogicalKeyboardKey.arrowLeft, shift: true);
    await key(tester, LogicalKeyboardKey.keyC, ctrl: true, shift: true);
    await tester.pump();
    expect(env.clipboard.single, 'id\tlabel\n1\trow-1\n');
  });

  testWidgets(
    'a selection beyond 10k cells copies through the core with progress',
    (tester) async {
      final env = await pumpGrid(tester, total: 20000);
      env.repo
        ..copyChunks = ['1\tx\n', '2\ty\n']
        ..copyHold = Completer<void>();
      await tapCell(tester, find.text('row-1'));
      await key(tester, LogicalKeyboardKey.keyA, ctrl: true);
      await key(tester, LogicalKeyboardKey.keyC, ctrl: true);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('copy-progress')), findsOneWidget);
      expect(find.text('2 of 20000 rows'), findsOneWidget);

      env.repo.copyHold!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copy-progress')), findsNothing);
      expect(env.clipboard.single, '1\tx\n2\ty\n');
    },
  );

  testWidgets('cancelling a core copy leaves the clipboard alone', (
    tester,
  ) async {
    final env = await pumpGrid(tester, total: 20000);
    env.repo
      ..copyChunks = ['1\tx\n']
      ..copyHold = Completer<void>();
    await tapCell(tester, find.text('row-1'));
    await key(tester, LogicalKeyboardKey.keyA, ctrl: true);
    await key(tester, LogicalKeyboardKey.keyC, ctrl: true);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('copy-progress')), findsNothing);
    expect(env.clipboard, isEmpty);
    expect(find.text('Copy cancelled'), findsOneWidget);
    expect(env.repo.copyCancelled, greaterThanOrEqualTo(1));
  });

  testWidgets('Space opens the value viewer with pretty JSON, Esc closes it', (
    tester,
  ) async {
    await pumpGrid(tester);
    // Row 3's doc column holds JSON.
    await tapCell(tester, find.text('row-3'));
    await key(tester, LogicalKeyboardKey.arrowRight);
    await key(tester, LogicalKeyboardKey.space);
    expect(find.byKey(const Key('value-viewer')), findsOneWidget);
    expect(find.textContaining('"a": ['), findsOneWidget);
    expect(find.textContaining('doc · row 4'), findsOneWidget);
    await key(tester, LogicalKeyboardKey.escape);
    expect(find.byKey(const Key('value-viewer')), findsNothing);
  });

  testWidgets('double-click opens the viewer on a long value', (tester) async {
    await pumpGrid(tester);
    final cell = find.textContaining('long text').first;
    await tester.tapAt(tester.getCenter(cell));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(tester.getCenter(cell));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('value-viewer')), findsOneWidget);
    // The viewer has the full value, not the 200-character preview.
    final full = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(full.data!.length, greaterThan(300));
  });

  testWidgets('dragging a header edge resizes the column', (tester) async {
    await pumpGrid(tester);
    final before = tester.getRect(find.text('label')).left;
    final handle = find
        .byWidgetPredicate(
          (w) =>
              w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn,
        )
        .first;
    await tester.drag(handle, const Offset(60, 0));
    await tester.pump();
    final after = tester.getRect(find.text('label')).left;
    expect(after - before, greaterThan(30), reason: 'drag slop eats some');
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('scrolling asks the window for rows around the viewport', (
    tester,
  ) async {
    final env = await pumpGrid(tester, total: 50000);
    await tester.drag(find.byType(ResultGrid), const Offset(0, -40000));
    await tester.pump();
    await tester.pump();
    expect(env.repo.fetches, isNotEmpty);
    final range = env.container.read(viewportProvider('r1'));
    expect(range.first, greaterThan(100));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('an empty result renders without errors', (tester) async {
    await pumpGrid(tester, total: 0);
    expect(find.text('id'), findsOneWidget);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.keyA, ctrl: true);
    expect(tester.takeException(), isNull);
  });

  for (final b in Brightness.values) {
    testWidgets('golden: ${b.name} theme', (tester) async {
      await pumpGrid(tester, brightness: b, size: const Size(640, 300));
      await tapCell(tester, find.text('row-1'));
      await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
      await key(tester, LogicalKeyboardKey.arrowRight, shift: true);
      await expectLater(
        find.byType(ResultGrid),
        matchesGoldenFile('goldens/result_grid_${b.name}.png'),
      );
    });
  }
}
