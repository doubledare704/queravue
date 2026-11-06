import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/documents/application/document_tab_controller.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/editor/data/query_repository.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import 'fake_connections_repository.dart';
import 'fake_document_repository.dart';
import 'fake_query_repository.dart';
import 'providers.dart';

/// A MongoDB-like engine for tests.
const mongoEngine = EngineSpec(
  id: 'mongodb',
  displayName: 'MongoDB',
  family: 'mongodb',
  supportsUri: true,
  capabilities: {'connect', 'schema_inspector', 'document_store'},
  fields: [FieldSpec(key: 'hosts', label: 'Hosts', required: true)],
);

/// Overrides for a document tab test: connection `c1` (production if asked),
/// a fake session and [docs].
List<Override> documentOverrides(
  FakeDocumentRepository docs, {
  bool production = false,
  FakeQueryRepository? query,
}) => [
  documentRepositoryProvider.overrideWithValue(docs),
  queryRepositoryProvider.overrideWithValue(
    query ??
        (FakeQueryRepository()..capabilities = {'connect', 'document_store'}),
  ),
  ...fakeCoreOverrides(
    FakeConnectionsRepository(
      initial: [
        ConnectionProfile(
          id: 'c1',
          name: 'Mongo',
          engineId: 'mongodb',
          production: production,
        ),
      ],
    )..engines = [mongoEngine],
  ),
];

ProviderContainer makeDocContainer(
  FakeDocumentRepository docs, {
  bool production = false,
}) {
  final c = ProviderContainer(
    overrides: documentOverrides(docs, production: production),
  );
  addTearDown(c.dispose);
  return c;
}

/// Opens a collection tab on `shop.users` and returns its id.
String openUsersTab(ProviderContainer c) => c
    .read(editorTabsProvider.notifier)
    .openCollection('c1', const TableRef(database: 'shop', table: 'users'))
    .id;

/// Waits until [test] holds, pumping the event loop.
Future<void> waitFor(bool Function() test, {int tries = 200}) async {
  for (var i = 0; i < tries; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not reached');
}

/// Waits until the tab has finished its first query.
Future<void> loaded(ProviderContainer c, String tabId) => waitFor(() {
  final s = c.read(documentTabProvider(tabId));
  return s.loaded && !s.isLoading;
});
