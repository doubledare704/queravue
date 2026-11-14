import 'dart:async';
import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/gen/queravue/v1/keyvalue.pb.dart';
import 'package:queravue/features/keyvalue/application/key_scan_controller.dart';
import 'package:queravue/features/keyvalue/application/key_value_controller.dart';
import 'package:queravue/features/keyvalue/application/pub_sub_controller.dart';
import 'package:queravue/features/keyvalue/data/key_value_repository.dart';
import 'package:queravue/features/keyvalue/domain/redis_command.dart';

class FakeKeys extends KeyValueRepository {
  FakeKeys() : super(() => throw StateError('Network access in test'));

  final scans = StreamController<ScanKeysResponse>.broadcast();
  final messages = StreamController<SubscribeResponse>.broadcast();
  ScanKeysRequest? request;

  Future<void> dispose() async {
    await scans.close();
    await messages.close();
  }

  @override
  Stream<ScanKeysResponse> scan(ScanKeysRequest request) {
    this.request = request;
    return scans.stream;
  }

  @override
  Stream<SubscribeResponse> subscribe(SubscribeRequest request) =>
      messages.stream;
}

void main() {
  const scope = (
    session: 'session',
    database: 3,
    pattern: 'users:*',
    type: KeyType.KEY_TYPE_HASH,
  );

  test('SCAN requests scope, skips empty pages, deduplicates, caps the window and cancels', () async {
    final fake = FakeKeys();
    addTearDown(fake.dispose);
    final cancelled = Completer<void>();
    fake.scans.onCancel = cancelled.complete;
    final container = ProviderContainer.test(
      overrides: [keyValueRepositoryProvider.overrideWithValue(fake)],
    );
    final provider = keyScanProvider(scope);
    container.listen(provider, (_, _) {});
    final loaded = container.read(provider.future);
    fake.scans.add(ScanKeysResponse());
    final first = KeySummary(key: utf8.encode('users:1'));
    fake.scans.add(ScanKeysResponse(keys: [first, first], scanned: Int64(2)));
    expect((await loaded).keys, [first]);
    expect(fake.request!.database, 3);
    expect(fake.request!.pattern, 'users:*');
    expect(fake.request!.typeFilter, KeyType.KEY_TYPE_HASH);

    final controller = container.read(provider.notifier);
    final next = controller.loadMore();
    fake.scans.add(
      ScanKeysResponse(
        keys: [
          for (var i = 2; i <= 2002; i++)
            KeySummary(key: utf8.encode('users:$i')),
        ],
        scanned: Int64(2003),
      ),
    );
    await next;
    final window = container.read(provider).requireValue;
    expect(window.keys.length, KeyScanController.retainedKeys);
    expect(window.dropped, 2);
    expect(window.scanned, 2003);

    final pending = controller.loadMore();
    await controller.cancel();
    await pending;
    await cancelled.future;
    expect(container.read(provider).requireValue.done, isTrue);
  });

  test('pub/sub pause freezes the view while the newest 10,000 messages are retained', () async {
    final fake = FakeKeys();
    addTearDown(fake.dispose);
    final cancelled = Completer<void>();
    fake.messages.onCancel = cancelled.complete;
    final container = ProviderContainer.test(
      overrides: [keyValueRepositoryProvider.overrideWithValue(fake)],
    );
    final provider = pubSubProvider('session');
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);
    controller.start(['live'], []);
    controller.togglePause();
    for (var i = 0; i <= PubSubController.capacity; i++) {
      fake.messages.add(
        SubscribeResponse(channel: 'live', receivedUnixMs: Int64(i)),
      );
    }
    await Future<void>.delayed(Duration.zero);
    expect(container.read(provider).messages, isEmpty);
    controller.togglePause();
    final messages = container.read(provider).messages;
    expect(messages.length, 10000);
    expect(messages.first.receivedUnixMs, Int64(10000));
    expect(messages.last.receivedUnixMs, Int64(1));
    await controller.stop();
    await cancelled.future;
  });

  test('confirmation retries only after acceptance', () async {
    final calls = <bool>[];
    Future<int> request(bool confirmed) async {
      calls.add(confirmed);
      if (confirmed) return 1;
      throw KeyValueFailure(
        KeyValueError(
          kind: KeyValueErrorKind.KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED,
          operation: 'FLUSHDB on db 3',
        ),
      );
    }

    expect(await withKeyValueConfirmation(request, (_) async => false), isNull);
    expect(calls, [false]);
    expect(
      await withKeyValueConfirmation(request, (operation) async {
        expect(operation, 'FLUSHDB on db 3');
        return true;
      }),
      1,
    );
    expect(calls, [false, false, true]);
  });

  test(
    'redis-cli quotes, escape bytes, empty arguments and invalid delimiters',
    () {
      expect(parseRedisCommand(r'''SET 'two words' "hello\x00\xff\n" ""'''), [
        utf8.encode('SET'),
        utf8.encode('two words'),
        [...utf8.encode('hello'), 0, 255, 10],
        <int>[],
      ]);
      expect(parseRedisCommand(r"GET 'can\'t'")[1], utf8.encode("can't"));
      for (final bytes in [
        <int>[],
        [0, 255],
        utf8.encode('x y'),
        utf8.encode('x:y'),
      ]) {
        expect(parseRedisCommand(quoteRedisArgument(bytes)).single, bytes);
      }
      expect(() => parseRedisCommand('GET "x'), throwsFormatException);
      expect(() => parseRedisCommand('GET "x"y'), throwsFormatException);
    },
  );
}
