import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../data/key_value_repository.dart';
import '../domain/key_value_text.dart';

typedef ScanScope = ({
  String session,
  int database,
  String pattern,
  KeyType type,
});

typedef KeyAddress = ({String session, int database, String identity});

final keyScanProvider = AsyncNotifierProvider.autoDispose
    .family<KeyScanController, KeyScanWindow, ScanScope>(KeyScanController.new);

final keyDatabasesProvider = FutureProvider.autoDispose
    .family<ListKvDatabasesResponse, String>(
      (ref, session) =>
          ref.watch(keyValueRepositoryProvider).databases(session),
    );

final keyInfoProvider = FutureProvider.autoDispose
    .family<GetKeyInfoResponse, KeyAddress>(
      (ref, key) => ref
          .watch(keyValueRepositoryProvider)
          .info(
            GetKeyInfoRequest(
              sessionId: key.session,
              database: key.database,
              key: keyBytes(key.identity),
            ),
          ),
    );

class KeyScanWindow {
  const KeyScanWindow({
    this.keys = const [],
    this.scanned = 0,
    this.dropped = 0,
    this.done = false,
    this.loadingMore = false,
  });

  final List<KeySummary> keys;
  final int scanned;
  final int dropped;
  final bool done;
  final bool loadingMore;
}

class KeyScanController extends AsyncNotifier<KeyScanWindow> {
  KeyScanController(this.scope);

  final ScanScope scope;

  static const retainedKeys = 2000;

  @override
  Future<KeyScanWindow> build() {
    _iterator = null;
    final stream = ref
        .watch(keyValueRepositoryProvider)
        .scan(
          ScanKeysRequest(
            sessionId: scope.session,
            database: scope.database,
            pattern: scope.pattern,
            typeFilter: scope.type,
            pageSize: 200,
          ),
        );
    final iterator = StreamIterator(stream);
    _cancelled = false;
    _iterator = iterator;
    ref.onDispose(() => unawaited(iterator.cancel()));
    return _next(iterator, const KeyScanWindow());
  }

  StreamIterator<ScanKeysResponse>? _iterator;
  bool _cancelled = false;

  Future<void> cancel() async {
    final iterator = _iterator;
    if (iterator == null) return;
    final previous = state.value;
    _cancelled = true;
    await iterator.cancel();
    if (ref.mounted && identical(_iterator, iterator)) {
      state = AsyncData(
        KeyScanWindow(
          keys: previous?.keys ?? const [],
          scanned: previous?.scanned ?? 0,
          dropped: previous?.dropped ?? 0,
          done: true,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final previous = state.value;
    if (state.isLoading ||
        previous == null ||
        previous.done ||
        previous.loadingMore) {
      return;
    }
    final iterator = _iterator;
    if (iterator == null) return;
    state = AsyncData(
      KeyScanWindow(
        keys: previous.keys,
        scanned: previous.scanned,
        dropped: previous.dropped,
        loadingMore: true,
      ),
    );
    final next = await AsyncValue.guard(() => _next(iterator, previous));
    if (ref.mounted && !_cancelled && identical(_iterator, iterator)) {
      state = next;
    }
  }

  Future<KeyScanWindow> _next(
    StreamIterator<ScanKeysResponse> iterator,
    KeyScanWindow previous,
  ) async {
    try {
      while (await iterator.moveNext()) {
        final page = iterator.current;
        if (page.keys.isEmpty && !page.done) continue;
        if (page.done) {
          // The final gRPC trailers can arrive after the server's done page.
          await iterator.moveNext();
        }
        final known = {
          for (final key in previous.keys) keyIdentity(key.key): key,
        };
        for (final key in page.keys) {
          known.putIfAbsent(keyIdentity(key.key), () => key);
        }
        final excess = known.length > retainedKeys
            ? known.length - retainedKeys
            : 0;
        return KeyScanWindow(
          keys: List.unmodifiable(known.values.skip(excess)),
          scanned: page.scanned.toInt(),
          dropped: previous.dropped + excess,
          done: page.done,
        );
      }
      return KeyScanWindow(
        keys: previous.keys,
        scanned: previous.scanned,
        dropped: previous.dropped,
        done: true,
      );
    } catch (_) {
      await iterator.cancel();
      rethrow;
    }
  }
}
