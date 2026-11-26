import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../connections/domain/cancellation.dart';
import '../data/gridfs_preview_files.dart';
import '../data/gridfs_repository.dart';
import '../domain/gridfs_models.dart';

enum GridFsPreviewKind { text, hex, image, pdf }

class GridFsPreview {
  const GridFsPreview(this.kind, {this.lines, this.bytes, this.file});

  final GridFsPreviewKind kind;
  final List<String>? lines;
  final Uint8List? bytes;
  final File? file;

  bool get tooLarge => lines == null && bytes == null && file == null;
}

Future<GridFsPreview> loadGridFsPreview(
  GridFsRepository repository,
  GridFsTarget target,
  GridFsEntry file,
  CancellationToken cancel,
  GridFsPreviewFiles files,
) async {
  var kind = _declaredType(file.contentType);
  Uint8List? prefix;
  if (kind == null) {
    prefix = await _readRange(repository, target, file, cancel, 0, 512);
    kind = sniffGridFsType(prefix);
  }
  final cap = switch (kind) {
    GridFsPreviewKind.image || GridFsPreviewKind.pdf => 32 * gridFsChunkBytes,
    GridFsPreviewKind.text || GridFsPreviewKind.hex => gridFsChunkBytes,
  };
  if (file.length > cap) return GridFsPreview(kind);
  if (kind == GridFsPreviewKind.image || kind == GridFsPreviewKind.pdf) {
    final preview = await _downloadToFile(
      repository,
      target,
      file,
      cancel,
      files,
      kind == GridFsPreviewKind.pdf ? 'preview.pdf' : 'preview',
      prefix,
    );
    return GridFsPreview(kind, file: preview);
  }
  final remaining = file.length - (prefix?.length ?? 0);
  final bytes = remaining == 0 && prefix != null
      ? prefix
      : await _readRange(
          repository,
          target,
          file,
          cancel,
          0,
          file.length,
          prefix: prefix,
        );
  if (kind == GridFsPreviewKind.text) {
    try {
      return GridFsPreview(kind, lines: _textLines(utf8.decode(bytes)));
    } on FormatException {
      kind = GridFsPreviewKind.hex;
    }
  }
  return GridFsPreview(kind, bytes: bytes);
}

Future<File> _downloadToFile(
  GridFsRepository repository,
  GridFsTarget target,
  GridFsEntry file,
  CancellationToken cancel,
  GridFsPreviewFiles files,
  String name,
  Uint8List? prefix,
) async {
  final destination = await files.create(name);
  try {
    final output = await destination.open(mode: FileMode.write);
    var written = 0;
    try {
      if (prefix != null) {
        await output.writeFrom(prefix);
        written = prefix.length;
      }
      if (written < file.length) {
        await for (final chunk in repository.download(
          target,
          file.id,
          cancel: cancel,
          offset: written,
          length: file.length - written,
        )) {
          if (written + chunk.length > file.length) {
            throw const GridFsFailure(
              GridFsFailureKind.corrupt,
              'Preview exceeds its requested range',
            );
          }
          await output.writeFrom(chunk);
          written += chunk.length;
        }
      }
    } finally {
      await output.close();
    }
    if (written != file.length) {
      throw const GridFsFailure(
        GridFsFailureKind.corrupt,
        'Incomplete preview',
      );
    }
    return destination;
  } on Object {
    await files.delete(destination);
    rethrow;
  }
}

Future<Uint8List> _readRange(
  GridFsRepository repository,
  GridFsTarget target,
  GridFsEntry file,
  CancellationToken cancel,
  int offset,
  int length, {
  Uint8List? prefix,
}) async {
  final expected = length.clamp(0, file.length - offset);
  final bytes = Uint8List(expected);
  var position = 0;
  if (prefix != null) {
    bytes.setAll(0, prefix);
    position = prefix.length;
  }
  if (position == expected) return bytes;
  await for (final chunk in repository.download(
    target,
    file.id,
    cancel: cancel,
    offset: offset + position,
    length: length - position,
  )) {
    if (position + chunk.length > expected) {
      throw const GridFsFailure(
        GridFsFailureKind.corrupt,
        'Preview exceeds its requested range',
      );
    }
    bytes.setAll(position, chunk);
    position += chunk.length;
  }
  if (position != expected) {
    throw const GridFsFailure(GridFsFailureKind.corrupt, 'Incomplete preview');
  }
  return bytes;
}

GridFsPreviewKind? _declaredType(String contentType) {
  final mime = contentType.split(';').first.trim().toLowerCase();
  if (mime.startsWith('text/') ||
      mime == 'application/json' ||
      mime == 'application/xml' ||
      mime.endsWith('+json') ||
      mime.endsWith('+xml')) {
    return GridFsPreviewKind.text;
  }
  return switch (mime) {
    'image/png' ||
    'image/jpeg' ||
    'image/gif' ||
    'image/webp' ||
    'image/bmp' ||
    'image/x-ms-bmp' => GridFsPreviewKind.image,
    'application/pdf' => GridFsPreviewKind.pdf,
    _ => null,
  };
}

GridFsPreviewKind sniffGridFsType(Uint8List bytes) {
  bool matches(List<int> signature, [int start = 0]) {
    if (bytes.length < start + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[start + i] != signature[i]) return false;
    }
    return true;
  }

  if (matches(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) ||
      matches(const [0xff, 0xd8, 0xff]) ||
      matches('GIF87a'.codeUnits) ||
      matches('GIF89a'.codeUnits) ||
      matches('BM'.codeUnits) ||
      matches('RIFF'.codeUnits) && matches('WEBP'.codeUnits, 8)) {
    return GridFsPreviewKind.image;
  }
  if (matches('%PDF-'.codeUnits)) return GridFsPreviewKind.pdf;
  if (bytes.any(
    (byte) => byte < 0x20 && byte != 9 && byte != 10 && byte != 13,
  )) {
    return GridFsPreviewKind.hex;
  }
  // The sample may end in the middle of a valid UTF-8 sequence.
  final text = const Utf8Decoder(allowMalformed: true).convert(bytes);
  return text.contains('\uFFFD') && bytes.length < 512
      ? GridFsPreviewKind.hex
      : GridFsPreviewKind.text;
}

List<String> _textLines(String text) {
  const lineWidth = 160;
  return [
    for (final line in const LineSplitter().convert(text))
      if (line.length <= lineWidth) line else ..._wrapLine(line, lineWidth),
  ];
}

Iterable<String> _wrapLine(String line, int width) sync* {
  var buffer = StringBuffer();
  for (final rune in line.runes) {
    buffer.writeCharCode(rune);
    if (buffer.length >= width) {
      yield buffer.toString();
      buffer = StringBuffer();
    }
  }
  if (buffer.isNotEmpty) yield buffer.toString();
}
