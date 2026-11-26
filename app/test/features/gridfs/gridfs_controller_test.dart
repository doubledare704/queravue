import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/connections/domain/cancellation.dart';
import 'package:queravue/features/gridfs/application/gridfs_controller.dart';
import 'package:queravue/features/gridfs/application/gridfs_preview.dart';
import 'package:queravue/features/gridfs/data/gridfs_preview_files.dart';
import 'package:queravue/features/gridfs/data/gridfs_repository.dart';
import 'package:queravue/features/gridfs/domain/gridfs_models.dart';

const _target = (scope: (sessionId: 'session', database: 'test'), bucket: 'fs');
final _provider = gridFsControllerProvider;

GridFsEntry _entry(String id, {int length = 0, String contentType = ''}) =>
    GridFsEntry(
      id: id,
      filename: 'file-$id',
      length: length,
      contentType: contentType,
      uploadDate: DateTime.utc(2026),
    );

class _RecordingPreviewFiles extends GridFsPreviewFiles {
  final live = <String>{};

  @override
  Future<File> create(String name) async {
    final file = await super.create(name);
    live.add(file.path);
    return file;
  }

  @override
  Future<void> delete(File file) {
    live.remove(file.path);
    return super.delete(file);
  }
}

class _Repository extends Fake implements GridFsRepository {
  final queries = <({int skip, int limit, String filter, String sort})>[];
  final ranges = <({int offset, int? length})>[];
  final files = <GridFsEntry>[];
  final bytes = <String, List<int>>{};
  final deleteConfirmations = <bool>[];
  final uploadConfirmations = <bool>[];
  final firstChunk = Completer<int>();
  Stream<GridFsEntry>? stalledListing;
  bool stopMidUpload = false;
  bool requireConfirmation = false;

  @override
  Stream<GridFsEntry> listFiles(
    GridFsTarget target, {
    required String filter,
    required String sort,
    required int skip,
    required int limit,
  }) {
    queries.add((skip: skip, limit: limit, filter: filter, sort: sort));
    expect(target, _target);
    return stalledListing ?? Stream.fromIterable(files.skip(skip).take(limit));
  }

  @override
  Stream<List<int>> download(
    GridFsTarget target,
    String id, {
    required CancellationToken cancel,
    int offset = 0,
    int? length,
  }) async* {
    ranges.add((offset: offset, length: length));
    final data = bytes[id]!;
    yield data.skip(offset).take(length ?? data.length).toList();
  }

  @override
  Future<GridFsEntry> upload(
    GridFsTarget target,
    GridFsUpload upload,
    Stream<List<int>> bytes, {
    required CancellationToken cancel,
    required bool confirmed,
  }) async {
    uploadConfirmations.add(confirmed);
    if (requireConfirmation && !confirmed) {
      throw const GridFsFailure(
        GridFsFailureKind.confirmationRequired,
        'replace',
      );
    }
    await for (final chunk in bytes) {
      if (!firstChunk.isCompleted) firstChunk.complete(chunk.length);
      if (stopMidUpload) await cancel.whenCancelled;
    }
    return _entry('uploaded');
  }

  @override
  Future<void> delete(
    GridFsTarget target,
    String id, {
    required bool confirmed,
  }) async {
    deleteConfirmations.add(confirmed);
    if (requireConfirmation && !confirmed) {
      throw const GridFsFailure(
        GridFsFailureKind.confirmationRequired,
        'delete',
      );
    }
    files.removeWhere((file) => file.id == id);
  }
}

