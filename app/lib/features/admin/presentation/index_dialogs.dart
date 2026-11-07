import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../application/admin_controllers.dart';
import '../domain/admin_models.dart';
import 'admin_widgets.dart';

/// Reads "a, b desc" into index keys.
List<IndexKeyModel> parseIndexKeys(String text) {
  final keys = <IndexKeyModel>[];
  for (final part in text.split(',')) {
    final words = part.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) continue;
    final descending = words.length > 1 && words.last.toLowerCase() == 'desc';
    final name = (descending ? words.sublist(0, words.length - 1) : words).join(
      ' ',
    );
    keys.add(IndexKeyModel(name, descending: descending));
  }
  return keys;
}

Future<void> showCreateIndexDialog(
  BuildContext context, {
  required AdminTarget target,
}) => showDialog<void>(
  context: context,
  builder: (_) => _CreateIndexDialog(target: target),
);

class _CreateIndexDialog extends ConsumerStatefulWidget {
  const _CreateIndexDialog({required this.target});

  final AdminTarget target;

  @override
  ConsumerState<_CreateIndexDialog> createState() => _CreateIndexDialogState();
}

class _CreateIndexDialogState extends ConsumerState<_CreateIndexDialog> {
  final _name = TextEditingController();
  final _keys = TextEditingController();
  final _method = TextEditingController();
  final _predicate = TextEditingController();
  bool _unique = false;
  bool _online = false;
  bool _busy = false;
  IndexStatement? _preview;
  AdminError? _error;

  IndexesController get _controller =>
      ref.read(indexesProvider(widget.target).notifier);

  IndexDraft get _draft => IndexDraft(
    name: _name.text.trim(),
    keys: parseIndexKeys(_keys.text),
    unique: _unique,
    method: _method.text.trim(),
    partialPredicate: _predicate.text.trim(),
    online: _online,
  );

  void _edited() => setState(() {
    _preview = null;
    _error = null;
  });

  Future<void> _previewDraft() async {
    setState(() => _busy = true);
    final result = await _controller.preview(_draft);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _preview = result.value;
      _error = result.error;
    });
  }

  Future<void> _create(bool production) async {
    setState(() => _busy = true);
    final result = await _controller.create(_draft, confirmed: production);
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _keys.dispose();
    _method.dispose();
    _predicate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final production = ref.watch(
      adminIsProductionProvider(widget.target.connectionId),
    );
    final documentOnly = ref.watch(
      connectionIsDocumentOnlyProvider(widget.target.connectionId),
    );
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('New index'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('index-name'),
                controller: _name,
                onChanged: (_) => _edited(),
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              TextField(
                key: const Key('index-keys'),
                controller: _keys,
                onChanged: (_) => _edited(),
                decoration: const InputDecoration(
                  labelText: 'Keys',
                  hintText: 'a, b desc',
                ),
              ),
              TextField(
                key: const Key('index-method'),
                controller: _method,
                onChanged: (_) => _edited(),
                decoration: const InputDecoration(
                  labelText: 'Method (optional)',
                ),
              ),
              TextField(
                key: const Key('index-predicate'),
                controller: _predicate,
                onChanged: (_) => _edited(),
                decoration: const InputDecoration(
                  labelText: 'Partial filter (optional)',
                ),
              ),
              CheckboxListTile(
                key: const Key('index-unique'),
                contentPadding: EdgeInsets.zero,
                value: _unique,
                onChanged: (v) {
                  _unique = v ?? false;
                  _edited();
                },
                title: const Text('Unique'),
              ),
              if (!documentOnly)
                CheckboxListTile(
                  key: const Key('index-online'),
                  contentPadding: EdgeInsets.zero,
                  value: _online,
                  onChanged: (v) {
                    _online = v ?? false;
                    _edited();
                  },
                  title: const Text('Build online'),
                  subtitle: const Text(
                    'Does not block writes while the index builds, where the server supports it.',
                  ),
                ),
              if (production)
                Text(
                  'This is a production connection.',
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              if (_preview != null) ...[
                const SizedBox(height: 8),
                StatementBox(
                  statement: _preview!.statement,
                  warnings: _preview!.warnings,
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!.message,
                    key: const Key('index-error'),
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          key: const Key('index-preview'),
          onPressed: _busy || _draft.keys.isEmpty ? null : _previewDraft,
          child: const Text('Preview'),
        ),
        FilledButton(
          key: const Key('index-create'),
          onPressed: _busy || _preview == null
              ? null
              : () => _create(production),
          child: Text(production ? 'Create on production' : 'Create'),
        ),
      ],
    );
  }
}

Future<void> showDropIndexDialog(
  BuildContext context, {
  required AdminTarget target,
  required String name,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DropIndexDialog(target: target, name: name),
);

class _DropIndexDialog extends ConsumerStatefulWidget {
  const _DropIndexDialog({required this.target, required this.name});

  final AdminTarget target;
  final String name;

  @override
  ConsumerState<_DropIndexDialog> createState() => _DropIndexDialogState();
}

class _DropIndexDialogState extends ConsumerState<_DropIndexDialog> {
  late final Future<AdminResult<IndexStatement>> _preview;

  @override
  void initState() {
    super.initState();
    _preview = Future.microtask(
      () => ref
          .read(indexesProvider(widget.target).notifier)
          .previewDrop(widget.name),
    );
  }

  bool _busy = false;
  AdminError? _error;

  Future<void> _drop() async {
    setState(() => _busy = true);
    final result = await ref
        .read(indexesProvider(widget.target).notifier)
        .drop(widget.name);
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Drop index ${widget.name}?'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queries that use this index can become slow until it is rebuilt.',
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: _preview,
              builder: (context, snap) {
                final value = snap.data?.value;
                return value == null
                    ? const SizedBox.shrink()
                    : StatementBox(statement: value.statement);
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!.message,
                  key: const Key('index-error'),
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('index-drop-confirm'),
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: _busy ? null : _drop,
          child: const Text('Drop'),
        ),
      ],
    );
  }
}
