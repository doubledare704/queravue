import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/actions/app_action.dart';
import '../../../shared/actions/key_chord.dart';
import '../application/keybindings_controller.dart';

Future<void> showKeybindingsDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(
      context: context,
      builder: (_) => const KeybindingsDialog(),
    );

class KeybindingsDialog extends ConsumerWidget {
  const KeybindingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(actionRegistryProvider);
    final controller = ref.read(keybindingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final problems = registry.problems;
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Keyboard shortcuts')),
          TextButton(
            key: const Key('keybindings-reset-all'),
            onPressed: registry.overrides.chords.isEmpty
                ? null
                : controller.resetAll,
            child: const Text('Reset all'),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        height: 460,
        child: ListView(
          children: [
            if (registry.conflicts.isNotEmpty)
              _Banner(
                key: const Key('keybindings-conflicts'),
                color: scheme.errorContainer,
                lines: [
                  'Conflicting shortcuts do nothing until you change one:',
                  for (final c in registry.conflicts)
                    '${c.chord.label}: ${c.actions.map((a) => a.title).join(', ')}',
                ],
              ),
            if (problems.isNotEmpty)
              _Banner(
                key: const Key('keybindings-problems'),
                color: scheme.tertiaryContainer,
                lines: ['Ignored in keybindings.json:', ...problems],
              ),
            for (final category in ActionCategory.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Text(
                  category.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              for (final a in registry.actions.where(
                (a) => a.category == category,
              ))
                _Row(
                  action: a,
                  chord: registry.chordOf(a.id),
                  conflicted: registry.isConflicted(a.id),
                  overridden: registry.overrides.chords.containsKey(a.id),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.color, required this.lines});

  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final l in lines) Text(l)],
    ),
  );
}

class _Row extends ConsumerWidget {
  const _Row({
    required this.action,
    required this.chord,
    required this.conflicted,
    required this.overridden,
  });

  final AppAction action;
  final KeyChord? chord;
  final bool conflicted;
  final bool overridden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(keybindingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('keybinding-${action.id}'),
      dense: true,
      title: Text(action.title),
      subtitle: action.subtitle.isEmpty ? null : Text(action.subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (conflicted)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.warning_amber, size: 16, color: scheme.error),
            ),
          Text(
            chord?.label ?? 'Unbound',
            style: TextStyle(
              color: chord == null ? scheme.onSurfaceVariant : null,
              fontWeight: overridden ? FontWeight.bold : null,
            ),
          ),
          IconButton(
            key: Key('keybinding-change-${action.id}'),
            tooltip: 'Change shortcut',
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () async {
              final picked = await showDialog<KeyChord>(
                context: context,
                builder: (_) => _CaptureDialog(title: action.title),
              );
              if (picked != null) await controller.setChord(action.id, picked);
            },
          ),
          IconButton(
            key: Key('keybinding-clear-${action.id}'),
            tooltip: 'Remove shortcut',
            icon: const Icon(Icons.clear, size: 18),
            onPressed: chord == null
                ? null
                : () => controller.setChord(action.id, null),
          ),
          IconButton(
            key: Key('keybinding-reset-${action.id}'),
            tooltip: 'Restore default',
            icon: const Icon(Icons.restore, size: 18),
            onPressed: overridden ? () => controller.reset(action.id) : null,
          ),
        ],
      ),
    );
  }
}

class _CaptureDialog extends StatelessWidget {
  const _CaptureDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Shortcut for "$title"'),
    content: Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.handled;
        final chord = KeyChord.fromEvent(event);
        if (chord != null) Navigator.of(context).pop(chord);
        return KeyEventResult.handled;
      },
      child: const Text('Press the new key combination.'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ],
  );
}
