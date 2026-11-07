import 'workspace_models.dart';

/// [body] with a header comment holding [title] and [connection], for files
/// that are saved to the workspace for the first time (ADR 0011). Returns
/// [body] unchanged if both are empty.
String withHeader(
  FileKind kind,
  String body, {
  String title = '',
  String connection = '',
}) {
  final prefix = kind == FileKind.sql ? '--' : '//';
  final lines = [
    if (title.trim().isNotEmpty) '$prefix title: ${_oneLine(title)}',
    if (connection.trim().isNotEmpty)
      '$prefix connection: ${_oneLine(connection)}',
  ];
  if (lines.isEmpty) return body;
  final header = lines.join('\n');
  return body.trim().isEmpty ? '$header\n' : '$header\n\n$body';
}

String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
