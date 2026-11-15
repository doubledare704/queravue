import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../application/key_scan_controller.dart';
import '../domain/key_value_text.dart';

class KeyTree extends ConsumerStatefulWidget {
  const KeyTree({
    super.key,
    required this.scope,
    required this.window,
    required this.selected,
    required this.onSelect,
  });

  final ScanScope scope;
  final KeyScanWindow window;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  ConsumerState<KeyTree> createState() => _KeyTreeState();
}

class _KeyTreeState extends ConsumerState<KeyTree> {
  final _expanded = <String>{};
  List<_TreeRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _flatten();
  }

  @override
  void didUpdateWidget(KeyTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scope != oldWidget.scope) _expanded.clear();
    if (widget.scope != oldWidget.scope ||
        widget.window.keys != oldWidget.window.keys) {
      _flatten();
    }
  }

  void _flatten() {
    final root = _Branch('', '');
    final live = <String>{};
    for (final key in widget.window.keys) {
      final text = utf8Text(key.key);
      final parts = text?.split(':') ?? [displayBytes(key.key)];
      var branch = root;
      var prefix = '';
      for (var i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        prefix = '$prefix$part:';
        live.add(prefix);
        branch = branch.children.putIfAbsent(
          prefix,
          () => _Branch(prefix, part),
        );
      }
      branch.keys.add(key);
    }
    _expanded.retainWhere(live.contains);
    final rows = <_TreeRow>[];
    final pending = <(int, _Branch)>[(0, root)];
    while (pending.isNotEmpty) {
      final (depth, branch) = pending.removeLast();
      if (branch != root) {
        rows.add((
          depth: depth - 1,
          branch: branch,
          key: null,
          label: branch.label,
        ));
        if (!_expanded.contains(branch.prefix)) continue;
      }
      for (final item in branch.keys) {
        rows.add((
          depth: depth,
          branch: null,
          key: item,
          label: branch == root
              ? displayBytes(item.key)
              : displayBytes(item.key.sublist(item.key.lastIndexOf(58) + 1)),
        ));
      }
      pending.addAll(
        branch.children.values.toList().reversed.map(
          (child) => (depth + 1, child),
        ),
      );
    }
    _rows = rows;
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return const Center(child: Text('No keys found'));
    return ListView.builder(
      itemCount: _rows.length,
      itemExtent: 48,
      itemBuilder: (context, index) {
        final row = _rows[index];
        final indent = (row.depth * 12.0).clamp(0.0, 96.0);
        final branch = row.branch;
        if (branch != null) {
          return Padding(
            padding: EdgeInsets.only(left: indent),
            child: ListTile(
              dense: true,
              leading: Icon(
                _expanded.contains(branch.prefix)
                    ? Icons.folder_open
                    : Icons.folder_outlined,
              ),
              title: Text(
                row.label.isEmpty ? '""' : row.label,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => setState(() {
                if (!_expanded.remove(branch.prefix)) {
                  _expanded.add(branch.prefix);
                }
                _flatten();
              }),
            ),
          );
        }
        final summary = row.key!;
        final identity = keyIdentity(summary.key);
        return _KeyRow(
          key: ValueKey(identity),
          address: (
            session: widget.scope.session,
            database: widget.scope.database,
            identity: identity,
          ),
          label: row.label,
          indent: indent,
          summary: summary,
          selected: widget.selected == identity,
          onTap: () => widget.onSelect(identity),
        );
      },
    );
  }
}

class _Branch {
  _Branch(this.prefix, this.label);

  final String prefix;
  final String label;
  final children = <String, _Branch>{};
  final keys = <KeySummary>[];
}

typedef _TreeRow = ({
  int depth,
  _Branch? branch,
  KeySummary? key,
  String label,
});

class _KeyRow extends ConsumerWidget {
  const _KeyRow({
    super.key,
    required this.address,
    required this.label,
    required this.indent,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final KeyAddress address;
  final String label;
  final double indent;
  final KeySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(keyInfoProvider(address)).value;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        dense: true,
        selected: selected,
        title: Text(label, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${keyTypeLabel(info?.type ?? summary.type)} · '
          '${ttlLabel((info?.ttlMs ?? summary.ttlMs).toInt())}',
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
