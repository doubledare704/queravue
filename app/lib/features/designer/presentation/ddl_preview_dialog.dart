import 'package:flutter/material.dart';

import '../../admin/domain/admin_models.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../domain/design_models.dart';

/// Shows the statements [preview] returns and runs [apply] on the user's
/// word: the dialog is the confirmation for destructive and production
/// changes.
class DdlPreviewDialog extends StatefulWidget {
  const DdlPreviewDialog({
    super.key,
    required this.preview,
    required this.apply,
  });

  final Future<AdminResult<DdlPreview>> Function() preview;
  final Future<AdminResult<Object?>> Function() apply;

  @override
  State<DdlPreviewDialog> createState() => _DdlPreviewDialogState();
}

class _DdlPreviewDialogState extends State<DdlPreviewDialog> {
  late final Future<AdminResult<DdlPreview>> _preview;

  @override
  void initState() {
    super.initState();
    _preview = Future.microtask(widget.preview);
  }

  bool _busy = false;
  AdminError? _error;

  Future<void> _apply() async {
    setState(() => _busy = true);
    final result = await widget.apply();
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Review changes'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            final result = snap.data;
            if (result == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (result.error != null) {
              return Text(
                result.error!.message,
                key: const Key('ddl-error'),
                style: TextStyle(color: scheme.error),
              );
            }
            final preview = result.value!;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in preview.statements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.summary,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (s.destructive) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'destructive',
                                  key: const Key('ddl-destructive'),
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          StatementBox(statement: s.sql),
                        ],
                      ),
                    ),
                  for (final w in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 14,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    preview.transactional
                        ? 'Runs in one transaction: a failure rolls everything back.'
                        : 'Each statement commits as it runs: a failure leaves earlier ones applied.',
                    key: const Key('ddl-transactional'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!.message,
                        key: const Key('ddl-error'),
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            final preview = snap.data?.value;
            return FilledButton(
              key: const Key('ddl-apply'),
              style: preview != null && preview.hasDestructive
                  ? FilledButton.styleFrom(backgroundColor: scheme.error)
                  : null,
              onPressed: preview == null || _busy ? null : _apply,
              child: Text(
                preview != null && preview.hasDestructive
                    ? 'Apply (destructive)'
                    : 'Apply',
              ),
            );
          },
        ),
      ],
    );
  }
}
