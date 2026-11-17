import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/application/query_run.dart';
import '../../editor/domain/query_models.dart';
import '../../editor/domain/text_offsets.dart';
import '../../schema/data/schema_repository.dart';
import '../../schema/domain/schema_models.dart';
import '../data/query_builder_repository.dart';
import '../domain/sql_query_models.dart';

const int defaultPreviewLimit = 100;

@immutable
class SqlQueryBuilderState {
  const SqlQueryBuilderState({
    this.inBuilderMode = false,
    this.isLoadingCatalog = false,
    this.isGenerating = false,
    this.draft = const SqlQueryDraft(),
    this.generatedSql = '',
    this.commentsDropped = false,
    this.builderError,
    this.editorUnsupportedMessage,
    this.editorUnsupportedOffset,
    this.previewLimit = defaultPreviewLimit,
    this.previewActive = false,
    this.availableTables = const [],
    this.tableDetailsByKey = const {},
    this.joinSuggestions = const [],
  });

  final bool inBuilderMode;
  final bool isLoadingCatalog;
  final bool isGenerating;
  final SqlQueryDraft draft;
  final String generatedSql;
  final bool commentsDropped;
  final String? builderError;
  final String? editorUnsupportedMessage;
  final int? editorUnsupportedOffset;
  final int previewLimit;
  final bool previewActive;
  final List<TableRef> availableTables;
  final Map<String, TableDetails> tableDetailsByKey;
  final List<JoinSuggestion> joinSuggestions;

  List<SqlTableRefModel> get activeTables => [
    if (draft.from != null && draft.from!.table.isNotEmpty) draft.from!,
    for (final j in draft.joins)
      if (j.table.table.isNotEmpty) j.table,
  ];

  SqlQueryBuilderState copyWith({
    bool? inBuilderMode,
    bool? isLoadingCatalog,
    bool? isGenerating,
    SqlQueryDraft? draft,
    String? generatedSql,
    bool? commentsDropped,
    String? builderError,
    bool clearBuilderError = false,
    String? editorUnsupportedMessage,
    int? editorUnsupportedOffset,
    bool clearUnsupported = false,
    int? previewLimit,
    bool? previewActive,
    List<TableRef>? availableTables,
    Map<String, TableDetails>? tableDetailsByKey,
    List<JoinSuggestion>? joinSuggestions,
  }) => SqlQueryBuilderState(
    inBuilderMode: inBuilderMode ?? this.inBuilderMode,
    isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
    isGenerating: isGenerating ?? this.isGenerating,
    draft: draft ?? this.draft,
    generatedSql: generatedSql ?? this.generatedSql,
    commentsDropped: commentsDropped ?? this.commentsDropped,
    builderError: clearBuilderError
        ? null
        : (builderError ?? this.builderError),
    editorUnsupportedMessage: clearUnsupported
        ? null
        : (editorUnsupportedMessage ?? this.editorUnsupportedMessage),
    editorUnsupportedOffset: clearUnsupported
        ? null
        : (editorUnsupportedOffset ?? this.editorUnsupportedOffset),
    previewLimit: previewLimit ?? this.previewLimit,
    previewActive: previewActive ?? this.previewActive,
    availableTables: availableTables ?? this.availableTables,
    tableDetailsByKey: tableDetailsByKey ?? this.tableDetailsByKey,
    joinSuggestions: joinSuggestions ?? this.joinSuggestions,
  );
}

final sqlQueryBuilderProvider =
    NotifierProvider.family<
      SqlQueryBuilderController,
      SqlQueryBuilderState,
      String
    >(SqlQueryBuilderController.new);

class SqlQueryBuilderController extends Notifier<SqlQueryBuilderState> {
  SqlQueryBuilderController(this.tabId);

  final String tabId;

  String? _connectionId;
  bool _disposed = false;
  int _genSeq = 0;

  QueryBuilderRepository get _repo => ref.read(queryBuilderRepositoryProvider);
  SchemaRepository get _schemaRepo => ref.read(schemaRepositoryProvider);

  @override
  SqlQueryBuilderState build() {
    _disposed = false;
    final tab = ref.watch(
      editorTabsProvider.select(
        (s) => s.tabs.where((t) => t.id == tabId).firstOrNull,
      ),
    );
    _connectionId = tab?.connectionId;
    ref.onDispose(() => _disposed = true);
    return const SqlQueryBuilderState();
  }

