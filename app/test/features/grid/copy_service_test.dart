import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/domain/cancellation.dart';
import 'package:queravue/features/editor/domain/query_models.dart';
import 'package:queravue/features/grid/application/copy_service.dart';

import '../../support/fake_query_repository.dart';

void main() {
  test('copyViaCore joins chunks and reports progress', () async {
    final repo = FakeQueryRepository()..copyChunks = ['a\n', 'b\n', 'c\n'];
    final progress = <int>[];
    final text = await copyViaCore(
      repo,
      resultId: 'r',
      start: 0,
      end: 3,
      columns: const [0],
      format: CopyFormat.tsv,
      includeHeader: false,
      onProgress: progress.add,
    );
    expect(text, 'a\nb\nc\n');
    expect(progress, [1, 2, 3]);
  });

  test('cancelling stops the copy and cancels the stream', () async {
    final repo = FakeQueryRepository()
      ..copyChunks = ['a\n']
      ..copyHold = Completer<void>();
    final token = CancellationToken();
    final f = copyViaCore(
      repo,
      resultId: 'r',
      start: 0,
      end: 1000000,
      columns: const [],
      format: CopyFormat.tsv,
      includeHeader: false,
      cancel: token,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    token.cancel();
    await expectLater(f, throwsA(isA<OperationCancelled>()));
    expect(repo.copyCancelled, greaterThanOrEqualTo(1));
  });

  test('errors from the core propagate', () async {
    final repo = _ErrorCopy();
    await expectLater(
      copyViaCore(
        repo,
        resultId: 'r',
        start: 0,
        end: 1,
        columns: const [],
        format: CopyFormat.tsv,
        includeHeader: false,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

class _ErrorCopy extends FakeQueryRepository {
  @override
  Stream<CopyChunk> copyRange({
    required String resultId,
    required int start,
    required int end,
    List<int> columns = const [],
    CopyFormat format = CopyFormat.tsv,
    bool includeHeader = false,
  }) => Stream.error(StateError('boom'));
}
