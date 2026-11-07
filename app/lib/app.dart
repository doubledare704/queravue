import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_client/core_providers.dart';
import 'features/command_palette/command_palette.dart';
import 'features/connections/presentation/connection_actions.dart';
import 'features/editor/application/editor_actions.dart';
import 'features/editor/domain/query_models.dart';
import 'features/editor/presentation/workspace.dart';
import 'features/history/presentation/history_dialog.dart';
import 'features/workspace/presentation/left_sidebar.dart';
import 'features/workspace/presentation/workspace_flows.dart';
import 'shared/shortcuts.dart';
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
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Main window: connection sidebar, workspace and status bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Cmd on macOS, Ctrl elsewhere.
  static SingleActivator primary(LogicalKeyboardKey key) =>
      primaryShortcut(key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        primary(LogicalKeyboardKey.keyN): () =>
            showConnectionDialog(context, ref),
        primary(LogicalKeyboardKey.keyK): () =>
            showCommandPalette(context, ref),
        primaryShortcut(LogicalKeyboardKey.enter): () =>
            runActiveTab(ref, ExecuteMode.statementAtCursor),
        primaryShortcut(LogicalKeyboardKey.enter, shift: true): () =>
            runActiveTab(ref, ExecuteMode.all),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            cancelActiveTab(ref),
        primary(LogicalKeyboardKey.keyT): () => openQueryTab(ref),
        primary(LogicalKeyboardKey.keyW): () => closeQueryTab(ref),
        primary(LogicalKeyboardKey.keyY): () => showHistoryDialog(context, ref),
        primary(LogicalKeyboardKey.keyS): () => saveActiveTabFlow(context, ref),
        primaryShortcut(LogicalKeyboardKey.keyS, shift: true): () =>
            saveActiveTabAsFlow(context, ref),
        primary(LogicalKeyboardKey.keyO): () => quickOpenFlow(context, ref),
        primaryShortcut(LogicalKeyboardKey.keyF, shift: true): () =>
            searchWorkspaceFlow(ref),
        primaryShortcut(LogicalKeyboardKey.keyT, shift: true): () =>
            openShellTab(ref),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 260, child: LeftSidebar()),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const Expanded(child: Workspace()),
            ],
          ),
          bottomNavigationBar: const StatusBar(),
        ),
      ),
    );
  }
}
