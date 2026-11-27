import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connection_session.dart';
import '../../connections/domain/cancellation.dart';
import '../../documents/application/document_tab_controller.dart'
    show kCancelDelay;
import '../../editor/application/editor_tabs.dart';
import '../data/gridfs_file_io.dart';
import '../data/gridfs_preview_files.dart';
import '../data/gridfs_repository.dart';
import '../domain/gridfs_models.dart';
import 'gridfs_preview.dart';

const gridFsPageSize = 100;

typedef GridFsPage = ({List<GridFsEntry> files, int index, bool hasNext});

typedef GridFsSelection = ({
  GridFsEntry file,
  GridFsPreview? preview,
  Object? error,
});

typedef GridFsConfirm = Future<bool> Function(bool production);

enum GridFsTask { listing, upload, download, rename, delete }

class GridFsWork {
  const GridFsWork(
    this.task, {
    this.completed = 0,
    this.total,
    this.canCancel = false,
  });

  final GridFsTask task;
  final int completed;
  final int? total;
  final bool canCancel;
}

class GridFsState {
  const GridFsState({
    this.target,
    this.page = (files: const [], index: 0, hasNext: false),
    this.selection,
    this.work,
    this.error,
  });

  final GridFsTarget? target;
  final GridFsPage page;
  final GridFsSelection? selection;
  final GridFsWork? work;
  final Object? error;

  GridFsState showPage(GridFsPage value) =>
      GridFsState(target: target, page: value, work: work, error: error);

  GridFsState select(GridFsSelection? value) => GridFsState(
    target: target,
    page: page,
    selection: value,
    work: work,
    error: error,
  );

  GridFsState working(GridFsWork? value, {Object? error}) => GridFsState(
    target: target,
    page: page,
    selection: selection,
    work: value,
    error: error,
  );
}

final gridFsTargetProvider = Provider.autoDispose.family<GridFsTarget?, String>(
  (ref, tabId) {
    final tab = ref.watch(
      editorTabsProvider.select(
        (tabs) => tabs.tabs
            .where((tab) => tab.id == tabId && tab.isGridFs)
            .firstOrNull,
      ),
    );
    final bucket = tab?.tableRef;
    if (tab == null || bucket == null) return null;
    final session = ref.watch(
      connectionSessionProvider(tab.connectionId)
          .select((value) => value.session),
    );
    if (session == null || !session.capabilities.contains('gridfs')) {
      return null;
    }
    return (
      scope: (sessionId: session.id, database: bucket.database),
      bucket: bucket.table,
    );
  },
);

final gridFsControllerProvider = NotifierProvider.autoDispose
    .family<GridFsController, GridFsState, String>(GridFsController.new);

class GridFsController extends Notifier<GridFsState> {
  GridFsController(this.tabId);

  final String tabId;
  late GridFsRepository _repository;
  late GridFsPreviewFiles _previewFiles;
  File? _imageFile;
  final _pdfFiles = <File>[];
  CancellationToken? _operation;
  CancellationToken? _preview;
  String _filter = '';
  String _sort = '{"_id":1}';

  @override
  GridFsState build() {
    final target = ref.watch(gridFsTargetProvider(tabId));
    _repository = ref.watch(gridFsRepositoryProvider);
    final previewFiles = _previewFiles = ref.watch(gridFsPreviewFilesProvider);
    ref.onDispose(() {
      _operation?.cancel();
      _operation = null;
      _preview?.cancel();
      _preview = null;
      for (final file in [?_imageFile, ..._pdfFiles]) {
        unawaited(previewFiles.delete(file));
      }
      _imageFile = null;
      _pdfFiles.clear();
    });
    if (target != null) {
      scheduleMicrotask(() {
        if (ref.mounted && state.target == target && state.work == null) {
          unawaited(refresh());
        }
      });
    }
    return GridFsState(target: target);
  }

  Future<void> apply(String filter, String sort) {
    if (state.work != null) return Future.value();
    _filter = filter.trim();
    _sort = sort.trim();
    return _load(0);
  }

  Future<void> refresh() => _load(state.page.index);

  Future<void> nextPage() =>
      state.page.hasNext ? _load(state.page.index + 1) : Future.value();

  Future<void> previousPage() =>
      state.page.index > 0 ? _load(state.page.index - 1) : Future.value();

  Future<void> _load(int page) =>
      _run(GridFsTask.listing, (target, cancel) async {
        final timer = Timer(kCancelDelay, () {
          if (_owns(cancel)) {
            state = state.working(
              const GridFsWork(GridFsTask.listing, canCancel: true),
            );
          }
        });
        final repository = _repository;
        try {
          var requestedPage = page;
          while (!cancel.isCancelled) {
            final iterator = StreamIterator(
              repository.listFiles(
                target,
                filter: _filter,
                sort: _sort,
                skip: requestedPage * gridFsPageSize,
                limit: gridFsPageSize + 1,
              ),
            );
            final files = <GridFsEntry>[];
            var hasNext = false;
            try {
              while (await Future.any([
                iterator.moveNext(),
                cancel.whenCancelled.then((_) => false),
              ])) {
                if (files.length == gridFsPageSize) {
                  hasNext = true;
                } else {
                  files.add(iterator.current);
                }
              }
            } finally {
              await iterator.cancel();
            }
            if (!_owns(cancel) || cancel.isCancelled) return;
            if (files.isNotEmpty || requestedPage == 0) {
              _preview?.cancel();
              _preview = null;
              state = state.showPage((
                files: files,
                index: requestedPage,
                hasNext: hasNext,
              ));
              return;
            }
            requestedPage--;
          }
        } finally {
          timer.cancel();
        }
      });

