import 'package:flutter/foundation.dart';

import 'pipeline_codec.dart';

const groupAccumulators = [
  r'$sum',
  r'$avg',
  r'$min',
  r'$max',
  r'$first',
  r'$last',
  r'$push',
  r'$addToSet',
  r'$count',
  r'$stdDevPop',
  r'$stdDevSamp',
];

const matchOperators = [
  'eq',
  r'$ne',
  r'$gt',
  r'$gte',
  r'$lt',
  r'$lte',
  r'$in',
  r'$nin',
  r'$exists',
];

@immutable
sealed class StageForm {
  const StageForm();

  Object? toBody();
}

int? _wholeNumber(Object? v) {
  if (v is int) return v;
  if (v is double && v == v.truncateToDouble()) return v.toInt();
  if (v is Map && v.length == 1) {
    final inner = v.values.single;
    if (v.keys.single == r'$numberInt' || v.keys.single == r'$numberLong') {
      return int.tryParse('$inner');
    }
  }
  return null;
}

String _text(Object? v) => toShellLiteral(v);

Object? _value(String text) => parseLiteralOrString(text);

final class CountLimitForm extends StageForm {
  const CountLimitForm(this.value);
  final int value;

  @override
  Object? toBody() => value;
}

final class CountForm extends StageForm {
  const CountForm(this.field);
  final String field;

  @override
  Object? toBody() => field;
}

final class UnwindForm extends StageForm {
  const UnwindForm({
    this.path = '',
    this.preserveNullAndEmpty = false,
    this.indexField = '',
  });

  final String path;
  final bool preserveNullAndEmpty;
  final String indexField;

  @override
  Object? toBody() {
    final fieldPath = '\$$path';
    if (!preserveNullAndEmpty && indexField.isEmpty) return fieldPath;
    return {
      'path': fieldPath,
      if (indexField.isNotEmpty) 'includeArrayIndex': indexField,
      if (preserveNullAndEmpty) 'preserveNullAndEmptyArrays': true,
    };
  }
}

@immutable
class SortRow {
  const SortRow(this.field, {this.ascending = true});
  final String field;
  final bool ascending;
}

final class SortForm extends StageForm {
  const SortForm(this.rows);
  final List<SortRow> rows;

  @override
  Object? toBody() => {for (final r in rows) r.field: r.ascending ? 1 : -1};
}

@immutable
class ProjectRow {
  const ProjectRow(this.field, {this.include = true});
  final String field;
  final bool include;
}

final class ProjectForm extends StageForm {
  const ProjectForm(this.rows);
  final List<ProjectRow> rows;

  @override
  Object? toBody() => {for (final r in rows) r.field: r.include ? 1 : 0};
}

@immutable
class ExpressionRow {
  const ExpressionRow(this.field, this.expression);
  final String field;
  final String expression;
}

final class AddFieldsForm extends StageForm {
  const AddFieldsForm(this.rows);
  final List<ExpressionRow> rows;

  @override
  Object? toBody() => {for (final r in rows) r.field: _value(r.expression)};
}

@immutable
class AccumulatorRow {
  const AccumulatorRow(this.field, this.accumulator, this.expression);
  final String field;
  final String accumulator;
  final String expression;
}

final class GroupForm extends StageForm {
  const GroupForm({this.idExpression = 'null', this.accumulators = const []});
  final String idExpression;
  final List<AccumulatorRow> accumulators;

  @override
  Object? toBody() => {
    '_id': _value(idExpression),
    for (final a in accumulators)
      a.field: {
        a.accumulator: a.accumulator == r'$count'
            ? <String, Object?>{}
            : _value(a.expression),
      },
  };
}

@immutable
class MatchRow {
  const MatchRow(this.field, this.operator, this.value);
  final String field;
  final String operator;
  final String value;
}

final class MatchForm extends StageForm {
  const MatchForm(this.rows);
  final List<MatchRow> rows;

  @override
  Object? toBody() {
    final byField = <String, List<MatchRow>>{};
    for (final r in rows) {
      byField.putIfAbsent(r.field, () => []).add(r);
    }
    return {
      for (final e in byField.entries)
        e.key: e.value.length == 1 && e.value.single.operator == 'eq'
            ? _value(e.value.single.value)
            : {
                for (final r in e.value)
                  (r.operator == 'eq' ? r'$eq' : r.operator): _value(r.value),
              },
    };
  }
}

final class LookupForm extends StageForm {
  const LookupForm({
    this.from = '',
    this.localField = '',
    this.foreignField = '',
    this.as = '',
  });

  final String from;
  final String localField;
  final String foreignField;
  final String as;

  @override
  Object? toBody() => {
    'from': from,
    'localField': localField,
    'foreignField': foreignField,
    'as': as,
  };
}

StageForm emptyStageForm(String operator) => switch (operator) {
  r'$match' => const MatchForm([]),
  r'$group' => const GroupForm(),
  r'$project' => const ProjectForm([]),
  r'$sort' => const SortForm([]),
  r'$limit' => const CountLimitForm(20),
  r'$skip' => const CountLimitForm(0),
  r'$unwind' => const UnwindForm(),
  r'$lookup' => const LookupForm(),
  r'$addFields' => const AddFieldsForm([]),
  r'$count' => const CountForm('count'),
  _ => throw ArgumentError('No form for $operator'),
};

