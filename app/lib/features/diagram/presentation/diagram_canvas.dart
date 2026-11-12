import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/diagram_models.dart';
import 'diagram_painter.dart';

const minDiagramScale = 0.04;
const maxDiagramScale = 2.5;
const _doubleClick = Duration(milliseconds: 350);

/// The diagram under a pan and zoom transform. Everything is painted on one
/// canvas; only tables inside the viewport are drawn.
class DiagramCanvas extends StatefulWidget {
  const DiagramCanvas({
    super.key,
    required this.graph,
    required this.rects,
    required this.selected,
    required this.fitKey,
    required this.onSelect,
    required this.onMoveTable,
    required this.onOpenTable,
    this.onTableMenu,
    this.onScaleChanged,
  });

  final SchemaGraph graph;
  final Map<String, Rect> rects;
  final String? selected;

  /// The diagram is fitted to the view whenever this changes: a new graph or
  /// a new automatic arrangement, not a moved or hidden table.
  final Object fitKey;
  final ValueChanged<String?> onSelect;
  final void Function(String table, Offset delta) onMoveTable;
  final ValueChanged<String> onOpenTable;
  final void Function(String table, Offset globalPosition)? onTableMenu;
  final ValueChanged<double>? onScaleChanged;

  @override
  State<DiagramCanvas> createState() => DiagramCanvasState();
}

class DiagramCanvasState extends State<DiagramCanvas> {
  final _texts = DiagramTextCache();
  final _focus = FocusNode(debugLabel: 'diagram');
  double scale = 1;
  Offset offset = Offset.zero;
  Size _size = Size.zero;
  Object? _fitted;
  SchemaGraph? _indexed;
  Map<String, DiagramTable> _tablesByName = const {};
  ColorScheme? _paintedWith;
  String? _dragging;
  bool _panning = false;
  double _gestureScale = 1;
  String? _lastClicked;
  DateTime _lastClickAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _texts.clear();
    _focus.dispose();
    super.dispose();
  }

  Rect get _bounds => widget.rects.isEmpty
      ? Rect.zero
      : widget.rects.values.reduce((a, b) => a.expandToInclude(b));

  Offset toDiagram(Offset local) => (local - offset) / scale;

  Offset toScreen(Offset point) => point * scale + offset;

  void _setScale(double next) {
    scale = next.clamp(minDiagramScale, maxDiagramScale);
    widget.onScaleChanged?.call(scale);
  }

  /// Shows the whole diagram, never magnified beyond its natural size.
  void fit() {
    final bounds = _bounds;
    if (bounds.isEmpty || _size.isEmpty) return;
    setState(() {
      _setScale(
        math.min(
          1,
          math.min(_size.width / bounds.width, _size.height / bounds.height) *
              0.94,
        ),
      );
      offset = _size.center(Offset.zero) - bounds.center * scale;
    });
  }

  void zoomBy(double factor, [Offset? around]) {
    final anchor = around ?? _size.center(Offset.zero);
    final fixed = toDiagram(anchor);
    setState(() {
      _setScale(scale * factor);
      offset = anchor - fixed * scale;
    });
  }

  String? _tableAt(Offset local) {
    final point = toDiagram(local);
    for (final table in widget.graph.tables.reversed) {
      if (widget.rects[table.name]?.contains(point) ?? false) return table.name;
    }
    return null;
  }

  void _onDown(PointerDownEvent event) {
    if (event.buttons == kSecondaryButton) {
      final hit = _tableAt(event.localPosition);
      if (hit != null) {
        widget.onSelect(hit);
        widget.onTableMenu?.call(hit, event.position);
      }
      return;
    }
    if (event.buttons != kPrimaryButton) return;
    _focus.requestFocus();
    final hit = _tableAt(event.localPosition);
    final now = DateTime.now();
    if (hit != null &&
        hit == _lastClicked &&
        now.difference(_lastClickAt) < _doubleClick) {
      _lastClicked = null;
      widget.onOpenTable(hit);
      return;
    }
    _lastClicked = hit;
    _lastClickAt = now;
    _dragging = hit;
    _panning = hit == null;
    widget.onSelect(hit);
  }

  void _onMove(PointerMoveEvent event) {
    final table = _dragging;
    if (table != null) {
      widget.onMoveTable(table, event.localDelta / scale);
    } else if (_panning) {
      setState(() => offset += event.localDelta);
    }
  }

  void _onUp(PointerEvent _) {
    _dragging = null;
    _panning = false;
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is PointerScaleEvent) {
      zoomBy(event.scale, event.localPosition);
    } else if (event is PointerScrollEvent) {
      final keys = HardwareKeyboard.instance;
      if (keys.isControlPressed || keys.isMetaPressed) {
        zoomBy(math.exp(-event.scrollDelta.dy / 240), event.localPosition);
      } else {
        setState(() => offset -= event.scrollDelta);
      }
    }
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final factor = event.scale / _gestureScale;
    _gestureScale = event.scale;
    if (factor != 1) zoomBy(factor, event.localPosition);
    setState(() => offset += event.localPanDelta);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_paintedWith != colors) {
      _texts.clear();
      _paintedWith = colors;
    }
    if (!identical(_indexed, widget.graph)) {
      _indexed = widget.graph;
      _tablesByName = {for (final t in widget.graph.tables) t.name: t};
    }
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        final wanted = widget.fitKey;
        if (_fitted != wanted && !_size.isEmpty) {
          _fitted = wanted;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) fit();
          });
        }
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.equal): () => zoomBy(1.25),
            const SingleActivator(LogicalKeyboardKey.add): () => zoomBy(1.25),
            const SingleActivator(LogicalKeyboardKey.minus): () => zoomBy(0.8),
            const SingleActivator(LogicalKeyboardKey.digit0): fit,
          },
          child: Focus(
            focusNode: _focus,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onDown,
              onPointerMove: _onMove,
              onPointerUp: _onUp,
              onPointerCancel: _onUp,
              onPointerSignal: _onSignal,
              onPointerPanZoomStart: (_) => _gestureScale = 1,
              onPointerPanZoomUpdate: _onPanZoomUpdate,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: DiagramPainter(
                    graph: widget.graph,
                    tablesByName: _tablesByName,
                    rects: widget.rects,
                    selected: widget.selected,
                    scale: scale,
                    offset: offset,
                    colors: colors,
                    texts: _texts,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
