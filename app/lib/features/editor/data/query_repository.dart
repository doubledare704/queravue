import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/query.pbgrpc.dart' as pb;
import '../../../core_client/gen/queravue/v1/session.pbgrpc.dart' as spb;
import '../domain/query_models.dart';

/// Running statements and reading their results through the core.
abstract interface class QueryRepository {
  /// Opens a session on a saved connection. Throws [SessionOpenException]
  /// if the connection fails.
  Future<SessionInfo> openSession(String connectionId);

  Future<void> closeSession(String sessionId);

  /// Runs statements and streams events. Cancelling the subscription cancels
  /// the call, which cancels the running statement.
  Stream<ExecuteEvent> execute(ExecuteRequest request);

  /// Native cancel of the statement running on [sessionId].
  Future<void> cancel(String sessionId);

  Future<FetchedRows> fetchRows(String resultId, int offset, int limit);

  Future<void> closeResult(String resultId);

  /// Formats rows [start, end) of a result in core. [end] 0 means to the end.
  /// Cancelling the subscription cancels the copy.
  Stream<CopyChunk> copyRange({
    required String resultId,
    required int start,
    required int end,
    List<int> columns = const [],
    CopyFormat format = CopyFormat.tsv,
    bool includeHeader = false,
  });
}

/// The repository backed by the live core.
final queryRepositoryProvider = Provider<QueryRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcQueryRepository(() => supervisor.connection);
});

/// gRPC implementation. Resolves the current core connection per call.
class GrpcQueryRepository implements QueryRepository {
  GrpcQueryRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _unaryTimeout = Duration(seconds: 30);

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) {
      throw const QueryException('Core not connected', coreUnavailable: true);
    }
    return c;
  }

  Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on GrpcError catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<SessionInfo> openSession(String connectionId) => _call(() async {
    final resp = await _conn.sessionService.open(
      spb.OpenRequest(connectionId: connectionId),
      // Core bounds the connect itself; leave headroom.
      options: CallOptions(timeout: const Duration(seconds: 20)),
    );
    if (resp.hasError()) {
      throw SessionOpenException(resp.error.message);
    }
    return SessionInfo(
      id: resp.sessionId,
      product: resp.serverInfo.product,
      version: resp.serverInfo.version,
      capabilities: resp.capabilities.toSet(),
    );
  });

  @override
  Future<void> closeSession(String sessionId) => _call(() async {
    await _conn.sessionService.close(
      spb.CloseRequest(sessionId: sessionId),
      options: CallOptions(timeout: _unaryTimeout),
    );
  });

  @override
  Stream<ExecuteEvent> execute(ExecuteRequest request) {
    final req = pb.ExecuteRequest(
      sessionId: request.sessionId,
      text: request.text,
      cursorOffset: request.cursorOffset,
      mode: switch (request.mode) {
        ExecuteMode.statementAtCursor =>
          pb.ExecuteMode.EXECUTE_MODE_STATEMENT_AT_CURSOR,
        ExecuteMode.selection => pb.ExecuteMode.EXECUTE_MODE_SELECTION,
        ExecuteMode.all => pb.ExecuteMode.EXECUTE_MODE_ALL,
      },
    );
    final sel = request.selection;
    if (sel != null) {
      req.selection = pb.TextRange(start: sel.start, end: sel.end);
    }
    return _stream(() => _conn.queryService.execute(req))
        .map(eventFromProto)
        .where((e) => e != null)
        .cast<ExecuteEvent>();
  }

  @override
  Future<void> cancel(String sessionId) => _call(() async {
    await _conn.queryService.cancel(
      pb.CancelRequest(sessionId: sessionId),
      options: CallOptions(timeout: _unaryTimeout),
    );
  });

  @override
  Future<FetchedRows> fetchRows(String resultId, int offset, int limit) =>
      _call(() async {
        final resp = await _conn.queryService.fetchRows(
          pb.FetchRowsRequest(
            resultId: resultId,
            offset: Int64(offset),
            limit: limit,
          ),
          options: CallOptions(timeout: _unaryTimeout),
        );
        return FetchedRows(
          offset: resp.offset.toInt(),
          rows: [for (final r in resp.rows) rowFromProto(r)],
          rowsSpooled: resp.rowsSpooled.toInt(),
          done: resp.done,
        );
      });

  @override
  Future<void> closeResult(String resultId) => _call(() async {
    await _conn.queryService.closeResult(
      pb.CloseResultRequest(resultId: resultId),
      options: CallOptions(timeout: _unaryTimeout),
    );
  });

  @override
  Stream<CopyChunk> copyRange({
    required String resultId,
    required int start,
    required int end,
    List<int> columns = const [],
    CopyFormat format = CopyFormat.tsv,
    bool includeHeader = false,
  }) {
    final req = pb.CopyRangeRequest(
      resultId: resultId,
      rowRange: pb.RowRange(start: Int64(start), end: Int64(end)),
      columnIndices: columns,
      format: switch (format) {
        CopyFormat.tsv => pb.CopyFormat.COPY_FORMAT_TSV,
        CopyFormat.csv => pb.CopyFormat.COPY_FORMAT_CSV,
        CopyFormat.json => pb.CopyFormat.COPY_FORMAT_JSON,
      },
      includeHeader: includeHeader,
    );
    return _stream(() => _conn.queryService.copyRange(req))
        .map((r) => CopyChunk(r.text, r.rowsWritten.toInt()));
  }
}

