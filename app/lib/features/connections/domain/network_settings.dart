enum SshAuth { password, keyFile, agent }

enum TlsMode { engineDefault, disable, prefer, require, verifyCa, verifyFull }

typedef SshEndpoint = ({
  String host,
  int port,
  String user,
  SshAuth auth,
  String keyFile,
  bool hasPassword,
  bool hasPassphrase,
});

typedef SshSettings = ({
  SshEndpoint bastion,
  SshEndpoint? jump,
  int keepaliveSeconds,
  int timeoutSeconds,
});

typedef TlsSettings = ({
  TlsMode mode,
  String caFile,
  String certFile,
  String keyFile,
  String serverName,
  bool hasPassphrase,
});

class NetworkSecrets {
  const NetworkSecrets({
    this.sshPassword,
    this.sshPassphrase,
    this.jumpPassword,
    this.jumpPassphrase,
    this.tlsPassphrase,
  });

  final String? sshPassword;
  final String? sshPassphrase;
  final String? jumpPassword;
  final String? jumpPassphrase;
  final String? tlsPassphrase;
}

typedef SshHostKey = ({
  String host,
  int port,
  String presented,
  String trusted,
});

enum ConnectionTestStage { ssh, tls, auth, ping }

typedef ConnectionTestStep = ({
  ConnectionTestStage stage,
  bool ok,
  int elapsedMs,
  String message,
});
