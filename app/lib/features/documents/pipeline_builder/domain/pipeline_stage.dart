import 'dart:convert';

import 'package:flutter/foundation.dart';

const typedStageOperators = [
  r'$match',
  r'$group',
  r'$project',
  r'$sort',
  r'$limit',
  r'$skip',
  r'$unwind',
  r'$lookup',
  r'$addFields',
  r'$count',
];

const rawStageOperators = [
  r'$bucket',
  r'$bucketAuto',
  r'$collStats',
  r'$facet',
  r'$geoNear',
  r'$graphLookup',
  r'$indexStats',
  r'$merge',
  r'$out',
  r'$redact',
  r'$replaceRoot',
  r'$replaceWith',
  r'$sample',
  r'$set',
  r'$setWindowFields',
  r'$sortByCount',
  r'$unionWith',
  r'$unset',
];

const stageOperators = [...typedStageOperators, ...rawStageOperators];

const writeStageOperators = {r'$out', r'$merge'};

int _nextStageId = 0;

@immutable
class PipelineStage {
  const PipelineStage._({
    required this.id,
    required this.operator,
    required this.body,
    required this.enabled,
    required this.unparsedText,
  });

  factory PipelineStage.of(
    String operator,
    Object? body, {
    bool enabled = true,
  }) => PipelineStage._(
    id: _nextStageId++,
    operator: operator,
    body: body,
    enabled: enabled,
    unparsedText: null,
  );

  factory PipelineStage.unparsed(String text) => PipelineStage._(
    id: _nextStageId++,
    operator: '',
    body: null,
    enabled: true,
    unparsedText: text,
  );

  final int id;
  final String operator;
  final Object? body;
  final bool enabled;
  final String? unparsedText;

  bool get isUnparsed => unparsedText != null;
  bool get isTyped => typedStageOperators.contains(operator);
  bool get isWrite => writeStageOperators.contains(operator);

  PipelineStage copyWith({String? operator, Object? body, bool? enabled}) =>
      PipelineStage._(
        id: id,
        operator: operator ?? this.operator,
        body: operator != null || body != null ? body : this.body,
        enabled: enabled ?? this.enabled,
        unparsedText: unparsedText,
      );

  PipelineStage withUnparsedText(String text) => PipelineStage._(
    id: id,
    operator: '',
    body: null,
    enabled: enabled,
    unparsedText: text,
  );

  PipelineStage withContent(String operator, Object? body) => PipelineStage._(
    id: id,
    operator: operator,
    body: body,
    enabled: enabled,
    unparsedText: null,
  );

  PipelineStage duplicate() => isUnparsed
      ? PipelineStage.unparsed(unparsedText!)
      : PipelineStage.of(operator, body, enabled: enabled);

  bool sameContentAs(PipelineStage other) =>
      operator == other.operator &&
      unparsedText == other.unparsedText &&
      jsonEncode(body) == jsonEncode(other.body);
}

bool samePipeline(List<PipelineStage> a, List<PipelineStage> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i].sameContentAs(b[i])]
        .every((x) => x);
