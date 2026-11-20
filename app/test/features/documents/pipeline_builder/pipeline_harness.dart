import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queravue/features/documents/application/document_preview_controller.dart';
import 'package:queravue/features/documents/pipeline_builder/application/pipeline_builder_controller.dart';
import 'package:queravue/features/schema/data/schema_repository.dart';
import 'package:queravue/features/shell/data/shell_repository.dart';
import 'package:queravue/features/shell/domain/shell_models.dart';

import '../../../support/document_harness.dart';
import '../../../support/fake_document_repository.dart';
import '../../../support/shell_workspace_fakes.dart';

const pipelineTarget = PipelineTarget(
  connectionId: 'c1',
  database: 'shop',
  collection: 'orders',
);

final aggregateCursor = ShellCursorEvent(
  const CursorHandle(
    cursorId: 'cur1',
    kind: CursorKind.aggregate,
    database: 'shop',
    collection: 'orders',
  ),
);

class PipelineHarness {
  PipelineHarness() {
    shell.cursorDocs = [fakeDoc(1), fakeDoc(2)];
    container = ProviderContainer(
      overrides: [
        ...documentOverrides(docs),
        shellRepositoryProvider.overrideWithValue(shell),
        schemaRepositoryProvider.overrideWithValue(EmptySchemaRepository()),
      ],
    );
  }

  final docs = FakeDocumentRepository();
  final shell = FakeShellRepository();
  late final ProviderContainer container;

  PipelineBuilderController get controller =>
      container.read(pipelineBuilderProvider(pipelineTarget).notifier);

  PipelineBuilderState get state =>
      container.read(pipelineBuilderProvider(pipelineTarget));

  DocumentPreviewState get preview =>
      container.read(documentPreviewProvider(pipelineTarget));

  void queueCursor() =>
      shell.scripts.add([aggregateCursor, const ShellDone(Duration.zero)]);
}
