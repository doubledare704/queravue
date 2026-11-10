import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Axis;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/editor_layout.dart';
import 'editor_tabs.dart';

@immutable
class EditorLayoutState {
  const EditorLayoutState([this.byConnection = const {}]);

  final Map<String, EditorLayout> byConnection;

  EditorLayout of(String connectionId) =>
      byConnection[connectionId] ?? const EditorLayout();

  EditorLayoutState withLayout(String connectionId, EditorLayout layout) =>
      EditorLayoutState({...byConnection, connectionId: layout});
}

/// How each connection's tabs are split into groups. The active tab of the
/// focused group is the connection's active tab in [EditorTabsState], so
/// everything that acts on "the active tab" keeps working.
final editorLayoutProvider =
    NotifierProvider<EditorLayoutController, EditorLayoutState>(
      EditorLayoutController.new,
    );

class EditorLayoutController extends Notifier<EditorLayoutState> {
  @override
  EditorLayoutState build() {
    final tabsNotifier = ref.read(editorTabsProvider.notifier);
    tabsNotifier.closeSuccessor = (connectionId, tabId) =>
        state.of(connectionId).successorOnClose(tabId);
    ref.onDispose(() => tabsNotifier.closeSuccessor = null);
    ref.listen(editorTabsProvider, (_, tabs) {
      final next = _reconciled(tabs, state);
      if (!mapEquals(next.byConnection, state.byConnection)) state = next;
    });
    return _reconciled(ref.read(editorTabsProvider), const EditorLayoutState());
  }

  EditorLayoutState _reconciled(EditorTabsState tabs, EditorLayoutState from) {
    final idsByConnection = <String, List<String>>{};
    for (final t in tabs.tabs) {
      idsByConnection.putIfAbsent(t.connectionId, () => []).add(t.id);
    }
    return EditorLayoutState({
      for (final e in idsByConnection.entries)
        e.key: from
            .of(e.key)
            .reconcile(
              tabIds: e.value,
              requestedActive: tabs.activeByConnection[e.key],
            ),
    });
  }

  void split(String connectionId, Axis along) =>
      _apply(connectionId, (l) => l.split(along));

  void moveActive(String connectionId, int delta) =>
      _apply(connectionId, (l) => l.moveActive(delta));

  void moveTab(
    String connectionId,
    String tabId,
    int toGroup, {
    String? before,
  }) => _apply(connectionId, (l) => l.moveTab(tabId, toGroup, before: before));

  void focusGroup(String connectionId, int index) =>
      _apply(connectionId, (l) => l.focusGroup(index));

  void focusRelative(String connectionId, int delta) =>
      _apply(connectionId, (l) {
        final n = l.groups.length;
        return l.focusGroup((l.focused + delta) % n);
      });

  void resize(String connectionId, int dividerIndex, double delta) {
    final next = state.of(connectionId).resize(dividerIndex, delta);
    state = state.withLayout(connectionId, next);
  }

  /// Puts back a layout read from disk, for tabs that already exist.
  void restore(String connectionId, EditorLayout layout) {
    state = state.withLayout(connectionId, layout);
    final active = layout.focusedGroup.activeId;
    if (active != null) ref.read(editorTabsProvider.notifier).select(active);
  }

  void _apply(String connectionId, EditorLayout Function(EditorLayout) change) {
    final before = state.of(connectionId);
    final after = change(before);
    if (after == before) return;
    state = state.withLayout(connectionId, after);
    final active = after.focusedGroup.activeId;
    if (active != null) ref.read(editorTabsProvider.notifier).select(active);
  }
}
