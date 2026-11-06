import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/query.pb.dart' as qpb;
import '../../../core_client/gen/queravue/v1/schema.pb.dart' as spb;
import '../../../core_client/gen/queravue/v1/table.pbgrpc.dart' as pb;
import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';
import '../../schema/domain/schema_models.dart';
import '../domain/table_models.dart';

/// One event emitted when opening a table: carries generated SQL and execution events.
class TableStreamEvent {
  const TableStreamEvent({this.sql, this.event});

  final String? sql;
  final ExecuteEvent? event;
}

abstract interface class TableRepository {
  Stream<TableStreamEvent> openTable({
    required String sessionId,
    required TableRef tableRef,
    TableFilter filter = const TableFilter(),
    List<SortClause> sort = const [],
    int pageSize = 500,
  });

  Future<ApplyChangesResult> applyChanges({
    required String sessionId,
    required TableRef tableRef,
    required List<RowChange> changes,
    bool dryRun = false,
    bool confirmProduction = false,
  });
}

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcTableRepository(() => supervisor.connection);
});

class GrpcTableRepository implements TableRepository {
  GrpcTableRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _timeout = Duration(seconds: 30);

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  @override
  Stream<TableStreamEvent> openTable({
    required String sessionId,
    required TableRef tableRef,
    TableFilter filter = const TableFilter(),
    List<SortClause> sort = const [],
    int pageSize = 500,
  }) {
    final req = pb.OpenTableRequest(
      sessionId: sessionId,
      tableRef: spb.TableRef(
        database: tableRef.database,
        schema: tableRef.schema,
        table: tableRef.table,
      ),
      filter: _filterToProto(filter),
      sort: [for (final s in sort) _sortToProto(s)],
      pageSize: Int64(pageSize),
    );

    late ResponseStream<pb.OpenTableResponse> call;
    late StreamController<TableStreamEvent> controller;
    StreamSubscription<pb.OpenTableResponse>? sub;

    controller = StreamController<TableStreamEvent>(
      onListen: () {
        try {
          call = _conn.tableService.openTable(req);
        } catch (e, st) {
          controller.addError(e, st);
          unawaited(controller.close());
          return;
        }
        sub = call.listen(
          (resp) {
            final ev = resp.hasEvent() ? eventFromProto(resp.event) : null;
            controller.add(
              TableStreamEvent(
                sql: resp.sql.isNotEmpty ? resp.sql : null,
                event: ev,
              ),
            );
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await sub?.cancel();
        await call.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<ApplyChangesResult> applyChanges({
    required String sessionId,
    required TableRef tableRef,
    required List<RowChange> changes,
    bool dryRun = false,
    bool confirmProduction = false,
  }) async {
    final req = pb.ApplyChangesRequest(
      sessionId: sessionId,
      tableRef: spb.TableRef(
        database: tableRef.database,
        schema: tableRef.schema,
        table: tableRef.table,
      ),
      changes: [for (final ch in changes) _changeToProto(ch)],
      dryRun: dryRun,
      confirmProduction: confirmProduction,
    );

    final resp = await _conn.tableService.applyChanges(
      req,
      options: CallOptions(timeout: _timeout),
    );

    return ApplyChangesResult(
      generatedSql: resp.generatedSql,
      rowsAffected: resp.rowsAffected.toInt(),
      dryRun: resp.dryRun,
      success: resp.success,
      errorMessage: resp.hasErrorMessage() ? resp.errorMessage : null,
    );
  }

  pb.TableFilter _filterToProto(TableFilter f) {
    return pb.TableFilter(root: _groupToProto(f.root), rawWhere: f.rawWhere);
  }

  pb.FilterGroup _groupToProto(FilterGroup g) {
    return pb.FilterGroup(
      op: switch (g.op) {
        LogicalOp.and => pb.LogicalOp.LOGICAL_OP_AND,
        LogicalOp.or => pb.LogicalOp.LOGICAL_OP_OR,
      },
      conditions: [for (final c in g.conditions) _conditionToProto(c)],
      groups: [for (final sub in g.groups) _groupToProto(sub)],
    );
  }

  pb.FilterCondition _conditionToProto(FilterCondition c) {
    return pb.FilterCondition(
      column: c.column,
      op: switch (c.op) {
        FilterOp.equals => pb.FilterOp.FILTER_OP_EQUALS,
        FilterOp.notEquals => pb.FilterOp.FILTER_OP_NOT_EQUALS,
        FilterOp.lessThan => pb.FilterOp.FILTER_OP_LESS_THAN,
        FilterOp.lessThanOrEqual => pb.FilterOp.FILTER_OP_LESS_THAN_OR_EQUAL,
        FilterOp.greaterThan => pb.FilterOp.FILTER_OP_GREATER_THAN,
        FilterOp.greaterThanOrEqual =>
          pb.FilterOp.FILTER_OP_GREATER_THAN_OR_EQUAL,
        FilterOp.like => pb.FilterOp.FILTER_OP_LIKE,
        FilterOp.ilike => pb.FilterOp.FILTER_OP_ILIKE,
        FilterOp.inList => pb.FilterOp.FILTER_OP_IN,
        FilterOp.isNull => pb.FilterOp.FILTER_OP_IS_NULL,
        FilterOp.isNotNull => pb.FilterOp.FILTER_OP_IS_NOT_NULL,
        FilterOp.between => pb.FilterOp.FILTER_OP_BETWEEN,
      },
      values: [for (final v in c.values) qpb.Value(textValue: v)],
    );
  }

  pb.SortClause _sortToProto(SortClause s) {
    return pb.SortClause(
      column: s.column,
      direction: switch (s.direction) {
        SortDirection.asc => pb.SortDirection.SORT_DIRECTION_ASC,
        SortDirection.desc => pb.SortDirection.SORT_DIRECTION_DESC,
      },
      nulls: switch (s.nulls) {
        NullsOrder.first => pb.NullsOrder.NULLS_ORDER_FIRST,
        NullsOrder.last => pb.NullsOrder.NULLS_ORDER_LAST,
        NullsOrder.unspecified => pb.NullsOrder.NULLS_ORDER_UNSPECIFIED,
      },
    );
  }

  pb.RowChange _changeToProto(RowChange ch) {
    return pb.RowChange(
      type: switch (ch.type) {
        RowChangeType.insert => pb.RowChangeType.ROW_CHANGE_TYPE_INSERT,
        RowChangeType.update => pb.RowChangeType.ROW_CHANGE_TYPE_UPDATE,
        RowChangeType.delete => pb.RowChangeType.ROW_CHANGE_TYPE_DELETE,
      },
      keys: [
        for (final entry in ch.keys.entries)
          pb.ColumnValue(column: entry.key, value: _toValueProto(entry.value)),
      ],
      values: [
        for (final entry in ch.values.entries)
          pb.ColumnValue(column: entry.key, value: _toValueProto(entry.value)),
      ],
    );
  }

  qpb.Value _toValueProto(Object? v) {
    if (v == null) {
      return qpb.Value();
    }
    if (v is bool) {
      return qpb.Value(boolValue: v);
    }
    if (v is int) {
      return qpb.Value(intValue: Int64(v));
    }
    if (v is double) {
      return qpb.Value(doubleValue: v);
    }
    return qpb.Value(textValue: v.toString());
  }
}
