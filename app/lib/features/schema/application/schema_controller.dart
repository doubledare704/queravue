import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../data/schema_repository.dart';
import '../domain/schema_models.dart';

/// State of a single schema tree node.
sealed class SchemaTreeNode {
  const SchemaTreeNode({required this.key, required this.label});

  final String key;
  final String label;
}

class DatabaseNode extends SchemaTreeNode {
  const DatabaseNode({required super.key, required super.label});
}

class SchemaNamespaceNode extends SchemaTreeNode {
  const SchemaNamespaceNode({
    required super.key,
    required super.label,
    required this.database,
  });

  final String database;
}

class ObjectNode extends SchemaTreeNode {
  const ObjectNode({
    required super.key,
    required super.label,
    required this.tableRef,
    required this.type,
    this.rowCountEstimate = -1,
    this.capped = false,
  });

  final TableRef tableRef;
  final SchemaObjectType type;
  final int rowCountEstimate;
  final bool capped;
}

class ColumnNode extends SchemaTreeNode {
  const ColumnNode({
    required super.key,
    required super.label,
    required this.column,
  });

  final ColumnDetails column;
}

class IndexNode extends SchemaTreeNode {
  const IndexNode({
    required super.key,
    required super.label,
    required this.index,
  });

  final IndexDetails index;
}

class ForeignKeyNode extends SchemaTreeNode {
  const ForeignKeyNode({
    required super.key,
    required super.label,
    required this.foreignKey,
  });

  final ForeignKeyDetails foreignKey;
}

/// State for the schema tree of one connection.
@immutable
class SchemaTreeState {
  const SchemaTreeState({
    this.sessionId,
    this.documentStore = false,
    this.isLoading = false,
    this.error,
    this.expandedKeys = const {},
    this.loadingKeys = const {},
    this.filterText = '',
    this.childrenByKey = const {},
    this.tableDetailsByRef = const {},
  });

  final String? sessionId;

  /// The engine has the `document_store` capability: databases hold
  /// collections directly (no schema level) and open in document tabs.
  final bool documentStore;
  final bool isLoading;
  final Object? error;
  final Set<String> expandedKeys;
  final Set<String> loadingKeys;
  final String filterText;
  final Map<String, List<SchemaTreeNode>> childrenByKey;
  final Map<String, TableDetails> tableDetailsByRef;

  SchemaTreeState copyWith({
    String? sessionId,
    bool? documentStore,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    Set<String>? expandedKeys,
    Set<String>? loadingKeys,
    String? filterText,
    Map<String, List<SchemaTreeNode>>? childrenByKey,
    Map<String, TableDetails>? tableDetailsByRef,
  }) => SchemaTreeState(
    sessionId: sessionId ?? this.sessionId,
    documentStore: documentStore ?? this.documentStore,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    expandedKeys: expandedKeys ?? this.expandedKeys,
    loadingKeys: loadingKeys ?? this.loadingKeys,
    filterText: filterText ?? this.filterText,
    childrenByKey: childrenByKey ?? this.childrenByKey,
    tableDetailsByRef: tableDetailsByRef ?? this.tableDetailsByRef,
  );
}

final schemaTreeProvider =
    NotifierProvider.family<SchemaTreeController, SchemaTreeState, String>(
      SchemaTreeController.new,
    );

class SchemaTreeController extends Notifier<SchemaTreeState> {
  SchemaTreeController(this.connectionId);

  final String connectionId;

  @override
  SchemaTreeState build() {
    final connState = ref.watch(connectionSessionProvider(connectionId));
    final sessionId = connState.sessionId;

    if (sessionId != null) {
      Future.microtask(() => _loadRoot(sessionId));
      return SchemaTreeState(
        sessionId: sessionId,
        documentStore:
            connState.session?.capabilities.contains('document_store') ?? false,
        isLoading: true,
      );
    }
    return const SchemaTreeState();
  }

  SchemaRepository get _repo => ref.read(schemaRepositoryProvider);

