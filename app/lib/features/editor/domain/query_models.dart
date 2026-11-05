import 'dart:typed_data';

/// General kind of a result column, from the core. Used for alignment and for
/// choosing a viewer. Cell values themselves are plain Dart objects.
enum ColumnKind {
  unknown,
  boolean,
  integer,
  float,
  decimal,
  text,
  bytes,
  timestamptz,
  json,
  uuid,
  array;

  /// True for kinds rendered right-aligned.
  bool get isNumeric => this == integer || this == float || this == decimal;
}

/// One result column.
class ResultColumn {
  const ResultColumn({
    required this.name,
    this.typeName = '',
    this.kind = ColumnKind.unknown,
  });

  final String name;

  /// Engine-native type name, e.g. `int4`.
  final String typeName;
  final ColumnKind kind;
}

/// One decoded row. Cells are `null`, `bool`, `int`, `double`, `String`
/// (text, decimal, JSON and UUID), [Uint8List], `DateTime` (UTC) or a
/// `List<Object?>` for arrays.
typedef ResultRow = List<Object?>;

/// Which statements of the editor text to run.
enum ExecuteMode { statementAtCursor, selection, all }

/// A half-open range of the editor text, in UTF-16 code units.
class TextSpanRange {
  const TextSpanRange(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is TextSpanRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// Input of `QueryRepository.execute`.
class ExecuteRequest {
  const ExecuteRequest({
    required this.sessionId,
    required this.text,
    this.cursorOffset = 0,
    this.mode = ExecuteMode.statementAtCursor,
    this.selection,
  });

  final String sessionId;
  final String text;
  final int cursorOffset;
  final ExecuteMode mode;
  final TextSpanRange? selection;
}

/// A live session on the core.
class SessionInfo {
  const SessionInfo({
    required this.id,
    this.product = '',
    this.version = '',
    this.capabilities = const {},
  });

  final String id;
  final String product;
  final String version;
  final Set<String> capabilities;

  bool get canExecute => capabilities.contains('execute');
}

/// Failure class of a statement.
enum QueryErrorKind { unspecified, sql, canceled, connection, unsupported }

/// Events of one Execute call, in stream order.
sealed class ExecuteEvent {
  const ExecuteEvent();
}

/// The statements about to run, as ranges of the request text.
class PlanEvent extends ExecuteEvent {
  const PlanEvent(this.statements);

  final List<TextSpanRange> statements;
}

/// A statement started; [resultId] addresses its rows.
class StartedEvent extends ExecuteEvent {
  const StartedEvent(this.statementIndex, this.resultId);

  final int statementIndex;
  final String resultId;
}

/// Column metadata of a statement that returns rows.
class ColumnsEvent extends ExecuteEvent {
  const ColumnsEvent(this.statementIndex, this.columns);

  final int statementIndex;
  final List<ResultColumn> columns;
}

/// The first window of rows (offset 0).
class RowsEvent extends ExecuteEvent {
  const RowsEvent(this.statementIndex, this.rows);

  final int statementIndex;
  final List<ResultRow> rows;
}

/// Spooling progress.
class ProgressEvent extends ExecuteEvent {
  const ProgressEvent(this.statementIndex, this.rowsSpooled, this.done);

  final int statementIndex;
  final int rowsSpooled;
  final bool done;
}

/// A statement finished.
class SummaryEvent extends ExecuteEvent {
  const SummaryEvent({
    required this.statementIndex,
    required this.rowsAffected,
    required this.rowsSpooled,
    required this.duration,
    required this.notices,
    required this.truncated,
    required this.hasRows,
  });

  final int statementIndex;
  final int rowsAffected;
  final int rowsSpooled;
  final Duration duration;
  final List<String> notices;
  final bool truncated;
  final bool hasRows;
}

/// A statement failed; the stream ends after this event.
class ErrorEvent extends ExecuteEvent {
  const ErrorEvent({
    required this.statementIndex,
    required this.kind,
    required this.message,
    this.position,
    this.duration = Duration.zero,
  });

  final int statementIndex;
  final QueryErrorKind kind;
  final String message;

  /// Offset in the request text where the server located the error.
  final int? position;
  final Duration duration;
}

/// Rows returned by `fetchRows`.
class FetchedRows {
  const FetchedRows({
    required this.offset,
    required this.rows,
    required this.rowsSpooled,
    required this.done,
  });

  final int offset;
  final List<ResultRow> rows;
  final int rowsSpooled;
  final bool done;
}

/// Text formats of `copyRange`.
enum CopyFormat { tsv, csv, json }

/// A chunk of formatted text from `copyRange`.
class CopyChunk {
  const CopyChunk(this.text, this.rowsWritten);

  final String text;
  final int rowsWritten;
}

/// A failure talking to the core about queries or sessions.
class QueryException implements Exception {
  const QueryException(this.message, {this.coreUnavailable = false});

  final String message;
  final bool coreUnavailable;

  @override
  String toString() => message;
}

/// Raised by `QueryRepository.openSession` when the connection could not be
/// opened (bad credentials, unreachable host...).
class SessionOpenException extends QueryException {
  const SessionOpenException(super.message);
}
