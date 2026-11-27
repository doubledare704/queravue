import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/documents/application/document_preview_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/gridfs/application/gridfs_controller.dart';
import 'package:queravue/features/gridfs/domain/gridfs_models.dart';
import 'package:queravue/features/mongo_sql/application/mongo_sql_controller.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';
import 'package:queravue/features/shell/application/cursor_page_controller.dart';
import 'package:queravue/features/shell/application/shell_tab_controller.dart';

import 'rss_report.dart';

const _settle = Duration(seconds: 10);
const _database = 'queravue';
const _bucket = 'perf_release';

class ReleaseMemoryScenario {
  ReleaseMemoryScenario(this.container, this.report);

  final ProviderContainer container;
  final RssReport report;

  EditorTabs get _tabs => container.read(editorTabsProvider.notifier);

  Future<void> run() async {
    await _until(
      'core connection',
      () => container.read(coreStatusProvider) is CoreConnected,
    );
    await report.checkpointsHeader();
    await report.idleUntil(const Duration(seconds: 30));
    await report.checkpoint('idle 30 s after launch');

    final profile = await _createProfile();
    try {
      await _connect(profile);
      await report.checkpoint('Mongo connection open', after: _settle);

      await _gridFsRound(profile);

      await _disconnect(profile);
      await report.checkpoint(
        'GridFS closed and disconnected',
        after: const Duration(seconds: 20),
      );

      await _connect(profile);
      await _sqlModeRound(profile);
      await _disconnect(profile);
      await report.checkpoint(
        'SQL mode closed and disconnected',
        after: const Duration(seconds: 20),
      );
    } finally {
      await container.read(connectionsRepositoryProvider).delete(profile.id);
    }
    await report.finish();
  }

  Future<ConnectionProfile> _createProfile() async {
    final host = Platform.environment['MONGO_HOST'] ?? '127.0.0.1';
    final port = Platform.environment['MONGO_PORT'] ?? '27017';
    final profile = await container
        .read(connectionsRepositoryProvider)
        .create(
          ConnectionProfile(
            name: 'Release perf',
            engineId: 'mongodb',
            params: {'hosts': '$host:$port', 'replica_set': 'rs0'},
          ),
        );
    await container.read(connectionsControllerProvider.notifier).reload();
    container.read(selectedConnectionProvider.notifier).select(profile.id);
    return profile;
  }

  Future<void> _connect(ConnectionProfile profile) async {
    final session = await container
        .read(connectionSessionProvider(profile.id).notifier)
        .connect();
    if (session == null) throw StateError('could not connect to MongoDB');
  }

  Future<void> _disconnect(ConnectionProfile profile) => container
      .read(connectionSessionProvider(profile.id).notifier)
      .disconnect();

  Future<void> _gridFsRound(ConnectionProfile profile) async {
    final scratch = await Directory.systemTemp.createTemp('queravue-perf-');
    try {
      var tab = _openBucket(profile);
      await _untilIdle(tab);
      await report.checkpoint('GridFS bucket open', after: _settle);
      _tabs.close(tab.id);
      await report.checkpoint('GridFS tab closed', after: _settle);

      tab = _openBucket(profile);
      await _untilIdle(tab);
      final controller = container.read(
        gridFsControllerProvider(tab.id).notifier,
      );
      final stamp = DateTime.now().microsecondsSinceEpoch;

      final bitmap = await _upload(
        controller,
        await _createBitmap(scratch),
        GridFsUpload(filename: 'perf-$stamp.bmp', contentType: 'image/bmp'),
        tab,
      );
      for (final round in ['first', 'second']) {
        final cachedBefore =
            PaintingBinding.instance.imageCache.currentSizeBytes;
        await controller.select(bitmap);
        await _until(
          'image decode',
          () =>
              PaintingBinding.instance.imageCache.currentSizeBytes >
              cachedBefore,
        );
        await report.checkpoint(
          '32 MiB image preview open ($round)',
          after: _settle,
        );
        await controller.select(null);
        await report.checkpoint(
          'image preview cleared ($round)',
          after: _settle,
        );
        await _forceGarbageCollection();
        await report.checkpoint('image preview cleared ($round), GC probe');
      }

      final big = File('${scratch.path}/1gib.bin');
      final writer = await big.open(mode: FileMode.write);
      await writer.truncate(1024 * gridFsChunkBytes);
      await writer.close();
      late GridFsEntry entry;
      await report.peakDuring('Upload 1 GiB', () async {
        entry = await _upload(
          controller,
          big,
          GridFsUpload(filename: 'perf-$stamp.bin'),
          tab,
        );
      });
      await report.peakDuring(
        'Download 1 GiB',
        () => controller.download(entry, File('${scratch.path}/1gib.out')),
      );
      await report.checkpoint(
        'after 1 GiB upload and download',
        after: _settle,
      );

      for (final file in [entry, bitmap]) {
        await controller.delete(
          file,
          production: false,
          confirm: (_) async => true,
        );
      }
      _tabs.close(tab.id);
    } finally {
      await scratch.delete(recursive: true);
    }
  }