  Future<void> _loadRoot(String sessionId) async {
    try {
      final dbs = await _repo.listDatabases(sessionId);
      if (state.documentStore) {
        state = state.copyWith(
          isLoading: false,
          childrenByKey: {
            'root': [
              for (final db in dbs) DatabaseNode(key: 'db:$db', label: db),
            ],
          },
        );
      } else if (dbs.isEmpty || (dbs.length == 1 && dbs.first == 'main')) {
        // Single database (like SQLite): load schemas directly
        final schemas = await _repo.listSchemas(sessionId);
        final nodes = <SchemaTreeNode>[
          for (final s in schemas)
            SchemaNamespaceNode(key: 'schema:$s', label: s, database: ''),
        ];
        state = state.copyWith(
          isLoading: false,
          childrenByKey: {'root': nodes},
          expandedKeys: {if (schemas.length == 1) 'schema:${schemas.first}'},
        );
        if (schemas.length == 1) {
          await _loadSchemaObjects(sessionId, '', schemas.first);
        }
      } else {
        // Multiple databases (PostgreSQL)
        final nodes = <SchemaTreeNode>[
          for (final db in dbs) DatabaseNode(key: 'db:$db', label: db),
        ];
        state = state.copyWith(
          isLoading: false,
          childrenByKey: {'root': nodes},
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void setFilter(String text) {
    state = state.copyWith(filterText: text);
  }

  Future<void> toggleExpand(String key) async {
    final expanded = Set<String>.from(state.expandedKeys);
    if (expanded.contains(key)) {
      expanded.remove(key);
      state = state.copyWith(expandedKeys: expanded);
      return;
    }

    expanded.add(key);
    state = state.copyWith(expandedKeys: expanded);

    // If children not loaded yet, fetch them
    if (!state.childrenByKey.containsKey(key)) {
      await _fetchChildren(key);
    }
  }

  Future<void> refresh(String key) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    if (key == 'root') {
      await _repo.refreshSchema(sessionId);
      await _loadRoot(sessionId);
      return;
    }

    if (key.startsWith('table:')) {
      final parts = key.substring(6).split('.');
      final schema = parts.length > 1 ? parts[0] : '';
      final table = parts.length > 1 ? parts[1] : parts[0];
      final ref = TableRef(schema: schema, table: table);
      await _repo.refreshSchema(sessionId, ref);
      await _fetchChildren(key, refresh: true);
    } else {
      await _repo.refreshSchema(sessionId);
      await _fetchChildren(key, refresh: true);
    }
  }

  Future<void> _fetchChildren(String key, {bool refresh = false}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    state = state.copyWith(loadingKeys: {...state.loadingKeys, key});

    try {
      if (key.startsWith('db:') && state.documentStore) {
        final db = key.substring(3);
        final objs = await _repo.listObjects(
          sessionId,
          database: db,
          schema: '',
          refresh: refresh,
        );
        state = state.copyWith(
          childrenByKey: {
            ...state.childrenByKey,
            key: [
              for (final o in objs)
                ObjectNode(
                  key: 'coll:$db/${o.name}',
                  label: o.name,
                  tableRef: TableRef(database: db, table: o.name),
                  type: o.type,
                  rowCountEstimate: o.rowCountEstimate,
                  capped: o.capped,
                ),
            ],
          },
        );
      } else if (key.startsWith('db:')) {
        final db = key.substring(3);
        final schemas = await _repo.listSchemas(
          sessionId,
          database: db,
          refresh: refresh,
        );
        final nodes = <SchemaTreeNode>[
          for (final s in schemas)
            SchemaNamespaceNode(key: 'schema:$db.$s', label: s, database: db),
        ];
        state = state.copyWith(
          childrenByKey: {...state.childrenByKey, key: nodes},
        );
      } else if (key.startsWith('schema:')) {
        final raw = key.substring(7);
        final parts = raw.split('.');
        final db = parts.length > 1 ? parts[0] : '';
        final schema = parts.length > 1 ? parts[1] : parts[0];
        await _loadSchemaObjects(sessionId, db, schema, refresh: refresh);
      } else if (key.startsWith('table:')) {
        final raw = key.substring(6);
        final parts = raw.split('.');
        final schema = parts.length > 1 ? parts[0] : '';
        final table = parts.length > 1 ? parts[1] : parts[0];
        final ref = TableRef(schema: schema, table: table);

        final details = await _repo.getTableDetails(
          sessionId,
          ref,
          refresh: refresh,
        );
        final nodes = <SchemaTreeNode>[
          for (final c in details.columns)
            ColumnNode(
              key: '$key.col.${c.name}',
              label: '${c.name} : ${c.typeName}',
              column: c,
            ),
          for (final idx in details.indexes)
            IndexNode(
              key: '$key.idx.${idx.name}',
              label: '${idx.name} (${idx.columns.join(', ')})',
              index: idx,
            ),
          for (final fk in details.foreignKeys)
            ForeignKeyNode(
              key: '$key.fk.${fk.name}',
              label: '${fk.name} → ${fk.referencedTable}',
              foreignKey: fk,
            ),
        ];

        state = state.copyWith(
          childrenByKey: {...state.childrenByKey, key: nodes},
          tableDetailsByRef: {
            ...state.tableDetailsByRef,
            ref.qualifiedName: details,
          },
        );
      }
    } catch (e) {
      state = state.copyWith(error: e);
    } finally {
      final loading = Set<String>.from(state.loadingKeys)..remove(key);
      state = state.copyWith(loadingKeys: loading);
    }
  }

  Future<void> _loadSchemaObjects(
    String sessionId,
    String db,
    String schema, {
    bool refresh = false,
  }) async {
    final objs = await _repo.listObjects(
      sessionId,
      database: db,
      schema: schema,
      refresh: refresh,
    );
    final key = db.isNotEmpty ? 'schema:$db.$schema' : 'schema:$schema';
    final nodes = <SchemaTreeNode>[
      for (final o in objs)
        ObjectNode(
          key: 'table:$schema.${o.name}',
          label: o.name,
          tableRef: TableRef(database: db, schema: schema, table: o.name),
          type: o.type,
          rowCountEstimate: o.rowCountEstimate,
        ),
    ];
    state = state.copyWith(childrenByKey: {...state.childrenByKey, key: nodes});
  }
}
