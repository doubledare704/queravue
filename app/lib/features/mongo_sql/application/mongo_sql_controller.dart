import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../connections/application/connection_session.dart';
import '../../documents/application/document_preview_controller.dart';
import '../../documents/data/document_repository.dart';
import '../../editor/application/editor_tabs.dart';
import '../../query_builder/domain/sql_query_models.dart'
    show utf8ByteOffsetToUtf16;
import '../../shell/application/cursor_page_controller.dart';
import '../../shell/application/shell_tab_controller.dart';
import '../data/mongo_sql_repository.dart';
import '../domain/mongo_sql_translation.dart';

const mongoSqlDebounce = Duration(milliseconds: 250);

final mongoSqlControllerProvider = NotifierProvider.autoDispose
    .family<MongoSqlController, MongoSqlState, EditorTab>(
      MongoSqlController.new,
    );

class MongoSqlState {
  const MongoSqlState({
    this.translation,
    this.pending = false,
    this.failure,
    this.errorOffset,
    this.format = MqlFormat.shell,
    this.showPreview = true,
  });

  final MongoSqlTranslation? translation;
  final bool pending;
  final MongoSqlFailure? failure;
  final int? errorOffset;
  final MqlFormat format;
  final bool showPreview;

  MongoSqlTranslation? get current =>
      pending || failure != null ? null : translation;
  bool get stale => translation != null && current == null;

  MongoSqlState withFormat(MqlFormat value) => MongoSqlState(
    translation: translation,
    pending: pending,
    failure: failure,
    errorOffset: errorOffset,
    format: value,
    showPreview: showPreview,
  );

  MongoSqlState withResults({required bool preview}) => MongoSqlState(
    translation: translation,
    pending: pending,
    failure: failure,
    errorOffset: errorOffset,
    format: format,
    showPreview: preview,
  );
}

class MongoSqlController extends Notifier<MongoSqlState> {
  MongoSqlController(this.tab);

  final EditorTab tab;
  Timer? _timer;
  Completer<void>? _translationCall;
  late CodeLines _lines;
  bool _waitingForSession = false;

  @override
  MongoSqlState build() {
    _lines = tab.controller.codeLines;
    tab.controller.addListener(_onEdit);
    ref.listen(connectionSessionProvider(tab.connectionId), (before, after) {
      if (_waitingForSession && !after.isConnecting) {
        _waitingForSession = false;
        if (after.sessionId == null) {
          _failConnection('Could not connect.');
        } else {
          _schedule();
        }
      } else if (before?.sessionId != null && after.sessionId == null) {
        _cancelTranslation();
        _failConnection('The connection was closed.');
      } else if (after.sessionId != null &&
          before?.sessionId != after.sessionId &&
          state.failure?.kind == MongoSqlErrorKind.other) {
        _schedule();
      }
    });
    ref.onDispose(() {
      tab.controller.removeListener(_onEdit);
      _cancelTranslation();
    });
    scheduleMicrotask(() {
      if (ref.mounted) _schedule();
    });
    return const MongoSqlState();
  }

  void _cancelTranslation() {
    _timer?.cancel();
    _waitingForSession = false;
    _translationCall?.complete();
    _translationCall = null;
  }

  void _onEdit() {
    final lines = tab.controller.codeLines;
    if (identical(_lines, lines)) return;
    _lines = lines;
    _schedule();
  }

  void _schedule() {
    _cancelTranslation();
    final sql = tab.controller.text;
    final hasSql = sql.trim().isNotEmpty;
    state = MongoSqlState(
      translation: hasSql ? state.translation : null,
      pending: hasSql,
      format: state.format,
      showPreview: state.showPreview,
    );
    _timer = Timer(mongoSqlDebounce, () => unawaited(_translate(sql)));
  }

