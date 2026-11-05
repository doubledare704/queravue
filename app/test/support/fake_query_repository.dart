import 'dart:async';

import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/editor/domain/query_models.dart';

/// Row `r` of the fake result: [id, 'row-r'].
ResultRow fakeRow(int r) => <Object?>[r, 'row-$r'];

const fakeColumns = [
  ResultColumn(name: 'id', typeName: 'int4', kind: ColumnKind.integer),
  ResultColumn(name: 'label', typeName: 'text', kind: ColumnKind.text),
];

/// An in-memory [QueryRepository]. `fetchRows` serves generated rows; pages
/// can be held back and released in any order to test out-of-order arrival.
class FakeQueryRepository implements QueryRepository {
  FakeQueryRepository({this.totalRows = 100000, this.pageSize = 500});

  /// Rows the "core" has spooled; raise it to simulate a result still being
  /// read.
  int totalRows;
  final int pageSize;
  bool done = true;

  /// When true, fetches wait until [release] or [releaseAll].
  bool hold = false;

  final fetches = <int>[]; // requested offsets, in request order
  final _held = <int, List<Completer<void>>>{};
  final closedResults = <String>[];
  final closedSessions = <String>[];
  final executed = <ExecuteRequest>[];
  int cancelCalls = 0;
  int openSessions = 0;

  /// Scripted events for the next `execute`, emitted one per microtask.
  List<ExecuteEvent> script = const [];

  /// If set, `execute` stays open after the script until this completes.
  Completer<void>? holdOpen;

  /// If set, `openSession` throws it.
  Object? openError;

  /// Capabilities returned by `openSession`.
  Set<String> capabilities = const {'connect', 'execute'};

  /// Chunks `copyRange` emits.
  List<String> copyChunks = const [];
  Completer<void>? copyHold;
  int copyCancelled = 0;

  @override
  Future<SessionInfo> openSession(String connectionId) async {
    final e = openError;
    if (e != null) throw e;
    openSessions++;
    return SessionInfo(
      id: 'session-$openSessions',
      product: 'FakeDB',
      version: '1',
      capabilities: capabilities,
    );
  }

  @override
  Future<void> closeSession(String sessionId) async =>
      closedSessions.add(sessionId);

  @override
  Stream<ExecuteEvent> execute(ExecuteRequest request) {
    executed.add(request);
    late StreamController<ExecuteEvent> c;
    c = StreamController<ExecuteEvent>(
      onListen: () async {
        for (final e in script) {
          await Future<void>.delayed(Duration.zero);
          if (c.isClosed) return;
          c.add(e);
        }
        final h = holdOpen;
        if (h != null) await h.future;
        if (!c.isClosed) await c.close();
      },
    );
    return c.stream;
  }

  @override
  Future<void> cancel(String sessionId) async => cancelCalls++;

  @override
  Future<FetchedRows> fetchRows(String resultId, int offset, int limit) async {
    fetches.add(offset);
    if (hold) {
      final c = Completer<void>();
      (_held[offset] ??= []).add(c);
      await c.future;
    }
    final end = (offset + limit).clamp(0, totalRows);
    return FetchedRows(
      offset: offset,
      rows: [for (var r = offset; r < end; r++) fakeRow(r)],
      rowsSpooled: totalRows,
      done: done,
    );
  }

  /// Lets the fetch(es) for the page at [offset] complete.
  void release(int offset) {
    for (final c in _held.remove(offset) ?? const <Completer<void>>[]) {
      c.complete();
    }
  }

  void releaseAll() {
    for (final o in _held.keys.toList()) {
      release(o);
    }
  }

  List<int> get heldOffsets => _held.keys.toList()..sort();

  @override
  Future<void> closeResult(String resultId) async =>
      closedResults.add(resultId);

  @override
  Stream<CopyChunk> copyRange({
    required String resultId,
    required int start,
    required int end,
    List<int> columns = const [],
    CopyFormat format = CopyFormat.tsv,
    bool includeHeader = false,
  }) {
    late StreamController<CopyChunk> c;
    c = StreamController<CopyChunk>(
      onListen: () async {
        var n = 0;
        for (final t in copyChunks) {
          await Future<void>.delayed(Duration.zero);
          if (c.isClosed) return;
          c.add(CopyChunk(t, ++n));
        }
        final h = copyHold;
        if (h != null) await h.future;
        if (!c.isClosed) await c.close();
      },
      onCancel: () => copyCancelled++,
    );
    return c.stream;
  }
}
