import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../data/key_value_repository.dart';

final pubSubProvider = NotifierProvider.autoDispose
    .family<PubSubController, PubSubState, String>(PubSubController.new);

typedef PubSubState = ({
  bool active,
  bool paused,
  List<SubscribeResponse> messages,
  String? error,
});

class PubSubController extends Notifier<PubSubState> {
  PubSubController(this.session);

  final String session;

  static const capacity = 10000;
  final _messages = ListQueue<SubscribeResponse>();
  StreamSubscription<SubscribeResponse>? _subscription;
  Timer? _refresh;

  @override
  PubSubState build() {
    ref.onDispose(() {
      _refresh?.cancel();
      unawaited(_subscription?.cancel());
    });
    return (active: false, paused: false, messages: const [], error: null);
  }

  void start(List<String> channels, List<String> patterns) {
    if (state.active || (channels.isEmpty && patterns.isEmpty)) return;
    state = (
      active: true,
      paused: false,
      messages: state.messages,
      error: null,
    );
    try {
      _subscription = ref
          .read(keyValueRepositoryProvider)
          .subscribe(
            SubscribeRequest(
              sessionId: session,
              channels: channels,
              patterns: patterns,
            ),
          )
          .listen(
            (message) {
              if (_messages.length == capacity) _messages.removeFirst();
              _messages.addLast(message);
              if (!state.paused) {
                _refresh ??= Timer(const Duration(milliseconds: 100), () {
                  _refresh = null;
                  _showMessages();
                });
              }
            },
            onError: (Object error) => _finish(error.toString()),
            onDone: () => _finish(null),
            cancelOnError: true,
          );
    } on Object catch (error) {
      _finish(error.toString());
    }
  }

  void _showMessages() {
    if (!state.paused) {
      state = (
        active: state.active,
        paused: false,
        messages: List.unmodifiable(_messages.toList().reversed),
        error: state.error,
      );
    }
  }

  void _finish(String? error) {
    _refresh?.cancel();
    _refresh = null;
    _subscription = null;
    state = (
      active: false,
      paused: false,
      messages: state.messages,
      error: error,
    );
    _showMessages();
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _finish(null);
    await subscription?.cancel();
  }

  void togglePause() {
    state = (
      active: state.active,
      paused: !state.paused,
      messages: state.messages,
      error: state.error,
    );
    _showMessages();
  }
}
