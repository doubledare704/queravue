import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../application/key_scan_controller.dart';
import '../application/key_value_actions.dart';
import '../application/key_value_controller.dart';
import '../data/key_value_repository.dart';
import '../domain/key_value_text.dart';
import 'key_dialogs.dart';
import 'key_value_view.dart';

class KeyDetails extends ConsumerStatefulWidget {
  const KeyDetails({
    super.key,
    required this.address,
    required this.onKeyChanged,
  });

  final KeyAddress address;
  final ValueChanged<String?> onKeyChanged;

  @override
  ConsumerState<KeyDetails> createState() => KeyDetailsState();
}

class KeyDetailsState extends ConsumerState<KeyDetails> {
  final _cursors = [''];
  bool _reverse = false;
  bool _scoreOrder = true;
  bool _busy = false;
  String? _error;

  KeyAddress get _address => widget.address;
  List<int> get _key => keyBytes(_address.identity);
  KeyValueRepository get _repo => ref.read(keyValueRepositoryProvider);
  ValueScope get _scope => (
    key: _address,
    cursor: _cursors.last,
    reverse: _reverse,
    scoreOrder: _scoreOrder,
  );

  Future<void> run(KeyValueAction action) async {
    if (_busy) return;
    final page = ref.read(keyValueProvider(_scope)).value;
    switch (action) {
      case KeyValueAction.add:
        if (page != null && _canAdd(page)) await _add(page);
      case KeyValueAction.focusValue:
        if (page != null) {
          if (_canReplace(page)) {
            await _add(page);
          } else {
            final rows = valueRows(page);
            for (final row in rows) {
              if (row.id != null) {
                await _edit(row);
                break;
              }
            }
          }
        }
      case KeyValueAction.expiry:
        await _expiry();
      case KeyValueAction.rename:
        await _rename();
      case KeyValueAction.delete:
        await _delete();
      default:
        break;
    }
  }

  Future<bool> _confirm(String title) =>
      mounted ? confirmKeyOperation(context, title) : Future.value(false);

