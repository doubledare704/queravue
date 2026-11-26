import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/actions/app_action.dart';
import '../../../shared/actions/key_chord.dart';
import '../../connections/application/connections_controller.dart';
import '../../connections/application/connection_session.dart';
import '../../documents/application/document_preview_controller.dart';
import '../../documents/pipeline_builder/application/pipeline_builder_controller.dart';
import '../../documents/pipeline_builder/presentation/pipeline_builder_view.dart';
import '../../editor/application/editor_tabs.dart';
import '../../shell/application/shell_tab_controller.dart';
import '../../schema/data/schema_repository.dart';
import '../domain/mongo_sql_translation.dart';
import 'mongo_sql_controller.dart';

void openMongoSqlTab(
  WidgetRef ref,
  String connectionId, {
  required String database,
  String collection = '',
}) {
  if (!ref.read(connectionHasMongoSqlProvider(connectionId))) return;
  ref.read(selectedConnectionProvider.notifier).select(connectionId);
  final tab = ref
      .read(editorTabsProvider.notifier)
      .openMongoSql(connectionId, database: database);
  if (collection.isNotEmpty) {
    tab.controller.text =
        'SELECT * FROM ${quoteMongoSqlIdentifier(collection)};';
  }
}

Future<void> copyMongoSqlMql(MongoSqlState state) async {
  final translation = state.translation;
  if (translation != null) {
    await Clipboard.setData(
      ClipboardData(text: translation.inFormat(state.format)),
    );
  }
}

Future<void> openMongoSqlPipeline(
  BuildContext context,
  EditorTab tab,
  MongoSqlTranslation? translation,
) async {
  if (translation is! MongoSqlAggregate) return;
  await showPipelineBuilder(
    context,
    PipelineTarget(
      connectionId: tab.connectionId,
      database: translation.database,
      collection: translation.collection,
    ),
    initialPipeline: translation.pipelineEjson,
  );
}

Future<String?> _chooseDatabase(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final configured = ref
      .read(connectionsControllerProvider)
      .value
      ?.where((profile) => profile.id == id)
      .firstOrNull
      ?.params['database'];
  if (configured != null && configured.isNotEmpty) return configured;
  final session = await ref
      .read(connectionSessionProvider(id).notifier)
      .connect();
  if (!context.mounted) return null;
  if (session == null) {
    _databaseMessage(
      context,
      ref.read(connectionSessionProvider(id)).error ??
          'Connect before choosing a database.',
    );
    return null;
  }
  final List<String> databases;
  try {
    databases = await ref
        .read(schemaRepositoryProvider)
        .listDatabases(session.id);
  } on Object catch (error) {
    if (context.mounted) {
      _databaseMessage(context, 'Could not list databases: $error');
    }
    return null;
  }
  if (!context.mounted) return null;
  if (databases.length == 1) return databases.single;
  if (databases.isEmpty) {
    _databaseMessage(context, 'No databases available.');
    return null;
  }
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Choose a database'),
      children: [
        for (final name in databases)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, name),
            child: Text(name),
          ),
      ],
    ),
  );
}

void _databaseMessage(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

EditorTab? _activeTab(ActionWatch watch) {
  final id = watch(selectedConnectionProvider);
  if (id == null || !watch(connectionHasMongoSqlProvider(id))) return null;
  final tab = watch(editorTabsProvider).activeFor(id);
  return tab?.isMongoSql == true ? tab : null;
}

bool _hasTranslation(ActionWatch watch, bool Function(MongoSqlState) test) {
  final tab = _activeTab(watch);
  return tab != null && test(watch(mongoSqlControllerProvider(tab)));
}

List<AppAction> mongoSqlActions() => [
  AppAction(
    id: 'mongoSql.open',
    title: 'Open SQL mode',
    category: ActionCategory.documents,
    defaultChord: const KeyChord(
      LogicalKeyboardKey.keyG,
      primary: true,
      shift: true,
    ),
    hideWhenDisabled: true,
    enabledWhen: (watch) {
      final id = watch(selectedConnectionProvider);
      return id != null && watch(connectionHasMongoSqlProvider(id));
    },
    run: (context, ref) async {
      final id = ref.read(selectedConnectionProvider);
      if (id == null || !ref.read(connectionHasMongoSqlProvider(id))) return;
      final active = ref.read(editorTabsProvider).activeFor(id);
      final scoped = active?.isMongoSql == true || active?.isShell == true
          ? active!.shellDatabase
          : active?.tableRef?.database ?? '';
      final database = scoped.isEmpty
          ? await _chooseDatabase(context, ref, id)
          : scoped;
      if (!context.mounted ||
          database == null ||
          ref.read(selectedConnectionProvider) != id) {
        return;
      }
      openMongoSqlTab(
        ref,
        id,
        database: database,
        collection: active?.isCollection == true ? active!.tableRef!.table : '',
      );
    },
  ),
  AppAction(
    id: 'mongoSql.preview',
    title: 'Preview SQL mode results',
    category: ActionCategory.documents,
    defaultChord: const KeyChord(
      LogicalKeyboardKey.enter,
      primary: true,
      alt: true,
    ),
    inMenu: false,
    hideWhenDisabled: true,
    enabledWhen: (watch) {
      final tab = _activeTab(watch);
      return tab != null &&
          watch(mongoSqlControllerProvider(tab)).current != null &&
          !watch(shellTabProvider(tab.id)).busy &&
          !watch(documentPreviewProvider(tab.id)).running;
    },
    run: (_, ref) async {
      final tab = _activeTab(ref.read);
      if (tab != null) {
        await ref.read(mongoSqlControllerProvider(tab).notifier).preview();
      }
    },
  ),
  AppAction(
    id: 'mongoSql.pipeline',
    title: 'Open in pipeline builder',
    category: ActionCategory.documents,
    defaultChord: const KeyChord(
      LogicalKeyboardKey.keyA,
      primary: true,
      alt: true,
    ),
    inMenu: false,
    hideWhenDisabled: true,
    enabledWhen: (watch) =>
        _hasTranslation(watch, (s) => s.current is MongoSqlAggregate),
    run: (context, ref) async {
      final tab = _activeTab(ref.read);
      if (tab != null) {
        await openMongoSqlPipeline(
          context,
          tab,
          ref.read(mongoSqlControllerProvider(tab)).current,
        );
      }
    },
  ),
  AppAction(
    id: 'mongoSql.copy',
    title: 'Copy MQL',
    category: ActionCategory.documents,
    defaultChord: const KeyChord(
      LogicalKeyboardKey.keyC,
      primary: true,
      shift: true,
    ),
    inMenu: false,
    hideWhenDisabled: true,
    enabledWhen: (watch) =>
        _hasTranslation(watch, (s) => s.translation != null),
    run: (_, ref) async {
      final tab = _activeTab(ref.read);
      if (tab != null) {
        await copyMongoSqlMql(ref.read(mongoSqlControllerProvider(tab)));
      }
    },
  ),
];
