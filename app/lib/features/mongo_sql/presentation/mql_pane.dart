import 'package:flutter/material.dart';

import '../domain/mongo_sql_translation.dart';

class MqlPane extends StatelessWidget {
  const MqlPane({
    super.key,
    required this.format,
    required this.onFormat,
    required this.onCopy,
    this.translation,
    this.stale = false,
    this.pending = false,
  });

  final MqlFormat format;
  final ValueChanged<MqlFormat> onFormat;
  final VoidCallback? onCopy;
  final MongoSqlTranslation? translation;
  final bool stale;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = translation?.inFormat(format);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Generated MQL', style: theme.textTheme.titleSmall),
                if (stale)
                  Text(
                    'Stale',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                if (pending)
                  const SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                SegmentedButton<MqlFormat>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: MqlFormat.shell, label: Text('Shell')),
                    ButtonSegment(value: MqlFormat.ejson, label: Text('EJSON')),
                  ],
                  selected: {format},
                  onSelectionChanged: (formats) => onFormat(formats.single),
                ),
                IconButton(
                  tooltip: 'Copy MQL',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: code == null
                  ? Text(
                      'Enter a SELECT statement.',
                      style: theme.textTheme.bodySmall,
                    )
                  : SelectableText(
                      code,
                      key: const Key('generated-mql'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