  Future<String?> _ensureSession() async {
    final connId = _connectionId;
    if (connId == null) return null;
    final current = ref.read(connectionSessionProvider(connId)).sessionId;
    if (current != null) return current;
    final opened = await ref
        .read(connectionSessionProvider(connId).notifier)
        .connect();
    return opened?.id;
  }

  Future<void> loadCatalog(String sessionId) async {
    if (_disposed || state.isLoadingCatalog) return;
    state = state.copyWith(isLoadingCatalog: true);
    try {
      final dbs = await _schemaRepo.listDatabases(sessionId);
      final tables = <TableRef>[];
      if (dbs.isEmpty || (dbs.length == 1 && dbs.first == 'main')) {
        final schemas = await _schemaRepo.listSchemas(sessionId);
        for (final schema in schemas) {
          final objs = await _schemaRepo.listObjects(sessionId, schema: schema);
          for (final obj in objs) {
            if (!obj.type.isCollection) {
              tables.add(TableRef(schema: schema, table: obj.name));
            }
          }
        }
      } else {
        final targetDb = _preferredDatabase(dbs);
        final schemas = await _schemaRepo.listSchemas(
          sessionId,
          database: targetDb,
        );
        for (final schema in schemas) {
          final objs = await _schemaRepo.listObjects(
            sessionId,
            database: targetDb,
            schema: schema,
          );
          for (final obj in objs) {
            if (!obj.type.isCollection) {
              tables.add(
                TableRef(database: targetDb, schema: schema, table: obj.name),
              );
            }
          }
        }
      }
      if (_disposed) return;
      state = state.copyWith(
        isLoadingCatalog: false,
        availableTables: tables,
        joinSuggestions: _computeJoinSuggestions(
          state.draft,
          state.tableDetailsByKey,
        ),
      );
      unawaited(_preloadTableDetails(sessionId, tables));
    } on Object {
      if (!_disposed) {
        state = state.copyWith(isLoadingCatalog: false);
      }
    }
  }

  String _preferredDatabase(List<String> dbs) {
    final profile = _connectionId == null
        ? null
        : ref
              .read(connectionsControllerProvider)
              .value
              ?.where((c) => c.id == _connectionId)
              .firstOrNull;
    final configured = profile?.params['database'] ?? '';
    if (configured.isNotEmpty && dbs.contains(configured)) {
      return configured;
    }
    const systemDbs = {
      'information_schema',
      'performance_schema',
      'mysql',
      'sys',
    };
    return dbs.where((d) => !systemDbs.contains(d)).firstOrNull ?? dbs.first;
  }

  Future<void> _preloadTableDetails(
    String sessionId,
    List<TableRef> tables,
  ) async {
    for (final ref in tables.take(30)) {
      if (_disposed) return;
      await _loadTableDetails(sessionId, ref);
    }
  }

  Future<void> _loadTableDetails(String sessionId, TableRef tableRef) async {
    final key = tableKey(tableRef.schema, tableRef.table);
    if (state.tableDetailsByKey.containsKey(key)) return;
    try {
      final details = await _schemaRepo.getTableDetails(sessionId, tableRef);
      if (_disposed) return;
      final updated = {...state.tableDetailsByKey, key: details};
      state = state.copyWith(
        tableDetailsByKey: updated,
        joinSuggestions: _computeJoinSuggestions(state.draft, updated),
      );
    } on Object {
      // Ignore schema detail failures for individual tables.
    }
  }

  Future<void> _ensureDetailsForModel(
    String sessionId,
    SqlQueryDraft draft,
  ) async {
    final refs = <TableRef>[];
    if (draft.from != null && draft.from!.table.isNotEmpty) {
      refs.add(TableRef(schema: draft.from!.schema, table: draft.from!.table));
    }
    for (final j in draft.joins) {
      if (j.table.table.isNotEmpty) {
        refs.add(TableRef(schema: j.table.schema, table: j.table.table));
      }
    }
    for (final r in refs) {
      await _loadTableDetails(sessionId, r);
    }
  }

