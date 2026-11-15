import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/core_client/gen/queravue/v1/keyvalue.pb.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/keyvalue/data/key_value_repository.dart';
import 'package:queravue/features/keyvalue/presentation/key_value_workspace.dart';

Future<void> _wait(
  WidgetTester tester,
  bool Function() ready,
  String label,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (ready()) return;
  }
  fail('Timed out waiting for $label');
}

Future<void> _visible(WidgetTester tester, Finder finder) =>
    _wait(tester, () => finder.evaluate().isNotEmpty, finder.toString());

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets(
    'browse, edit, expire, rename and delete a Redis key; run CLI and pub/sub',
    skip: Platform.environment['QUERAVUE_E2E'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);

      final container = ProviderContainer(
        overrides: [
          coreSupervisorProvider.overrideWith((ref) {
            final supervisor = CoreSupervisor(
              launcher: ref.watch(coreLauncherProvider),
              connector: ref.watch(coreConnectorProvider),
              heartbeatTimeout: const Duration(minutes: 2),
            )..start();
            ref.onDispose(supervisor.dispose);
            return supervisor;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QueravueApp(),
        ),
      );
      await _wait(
        tester,
        () => container.read(coreStatusProvider) is CoreConnected,
        'core',
      );
      final prefix = 'qv_e2e_${DateTime.now().microsecondsSinceEpoch}';
      final key = '$prefix:value';
      final renamed = '$prefix:renamed';
      final connections = container.read(connectionsRepositoryProvider);
      final env = Platform.environment;
      final connection = (await tester.runAsync(
        () => connections.create(
          ConnectionProfile(
            name: 'Redis workspace E2E',
            engineId: 'redis',
            params: {
              'hosts':
                  '${env['REDIS_HOST'] ?? '127.0.0.1'}:${env['REDIS_PORT'] ?? '6379'}',
            },
          ),
          password: env['REDIS_PASSWORD'] ?? 'queravue',
        ),
      ))!;
      await tester.runAsync(
        () => container.read(connectionsControllerProvider.notifier).reload(),
      );
      final session = await tester.runAsync(
        () => container
            .read(connectionSessionProvider(connection.id).notifier)
            .connect(),
      );
      expect(session?.capabilities, contains('key_value_store'));
      final repository = container.read(keyValueRepositoryProvider);
      const database = 0;
      Future<RespValue> command(List<String> args) async =>
          (await tester.runAsync(
            () => repository.execute(
              ExecuteCommandRequest(
                sessionId: session!.id,
                database: database,
                args: args.map(utf8.encode),
              ),
            ),
          ))!;
      await command(['SET', key, 'initial', 'EX', '300']);
      try {
        container
            .read(selectedConnectionProvider.notifier)
            .select(connection.id);
        await _visible(tester, find.byType(KeyValueWorkspace));
        final pattern = find.widgetWithText(TextField, 'Key pattern');
        await tester.enterText(pattern, '$prefix:*');
        expect(tester.widget<TextField>(pattern).controller!.text, '$prefix:*');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _visible(tester, find.text(prefix));
        await tester.tap(find.text(prefix));
        await _visible(tester, find.text('value'));
        await tester.tap(find.text('value'));
        await _visible(tester, find.text('initial'));
        await tester.tap(find.widgetWithText(TextButton, 'Edit value'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextFormField), 'changed');
        await tester.tap(find.text('Save'));
        await _visible(tester, find.text('changed'));
        expect(
          utf8.decode((await command(['GET', key])).stringValue),
          'changed',
        );

        await tester.tap(find.text('TTL'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextFormField), '60000');
        await tester.tap(find.text('Save'));
        await _wait(
          tester,
          () => find
              .textContaining(RegExp(r'\b[1-9]\d+ ms'))
              .evaluate()
              .isNotEmpty,
          'TTL',
        );
        expect((await command(['PTTL', key])).integer.toInt(), greaterThan(0));

        await tester.tap(find.text('Rename'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextFormField), renamed);
        await tester.tap(find.text('Save'));
        await _visible(tester, find.text(renamed));
        expect((await command(['EXISTS', key])).integer.toInt(), 0);

        await tester.tap(find.text('CLI'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.widgetWithText(TextField, 'Command'),
          'GET "$renamed"',
        );
        await tester.tap(find.text('Run'));
        await _visible(tester, find.textContaining('(string) changed'));

        await tester.tap(find.widgetWithText(Tab, 'Pub/sub'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.widgetWithText(TextField, 'Channels (comma separated)'),
          prefix,
        );
        await tester.tap(find.text('Subscribe'));
        for (var attempt = 0; attempt < 30; attempt++) {
          final receivers = await command([
            'PUBLISH',
            prefix,
            'hello from Redis',
          ]);
          if (receivers.integer.toInt() > 0) break;
          await tester.pump(const Duration(milliseconds: 50));
        }
        await _visible(tester, find.text('hello from Redis'));
        await tester.tap(find.text('Unsubscribe'));
        await _visible(tester, find.text('Subscribe'));

        await tester.tap(find.widgetWithText(Tab, 'Keys'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Delete'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Confirm'));
        await _visible(tester, find.text('Select a key'));
        expect((await command(['EXISTS', renamed])).integer.toInt(), 0);
      } finally {
        try {
          await command(['DEL', key, renamed]);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
