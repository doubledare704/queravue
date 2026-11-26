import 'package:flutter/services.dart';

import '../../../shared/actions/app_action.dart';
import '../../../shared/actions/key_chord.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../presentation/gridfs_flows.dart';
import 'gridfs_controller.dart';

List<AppAction> gridFsActions() => [
  _action(
    GridFsAction.upload,
    'Upload file to GridFS',
    LogicalKeyboardKey.keyU,
  ),
  _action(
    GridFsAction.download,
    'Download GridFS file',
    LogicalKeyboardKey.keyD,
    selected: true,
  ),
  _action(
    GridFsAction.rename,
    'Rename GridFS file',
    LogicalKeyboardKey.f2,
    selected: true,
  ),
  _action(
    GridFsAction.replace,
    'Replace GridFS file',
    LogicalKeyboardKey.keyP,
    selected: true,
  ),
  _action(
    GridFsAction.delete,
    'Delete GridFS file',
    LogicalKeyboardKey.backspace,
    selected: true,
  ),
  _action(
    GridFsAction.refresh,
    'Refresh or cancel GridFS operation',
    LogicalKeyboardKey.keyR,
  ),
];

EditorTab? _activeTab(ActionWatch watch) =>
    watch(editorTabsProvider).activeFor(watch(selectedConnectionProvider));

AppAction _action(
  GridFsAction action,
  String title,
  LogicalKeyboardKey key, {
  bool selected = false,
}) => AppAction(
  id: 'gridfs.${action.name}',
  title: title,
  category: ActionCategory.documents,
  defaultChord: KeyChord(key, primary: true, alt: true, shift: true),
  enabledWhen: (watch) {
    final tab = _activeTab(watch);
    if (tab == null || !tab.isGridFs) return false;
    final state = watch(gridFsControllerProvider(tab.id));
    if (state.target == null) return false;
    if (state.work != null) {
      return action == GridFsAction.refresh && state.work!.canCancel;
    }
    return !selected || state.selection != null;
  },
  run: (context, ref) async {
    final tab = _activeTab(ref.read);
    if (tab != null && tab.isGridFs) {
      await runGridFsAction(context, ref, tab, action);
    }
  },
);
