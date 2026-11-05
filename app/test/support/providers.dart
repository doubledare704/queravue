import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';

import 'fake_connections_repository.dart';

/// Overrides that replace the core with [repo].
List<Override> fakeCoreOverrides(
  FakeConnectionsRepository repo, {
  bool ready = true,
}) => [
  connectionsRepositoryProvider.overrideWithValue(repo),
  coreReadyProvider.overrideWithValue(ready),
];

/// A container backed by [repo], disposed after the test.
ProviderContainer makeContainer(
  FakeConnectionsRepository repo, {
  bool ready = true,
}) {
  final c = ProviderContainer(overrides: fakeCoreOverrides(repo, ready: ready));
  addTearDown(c.dispose);
  return c;
}
