import 'dart:async';

import '../../connections/domain/cancellation.dart';
import '../../editor/data/query_repository.dart';
import '../../editor/domain/query_models.dart';
import '../domain/cell_format.dart';

/// Largest copy built from rows already in the window; anything bigger, or
/// missing rows, goes through the core.
const int kLocalCopyMaxCells = 10000;

/// Formats [rows] (restricted to [columns]) as TSV or CSV without a header
/// unless [header] names the columns. Same quoting as the core's formatter.
String formatDelimited(
  List<ResultRow> rows,
  List<int> columns, {
  required CopyFormat format,
  List<ResultColumn>? header,
}) {
  assert(format != CopyFormat.json, 'JSON is formatted by the core');
  final sep = format == CopyFormat.csv ? ',' : '\t';
  final sb = StringBuffer();
  if (header != null) {
    sb
      ..writeAll([
        for (final c in columns) delimitedField(header[c].name, sep),
      ], sep)
      ..write('\n');
  }
  for (final row in rows) {
    var first = true;
    for (final c in columns) {
      if (!first) sb.write(sep);
      first = false;
      sb.write(
        c < row.length
            ? delimitedField(formatCell(row[c], forCopy: true), sep)
            : '',
      );
    }
    sb.write('\n');
  }
  return sb.toString();
}

/// Copies rows [start, end) of a result through the core and returns the
/// text. [onProgress] gets rows written so far; firing [cancel] stops the
/// copy and throws [OperationCancelled].
Future<String> copyViaCore(
  QueryRepository repo, {
  required String resultId,
  required int start,
  required int end,
  required List<int> columns,
  required CopyFormat format,
  required bool includeHeader,
  void Function(int rowsWritten)? onProgress,
  CancellationToken? cancel,
}) async {
  final sb = StringBuffer();
  final done = Completer<void>();
  late StreamSubscription<CopyChunk> sub;
  sub = repo
      .copyRange(
        resultId: resultId,
        start: start,
        end: end,
        columns: columns,
        format: format,
        includeHeader: includeHeader,
      )
      .listen(
        (c) {
          sb.write(c.text);
          onProgress?.call(c.rowsWritten);
        },
        onError: (Object e, StackTrace st) {
          if (!done.isCompleted) done.completeError(e, st);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
  unawaited(
    cancel?.whenCancelled.then((_) {
      if (done.isCompleted) return;
      unawaited(sub.cancel());
      done.completeError(const OperationCancelled());
    }),
  );
  try {
    await done.future;
  } finally {
    unawaited(sub.cancel());
  }
  return sb.toString();
}
