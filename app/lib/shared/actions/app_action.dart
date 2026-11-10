import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'key_chord.dart';

enum ActionCategory {
  connection('Connection'),
  editor('Editor'),
  documents('Documents'),
  workspace('Workspace'),
  view('View');

  const ActionCategory(this.label);
  final String label;
}

typedef ActionWatch = T Function<T>(ProviderListenable<T> provider);
typedef ActionEnabled = bool Function(ActionWatch watch);
typedef ActionRun = Future<void> Function(BuildContext context, WidgetRef ref);

/// Something the user can do. The palette, the shortcuts and the menus are all
/// built from the same list of these.
@immutable
class AppAction {
  const AppAction({
    required this.id,
    required this.title,
    required this.category,
    required this.run,
    this.subtitle = '',
    this.defaultChord,
    this.inMenu = true,
    this.enabledWhen,
  });

  final String id;
  final String title;
  final String subtitle;
  final ActionCategory category;
  final KeyChord? defaultChord;
  final bool inMenu;
  final ActionRun run;

  /// Null means always enabled. A disabled action is greyed out in the
  /// palette and the menus, and its shortcut does nothing.
  final ActionEnabled? enabledWhen;
}
