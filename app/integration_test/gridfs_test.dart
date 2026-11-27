import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:queravue/app.dart';
import 'package:queravue/core_client/core_providers.dart';
import 'package:queravue/core_client/core_supervisor.dart';
import 'package:queravue/features/connections/application/connection_session.dart';
import 'package:queravue/features/connections/application/connections_controller.dart';
import 'package:queravue/features/connections/data/connections_repository.dart';
import 'package:queravue/features/connections/domain/models.dart';
import 'package:queravue/features/core_status/core_status_controller.dart';
import 'package:queravue/features/editor/application/editor_tabs.dart';
import 'package:queravue/features/gridfs/application/gridfs_controller.dart';
import 'package:queravue/features/gridfs/data/gridfs_repository.dart';
import 'package:queravue/features/gridfs/domain/gridfs_models.dart';
import 'package:queravue/features/gridfs/presentation/gridfs_preview_panel.dart';
import 'package:queravue/features/schema/domain/schema_models.dart';

import 'support/settle.dart';

const _measure = bool.fromEnvironment('GRIDFS_PERF');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GridFS uploads, previews, downloads and deletes through MongoDB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QueravueApp(),
      ),
    );
    await pumpUntilServer(
      tester,
      'core connection',
      () async => container.read(coreStatusProvider) is CoreConnected,
    );
    final profiles = container.read(connectionsRepositoryProvider);
    final host = Platform.environment['MONGO_HOST'] ?? '127.0.0.1';
    final port = Platform.environment['MONGO_PORT'] ?? '27017';
    final profile = await profiles.create(
      ConnectionProfile(
        name: 'GridFS e2e',
        engineId: 'mongodb',
        production: true,
        params: {'hosts': '$host:$port', 'replica_set': 'rs0'},
      ),
    );
    addTearDown(() => profiles.delete(profile.id));
    await container.read(connectionsControllerProvider.notifier).reload();
    container.read(selectedConnectionProvider.notifier).select(profile.id);
    final session = await container
        .read(connectionSessionProvider(profile.id).notifier)
        .connect();
    expect(session?.capabilities, contains('gridfs'));

    final tabs = container.read(editorTabsProvider.notifier);
    final bucket = 'gridfs_e2e';
    final tab = tabs.openGridFs(
      profile.id,
      TableRef(database: 'queravue', table: bucket),
    );
    final provider = gridFsControllerProvider(tab.id);
    final controller = container.read(provider.notifier);
    GridFsState state() => container.read(provider);
    await pumpUntilServer(
      tester,
      'bucket listing',
      () async => state().work == null,
    );
    expect(state().error, isNull);

    final dir = await Directory.systemTemp.createTemp('queravue-gridfs-e2e-');
    addTearDown(() => dir.delete(recursive: true));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final appRss = _RssSampler(pid);
    final coreRss = _RssSampler(
      container.read(coreSupervisorProvider).corePid!,
    );
    if (_measure) {
      final app = await appRss.rss();
      final core = await coreRss.rss();
      debugPrint(
        'GRIDFS_RSS before app=$app core=$core combined=${app + core} KiB',
      );
    }
    final files = <GridFsEntry>[];

    Future<GridFsEntry> upload(File source, GridFsUpload metadata) async {
      await controller.upload(
        source,
        metadata,
        production: true,
        confirm: (_) async => true,
      );
      expect(state().error, isNull);
      final file = state().page.files.singleWhere(
        (f) => f.filename == metadata.filename,
      );
      files.add(file);
      return file;
    }

    try {
      final source = File('${dir.path}/note.txt');
      await source.writeAsString('A GridFS round trip.\n');
      final note = await upload(
        source,
        GridFsUpload(filename: 'note-$stamp.txt', contentType: 'text/plain'),
      );
      await tester.pump();
      expect(find.text(note.filename), findsOneWidget);
      await tester.tap(find.text(note.filename));
      await pumpUntilServer(
        tester,
        'text preview',
        () async => state().selection?.preview != null,
      );
      await tester.pump();
      expect(find.byType(GridFsPreviewPanel), findsOneWidget);
      expect(find.text('A GridFS round trip.'), findsOneWidget);

      final downloaded = File('${dir.path}/download.txt');
      await controller.download(note, downloaded);
      expect(state().error, isNull);
      expect(await downloaded.readAsString(), await source.readAsString());
      final target = state().target!;
      expect(
        await container
            .read(gridFsRepositoryProvider)
            .listBuckets(target.scope),
        contains(bucket),
      );

      await controller.rename(note, 'renamed-$stamp.txt');
      expect(state().error, isNull);
      final renamed = state().page.files.singleWhere(
        (file) => file.id == note.id,
      );
      expect(renamed.filename, 'renamed-$stamp.txt');
      final replacement = await upload(
        source,
        GridFsUpload(filename: 'replacement-$stamp.txt', replaceId: note.id),
      );
      expect(state().page.files.map((f) => f.id), isNot(contains(note.id)));
      files.remove(note);
      await controller.delete(
        replacement,
        production: true,
        confirm: (_) async => true,
      );
      expect(state().error, isNull);
      expect(
        state().page.files.map((f) => f.id),
        isNot(contains(replacement.id)),
      );
      files.remove(replacement);

      if (_measure) {
        final big = File('${dir.path}/1gib.bin');
        final writer = await big.open(mode: FileMode.write);
        await writer.truncate(1024 * gridFsChunkBytes);
        await writer.close();
        late GridFsEntry entry;
        await appRss.measure('upload 1 GiB', () async {
          entry = await upload(big, GridFsUpload(filename: 'perf-$stamp.bin'));
        });
        final output = File('${dir.path}/1gib.out');
        await appRss.measure(
          'download 1 GiB',
          () => controller.download(entry, output),
        );
        expect(state().error, isNull);
        expect(await output.length(), await big.length());

        final image = await _createBitmap(dir);
        final bitmap = await upload(
          image,
          GridFsUpload(filename: 'perf-$stamp.bmp', contentType: 'image/bmp'),
        );
        final cache = PaintingBinding.instance.imageCache;
        final cachedBefore = cache.currentSizeBytes;
        await appRss.measure('preview 32 MiB BMP', () async {
          await controller.select(bitmap);
          await pumpUntilServer(tester, 'image decode', () async {
            final finder = find.descendant(
              of: find.byType(GridFsPreviewPanel),
              matching: find.byType(RawImage),
            );
            return finder.evaluate().isNotEmpty &&
                tester.widget<RawImage>(finder).image != null;
          });
          expect(
            state().selection?.preview?.file?.lengthSync(),
            32 * gridFsChunkBytes,
          );
        });
        await controller.select(null);
        await tester.pump();
        await Future<void>.delayed(const Duration(seconds: 10));
        expect(cache.currentSizeBytes, lessThanOrEqualTo(cachedBefore));
        debugPrint('GRIDFS_RSS released app=${await appRss.rss()} KiB at 10 s');
      }
    } finally {
      for (final file in files) {
        await controller.delete(
          file,
          production: true,
          confirm: (_) async => true,
        );
      }
      tabs.close(tab.id);
      await tester.pump();
      await container
          .read(connectionSessionProvider(profile.id).notifier)
          .disconnect();
    }
    if (_measure) {
      await Future<void>.delayed(const Duration(seconds: 20));
      final app = await appRss.rss();
      final core = await coreRss.rss();
      debugPrint(
        'GRIDFS_RSS idle app=$app core=$core combined=${app + core} KiB at 20 s',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<File> _createBitmap(Directory dir) async {
  const width = 4096;
  const height = 2700;
  const pixelBytes = width * height * 3;
  const length = 32 * gridFsChunkBytes;
  final bytes = ByteData(54)
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
  await output.writeFrom(bytes.buffer.asUint8List());
  await output.truncate(length);
  await output.close();
  return file;
}

class _RssSampler {
  _RssSampler(this.pid);

  final int pid;

  Future<int> rss() async {
    final result = await Process.run('ps', ['-o', 'rss=', '-p', '$pid']);
    return int.parse(result.stdout.toString().trim());
  }

  Future<void> measure(String label, Future<void> Function() run) async {
    final baseline = await rss();
    var peak = baseline;
    var running = true;
    var samples = 0;
    final elapsed = Stopwatch()..start();
    final sampler = Future<void>(() async {
      while (running) {
        peak = math.max(peak, await rss());
        samples++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    try {
      await run();
    } finally {
      running = false;
      await sampler;
    }
    final after = await rss();
    peak = math.max(peak, after);
    debugPrint(
      'GRIDFS_RSS $label base=$baseline peak=$peak after=$after KiB, '
      '$samples samples in ${elapsed.elapsedMilliseconds} ms',
    );
  }
}
