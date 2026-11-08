import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote {
  _Remote(this.text, this.caret, this.logLength);

  String text;
  int caret;
  int logLength;
}

final _remotes = Expando<_Remote>();

/// Types [chars] into the focused re_editor as the platform would: as an IME
/// insertion delta at the caret. re_editor ignores whole-value updates, so
/// `testTextInput.enterText` does nothing for it.
///
/// The editor only publishes its text to the platform when it changed it
/// itself, so the helper follows its own insertions and re-reads the editor's
/// state whenever the editor published a new one.
Future<void> typeInEditor(WidgetTester tester, String chars) async {
  final log = tester.testTextInput.log;
  final client =
      log.lastWhere((c) => c.method == 'TextInput.setClient').arguments[0]
          as int;
  var remote = _remotes[tester];
  final published = log
      .where((c) => c.method == 'TextInput.setEditingState')
      .toList();
  if (remote == null || published.length != remote.logLength) {
    final state = published.last.arguments as Map<dynamic, dynamic>;
    remote = _Remote(
      state['text'] as String,
      state['selectionBase'] as int,
      published.length,
    );
    _remotes[tester] = remote;
  }
  final old = remote.text;
  final at = remote.caret;
  final end = at + chars.length;
  remote
    ..text = old.replaceRange(at, at, chars)
    ..caret = end;
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('TextInputClient.updateEditingStateWithDeltas', [
      client,
      {
        'deltas': [
          {
            'oldText': old,
            'deltaText': chars,
            'deltaStart': at,
            'deltaEnd': at,
            'selectionBase': end,
            'selectionExtent': end,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': -1,
            'composingExtent': -1,
            'deltaType': 'TextEditingDeltaType.insertion',
          },
        ],
      },
    ]),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/textinput',
    message,
    (_) {},
  );
  await tester.pump();
  await tester.pump();
}
