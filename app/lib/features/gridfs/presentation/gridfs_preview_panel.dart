import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../admin/domain/admin_models.dart' show formatBytes;
import '../application/gridfs_controller.dart';
import '../application/gridfs_preview.dart';
import '../data/pdf_previewer.dart';

class GridFsPreviewPanel extends StatelessWidget {
  const GridFsPreviewPanel({
    super.key,
    required this.selection,
    required this.previewer,
    this.onDownload,
    this.onClear,
  });

  final GridFsSelection? selection;
  final PdfPreviewer previewer;
  final VoidCallback? onDownload;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final current = selection;
    if (current == null) {
      return const Center(child: Text('Select a file to preview.'));
    }
    final file = current.file;
    final preview = current.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          title: Text(
            file.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              formatBytes(file.length),
              if (file.contentType.isNotEmpty) file.contentType,
              file.uploadDate.toUtc().toIso8601String(),
            ].join(' · '),
          ),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Download',
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton(
                tooltip: 'Clear preview',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (file.metadata.isNotEmpty)
          ExpansionTile(
            dense: true,
            title: const Text('Metadata'),
            children: [
              SizedBox(
                height: 64,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SelectableText(file.metadata),
                ),
              ),
            ],
          ),
        const Divider(height: 1),
        Expanded(
          child: current.error != null
              ? Center(child: Text(current.error.toString()))
              : preview == null
              ? const Center(child: CircularProgressIndicator())
              : preview.tooLarge
              ? const Center(
                  child: Text('File exceeds the preview size limit.'),
                )
              : _previewBody(context, preview),
        ),
      ],
    );
  }

  Widget _previewBody(BuildContext context, GridFsPreview preview) =>
      switch (preview.kind) {
        GridFsPreviewKind.text => _PreviewLines(
          count: preview.lines!.length,
          line: (i) => preview.lines![i],
        ),
        GridFsPreviewKind.hex => _PreviewLines(
          count: (preview.bytes!.length + 15) ~/ 16,
          line: (i) => _hexLine(preview.bytes!, i),
        ),
        GridFsPreviewKind.image => _PreviewImage(
          key: ObjectKey(preview.file),
          file: preview.file!,
        ),
        GridFsPreviewKind.pdf => Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await previewer.open(preview.file!);
              } on Object catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)
                      ?.showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
          ),
        ),
      };

  String _hexLine(Uint8List bytes, int row) {
    final start = row * 16;
    final end = math.min(start + 16, bytes.length);
    final hex = StringBuffer(start.toRadixString(16).padLeft(8, '0'))
      ..write('  ');
    for (var i = start; i < end; i++) {
      hex
        ..write(bytes[i].toRadixString(16).padLeft(2, '0'))
        ..write(' ');
    }
    return hex.toString();
  }
}

class _PreviewLines extends StatelessWidget {
  const _PreviewLines({required this.count, required this.line});

  final int count;
  final String Function(int) line;

  @override
  Widget build(BuildContext context) => SelectionArea(
    child: ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: count,
      itemBuilder: (_, i) => Text(
        line(i).isEmpty ? ' ' : line(i),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    ),
  );
}

class _PreviewImage extends StatefulWidget {
  const _PreviewImage({super.key, required this.file});

  final File file;

  @override
  State<_PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<_PreviewImage> {
  late final _dimensions = _readDimensions();
  ImageProvider<Object>? _imageProvider;

  Future<({int? width, int? height})> _readDimensions() async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(widget.file.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        const maxSide = 2048;
        final longest = math.max(descriptor.width, descriptor.height);
        if (longest <= maxSide) return (width: null, height: null);
        return (
          width: math.max(1, descriptor.width * maxSide ~/ longest),
          height: math.max(1, descriptor.height * maxSide ~/ longest),
        );
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  @override
  void dispose() {
    if (_imageProvider case final provider?) {
      unawaited(provider.evict());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _dimensions,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('Image could not be decoded.'));
      }
      final size = snapshot.data;
      if (size == null) return const Center(child: CircularProgressIndicator());
      final image = Image.file(
        widget.file,
        fit: BoxFit.contain,
        cacheWidth: size.width,
        cacheHeight: size.height,
        errorBuilder: (_, _, _) =>
            const Center(child: Text('Image could not be decoded.')),
      );
      _imageProvider = image.image;
      return image;
    },
  );
}
