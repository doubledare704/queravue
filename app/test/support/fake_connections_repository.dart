import 'dart:async';

import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/cancellation.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/connections/domain/network_settings.dart';

const pgEngine = EngineSpec(
  id: 'postgres',
  displayName: 'PostgreSQL',
  family: 'postgres',
  supportsUri: true,
  uriExample: 'postgres://user@localhost:5432/postgres',
  capabilities: {'connect'},
  fields: [
    FieldSpec(
      key: 'host',
      label: 'Host',
      required: true,
      defaultValue: 'localhost',
    ),
    FieldSpec(
      key: 'port',
      label: 'Port',
      kind: FieldKind.integer,
      required: true,
      defaultValue: '5432',
    ),
    FieldSpec(key: 'database', label: 'Database', defaultValue: 'postgres'),
    FieldSpec(key: 'user', label: 'User'),
    FieldSpec(key: 'password', label: 'Password', kind: FieldKind.password),
    FieldSpec(
      key: 'sslmode',
      label: 'SSL mode',
      kind: FieldKind.select,
      defaultValue: 'prefer',
      options: ['disable', 'prefer', 'require'],
    ),
  ],
);

const sqliteEngine = EngineSpec(
  id: 'sqlite',
  displayName: 'SQLite',
  family: 'sqlite',
  supportsUri: true,
  capabilities: {'connect'},
  fields: [
    FieldSpec(
      key: 'path',
      label: 'Database file',
      kind: FieldKind.file,
      required: true,
    ),
    FieldSpec(
      key: 'read_only',
      label: 'Read-only',
      kind: FieldKind.boolean,
      defaultValue: 'false',
    ),
  ],
);

/// A recorded test() call.
typedef TestCall = ({String? id, ConnectionProfile? draft, String? password});

/// In-memory repository. Passwords are kept apart from profiles, like the
/// real keychain.
class FakeConnectionsRepository implements ConnectionsRepository {
  FakeConnectionsRepository({List<ConnectionProfile> initial = const []}) {
    for (final c in initial) {
      _items[c.id] = c;
    }
  }

  final _items = <String, ConnectionProfile>{};
  final passwords = <String, String>{};
  final testCalls = <TestCall>[];
  NetworkSecrets? lastTestSecrets;
  NetworkSecrets? lastSavedSecrets;
  var _next = 1;

  List<EngineSpec> engines = [pgEngine, sqliteEngine];
  final queuedResults = <TestResult>[];
  TestResult nextResult = const TestPassed(
    product: 'PostgreSQL',
    version: '17.11',
    connectMs: 4,
    latencyMs: 1,
  );

  /// When set, test() waits for it (to observe the "testing" state).
  Completer<void>? testGate;
  ConnectionsException? failNextSave;

  List<ConnectionProfile> get items => _items.values.toList();

  @override
  Future<List<EngineSpec>> listEngines() async => engines;

  @override
  Future<List<ConnectionProfile>> list() async => items;

  @override
  Future<ConnectionProfile> create(
    ConnectionProfile draft, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
  }) async {
    if (failNextSave case final e?) {
      failNextSave = null;
      throw e;
    }
    lastSavedSecrets = secrets;
    final id = 'c${_next++}';
    if (password != null && password.isNotEmpty) passwords[id] = password;
    return _items[id] = draft.copyWith(
      id: id,
      hasPassword: passwords.containsKey(id),
    );
  }

  @override
  Future<ConnectionProfile> update(
    ConnectionProfile profile, {
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    bool clearPassword = false,
  }) async {
    if (!_items.containsKey(profile.id)) {
      throw const ConnectionsException('connection not found');
    }
    if (password != null && password.isNotEmpty) {
      passwords[profile.id] = password;
    } else if (clearPassword) {
      passwords.remove(profile.id);
    }
    return _items[profile.id] = profile.copyWith(
      hasPassword: passwords.containsKey(profile.id),
    );
  }

  final trustedKeys = <SshHostKey>[];

  @override
  Future<void> trustHostKey(SshHostKey key) async => trustedKeys.add(key);

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    passwords.remove(id);
  }

  @override
  Future<TestResult> test({
    String? id,
    ConnectionProfile? draft,
    String? password,
    NetworkSecrets secrets = const NetworkSecrets(),
    Duration? timeout,
    CancellationToken? cancel,
  }) async {
    lastTestSecrets = secrets;
    testCalls.add((id: id, draft: draft, password: password));
    if (testGate case final gate?) {
      await Future.any([gate.future, ?cancel?.whenCancelled]);
      if (cancel?.isCancelled ?? false) throw const OperationCancelled();
    }
    return queuedResults.isEmpty ? nextResult : queuedResults.removeAt(0);
  }

  @override
  Future<({Map<String, String> params, String? password})> parseUri(
    String engineId,
    String uri,
  ) async {
    if (!uri.startsWith('postgres://')) {
      throw const ConnectionsException('unsupported scheme');
    }
    final u = Uri.parse(uri);
    final userInfo = u.userInfo.split(':');
    return (
      params: {
        'host': u.host,
        if (u.hasPort) 'port': '${u.port}',
        if (userInfo.first.isNotEmpty) 'user': userInfo.first,
        if (u.path.length > 1) 'database': u.path.substring(1),
      },
      password: userInfo.length > 1 ? userInfo[1] : null,
    );
  }
}
