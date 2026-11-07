import '../../schema/domain/schema_models.dart';

class ColumnDraft {
  const ColumnDraft({
    required this.name,
    this.typeName = '',
    this.nullable = true,
    this.defaultExpression,
    this.identity = false,
    this.primaryKey = false,
    this.originalName,
  });

  factory ColumnDraft.fromDetails(ColumnDetails c) => ColumnDraft(
    name: c.name,
    typeName: c.typeName,
    nullable: c.nullable,
    defaultExpression: c.defaultValue,
    identity: c.identity,
    primaryKey: c.isPrimaryKey,
    originalName: c.name,
  );

  final String name;
  final String typeName;
  final bool nullable;
  final String? defaultExpression;
  final bool identity;
  final bool primaryKey;

  /// Name on the server; null for a column added in the designer.
  final String? originalName;

  ColumnDraft copyWith({
    String? name,
    String? typeName,
    bool? nullable,
    String? defaultExpression,
    bool clearDefault = false,
    bool? identity,
    bool? primaryKey,
  }) => ColumnDraft(
    name: name ?? this.name,
    typeName: typeName ?? this.typeName,
    nullable: nullable ?? this.nullable,
    defaultExpression: clearDefault
        ? null
        : (defaultExpression ?? this.defaultExpression),
    identity: identity ?? this.identity,
    primaryKey: primaryKey ?? this.primaryKey,
    originalName: originalName,
  );
}

sealed class SchemaChangeModel {
  const SchemaChangeModel();
}

class CreateTableChange extends SchemaChangeModel {
  const CreateTableChange(this.columns);

  final List<ColumnDraft> columns;
}

class AddColumnChange extends SchemaChangeModel {
  const AddColumnChange(this.column);

  final ColumnDraft column;
}

class DropColumnChange extends SchemaChangeModel {
  const DropColumnChange(this.name);

  final String name;
}

class RenameColumnChange extends SchemaChangeModel {
  const RenameColumnChange(this.from, this.to);

  final String from;
  final String to;
}

class AlterColumnChange extends SchemaChangeModel {
  const AlterColumnChange(this.before, this.after);

  final ColumnDraft before;
  final ColumnDraft after;
}

class DdlStatementModel {
  const DdlStatementModel({
    required this.sql,
    required this.destructive,
    required this.summary,
  });

  final String sql;
  final bool destructive;
  final String summary;
}

class DdlPreview {
  const DdlPreview({
    required this.statements,
    this.warnings = const [],
    this.transactional = true,
  });

  final List<DdlStatementModel> statements;
  final List<String> warnings;
  final bool transactional;

  bool get hasDestructive => statements.any((s) => s.destructive);
}

class DdlApplied {
  const DdlApplied({
    required this.statements,
    required this.executed,
    required this.transactional,
  });

  final List<DdlStatementModel> statements;
  final int executed;
  final bool transactional;
}

/// Turns the designer's columns into ordered changes: renames, alters, adds,
/// then drops. A new table is a single create.
List<SchemaChangeModel> diffDesign({
  TableDetails? original,
  required List<ColumnDraft> columns,
}) {
  if (original == null) return [CreateTableChange(columns)];
  final before = {
    for (final c in original.columns) c.name: ColumnDraft.fromDetails(c),
  };
  final renames = <SchemaChangeModel>[];
  final alters = <SchemaChangeModel>[];
  final adds = <SchemaChangeModel>[];
  final kept = <String>{};
  for (final c in columns) {
    final from = c.originalName;
    final old = from == null ? null : before[from];
    if (old == null) {
      adds.add(AddColumnChange(c));
      continue;
    }
    kept.add(old.name);
    if (c.name != old.name) renames.add(RenameColumnChange(old.name, c.name));
    final changed =
        c.typeName != old.typeName ||
        c.nullable != old.nullable ||
        c.defaultExpression != old.defaultExpression;
    if (changed) {
      alters.add(
        AlterColumnChange(
          old.copyWith(name: c.name),
          c.copyWith(identity: old.identity),
        ),
      );
    }
  }
  final drops = [
    for (final name in before.keys)
      if (!kept.contains(name)) DropColumnChange(name),
  ];
  return [...renames, ...alters, ...adds, ...drops];
}
