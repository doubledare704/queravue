import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/connection_form_controller.dart';
import '../domain/models.dart';
import 'connection_actions.dart';

/// New / edit / duplicate connection dialog. The form is built entirely from
/// the engine's [FieldSpec]s.
class ConnectionDialog extends ConsumerStatefulWidget {
  const ConnectionDialog({super.key, required this.args});

  final ConnectionFormArgs args;

  @override
  ConsumerState<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends ConsumerState<ConnectionDialog> {
  final _fields = <String, TextEditingController>{};
  late final TextEditingController _name;
  late final TextEditingController _folder;
  final _password = TextEditingController();
  final _uri = TextEditingController();
  int _revision = -1;

  NotifierProvider<ConnectionFormController, ConnectionFormState>
  get _provider => connectionFormProvider(widget.args);

  ConnectionFormController get _ctrl => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    final s = ref.read(_provider);
    _name = TextEditingController(text: s.name);
    _folder = TextEditingController(text: s.folder);
    _sync(s);
  }

  /// Copies values set by the controller (engine switch, URI import) into
  /// the text fields.
  void _sync(ConnectionFormState s) {
    if (s.revision == _revision) return;
    _revision = s.revision;
    for (final f in s.engine.paramFields) {
      final c = _fields.putIfAbsent(f.key, TextEditingController.new);
      final v = s.values[f.key] ?? '';
      if (c.text != v) c.text = v;
    }
    if (s.passwordDirty && _password.text != s.password) {
      _password.text = s.password;
    }
  }

