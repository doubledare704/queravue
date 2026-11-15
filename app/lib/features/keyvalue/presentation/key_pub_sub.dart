import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../application/pub_sub_controller.dart';
import '../data/key_value_repository.dart';
import '../domain/key_value_text.dart';

class KeyPubSub extends ConsumerStatefulWidget {
  const KeyPubSub({super.key, required this.session});

  final String session;

  @override
  ConsumerState<KeyPubSub> createState() => _KeyPubSubState();
}

class _KeyPubSubState extends ConsumerState<KeyPubSub> {
  final _channels = TextEditingController();
  final _patterns = TextEditingController();
  final _channel = TextEditingController();
  final _payload = TextEditingController();
  String? _result;
  bool _publishing = false;

  @override
  void dispose() {
    _channels.dispose();
    _patterns.dispose();
    _channel.dispose();
    _payload.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_publishing || _channel.text.isEmpty) return;
    setState(() {
      _publishing = true;
      _result = null;
    });
    String result;
    try {
      final count = await ref
          .read(keyValueRepositoryProvider)
          .publish(
            PublishRequest(
              sessionId: widget.session,
              channel: _channel.text,
              payload: utf8.encode(_payload.text),
            ),
          );
      result = 'Delivered to $count subscriber${count == 1 ? '' : 's'}';
    } on Object catch (error) {
      result = error.toString();
    }
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pubSubProvider(widget.session));
    final controller = ref.read(pubSubProvider(widget.session).notifier);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _channels,
                  enabled: !state.active,
                  decoration: const InputDecoration(
                    labelText: 'Channels (comma separated)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _patterns,
                  enabled: !state.active,
                  decoration: const InputDecoration(
                    labelText: 'Patterns (comma separated)',
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: state.active
                    ? controller.stop
                    : () {
                        final channels = _split(_channels.text);
                        final patterns = _split(_patterns.text);
                        if (channels.isEmpty && patterns.isEmpty) {
                          setState(
                            () => _result =
                                'Enter at least one channel or pattern.',
                          );
                        } else {
                          setState(() => _result = null);
                          controller.start(channels, patterns);
                        }
                      },
                child: Text(state.active ? 'Unsubscribe' : 'Subscribe'),
              ),
              TextButton(
                onPressed: state.active ? controller.togglePause : null,
                child: Text(state.paused ? 'Resume' : 'Pause'),
              ),
              Text(
                '${state.messages.length} / ${PubSubController.capacity} messages',
              ),
            ],
          ),
          if (state.error != null) Text(state.error!),
          Expanded(
            child: state.messages.isEmpty
                ? const Center(child: Text('No messages received'))
                : ListView.builder(
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          displayBytes(message.payload),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${message.channel}'
                          '${message.pattern.isEmpty ? '' : ' · ${message.pattern}'}'
                          ' · ${DateTime.fromMillisecondsSinceEpoch(message.receivedUnixMs.toInt())}',
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _channel,
                  decoration: const InputDecoration(
                    labelText: 'Publish channel',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _payload,
                  decoration: const InputDecoration(labelText: 'Message'),
                  onSubmitted: (_) => _publish(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _publishing ? null : _publish,
                child: const Text('Publish'),
              ),
            ],
          ),
          if (_result != null) Text(_result!),
        ],
      ),
    );
  }
}

List<String> _split(String text) => text
    .split(',')
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList();
