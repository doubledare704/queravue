// Completion budget against the real core and the seeded 500-table Postgres
// schema (ADR 0015): keystroke to popup <= 50 ms p95.
//
//   docker compose -f dev/docker-compose.yml --profile large-schema up -d --wait postgres postgres-large-seed
//   make core
//   cd app && flutter drive --profile -d macos \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/completion_perf_test.dart
// or `make test-perf-completion`.
//
// Thresholds are asserted in profile mode only; debug builds record numbers.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/completion/data/completion_repository.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';

import '../test/support/editor_typing.dart';

String _env(String k, String d) => Platform.environment[k] ?? d;

Future<void> _pumpUntil(
  WidgetTester tester,
  String what,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (done()) return;
  }
  fail('timed out waiting for $what');
}

Future<void> _idle(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

int _p95(List<int> micros) {
  final sorted = [...micros]..sort();
  return sorted[(sorted.length * 95 ~/ 100).clamp(0, sorted.length - 1)];
}

double _ms(int micros) => micros / 1000;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'completion on 500 tables: keystroke to popup p95 within 50 ms',
    timeout: const Timeout(Duration(minutes: 5)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final report = <String, Object?>{
        'mode': kProfileMode ? 'profile' : 'debug',
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QueravueApp(),
        ),
      );
      await _pumpUntil(
        tester,
        'core connected',
        () => container.read(coreStatusProvider) is CoreConnected,
        timeout: const Duration(seconds: 30),
      );

      final repo = container.read(connectionsRepositoryProvider);
      final saved = await repo.create(
        ConnectionProfile(
          name: 'completion perf pg',
          engineId: 'postgres',
          params: {
            'host': _env('PG_HOST', '127.0.0.1'),
            'port': _env('PG_PORT', '5432'),
            'database': _env('PG_DB', 'queravue'),
            'user': _env('PG_USER', 'queravue'),
            'sslmode': 'disable',
          },
        ),
        password: _env('PG_PASSWORD', 'queravue'),
      );
      addTearDown(() => repo.delete(saved.id));
      await container.read(connectionsControllerProvider.notifier).reload();
      container.read(selectedConnectionProvider.notifier).select(saved.id);
      await tester.pumpAndSettle();

      final session = await container
          .read(connectionSessionProvider(saved.id).notifier)
          .connect();
      expect(session, isNotNull, reason: 'the session must open');
      expect(session!.capabilities, contains('completion'));
      final completion = container.read(completionRepositoryProvider);

      CompletionRequest request(String text) => CompletionRequest(
        sessionId: session.id,
        context: CompletionContext.sql,
        text: text,
        cursorOffset: text.length,
        maxItems: 1000,
        schema: 'large',
      );

      // The catalog warms in the background; wait until columns are loaded.
      final warmDeadline = DateTime.now().add(const Duration(seconds: 60));
      var ready = false;
      while (!ready && DateTime.now().isBefore(warmDeadline)) {
        final r = await completion.complete(
          request('SELECT * FROM large.'),
          cancel: Future<void>.value().then(
            (_) => Future<void>.delayed(const Duration(days: 1)),
          ),
        );
        ready = r.catalogState == CatalogState.ready && r.items.length > 400;
        debugPrint(
          'WARM state=${r.catalogState} items=${r.items.length} error=${r.error}',
        );
        if (!ready) await _idle(tester, 200);
      }
      expect(ready, isTrue, reason: 'catalog READY with the 500 tables');

      // Round trip through the socket, without the UI.
      final rpc = <int>[];
      for (var i = 0; i < 60; i++) {
        final sw = Stopwatch()..start();
        await completion.complete(
          request('SELECT '),
          cancel: Completer<void>().future,
        );
        rpc.add(sw.elapsedMicroseconds);
      }
      report['rpc_p95_ms'] = _ms(_p95(rpc));

      // Route text input through the test channel so typing can be injected.
      tester.testTextInput.register();
      final tab = container.read(editorTabsProvider.notifier).open(saved.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('sql-editor-${tab.id}')));
      await tester.pump();
      await _idle(tester, 300);

      final firstChar = <int>[];
      final extend = <int>[];

      Future<void> keystroke(String ch, {required bool popupBefore}) async {
        final sw = Stopwatch()..start();
        await insertInEditor(tester, ch);
        final firstBefore = popupBefore ? _firstRow(tester) : null;
        var shown = false;
        var micros = 0;
        for (var i = 0; i < 20 && !shown; i++) {
          await tester.pump();
          micros = sw.elapsedMicroseconds;
          final popup = find.byKey(const Key('completion-popup'));
          final present = popup.evaluate().isNotEmpty;
          // Narrowing may leave the first row as it was; by the third frame
          // the list has been rebuilt for the new text either way.
          shown =
              present &&
              (!popupBefore || _firstRow(tester) != firstBefore || i >= 2);
        }
        expect(shown, isTrue, reason: 'popup after typing "$ch"');
        (popupBefore ? extend : firstChar).add(micros);
      }

      // Context changes are typed whole (the previous keystroke prefetches),
      // then the identifier is typed one character at a time.
      Future<void> scenario(String context, String word) async {
        await insertInEditor(tester, context);
        await _idle(tester, 150);
        for (var i = 0; i < word.length; i++) {
          await keystroke(word[i], popupBefore: i > 0);
          await _idle(tester, 90);
        }
        await _idle(tester, 60);
      }

      for (var round = 0; round < 6; round++) {
        await scenario('\nSELECT * FROM large.', 'account_a');
        await scenario('\nSELECT * FROM large.account x WHERE x.', 'na');
        await scenario('\nSELECT ', 'co');
        await scenario('\nSELECT * FROM large.account a JOIN large.', 'acc');
      }

      report['first_char_samples'] = firstChar.length;
      report['first_char_p50_ms'] = _ms(
        (([...firstChar]..sort())[firstChar.length ~/ 2]),
      );
      report['first_char_p95_ms'] = _ms(_p95(firstChar));
      report['extend_samples'] = extend.length;
      report['extend_p95_ms'] = _ms(_p95(extend));
      binding.reportData = {...?binding.reportData, ...report};
      debugPrint('COMPLETION PERF ${binding.reportData}');

      expect(firstChar.length, greaterThanOrEqualTo(20));
      if (kProfileMode) {
        expect(
          _ms(_p95(firstChar)),
          lessThanOrEqualTo(50),
          reason: 'keystroke to popup p95 (first character of a word)',
        );
        expect(
          _ms(_p95(extend)),
          lessThanOrEqualTo(50),
          reason: 'keystroke to popup p95 (narrowing the list)',
        );
      }
    },
  );
}

String? _firstRow(WidgetTester tester) {
  final row = find.byKey(const Key('completion-item-0'));
  if (row.evaluate().isEmpty) return null;
  final texts = find.descendant(of: row, matching: find.byType(Text));
  return texts.evaluate().isEmpty
      ? null
      : tester.widget<Text>(texts.first).data;
}
