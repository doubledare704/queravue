import 'package:flutter/material.dart';

Future<bool> confirmKeyOperation(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

typedef KeyInput = ({String label, String initial, bool multiline});

KeyInput input(String label, [String initial = '', bool multiline = false]) =>
    (label: label, initial: initial, multiline: multiline);

Future<List<String>?> keyInputs(
  BuildContext context,
  String title,
  List<KeyInput> fields,
) => showDialog<List<String>>(
  context: context,
  builder: (_) => _KeyInputDialog(title: title, fields: fields),
);

class _KeyInputDialog extends StatefulWidget {
  const _KeyInputDialog({required this.title, required this.fields});

  final String title;
  final List<KeyInput> fields;

  @override
  State<_KeyInputDialog> createState() => _KeyInputDialogState();
}

class _KeyInputDialogState extends State<_KeyInputDialog> {
  late final _values = widget.fields.map((field) => field.initial).toList();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.fields.length; i++)
            TextFormField(
              autofocus: i == 0,
              initialValue: _values[i],
              maxLines: widget.fields[i].multiline ? 8 : 1,
              decoration: InputDecoration(labelText: widget.fields[i].label),
              onChanged: (value) => _values[i] = value,
              onFieldSubmitted: widget.fields.length == 1
                  ? (_) => Navigator.pop(context, _values)
                  : null,
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _values),
        child: const Text('Save'),
      ),
    ],
  );
}
