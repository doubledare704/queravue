import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/data/shell_repository.dart';
import '../../shell/domain/shell_models.dart';
import '../data/document_repository.dart';
import '../domain/models.dart';
import 'document_tab_controller.dart' show kCancelDelay;

const kDefaultPreviewLimit = 20;
const kPreviewMaxTimeMs = 5000;

enum PreviewPhase { idle, running, done, failed }

class DocumentPreviewState {
  const DocumentPreviewState({
    this.phase = PreviewPhase.idle,
    this.canCancel = false,
    this.docs = const [],
    this.error,
  });

  final PreviewPhase phase;
  final bool canCancel;
  final List<DocItem> docs;
  final String? error;

  bool get running => phase == PreviewPhase.running;
}

final documentPreviewProvider = NotifierProvider.autoDispose
    .family<DocumentPreviewController, DocumentPreviewState, Object>(
      (key) => DocumentPreviewController(),
    );

class DocumentPreviewController extends Notifier<DocumentPreviewState> {
  _PreviewRun? _active;

  @override
  DocumentPreviewState build() {
    ref.onDispose(_cancelActive);
    return const DocumentPreviewState();
  }

  Future<void> runFind(
    CollectionTarget target,
    FindQuery query, {
    int limit = kDefaultPreviewLimit,
  }) {
    final cap = limit.clamp(1, 1000);
    final count = query.limit > 0 ? math.min(query.limit, cap) : cap;
    return _run(
      (run) => _collect(
        run,
        ref
            .read(documentRepositoryProvider)
            .find(
              target,
              query.copyWith(limit: count),
              batchSize: count,
              maxTimeMs: kPreviewMaxTimeMs,
            ),
        count,
      ),
    );
  }

  Future<void> runShell({
    required Future<String?> Function() connect,
    required String database,
    required String Function(int limit) code,
    int limit = kDefaultPreviewLimit,
  }) {
    final cap = limit.clamp(1, 1000);
    return _run((run) async {
      final shell = ref.read(shellRepositoryProvider);
      final session = await connect();
      if (run.cancelled) return const [];
      if (session == null) throw StateError('Cannot start a preview shell.');

      final shellId = await shell.openShell(session, database);
      try {
        if (run.cancelled) return const [];
        final cursor = await _evalCursor(run, shell.eval(shellId, code(cap)));
        if (run.cancelled) return const [];
        if (cursor == null) return const [];
        return await _collect(
          run,
          shell.fetchCursor(shellId, cursor.cursorId, limit: cap),
          cap,
        );
      } finally {
        if (run.cancelled) await _ignoreCleanup(shell.cancel(shellId));
        await _ignoreCleanup(shell.closeShell(shellId));
      }
    });
  }

  Future<CursorHandle?> _evalCursor(
    _PreviewRun run,
    Stream<ShellEvent> events,
  ) async {
    CursorHandle? cursor;
    final iterator = StreamIterator(events);
    run.cancelStream = iterator.cancel;
    try {
      while (await iterator.moveNext()) {
        final event = iterator.current;
        if (event is ShellErrorEvent) throw event.failure;
        if (event is ShellCursorEvent) cursor = event.handle;
      }
      return cursor;
    } finally {
      unawaited(_ignoreCleanup(iterator.cancel()));
    }
  }

  Future<List<DocItem>> _collect(
    _PreviewRun run,
    Stream<DocBatch> batches,
    int cap,
  ) async {
    final docs = <DocItem>[];
    final iterator = StreamIterator(batches);
    run.cancelStream = iterator.cancel;
    try {
      while (docs.length < cap && await iterator.moveNext()) {
        docs.addAll(
          iterator.current.documents.take(cap - docs.length).map(DocItem.new),
        );
      }
      return List.unmodifiable(docs);
    } finally {
      unawaited(_ignoreCleanup(iterator.cancel()));
    }
  }

  Future<void> _run(
    Future<List<DocItem>> Function(_PreviewRun run) load,
  ) async {
    if (_active != null) return;
    final run = _active = _PreviewRun();
    state = const DocumentPreviewState(phase: PreviewPhase.running);
    run.timer = Timer(kCancelDelay, () {
      state = const DocumentPreviewState(
        phase: PreviewPhase.running,
        canCancel: true,
      );
    });
    try {
      final docs = await load(run);
      if (!run.cancelled) {
        state = DocumentPreviewState(phase: PreviewPhase.done, docs: docs);
      }
    } on Object catch (error) {
      if (!run.cancelled) {
        fail(error is ShellFailure ? error.message : error.toString());
      }
    } finally {
      run.timer?.cancel();
      if (identical(_active, run)) _active = null;
    }
  }

  void fail(String error) {
    _cancelActive();
    state = DocumentPreviewState(phase: PreviewPhase.failed, error: error);
  }

  void reset() {
    _cancelActive();
    if (state.phase != PreviewPhase.idle) state = const DocumentPreviewState();
  }

  void _cancelActive() {
    final run = _active;
    if (run == null) return;
    _active = null;
    run.cancelled = true;
    run.timer?.cancel();
    unawaited(_ignoreCleanup(run.cancelStream?.call()));
  }
}

class _PreviewRun {
  bool cancelled = false;
  Timer? timer;
  Future<void> Function()? cancelStream;
}

Future<void> _ignoreCleanup(Future<void>? cleanup) async {
  try {
    await cleanup;
  } on Object {
    // The stream or shell may already have closed.
  }
}
