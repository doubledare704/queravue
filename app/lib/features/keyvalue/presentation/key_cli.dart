import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../application/key_value_controller.dart';
import '../data/key_value_repository.dart';
import '../domain/redis_command.dart';
import 'key_dialogs.dart';

class KeyCli extends ConsumerStatefulWidget {
  const KeyCli({
    super.key,
    required this.session,
    required this.database,
    required this.keys,
  });

  final String session;
  final int database;
  final List<KeySummary> keys;

  @override
  ConsumerState<KeyCli> createState() => _KeyCliState();
}

typedef _CliEntry = ({String command, int database, String output});

class _KeyCliState extends ConsumerState<KeyCli> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _history = <String>[];
  final _output = <_CliEntry>[];
  int? _historyIndex;
  String _draft = '';
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setInput(String text) {
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _recall(int direction) {
    if (_history.isEmpty) return;
    if (_historyIndex == null) _draft = _input.text;
    final index = ((_historyIndex ?? _history.length) + direction).clamp(
      0,
      _history.length,
    );
    _historyIndex = index == _history.length ? null : index;
    _setInput(_historyIndex == null ? _draft : _history[index]);
  }

  List<String> _suggestions() {
    final text = _input.text;
    final separator = text.indexOf(RegExp(r'\s'));
    if (separator == -1) {
      if (text.isEmpty) return const [];
      return redisCommands
          .where((name) => name.startsWith(text.toUpperCase()))
          .take(8)
          .toList();
    }
    final prefix = text.substring(0, text.lastIndexOf(RegExp(r'\s')) + 1);
    final token = text.substring(prefix.length);
    return widget.keys
        .map((key) => quoteRedisArgument(key.key))
        .where((key) => key.startsWith(token))
        .take(8)
        .map((key) => '$prefix$key')
        .toList();
  }

  Future<void> _run() async {
    final command = _input.text;
    if (_busy || command.trim().isEmpty) return;
    final database = widget.database;
    final session = widget.session;
    final repository = ref.read(keyValueRepositoryProvider);
    setState(() {
      _busy = true;
      _historyIndex = null;
      if (_history.length == 100) _history.removeAt(0);
      _history.add(command);
    });
    _input.clear();
    String? output;
    try {
      final args = parseRedisCommand(command);
      final reply = await withKeyValueConfirmation(
        (confirmed) => repository.execute(
          ExecuteCommandRequest(
            sessionId: session,
            database: database,
            args: args,
            confirmed: confirmed,
          ),
        ),
        (operation) => mounted
            ? confirmKeyOperation(context, operation)
            : Future.value(false),
      );
      if (reply != null) output = formatRedisReply(reply);
    } on Object catch (error) {
      output = error.toString();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (output != null) {
        if (_output.length == 100) _output.removeAt(0);
        _output.add((command: command, database: database, output: output));
      }
    });
    if (_focus.context != null) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Expanded(
          child: _output.isEmpty
              ? const Center(child: Text('Enter a command to get started'))
              : ListView.builder(
                  reverse: true,
                  itemCount: _output.length,
                  itemBuilder: (context, index) {
                    final entry = _output[_output.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SelectableText(
                        'DB ${entry.database}> ${entry.command}\n${entry.output}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
        if (_busy) const LinearProgressIndicator(),
        ListenableBuilder(
          listenable: Listenable.merge([_input, _focus]),
          builder: (context, _) {
            final suggestions = _focus.hasFocus
                ? _suggestions()
                : const <String>[];
            return Wrap(
              spacing: 6,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion, overflow: TextOverflow.ellipsis),
                    onPressed: () => _setInput(suggestion),
                  ),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _recall(-1);
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _recall(1);
                  } else if (event.logicalKey == LogicalKeyboardKey.tab &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    final completion = _suggestions().firstOrNull;
                    if (completion == null) return KeyEventResult.ignored;
                    _setInput(completion);
                  } else {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                },
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  decoration: const InputDecoration(labelText: 'Command'),
                  onSubmitted: (_) => _run(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _run,
              child: const Text('Run'),
            ),
          ],
        ),
      ],
    ),
  );
}
