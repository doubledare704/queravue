import 'dart:convert';

import '../../domain/ejson.dart';
import 'pipeline_stage.dart';
import 'relaxed_parser.dart';

class PipelineImport {
  const PipelineImport({
    required this.stages,
    this.collection,
    this.keptAsRaw = 0,
    this.ignoredTrailing = false,
  });

  final List<PipelineStage> stages;
  final String? collection;
  final int keptAsRaw;
  final bool ignoredTrailing;
}

final _shellCallPrefix = RegExp(
  r'''^db\s*(?:\.\s*getCollection\(\s*(["'])(.*?)\1\s*\)|\[\s*(["'])(.*?)\3\s*\]|\.\s*([A-Za-z_$][\w$]*))\s*\.\s*aggregate\s*\(''',
);

PipelineImport importPipeline(String text) {
  final trimmed = text.trim();
  var start = 0;
  String? collection;
  final call = _shellCallPrefix.firstMatch(trimmed);
  if (call != null) {
    collection = call.group(2) ?? call.group(4) ?? call.group(5);
    start = call.end;
  }
  final parser = RelaxedEjsonParser(trimmed, start: start);
  parser.skipTrivia();
  if (!trimmed.startsWith('[', parser.position)) {
    throw const FormatException(
      'Expected a pipeline: an array of stages, or db.<collection>.aggregate([...]).',
    );
  }
  var keptAsRaw = 0;
  final elements = parser.parseArrayElementsLeniently((_) {});
  final stages = <PipelineStage>[];
  for (final element in elements) {
    final stage = _stageOf(element);
    if (stage.isUnparsed) keptAsRaw++;
    stages.add(stage);
  }
  final rest = trimmed
      .substring(parser.position)
      .replaceAll(RegExp(r'[\s);]'), '');
  return PipelineImport(
    stages: stages,
    collection: collection,
    keptAsRaw: keptAsRaw,
    ignoredTrailing: rest.isNotEmpty,
  );
}

PipelineStage _stageOf(Object? element) {
  if (isFailedElement(element)) {
    return PipelineStage.unparsed(failedElementText(element));
  }
  if (element is Map && element.length == 1) {
    final key = element.keys.single as String;
    if (key.startsWith(r'$')) return PipelineStage.of(key, element[key]);
  }
  return PipelineStage.unparsed(jsonEncode(element));
}

List<PipelineStage> enabledStages(List<PipelineStage> stages) => [
  for (final s in stages)
    if (s.enabled) s,
];

String _stageJson(PipelineStage s) =>
    s.isUnparsed ? s.unparsedText! : jsonEncode({s.operator: s.body});

String pipelineToJson(List<PipelineStage> stages) {
  final lines = [for (final s in enabledStages(stages)) '  ${_stageJson(s)}'];
  return lines.isEmpty ? '[]' : '[\n${lines.join(',\n')}\n]';
}

String pipelineToShellArray(List<PipelineStage> stages) {
  final lines = [
    for (final s in enabledStages(stages))
      '  ${s.isUnparsed ? s.unparsedText! : '{ ${s.operator}: ${toShellLiteral(s.body)} }'}',
  ];
  return lines.isEmpty ? '[]' : '[\n${lines.join(',\n')}\n]';
}

String pipelineToShell(String collection, List<PipelineStage> stages) =>
    '${collectionAccessor(collection)}.aggregate(${pipelineToShellArray(stages)})';

String collectionAccessor(String collection) =>
    RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(collection)
    ? 'db.$collection'
    : 'db[${jsonEncode(collection)}]';

final _identifierKey = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');

String toShellLiteral(Object? v) {
  final type = ejsonTypeOf(v);
  if (type == EjsonType.object && v is Map) {
    if (v.isEmpty) return '{}';
    final entries = [
      for (final e in v.entries)
        '${_identifierKey.hasMatch('${e.key}') ? e.key : jsonEncode(e.key)}: ${toShellLiteral(e.value)}',
    ];
    return '{ ${entries.join(', ')} }';
  }
  if (type == EjsonType.array && v is List) {
    return '[${v.map(toShellLiteral).join(', ')}]';
  }
  if (type == EjsonType.int32 && v is Map) {
    return 'NumberInt(${v[r'$numberInt']})';
  }
  if (type == EjsonType.double_ && v is Map) {
    return 'Double(${v[r'$numberDouble']})';
  }
  return shellScalar(v);
}

Object? parseShellLiteral(String text) {
  final parser = RelaxedEjsonParser(text);
  final value = parser.parseValue();
  parser.skipTrivia();
  if (parser.position != text.length) {
    throw RelaxedParseException('Unexpected text', text, parser.position);
  }
  return value;
}

Object? parseLiteralOrString(String text) {
  final trimmed = text.trim();
  try {
    return parseShellLiteral(trimmed);
  } on FormatException {
    return text;
  }
}
