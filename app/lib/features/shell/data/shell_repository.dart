import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/shell.pbgrpc.dart' as pb;
import '../../documents/domain/models.dart';
import '../domain/shell_models.dart';

/// Access to the core's ShellService.
abstract interface class ShellRepository {
  /// Starts a shell on an open session and returns its id.
  Future<String> openShell(String sessionId, String database);

  /// Runs [code]. The stream ends after a [ShellDone] or [ShellErrorEvent].
  /// Cancelling the subscription cancels the script.
  Stream<ShellEvent> eval(String shellId, String code, {bool confirmed});

  /// One page of the documents behind a cursor handle.
  Stream<DocBatch> fetchCursor(
    String shellId,
    String cursorId, {
    int skip,
    int limit,
  });

  Future<void> cancel(String shellId);

  Future<void> closeShell(String shellId);
}

final shellRepositoryProvider = Provider<ShellRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcShellRepository(() => supervisor.connection);
});

class GrpcShellRepository implements ShellRepository {
  GrpcShellRepository(this._connection);

  final CoreConnection? Function() _connection;

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  @override
  Future<String> openShell(String sessionId, String database) async {
    final r = await _conn.shellService.openShell(
      pb.OpenShellRequest(sessionId: sessionId, database: database),
    );
    return r.shellId;
  }

  @override
  Stream<ShellEvent> eval(
    String shellId,
    String code, {
    bool confirmed = false,
  }) => _conn.shellService
      .eval(pb.EvalRequest(shellId: shellId, code: code, confirmed: confirmed))
      .map(_event);

  @override
  Stream<DocBatch> fetchCursor(
    String shellId,
    String cursorId, {
    int skip = 0,
    int limit = 0,
  }) => _conn.shellService
      .fetchCursor(
        pb.FetchCursorRequest(
          shellId: shellId,
          cursorId: cursorId,
          skip: Int64(skip),
          limit: limit,
        ),
      )
      .map(
        (r) => DocBatch(
          offset: r.batch.offset.toInt(),
          documents: List.of(r.batch.documents),
          done: r.batch.done,
        ),
      );

  @override
  Future<void> cancel(String shellId) async {
    await _conn.shellService.cancel(
      pb.ShellServiceCancelRequest(shellId: shellId),
    );
  }

  @override
  Future<void> closeShell(String shellId) async {
    await _conn.shellService.closeShell(pb.CloseShellRequest(shellId: shellId));
  }
}

ShellEvent _event(pb.EvalResponse r) {
  if (r.hasPrint()) return ShellPrint(_level(r.print.level), r.print.text);
  if (r.hasError()) return ShellErrorEvent(_failure(r.error));
  if (r.hasDone()) {
    return ShellDone(
      Duration(
        seconds: r.done.duration.seconds.toInt(),
        microseconds: r.done.duration.nanos ~/ 1000,
      ),
    );
  }
  final item = r.result;
  if (item.hasCursor()) {
    final c = item.cursor;
    return ShellCursorEvent(
      CursorHandle(
        cursorId: c.cursorId,
        kind: c.kind == pb.CursorKind.CURSOR_KIND_AGGREGATE
            ? CursorKind.aggregate
            : CursorKind.find,
        database: c.database,
        collection: c.collection,
      ),
    );
  }
  if (item.hasWrite()) {
    return ShellValue(
      ValueKind.write,
      item.write.result,
      writeOp: item.write.operation,
    );
  }
  if (item.hasDocument()) return ShellValue(ValueKind.document, item.document);
  return ShellValue(ValueKind.scalar, item.scalar);
}

PrintLevel _level(pb.PrintLevel l) => switch (l) {
  pb.PrintLevel.PRINT_LEVEL_INFO => PrintLevel.info,
  pb.PrintLevel.PRINT_LEVEL_WARN => PrintLevel.warn,
  pb.PrintLevel.PRINT_LEVEL_ERROR => PrintLevel.error,
  _ => PrintLevel.log,
};

ShellFailure _failure(pb.ShellError e) => ShellFailure(
  kind: switch (e.kind) {
    pb.ShellErrorKind.SHELL_ERROR_KIND_SYNTAX => ShellErrorKind.syntax,
    pb.ShellErrorKind.SHELL_ERROR_KIND_RUNTIME => ShellErrorKind.runtime,
    pb.ShellErrorKind.SHELL_ERROR_KIND_CONFIRMATION_REQUIRED =>
      ShellErrorKind.confirmationRequired,
    pb.ShellErrorKind.SHELL_ERROR_KIND_OUTPUT_LIMIT =>
      ShellErrorKind.outputLimit,
    pb.ShellErrorKind.SHELL_ERROR_KIND_TIMEOUT => ShellErrorKind.timeout,
    pb.ShellErrorKind.SHELL_ERROR_KIND_CANCELED => ShellErrorKind.canceled,
    pb.ShellErrorKind.SHELL_ERROR_KIND_SERVER => ShellErrorKind.server,
    pb.ShellErrorKind.SHELL_ERROR_KIND_UNSUPPORTED =>
      ShellErrorKind.unsupported,
    _ => ShellErrorKind.unspecified,
  },
  message: e.message,
  stack: e.jsStack,
  line: e.line,
  column: e.column,
  operation: e.operation,
);
