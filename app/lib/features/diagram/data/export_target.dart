import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExportFormat {
  svg('SVG image', 'svg', 'public.svg-image'),
  png('PNG image', 'png', 'public.png');

  const ExportFormat(this.label, this.extension, this.uniformTypeIdentifier);

  final String label;
  final String extension;
  final String uniformTypeIdentifier;
}

/// Where an export goes: a file the user picks outside the workspace.
abstract interface class ExportTarget {
  /// The chosen path, ending in the format's extension; null if cancelled.
  Future<String?> chooseLocation(String suggestedName, ExportFormat format);

  Future<void> write(String path, Uint8List bytes);
}

final exportTargetProvider = Provider<ExportTarget>(
  (_) => const FileSelectorExportTarget(),
);

class FileSelectorExportTarget implements ExportTarget {
  const FileSelectorExportTarget();

  @override
  Future<String?> chooseLocation(
    String suggestedName,
    ExportFormat format,
  ) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: format.label,
          extensions: [format.extension],
          uniformTypeIdentifiers: [format.uniformTypeIdentifier],
        ),
      ],
    );
    if (location == null) return null;
    final path = location.path;
    return path.toLowerCase().endsWith('.${format.extension}')
        ? path
        : '$path.${format.extension}';
  }

  @override
  Future<void> write(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes, flush: true);
}
