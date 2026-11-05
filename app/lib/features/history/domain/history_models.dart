import 'package:flutter/foundation.dart';

/// Single query execution record in history.
@immutable
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.connectionId,
    required this.queryText,
    required this.startedAt,
    required this.duration,
    required this.rowsAffected,
    this.error,
  });

  final int id;
  final String connectionId;
  final String queryText;
  final DateTime startedAt;
  final Duration duration;
  final int rowsAffected;
  final String? error;

  bool get isSuccess => error == null || error!.isEmpty;
}

/// Paginated list of history items.
@immutable
class HistoryPage {
  const HistoryPage({required this.items, required this.totalCount});

  final List<HistoryItem> items;
  final int totalCount;
}
