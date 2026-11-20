import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queravue/features/gridfs/application/gridfs_preview.dart';
import 'package:queravue/features/gridfs/data/pdf_previewer.dart';
import 'package:queravue/features/gridfs/domain/gridfs_models.dart';
import 'package:queravue/features/gridfs/presentation/gridfs_file_list.dart';
import 'package:queravue/features/gridfs/presentation/gridfs_preview_panel.dart';

class _PdfViewer implements PdfPreviewer {
  Uint8List? opened;

  @override
  Future<void> open(Uint8List bytes) async => opened = bytes;

  @override
  Future<void> dispose() async {}
}

final _file = GridFsEntry(
  id: '"notes"',
  filename: 'notes.txt',
  length: 1536,
  uploadDate: DateTime.utc(2026, 11, 20, 9, 0),
  contentType: 'text/plain',
  metadata: '{"folder":"Archive"}',
);

Widget _surface(Widget child) => MaterialApp(
  theme: ThemeData(colorSchemeSeed: Colors.indigo),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: const Key('gridfs-golden'),
        child: SizedBox(width: 1024, height: 240, child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'virtual grid displays file columns and supports keyboard selection',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final second = GridFsEntry(
        id: '"logo"',
        filename: 'logo.png',
        length: 231294,
        contentType: 'image/png',
        uploadDate: DateTime.utc(2026, 11, 19, 15, 42),
      );
      GridFsEntry? selection;
      await tester.pumpWidget(
        _surface(
          GridFsFileList(
            page: (files: [_file, second], index: 0, hasNext: false),
            onSelect: (file) => selection = file,
            selectedId: _file.id,
          ),
        ),
      );
      expect(find.text('notes.txt'), findsOneWidget);
      expect(find.text('1.5 KB'), findsOneWidget);
      expect(find.text('text/plain'), findsOneWidget);
      expect(find.text('"logo"'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('gridfs-golden')),
        matchesGoldenFile('goldens/gridfs_file_list.png'),
      );
      await tester.tap(find.text('notes.txt'));
      await tester.pump();
      expect(selection, _file);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(selection, second);
    },
  );

  testWidgets('text preview renders metadata and file contents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var downloaded = false;
    await tester.pumpWidget(
      _surface(
        GridFsPreviewPanel(
          selection: (
            file: _file,
            preview: const GridFsPreview(
              GridFsPreviewKind.text,
              lines: [
                'Archive notes',
                '',
                'Three images and a signed document.',
              ],
            ),
            error: null,
          ),
          previewer: _PdfViewer(),
          onDownload: () => downloaded = true,
        ),
      ),
    );
    expect(find.text('Archive notes'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('gridfs-golden')),
      matchesGoldenFile('goldens/gridfs_preview.png'),
    );
    await tester.tap(find.byTooltip('Download'));
    expect(downloaded, isTrue);
  });

  testWidgets('PDF preview delegates to the selected viewer', (tester) async {
    final viewer = _PdfViewer();
    final bytes = Uint8List.fromList('%PDF-1.4'.codeUnits);
    await tester.pumpWidget(
      _surface(
        GridFsPreviewPanel(
          selection: (
            file: _file,
            preview: GridFsPreview(GridFsPreviewKind.pdf, bytes: bytes),
            error: null,
          ),
          previewer: viewer,
        ),
      ),
    );
    await tester.tap(find.text('Open PDF'));
    expect(viewer.opened, same(bytes));
  });
}
