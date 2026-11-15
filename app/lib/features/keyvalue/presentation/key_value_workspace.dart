import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../application/key_scan_controller.dart';
import '../application/key_value_actions.dart';
import '../domain/key_value_text.dart';
import 'key_cli.dart';
import 'key_details.dart';
import 'key_pub_sub.dart';
import 'key_tree.dart';

class KeyValueWorkspace extends ConsumerStatefulWidget {
  const KeyValueWorkspace({super.key, required this.session});

  final String session;

  @override
  ConsumerState<KeyValueWorkspace> createState() => _KeyValueWorkspaceState();
}

class _KeyValueWorkspaceState extends ConsumerState<KeyValueWorkspace>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  final _patternField = TextEditingController();
  final _filterFocus = FocusNode();
  final _details = GlobalKey<KeyDetailsState>();
  int _database = 0;
  String _pattern = '';
  String? _selected;
  KeyType _type = KeyType.KEY_TYPE_UNSPECIFIED;

  ScanScope get _scope => (
    session: widget.session,
    database: _database,
    pattern: _pattern,
    type: _type,
  );

  @override
  void dispose() {
    _tabs.dispose();
    _patternField.dispose();
    _filterFocus.dispose();
    super.dispose();
  }

  void _select(String? identity) {
    setState(() => _selected = identity);
    ref
        .read(keyValueSelectionProvider(widget.session).notifier)
        .select(hasKey: identity != null);
  }

  void _run(KeyValueAction action) {
    switch (action) {
      case KeyValueAction.cli:
        _tabs.index = 1;
      case KeyValueAction.pubSub:
        _tabs.index = 2;
      case KeyValueAction.browse:
        _tabs.index = 0;
      case KeyValueAction.filter:
        _tabs.index = 0;
        _filterFocus.requestFocus();
      case KeyValueAction.loadMore:
        _tabs.index = 0;
        unawaited(ref.read(keyScanProvider(_scope).notifier).loadMore());
      case KeyValueAction.cancelScan:
        _tabs.index = 0;
        unawaited(ref.read(keyScanProvider(_scope).notifier).cancel());
      case KeyValueAction.refresh:
        _tabs.index = 0;
        ref.invalidate(keyScanProvider(_scope));
      default:
        _tabs.index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_details.currentState?.run(action));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(keyValueActionProvider(widget.session), (_, action) {
      if (action != null) _run(action.$1);
    });
    ref.watch(keyValueSelectionProvider(widget.session));
    final databases = ref.watch(keyDatabasesProvider(widget.session));
    final scope = _scope;
    final scan = ref.watch(keyScanProvider(scope));
    final window = scan.value;
    final known = {
      for (final db in databases.value?.databases ?? <KvDatabase>[])
        db.index: db,
    };
    final limit = databases.value?.databaseLimit ?? 0;
    final indices = {
      0,
      _database,
      ...known.keys,
      for (var i = 0; i < limit; i++) i,
    }.toList()..sort();
    final selected = _selected;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Keys'),
            Tab(text: 'CLI'),
            Tab(text: 'Pub/sub'),
          ],
        ),
        if (databases.hasError)
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(keyDatabasesProvider(widget.session)),
            icon: const Icon(Icons.refresh),
            label: Text('Database list unavailable: ${databases.error}'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('Database'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _database,
                items: [
                  for (final index in indices)
                    DropdownMenuItem(
                      value: index,
                      child: Text(
                        'DB $index${known.containsKey(index) ? ' · ${known[index]!.keyCount} keys' : ''}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null || value == _database) return;
                  _select(null);
                  setState(() => _database = value);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabs,
            builder: (context, _) => IndexedStack(
              index: _tabs.index,
              sizing: StackFit.expand,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _patternField,
                              focusNode: _filterFocus,
                              decoration: InputDecoration(
                                labelText: 'Key pattern',
                                hintText: 'e.g. session:*',
                                suffixIcon: IconButton(
                                  tooltip: 'Apply filter',
                                  icon: const Icon(Icons.search),
                                  onPressed: () => setState(
                                    () => _pattern = _patternField.text,
                                  ),
                                ),
                              ),
                              onSubmitted: (value) =>
                                  setState(() => _pattern = value),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DropdownButton<KeyType>(
                                value: _type,
                                items: [
                                  for (final type in KeyType.values)
                                    if (type != KeyType.KEY_TYPE_HYPERLOGLOG)
                                      DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type == KeyType.KEY_TYPE_UNSPECIFIED
                                              ? 'All types'
                                              : keyTypeLabel(type),
                                        ),
                                      ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _type = value);
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Rescan keys',
                                onPressed: () =>
                                    ref.invalidate(keyScanProvider(scope)),
                                icon: const Icon(Icons.refresh),
                              ),
                              if (!scan.hasError && window?.done != true)
                                IconButton(
                                  tooltip: 'Cancel scan',
                                  onPressed: () => ref
                                      .read(keyScanProvider(scope).notifier)
                                      .cancel(),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                ),
                            ],
                          ),
                          if (scan.isLoading || window?.loadingMore == true)
                            const LinearProgressIndicator(),
                          Expanded(
                            child: scan.hasError
                                ? Center(child: Text('${scan.error}'))
                                : window == null
                                ? const SizedBox.shrink()
                                : KeyTree(
                                    key: ValueKey(scope),
                                    scope: scope,
                                    window: window,
                                    selected: selected,
                                    onSelect: _select,
                                  ),
                          ),
                          if (window != null) ...[
                            Text(
                              '${window.keys.length} shown · ${window.scanned} scanned',
                            ),
                            if (window.dropped > 0)
                              const Text('Earlier keys left the scan window.'),
                            TextButton(
                              onPressed:
                                  scan.isLoading ||
                                      window.loadingMore ||
                                      window.done
                                  ? null
                                  : ref
                                        .read(keyScanProvider(scope).notifier)
                                        .loadMore,
                              child: const Text('Load more'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 4,
                      child: selected == null
                          ? const Center(child: Text('Select a key'))
                          : KeyedSubtree(
                              key: ValueKey((_database, selected)),
                              child: KeyDetails(
                                key: _details,
                                address: (
                                  session: widget.session,
                                  database: _database,
                                  identity: selected,
                                ),
                                onKeyChanged: (value) {
                                  _select(value);
                                  ref.invalidate(keyScanProvider(scope));
                                },
                              ),
                            ),
                    ),
                  ],
                ),
                KeyCli(
                  session: widget.session,
                  database: _database,
                  keys: window?.keys ?? const [],
                ),
                KeyPubSub(session: widget.session),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
