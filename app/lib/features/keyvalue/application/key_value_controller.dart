import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/gen/queravue/v1/keyvalue.pb.dart';
import '../data/key_value_repository.dart';
import '../domain/key_value_text.dart';
import 'key_scan_controller.dart';

typedef ValueScope = ({
  KeyAddress key,
  String cursor,
  bool reverse,
  bool scoreOrder,
});

final keyValueProvider = FutureProvider.autoDispose
    .family<ReadValueResponse, ValueScope>((ref, scope) {
      final key = scope.key;
      return ref
          .watch(keyValueRepositoryProvider)
          .read(
            ReadValueRequest(
              sessionId: key.session,
              database: key.database,
              key: keyBytes(key.identity),
              cursor: scope.cursor,
              reverse: scope.reverse,
              orderByScore: scope.scoreOrder,
              pageSize: 100,
            ),
          );
    });

typedef ConfirmOperation = Future<bool> Function(String operation);

Future<T?> withKeyValueConfirmation<T>(
  Future<T> Function(bool confirmed) request,
  ConfirmOperation confirm,
) async {
  try {
    return await request(false);
  } on KeyValueFailure catch (error) {
    if (!error.needsConfirmation) rethrow;
    if (!await confirm(error.error.operation)) return null;
    return request(true);
  }
}
