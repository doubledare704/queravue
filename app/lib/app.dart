import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_client/core_providers.dart';
import 'shared/widgets/status_bar.dart';

/// Root widget.
class QueravueApp extends ConsumerStatefulWidget {
  const QueravueApp({super.key});

  @override
  ConsumerState<QueravueApp> createState() => _QueravueAppState();
}

class _QueravueAppState extends ConsumerState<QueravueApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop the core gracefully on quit. If the app dies instead, the core
    // sees EOF on stdin and exits on its own.
    _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
  }

  Future<AppExitResponse> _onExitRequested() async {
    await ref.read(coreSupervisorProvider).dispose();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queravue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Main window: an empty workspace for now, plus the status bar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Queravue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      bottomNavigationBar: const StatusBar(),
    );
  }
}
