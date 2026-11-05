import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../grid/application/result_window.dart';
import 'editor_tabs.dart';
import 'query_run.dart';

/// What the status bar shows about the active tab's query.
@immutable
class QueryStatus {
  const QueryStatus(this.text);

  final String text;
}

String _n(int v) {
  final s = v.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

String _duration(Duration d) {
  if (d.inMilliseconds < 1000) return '${d.inMilliseconds} ms';
  return '${(d.inMilliseconds / 1000).toStringAsFixed(2)} s';
}

/// Formats the status line: rows spooled, window position, duration and
/// `streaming…` / `truncated at N rows`.
String formatQueryStatus({
  required QueryRunState run,
  ViewportRange? viewport,
}) {
  final r = run.active;
  switch (run.phase) {
    case RunPhase.idle:
      return '';
    case RunPhase.connecting:
      return 'Connecting…';
    case RunPhase.running:
    case RunPhase.finished:
    case RunPhase.failed:
    case RunPhase.cancelled:
      break;
  }
  final parts = <String>[];
  if (r != null && r.hasRows) {
    parts.add('${_n(r.rowsSpooled)} rows');
    if (r.rowsSpooled > 0 && viewport != null) {
      final last = viewport.last >= r.rowsSpooled
          ? r.rowsSpooled - 1
          : viewport.last;
      parts.add('rows ${_n(viewport.first + 1)}–${_n(last + 1)}');
    }
  } else if (r != null && run.phase == RunPhase.finished) {
    parts.add('${_n(r.rowsAffected)} rows affected');
  }
  if (run.phase == RunPhase.running) {
    parts.add(run.cancelling ? 'cancelling…' : 'streaming…');
  } else {
    if (r != null && r.truncated) {
      parts.add('truncated at ${_n(r.rowsSpooled)} rows');
    }
    final d = run.totalDuration;
    if (run.phase == RunPhase.finished && d > Duration.zero) {
      parts.add(_duration(d));
    }
    if (run.phase == RunPhase.failed) parts.add('failed');
    if (run.phase == RunPhase.cancelled) parts.add('cancelled');
  }
  return parts.join(' · ');
}

/// Status of the active tab of the selected connection.
final queryStatusProvider = Provider<QueryStatus>((ref) {
  final tab = ref
      .watch(editorTabsProvider)
      .activeFor(ref.watch(selectedConnectionProvider));
  if (tab == null) return const QueryStatus('');
  final run = ref.watch(queryRunProvider(tab.id));
  final id = run.active?.resultId;
  final viewport = id == null ? null : ref.watch(viewportProvider(id));
  return QueryStatus(formatQueryStatus(run: run, viewport: viewport));
});
