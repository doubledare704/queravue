import '../domain/models.dart';
import '../domain/network_settings.dart';

Map<String, String> networkFormValues(ConnectionProfile profile) => {
  if (profile.ssh case final ssh?) ...{
    'ssh.enabled': 'true',
    ..._endpointValues('ssh', ssh.bastion),
    if (ssh.jump case final jump?) ...{
      'jump.enabled': 'true',
      ..._endpointValues('jump', jump),
    },
    'ssh.keepalive': _number(ssh.keepaliveSeconds),
    'ssh.timeout': _number(ssh.timeoutSeconds),
  },
  if (profile.tls case final tls?) ...{
    'tls.mode': tls.mode.name,
    'tls.ca': tls.caFile,
    'tls.cert': tls.certFile,
    'tls.key': tls.keyFile,
    'tls.server': tls.serverName,
  },
};

String _number(int n) => n == 0 ? '' : '$n';

Map<String, String> _endpointValues(String prefix, SshEndpoint endpoint) => {
  '$prefix.host': endpoint.host,
  '$prefix.port': _number(endpoint.port),
  '$prefix.user': endpoint.user,
  '$prefix.auth': endpoint.auth.name,
  '$prefix.key': endpoint.keyFile,
};

SshSettings? sshFromForm(Map<String, String> values) {
  if (values['ssh.enabled'] != 'true') return null;
  SshEndpoint endpoint(String prefix) {
    final port = _text(values, '$prefix.port');
    return (
      host: _text(values, '$prefix.host'),
      port: port.isEmpty ? 0 : int.tryParse(port) ?? -1,
      user: _text(values, '$prefix.user'),
      auth: _auth(values, prefix),
      keyFile: _auth(values, prefix) == SshAuth.keyFile
          ? _text(values, '$prefix.key')
          : '',
      hasPassword: false,
      hasPassphrase: false,
    );
  }

  return (
    bastion: endpoint('ssh'),
    jump: values['jump.enabled'] == 'true' ? endpoint('jump') : null,
    keepaliveSeconds: int.tryParse(_text(values, 'ssh.keepalive')) ?? 0,
    timeoutSeconds: int.tryParse(_text(values, 'ssh.timeout')) ?? 0,
  );
}

TlsSettings? tlsFromForm(Map<String, String> values) {
  final mode = TlsMode.values.byName(values['tls.mode'] ?? 'engineDefault');
  if (mode == TlsMode.engineDefault) return null;
  final enabled = mode != TlsMode.disable;
  return (
    mode: mode,
    caFile: enabled ? _text(values, 'tls.ca') : '',
    certFile: enabled ? _text(values, 'tls.cert') : '',
    keyFile: enabled ? _text(values, 'tls.key') : '',
    serverName: enabled ? _text(values, 'tls.server') : '',
    hasPassphrase: false,
  );
}

String _text(Map<String, String> values, String key) =>
    values[key]?.trim() ?? '';

SshAuth _auth(Map<String, String> values, String prefix) =>
    SshAuth.values.byName(values['$prefix.auth'] ?? 'password');

NetworkSecrets networkSecrets(
  Map<String, String> values,
  ConnectionProfile draft,
) => NetworkSecrets(
  sshPassword: draft.ssh?.bastion.auth == SshAuth.password
      ? values['ssh.password']
      : null,
  sshPassphrase: draft.ssh?.bastion.auth == SshAuth.keyFile
      ? values['ssh.passphrase']
      : null,
  jumpPassword: draft.ssh?.jump?.auth == SshAuth.password
      ? values['jump.password']
      : null,
  jumpPassphrase: draft.ssh?.jump?.auth == SshAuth.keyFile
      ? values['jump.passphrase']
      : null,
  tlsPassphrase: draft.tls?.keyFile.isNotEmpty == true
      ? values['tls.passphrase']
      : null,
);

bool legacyTlsField(EngineSpec engine, String key) =>
    engine.supportsTls &&
    const {
      'sslmode',
      'tls',
      'tls_ca_file',
      'tls_cert_key_file',
      'tls_insecure',
      'ssl',
      'ssl_verify',
      'encrypt',
      'trust_server_certificate',
    }.contains(key);

Map<String, String> importedTls(EngineSpec engine, Map<String, String> p) {
  if (!engine.supportsTls) return const {};
  final mode = switch (p) {
    {'sslmode': 'disable'} ||
    {'encrypt': 'disable'} ||
    {'tls': 'false'} ||
    {'tls': 'disable'} ||
    {'ssl': 'false'} => TlsMode.disable,
    {'sslmode': 'allow' || 'prefer'} ||
    {'tls': 'preferred'} ||
    {'encrypt': 'optional'} => TlsMode.prefer,
    {'sslmode': 'require'} ||
    {'tls': 'skip-verify'} ||
    {'tls': 'true', 'tls_insecure': 'true'} ||
    {'ssl': 'true', 'ssl_verify': 'false'} ||
    {
      'encrypt': 'required',
      'trust_server_certificate': 'true',
    } => TlsMode.require,
    {'sslmode': 'verify-ca'} => TlsMode.verifyCa,
    {'sslmode': 'verify-full'} ||
    {'tls': 'true' || 'verify'} ||
    {'ssl': 'true'} ||
    {'encrypt': 'required'} => TlsMode.verifyFull,
    {'encrypt': 'strict'} => TlsMode.engineDefault,
    _ => null,
  };
  if (mode == null) return const {};
  return {
    'tls.mode': mode.name,
    'tls.ca': p['tls_ca_file'] ?? '',
    'tls.cert': p['tls_cert_key_file'] ?? '',
    'tls.key': p['tls_cert_key_file'] ?? '',
  };
}
