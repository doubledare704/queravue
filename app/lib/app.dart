import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_client/core_providers.dart';
import 'features/editor/application/layout_persistence.dart';
import 'features/editor/presentation/workspace.dart';
import 'features/keybindings/application/keybindings_controller.dart';
import 'features/workspace/presentation/left_sidebar.dart';
import 'shared/actions/action_shortcuts.dart';
import 'shared/panes/pane_sizes.dart';
import 'shared/theme.dart';
import 'shared/widgets/status_bar.dart';

/// Root widget.
class QueravueApp extends ConsumerStatefulWidget {
  const QueravueApp({super.key});

  @override
  ConsumerState<QueravueApp> createState() => _QueravueAppState();
}

class _QueravueAppState extends ConsumerState<QueravueApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop the core gracefully on quit. If the app dies instead, the core
    // sees EOF on stdin and exits on its own.
    _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
  }

  Future<AppExitResponse> _onExitRequested() async {
    await ref.read(layoutPersistenceProvider).flush();
    await ref.read(coreSupervisorProvider).dispose();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queravue',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomeScreen(),
    );
  }
}

/// Main window: connection sidebar, workspace and status bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(layoutPersistenceProvider);
    final registry = ref.watch(actionRegistryProvider);
    final panes = ref.watch(paneSizesProvider);
    return ActionMenuBar(
      registry: registry,
      enabledActionIds: enabledActionIdsProvider,
      child: ActionShortcuts(
        registry: registry,
        enabledActionIds: enabledActionIdsProvider,
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (panes.sidebarVisible) ...[
                  SizedBox(
                    width: panes.sidebarWidth,
                    child: const LeftSidebar(),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      key: const Key('sidebar-divider'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (d) => ref
                          .read(paneSizesProvider.notifier)
                          .dragSidebar(d.delta.dx),
                      onDoubleTap: ref
                          .read(paneSizesProvider.notifier)
                          .toggleSidebar,
                      child: SizedBox(
                        width: 5,
                        child: VerticalDivider(
                          width: 5,
                          thickness: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                const Expanded(child: Workspace()),
              ],
            ),
            bottomNavigationBar: const StatusBar(),
          ),
        ),
      ),
    );
  }
}
