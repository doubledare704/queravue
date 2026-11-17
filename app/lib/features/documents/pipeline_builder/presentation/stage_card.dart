import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/pipeline_codec.dart';
import '../domain/pipeline_stage.dart';
import '../domain/stage_forms.dart';
import 'form_cells.dart';
import 'stage_form_view.dart';

class StageCardActions {
  const StageCardActions({
    required this.select,
    required this.toggleEnabled,
    required this.setOperator,
    required this.setBody,
    required this.setRawText,
    required this.duplicate,
    required this.remove,
    required this.preview,
  });

  final VoidCallback select;
  final ValueChanged<bool> toggleEnabled;
  final ValueChanged<String> setOperator;
  final ValueChanged<Object?> setBody;
  final ValueChanged<String> setRawText;
  final VoidCallback duplicate;
  final VoidCallback remove;
  final VoidCallback preview;
}

class StageCard extends StatelessWidget {
  const StageCard({
    super.key,
    required this.stage,
    required this.index,
    required this.selected,
    required this.running,
    required this.fieldNames,
    required this.collectionNames,
    required this.actions,
  });

  final PipelineStage stage;
  final int index;
  final bool selected;
  final bool running;
  final List<String> fieldNames;
  final List<String> collectionNames;
  final StageCardActions actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: stage.enabled ? 1 : 0.5,
      child: Card(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: actions.select,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_header(context), const SizedBox(height: 8), _body()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
    children: [
      ReorderableDragStartListener(
        index: index,
        child: const MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Icon(Icons.drag_indicator, size: 18),
        ),
      ),
      const SizedBox(width: 6),
      Text('${index + 1}', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(width: 8),
      if (stage.isUnparsed)
        const Chip(
          label: Text('Raw text'),
          visualDensity: VisualDensity.compact,
        )
      else
        DropdownCell<String>(
          key: Key('stage-operator-$index'),
          value: stage.operator,
          items: stageOperators.contains(stage.operator)
              ? stageOperators
              : [stage.operator, ...stageOperators],
          labelOf: (o) => o,
          onChanged: actions.setOperator,
        ),
      const Spacer(),
      Tooltip(
        message: stage.enabled ? 'Disable stage' : 'Enable stage',
        child: Switch(
          key: Key('stage-enabled-$index'),
          value: stage.enabled,
          onChanged: actions.toggleEnabled,
        ),
      ),
      IconButton(
        key: Key('stage-preview-$index'),
        tooltip: 'Preview up to this stage',
        icon: running
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow, size: 18),
        visualDensity: VisualDensity.compact,
        onPressed: actions.preview,
      ),
      IconButton(
        key: Key('stage-duplicate-$index'),
        tooltip: 'Duplicate stage',
        icon: const Icon(Icons.copy, size: 16),
        visualDensity: VisualDensity.compact,
        onPressed: actions.duplicate,
      ),
      IconButton(
        key: Key('stage-remove-$index'),
        tooltip: 'Remove stage',
        icon: const Icon(Icons.delete_outline, size: 18),
        visualDensity: VisualDensity.compact,
        onPressed: actions.remove,
      ),
    ],
  );

  Widget _body() {
    if (stage.isUnparsed) {
      return RawStageEditor(
        key: ValueKey('raw-${stage.id}'),
        initialText: stage.unparsedText!,
        note: 'This text is not a valid stage yet. It is kept as written.',
        onChanged: actions.setRawText,
      );
    }
    final form = stage.isTyped
        ? decodeStageForm(stage.operator, stage.body)
        : null;
    if (form != null) {
      return StageFormView(
        stageId: stage.id,
        form: form,
        fieldNames: fieldNames,
        collectionNames: collectionNames,
        onChanged: (f) => actions.setBody(f.toBody()),
      );
    }
    return RawStageEditor(
      key: ValueKey('raw-${stage.id}-${stage.operator}'),
      initialText: const JsonEncoder.withIndent('  ').convert(stage.body),
      note: stage.isTyped
          ? 'This stage uses features the form does not cover. Edit it as EJSON.'
          : null,
      onChanged: (text) {
        try {
          actions.setBody(parseShellLiteral(text));
        } on FormatException {
          return;
        }
      },
      validate: (text) {
        try {
          parseShellLiteral(text);
          return null;
        } on FormatException catch (e) {
          return e.message;
        }
      },
    );
  }
}

class RawStageEditor extends StatefulWidget {
  const RawStageEditor({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.note,
    this.validate,
  });

  final String initialText;
  final String? note;
  final ValueChanged<String> onChanged;
  final String? Function(String)? validate;

  @override
  State<RawStageEditor> createState() => _RawStageEditorState();
}

class _RawStageEditorState extends State<RawStageEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() => _error = widget.validate?.call(text));
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.note != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.note!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      TextField(
        controller: _controller,
        onChanged: _changed,
        minLines: 2,
        maxLines: 10,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
      ),
    ],
  );
}