  Future<void> select(GridFsEntry? file) async {
    _preview?.cancel();
    _preview = null;
    final superseded = _imageFile;
    _imageFile = null;
    state = state.select(
      file == null ? null : (file: file, preview: null, error: null),
    );
    if (superseded != null) unawaited(_previewFiles.delete(superseded));
    final target = state.target;
    if (target == null || file == null) return;
    final cancel = _preview = CancellationToken();
    try {
      final preview = await loadGridFsPreview(
        _repository,
        target,
        file,
        cancel,
        _previewFiles,
      );
      if (ref.mounted && identical(_preview, cancel)) {
        _keepPreviewFile(preview);
        state = state.select((file: file, preview: preview, error: null));
      } else if (preview.file case final stale?) {
        unawaited(_previewFiles.delete(stale));
      }
    } on Object catch (error) {
      if (ref.mounted && identical(_preview, cancel)) {
        state = state.select((file: file, preview: null, error: error));
      }
    } finally {
      if (identical(_preview, cancel)) _preview = null;
    }
  }

  void _keepPreviewFile(GridFsPreview preview) {
    final file = preview.file;
    if (file == null) return;
    if (preview.kind == GridFsPreviewKind.pdf) {
      _pdfFiles.add(file);
    } else {
      _imageFile = file;
    }
  }

  void cancel() => _operation?.cancel();

  Future<void> upload(
    File source,
    GridFsUpload upload, {
    required bool production,
    required GridFsConfirm confirm,
  }) async {
    var changed = false;
    await _run(GridFsTask.upload, (target, cancel) async {
      final total = await source.length();
      final repository = _repository;
      changed = await _confirmed(
        cancel,
        initialPrompt: production && upload.replaceId != null,
        production: production,
        confirm: confirm,
        run: (confirmed) async {
          _progress(cancel, GridFsTask.upload, 0, total);
          await repository.upload(
            target,
            upload,
            readGridFsFile(
              source,
              cancel,
              (n) => _progress(cancel, GridFsTask.upload, n, total),
            ),
            cancel: cancel,
            confirmed: confirmed,
          );
        },
      );
    });
    if (changed && ref.mounted) await refresh();
  }

  Future<void> download(GridFsEntry file, File destination) =>
      _run(GridFsTask.download, (target, cancel) async {
        _progress(cancel, GridFsTask.download, 0, file.length);
        await saveGridFsDownload(
          destination,
          _repository.download(target, file.id, cancel: cancel),
          cancel,
          (n) => _progress(cancel, GridFsTask.download, n, file.length),
        );
      });

  Future<void> delete(
    GridFsEntry file, {
    required bool production,
    required GridFsConfirm confirm,
  }) async {
    var changed = false;
    await _run(GridFsTask.delete, (target, cancel) async {
      final repository = _repository;
      changed = await _confirmed(
        cancel,
        initialPrompt: true,
        production: production,
        confirm: confirm,
        run: (confirmed) =>
            repository.delete(target, file.id, confirmed: confirmed),
      );
    });
    if (changed && ref.mounted) await refresh();
  }

  Future<void> rename(GridFsEntry file, String filename) async {
    var changed = false;
    await _run(GridFsTask.rename, (target, cancel) async {
      await _repository.rename(target, file.id, filename);
      changed = _owns(cancel);
    });
    if (changed && ref.mounted) await refresh();
  }

  Future<bool> _confirmed(
    CancellationToken cancel, {
    required bool initialPrompt,
    required bool production,
    required GridFsConfirm confirm,
    required Future<void> Function(bool confirmed) run,
  }) async {
    if (initialPrompt && !await confirm(production)) return false;
    if (cancel.isCancelled) return false;
    try {
      await run(false);
    } on GridFsFailure catch (error) {
      if (error.kind != GridFsFailureKind.confirmationRequired) rethrow;
      if (!(production && initialPrompt) && !await confirm(true)) return false;
      if (cancel.isCancelled) return false;
      await run(true);
    }
    return _owns(cancel) && !cancel.isCancelled;
  }

  bool _owns(CancellationToken cancel) =>
      ref.mounted && identical(_operation, cancel);

  void _progress(
    CancellationToken cancel,
    GridFsTask task,
    int completed,
    int total,
  ) {
    if (!_owns(cancel) || cancel.isCancelled) return;
    state = state.working(
      GridFsWork(task, completed: completed, total: total, canCancel: true),
    );
  }

  Future<void> _run(
    GridFsTask task,
    Future<void> Function(GridFsTarget target, CancellationToken cancel) action,
  ) async {
    final target = state.target;
    if (target == null || state.work != null) return;
    final cancel = _operation = CancellationToken();
    state = state.working(GridFsWork(task));
    Object? failure;
    try {
      await action(target, cancel);
    } on Object catch (error) {
      if (!cancel.isCancelled) failure = error;
    } finally {
      if (_owns(cancel)) {
        _operation = null;
        state = state.working(null, error: failure);
      }
    }
  }
}
