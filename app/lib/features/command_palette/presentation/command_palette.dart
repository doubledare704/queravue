import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/workspace_controller.dart';
import '../../workspace/data/workspace_repository.dart';
import '../../workspace/domain/workspace_models.dart';
import '../../workspace/presentation/workspace_flows.dart';
import '../application/palette_items.dart';
import '../domain/palette_search.dart';

export '../domain/palette_search.dart' show fuzzyMatch;

Future<void> showCommandPalette(
  BuildContext context,
  WidgetRef ref, {
  String initialQuery = '',
}) async {
  final item = await showDialog<PaletteItem>(
    context: context,
    builder: (_) => CommandPalette(initialQuery: initialQuery),
  );
  if (item != null && context.mounted) await item.run(context, ref);
}

const _hints = {
  PaletteMode.all: 'Search actions, tabs, files, connections and objects',
  PaletteMode.actions: 'Run an action',
  PaletteMode.tabs: 'Go to an open tab',
  PaletteMode.objects: 'Open a table or collection',
};

/// ⌘K palette. A leading `>` searches actions, `@` open tabs and `#` the
/// database objects loaded for the selected connection.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  late final TextEditingController _query;
  StreamSubscription<SearchHit>? _fileSearch;
  Timer? _debounce;
  List<PaletteItem> _files = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery)
      ..selection = TextSelection.collapsed(offset: widget.initialQuery.length);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_fileSearch?.cancel());
    _query.dispose();
    super.dispose();
  }

  PaletteQuery get _parsed => parsePaletteQuery(_query.text);

  List<PaletteItem> get _matches {
    final parsed = _parsed;
    final wanted = switch (parsed.mode) {
      PaletteMode.all => PaletteGroup.values.toSet(),
      PaletteMode.actions => {PaletteGroup.action},
      PaletteMode.tabs => {PaletteGroup.tab},
      PaletteMode.objects => {PaletteGroup.object},
    };
    final searching = parsed.text.isNotEmpty;
    final pool = [
      for (final i in ref.read(paletteItemsProvider))
        if (wanted.contains(i.group) &&
            (searching || i.group != PaletteGroup.object))
          i,
      if (parsed.mode == PaletteMode.all) ..._files,
    ];
    return rankPaletteItems(pool, parsed.text);
  }

  void _onChanged(String _) {
    setState(() => _index = 0);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _searchFiles);
  }

  void _searchFiles() {
    unawaited(_fileSearch?.cancel());
    final parsed = _parsed;
    if (parsed.mode != PaletteMode.all || parsed.text.length < 2) {
      if (_files.isNotEmpty) setState(() => _files = const []);
      return;
    }
    final q = parseSearch(parsed.text);
    final hits = <PaletteItem>[];
    _fileSearch = ref
        .read(workspaceRepositoryProvider)
        .search(q.text, tags: q.tags)
        .listen((h) {
          hits.add(_fileItem(h));
          if (mounted) setState(() => _files = [...hits]);
        }, onError: (_) {});
  }

  PaletteItem _fileItem(SearchHit h) => PaletteItem(
    id: 'file.${h.file}',
    title: h.meta.title.isNotEmpty ? h.meta.title : h.file.name,
    subtitle: h.file.path,
    group: PaletteGroup.file,
    run: (context, ref) => openFileFlow(context, ref, h.file),
  );

  void _move(int delta) {
    final n = _matches.length;
    if (n == 0) return;
    setState(() => _index = (_index + delta) % n);
  }

  void _pick([PaletteItem? item]) {
    final m = _matches;
    item ??= m.isEmpty ? null : m[_index.clamp(0, m.length - 1)];
    if (item != null) Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(paletteItemsProvider);
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _hints[_parsed.mode],
                  border: InputBorder.none,
                ),
                onChanged: _onChanged,
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
                            trailing: _Trailing(c),
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

class _Trailing extends StatelessWidget {
  const _Trailing(this.item);

  final PaletteItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.conflicted)
          Tooltip(
            message: 'This shortcut is used by another action',
            child: Icon(Icons.warning_amber, size: 16, color: scheme.error),
          ),
        if (item.trailing.isNotEmpty)
          Text(item.trailing)
        else if (item.group != PaletteGroup.action)
          Text(
            item.group.label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
      ],
    );
  }
}
