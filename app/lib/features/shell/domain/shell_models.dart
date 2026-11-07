import 'package:flutter/foundation.dart';

/// Failure class of a script (mirrors ShellErrorKind).
enum ShellErrorKind {
  unspecified,
  syntax,
  runtime,
  confirmationRequired,
  outputLimit,
  timeout,
  canceled,
  server,
  unsupported,
}

/// Console method behind a print line.
enum PrintLevel { log, info, warn, error }

/// A typed script failure. [line] and [column] start at 1, in UTF-16 units;
/// 0 means unknown.
@immutable
class ShellFailure {
  const ShellFailure({
    required this.kind,
    required this.message,
    this.stack = '',
    this.line = 0,
    this.column = 0,
    this.operation = '',
  });

  final ShellErrorKind kind;
  final String message;
  final String stack;
  final int line;
  final int column;

  /// For [ShellErrorKind.confirmationRequired]: what needs confirming.
  final String operation;

  bool get needsConfirmation => kind == ShellErrorKind.confirmationRequired;
}

/// How a cursor handle is replayed.
enum CursorKind { find, aggregate }

/// A replayable query the script left unconsumed.
@immutable
class CursorHandle {
  const CursorHandle({
    required this.cursorId,
    required this.kind,
    required this.database,
    required this.collection,
  });

  final String cursorId;
  final CursorKind kind;
  final String database;
  final String collection;
}

/// One event of an Eval stream.
sealed class ShellEvent {
  const ShellEvent();
}

final class ShellPrint extends ShellEvent {
  const ShellPrint(this.level, this.text);
  final PrintLevel level;
  final String text;
}

enum ValueKind { scalar, document, write }

/// A value the script produced; [text] is canonical EJSON.
final class ShellValue extends ShellEvent {
  const ShellValue(this.kind, this.text, {this.writeOp = ''});
  final ValueKind kind;
  final String text;
  final String writeOp;
}

final class ShellCursorEvent extends ShellEvent {
  const ShellCursorEvent(this.handle);
  final CursorHandle handle;
}

final class ShellErrorEvent extends ShellEvent {
  const ShellErrorEvent(this.failure);
  final ShellFailure failure;
}

final class ShellDone extends ShellEvent {
  const ShellDone(this.duration);
  final Duration duration;
}
