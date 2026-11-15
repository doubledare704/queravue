import 'package:flutter/widgets.dart' show Axis, BuildContext;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/actions/app_action.dart';
import '../../../shared/actions/key_chord.dart';
import '../../../shared/panes/pane_sizes.dart';
import '../../completion/application/format_action.dart';
import '../../connections/application/connection_session.dart';
import '../../connections/application/connections_controller.dart';
import '../../connections/presentation/connection_actions.dart';
import '../../documents/application/document_actions.dart';
import '../../diagram/application/diagram_controller.dart';
import '../../diagram/data/export_target.dart';
import '../../diagram/presentation/diagram_flows.dart';
import '../../editor/application/editor_actions.dart';
import '../../editor/application/editor_layout_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../../editor/domain/editor_layout.dart';
import '../../editor/domain/query_models.dart';
import '../../history/presentation/history_dialog.dart';
import '../../keybindings/presentation/keybindings_dialog.dart';
import '../../keyvalue/application/key_value_actions.dart';
import '../../workspace/domain/workspace_models.dart';
import '../../workspace/presentation/workspace_flows.dart';
import '../presentation/command_palette.dart';

KeyChord _primary(LogicalKeyboardKey key, {bool shift = false}) =>
    KeyChord(key, primary: true, shift: shift);

EditorTab? _activeTab(ActionWatch watch) =>
    watch(editorTabsProvider).activeFor(watch(selectedConnectionProvider));

bool _hasActiveTab(ActionWatch watch) => _activeTab(watch) != null;

bool _inCollectionTab(ActionWatch watch) =>
    _activeTab(watch)?.isCollection ?? false;

bool _inDiagramTab(ActionWatch watch) => _activeTab(watch)?.isDiagram ?? false;

bool _diagramShows(ActionWatch watch, bool Function(DiagramReady) test) {
  final tab = _activeTab(watch);
  if (tab == null || !tab.isDiagram) return false;
  return watch(
    diagramProvider(tab.id).select((s) => s is DiagramReady && test(s)),
  );
}

bool _canDesignDiagram(ActionWatch watch) {
  final tab = _activeTab(watch);
  return tab != null &&
      tab.isDiagram &&
      watch(connectionCanDesignDiagramProvider(tab.connectionId)) &&
      _diagramShows(watch, (_) => true);
}

bool _canExportDiagram(ActionWatch watch) =>
    _diagramShows(watch, (s) => !s.isEmpty);

bool _inSavableTab(ActionWatch watch) =>
    _inScriptTab(watch) || _inDiagramTab(watch);

Future<void> _save(BuildContext context, WidgetRef ref, {required bool as}) {
  final diagram = activeDiagramTab(ref);
  if (diagram != null) {
    return saveDiagramFlow(context, ref, diagram.id, saveAs: as);
  }
  return as
      ? saveActiveTabAsFlow(context, ref)
      : saveActiveTabFlow(context, ref);
}

Future<void> _export(BuildContext context, WidgetRef ref, ExportFormat format) {
  final diagram = activeDiagramTab(ref);
  return diagram == null
      ? Future.value()
      : exportDiagramFlow(context, ref, diagram.id, format);
}

bool _inScriptTab(ActionWatch watch) {
  final tab = _activeTab(watch);
  return tab != null && (tab.isQuery || tab.isShell);
}

EditorLayout _layout(ActionWatch watch) {
  final id = watch(selectedConnectionProvider);
  return id == null ? const EditorLayout() : watch(editorLayoutProvider).of(id);
}

bool _isSplit(ActionWatch watch) => _layout(watch).groups.length > 1;

bool _canOpenQueryTab(ActionWatch watch) {
  final id = watch(selectedConnectionProvider);
  return id != null &&
      !watch(hasKeyValueProvider(id)) &&
      !watch(connectionIsDocumentOnlyProvider(id));
}

bool _canOpenShellTab(ActionWatch watch) {
  final id = watch(selectedConnectionProvider);
  return id != null && watch(connectionHasShellProvider(id));
}