  Future<void> openFromEditor(String sqlText) async {
    state = state.copyWith(clearUnsupported: true, clearBuilderError: true);
    final sessionId = await _ensureSession();
    if (_disposed) return;
    if (sessionId == null) {
      final connId = _connectionId;
      final err = connId == null
          ? 'No active connection.'
          : (ref.read(connectionSessionProvider(connId)).error ??
                'Connect to the database before opening the visual builder.');
      state = state.copyWith(editorUnsupportedMessage: err);
      return;
    }

    unawaited(loadCatalog(sessionId));

    if (sqlText.trim().isEmpty) {
      state = state.copyWith(
        inBuilderMode: true,
        commentsDropped: false,
        clearUnsupported: true,
        clearBuilderError: true,
      );
      if (state.draft.from != null && state.draft.from!.table.isNotEmpty) {
        await _regenerate(sessionId, state.draft);
      }
      return;
    }

    try {
      final outcome = await _repo.parseSql(sessionId: sessionId, sql: sqlText);
      if (_disposed) return;
      state = state.copyWith(
        inBuilderMode: true,
        draft: outcome.model,
        commentsDropped: outcome.commentsDropped,
        clearUnsupported: true,
        clearBuilderError: true,
        joinSuggestions: _computeJoinSuggestions(
          outcome.model,
          state.tableDetailsByKey,
        ),
      );
      await Future.wait([
        _ensureDetailsForModel(sessionId, outcome.model),
        _regenerate(sessionId, outcome.model),
      ]);
    } on QueryBuilderException catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        inBuilderMode: false,
        editorUnsupportedMessage: e.message,
        editorUnsupportedOffset: e.offset,
      );
    }
  }

  void openInEditor(CodeLineEditingController controller) {
    if (state.generatedSql.isNotEmpty) {
      controller.text = state.generatedSql;
      final (line, col) = positionOfOffset(
        state.generatedSql,
        state.generatedSql.length,
      );
      controller.selection = CodeLineSelection.collapsed(
        index: line,
        offset: col,
      );
    }
    state = state.copyWith(
      inBuilderMode: false,
      clearUnsupported: true,
      clearBuilderError: true,
    );
  }

  void dismissCommentsDropped() {
    state = state.copyWith(commentsDropped: false);
  }

  void dismissUnsupportedMessage() {
    state = state.copyWith(clearUnsupported: true);
  }

  void setPreviewLimit(int limit) {
    if (limit <= 0) return;
    state = state.copyWith(previewLimit: limit);
  }

  Future<void> setFromTable(TableRef ref) async {
    final alias = _uniqueAlias(ref.table, const []);
    final next = state.draft.copyWith(
      from: SqlTableRefModel(
        schema: ref.schema,
        table: ref.table,
        alias: alias,
      ),
    );
    await _updateDraft(next);
  }

  Future<void> setFromAlias(String alias) async {
    final current = state.draft.from;
    if (current == null) return;
    await _updateDraft(
      state.draft.copyWith(from: current.copyWith(alias: alias)),
    );
  }

  Future<void> setDistinct(bool distinct) =>
      _updateDraft(state.draft.copyWith(distinct: distinct));

  Future<void> addJoin(SqlJoinModel join) =>
      _updateDraft(state.draft.copyWith(joins: [...state.draft.joins, join]));

  Future<void> applyJoinSuggestion(JoinSuggestion suggestion) async {
    final existingAliases = [
      for (final t in state.activeTables) t.effectiveAlias,
    ];
    final targetAlias = _uniqueAlias(suggestion.targetTable, existingAliases);
    final comparisons = [
      for (var i = 0; i < suggestion.existingColumns.length; i++)
        SqlComparisonModel(
          left: SqlColumnOperand(
            SqlColumnRefModel(
              tableAlias: suggestion.existingAlias,
              column: suggestion.existingColumns[i],
            ),
          ),
          op: SqlOperatorKind.eq,
          operands: [
            SqlColumnOperand(
              SqlColumnRefModel(
                tableAlias: targetAlias,
                column: suggestion.targetColumns[i],
              ),
            ),
          ],
        ),
    ];
    final SqlConditionNode onCondition = comparisons.length == 1
        ? comparisons.first
        : SqlConditionGroupModel(children: comparisons);
    await addJoin(
      SqlJoinModel(
        kind: SqlJoinKindModel.inner,
        table: SqlTableRefModel(
          schema: suggestion.targetSchema,
          table: suggestion.targetTable,
          alias: targetAlias,
        ),
        on: onCondition,
      ),
    );
  }

  Future<void> updateJoin(int index, SqlJoinModel join) async {
    final next = [...state.draft.joins]..[index] = join;
    await _updateDraft(state.draft.copyWith(joins: next));
  }

  Future<void> removeJoin(int index) async {
    final next = [...state.draft.joins]..removeAt(index);
    await _updateDraft(state.draft.copyWith(joins: next));
  }

  Future<void> addSelectItem(SqlSelectItemModel item) =>
      _updateDraft(state.draft.copyWith(select: [...state.draft.select, item]));

  Future<void> toggleColumnSelect(SqlColumnRefModel col) async {
    final list = [...state.draft.select];
    final idx = list.indexWhere((s) => !s.isAggregate && s.column == col);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(SqlSelectItemModel.column(col));
    }
    await _updateDraft(state.draft.copyWith(select: list));
  }

  Future<void> updateSelectItem(int index, SqlSelectItemModel item) async {
    final next = [...state.draft.select]..[index] = item;
    await _updateDraft(state.draft.copyWith(select: next));
  }

  Future<void> removeSelectItem(int index) async {
    final next = [...state.draft.select]..removeAt(index);
    await _updateDraft(state.draft.copyWith(select: next));
  }

  Future<void> setWhere(SqlConditionNode? where) => _updateDraft(
    where == null
        ? state.draft.copyWith(clearWhere: true)
        : state.draft.copyWith(where: where),
  );

  Future<void> addGroupBy(SqlColumnRefModel col) async {
    if (state.draft.groupBy.contains(col)) return;
    await _updateDraft(
      state.draft.copyWith(groupBy: [...state.draft.groupBy, col]),
    );
  }

  Future<void> removeGroupBy(int index) async {
    final next = [...state.draft.groupBy]..removeAt(index);
    await _updateDraft(state.draft.copyWith(groupBy: next));
  }

  Future<void> setHaving(SqlConditionNode? having) => _updateDraft(
    having == null
        ? state.draft.copyWith(clearHaving: true)
        : state.draft.copyWith(having: having),
  );

  Future<void> addOrderTerm(SqlOrderTermModel term) => _updateDraft(
    state.draft.copyWith(orderBy: [...state.draft.orderBy, term]),
  );

  Future<void> updateOrderTerm(int index, SqlOrderTermModel term) async {
    final next = [...state.draft.orderBy]..[index] = term;
    await _updateDraft(state.draft.copyWith(orderBy: next));
  }

  Future<void> removeOrderTerm(int index) async {
    final next = [...state.draft.orderBy]..removeAt(index);
    await _updateDraft(state.draft.copyWith(orderBy: next));
  }

  Future<void> setLimit(int? limit) => _updateDraft(
    limit == null || limit <= 0
        ? state.draft.copyWith(clearLimit: true)
        : state.draft.copyWith(limit: limit),
  );

  Future<void> setOffset(int? offset) => _updateDraft(
    offset == null || offset <= 0
        ? state.draft.copyWith(clearOffset: true)
        : state.draft.copyWith(offset: offset),
  );

  Future<void> clearDraft() async {
    state = state.copyWith(
      draft: const SqlQueryDraft(),
      generatedSql: '',
      commentsDropped: false,
      clearBuilderError: true,
      joinSuggestions: const [],
    );
  }

  Future<void> runPreview() async {
    final draft = state.draft;
    if (draft.from == null || draft.from!.table.isEmpty) {
      state = state.copyWith(builderError: 'Select a FROM table first.');
      return;
    }
    final sessionId = await _ensureSession();
    if (_disposed || sessionId == null) return;

    final capped =
        draft.limit != null &&
            draft.limit! > 0 &&
            draft.limit! <= state.previewLimit
        ? draft
        : draft.copyWith(limit: state.previewLimit);
    try {
      final previewSql = await _repo.generateSql(
        sessionId: sessionId,
        model: capped,
      );
      if (_disposed) return;
      state = state.copyWith(previewActive: true, clearBuilderError: true);
      await ref
          .read(queryRunProvider(tabId).notifier)
          .run(text: previewSql, mode: ExecuteMode.all);
    } on QueryBuilderException catch (e) {
      if (!_disposed) {
        state = state.copyWith(builderError: e.message);
      }
    }
  }

  Future<void> cancelPreview() =>
      ref.read(queryRunProvider(tabId).notifier).cancel();

  Future<void> _updateDraft(SqlQueryDraft next) async {
    state = state.copyWith(
      draft: next,
      clearBuilderError: true,
      joinSuggestions: _computeJoinSuggestions(next, state.tableDetailsByKey),
    );
    final sessionId = await _ensureSession();
    if (_disposed || sessionId == null) return;
    await _ensureDetailsForModel(sessionId, next);
    await _regenerate(sessionId, next);
  }

  Future<void> _regenerate(String sessionId, SqlQueryDraft draft) async {
    final seq = ++_genSeq;
    if (draft.from == null || draft.from!.table.isEmpty) {
      state = state.copyWith(
        generatedSql: '',
        isGenerating: false,
        clearBuilderError: true,
      );
      return;
    }
    state = state.copyWith(isGenerating: true);
    try {
      final sql = await _repo.generateSql(sessionId: sessionId, model: draft);
      if (_disposed || seq != _genSeq) return;
      state = state.copyWith(
        generatedSql: sql,
        isGenerating: false,
        clearBuilderError: true,
      );
    } on QueryBuilderException catch (e) {
      if (_disposed || seq != _genSeq) return;
      state = state.copyWith(isGenerating: false, builderError: e.message);
    }
  }

  List<JoinSuggestion> _computeJoinSuggestions(
    SqlQueryDraft draft,
    Map<String, TableDetails> detailsByKey,
  ) {
    final active = [
      if (draft.from != null && draft.from!.table.isNotEmpty) draft.from!,
      for (final j in draft.joins)
        if (j.table.table.isNotEmpty) j.table,
    ];
    if (active.isEmpty) return const [];

    final suggestions = <JoinSuggestion>[];
    final seen = <String>{};

    void addIfNew(JoinSuggestion s) {
      final key =
          '${s.existingAlias}:${s.existingColumns.join(",")}=>'
          '${s.targetSchema}.${s.targetTable}:${s.targetColumns.join(",")}';
      if (seen.add(key)) suggestions.add(s);
    }

    for (final src in active) {
      final details = detailsByKey[tableKey(src.schema, src.table)];
      if (details != null) {
        for (final fk in details.foreignKeys) {
          if (fk.columns.isEmpty ||
              fk.columns.length != fk.referencedColumns.length) {
            continue;
          }
          addIfNew(
            JoinSuggestion(
              constraintName: fk.name,
              existingAlias: src.effectiveAlias,
              existingColumns: fk.columns,
              targetSchema: fk.referencedSchema,
              targetTable: fk.referencedTable,
              targetColumns: fk.referencedColumns,
            ),
          );
        }
      }

      for (final other in detailsByKey.values) {
        for (final fk in other.foreignKeys) {
          if (fk.columns.isEmpty ||
              fk.columns.length != fk.referencedColumns.length) {
            continue;
          }
          final sameTable = fk.referencedTable == src.table;
          final sameSchema =
              fk.referencedSchema.isEmpty ||
              src.schema.isEmpty ||
              fk.referencedSchema == src.schema;
          if (!sameTable || !sameSchema) continue;
          addIfNew(
            JoinSuggestion(
              constraintName: '${other.tableRef.table}_${fk.name}',
              existingAlias: src.effectiveAlias,
              existingColumns: fk.referencedColumns,
              targetSchema: other.tableRef.schema,
              targetTable: other.tableRef.table,
              targetColumns: fk.columns,
            ),
          );
        }
      }
    }
    return suggestions;
  }

  String _uniqueAlias(String tableName, List<String> taken) {
    final used = <String>{
      if (state.draft.from != null && state.draft.from!.table.isNotEmpty)
        state.draft.from!.effectiveAlias,
      for (final j in state.draft.joins)
        if (j.table.table.isNotEmpty) j.table.effectiveAlias,
      ...taken,
    };
    final base = tableName.isNotEmpty
        ? tableName.substring(0, 1).toLowerCase()
        : 't';
    if (!used.contains(base)) return base;
    for (var i = 2; ; i++) {
      final candidate = '$base$i';
      if (!used.contains(candidate)) return candidate;
    }
  }
}

String tableKey(String schema, String table) =>
    schema.isEmpty || schema == 'main' ? table : '$schema.$table';
