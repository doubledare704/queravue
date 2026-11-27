import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/image_cache_limits.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  limitImageCache();
  runApp(const ProviderScope(child: QueravueApp()));
}