  Future<void> _translate(String sql) async {
    final connection = connectionSessionProvider(tab.connectionId);
    if (ref.read(connection).isConnecting) {
      _waitingForSession = true;
      return;
    }

    final call = _translationCall = Completer<void>();
    try {
      final session = await ref.read(connection.notifier).connect();
      if (!ref.mounted || call.isCompleted) return;
      if (session == null) {
        _failConnection('Could not connect.');
        return;
      }
      if (sql.trim().isEmpty) return;
      if (!supportsMongoSql(session.capabilities)) {
        _failConnection(
          'SQL mode requires a document connection with shell support.',
        );
        return;
      }
      final result = await ref
          .read(mongoSqlRepositoryProvider)
          .translate(
            sessionId: session.id,
            database: tab.shellDatabase,
            sql: sql,
            cancel: call.future,
          );
      if (!ref.mounted || call.isCompleted) return;
      state = MongoSqlState(
        translation: result,
        format: state.format,
        showPreview: state.showPreview,
      );
    } on MongoSqlFailure catch (failure) {
      if (!ref.mounted || call.isCompleted) return;
      _fail(failure, sql);
    } on Object catch (error) {
      if (!ref.mounted || call.isCompleted) return;
      _fail(
        MongoSqlFailure(MongoSqlErrorKind.other, MongoSqlDiagnostic('$error')),
        sql,
      );
    } finally {
      if (identical(_translationCall, call)) _translationCall = null;
    }
  }

  void _failConnection(String fallback) {
    final connection = ref.read(connectionSessionProvider(tab.connectionId));
    _fail(
      MongoSqlFailure(
        MongoSqlErrorKind.other,
        MongoSqlDiagnostic(connection.error ?? fallback),
      ),
      '',
    );
  }

  void _fail(MongoSqlFailure failure, String sql) {
    final offset = failure.diagnostic.byteOffset;
    state = MongoSqlState(
      translation: state.translation,
      failure: failure,
      errorOffset: failure.kind == MongoSqlErrorKind.other || offset == null
          ? null
          : utf8ByteOffsetToUtf16(sql, offset),
      format: state.format,
      showPreview: state.showPreview,
    );
  }

  void retry() => _schedule();

  void setFormat(MqlFormat format) => state = state.withFormat(format);

  Future<void> preview() async {
    final translation = state.current;
    final sessionId = ref
        .read(connectionSessionProvider(tab.connectionId))
        .sessionId;
    if (translation == null || sessionId == null || _busy) return;
    state = state.withResults(preview: true);
    final preview = ref.read(documentPreviewProvider(tab.id).notifier);
    switch (translation) {
      case MongoSqlFind(:final query):
        await preview.runFind(
          CollectionTarget(
            sessionId,
            translation.database,
            translation.collection,
          ),
          query,
        );
      case MongoSqlAggregate():
        // FetchCursor applies the preview cap to the server-side pipeline.
        await preview.runShell(
          connect: () async => sessionId,
          database: translation.database,
          code: (_) => translation.shellCode,
        );
    }
  }

  Future<void> run() async {
    final translation = state.current;
    if (translation == null || _busy) return;
    state = state.withResults(preview: false);
    final shell = ref.read(shellTabProvider(tab.id).notifier);
    shell.clear();
    await shell.run(translation.shellCode);
  }

  bool get _busy =>
      ref.read(shellTabProvider(tab.id)).busy ||
      ref.read(documentPreviewProvider(tab.id)).running;

  Future<void> cancel() async {
    final preview = documentPreviewProvider(tab.id);
    if (ref.read(preview).running) {
      ref.read(preview.notifier).reset();
      return;
    }
    final shell = shellTabProvider(tab.id);
    final result = ref.read(shell);
    if (result.busy) {
      await ref.read(shell.notifier).cancel();
    } else if (!state.showPreview) {
      final key = cursorOf(result);
      if (key != null) ref.read(cursorPageProvider(key).notifier).cancel();
    }
  }
}

CursorKey? cursorOf(ShellTabState result) {
  final handle = result.entries.whereType<OutputCursor>().lastOrNull?.handle;
  final shellId = result.shellId;
  return handle == null || shellId == null
      ? null
      : CursorKey(shellId, handle.cursorId, transient: true);
}

bool supportsMongoSql(Set<String>? capabilities) =>
    capabilities != null &&
    capabilities.contains('document_store') &&
    capabilities.contains('shell');

final connectionHasMongoSqlProvider = Provider.family<bool, String>(
  (ref, id) => supportsMongoSql(ref.watch(connectionCapabilitiesProvider(id))),
);
