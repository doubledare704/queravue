import 'package:flutter/foundation.dart';

import '../../designer/domain/design_models.dart';
import '../../schema/domain/schema_models.dart';
import 'diagram_models.dart';

/// A table designed on the diagram; the column order is the primary key order.
@immutable
class DraftTable {
  const DraftTable({required this.name, required this.columns});

  final String name;
  final List<ColumnDraft> columns;

  DraftTable renamed(String to) => DraftTable(name: to, columns: columns);
}

/// A reference drawn on the diagram: [columns] of [fromTable] point at
/// [toColumns] of [toTable], in key order. [newColumns] are added to
/// [fromTable] for it, in the same order.
@immutable
class DraftRelation {
  const DraftRelation({
    required this.name,
    required this.fromTable,
    required this.columns,
    required this.toTable,
    required this.toColumns,
    this.newColumns = const [],
    this.onDelete = ReferentialAction.unspecified,
  });

  final String name;
  final String fromTable;
  final List<String> columns;
  final String toTable;
  final List<String> toColumns;
  final List<ColumnDraft> newColumns;
  final ReferentialAction onDelete;

  DraftRelation _renaming(String from, String to) => DraftRelation(
    name: name,
    fromTable: fromTable == from ? to : fromTable,
    columns: columns,
    toTable: toTable == from ? to : toTable,
    toColumns: toColumns,
    newColumns: newColumns,
    onDelete: onDelete,
  );
}

/// Changes to one table, in order, as the core takes them.
@immutable
class TableChangesModel {
  const TableChangesModel(this.table, this.changes);

  final TableRef table;
  final List<SchemaChangeModel> changes;
}

/// Tables and relations designed on a diagram and not applied yet.
@immutable
class DiagramDraft {
  const DiagramDraft({this.tables = const [], this.relations = const []});

  final List<DraftTable> tables;
  final List<DraftRelation> relations;

  bool get isEmpty => tables.isEmpty && relations.isEmpty;

  int get size => tables.length + relations.length;

  DraftTable? table(String name) =>
      tables.where((t) => t.name == name).firstOrNull;

  /// Adds [table], or puts it in place of the draft table named [replacing]
  /// and moves that table's relations along with a new name.
  DiagramDraft withTable(DraftTable table, {String? replacing}) {
    if (replacing == null) {
      return DiagramDraft(tables: [...tables, table], relations: relations);
    }
    return DiagramDraft(
      tables: [for (final t in tables) t.name == replacing ? table : t],
      relations: [
        for (final r in relations) r._renaming(replacing, table.name),
      ],
    );
  }

  /// Drops the draft table [name] and every drafted relation from or to it.
  DiagramDraft withoutTable(String name) => DiagramDraft(
    tables: [
      for (final t in tables)
        if (t.name != name) t,
    ],
    relations: [
      for (final r in relations)
        if (r.fromTable != name && r.toTable != name) r,
    ],
  );

  DiagramDraft withRelation(DraftRelation relation) =>
      DiagramDraft(tables: tables, relations: [...relations, relation]);

  DiagramDraft withoutRelation(DraftRelation relation) => DiagramDraft(
    tables: tables,
    relations: [
      for (final r in relations)
        if (!identical(r, relation)) r,
    ],
  );

  List<DraftRelation> relationsFrom(String table) => [
    for (final r in relations)
      if (r.fromTable == table) r,
  ];

  Map<String, Object?> toJson() => {
    'tables': [for (final t in tables) _tableJson(t)],
    'relations': [for (final r in relations) _relationJson(r)],
  };

  /// Null when [json] is not a draft.
  static DiagramDraft? fromJson(Object? json) {
    if (json == null) return const DiagramDraft();
    if (json is! Map<String, Object?>) return null;
    final tables = json['tables'] ?? const <Object?>[];
    final relations = json['relations'] ?? const <Object?>[];
    if (tables is! List || relations is! List) return null;
    final draftTables = <DraftTable>[];
    for (final t in tables) {
      final table = _tableFromJson(t);
      if (table == null) return null;
      draftTables.add(table);
    }
    final draftRelations = <DraftRelation>[];
    for (final r in relations) {
      final relation = _relationFromJson(r);
      if (relation == null) return null;
      draftRelations.add(relation);
    }
    return DiagramDraft(tables: draftTables, relations: draftRelations);
  }
}

