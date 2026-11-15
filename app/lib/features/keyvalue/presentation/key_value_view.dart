import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../domain/key_value_text.dart';

typedef ValueRow = ({
  String label,
  String value,
  WriteOp? remove,
  List<int>? editable,
  Object? id,
});

List<ValueRow> valueRows(ReadValueResponse page) => switch (page.whichValue()) {
  ReadValueResponse_Value.hash => [
    for (final entry in page.hash.entries)
      (
        label: displayBytes(entry.field_1),
        value: displayBytes(entry.value),
        remove: WriteOp(hashDelete: WriteOp_HashDelete(field_1: entry.field_1)),
        editable: entry.value,
        id: entry.field_1,
      ),
  ],
  ReadValueResponse_Value.list => [
    for (final (index, item) in page.list.items.indexed)
      (
        label: '${page.list.startIndex.toInt() + index}',
        value: displayBytes(item),
        remove: WriteOp(listRemove: WriteOp_ListRemove(value: item)),
        editable: item,
        id: page.list.startIndex.toInt() + index,
      ),
  ],
  ReadValueResponse_Value.set => [
    for (final member in page.set.members)
      (
        label: displayBytes(member),
        value: '',
        remove: WriteOp(setRemove: WriteOp_SetRemove(members: [member])),
        editable: null,
        id: null,
      ),
  ],
  ReadValueResponse_Value.zset => [
    for (final entry in page.zset.entries)
      (
        label: displayBytes(entry.member),
        value: '${entry.score}',
        remove: WriteOp(
          zsetRemove: WriteOp_ZsetRemove(members: [entry.member]),
        ),
        editable: null,
        id: entry.member,
      ),
  ],
  ReadValueResponse_Value.stream => [
    for (final entry in page.stream.entries)
      (
        label: entry.id,
        value: entry.fields
            .map(
              (field) =>
                  '${displayBytes(field.field_1)} = ${displayBytes(field.value)}',
            )
            .join(' · '),
        remove: WriteOp(streamDelete: WriteOp_StreamDelete(ids: [entry.id])),
        editable: null,
        id: null,
      ),
  ],
  _ => const [],
};

class KeyValueView extends StatelessWidget {
  const KeyValueView({
    super.key,
    required this.page,
    required this.onEdit,
    required this.onRemove,
    required this.busy,
  });

  final ReadValueResponse page;
  final ValueChanged<ValueRow> onEdit;
  final ValueChanged<ValueRow> onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    switch (page.whichValue()) {
      case ReadValueResponse_Value.stringValue:
        return _StringView(value: page.stringValue);
      case ReadValueResponse_Value.json:
        return JsonValueTree(text: page.json.json);
      case ReadValueResponse_Value.hyperloglog:
        return Center(
          child: Text('Estimated cardinality · ${page.hyperloglog.count}'),
        );
      default:
        final rows = valueRows(page);
        if (rows.isEmpty) {
          return const Center(child: Text('This page is empty'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              title: Text(row.label, overflow: TextOverflow.ellipsis),
              subtitle: row.value.isEmpty
                  ? null
                  : Text(
                      row.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: Wrap(
                children: [
                  if (row.id != null)
                    IconButton(
                      tooltip: 'Edit value',
                      onPressed: busy ? null : () => onEdit(row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  IconButton(
                    tooltip: 'Remove value',
                    onPressed: busy ? null : () => onRemove(row),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}

enum _StringMode { text, json, hex }

class _StringView extends StatefulWidget {
  const _StringView({required this.value});

  final StringValue value;

  @override
  State<_StringView> createState() => _StringViewState();
}

class _StringViewState extends State<_StringView> {
  _StringMode? _mode;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final text = value.binary ? null : utf8Text(value.data);
    final mode = text == null ? _StringMode.hex : _mode ?? _StringMode.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final option in _StringMode.values)
              ChoiceChip(
                label: Text(switch (option) {
                  _StringMode.text => 'Text',
                  _StringMode.json => 'JSON',
                  _StringMode.hex => 'Hex',
                }),
                selected: mode == option,
                onSelected: text == null && option != _StringMode.hex
                    ? null
                    : (_) => setState(() => _mode = option),
              ),
          ],
        ),
        if (text == null) const Text('Binary or incomplete UTF-8'),
        if (value.totalBytes.toInt() > value.data.length)
          Text(
            '${value.data.length} bytes on this page · ${value.totalBytes} total',
          ),
        Expanded(
          child: switch (mode) {
            _StringMode.json => JsonValueTree(text: text!),
            _StringMode.text => SingleChildScrollView(
              child: SelectableText(text!),
            ),
            _StringMode.hex => ListView.builder(
              itemCount: (value.data.length + 15) ~/ 16,
              itemBuilder: (context, index) {
                final start = index * 16;
                final end = (start + 16).clamp(start, value.data.length);
                return SelectableText(
                  '${start.toRadixString(16).padLeft(8, '0')}  ${hexBytes(value.data.sublist(start, end))}',
                  style: const TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
          },
        ),
      ],
    );
  }
}

class JsonValueTree extends StatefulWidget {
  const JsonValueTree({super.key, required this.text});

  final String text;

  @override
  State<JsonValueTree> createState() => _JsonValueTreeState();
}

class _JsonValueTreeState extends State<JsonValueTree> {
  final _collapsed = <String>{};
  List<_JsonRow>? _rows;
  Object? _value;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(JsonValueTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _decode();
  }

  void _decode() {
    try {
      _value = jsonDecode(widget.text);
      _collapsed.clear();
      _flatten();
    } on FormatException {
      _rows = null;
    }
  }

  void _flatten() {
    final rows = <_JsonRow>[];
    final stack = <_JsonRow>[(path: '', label: r'$', depth: 0, value: _value)];
    while (stack.isNotEmpty) {
      final row = stack.removeLast();
      rows.add(row);
      if (_collapsed.contains(row.path)) continue;
      final children = switch (row.value) {
        final Map<String, dynamic> map => map.entries.map(
          (entry) => (entry.key, entry.value as Object?),
        ),
        final List<dynamic> list => list.indexed.map(
          (entry) => ('${entry.$1}', entry.$2 as Object?),
        ),
        _ => const <(String, Object?)>[],
      };
      stack.addAll(
        children.toList().reversed.map(
          (child) => (
            path: '${row.path}/${Uri.encodeComponent(child.$1)}',
            label: child.$1,
            depth: row.depth + 1,
            value: child.$2,
          ),
        ),
      );
    }
    _rows = rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) {
      return const Center(child: Text('Invalid or incomplete JSON'));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final description = switch (row.value) {
          final Map<String, dynamic> map => '{${map.length}}',
          final List<dynamic> list => '[${list.length}]',
          _ => jsonEncode(row.value),
        };
        final expandable =
            row.value is Map<String, dynamic> || row.value is List<dynamic>;
        return Padding(
          padding: EdgeInsets.only(left: (row.depth * 12.0).clamp(0.0, 96.0)),
          child: ListTile(
            dense: true,
            leading: expandable
                ? Icon(
                    _collapsed.contains(row.path)
                        ? Icons.chevron_right
                        : Icons.expand_more,
                  )
                : null,
            title: Text(
              '${row.label}  $description',
              overflow: TextOverflow.ellipsis,
            ),
            onTap: expandable
                ? () => setState(() {
                    if (!_collapsed.remove(row.path)) _collapsed.add(row.path);
                    _flatten();
                  })
                : null,
          ),
        );
      },
    );
  }
}

typedef _JsonRow = ({String path, String label, int depth, Object? value});
