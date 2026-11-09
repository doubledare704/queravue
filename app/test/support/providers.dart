import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queravue/features/completion/application/user_snippets.dart';
import 'package:queravue/features/completion/data/completion_repository.dart';
import 'package:queravue/features/completion/domain/snippets.dart';

import 'fake_completion.dart';
import 'fake_keybindings.dart';
import 'fake_layout.dart';

import 'package:queravue/features/editor/application/layout_persistence.dart';

import 'package:queravue/features/keybindings/application/keybindings_controller.dart';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';

import 'fake_connections_repository.dart';

/// Overrides that replace the core with [repo].
List<Override> fakeCoreOverrides(
  FakeConnectionsRepository repo, {
  bool ready = true,
  bool fakeLayoutPersistence = true,
}) => [
  connectionsRepositoryProvider.overrideWithValue(repo),
  coreReadyProvider.overrideWithValue(ready),
  completionRepositoryProvider.overrideWithValue(FakeCompletionRepository()),
  userSnippetsProvider.overrideWith((ref) async => const <Snippet>[]),
  keybindingsProvider.overrideWith(FakeKeybindings.new),
  if (fakeLayoutPersistence)
    layoutPersistenceProvider.overrideWith(NoLayoutPersistence.new),
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
