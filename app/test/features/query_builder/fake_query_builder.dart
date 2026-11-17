import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/query_builder/data/query_builder_repository.dart';
import 'package:queravue/features/query_builder/domain/sql_query_models.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

class FakeQueryBuilderRepository implements QueryBuilderRepository {
  final generatedModels = <SqlQueryDraft>[];
  final parsedInputs = <String>[];

  QueryBuilderException? generateError;
  QueryBuilderException? parseError;
  ParseSqlOutcome? nextParseOutcome;

  @override
  Future<String> generateSql({
    required String sessionId,
    required SqlQueryDraft model,
  }) async {
    generatedModels.add(model);
    if (generateError != null) throw generateError!;
    return renderSqlPreview(model);
  }

  @override
  Future<ParseSqlOutcome> parseSql({
    required String sessionId,
    required String sql,
  }) async {
    parsedInputs.add(sql);
    if (parseError != null) throw parseError!;
    if (nextParseOutcome != null) return nextParseOutcome!;
    return const ParseSqlOutcome(
      model: SqlQueryDraft(
        from: SqlTableRefModel(schema: 'public', table: 'orders', alias: 'o'),
      ),
      commentsDropped: false,
    );
  }

  static String renderSqlPreview(SqlQueryDraft m) {
    final from = m.from;
    if (from == null || from.table.isEmpty) return '';
    final selectStr = m.select.isEmpty
        ? '*'
        : m.select
              .map((s) {
                final expr = s.aggregate != null
                    ? s.aggregate!.display
                    : s.column!.display;
                return s.alias.isEmpty ? expr : '$expr AS "${s.alias}"';
              })
              .join(', ');
    final distinctStr = m.distinct ? 'DISTINCT ' : '';
    final buf = StringBuffer('SELECT $distinctStr$selectStr FROM ');
    buf.write(from.qualifiedName);
    if (from.alias.isNotEmpty) buf.write(' AS ${from.alias}');
    for (final j in m.joins) {
      buf.write(' ${j.kind.label} ${j.table.qualifiedName}');
      if (j.table.alias.isNotEmpty) buf.write(' AS ${j.table.alias}');
      buf.write(' ON ${_renderCond(j.on)}');
    }
    if (m.where != null) {
      buf.write(' WHERE ${_renderCond(m.where!)}');
    }
    if (m.groupBy.isNotEmpty) {
      buf.write(' GROUP BY ${m.groupBy.map((c) => c.display).join(', ')}');
    }
    if (m.having != null) {
      buf.write(' HAVING ${_renderCond(m.having!)}');
    }
    if (m.orderBy.isNotEmpty) {
      buf.write(
        ' ORDER BY ${m.orderBy.map((o) => '${_renderOperand(o.expression)} ${o.descending ? 'DESC' : 'ASC'}').join(', ')}',
      );
    }
    if (m.limit != null) buf.write(' LIMIT ${m.limit}');
    if (m.offset != null) buf.write(' OFFSET ${m.offset}');
    return buf.toString();
  }

  static String _renderCond(SqlConditionNode node) => switch (node) {
    SqlComparisonModel(:final left, :final op, :final operands, :final negated) =>
      '${negated ? 'NOT ' : ''}${_renderOperand(left)} ${op.label}${operands.isEmpty ? '' : ' ${operands.map(_renderOperand).join(', ')}'}',
    SqlConditionGroupModel(:final op, :final children, :final negated) =>
      '${negated ? 'NOT (' : ''}${children.map(_renderCond).join(' ${op.label} ')}${negated ? ')' : ''}',
  };

  static String _renderOperand(SqlOperandModel op) => switch (op) {
    SqlColumnOperand(:final column) => column.display,
    SqlAggregateOperand(:final aggregate) => aggregate.display,
    SqlLiteralOperand(:final literal) => switch (literal) {
      SqlNullLiteral() => 'NULL',
      SqlBoolLiteral(:final value) => value ? 'TRUE' : 'FALSE',
      SqlIntLiteral(:final value) => '$value',
      SqlDoubleLiteral(:final value) => '$value',
      SqlStringLiteral(:final value) => "'$value'",
    },
  };
}

class FakeBuilderSchemaRepository implements SchemaRepository {
  @override
  Future<List<String>> listDatabases(
    String sessionId, {
    bool refresh = false,
  }) async => const ['queravue'];

  @override
  Future<List<String>> listSchemas(
    String sessionId, {
    String? database,
    bool refresh = false,
  }) async => const ['public'];

  @override
  Future<List<SchemaObject>> listObjects(
    String sessionId, {
    String? database,
    required String schema,
    bool refresh = false,
  }) async => const [
    SchemaObject(name: 'customers', type: SchemaObjectType.table),
    SchemaObject(name: 'orders', type: SchemaObjectType.table),
  ];

  @override
  Future<TableDetails> getTableDetails(
    String sessionId,
    TableRef tableRef, {
    bool refresh = false,
  }) async {
    if (tableRef.table == 'orders') {
      return TableDetails(
        tableRef: tableRef,
        type: SchemaObjectType.table,
        canEdit: true,
        columns: const [
          ColumnDetails(
            name: 'id',
            typeName: 'int4',
            kind: ColumnKind.integer,
            nullable: false,
            isPrimaryKey: true,
          ),
          ColumnDetails(
            name: 'customer_id',
            typeName: 'int4',
            kind: ColumnKind.integer,
            nullable: false,
            isPrimaryKey: false,
          ),
          ColumnDetails(
            name: 'status',
            typeName: 'text',
            kind: ColumnKind.text,
            nullable: false,
            isPrimaryKey: false,
          ),
          ColumnDetails(
            name: 'total',
            typeName: 'numeric',
            kind: ColumnKind.decimal,
            nullable: false,
            isPrimaryKey: false,
          ),
        ],
        foreignKeys: const [
          ForeignKeyDetails(
            name: 'fk_orders_customer',
            columns: ['customer_id'],
            referencedSchema: 'public',
            referencedTable: 'customers',
            referencedColumns: ['id'],
          ),
        ],
      );
    }
    return TableDetails(
      tableRef: tableRef,
      type: SchemaObjectType.table,
      canEdit: true,
      columns: const [
        ColumnDetails(
          name: 'id',
          typeName: 'int4',
          kind: ColumnKind.integer,
          nullable: false,
          isPrimaryKey: true,
        ),
        ColumnDetails(
          name: 'name',
          typeName: 'text',
          kind: ColumnKind.text,
          nullable: false,
          isPrimaryKey: false,
        ),
      ],
    );
  }

  @override
  Future<void> refreshSchema(String sessionId, [TableRef? tableRef]) async {}
}
