import 'package:flutter/material.dart';

import 'editors/editor_handle.dart';
import 'sql_sample.dart';

typedef EditorBuilder = Widget Function(EditorArgs args);

class Harness {
  Harness(this.editor);
  final String editor;
  final dark = ValueNotifier(false);
  final text = ValueNotifier<String?>(null);
  EditorHandle? handle;
  void load() => text.value = buildSqlSample();
}

late Harness harness;

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key, required this.builder});
  final EditorBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: harness.dark,
      builder: (context, dark, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
        darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Row(children: [
                Text('  ${harness.editor}'),
                const Spacer(),
                TextButton(onPressed: harness.load, child: const Text('Load 5k lines')),
                IconButton(
                    onPressed: () => harness.dark.value = !dark,
                    icon: Icon(dark ? Icons.light_mode : Icons.dark_mode)),
              ]),
            ),
            Expanded(
              child: RepaintBoundary(
                key: const ValueKey('editor'),
                child: ValueListenableBuilder<String?>(
                  valueListenable: harness.text,
                  builder: (context, text, _) => text == null
                      ? const SizedBox.expand()
                      : builder(EditorArgs(
                          text: text, dark: dark, onHandle: (h) => harness.handle = h)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
