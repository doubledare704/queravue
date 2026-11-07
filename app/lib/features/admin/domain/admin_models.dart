enum AdminErrorKind {
  confirmationRequired,
  unsupported,
  invalid,
  notFound,
  canceled,
  server,
}

class AdminError {
  const AdminError({required this.kind, required this.message, this.position});

  final AdminErrorKind kind;
  final String message;

  /// UTF-16 offset into the submitted text for invalid input.
  final int? position;

  bool get isUnsupported => kind == AdminErrorKind.unsupported;
  bool get needsConfirmation => kind == AdminErrorKind.confirmationRequired;
}

class AdminResult<T> {
  const AdminResult.ok(T this.value) : error = null;
  const AdminResult.failed(AdminError this.error) : value = null;

  final T? value;
  final AdminError? error;

  bool get isOk => error == null;
}

class IndexKeyModel {
  const IndexKeyModel(
    this.name, {
    this.descending = false,
    this.isExpression = false,
  });

  final String name;
  final bool descending;
  final bool isExpression;

  String get label => descending ? '$name desc' : name;
}

class IndexEntry {
  const IndexEntry({
    required this.name,
    required this.keys,
    this.unique = false,
    this.primary = false,
    this.method = '',
    this.partialPredicate = '',
    this.includeColumns = const [],
    this.sizeBytes,
    this.usageAvailable = false,
    this.scans,
    this.lastUsed,
  });

  final String name;
  final List<IndexKeyModel> keys;
  final bool unique;
  final bool primary;
  final String method;
  final String partialPredicate;
  final List<String> includeColumns;
  final int? sizeBytes;
  final bool usageAvailable;
  final int? scans;
  final DateTime? lastUsed;
}

class IndexDraft {
  const IndexDraft({
    this.name = '',
    this.keys = const [],
    this.unique = false,
    this.method = '',
    this.partialPredicate = '',
    this.online = false,
  });

  final String name;
  final List<IndexKeyModel> keys;
  final bool unique;
  final String method;
  final String partialPredicate;

  /// Build without blocking writes, where the server can.
  final bool online;
}

class IndexStatement {
  const IndexStatement({required this.statement, this.warnings = const []});

  final String statement;
  final List<String> warnings;
}

class StatsModel {
  const StatsModel({
    this.estimatedRows,
    this.dataBytes,
    this.indexBytes,
    this.totalBytes,
    this.extras = const [],
  });

  final int? estimatedRows;
  final int? dataBytes;
  final int? indexBytes;
  final int? totalBytes;
  final List<({String label, String value})> extras;
}

class ValidationModel {
  const ValidationModel({
    this.validator = '',
    this.level = '',
    this.action = '',
  });

  final String validator;

  /// `off`, `moderate`, `strict`, or empty for the server default.
  final String level;

  /// `error`, `warn`, or empty for the server default.
  final String action;
}

class StarterSchema {
  const StarterSchema({
    required this.text,
    required this.sampled,
    this.usedFallback = false,
  });

  final String text;
  final int sampled;
  final bool usedFallback;
}

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 ? '$bytes' : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// Line and column (both 1-based) of a UTF-16 [offset] in [text].
({int line, int column}) lineAndColumn(String text, int offset) {
  final end = offset.clamp(0, text.length);
  var line = 1;
  var lineStart = 0;
  for (var i = 0; i < end; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line: line, column: end - lineStart + 1);
}
