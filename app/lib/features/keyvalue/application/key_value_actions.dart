import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/actions/app_action.dart';
import '../../../shared/actions/key_chord.dart';
import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';

final hasKeyValueProvider = Provider.family<bool, String>(
  (ref, id) =>
      ref
          .watch(connectionCapabilitiesProvider(id))
          ?.contains('key_value_store') ??
      false,
);

enum KeyValueAction {
  browse('Browse keys', LogicalKeyboardKey.keyB),
  cli('Open key-value CLI', LogicalKeyboardKey.keyK),
  pubSub('Open pub/sub', LogicalKeyboardKey.keyU),
  filter('Filter keys'),
  loadMore('Load more keys'),
  cancelScan('Cancel key scan'),
  refresh('Refresh key scan'),
  focusValue('Edit selected key value'),
  add('Add value'),
  expiry('Set key TTL'),
  rename('Rename key'),
  delete('Delete key');

  const KeyValueAction(this.title, [this.key]);

  final String title;
  final LogicalKeyboardKey? key;

  bool get needsKey => index >= focusValue.index;
}

final keyValueActionProvider = NotifierProvider.autoDispose
    .family<KeyValueActions, (KeyValueAction, int)?, String>(
      KeyValueActions.new,
    );

final keyValueSelectionProvider = NotifierProvider.autoDispose
    .family<KeyValueSelection, bool, String>(KeyValueSelection.new);

class KeyValueSelection extends Notifier<bool> {
  KeyValueSelection(this.session);

  final String session;

  @override
  bool build() => false;

  void select({required bool hasKey}) => state = hasKey;
}

class KeyValueActions extends Notifier<(KeyValueAction, int)?> {
  KeyValueActions(this.session);

  final String session;

  @override
  (KeyValueAction, int)? build() => null;

  void dispatch(KeyValueAction action) =>
      state = (action, (state?.$2 ?? 0) + 1);
}

List<AppAction> keyValueActions() => [
  for (final action in KeyValueAction.values)
    AppAction(
      id: 'keyvalue.${action.name}',
      title: action.title,
      category: ActionCategory.workspace,
      defaultChord: action.key == null
          ? null
          : KeyChord(action.key!, primary: true, shift: true),
      enabledWhen: (watch) {
        final id = watch(selectedConnectionProvider);
        if (id == null || !watch(hasKeyValueProvider(id))) return false;
        final session = watch(connectionSessionProvider(id)).sessionId;
        return session != null &&
            (!action.needsKey || watch(keyValueSelectionProvider(session)));
      },
      run: (_, ref) async {
        final id = ref.read(selectedConnectionProvider);
        if (id == null || !ref.read(hasKeyValueProvider(id))) return;
        final session = ref.read(connectionSessionProvider(id)).sessionId;
        if (session != null) {
          ref.read(keyValueActionProvider(session).notifier).dispatch(action);
        }
      },
    ),
];
