import 'dart:io';
import 'dart:typed_data';

enum SpikeFixture {
  onePage('one_page', 'one_page.pdf', '1-page PDF'),
  text300('text_300', 'text_300_pages.pdf', '300-page text PDF'),
  images30MiB('images_30mib', 'images_30mib.pdf', '30 MiB image-heavy PDF');

  const SpikeFixture(this.id, this.fileName, this.label);

  final String id;
  final String fileName;
  final String label;

  static SpikeFixture fromId(String id) {
    return SpikeFixture.values.firstWhere(
      (f) => f.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown fixture id'),
    );
  }
}

Directory resolveFixturesDir() {
  final override = Platform.environment['SPIKE_FIXTURES_DIR'];
  if (override != null && override.isNotEmpty) {
    return Directory(override);
  }

  final cwdCandidate = Directory('build${Platform.pathSeparator}fixtures');
  if (cwdCandidate.existsSync()) {
    return cwdCandidate;
  }

  // When launched directly from .app/Contents/MacOS/pdf_spike, walk up to spikes/pdf/.
  var cursor = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory(
      '${cursor.path}${Platform.pathSeparator}build${Platform.pathSeparator}fixtures',
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) break;
    cursor = parent;
  }

  return cwdCandidate;
}

Future<Uint8List> loadFixtureBytes(SpikeFixture fixture) {
  final dir = resolveFixturesDir();
  final file = File('${dir.path}${Platform.pathSeparator}${fixture.fileName}');
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture ${file.path}. Run python3 tool/generate_fixtures.py first.',
    );
  }
  return file.readAsBytes();
}