void main() {
  late _Repository repository;
  late _RecordingPreviewFiles previewFiles;
  late ProviderContainer container;
  late GridFsController controller;
  GridFsState state() => container.read(_provider('tab'));

  setUp(() async {
    repository = _Repository();
    previewFiles = _RecordingPreviewFiles();
    container = ProviderContainer.test(
      overrides: [
        gridFsRepositoryProvider.overrideWithValue(repository),
        gridFsPreviewFilesProvider.overrideWithValue(previewFiles),
        gridFsTargetProvider('tab').overrideWithValue(_target),
      ],
    );
    container.listen(_provider('tab'), (_, _) {});
    controller = container.read(_provider('tab').notifier);
    await controller.refresh();
    repository.queries.clear();
  });

  test(
    'EJSON listing takes one extra row and keeps only the visible page',
    () async {
      repository.files.addAll(List.generate(101, (i) => _entry('$i')));
      await controller.apply('{"filename":"file"}', '{"filename":1}');
      expect(repository.queries.single, (
        skip: 0,
        limit: 101,
        filter: '{"filename":"file"}',
        sort: '{"filename":1}',
      ));
      expect(state().page.files, hasLength(100));
      expect(state().page.hasNext, isTrue);
      await controller.nextPage();
      expect(repository.queries.last.skip, 100);
      expect(state().page.files.single.id, '100');
      expect(state().page.hasNext, isFalse);
    },
  );

  test('slow listing exposes cancel and cancels its subscription', () async {
    final canceled = Completer<void>();
    final stream = StreamController<GridFsEntry>(onCancel: canceled.complete);
    addTearDown(stream.close);
    repository.stalledListing = stream.stream;
    final pending = controller.refresh();
    expect(state().work?.canCancel, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 330));
    expect(state().work?.canCancel, isTrue);
    controller.cancel();
    await pending;
    await canceled.future;
    expect(state().work, isNull);
    expect(state().error, isNull);
  });

  test(
    'preview samples 512 bytes then reads the rest with an offset',
    () async {
      final file = _entry('text', length: 800);
      repository.bytes[file.id] = utf8.encode('a' * file.length);
      await controller.select(file);
      expect(repository.ranges, [
        (offset: 0, length: 512),
        (offset: 512, length: 288),
      ]);
      expect(state().selection?.preview?.kind, GridFsPreviewKind.text);
      expect(state().selection?.preview?.lines?.join(), 'a' * file.length);
      await controller.select(null);
      expect(state().selection, isNull);
    },
  );

  test('declared text falls back to hex for invalid UTF-8', () async {
    final file = _entry(
      'binary',
      length: 3,
      contentType: 'text/plain; charset=utf-8',
    );
    repository.bytes[file.id] = [65, 255, 66];
    await controller.select(file);
    expect(repository.ranges.single, (offset: 0, length: 3));
    expect(state().selection?.preview?.kind, GridFsPreviewKind.hex);
    expect(state().selection?.preview?.bytes, [65, 255, 66]);
  });

  test('large files fetch at most the sniffing range', () async {
    final file = _entry('pdf', length: 32 * gridFsChunkBytes + 1);
    repository.bytes[file.id] = [
      ...'%PDF-1.4'.codeUnits,
      ...List.filled(504, 0),
    ];
    await controller.select(file);
    expect(repository.ranges.single, (offset: 0, length: 512));
    expect(state().selection?.preview?.kind, GridFsPreviewKind.pdf);
    expect(state().selection?.preview?.tooLarge, isTrue);
  });

  test(
    'image preview lives in a temp file that selection change deletes',
    () async {
      final image = _entry('png', length: 600, contentType: 'image/png');
      repository.bytes[image.id] = List.generate(600, (i) => i % 251);
      await controller.select(image);
      final preview = state().selection!.preview!;
      expect(preview.kind, GridFsPreviewKind.image);
      expect(preview.bytes, isNull);
      expect(await preview.file!.readAsBytes(), repository.bytes[image.id]);
      await controller.select(null);
      expect(preview.file!.existsSync(), isFalse);
    },
  );

  test('PDF preview files stay until the tab closes', () async {
    final pdf = _entry('pdf', length: 8, contentType: 'application/pdf');
    repository.bytes[pdf.id] = '%PDF-1.4'.codeUnits;
    await controller.select(pdf);
    final file = state().selection!.preview!.file!;
    expect(file.path, endsWith('preview.pdf'));
    await controller.select(null);
    expect(file.existsSync(), isTrue);
    container.dispose();
    await pumpEventQueue();
    expect(file.existsSync(), isFalse);
  });

  test('a failed image download leaves no temp file behind', () async {
    final image = _entry('short', length: 600, contentType: 'image/png');
    repository.bytes[image.id] = List.filled(10, 1);
    await controller.select(image);
    expect(state().selection?.error, isNotNull);
    expect(previewFiles.live, isEmpty);
  });

  test('sniffing recognizes supported image signatures', () {
    for (final signature in [
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      [0xff, 0xd8, 0xff],
      'GIF87a'.codeUnits,
      'GIF89a'.codeUnits,
      'RIFF0000WEBP'.codeUnits,
      'BM'.codeUnits,
    ]) {
      expect(
        sniffGridFsType(Uint8List.fromList(signature)),
        GridFsPreviewKind.image,
      );
    }
  });

  test('upload streams 1 MiB chunks and can be cancelled mid-upload', () async {
    await controller.refresh();
    final source = await _source(2 * gridFsChunkBytes);
    repository.stopMidUpload = true;
    final upload = controller.upload(
      source,
      const GridFsUpload(filename: 'source'),
      production: false,
      confirm: (_) async =>
          throw StateError('new upload asks for confirmation'),
    );
    expect(await repository.firstChunk.future, gridFsChunkBytes);
    expect(state().work?.canCancel, isTrue);
    controller.cancel();
    await upload;
    expect(state().work, isNull);
    expect(state().error, isNull);
    expect(repository.queries, hasLength(1));
  });

  test(
    'production replace asks before sending and retries with a fresh stream',
    () async {
      await controller.refresh();
      final source = await _source(12);
      repository.requireConfirmation = true;
      final prompts = <bool>[];
      await controller.upload(
        source,
        const GridFsUpload(filename: 'source', replaceId: 'old'),
        production: true,
        confirm: (production) async {
          expect(repository.uploadConfirmations, isEmpty);
          prompts.add(production);
          return true;
        },
      );
      expect(prompts, [true]);
      expect(repository.uploadConfirmations, [false, true]);
      expect(await repository.firstChunk.future, 12);
      expect(state().error, isNull);
    },
  );

  test('server production check prompts before confirming a delete', () async {
    final file = _entry('delete');
    repository.files.add(file);
    repository.requireConfirmation = true;
    await controller.refresh();
    final prompts = <bool>[];
    await controller.delete(
      file,
      production: false,
      confirm: (production) async {
        prompts.add(production);
        return !production;
      },
    );
    expect(prompts, [false, true]);
    expect(repository.deleteConfirmations, [false]);
    expect(repository.files, [file]);
    expect(state().error, isNull);
  });
}

Future<File> _source(int length) async {
  final dir = await Directory.systemTemp.createTemp('queravue-gridfs-test-');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}/source');
  final writer = await file.open(mode: FileMode.write);
  await writer.truncate(length);
  await writer.close();
  return file;
}
