import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../connections/domain/models.dart';
import '../application/table_tab_controller.dart';
import '../domain/table_models.dart';

/// Dialog that runs dry_run on pending changes, displays the generated SQL,
/// asks for confirmation on production connections, and executes the changes.
class CommitPreviewDialog extends ConsumerStatefulWidget {
  const CommitPreviewDialog({super.key, required this.tabId});

  final String tabId;

  static Future<bool?> show(BuildContext context, String tabId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CommitPreviewDialog(tabId: tabId),
    );
  }

  @override
  ConsumerState<CommitPreviewDialog> createState() =>
      _CommitPreviewDialogState();
}

class _CommitPreviewDialogState extends ConsumerState<CommitPreviewDialog> {
  bool _loadingPreview = true;
  bool _committing = false;
  bool _prodConfirmed = false;
  ApplyChangesResult? _previewResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _error = null;
    });

    final controller = ref.read(tableTabProvider(widget.tabId).notifier);
    final res = await controller.applyChanges(dryRun: true);

    if (mounted) {
      setState(() {
        _loadingPreview = false;
        _previewResult = res;
        if (!res.success) {
          _error = res.errorMessage;
        }
      });
    }
  }

  Future<void> _commit(bool isProd) async {
    if (isProd && !_prodConfirmed) return;

    setState(() {
      _committing = true;
      _error = null;
    });

    final controller = ref.read(tableTabProvider(widget.tabId).notifier);
    final res = await controller.applyChanges(
      dryRun: false,
      confirmProduction: _prodConfirmed,
    );

    if (!mounted) return;

    if (res.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _committing = false;
        _error = res.errorMessage ?? 'Failed to apply changes';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tableTabProvider(widget.tabId));
    final profiles = ref.watch(connectionsControllerProvider).value ?? [];
    final profile = profiles
        .where((ConnectionProfile p) => p.id == tabState.connectionId)
        .firstOrNull;
    final isProd = profile?.production ?? false;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.rate_review_outlined, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Review & Commit Changes',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isProd) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRODUCTION',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isProd)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This connection is flagged as PRODUCTION. '
                        'Changes will be committed directly to production data.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text('Generated SQL Preview:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: _loadingPreview
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _previewResult?.generatedSql ?? '-- No SQL generated',
                          key: const Key('commit-sql-preview'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _error!,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (isProd) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('confirm-prod-checkbox'),
                value: _prodConfirmed,
                onChanged: _committing
                    ? null
                    : (v) => setState(() => _prodConfirmed = v ?? false),
                title: Text(
                  'I understand this is a production database and confirm applying these changes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _committing
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('commit-confirm-btn'),
          style: isProd
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed:
              (_loadingPreview || _committing || (isProd && !_prodConfirmed))
              ? null
              : () => _commit(isProd),
          child: _committing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Commit'),
        ),
      ],
    );
  }
}
