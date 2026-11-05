import 'package:flutter/widgets.dart';

import '../app.dart';
import '../editors/editor_handle.dart';
import '../editors/re_editor_variant.dart';

const editor = 're_editor';
Widget build(EditorArgs a) => ReEditorVariant(args: a);

void main() {
  harness = Harness(editor);
  runApp(const SpikeApp(builder: build));
}
