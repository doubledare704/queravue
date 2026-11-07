import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_controllers.dart';
import '../domain/admin_models.dart';
import 'admin_widgets.dart';

String prettyValidator(String canonical) {
  if (canonical.trim().isEmpty) return '';
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(canonical));
  } on FormatException {
    return canonical;
  }
}

class ValidationPanel extends ConsumerStatefulWidget {
  const ValidationPanel({super.key, required this.target});

  final AdminTarget target;

  @override
  ConsumerState<ValidationPanel> createState() => _ValidationPanelState();
}

class _ValidationPanelState extends ConsumerState<ValidationPanel> {
  final _text = TextEditingController();
  String _level = '';
  String _action = '';
  bool _loaded = false;
  bool _busy = false;
  String? _command;
  String? _starterNote;
  AdminError? _error;

  ValidationController get _controller =>
      ref.read(validationProvider(widget.target).notifier);

  ValidationModel get _rule => ValidationModel(
    validator: _text.text.trim(),
    level: _level,
    action: _action,
  );

  void _adopt(ValidationModel model) {
    _text.text = prettyValidator(model.validator);
    _level = model.level;
    _action = model.action;
    _loaded = true;
    _command = null;
    _error = null;
    _starterNote = null;
  }

  Future<void> _useSample() async {
    if (_text.text.trim().isNotEmpty && !await _confirmReplace()) return;
    setState(() => _busy = true);
    final result = await _controller.starterFromSample();
    if (!mounted) return;
    final starter = result.value;
    setState(() {
      _busy = false;
      _error = result.error;
      if (starter == null) return;
      if (starter.sampled == 0) {
        _error = const AdminError(
          kind: AdminErrorKind.invalid,
          message: 'The collection has no documents to learn from.',
        );
        return;
      }
      _text.text = starter.text;
      _command = null;
      _starterNote =
          'Inferred from ${starter.sampled} sampled documents'
          '${starter.usedFallback ? ' (the first ones, not a random sample)' : ''}. '
          'Review it before applying: it is not applied automatically.';
    });
  }

  Future<bool> _confirmReplace() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace the editor text?'),
        content: const Text(
          'The text in the editor is replaced by a schema inferred from the collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('validation-starter-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    final result = await _controller.preview(_rule);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _command = result.value;
      _error = result.error;
    });
  }

  Future<void> _apply() async {
    final production = ref.read(
      adminIsProductionProvider(widget.target.connectionId),
    );
    if (production && !await _confirmProduction()) return;
    setState(() => _busy = true);
    final result = await _controller.apply(_rule, confirmed: production);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.error;
      _command = result.value;
    });
  }

  Future<bool> _confirmProduction() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change validator on production?'),
        content: const Text(
          'This connection is flagged as production. Writes that fail the new validator may be rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('validation-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final load = ref.watch(validationProvider(widget.target));
    ref.watch(adminIsProductionProvider(widget.target.connectionId));
    final scheme = Theme.of(context).colorScheme;
    if (load.error != null && !_loaded) {
      return AdminErrorView(error: load.error!, onRetry: _controller.reload);
    }
    final model = load.value;
    if (model == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_loaded) _adopt(model);
    ref.listen(validationProvider(widget.target), (_, next) {
      final fresh = next.value;
      if (fresh != null && !next.loading) setState(() => _adopt(fresh));
    });

    final position = _error?.position;
    final where = position == null
        ? ''
        : () {
            final p = lineAndColumn(_text.text, position);
            return 'Line ${p.line}, column ${p.column}: ';
          }();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Level'),
                    DropdownButton<String>(
                      key: const Key('validation-level'),
                      value: _level,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('default')),
                        DropdownMenuItem(value: 'off', child: Text('off')),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'strict',
                          child: Text('strict'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _level = v ?? ''),
                    ),
                    const SizedBox(width: 16),
                    const Text('Action'),
                    DropdownButton<String>(
                      key: const Key('validation-action'),
                      value: _action,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('default')),
                        DropdownMenuItem(value: 'error', child: Text('error')),
                        DropdownMenuItem(value: 'warn', child: Text('warn')),
                      ],
                      onChanged: (v) => setState(() => _action = v ?? ''),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      key: const Key('validation-starter'),
                      onPressed: _busy ? null : _useSample,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Start from sample'),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('validation-reload'),
                tooltip: 'Reload from server',
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _busy ? null : _controller.reload,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              key: const Key('validation-text'),
              controller: _text,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              onChanged: (_) => setState(() {
                _command = null;
                _error = null;
              }),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    '{"\$jsonSchema": {...}}  (empty removes the validator)',
              ),
            ),
          ),
          if (_starterNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _starterNote!,
                key: const Key('validation-starter-note'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$where${_error!.message}',
                key: const Key('validation-error'),
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ),
          if (_command != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StatementBox(statement: _command!),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                key: const Key('validation-preview'),
                onPressed: _busy ? null : _preview,
                child: const Text('Preview command'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('validation-apply'),
                onPressed: _busy ? null : _apply,
                child: Text(_text.text.trim().isEmpty ? 'Remove' : 'Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