Object? defaultStageBody(String operator) =>
    operator.isNotEmpty && _isTyped(operator)
    ? emptyStageForm(operator).toBody()
    : <String, Object?>{};

bool _isTyped(String operator) => const {
  r'$match', r'$group', r'$project', r'$sort', r'$limit', r'$skip', //
  r'$unwind', r'$lookup', r'$addFields', r'$count',
}.contains(operator);

StageForm? decodeStageForm(String operator, Object? body) {
  switch (operator) {
    case r'$limit' || r'$skip':
      final n = _wholeNumber(body);
      return n == null || n < 0 ? null : CountLimitForm(n);
    case r'$count':
      return body is String && body.isNotEmpty ? CountForm(body) : null;
    case r'$unwind':
      return _decodeUnwind(body);
    case r'$sort':
      return _decodeSort(body);
    case r'$project':
      return _decodeProject(body);
    case r'$addFields':
      return body is Map
          ? AddFieldsForm([
              for (final e in body.entries)
                ExpressionRow('${e.key}', _text(e.value)),
            ])
          : null;
    case r'$group':
      return _decodeGroup(body);
    case r'$match':
      return _decodeMatch(body);
    case r'$lookup':
      return _decodeLookup(body);
  }
  return null;
}

StageForm? _decodeUnwind(Object? body) {
  if (body is String) {
    return body.startsWith(r'$') ? UnwindForm(path: body.substring(1)) : null;
  }
  if (body is! Map) return null;
  final path = body['path'];
  final preserve = body['preserveNullAndEmptyArrays'];
  final index = body['includeArrayIndex'];
  final known = body.keys.every(
    (k) =>
        k == 'path' ||
        k == 'preserveNullAndEmptyArrays' ||
        k == 'includeArrayIndex',
  );
  if (!known || path is! String || !path.startsWith(r'$')) return null;
  if ((preserve != null && preserve is! bool) ||
      (index != null && index is! String)) {
    return null;
  }
  return UnwindForm(
    path: path.substring(1),
    preserveNullAndEmpty: preserve == true,
    indexField: (index as String?) ?? '',
  );
}

StageForm? _decodeSort(Object? body) {
  if (body is! Map) return null;
  final rows = <SortRow>[];
  for (final e in body.entries) {
    final n = _wholeNumber(e.value);
    if (n != 1 && n != -1) return null;
    rows.add(SortRow('${e.key}', ascending: n == 1));
  }
  return SortForm(rows);
}

StageForm? _decodeProject(Object? body) {
  if (body is! Map) return null;
  final rows = <ProjectRow>[];
  for (final e in body.entries) {
    final v = e.value;
    final include = v is bool
        ? v
        : (_wholeNumber(v) == null ? null : _wholeNumber(v) != 0);
    if (include == null) return null;
    rows.add(ProjectRow('${e.key}', include: include));
  }
  return ProjectForm(rows);
}

StageForm? _decodeGroup(Object? body) {
  if (body is! Map || !body.containsKey('_id')) return null;
  final rows = <AccumulatorRow>[];
  for (final e in body.entries) {
    if (e.key == '_id') continue;
    final v = e.value;
    if (v is! Map || v.length != 1) return null;
    final op = '${v.keys.single}';
    if (!groupAccumulators.contains(op)) return null;
    final expression = op == r'$count' ? '{}' : _text(v.values.single);
    if (op == r'$count' && v.values.single is! Map) return null;
    rows.add(AccumulatorRow('${e.key}', op, expression));
  }
  return GroupForm(idExpression: _text(body['_id']), accumulators: rows);
}

StageForm? _decodeMatch(Object? body) {
  if (body is! Map) return null;
  final rows = <MatchRow>[];
  for (final e in body.entries) {
    final field = '${e.key}';
    if (field.startsWith(r'$')) return null;
    final v = e.value;
    final isOperatorMap =
        v is Map && v.isNotEmpty && v.keys.every((k) => '$k'.startsWith(r'$'));
    if (!isOperatorMap) {
      rows.add(MatchRow(field, 'eq', _text(v)));
      continue;
    }
    for (final op in v.entries) {
      final key = '${op.key}' == r'$eq' ? 'eq' : '${op.key}';
      if (!matchOperators.contains(key)) return null;
      rows.add(MatchRow(field, key, _text(op.value)));
    }
  }
  return MatchForm(rows);
}

StageForm? _decodeLookup(Object? body) {
  if (body is! Map) return null;
  const keys = {'from', 'localField', 'foreignField', 'as'};
  if (!body.keys.every(keys.contains) ||
      !body.values.every((v) => v is String)) {
    return null;
  }
  return LookupForm(
    from: (body['from'] as String?) ?? '',
    localField: (body['localField'] as String?) ?? '',
    foreignField: (body['foreignField'] as String?) ?? '',
    as: (body['as'] as String?) ?? '',
  );
}