/// Every action of the app. Chords here are defaults; the user can change them.
final builtinActionsProvider = Provider<List<AppAction>>(
  (ref) => [
    ...keyValueActions(),
    AppAction(
      id: 'connection.new',
      title: 'New connection',
      category: ActionCategory.connection,
      defaultChord: _primary(LogicalKeyboardKey.keyN),
      run: showConnectionDialog,
    ),
    AppAction(
      id: 'editor.new',
      enabledWhen: _canOpenQueryTab,
      title: 'New query tab',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.keyT),
      run: (context, ref) async => openQueryTab(ref),
    ),
    AppAction(
      id: 'editor.close',
      enabledWhen: _hasActiveTab,
      title: 'Close query tab',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.keyW),
      run: (context, ref) async => closeQueryTab(ref),
    ),
    AppAction(
      id: 'editor.run',
      enabledWhen: _hasActiveTab,
      title: 'Run statement at cursor',
      subtitle: 'In a collection tab: run the query bar',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.enter),
      run: (context, ref) => runActiveTab(ref, ExecuteMode.statementAtCursor),
    ),
    AppAction(
      id: 'editor.runAll',
      enabledWhen: _hasActiveTab,
      title: 'Run all statements',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.enter, shift: true),
      run: (context, ref) => runActiveTab(ref, ExecuteMode.all),
    ),
    AppAction(
      id: 'editor.format',
      enabledWhen: (watch) => _activeTab(watch)?.isQuery ?? false,
      title: 'Format SQL',
      subtitle: 'Selection, or the statement at the cursor',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.keyF,
        shift: true,
        alt: true,
      ),
      run: formatActiveTab,
    ),
    AppAction(
      id: 'editor.cancel',
      enabledWhen: _hasActiveTab,
      title: 'Cancel running statement',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(LogicalKeyboardKey.escape),
      run: (context, ref) => cancelActiveTab(ref),
    ),
    AppAction(
      id: 'editor.splitRight',
      enabledWhen: (watch) => _layout(watch).canSplit,
      title: 'Split editor right',
      subtitle: 'Moves the active tab into a new group',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(LogicalKeyboardKey.backslash, primary: true),
      run: (context, ref) async => splitEditor(ref, Axis.horizontal),
    ),
    AppAction(
      id: 'editor.splitDown',
      enabledWhen: (watch) => _layout(watch).canSplit,
      title: 'Split editor down',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.backslash, shift: true),
      run: (context, ref) async => splitEditor(ref, Axis.vertical),
    ),
    AppAction(
      id: 'editor.focusNextGroup',
      enabledWhen: _isSplit,
      title: 'Focus next editor group',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.arrowRight,
        primary: true,
        alt: true,
      ),
      run: (context, ref) async => focusEditorGroup(ref, 1),
    ),
    AppAction(
      id: 'editor.focusPreviousGroup',
      enabledWhen: _isSplit,
      title: 'Focus previous editor group',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.arrowLeft,
        primary: true,
        alt: true,
      ),
      run: (context, ref) async => focusEditorGroup(ref, -1),
    ),
    AppAction(
      id: 'editor.moveToNextGroup',
      enabledWhen: _isSplit,
      title: 'Move tab to next editor group',
      category: ActionCategory.editor,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.arrowRight,
        primary: true,
        alt: true,
        shift: true,
      ),
      run: (context, ref) async => moveTabToGroup(ref, 1),
    ),
    for (final (index, key) in const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ].indexed)
      AppAction(
        id: 'editor.focusGroup${index + 1}',
        enabledWhen: (watch) => _layout(watch).groups.length > index,
        title: 'Focus editor group ${index + 1}',
        category: ActionCategory.editor,
        defaultChord: _primary(key),
        run: (context, ref) async => focusEditorGroupAt(ref, index),
      ),
    AppAction(
      id: 'view.maximizeEditor',
      enabledWhen: _hasActiveTab,
      title: 'Maximize editor group',
      subtitle: 'The focused group fills the window; run again to restore',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyM, shift: true),
      run: (context, ref) async =>
          ref.read(paneSizesProvider.notifier).toggleEditorMaximized(),
    ),
    AppAction(
      id: 'view.toggleSidebar',
      title: 'Toggle sidebar',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyB),
      run: (context, ref) async =>
          ref.read(paneSizesProvider.notifier).toggleSidebar(),
    ),
    AppAction(
      id: 'view.toggleOutput',
      enabledWhen: _inScriptTab,
      title: 'Toggle results and output pane',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyJ),
      run: (context, ref) async =>
          ref.read(paneSizesProvider.notifier).toggleOutput(),
    ),
    AppAction(
      id: 'documents.run',
      enabledWhen: _inCollectionTab,
      title: 'Run document query',
      subtitle: 'Collection tab: filter, sort, projection',
      category: ActionCategory.documents,
      inMenu: false,
      run: (context, ref) => runDocumentQuery(ref),
    ),
    AppAction(
      id: 'documents.insert',
      enabledWhen: _inCollectionTab,
      title: 'Insert document',
      subtitle: 'Collection tab',
      category: ActionCategory.documents,
      run: (context, ref) async => insertDocument(context, ref),
    ),
    AppAction(
      id: 'documents.refresh',
      enabledWhen: _inCollectionTab,
      title: 'Refresh documents',
      subtitle: 'Collection tab',
      category: ActionCategory.documents,
      run: (context, ref) => refreshDocuments(ref),
    ),
    AppAction(
      id: 'history.open',
      title: 'Query history',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.keyY),
      run: showHistoryDialog,
    ),
    AppAction(
      id: 'shell.new',
      enabledWhen: _canOpenShellTab,
      title: 'New Mongo shell tab',
      subtitle: 'MongoDB connections',
      category: ActionCategory.editor,
      defaultChord: _primary(LogicalKeyboardKey.keyT, shift: true),
      run: (context, ref) async => openShellTab(ref),
    ),
    AppAction(
      id: 'diagram.open',
      title: 'Open schema diagram',
      subtitle: 'Tables and relations of the current schema',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyD, shift: true),
      enabledWhen: (watch) {
        final id = watch(selectedConnectionProvider);
        return id != null && watch(connectionHasSchemaGraphProvider(id));
      },
      run: (context, ref) async => openSchemaDiagram(ref),
    ),
    AppAction(
      id: 'diagram.openSaved',
      title: 'Open saved diagram…',
      subtitle: 'Diagrams saved in .queravue/diagrams',
      category: ActionCategory.view,
      run: openSavedDiagramFlow,
    ),
    AppAction(
      id: 'diagram.exportSvg',
      title: 'Export diagram as SVG',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyE, shift: true),
      enabledWhen: _canExportDiagram,
      run: (context, ref) => _export(context, ref, ExportFormat.svg),
    ),
    AppAction(
      id: 'diagram.exportPng',
      title: 'Export diagram as PNG',
      category: ActionCategory.view,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.keyE,
        primary: true,
        alt: true,
        shift: true,
      ),
      enabledWhen: _canExportDiagram,
      run: (context, ref) => _export(context, ref, ExportFormat.png),
    ),
    AppAction(
      id: 'diagram.showHidden',
      title: 'Show hidden tables',
      subtitle: 'Schema diagram',
      category: ActionCategory.view,
      enabledWhen: (watch) => _diagramShows(watch, (s) => s.hidden.isNotEmpty),
      run: (context, ref) async {
        final diagram = activeDiagramTab(ref);
        if (diagram != null) {
          ref.read(diagramProvider(diagram.id).notifier).showAll();
        }
      },
    ),
    AppAction(
      id: 'diagram.toggleInferred',
      title: 'Show or hide inferred relations',
      subtitle: 'Relations guessed from sampled documents',
      category: ActionCategory.view,
      enabledWhen: (watch) =>
          _diagramShows(watch, (s) => s.drawnGraph.inferredRelationCount > 0),
      run: (context, ref) async {
        final diagram = activeDiagramTab(ref);
        if (diagram == null) return;
        final controller = ref.read(diagramProvider(diagram.id).notifier);
        final shown = ref.read(diagramProvider(diagram.id));
        if (shown is DiagramReady) {
          controller.showInferredRelations(!shown.showInferred);
        }
      },
    ),
    AppAction(
      id: 'diagram.newTable',
      title: 'New table on the diagram',
      subtitle: 'Design mode: drafted until you apply it',
      category: ActionCategory.view,
      defaultChord: const KeyChord(
        LogicalKeyboardKey.keyT,
        primary: true,
        alt: true,
      ),
      enabledWhen: _canDesignDiagram,
      run: (context, ref) async {
        final diagram = activeDiagramTab(ref);
        if (diagram != null) await newDraftTableFlow(context, ref, diagram.id);
      },
    ),
    AppAction(
      id: 'diagram.reviewDraft',
      title: 'Review and apply diagram changes',
      subtitle: 'Shows the DDL of the drafted tables and relations',
      category: ActionCategory.view,
      enabledWhen: (watch) => _diagramShows(watch, (s) => !s.draft.isEmpty),
      run: (context, ref) async {
        final diagram = activeDiagramTab(ref);
        if (diagram != null) await reviewDraftFlow(context, ref, diagram.id);
      },
    ),
    AppAction(
      id: 'diagram.discardDraft',
      title: 'Discard diagram draft',
      category: ActionCategory.view,
      enabledWhen: (watch) => _diagramShows(watch, (s) => !s.draft.isEmpty),
      run: (context, ref) async {
        final diagram = activeDiagramTab(ref);
        if (diagram != null) await discardDraftFlow(context, ref, diagram.id);
      },
    ),
    AppAction(
      id: 'workspace.open',
      title: 'Open workspace file',
      category: ActionCategory.workspace,
      defaultChord: _primary(LogicalKeyboardKey.keyO),
      run: quickOpenFlow,
    ),
    AppAction(
      id: 'workspace.newSql',
      title: 'New SQL file',
      subtitle: 'Create in the workspace and open',
      category: ActionCategory.workspace,
      run: (context, ref) => newScriptFlow(context, ref, FileKind.sql),
    ),
    AppAction(
      id: 'workspace.newMongo',
      title: 'New Mongo script',
      subtitle: 'Create in the workspace and open',
      category: ActionCategory.workspace,
      run: (context, ref) => newScriptFlow(context, ref, FileKind.mongo),
    ),
    AppAction(
      id: 'workspace.search',
      title: 'Search workspace',
      category: ActionCategory.workspace,
      defaultChord: _primary(LogicalKeyboardKey.keyF, shift: true),
      run: (context, ref) async => searchWorkspaceFlow(ref),
    ),
    AppAction(
      id: 'workspace.save',
      enabledWhen: _inSavableTab,
      title: 'Save to workspace',
      category: ActionCategory.workspace,
      defaultChord: _primary(LogicalKeyboardKey.keyS),
      run: (context, ref) => _save(context, ref, as: false),
    ),
    AppAction(
      id: 'workspace.saveAs',
      enabledWhen: _inSavableTab,
      title: 'Save to workspace as…',
      category: ActionCategory.workspace,
      defaultChord: _primary(LogicalKeyboardKey.keyS, shift: true),
      run: (context, ref) => _save(context, ref, as: true),
    ),
    AppAction(
      id: 'palette.open',
      title: 'Command palette',
      subtitle: 'Prefix > actions, @ database objects, # files, : tabs',
      category: ActionCategory.view,
      defaultChord: _primary(LogicalKeyboardKey.keyK),
      run: showCommandPalette,
    ),
    AppAction(
      id: 'palette.tabs',
      title: 'Go to tab',
      category: ActionCategory.view,
      run: (context, ref) =>
          showCommandPalette(context, ref, initialQuery: ':'),
    ),
    AppAction(
      id: 'palette.objects',
      title: 'Go to database object',
      category: ActionCategory.view,
      run: (context, ref) =>
          showCommandPalette(context, ref, initialQuery: '@'),
    ),
    AppAction(
      id: 'view.keybindings',
      title: 'Keyboard shortcuts',
      subtitle: 'Change shortcuts and resolve conflicts',
      category: ActionCategory.view,
      run: showKeybindingsDialog,
    ),
  ],
);
