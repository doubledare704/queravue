import 'package:flutter/material.dart';

import 'data/dataset.dart';
import 'grids/grid_handle.dart';

const kMode = String.fromEnvironment('MODE', defaultValue: 'full');

typedef GridBuilder = Widget Function(GridArgs args, String mode);

/// Global hooks for the integration test (spike only).
class Harness {
  Harness(this.grid, this.mode)
    : store = switch ((grid, mode)) {
        ('tableview' || 'fixedgrid', 'window') ||
        ('syncfusion', 'window') => WindowStore(),
        ('tableview' || 'fixedgrid', _) => FullStore(),
        _ => CountingStore(),
      };
  final String grid;
  final String mode;
  final RowStore store;
  final dark = ValueNotifier(false);
  GridHandle? handle;
  BatchSink? sink;

  Future<Duration> load({int total = kTotalRows}) =>
      feed(store, total: total, onBatch: (s, b) => sink?.call(s, b));
}

late Harness harness;

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key, required this.builder});
  final GridBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: harness.dark,
      builder: (context, dark, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
        ),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Toolbar(dark: dark),
              Expanded(
                child: RepaintBoundary(
                  key: const ValueKey('grid'),
                  child: Builder(
                    builder: (context) => ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: builder(
                        GridArgs(
                          store: harness.store,
                          dark: dark,
                          onHandle: (h) => harness.handle = h,
                          registerSink: (s) => harness.sink = s,
                        ),
                        harness.mode,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            ListenableBuilder(
              listenable: harness.store,
              builder: (_, _) => Text(
                '${harness.grid}/${harness.mode} · rows ${harness.store.rowCount}'
                '${harness.store.done ? ' (done)' : ''}',
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => harness.load(),
              child: const Text('Load 1M'),
            ),
            TextButton(
              onPressed: () => harness.handle?.jumpToRow(900000),
              child: const Text('Jump 900k'),
            ),
            IconButton(
              onPressed: () => harness.dark.value = !dark,
              icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
        ),
      ),
    );
  }
}
