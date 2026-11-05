import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/history.pbgrpc.dart' as pb;
import '../domain/history_models.dart';

abstract interface class HistoryRepository {
  Future<HistoryPage> listHistory({
    String? connectionId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });

  Future<void> clearHistory([String? connectionId]);
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcHistoryRepository(() => supervisor.connection);
});

class GrpcHistoryRepository implements HistoryRepository {
  GrpcHistoryRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _timeout = Duration(seconds: 10);

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  @override
  Future<HistoryPage> listHistory({
    String? connectionId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _conn.historyService.listHistory(
      pb.ListHistoryRequest(
        connectionId: connectionId ?? '',
        searchQuery: searchQuery ?? '',
        limit: limit,
        offset: offset,
      ),
      options: CallOptions(timeout: _timeout),
    );

    final items = resp.entries.map((e) {
      final startedAt = e.startedAt.toDateTime();
      final duration = Duration(
        microseconds:
            e.duration.seconds.toInt() * 1000000 + e.duration.nanos ~/ 1000,
      );
      return HistoryItem(
        id: e.id.toInt(),
        connectionId: e.connectionId,
        queryText: e.queryText,
        startedAt: startedAt,
        duration: duration,
        rowsAffected: e.rowsAffected.toInt(),
        error: e.error.isNotEmpty ? e.error : null,
      );
    }).toList();

    return HistoryPage(items: items, totalCount: resp.totalCount.toInt());
  }

  @override
  Future<void> clearHistory([String? connectionId]) async {
    await _conn.historyService.clearHistory(
      pb.ClearHistoryRequest(connectionId: connectionId ?? ''),
      options: CallOptions(timeout: _timeout),
    );
  }
}
