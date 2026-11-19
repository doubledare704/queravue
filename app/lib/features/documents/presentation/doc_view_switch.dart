import 'package:flutter/material.dart';

import '../application/document_tab_controller.dart' show DocView;

class DocViewSwitch extends StatelessWidget {
  const DocViewSwitch({super.key, required this.view, required this.onChanged});

  final DocView view;
  final ValueChanged<DocView> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<DocView>(
    key: const Key('doc-view-switch'),
    showSelectedIcon: false,
    style: const ButtonStyle(visualDensity: VisualDensity.compact),
    segments: const [
      ButtonSegment(
        value: DocView.table,
        icon: Icon(Icons.table_rows_outlined, size: 16),
        label: Text('Table'),
      ),
      ButtonSegment(
        value: DocView.tree,
        icon: Icon(Icons.account_tree_outlined, size: 16),
        label: Text('Tree'),
      ),
      ButtonSegment(
        value: DocView.json,
        icon: Icon(Icons.data_object, size: 16),
        label: Text('JSON'),
      ),
    ],
    selected: {view},
    onSelectionChanged: (s) => onChanged(s.first),
  );
}