  Future<void> _perform(Future<void> Function() operation) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    setState(() => _cursors.replaceRange(0, _cursors.length, ['']));
    ref.invalidate(keyInfoProvider(_address));
    ref.invalidate(keyValueProvider(_scope));
  }

  Future<void> _write(WriteOp op) async {
    final changed = await withKeyValueConfirmation((confirmed) async {
      await _repo.write(
        WriteValueRequest(
          sessionId: _address.session,
          database: _address.database,
          key: _key,
          op: op,
          confirmed: confirmed,
        ),
      );
      return true;
    }, _confirm);
    if (mounted && changed == true) _refresh();
  }

  Future<void> _expiry() => _perform(() async {
    final ttl = ref.read(keyInfoProvider(_address)).value?.ttlMs.toInt() ?? -1;
    final values = await keyInputs(context, 'Set key TTL', [
      input('Milliseconds (empty to persist)', ttl < 0 ? '' : '$ttl'),
    ]);
    if (values == null || !mounted) return;
    final text = values.single.trim();
    final milliseconds = int.tryParse(text);
    if (text.isNotEmpty && (milliseconds == null || milliseconds <= 0)) {
      throw const FormatException('Enter a positive TTL in milliseconds.');
    }
    await _repo.expiry(
      SetExpiryRequest(
        sessionId: _address.session,
        database: _address.database,
        key: _key,
        ttlMs: milliseconds == null ? null : Int64(milliseconds),
      ),
    );
    if (mounted) ref.invalidate(keyInfoProvider(_address));
  });

  Future<void> _rename() => _perform(() async {
    final original = utf8Text(_key);
    final values = await keyInputs(context, 'Rename key', [
      original == null
          ? input('New key (hex)', hexBytes(_key))
          : input('New key', original),
    ]);
    if (values == null || !mounted) return;
    final target = original == null
        ? parseHex(values.single)
        : utf8.encode(values.single);
    if (keyIdentity(target) == _address.identity) return;
    final changed = await withKeyValueConfirmation((confirmed) async {
      await _repo.rename(
        RenameKeyRequest(
          sessionId: _address.session,
          database: _address.database,
          key: _key,
          newKey: target,
          confirmed: confirmed,
        ),
      );
      return true;
    }, _confirm);
    if (mounted && changed == true) widget.onKeyChanged(keyIdentity(target));
  });

  Future<void> _delete() => _perform(() async {
    if (!await _confirm('Delete ${displayBytes(_key)}?') || !mounted) return;
    final changed = await withKeyValueConfirmation((confirmed) async {
      await _repo.delete(
        DeleteKeysRequest(
          sessionId: _address.session,
          database: _address.database,
          keys: [_key],
          confirmed: confirmed,
        ),
      );
      return true;
    }, _confirm);
    if (mounted && changed == true) widget.onKeyChanged(null);
  });

  Future<void> _edit(ValueRow row) => _perform(() async {
    final id = row.id;
    final editable = row.editable;
    final text = editable == null ? null : utf8Text(editable);
    final values = await keyInputs(context, 'Edit ${row.label}', [
      if (editable == null)
        input('Score', row.value)
      else if (text == null)
        input('Value (hex)', hexBytes(editable), true)
      else
        input('Value', text, true),
    ]);
    if (values == null || !mounted) return;
    final value = text == null ? null : utf8.encode(values.single);
    await _write(switch (id) {
      final int index => WriteOp(
        listSet: WriteOp_ListSet(
          index: Int64(index),
          value: value ?? parseHex(values.single),
        ),
      ),
      final List<int> bytes when editable != null => WriteOp(
        hashSet: WriteOp_HashSet(
          field_1: bytes,
          value: value ?? parseHex(values.single),
        ),
      ),
      final List<int> bytes => _zadd(bytes, values.single),
      _ => throw StateError('This value cannot be edited in place.'),
    });
  });

  Future<void> _remove(ValueRow row) => _perform(() async {
    final op = row.remove;
    if (op == null) return;
    final title = op.hasListRemove()
        ? 'Remove all occurrences of this list value?'
        : 'Remove ${row.label}?';
    if (await _confirm(title) && mounted) await _write(op);
  });

  bool _canReplace(ReadValueResponse page) =>
      page.hasJson() ||
      (page.hasStringValue() &&
          _cursors.last.isEmpty &&
          page.stringValue.totalBytes.toInt() == page.stringValue.data.length);

  bool _canAdd(ReadValueResponse page) =>
      _canReplace(page) || (!page.hasStringValue() && !page.hasHyperloglog());

  Future<void> _add(ReadValueResponse page) => _perform(() async {
    final text = page.hasStringValue() && !page.stringValue.binary
        ? utf8Text(page.stringValue.data)
        : null;
    final fields = switch (page.whichValue()) {
      ReadValueResponse_Value.stringValue => [
        text == null
            ? input('Value (hex)', hexBytes(page.stringValue.data), true)
            : input('Value', text, true),
      ],
      ReadValueResponse_Value.hash => [
        input('Field'),
        input('Value', '', true),
      ],
      ReadValueResponse_Value.list => [input('Value to append', '', true)],
      ReadValueResponse_Value.set => [input('Member')],
      ReadValueResponse_Value.zset => [input('Member'), input('Score', '0')],
      ReadValueResponse_Value.stream => [
        input('Entry ID', '*'),
        input('Field/value pairs as JSON object', '{"field":"value"}', true),
      ],
      ReadValueResponse_Value.json => [
        input('JSON path', r'$'),
        input('JSON value', _jsonRoot(page.json.json), true),
      ],
      _ => const <KeyInput>[],
    };
    if (fields.isEmpty) return;
    final values = await keyInputs(
      context,
      _canReplace(page) ? 'Edit value' : 'Add value',
      fields,
    );
    if (values == null || !mounted) return;
    await _write(switch (page.whichValue()) {
      ReadValueResponse_Value.stringValue => WriteOp(
        setString: WriteOp_SetString(
          value: text == null
              ? parseHex(values.single)
              : utf8.encode(values.single),
        ),
      ),
      ReadValueResponse_Value.hash => WriteOp(
        hashSet: WriteOp_HashSet(
          field_1: utf8.encode(values[0]),
          value: utf8.encode(values[1]),
        ),
      ),
      ReadValueResponse_Value.list => WriteOp(
        listPush: WriteOp_ListPush(values: [utf8.encode(values.single)]),
      ),
      ReadValueResponse_Value.set => WriteOp(
        setAdd: WriteOp_SetAdd(members: [utf8.encode(values.single)]),
      ),
      ReadValueResponse_Value.zset => _zadd(utf8.encode(values[0]), values[1]),
      ReadValueResponse_Value.stream => WriteOp(
        streamAdd: WriteOp_StreamAdd(
          id: values[0],
          fields: _streamFields(values[1]),
        ),
      ),
      ReadValueResponse_Value.json => WriteOp(
        jsonSet: WriteOp_JsonSet(
          path: values[0],
          json: jsonEncode(jsonDecode(values[1])),
        ),
      ),
      _ => throw StateError('This value is read-only.'),
    });
  });

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(keyInfoProvider(_address));
    final value = ref.watch(keyValueProvider(_scope));
    final page = value.value;
    final metadata = info.value;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            displayBytes(_key),
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
          ),
          if (metadata != null)
            Text(
              '${keyTypeLabel(metadata.type)} · ${ttlLabel(metadata.ttlMs.toInt())} · '
              'Length ${metadata.length}'
              '${metadata.hasMemoryBytes() ? ' · ${metadata.memoryBytes} bytes in memory' : ''}'
              '${metadata.encoding.isEmpty ? '' : ' · ${metadata.encoding}'}',
            ),
          if (metadata?.bigKey == true) const Text('Large key'),
          if (info.hasError) Text('${info.error}'),
          Wrap(
            children: [
              TextButton(
                onPressed: _busy ? null : _expiry,
                child: const Text('TTL'),
              ),
              TextButton(
                onPressed: _busy ? null : _rename,
                child: const Text('Rename'),
              ),
              TextButton(
                onPressed: _busy ? null : _delete,
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: _busy ? null : _refresh,
                child: const Text('Refresh'),
              ),
              if (page != null && _canAdd(page))
                TextButton(
                  onPressed: _busy ? null : () => _add(page),
                  child: Text(_canReplace(page) ? 'Edit value' : 'Add value'),
                ),
              if (page?.hasZset() == true)
                FilterChip(
                  label: const Text('Order by score'),
                  selected: _scoreOrder,
                  onSelected: _busy
                      ? null
                      : (value) => setState(() {
                          _scoreOrder = value;
                          _cursors.replaceRange(0, _cursors.length, ['']);
                        }),
                ),
              if (page?.hasStream() == true)
                TextButton(
                  onPressed: _busy ? null : _jumpToStreamId,
                  child: const Text('Start at ID'),
                ),
              if (page?.hasStream() == true ||
                  (page?.hasZset() == true && _scoreOrder))
                FilterChip(
                  label: const Text('Descending'),
                  selected: _reverse,
                  onSelected: _busy
                      ? null
                      : (value) => setState(() {
                          _reverse = value;
                          _cursors.replaceRange(0, _cursors.length, ['']);
                        }),
                ),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_busy || value.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: value.hasError
                ? Center(child: Text('${value.error}'))
                : page == null
                ? const SizedBox.shrink()
                : KeyValueView(
                    page: page,
                    onEdit: _edit,
                    onRemove: _remove,
                    busy: _busy || value.isLoading,
                  ),
          ),
          if (_cursors.length > 1 || (page?.nextCursor.isNotEmpty ?? false))
            Row(
              children: [
                TextButton(
                  onPressed: _busy || value.isLoading || _cursors.length == 1
                      ? null
                      : () => setState(_cursors.removeLast),
                  child: const Text('Previous page'),
                ),
                TextButton(
                  onPressed:
                      _busy ||
                          value.isLoading ||
                          page == null ||
                          page.nextCursor.isEmpty
                      ? null
                      : () => setState(() => _cursors.add(page.nextCursor)),
                  child: const Text('Next page'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _jumpToStreamId() => _perform(() async {
    final values = await keyInputs(context, 'Start stream page at ID', [
      input('Entry ID'),
    ]);
    if (values == null || !mounted) return;
    final id = values.single.trim();
    if (id.isNotEmpty && !RegExp(r'^\d+-\d+$').hasMatch(id)) {
      throw const FormatException('Enter an entry ID such as 1700000000000-0.');
    }
    setState(() => _cursors.replaceRange(0, _cursors.length, [id]));
  });
}

String _jsonRoot(String json) {
  final Object? parsed = jsonDecode(json);
  final root = parsed is List<Object?> && parsed.length == 1
      ? parsed.single
      : parsed;
  return const JsonEncoder.withIndent('  ').convert(root);
}

WriteOp _zadd(List<int> member, String text) {
  final score = double.tryParse(text);
  if (score == null || score.isNaN) {
    throw const FormatException('Enter a valid score.');
  }
  return WriteOp(
    zsetAdd: WriteOp_ZsetAdd(
      entries: [ZsetEntry(member: member, score: score)],
    ),
  );
}

List<HashEntry> _streamFields(String text) {
  final Object? parsed = jsonDecode(text);
  if (parsed is! Map<String, Object?> ||
      parsed.isEmpty ||
      parsed.values.any((value) => value is! String)) {
    throw const FormatException(
      'Enter a JSON object with at least one string value.',
    );
  }
  return [
    for (final entry in parsed.entries)
      HashEntry(
        field_1: utf8.encode(entry.key),
        value: utf8.encode(entry.value as String),
      ),
  ];
}
