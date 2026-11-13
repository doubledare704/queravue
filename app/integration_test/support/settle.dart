import 'package:flutter_test/flutter_test.dart';

const _frameWait = Duration(seconds: 20);

/// [WidgetTester.pumpAndSettle] that fails with the likely reason instead of
/// hanging when the app window stops drawing (docs/testing.md).
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle().timeout(
  _frameWait,
  onTimeout: () => fail(
    'No frame for ${_frameWait.inSeconds} s: the app window is probably '
    'hidden or covered. Run through make (it sets QUERAVUE_E2E=1) and keep '
    'the display awake.',
  ),
);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await settle(tester);
}

/// Pumps until [check], which may talk to the core, holds.
Future<void> pumpUntilServer(
  WidgetTester tester,
  String what,
  Future<bool> Function() check, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (await tester.runAsync(check) ?? false) return;
  }
  fail('timed out waiting for $what');
}
