import 'package:flutter/material.dart';

class TextCell extends StatelessWidget {
  const TextCell({
    super.key,
    required this.initial,
    required this.label,
    required this.onChanged,
    this.mono = false,
  });

  final String initial;
  final String label;
  final ValueChanged<String> onChanged;
  final bool mono;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initial,
    onChanged: onChanged,
    style: mono ? const TextStyle(fontFamily: 'monospace', fontSize: 12) : null,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
  );
}

class SuggestCell extends StatelessWidget {
  const SuggestCell({
    super.key,
    required this.initial,
    required this.label,
    required this.suggestions,
    required this.onChanged,
  });

  final String initial;
  final String label;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
    initialValue: TextEditingValue(text: initial),
    optionsBuilder: (value) {
      final q = value.text.toLowerCase();
      return suggestions.where(
        (s) => s.toLowerCase().contains(q) && s != value.text,
      );
    },
    onSelected: onChanged,
    fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
      controller: controller,
      focusNode: focus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final o in options)
                ListTile(
                  dense: true,
                  title: Text(o),
                  onTap: () => onSelected(o),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DropdownCell<T> extends StatelessWidget {
  const DropdownCell({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<T>(
      value: value,
      isDense: true,
      items: [
        for (final i in items)
          DropdownMenuItem(value: i, child: Text(labelOf(i))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

class FormRowShell extends StatelessWidget {
  const FormRowShell({
    super.key,
    required this.children,
    required this.onRemove,
  });

  final List<Widget> children;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        for (final c in children) ...[
          Expanded(child: c),
          const SizedBox(width: 6),
        ],
        IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
        ),
      ],
    ),
  );
}

class AddRowButton extends StatelessWidget {
  const AddRowButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
    ),
  );
}