  EditorTab _openBucket(ConnectionProfile profile) => _tabs.openGridFs(
    profile.id,
    const TableRef(database: _database, table: _bucket),
  );

  Future<void> _untilIdle(EditorTab tab) async {
    await WidgetsBinding.instance.endOfFrame;
    await _until(
      'bucket listing',
      () => container.read(gridFsControllerProvider(tab.id)).work == null,
    );
  }

  Future<GridFsEntry> _upload(
    GridFsController controller,
    File source,
    GridFsUpload metadata,
    EditorTab tab,
  ) async {
    await controller.upload(
      source,
      metadata,
      production: false,
      confirm: (_) async => true,
    );
    final state = container.read(gridFsControllerProvider(tab.id));
    if (state.error != null) throw StateError('upload failed: ${state.error}');
    return state.page.files.singleWhere((f) => f.filename == metadata.filename);
  }

  Future<void> _sqlModeRound(ConnectionProfile profile) async {
    final tab = _tabs.openMongoSql(profile.id, database: _database);
    tab.controller.text = 'SELECT * FROM events';
    final provider = mongoSqlControllerProvider(tab);
    await _until(
      'SQL translation',
      () => container.read(provider).current != null,
    );
    await container.read(provider.notifier).preview();
    await _until(
      'preview rows',
      () => container.read(documentPreviewProvider(tab.id)).docs.isNotEmpty,
    );
    await container.read(provider.notifier).run();
    await _until('cursor rows', () {
      final cursor = cursorOf(container.read(shellTabProvider(tab.id)));
      return cursor != null &&
          container.read(cursorPageProvider(cursor)).docs.isNotEmpty;
    });
    await report.checkpoint('SQL mode tab with results open', after: _settle);
    _tabs.close(tab.id);
    await report.checkpoint('SQL mode tab closed', after: _settle);
  }

  Future<void> _forceGarbageCollection() async {
    for (var i = 0; i < 400; i++) {
      Uint8List(1024 * 1024);
      if (i % 20 == 0) await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _until(
    String what,
    FutureOr<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException('timed out waiting for $what');
  }
}

Future<File> _createBitmap(Directory dir) async {
  const width = 4096;
  const height = 2700;
  const pixelBytes = width * height * 3;
  const length = 32 * gridFsChunkBytes;
  final header = ByteData(54)
    ..setUint16(0, 0x4d42, Endian.little)
    ..setUint32(2, length, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, width, Endian.little)
    ..setInt32(22, height, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, pixelBytes, Endian.little);
  final file = File('${dir.path}/32mib.bmp');
  final output = await file.open(mode: FileMode.write);
  await output.writeFrom(header.buffer.asUint8List());
  await output.truncate(length);
  await output.close();
  return file;
}

Future<void> disposeCore(ProviderContainer container) =>
    container.read(coreSupervisorProvider).dispose();
