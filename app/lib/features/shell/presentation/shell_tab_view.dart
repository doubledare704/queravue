import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shortcuts.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/shell_actions.dart';
import '../application/shell_tab_controller.dart';
import 'js_editor.dart';
import 'output_pane.dart';
import 'shell_dialogs.dart';

/// A Mongo shell tab: JavaScript editor on top, output below.
class ShellTabView extends ConsumerStatefulWidget {
  const ShellTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<ShellTabView> createState() => _ShellTabViewState();
}

class _ShellTabViewState extends ConsumerState<ShellTabView> {
  bool _asking = false;

  Future<void> _confirm(PendingConfirmation p) async {
    if (_asking) return;
    _asking = true;
    final name =
        ref
            .read(connectionsControllerProvider)
            .value
            ?.where((c) => c.id == widget.tab.connectionId)
            .firstOrNull
            ?.name ??
        'This connection';
    final ok = await confirmShellOperation(
      context,
      operation: p.operation,
      connectionName: name,
    );
    _asking = false;
    if (!mounted) return;
    final c = ref.read(shellTabProvider(widget.tab.id).notifier);
    if (ok) {
      await c.confirmPending();
    } else {
      c.dismissPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    ref.listen(shellTabProvider(tab.id).select((s) => s.pending), (_, p) {
      if (p != null) unawaited(_confirm(p));
    });
    final state = ref.watch(shellTabProvider(tab.id));
    final c = ref.read(shellTabProvider(tab.id).notifier);
    final cs = Theme.of(context).colorScheme;
    final lastError = state.entries.whereType<OutputError>().lastOrNull;
    final errorLine = lastError != null && lastError.failure.line > 0
        ? lastError.line
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              FilledButton.icon(
                key: const Key('shell-run'),
                onPressed: state.busy ? null : () => runShellTab(ref, tab),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text('Run ($primaryLabel↵)'),
              ),
              const SizedBox(width: 8),
              if (state.showCancel)
                OutlinedButton.icon(
                  key: const Key('shell-cancel'),
                  onPressed: c.cancel,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Cancel'),
                ),
              if (state.busy && !state.showCancel)
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const Spacer(),
              IconButton(
                key: const Key('shell-clear'),
                tooltip: 'Clear output',
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                onPressed: state.entries.isEmpty ? null : c.clear,
              ),
            ],
          ),
        ),
        if (state.connectionError != null)
          MaterialBanner(
            key: const Key('shell-connection-error'),
            content: Text(state.connectionError!),
            backgroundColor: cs.errorContainer,
            actions: const [SizedBox.shrink()],
          ),
        const Divider(height: 1),
        Expanded(
          flex: 5,
          child: JsEditor(
            key: Key('shell-editor-${tab.id}'),
            controller: tab.controller,
            errorLine: errorLine,
            connectionId: tab.connectionId,
            database: tab.shellDatabase,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 6,
          child: ShellOutputPane(
            entries: state.entries,
            shellId: state.shellId,
            onJump: (line, col) => jumpToLine(tab, line, col),
          ),
        ),
      ],
    );
  }
}