/// Adapts a gRPC response stream so cancelling the subscription cancels the
/// call and gRPC errors become [QueryException]s.
Stream<T> _stream<T>(ResponseStream<T> Function() start) {
  late ResponseStream<T> call;
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  controller = StreamController<T>(
    onListen: () {
      try {
        call = start();
      } on QueryException catch (e, st) {
        controller.addError(e, st);
        unawaited(controller.close());
        return;
      }
      sub = call.listen(
        controller.add,
        onError: (Object e, StackTrace st) {
          controller.addError(e is GrpcError ? _toException(e) : e, st);
        },
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

QueryException _toException(GrpcError e) => QueryException(
  e.message?.isNotEmpty == true ? e.message! : e.codeName,
  coreUnavailable: e.code == StatusCode.unavailable,
);

/// Converts an ExecuteResponse protobuf message into an ExecuteEvent.
ExecuteEvent? eventFromProto(pb.ExecuteResponse r) {
  switch (r.whichEvent()) {
    case pb.ExecuteResponse_Event.plan:
      return PlanEvent([
        for (final s in r.plan.statements)
          TextSpanRange(s.range.start, s.range.end),
      ]);
    case pb.ExecuteResponse_Event.started:
      return StartedEvent(r.started.statementIndex, r.started.resultId);
    case pb.ExecuteResponse_Event.columns:
      return ColumnsEvent(r.columns.statementIndex, [
        for (final c in r.columns.columns) columnFromProto(c),
      ]);
    case pb.ExecuteResponse_Event.rows:
      return RowsEvent(r.rows.statementIndex, [
        for (final row in r.rows.rows) rowFromProto(row),
      ]);
    case pb.ExecuteResponse_Event.progress:
      return ProgressEvent(
        r.progress.statementIndex,
        r.progress.rowsSpooled.toInt(),
        r.progress.done,
      );
    case pb.ExecuteResponse_Event.summary:
      final s = r.summary;
      return SummaryEvent(
        statementIndex: s.statementIndex,
        rowsAffected: s.rowsAffected.toInt(),
        rowsSpooled: s.rowsSpooled.toInt(),
        duration: Duration(
          microseconds:
              s.duration.seconds.toInt() * 1000000 + s.duration.nanos ~/ 1000,
        ),
        notices: s.notices.toList(),
        truncated: s.truncated,
        hasRows: s.hasRows,
      );
    case pb.ExecuteResponse_Event.error:
      final e = r.error;
      return ErrorEvent(
        statementIndex: e.statementIndex,
        kind: switch (e.kind) {
          pb.QueryErrorKind.QUERY_ERROR_KIND_SQL => QueryErrorKind.sql,
          pb.QueryErrorKind.QUERY_ERROR_KIND_CANCELED =>
            QueryErrorKind.canceled,
          pb.QueryErrorKind.QUERY_ERROR_KIND_CONNECTION =>
            QueryErrorKind.connection,
          pb.QueryErrorKind.QUERY_ERROR_KIND_UNSUPPORTED =>
            QueryErrorKind.unsupported,
          _ => QueryErrorKind.unspecified,
        },
        message: e.message,
        position: e.hasPosition() ? e.position : null,
        duration: Duration(
          microseconds:
              e.duration.seconds.toInt() * 1000000 + e.duration.nanos ~/ 1000,
        ),
      );
    case pb.ExecuteResponse_Event.notSet:
      return null;
  }
}

/// Maps a wire column.
ResultColumn columnFromProto(pb.Column c) => ResultColumn(
  name: c.name,
  typeName: c.typeName,
  kind: switch (c.kind) {
    pb.ValueKind.VALUE_KIND_BOOL => ColumnKind.boolean,
    pb.ValueKind.VALUE_KIND_INT => ColumnKind.integer,
    pb.ValueKind.VALUE_KIND_FLOAT => ColumnKind.float,
    pb.ValueKind.VALUE_KIND_DECIMAL => ColumnKind.decimal,
    pb.ValueKind.VALUE_KIND_TEXT => ColumnKind.text,
    pb.ValueKind.VALUE_KIND_BYTES => ColumnKind.bytes,
    pb.ValueKind.VALUE_KIND_TIMESTAMPTZ => ColumnKind.timestamptz,
    pb.ValueKind.VALUE_KIND_JSON => ColumnKind.json,
    pb.ValueKind.VALUE_KIND_UUID => ColumnKind.uuid,
    pb.ValueKind.VALUE_KIND_ARRAY => ColumnKind.array,
    _ => ColumnKind.unknown,
  },
);

/// Decodes a wire row into plain Dart cells.
ResultRow rowFromProto(pb.Row r) {
  final values = r.values;
  return List<Object?>.generate(
    values.length,
    (i) => valueFromProto(values[i]),
    growable: false,
  );
}

/// Decodes one wire value.
Object? valueFromProto(pb.Value v) {
  switch (v.whichKind()) {
    case pb.Value_Kind.boolValue:
      return v.boolValue;
    case pb.Value_Kind.intValue:
      return v.intValue.toInt();
    case pb.Value_Kind.doubleValue:
      return v.doubleValue;
    case pb.Value_Kind.decimalValue:
      return v.decimalValue;
    case pb.Value_Kind.textValue:
      return v.textValue;
    case pb.Value_Kind.bytesValue:
      return Uint8List.fromList(v.bytesValue);
    case pb.Value_Kind.timestampValue:
      return v.timestampValue.toDateTime().toUtc();
    case pb.Value_Kind.jsonValue:
      return v.jsonValue;
    case pb.Value_Kind.uuidValue:
      return v.uuidValue;
    case pb.Value_Kind.arrayValue:
      return [for (final e in v.arrayValue.values) valueFromProto(e)];
    case pb.Value_Kind.nullValue:
    case pb.Value_Kind.notSet:
      return null;
  }
}
