import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfrxPreviewMetrics {
  const PdfrxPreviewMetrics({
    required this.viewerReadyMs,
    required this.firstPageMs,
    required this.pageCount,
  });

  final int viewerReadyMs;
  final int firstPageMs;
  final int pageCount;
}

Future<bool> waitForVisiblePagesReady(
  PdfViewerController controller, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final state = controller.visibleRenderState.value;
  if (state == PdfVisibleRenderState.ready) {
    await WidgetsBinding.instance.endOfFrame;
    return true;
  }
  if (state == PdfVisibleRenderState.failed) {
    return false;
  }

  final completer = Completer<bool>();
  void onState() {
    final current = controller.visibleRenderState.value;
    if (current != PdfVisibleRenderState.ready &&
        current != PdfVisibleRenderState.failed) {
      return;
    }
    controller.visibleRenderState.removeListener(onState);
    if (!completer.isCompleted) {
      completer.complete(current == PdfVisibleRenderState.ready);
    }
  }

  controller.visibleRenderState.addListener(onState);
  final ok = await completer.future.timeout(
    timeout,
    onTimeout: () {
      controller.visibleRenderState.removeListener(onState);
      return false;
    },
  );
  if (ok) {
    await WidgetsBinding.instance.endOfFrame;
  }
  return ok;
}

class PdfrxPreviewPane extends StatefulWidget {
  const PdfrxPreviewPane({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.controller,
    this.onFirstPageReady,
    this.onPageChanged,
    this.onPagePainted,
    this.onError,
  });

  final Uint8List bytes;
  final String sourceName;
  final PdfViewerController controller;
  final ValueChanged<PdfrxPreviewMetrics>? onFirstPageReady;
  final ValueChanged<int?>? onPageChanged;
  final ValueChanged<int>? onPagePainted;
  final ValueChanged<Object>? onError;

  @override
  State<PdfrxPreviewPane> createState() => _PdfrxPreviewPaneState();
}

class _PdfrxPreviewPaneState extends State<PdfrxPreviewPane> {
  final Stopwatch _openWatch = Stopwatch();
  int? _viewerReadyMs;
  int? _pageCount;
  bool _reportedFirstPage = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void didUpdateWidget(covariant PdfrxPreviewPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceName != widget.sourceName ||
        !identical(oldWidget.bytes, widget.bytes)) {
      oldWidget.controller.visibleRenderState.removeListener(_onVisibleState);
      _startTracking();
    }
  }

  @override
  void dispose() {
    widget.controller.visibleRenderState.removeListener(_onVisibleState);
    super.dispose();
  }

  void _startTracking() {
    _viewerReadyMs = null;
    _pageCount = null;
    _reportedFirstPage = false;
    _loadError = null;
    _openWatch
      ..reset()
      ..start();
    widget.controller.visibleRenderState.addListener(_onVisibleState);
  }

  void _onVisibleState() {
    if (_reportedFirstPage || !mounted) return;
    final state = widget.controller.visibleRenderState.value;
    if (state == PdfVisibleRenderState.failed) {
      _reportedFirstPage = true;
      widget.controller.visibleRenderState.removeListener(_onVisibleState);
      widget.onError?.call(StateError('pdfrx failed to render visible page'));
      return;
    }
    if (state != PdfVisibleRenderState.ready) return;
    _reportedFirstPage = true;
    widget.controller.visibleRenderState.removeListener(_onVisibleState);
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;
      final elapsedMs = _openWatch.elapsedMilliseconds;
      final pageCount = _pageCount ??
          (widget.controller.isReady ? widget.controller.pageCount : 0);
      widget.onFirstPageReady?.call(
        PdfrxPreviewMetrics(
          viewerReadyMs: _viewerReadyMs ?? elapsedMs,
          firstPageMs: elapsedMs,
          pageCount: pageCount,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(child: Text('Failed to load PDF: $_loadError'));
    }
    return PdfViewer.data(
      widget.bytes,
      sourceName: widget.sourceName,
      controller: widget.controller,
      params: PdfViewerParams(
        onViewerReady: (document, controller) {
          _viewerReadyMs = _openWatch.elapsedMilliseconds;
          _pageCount = document.pages.length;
          _onVisibleState();
        },
        onPageChanged: widget.onPageChanged,
        onDocumentLoadFinished: (document, succeeded) {
          if (!succeeded && mounted) {
            setState(() {
              _loadError = 'Document load failed';
            });
            widget.onError?.call(StateError('pdfrx document load failed'));
          }
        },
        pagePaintCallbacks: [
          (_, _, page) {
            widget.onPagePainted?.call(page.pageNumber);
          },
        ],
      ),
    );
  }
}

Future<void> initializePdfrxRuntime() => pdfrxFlutterInitialize();
