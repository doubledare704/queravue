import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shortcuts.dart';
import '../../grid/presentation/result_grid.dart';
import '../application/editor_tabs.dart';
import '../application/query_run.dart';
import '../domain/query_models.dart';
import 'sql_editor.dart';

/// One editor tab: run bar, SQL editor and the result area under it.
class QueryTabView extends ConsumerStatefulWidget {
  const QueryTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<QueryTabView> createState() => _QueryTabViewState();
}

class _QueryTabViewState extends ConsumerState<QueryTabView> {
  double _split = 0.4; // editor share of the height

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(queryRunProvider(widget.tab.id));
    final tabs = ref.read(editorTabsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunBar(
          run: run,
          onRun: () =>
              unawaited(tabs.run(widget.tab.id, ExecuteMode.statementAtCursor)),
          onRunAll: () => unawaited(tabs.run(widget.tab.id, ExecuteMode.all)),
          onCancel: () => unawaited(tabs.cancel(widget.tab.id)),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final h = box.maxHeight;
              final editorH = (h * _split).clamp(
                80.0,
                h - 80.0 < 80 ? 80.0 : h - 80.0,
              );
              return Column(
                children: [
                  SizedBox(
                    height: editorH,
                    child: SqlEditor(tab: widget.tab),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) => setState(() {
                        _split = ((editorH + d.delta.dy) / h).clamp(0.1, 0.9);
                      }),
                      child: Container(
                        height: 6,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _ResultArea(tabId: widget.tab.id, run: run),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RunBar extends StatelessWidget {
  const _RunBar({
    required this.run,
    required this.onRun,
    required this.onRunAll,
    required this.onCancel,
  });

  final QueryRunState run;
  final VoidCallback onRun;
  final VoidCallback onRunAll;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _build(context, compact: box.maxWidth < 560),
  );

  Widget _build(BuildContext context, {required bool compact}) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (!run.busy) ...[
              FilledButton.icon(
                key: const Key('run-button'),
                onPressed: onRun,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(compact ? 'Run' : 'Run  $primaryLabel↵'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('run-all-button'),
                onPressed: onRunAll,
                child: Text(compact ? 'Run all' : 'Run all  $primaryLabel⇧↵'),
              ),
            ] else
              FilledButton.icon(
                key: const Key('cancel-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: run.cancelling ? null : onCancel,
                icon: const Icon(Icons.stop, size: 18),
                label: Text(
                  run.cancelling
                      ? 'Cancelling…'
                      : compact
                      ? 'Cancel'
                      : 'Cancel  Esc',
                ),
              ),
            const SizedBox(width: 12),
            ElapsedText(
              startedAt: run.startedAt,
              running: run.busy,
              finalDuration: run.totalDuration,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  run.serverLabel,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elapsed time of the current run, ticking while it runs and showing the
/// final duration afterwards.
class ElapsedText extends StatefulWidget {
  const ElapsedText({
    super.key,
    required this.startedAt,
    required this.running,
    required this.finalDuration,
  });

  final DateTime? startedAt;
  final bool running;
  final Duration finalDuration;

  @override
  State<ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<ElapsedText> {
  Timer? _timer;
  Duration _ticked = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ElapsedText old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.running && _timer == null) {
      _ticked = Duration.zero;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        setState(() => _ticked += const Duration(milliseconds: 100));
      });
    } else if (!widget.running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startedAt;
    final Duration d;
    if (widget.running && start != null) {
      // Wall clock, but never behind the ticks (a paused clock in tests).
      final wall = DateTime.now().difference(start);
      d = wall > _ticked ? wall : _ticked;
    } else {
      d = widget.finalDuration;
    }
    if (start == null) return const SizedBox.shrink();
    return Text(
      formatElapsed(d),
      key: const Key('elapsed'),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

/// `0.4 s`, `12.3 s`, `2 m 05 s`.
String formatElapsed(Duration d) {
  if (d.inMinutes >= 1) {
    return '${d.inMinutes} m ${(d.inSeconds % 60).toString().padLeft(2, '0')} s';
  }
  return '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';
}

class _ResultArea extends ConsumerWidget {
  const _ResultArea({required this.tabId, required this.run});

  final String tabId;
  final QueryRunState run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final active = run.active;
    final children = <Widget>[];

    if (run.results.length > 1) {
      children.add(
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (var i = 0; i < run.results.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                  child: ChoiceChip(
                    key: Key('result-chip-$i'),
                    label: Text(_chipLabel(run, i)),
                    selected: i == run.activeResult,
                    onSelected: (_) => ref
                        .read(queryRunProvider(tabId).notifier)
                        .selectResult(i),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    final message = run.message;
    if (message != null) {
      final isError = run.phase == RunPhase.failed;
      children.add(
        Container(
          key: const Key('run-message'),
          color: isError ? cs.errorContainer : cs.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SelectableText(
            message,
            style: text.bodySmall!.copyWith(
              color: isError ? cs.onErrorContainer : cs.onSurface,
            ),
          ),
        ),
      );
    }
    if (active != null && active.notices.isNotEmpty) {
      children.add(
        Container(
          color: cs.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SelectableText(
            active.notices.join('\n'),
            style: text.bodySmall,
          ),
        ),
      );
    }

    Widget body;
    if (active != null && active.resultId != null && active.hasRows) {
      body = ResultGrid(
        key: ValueKey(active.resultId),
        resultId: active.resultId!,
      );
    } else if (active != null && run.phase == RunPhase.finished) {
      body = Center(
        child: Text(
          'OK · ${active.rowsAffected} rows affected',
          key: const Key('rows-affected'),
          style: text.bodyMedium,
        ),
      );
    } else if (run.phase == RunPhase.idle) {
      body = Center(
        child: Text(
          'Run a statement with $primaryLabel↵',
          style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    } else {
      body = const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        Expanded(child: body),
      ],
    );
  }

  String _chipLabel(QueryRunState run, int i) {
    final r = run.results[i];
    final what = r.errorMessage != null
        ? 'error'
        : r.hasRows
        ? '${r.rowsSpooled} rows'
        : '${r.rowsAffected} affected';
    return '${r.index + 1}: $what';
  }
}
