import 'package:flutter/widgets.dart';

import '../app.dart';
import '../editors/editor_handle.dart';
import '../editors/fce_variant.dart';

const editor = 'fce';
Widget build(EditorArgs a) => FceVariant(args: a);

void main() {
  harness = Harness(editor);
  runApp(const SpikeApp(builder: build));
}
