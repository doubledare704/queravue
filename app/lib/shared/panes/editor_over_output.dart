import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pane_sizes.dart';

const _minPaneHeight = 80.0;
const _handleHeight = 6.0;

/// An editor above its results or output, with a draggable divider. The share
/// and the collapsed state are the same for every tab and are persisted.
class EditorOverOutput extends ConsumerWidget {
  const EditorOverOutput({
    super.key,
    required this.editor,
    required this.output,
  });

  final Widget editor;
  final Widget output;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = ref.watch(paneSizesProvider);
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final most = h - _minPaneHeight < _minPaneHeight
            ? _minPaneHeight
            : h - _minPaneHeight;
        final editorH = (h * sizes.editorShare).clamp(_minPaneHeight, most);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: sizes.outputCollapsed ? h - _handleHeight : editorH,
              child: editor,
            ),
            MouseRegion(
              cursor: sizes.outputCollapsed
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.resizeRow,
              child: GestureDetector(
                key: const Key('output-divider'),
                behavior: HitTestBehavior.opaque,
                onDoubleTap: ref.read(paneSizesProvider.notifier).toggleOutput,
                onTap: sizes.outputCollapsed
                    ? ref.read(paneSizesProvider.notifier).toggleOutput
                    : null,
                onVerticalDragUpdate: sizes.outputCollapsed
                    ? null
                    : (d) => ref
                          .read(paneSizesProvider.notifier)
                          .setEditorShare((editorH + d.delta.dy) / h),
                child: Container(
                  height: _handleHeight,
                  color: cs.surfaceContainerHigh,
                ),
              ),
            ),
            Expanded(
              child: Offstage(
                offstage: sizes.outputCollapsed,
                // Hidden output keeps a real height so it never lays out at 0.
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: sizes.outputCollapsed ? _minPaneHeight : null,
                  maxHeight: sizes.outputCollapsed ? _minPaneHeight : null,
                  child: output,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
