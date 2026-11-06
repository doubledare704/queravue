import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/table_models.dart';

/// Builds a deterministic string key from primary key column values.
String makePkKey(Map<String, Object?> pkValues) {
  final keys = pkValues.keys.toList()..sort();
  return keys.map((k) => '$k=${pkValues[k]}').join('&');
}

/// State of pending changes for a single table view tab.
@immutable
class PendingChangesState {
  const PendingChangesState({
    this.updates = const {},
    this.deletes = const {},
    this.inserts = const {},
  });

  /// Map of pkKey -> (pkMap, map of updated column -> new value).
  final Map<String, (Map<String, Object?>, Map<String, Object?>)> updates;

  /// Map of pkKey -> pkMap for rows marked for deletion.
  final Map<String, Map<String, Object?>> deletes;

  /// Map of syntheticId -> map of column -> value for new rows.
  final Map<String, Map<String, Object?>> inserts;

  bool get isEmpty => updates.isEmpty && deletes.isEmpty && inserts.isEmpty;
  bool get hasChanges => !isEmpty;
  int get changeCount => updates.length + deletes.length + inserts.length;

  bool isUpdated(String pkKey) => updates.containsKey(pkKey);
  bool isDeleted(String pkKey) => deletes.containsKey(pkKey);

  Object? getUpdatedValue(String pkKey, String column) {
    final entry = updates[pkKey];
    if (entry != null && entry.$2.containsKey(column)) {
      return entry.$2[column];
    }
    return null;
  }

  bool hasUpdatedValue(String pkKey, String column) {
    final entry = updates[pkKey];
    return entry != null && entry.$2.containsKey(column);
  }

  PendingChangesState copyWith({
    Map<String, (Map<String, Object?>, Map<String, Object?>)>? updates,
    Map<String, Map<String, Object?>>? deletes,
    Map<String, Map<String, Object?>>? inserts,
  }) => PendingChangesState(
    updates: updates ?? this.updates,
    deletes: deletes ?? this.deletes,
    inserts: inserts ?? this.inserts,
  );
}

final pendingChangesProvider =
    NotifierProvider.family<
      PendingChangesController,
      PendingChangesState,
      String
    >(PendingChangesController.new);

class PendingChangesController extends Notifier<PendingChangesState> {
  PendingChangesController(this.tableKey);

  final String tableKey;
  int _insertSeq = 0;

  @override
  PendingChangesState build() {
    return const PendingChangesState();
  }

  /// Records a cell update for row identified by [pkValues].
  void updateCell({
    required Map<String, Object?> pkValues,
    required String column,
    required Object? newValue,
  }) {
    final pkKey = makePkKey(pkValues);
    final currentUpdates =
        Map<String, (Map<String, Object?>, Map<String, Object?>)>.from(
          state.updates,
        );

    final existing = currentUpdates[pkKey];
    final updatedCols = Map<String, Object?>.from(existing?.$2 ?? {});
    updatedCols[column] = newValue;

    currentUpdates[pkKey] = (pkValues, updatedCols);
    state = state.copyWith(updates: currentUpdates);
  }

  /// Marks row identified by [pkValues] for deletion.
  void deleteRow(Map<String, Object?> pkValues) {
    final pkKey = makePkKey(pkValues);
    final deletes = Map<String, Map<String, Object?>>.from(state.deletes);
    final updates =
        Map<String, (Map<String, Object?>, Map<String, Object?>)>.from(
          state.updates,
        );

    if (deletes.containsKey(pkKey)) {
      deletes.remove(pkKey); // Undelete / toggle
    } else {
      deletes[pkKey] = pkValues;
      updates.remove(pkKey); // Remove updates if row is deleted
    }

    state = state.copyWith(deletes: deletes, updates: updates);
  }

  /// Adds a new pending insert row.
  String addRow([Map<String, Object?> initialValues = const {}]) {
    final tempId = 'new_${++_insertSeq}';
    final inserts = Map<String, Map<String, Object?>>.from(state.inserts);
    inserts[tempId] = Map<String, Object?>.from(initialValues);
    state = state.copyWith(inserts: inserts);
    return tempId;
  }

  /// Updates a cell in a newly inserted row.
  void updateNewRowCell(String tempId, String column, Object? value) {
    final inserts = Map<String, Map<String, Object?>>.from(state.inserts);
    final row = Map<String, Object?>.from(inserts[tempId] ?? {});
    row[column] = value;
    inserts[tempId] = row;
    state = state.copyWith(inserts: inserts);
  }

  /// Removes a pending inserted row.
  void removeNewRow(String tempId) {
    final inserts = Map<String, Map<String, Object?>>.from(state.inserts);
    inserts.remove(tempId);
    state = state.copyWith(inserts: inserts);
  }

  /// Discards all pending changes.
  void discard() {
    state = const PendingChangesState();
  }

  /// Builds list of [RowChange] objects for ApplyChanges.
  List<RowChange> toRowChanges() {
    final changes = <RowChange>[];

    // 1. Inserts
    for (final entry in state.inserts.entries) {
      if (entry.value.isNotEmpty) {
        changes.add(RowChange(type: RowChangeType.insert, values: entry.value));
      }
    }

    // 2. Updates
    for (final entry in state.updates.values) {
      changes.add(
        RowChange(type: RowChangeType.update, keys: entry.$1, values: entry.$2),
      );
    }

    // 3. Deletes
    for (final pkMap in state.deletes.values) {
      changes.add(RowChange(type: RowChangeType.delete, keys: pkMap));
    }

    return changes;
  }
}
