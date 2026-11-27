import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';

Future<int> residentKiB(int pid) async {
  final result = await Process.run('ps', ['-o', 'rss=', '-p', '$pid']);
  return int.parse(result.stdout.toString().trim());
}

Future<int> footprintKiB(int pid) async {
  final result = await Process.run('footprint', [
    '-f',
    'bytes',
    '--noCategories',
    '-p',
    '$pid',
  ]);
  final bytes = RegExp(r'Footprint: (\d+) B')
      .firstMatch(result.stdout.toString());
  return bytes == null ? 0 : int.parse(bytes.group(1)!) ~/ 1024;
}

String _mib(int kib) => (kib / 1024).toStringAsFixed(1);

class RssReport {
  RssReport({required this.corePid, required this.output, this.reportPath});

  final String? reportPath;
  final int corePid;
  final IOSink output;
  final _sinceLaunch = Stopwatch()..start();
  final _peakRows = <String>[];

  Future<void> idleUntil(Duration sinceLaunch) async {
    final remaining = sinceLaunch - _sinceLaunch.elapsed;
    if (!remaining.isNegative) await Future<void>.delayed(remaining);
  }

  Future<void> _writeCategories(String label) async {
    final result = await Process.run('footprint', ['-p', '$pid']);
    final rows = result.stdout.toString().split('\n').skip(4).take(14);
    final file = File('${reportPath!}.categories.txt');
    await file.writeAsString(
      '## $label\n${rows.join('\n')}\n\n',
      mode: FileMode.append,
    );
  }

  Future<void> checkpointsHeader() => _write([
    '| Checkpoint | App RSS MiB | App footprint MiB | Core RSS MiB | Combined RSS MiB | Image cache MiB |',
    '|---|---:|---:|---:|---:|---:|',
  ]);

  Future<void> checkpoint(
    String label, {
    Duration after = Duration.zero,
  }) async {
    await Future<void>.delayed(after);
    final app = await residentKiB(pid);
    final footprint = await footprintKiB(pid);
    final core = await residentKiB(corePid);
    final cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
    if (reportPath != null) await _writeCategories(label);
    await _write([
      '| $label | ${_mib(app)} | ${_mib(footprint)} | ${_mib(core)} | ${_mib(app + core)} '
          '| ${(cacheBytes / (1024 * 1024)).toStringAsFixed(1)} |',
    ]);
  }

  Future<void> finish() => _write([
    '',
    '| Operation | App MiB before | App MiB peak | App MiB after | Core MiB peak | Seconds |',
    '|---|---:|---:|---:|---:|---:|',
    ..._peakRows,
  ]);

  Future<void> peakDuring(String label, Future<void> Function() run) async {
    final before = await residentKiB(pid);
    var peak = before;
    var corePeak = await residentKiB(corePid);
    var running = true;
    final sampler = Future<void>(() async {
      while (running) {
        peak = math.max(peak, await residentKiB(pid));
        corePeak = math.max(corePeak, await residentKiB(corePid));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    final elapsed = Stopwatch()..start();
    try {
      await run();
    } finally {
      running = false;
      await sampler;
    }
    final after = await residentKiB(pid);
    corePeak = math.max(corePeak, await residentKiB(corePid));
    _peakRows.add(
      '| $label | ${_mib(before)} | ${_mib(math.max(peak, after))} '
      '| ${_mib(after)} | ${_mib(corePeak)} | ${elapsed.elapsed.inSeconds} |',
    );
  }

  Future<void> _write(List<String> lines) async {
    lines.forEach(output.writeln);
    await output.flush();
  }
}
