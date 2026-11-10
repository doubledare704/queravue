import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const minSidebarWidth = 180.0;
const maxSidebarWidth = 520.0;
const minEditorShare = 0.1;
const maxEditorShare = 0.9;

@immutable
class PaneSizes {
  const PaneSizes({
    this.sidebarWidth = 260,
    this.sidebarCollapsed = false,
    this.editorShare = 0.4,
    this.outputCollapsed = false,
    this.editorMaximized = false,
  });

  final double sidebarWidth;
  final bool sidebarCollapsed;
  final double editorShare;
  final bool outputCollapsed;
  final bool editorMaximized;

  bool get sidebarVisible => !sidebarCollapsed && !editorMaximized;

  PaneSizes copyWith({
    double? sidebarWidth,
    bool? sidebarCollapsed,
    double? editorShare,
    bool? outputCollapsed,
    bool? editorMaximized,
  }) => PaneSizes(
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    editorShare: editorShare ?? this.editorShare,
    outputCollapsed: outputCollapsed ?? this.outputCollapsed,
    editorMaximized: editorMaximized ?? this.editorMaximized,
  );

  // Maximizing is a momentary view, so a restart never opens into it.
  Map<String, Object?> toJson() => {
    'sidebarWidth': sidebarWidth,
    'sidebarCollapsed': sidebarCollapsed,
    'editorShare': editorShare,
    'outputCollapsed': outputCollapsed,
  };

  static PaneSizes fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const PaneSizes();
    final width = json['sidebarWidth'];
    final share = json['editorShare'];
    return PaneSizes(
      sidebarWidth: width is num
          ? width.toDouble().clamp(minSidebarWidth, maxSidebarWidth)
          : 260,
      sidebarCollapsed: json['sidebarCollapsed'] == true,
      editorShare: share is num
          ? share.toDouble().clamp(minEditorShare, maxEditorShare)
          : 0.4,
      outputCollapsed: json['outputCollapsed'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaneSizes &&
      other.sidebarWidth == sidebarWidth &&
      other.sidebarCollapsed == sidebarCollapsed &&
      other.editorShare == editorShare &&
      other.outputCollapsed == outputCollapsed &&
      other.editorMaximized == editorMaximized;

  @override
  int get hashCode => Object.hash(
    sidebarWidth,
    sidebarCollapsed,
    editorShare,
    outputCollapsed,
    editorMaximized,
  );
}

final paneSizesProvider = NotifierProvider<PaneSizesController, PaneSizes>(
  PaneSizesController.new,
);

class PaneSizesController extends Notifier<PaneSizes> {
  @override
  PaneSizes build() => const PaneSizes();

  void restore(PaneSizes sizes) => state = sizes;

  void dragSidebar(double pixels) => state = state.copyWith(
    sidebarWidth: (state.sidebarWidth + pixels).clamp(
      minSidebarWidth,
      maxSidebarWidth,
    ),
  );

  void setEditorShare(double share) => state = state.copyWith(
    editorShare: share.clamp(minEditorShare, maxEditorShare),
  );

  void toggleSidebar() => state = state.editorMaximized
      ? state.copyWith(editorMaximized: false, sidebarCollapsed: false)
      : state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);

  void toggleOutput() =>
      state = state.copyWith(outputCollapsed: !state.outputCollapsed);

  void toggleEditorMaximized() =>
      state = state.copyWith(editorMaximized: !state.editorMaximized);
}