Map<String, Object?> _columnJson(ColumnDraft c) => {
  'name': c.name,
  'type': c.typeName,
  if (!c.nullable) 'nullable': false,
  if (c.primaryKey) 'primaryKey': true,
  if (c.identity) 'identity': true,
  if (c.defaultExpression != null) 'default': c.defaultExpression,
};

ColumnDraft? _columnFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final name = json['name'], type = json['type'], dflt = json['default'];
  if (name is! String || type is! String) return null;
  return ColumnDraft(
    name: name,
    typeName: type,
    nullable: json['nullable'] != false,
    primaryKey: json['primaryKey'] == true,
    identity: json['identity'] == true,
    defaultExpression: dflt is String ? dflt : null,
  );
}

Map<String, Object?> _tableJson(DraftTable t) => {
  'name': t.name,
  'columns': [for (final c in t.columns) _columnJson(c)],
};

DraftTable? _tableFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final name = json['name'], columns = json['columns'];
  if (name is! String || columns is! List) return null;
  final parsed = <ColumnDraft>[];
  for (final c in columns) {
    final column = _columnFromJson(c);
    if (column == null) return null;
    parsed.add(column);
  }
  return DraftTable(name: name, columns: parsed);
}

Map<String, Object?> _relationJson(DraftRelation r) => {
  'name': r.name,
  'from': r.fromTable,
  'columns': r.columns,
  'to': r.toTable,
  'toColumns': r.toColumns,
  if (r.newColumns.isNotEmpty)
    'newColumns': [for (final c in r.newColumns) _columnJson(c)],
  if (r.onDelete != ReferentialAction.unspecified) 'onDelete': r.onDelete.name,
};

List<String>? _names(Object? list, Object? single) => switch ((list, single)) {
  (final List<Object?> l, _) when l.isNotEmpty && l.every((n) => n is String) =>
    l.cast<String>(),
  (null, final String s) => [s],
  _ => null,
};

// Diagrams saved before composite keys hold one column, in the singular fields.
List<ColumnDraft>? _newColumnsFromJson(Map<String, Object?> json) {
  final list = json['newColumns'] ?? [?json['newColumn']];
  if (list is! List) return null;
  final parsed = <ColumnDraft>[];
  for (final c in list) {
    final column = _columnFromJson(c);
    if (column == null) return null;
    parsed.add(column);
  }
  return parsed;
}

DraftRelation? _relationFromJson(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final name = json['name'], from = json['from'], to = json['to'];
  final columns = _names(json['columns'], json['column']);
  final toColumns = _names(json['toColumns'], json['toColumn']);
  final newColumns = _newColumnsFromJson(json);
  if (name is! String ||
      from is! String ||
      to is! String ||
      columns == null ||
      toColumns == null ||
      columns.length != toColumns.length ||
      newColumns == null) {
    return null;
  }
  return DraftRelation(
    name: name,
    fromTable: from,
    columns: columns,
    toTable: to,
    toColumns: toColumns,
    newColumns: newColumns,
    onDelete:
        ReferentialAction.values
            .where((a) => a.name == json['onDelete'])
            .firstOrNull ??
        ReferentialAction.unspecified,
  );
}

DiagramColumn _drawn(ColumnDraft c, int primaryKeyOrder) => DiagramColumn(
  name: c.name,
  typeName: c.typeName,
  nullable: c.nullable,
  primaryKeyOrder: primaryKeyOrder,
  draft: true,
);

DiagramRelation _drawnRelation(DraftRelation r) => DiagramRelation(
  name: r.name,
  columns: r.columns,
  referencedTable: r.toTable,
  referencedColumns: r.toColumns,
  draft: true,
);

