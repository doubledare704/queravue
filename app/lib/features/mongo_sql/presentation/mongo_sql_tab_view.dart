import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../../shared/shortcuts.dart';
import '../../documents/application/document_preview_controller.dart';
import '../../documents/presentation/document_preview_pane.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/text_offsets.dart';
import '../../query_builder/domain/sql_query_models.dart'
    show utf8ByteOffsetToUtf16;
import '../../shell/application/shell_tab_controller.dart';
import '../../shell/presentation/output_pane.dart';
import '../application/mongo_sql_actions.dart';
import '../application/mongo_sql_controller.dart';
import '../domain/mongo_sql_translation.dart';
import 'mongo_sql_editor.dart';
import 'mql_pane.dart';

class MongoSqlTabView extends ConsumerStatefulWidget {
  const MongoSqlTabView({super.key, required this.tab});

  final EditorTab tab;

  @override
  ConsumerState<MongoSqlTabView> createState() => _MongoSqlTabViewState();
}

class _MongoSqlTabViewState extends ConsumerState<MongoSqlTabView> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _jump(int offset) {
    final editor = widget.tab.controller;
    final (line, column) = positionOfOffset(editor.text, offset);
    editor.selection = CodeLineSelection.collapsed(index: line, offset: column);
    editor.makeCursorCenterIfInvisible();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    if (!ref.watch(connectionHasMongoSqlProvider(tab.connectionId))) {
      return const Center(
        child: Text('SQL mode requires document and shell support.'),
      );
    }

    final provider = mongoSqlControllerProvider(tab);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final shell = ref.watch(shellTabProvider(tab.id));
    final preview = ref.watch(documentPreviewProvider(tab.id));
    final enabled = state.current != null && !shell.busy && !preview.running;
    final failure = state.failure;
    final warnings = state.current?.warnings ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const Key('mongo-sql-run'),
                onPressed: enabled ? controller.run : null,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text('Run ($primaryLabel↵)'),
              ),
              OutlinedButton(
                key: const Key('mongo-sql-preview'),
                onPressed: enabled ? controller.preview : null,
                child: const Text('Preview'),
              ),
              if (state.current is MongoSqlAggregate)
                TextButton(
                  onPressed: () =>
                      openMongoSqlPipeline(context, tab, state.current),
                  child: const Text('Open in pipeline builder'),
                ),
              if (shell.showCancel)
                TextButton(
                  onPressed: controller.cancel,
                  child: const Text('Cancel'),
                ),
              if (tab.shellDatabase.isNotEmpty)
                Text(
                  tab.shellDatabase,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: MongoSqlEditor(
            tab: tab,
            errorOffset: state.errorOffset,
            focusNode: _focus,
          ),
        ),
        if (failure != null)
          _DiagnosticStrip(
            children: [
              _Diagnostic(
                message: failure.diagnostic.message,
                error: true,
                onJump: state.errorOffset == null
                    ? null
                    : () => _jump(state.errorOffset!),
              ),
              if (failure.kind == MongoSqlErrorKind.other)
                TextButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: MqlPane(
            translation: state.translation,
            stale: state.stale,
            pending: state.pending,
            format: state.format,
            onFormat: controller.setFormat,
            onCopy: state.translation == null
                ? null
                : () => copyMongoSqlMql(state),
          ),
        ),
        if (warnings.isNotEmpty)
          _DiagnosticStrip(
            children: [
              for (final warning in warnings)
                _Diagnostic(
                  message: warning.message,
                  onJump: warning.byteOffset == null
                      ? null
                      : () => _jump(
                          utf8ByteOffsetToUtf16(
                            tab.controller.text,
                            warning.byteOffset!,
                          ),
                        ),
                ),
            ],
          ),
        const Divider(height: 1),
        Expanded(
          flex: 3,
          child: state.showPreview
              ? DocumentPreviewPane(
                  previewKey: tab.id,
                  title: 'Preview results',
                  idleHint:
                      'Preview fetches up to $kDefaultPreviewLimit documents.',
                )
              : _RunResults(shell: shell),
        ),
      ],
    );
  }
}

class _RunResults extends StatelessWidget {
  const _RunResults({required this.shell});

  final ShellTabState shell;

  @override
  Widget build(BuildContext context) {
    final key = cursorOf(shell);
    final error =
        shell.connectionError ??
        shell.entries.whereType<OutputError>().lastOrNull?.failure.message;
    if (shell.busy) return const Center(child: CircularProgressIndicator());
    if (error != null || shell.pending != null) {
      return Center(
        child: Text(
          error ?? 'The generated query was blocked by the shell.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (key == null) {
      return const Center(child: Text('The query returned no cursor.'));
    }
    return CursorResultView(cursorKey: key, title: 'Results', height: null);
  }
}

class _DiagnosticStrip extends StatelessWidget {
  const _DiagnosticStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 64),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _Diagnostic extends StatelessWidget {
  const _Diagnostic({required this.message, this.onJump, this.error = false});

  final String message;
  final VoidCallback? onJump;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: error ? colors.errorContainer : colors.secondaryContainer,
      child: InkWell(
        onTap: onJump,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                error ? Icons.error_outline : Icons.warning_amber_rounded,
                size: 16,
                color: error
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: error
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
