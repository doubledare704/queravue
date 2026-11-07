import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SidebarMode { connections, workspace }

/// Which panel the sidebar shows.
class SidebarModeController extends Notifier<SidebarMode> {
  @override
  SidebarMode build() => SidebarMode.connections;

  void show(SidebarMode mode) => state = mode;
}

final sidebarModeProvider =
    NotifierProvider<SidebarModeController, SidebarMode>(
      SidebarModeController.new,
    );

/// True while a request to focus the workspace search box is waiting to be
/// served by the panel.
class WorkspaceSearchFocus extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  void consume() => state = false;
}

final workspaceSearchFocusProvider =
    NotifierProvider<WorkspaceSearchFocus, bool>(WorkspaceSearchFocus.new);