/// [graph] with the draft drawn in: new tables at the end, new columns and
/// relations on the tables they belong to.
SchemaGraph graphWithDraft(SchemaGraph graph, DiagramDraft draft) {
  if (draft.isEmpty) return graph;
  List<DiagramColumn> addedColumns(String table) => [
    for (final r in draft.relationsFrom(table))
      for (final c in r.newColumns) _drawn(c, 0),
  ];
  List<DiagramRelation> addedRelations(String table) => [
    for (final r in draft.relationsFrom(table)) _drawnRelation(r),
  ];
  return SchemaGraph([
    for (final t in graph.tables)
      if (draft.relationsFrom(t.name).isEmpty)
        t
      else
        DiagramTable(
          name: t.name,
          type: t.type,
          rowEstimate: t.rowEstimate,
          columns: [...t.columns, ...addedColumns(t.name)],
          relations: [...t.relations, ...addedRelations(t.name)],
          columnsTruncated: t.columnsTruncated,
        ),
    for (final t in draft.tables)
      DiagramTable(
        name: t.name,
        columns: [
          for (final (i, c) in _withKeyOrder(t.columns)) _drawn(c, i),
          ...addedColumns(t.name),
        ],
        relations: addedRelations(t.name),
        draft: true,
      ),
  ]);
}

Iterable<(int, ColumnDraft)> _withKeyOrder(List<ColumnDraft> columns) sync* {
  var order = 0;
  for (final c in columns) {
    yield (c.primaryKey ? ++order : 0, c);
  }
}

ForeignKeyDraft _foreignKey(DraftRelation r, String schema) => ForeignKeyDraft(
  name: r.name,
  columns: r.columns,
  referencedSchema: schema,
  referencedTable: r.toTable,
  referencedColumns: r.toColumns,
  onDelete: r.onDelete,
);

/// The draft as changes per table: a create for each new table with its
/// relations, and added columns and foreign keys on existing tables. The
/// core orders them.
List<TableChangesModel> draftChanges(
  DiagramDraft draft, {
  String database = '',
  String schema = '',
}) {
  TableRef ref(String table) =>
      TableRef(database: database, schema: schema, table: table);
  final drafted = {for (final t in draft.tables) t.name};
  final existing = <String>{
    for (final r in draft.relations)
      if (!drafted.contains(r.fromTable)) r.fromTable,
  };
  return [
    for (final t in draft.tables)
      TableChangesModel(ref(t.name), [
        CreateTableChange(
          [
            ...t.columns,
            for (final r in draft.relationsFrom(t.name)) ...r.newColumns,
          ],
          constraints: ConstraintDrafts(
            foreignKeys: [
              for (final r in draft.relationsFrom(t.name))
                _foreignKey(r, schema),
            ],
          ),
        ),
      ]),
    for (final table in existing)
      TableChangesModel(ref(table), [
        for (final r in draft.relationsFrom(table))
          for (final c in r.newColumns) AddColumnChange(c),
        for (final r in draft.relationsFrom(table))
          AddForeignKeyChange(_foreignKey(r, schema)),
      ]),
  ];
}

/// Why [table] cannot be part of the draft, or null. [taken] holds the
/// names of every other table on the diagram.
String? draftTableProblem(DraftTable table, Set<String> taken) {
  final name = table.name.trim();
  if (name.isEmpty) return 'The table needs a name.';
  if (taken.contains(name)) {
    return 'A table named $name is already on the diagram.';
  }
  if (table.columns.isEmpty) return 'The table needs at least one column.';
  final seen = <String>{};
  for (final c in table.columns) {
    final column = c.name.trim();
    if (column.isEmpty) return 'Every column needs a name.';
    if (!seen.add(column)) return 'Column $column is listed twice.';
    if (c.typeName.trim().isEmpty) return 'Column $column needs a type.';
  }
  return null;
}