  @override
  void dispose() {
    for (final c in [..._fields.values, _name, _folder, _password, _uri]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _ctrl.save();
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _applyUri() async {
    await _ctrl.applyUri(_uri.text);
    if (ref.read(_provider).error == null) _uri.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_provider);
    ref.listen(_provider, (_, next) => _sync(next));
    final title = widget.args.isEdit
        ? 'Edit connection'
        : widget.args.duplicate
        ? 'Duplicate connection'
        : 'New connection';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
      },
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _engineSelector(s),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('field-name'),
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: _ctrl.setName,
                ),
                const SizedBox(height: 12),
                if (s.engine.supportsUri) ...[
                  _uriRow(s),
                  const SizedBox(height: 12),
                ],
                for (final f in s.engine.fields) ...[
                  _field(s, f),
                  const SizedBox(height: 12),
                ],
                _organizeRow(s),
                const SizedBox(height: 12),
                _testRow(s),
                if (s.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.error!,
                    key: const Key('form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-connection'),
            onPressed: s.saving ? null : _save,
            child: Text(s.saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _engineSelector(ConnectionFormState s) {
    return DropdownButtonFormField<String>(
      key: const Key('field-engine'),
      initialValue: s.engine.id,
      decoration: const InputDecoration(labelText: 'Engine'),
      items: [
        for (final e in widget.args.engines)
          DropdownMenuItem(value: e.id, child: Text(e.displayName)),
      ],
      onChanged: widget.args.isEdit
          ? null
          : (id) {
              if (id != null) _ctrl.selectEngine(id);
            },
    );
  }

  Widget _uriRow(ConnectionFormState s) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('field-uri'),
            controller: _uri,
            decoration: InputDecoration(
              labelText: 'Paste connection URI (optional)',
              hintText: s.engine.uriExample,
            ),
            onSubmitted: (_) => _applyUri(),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          key: const Key('apply-uri'),
          onPressed: _applyUri,
          child: const Text('Fill'),
        ),
      ],
    );
  }

  Widget _field(ConnectionFormState s, FieldSpec f) {
    final key = Key('field-${f.key}');
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.kind) {
      case FieldKind.password:
        return Row(
          children: [
            Expanded(
              child: TextField(
                key: key,
                controller: _password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: s.hasStoredPassword && !s.clearStoredPassword
                      ? 'Saved in keychain — leave empty to keep'
                      : null,
                ),
                onChanged: _ctrl.setPassword,
              ),
            ),
            if (s.hasStoredPassword && !s.clearStoredPassword)
              TextButton(
                key: const Key('clear-stored-password'),
                onPressed: () {
                  _password.clear();
                  _ctrl.clearStoredPassword();
                },
                child: const Text('Forget'),
              ),
          ],
        );
      case FieldKind.boolean:
        return CheckboxListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(f.label),
          value: s.values[f.key] == 'true',
          onChanged: (v) => _ctrl.setField(f.key, (v ?? false).toString()),
        );
      case FieldKind.select:
        final v = s.values[f.key];
        return DropdownButtonFormField<String>(
          key: ValueKey('${f.key}-${s.revision}'),
          initialValue: f.options.contains(v) ? v : null,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in f.options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (o) {
            if (o != null) _ctrl.setField(f.key, o);
          },
        );
      case FieldKind.file:
        return Row(
          children: [
            Expanded(child: _textField(f, key, label)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: Key('browse-${f.key}'),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Browse…'),
              onPressed: () async {
                final path = await ref.read(filePickerProvider)();
                if (path == null) return;
                _fields[f.key]!.text = path;
                _ctrl.setField(f.key, path);
              },
            ),
          ],
        );
      case FieldKind.integer:
      case FieldKind.text:
        return _textField(f, key, label);
    }
  }

  Widget _textField(FieldSpec f, Key key, String label) => TextField(
    key: key,
    controller: _fields.putIfAbsent(f.key, TextEditingController.new),
    keyboardType: f.kind == FieldKind.integer ? TextInputType.number : null,
    inputFormatters: f.kind == FieldKind.integer
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: f.placeholder.isEmpty ? null : f.placeholder,
    ),
    onChanged: (v) => _ctrl.setField(f.key, v),
  );

  Widget _organizeRow(ConnectionFormState s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            key: const Key('field-folder'),
            controller: _folder,
            decoration: const InputDecoration(
              labelText: 'Folder',
              hintText: 'e.g. Work/Clients',
            ),
            onChanged: _ctrl.setFolder,
          ),
        ),
        const SizedBox(width: 12),
        _ColorPicker(value: s.color, onChanged: _ctrl.setColor),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Production connections get extra safety prompts',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                key: const Key('field-production'),
                value: s.production,
                onChanged: _ctrl.setProduction,
              ),
              const Text('Production'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _testRow(ConnectionFormState s) {
    final scheme = Theme.of(context).colorScheme;
    final Widget status = switch (s.test) {
      FormTestIdle() => const SizedBox.shrink(),
      FormTesting() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Testing…'),
        ],
      ),
      FormTested(result: final TestPassed ok) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Text(ok.summary, key: const Key('test-result')),
        ],
      ),
      FormTested(result: final TestFailed err) => Flexible(
        child: Row(
          children: [
            Icon(Icons.error, color: scheme.error, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Tooltip(
                message: err.message,
                child: Text(
                  '${err.headline}: ${err.message}',
                  key: const Key('test-result'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    };
    final testing = s.test is FormTesting;
    return Row(
      children: [
        OutlinedButton.icon(
          key: const Key('test-connection'),
          icon: Icon(testing ? Icons.close : Icons.bolt, size: 18),
          label: Text(testing ? 'Cancel test' : 'Test'),
          onPressed: testing ? _ctrl.cancelTest : _ctrl.test,
        ),
        const SizedBox(width: 12),
        status,
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.value, required this.onChanged});

  final ColorTag value;
  final ValueChanged<ColorTag> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ColorTag>(
      key: const Key('field-color'),
      tooltip: 'Color tag',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final t in ColorTag.values)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                _Dot(color: colorTagColor(t)),
                const SizedBox(width: 8),
                Text(t == ColorTag.none ? 'No color' : t.name),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _Dot(color: colorTagColor(value), size: 16),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 12});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: color == null
            ? Border.all(color: Theme.of(context).colorScheme.outline)
            : null,
      ),
    );
  }
}
