import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'diagram_layout.dart';
import 'diagram_models.dart';

const savedDiagramVersion = 1;

/// What a saved diagram keeps: where it points and how it is arranged. The
/// schema itself is read again when the diagram opens.
@immutable
class SavedDiagram {
  const SavedDiagram({
    required this.connectionId,
    this.connectionName = '',
    this.database = '',
    this.schema = '',
    this.positions = const {},
    this.hidden = const {},
  });

  final String connectionId;

  /// Lets the file find its connection on another machine, where ids differ.
  final String connectionName;
  final String database;
  final String schema;

  /// Top-left corner of each table's box.
  final Map<String, Offset> positions;
  final Set<String> hidden;

  /// One table per line, sorted, so a diagram in Git diffs table by table.
  String toJson() {
    String n(double v) =>
        (v.roundToDouble() == v) ? v.toInt().toString() : v.toStringAsFixed(1);
    final names = positions.keys.toList()..sort();
    final hiddenNames = hidden.toList()..sort();
    final out = StringBuffer()
      ..writeln('{')
      ..writeln('  "version": $savedDiagramVersion,')
      ..writeln('  "connection": ${jsonEncode(connectionId)},')
      ..writeln('  "connectionName": ${jsonEncode(connectionName)},')
      ..writeln('  "database": ${jsonEncode(database)},')
      ..writeln('  "schema": ${jsonEncode(schema)},');
    if (names.isEmpty) {
      out.writeln('  "tables": {},');
    } else {
      out.writeln('  "tables": {');
      for (var i = 0; i < names.length; i++) {
        final p = positions[names[i]]!;
        final comma = i == names.length - 1 ? '' : ',';
        out.writeln(
          '    ${jsonEncode(names[i])}: {"x": ${n(p.dx)}, "y": ${n(p.dy)}}$comma',
        );
      }
      out.writeln('  },');
    }
    out
      ..writeln('  "hidden": ${jsonEncode(hiddenNames)}')
      ..writeln('}');
    return out.toString();
  }

  /// Null when [text] is not a diagram of this version.
  static SavedDiagram? fromJson(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?> ||
        json['version'] != savedDiagramVersion) {
      return null;
    }
    final connection = json['connection'];
    final tables = json['tables'];
    final hidden = json['hidden'] ?? const <Object?>[];
    if (connection is! String || tables is! Map<String, Object?>) return null;
    if (hidden is! List) return null;
    final positions = <String, Offset>{};
    for (final e in tables.entries) {
      final p = e.value;
      if (p is! Map<String, Object?>) return null;
      final x = p['x'], y = p['y'];
      if (x is! num || y is! num) return null;
      positions[e.key] = Offset(x.toDouble(), y.toDouble());
    }
    String text0(String key) =>
        json is Map<String, Object?> && json[key] is String
        ? json[key]! as String
        : '';
    return SavedDiagram(
      connectionId: connection,
      connectionName: text0('connectionName'),
      database: text0('database'),
      schema: text0('schema'),
      positions: positions,
      hidden: {
        for (final h in hidden)
          if (h is String) h,
      },
    );
  }
}

/// Boxes for [graph]: the saved spot for tables the file knows, and the
/// automatic layout, beside them, for tables added since.
Map<String, Rect> placeSaved(SchemaGraph graph, Map<String, Offset> positions) {
  final rects = <String, Rect>{};
  final newcomers = <DiagramTable>[];
  for (final table in graph.tables) {
    final at = positions[table.name];
    if (at == null) {
      newcomers.add(table);
    } else {
      rects[table.name] = at & tableSize(table);
    }
  }
  if (newcomers.isNotEmpty) {
    rects.addAll(layoutBeside(newcomers, DiagramLayout(rects).bounds));
  }
  return rects;
}