/// Why [to] cannot be referenced from the diagram, or null.
String? referenceProblem(DiagramTable to) => to.primaryKey.isEmpty
    ? '${to.name} has no primary key to reference.'
    : null;

/// Why the columns in [through] cannot carry one reference, or null.
String? throughProblem(List<String?> through) {
  final seen = <String>{};
  for (final column in through.nonNulls) {
    if (!seen.add(column)) {
      return 'Column $column is picked for two key columns.';
    }
  }
  return null;
}

/// Per key column of [to], the column of [from] named `<to>_<key>`, or null
/// when [from] has none and a new one is to be added.
List<String?> suggestedThrough(DiagramTable from, DiagramTable to) => [
  for (final k in to.primaryKey)
    from.column(_referencingName(to, k)) != null
        ? _referencingName(to, k)
        : null,
];

/// A reference from [from] to [to]'s primary key, through the columns
/// [suggestedThrough] picks.
DraftRelation suggestRelation(
  DiagramTable from,
  DiagramTable to, {
  Set<String> takenNames = const {},
  ReferentialAction onDelete = ReferentialAction.unspecified,
}) => relationThrough(
  from,
  to,
  suggestedThrough(from, to),
  takenNames: takenNames,
  onDelete: onDelete,
);

/// A reference from [from] to [to]'s primary key. [through] holds, per key
/// column, the column of [from] that carries it, or null for a new column
/// named after the key. [takenNames] holds the constraint names already drawn.
DraftRelation relationThrough(
  DiagramTable from,
  DiagramTable to,
  List<String?> through, {
  Set<String> takenNames = const {},
  ReferentialAction onDelete = ReferentialAction.unspecified,
}) {
  final key = to.primaryKey;
  final used = {for (final c in from.columns) c.name, ...through.nonNulls};
  String freeName(String base) {
    var name = base;
    for (var n = 2; used.contains(name); n++) {
      name = '${base}_$n';
    }
    used.add(name);
    return name;
  }

  final columns = <String>[];
  final newColumns = <ColumnDraft>[];
  for (final (i, k) in key.indexed) {
    final existing = i < through.length ? through[i] : null;
    if (existing != null) {
      columns.add(existing);
      continue;
    }
    final column = ColumnDraft(
      name: freeName(_referencingName(to, k)),
      typeName: _referencingType(k.typeName),
    );
    columns.add(column.name);
    newColumns.add(column);
  }
  var name = 'fk_${from.name}_${to.name}';
  for (var n = 2; takenNames.contains(name); n++) {
    name = 'fk_${from.name}_${to.name}_$n';
  }
  return DraftRelation(
    name: name,
    fromTable: from.name,
    columns: columns,
    toTable: to.name,
    toColumns: [for (final k in key) k.name],
    newColumns: newColumns,
    onDelete: onDelete,
  );
}

/// One sentence on what [relation] adds to [from] or reuses there.
String describeRelation(DraftRelation relation, String from) {
  final steps = [
    for (final c in relation.columns)
      if (relation.newColumns.where((n) => n.name == c).firstOrNull
          case final added?)
        'adds column ${added.name} ${added.typeName}'
      else
        'uses column $c',
  ];
  final first = steps.join(', ');
  final target = relation.toColumns.length == 1
      ? '${relation.toTable}.${relation.toColumns.single}'
      : '${relation.toTable} (${relation.toColumns.join(', ')})';
  final where = relation.newColumns.isEmpty ? 'of' : 'to';
  return '${first[0].toUpperCase()}${first.substring(1)} $where $from, '
      'referencing $target.';
}

String _referencingName(DiagramTable to, DiagramColumn key) =>
    '${to.name}_${key.name}';

// A serial or identity key is referenced by a plain integer of the same width.
String _referencingType(String keyType) => switch (keyType.toLowerCase()) {
  'serial' => 'integer',
  'bigserial' => 'bigint',
  'smallserial' => 'smallint',
  _ => keyType,
};
