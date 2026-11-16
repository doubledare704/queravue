import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/connection_form_controller.dart';
import '../domain/network_settings.dart';
import 'connection_actions.dart';

class ConnectionNetworkFields extends ConsumerWidget {
  const ConnectionNetworkFields({super.key, required this.args});

  final ConnectionFormArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionFormProvider(args));
    final controller = ref.read(connectionFormProvider(args).notifier);
    final values = state.network;
    final initial = args.isEdit ? args.initial : null;
    final mode = TlsMode.values.byName(values['tls.mode'] ?? 'engineDefault');
    final useSsh = values['ssh.enabled'] == 'true';
    final useJump = values['jump.enabled'] == 'true';

    Widget toggle(String key, String label, bool value) => SwitchListTile(
      key: Key(key),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (v) => controller.setNetworkField(key, '$v'),
    );

    Widget field(
      String key,
      String label, {
      String? hint,
      bool file = false,
      bool secret = false,
      bool numeric = false,
    }) => _NetworkField(
      key: Key(key),
      value: values[key] ?? '',
      label: label,
      hint: hint,
      file: file,
      secret: secret,
      numeric: numeric,
      onChanged: (v) => controller.setNetworkField(key, v),
    );

    List<Widget> endpoint(String prefix, SshEndpoint? stored) {
      final auth = SshAuth.values.byName(values['$prefix.auth'] ?? 'password');
      return [
        field('$prefix.host', 'Host'),
        field('$prefix.port', 'Port', hint: '22', numeric: true),
        field('$prefix.user', 'User'),
        DropdownButtonFormField<SshAuth>(
          key: Key('$prefix.auth'),
          initialValue: auth,
          decoration: const InputDecoration(labelText: 'Authentication'),
          items: const [
            DropdownMenuItem(value: SshAuth.password, child: Text('Password')),
            DropdownMenuItem(
              value: SshAuth.keyFile,
              child: Text('Private key'),
            ),
            DropdownMenuItem(
              value: SshAuth.agent,
              child: Text('Use SSH agent'),
            ),
          ],
          onChanged: (v) => controller.setNetworkField('$prefix.auth', v!.name),
        ),
        if (auth == SshAuth.password)
          field(
            '$prefix.password',
            'SSH password',
            secret: true,
            hint: stored?.hasPassword == true ? 'Stored in keychain' : null,
          ),
        if (auth == SshAuth.keyFile) ...[
          field('$prefix.key', 'Private key file', file: true),
          field(
            '$prefix.passphrase',
            'Key passphrase',
            secret: true,
            hint: stored?.hasPassphrase == true ? 'Stored in keychain' : null,
          ),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.engine.supportsSsh)
          ExpansionTile(
            key: const Key('ssh-settings'),
            initiallyExpanded: args.initial?.ssh != null,
            title: const Text('SSH'),
            children: [
              toggle('ssh.enabled', 'Use SSH tunnel', useSsh),
              if (useSsh) ...[
                ...endpoint('ssh', initial?.ssh?.bastion),
                field(
                  'ssh.keepalive',
                  'Keep-alive (seconds)',
                  hint: '30',
                  numeric: true,
                ),
                field(
                  'ssh.timeout',
                  'Connect timeout (seconds)',
                  hint: '10',
                  numeric: true,
                ),
                toggle('jump.enabled', 'Use jump host', useJump),
                if (useJump) ...endpoint('jump', initial?.ssh?.jump),
              ],
            ],
          ),
        if (state.engine.supportsTls)
          ExpansionTile(
            key: const Key('tls-settings'),
            initiallyExpanded: args.initial?.tls != null,
            title: const Text('TLS'),
            children: [
              DropdownButtonFormField<TlsMode>(
                key: ValueKey(('tls.mode', state.revision)),
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(
                    value: TlsMode.engineDefault,
                    child: Text('Engine default'),
                  ),
                  DropdownMenuItem(
                    value: TlsMode.disable,
                    child: Text('Disable'),
                  ),
                  DropdownMenuItem(
                    value: TlsMode.prefer,
                    child: Text('Prefer'),
                  ),
                  DropdownMenuItem(
                    value: TlsMode.require,
                    child: Text('Require'),
                  ),
                  DropdownMenuItem(
                    value: TlsMode.verifyCa,
                    child: Text('Verify CA'),
                  ),
                  DropdownMenuItem(
                    value: TlsMode.verifyFull,
                    child: Text('Verify full'),
                  ),
                ],
                onChanged: (v) =>
                    controller.setNetworkField('tls.mode', v!.name),
              ),
              if (mode != TlsMode.engineDefault && mode != TlsMode.disable) ...[
                field('tls.ca', 'CA bundle', file: true),
                field('tls.cert', 'Client certificate', file: true),
                field('tls.key', 'Client private key', file: true),
                if (values['tls.key']?.isNotEmpty == true)
                  field(
                    'tls.passphrase',
                    'Client key passphrase',
                    secret: true,
                    hint: initial?.tls?.hasPassphrase == true
                        ? 'Stored in keychain'
                        : null,
                  ),
                field('tls.server', 'Server name override'),
              ],
            ],
          ),
      ],
    );
  }
}

class _NetworkField extends ConsumerStatefulWidget {
  const _NetworkField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.hint,
    required this.file,
    required this.secret,
    required this.numeric,
  });

  final String value;
  final String label;
  final String? hint;
  final bool file;
  final bool secret;
  final bool numeric;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<_NetworkField> createState() => _NetworkFieldState();
}

class _NetworkFieldState extends ConsumerState<_NetworkField> {
  late final _text = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_NetworkField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.value) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: _text,
      obscureText: widget.secret,
      autocorrect: !widget.secret,
      enableSuggestions: !widget.secret,
      keyboardType: widget.numeric ? TextInputType.number : null,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: widget.file
            ? IconButton(
                tooltip: 'Browse for ${widget.label}',
                icon: const Icon(Icons.folder_open),
                onPressed: () async {
                  final path = await ref.read(filePickerProvider)();
                  if (path != null && mounted) widget.onChanged(path);
                },
              )
            : null,
      ),
      onChanged: widget.onChanged,
    ),
  );
}
