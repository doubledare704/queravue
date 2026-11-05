import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connections/application/connections_controller.dart';
import '../connections/presentation/connection_actions.dart';

/// One palette entry.
class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.title,
    required this.run,
    this.subtitle = '',
    this.shortcut = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String shortcut;
  final Future<void> Function(BuildContext context, WidgetRef ref) run;
}

/// Commands for the palette: global actions plus one per connection.
final paletteCommandsProvider = Provider<List<PaletteCommand>>((ref) {
  final conns = ref.watch(connectionsControllerProvider).value ?? const [];
  return [
    PaletteCommand(
      id: 'connection.new',
      title: 'New connection',
      shortcut: '⌘N',
      run: showConnectionDialog,
    ),
    for (final c in conns)
      PaletteCommand(
        id: 'connection.connect.${c.id}',
        title: 'Connect: ${c.name}',
        subtitle: [c.engineId, if (c.folder.isNotEmpty) c.folder].join(' · '),
        run: (context, ref) => connectTo(ref, c),
      ),
  ];
});

/// Case-insensitive subsequence match, so "lpg" finds "Local PG".
bool fuzzyMatch(String query, String text) {
  final q = query.toLowerCase().replaceAll(' ', '');
  final t = text.toLowerCase();
  var i = 0;
  for (var j = 0; j < t.length && i < q.length; j++) {
    if (t[j] == q[i]) i++;
  }
  return i == q.length;
}

Future<void> showCommandPalette(BuildContext context, WidgetRef ref) async {
  final cmd = await showDialog<PaletteCommand>(
    context: context,
    builder: (_) => const CommandPalette(),
  );
  if (cmd != null && context.mounted) await cmd.run(context, ref);
}

/// ⌘K palette (stub): filter and run commands.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _query = TextEditingController();
  int _index = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<PaletteCommand> get _matches => ref
      .read(paletteCommandsProvider)
      .where((c) => fuzzyMatch(_query.text, c.title))
      .toList();

  void _move(int delta) {
    final n = _matches.length;
    if (n == 0) return;
    // Dart's % on ints is non-negative, so this wraps both ways.
    setState(() => _index = (_index + delta) % n);
  }

  void _pick([PaletteCommand? cmd]) {
    final m = _matches;
    cmd ??= m.isEmpty ? null : m[_index.clamp(0, m.length - 1)];
    if (cmd != null) Navigator.of(context).pop(cmd);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(paletteCommandsProvider);
    final matches = _matches;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('palette-query'),
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Type a command or connection name',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() => _index = 0),
                onSubmitted: (_) => _pick(),
              ),
              const Divider(height: 1),
              Flexible(
                child: matches.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No matching commands'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (_, i) {
                          final c = matches[i];
                          return ListTile(
                            key: Key('palette-${c.id}'),
                            dense: true,
                            selected: i == _index,
                            selectedTileColor: scheme.secondaryContainer,
                            title: Text(c.title),
                            subtitle: c.subtitle.isEmpty
                                ? null
                                : Text(c.subtitle),
                            trailing: c.shortcut.isEmpty
                                ? null
                                : Text(c.shortcut),
                            onTap: () => _pick(c),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
