import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/core_client/core_launcher.dart';

void main() {
  late Directory root;

  setUp(() async => root = await Directory.systemTemp.createTemp('sweep'));
  tearDown(() => root.delete(recursive: true));

  Directory makeDir(String name) =>
      Directory('${root.path}/$name')..createSync();

  test(
    'removes stale queravue dirs and keeps live, fresh and foreign ones',
    () async {
      final empty = makeDir('queravue-empty');
      final deadSock = makeDir('queravue-dead');
      // A socket file nobody listens on, as left by a SIGKILLed core.
      final dead = await ServerSocket.bind(
        InternetAddress(
          '${deadSock.path}/core.sock',
          type: InternetAddressType.unix,
        ),
        0,
      );
      await dead.close(); // Dart leaves the socket file behind on close.
      if (FileSystemEntity.typeSync('${deadSock.path}/core.sock') !=
          FileSystemEntityType.unixDomainSock) {
        File('${deadSock.path}/core.sock').createSync(); // fallback: stale file
      }

      final liveDir = makeDir('queravue-live');
      final live = await ServerSocket.bind(
        InternetAddress(
          '${liveDir.path}/core.sock',
          type: InternetAddressType.unix,
        ),
        0,
      );
      addTearDown(live.close);
      final foreign = makeDir('other-tool');

      final removed = await sweepStaleSocketDirs(root, minAge: Duration.zero);

      expect(removed, 2);
      expect(empty.existsSync(), isFalse);
      expect(deadSock.existsSync(), isFalse);
      expect(liveDir.existsSync(), isTrue);
      expect(foreign.existsSync(), isTrue);
    },
  );

  test('keeps directories younger than minAge', () async {
    final fresh = makeDir('queravue-fresh');
    expect(await sweepStaleSocketDirs(root), 0);
    expect(fresh.existsSync(), isTrue);
  });
}
