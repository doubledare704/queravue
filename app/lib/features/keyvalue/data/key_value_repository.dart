import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/keyvalue.pbgrpc.dart';

final keyValueRepositoryProvider = Provider<KeyValueRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  CoreConnection connected() {
    final connection = supervisor.connection;
    if (connection == null) throw StateError('Core is not connected');
    return connection;
  }

  return KeyValueRepository(
    () => connected().keyValueService,
    scanKeys: (request) => connected().scanKeyValues(request),
  );
});

class KeyValueFailure implements Exception {
  const KeyValueFailure(this.error);

  final KeyValueError error;

  bool get needsConfirmation =>
      error.kind ==
      KeyValueErrorKind.KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED;

  @override
  String toString() => error.message.isEmpty ? error.kind.name : error.message;
}

class KeyValueRepository {
  KeyValueRepository(this._client, {this.scanKeys});

  final KeyValueServiceClient Function() _client;
  final Stream<ScanKeysResponse> Function(ScanKeysRequest)? scanKeys;

  static final _deadline = CallOptions(timeout: const Duration(seconds: 10));

  Future<ListKvDatabasesResponse> databases(String session) async {
    final response = await _client().listKvDatabases(
      ListKvDatabasesRequest(sessionId: session),
      options: _deadline,
    );
    return _checked(response, response.hasError(), response.error);
  }

  Stream<ScanKeysResponse> scan(ScanKeysRequest request) =>
      (scanKeys?.call(request) ?? _client().scanKeys(request)).map(
        (response) => _checked(response, response.hasError(), response.error),
      );

  Future<GetKeyInfoResponse> info(GetKeyInfoRequest request) async {
    final response = await _client().getKeyInfo(request, options: _deadline);
    return _checked(response, response.hasError(), response.error);
  }

  Future<ReadValueResponse> read(ReadValueRequest request) async {
    final response = await _client().readValue(request, options: _deadline);
    return _checked(response, response.hasError(), response.error);
  }

  Future<void> write(WriteValueRequest request) async {
    final response = await _client().writeValue(request, options: _deadline);
    _checked(response, response.hasError(), response.error);
  }

  Future<void> rename(RenameKeyRequest request) async {
    final response = await _client().renameKey(request, options: _deadline);
    _checked(response, response.hasError(), response.error);
  }

  Future<void> expiry(SetExpiryRequest request) async {
    final response = await _client().setExpiry(request, options: _deadline);
    _checked(response, response.hasError(), response.error);
  }

  Future<void> delete(DeleteKeysRequest request) async {
    final response = await _client().deleteKeys(request, options: _deadline);
    _checked(response, response.hasError(), response.error);
  }

  Future<RespValue> execute(ExecuteCommandRequest request) async {
    final response = await _client().executeCommand(
      request,
      options: _deadline,
    );
    return _checked(response.reply, response.hasError(), response.error);
  }

  Stream<SubscribeResponse> subscribe(SubscribeRequest request) => _client()
      .subscribe(request)
      .map(
        (response) => _checked(response, response.hasError(), response.error),
      );

  Future<int> publish(PublishRequest request) async {
    final response = await _client().publish(request, options: _deadline);
    return _checked(
      response,
      response.hasError(),
      response.error,
    ).receivers.toInt();
  }

  T _checked<T>(T value, bool failed, KeyValueError error) {
    if (failed) throw KeyValueFailure(error);
    return value;
  }
}
