import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../connections/application/connection_session.dart';
import '../application/completion_engine.dart';
import '../application/user_snippets.dart';
import '../data/completion_repository.dart';
import '../domain/completion_models.dart';
import '../domain/snippets.dart';
import 'completion_scope.dart';

/// Capability a session needs for completion in [context].
String completionCapability(CompletionContext context) => switch (context) {
  CompletionContext.sql => 'completion',
  CompletionContext.shell => 'shell',
  CompletionContext.mongoQuery => 'document_store',
};

/// Owns the [CompletionEngine] of one editor: finds the session of
/// [connectionId], adds user snippets and puts the popup around [child].
class CompletionHost extends ConsumerStatefulWidget {
  const CompletionHost({
    super.key,
    required this.connectionId,
    required this.context,
    required this.controller,
    required this.child,
    this.database = '',
    this.collection = '',
  });

  final String connectionId;
  final CompletionContext context;
  final CodeLineEditingController controller;
  final String database;
  final String collection;
  final Widget child;

  @override
  ConsumerState<CompletionHost> createState() => _CompletionHostState();
}

class _CompletionHostState extends ConsumerState<CompletionHost> {
  late final CompletionEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = CompletionEngine(
      repositoryOf: () => ref.read(completionRepositoryProvider),
      context: widget.context,
      sessionId: _sessionId,
      database: () => widget.database,
      collection: () => widget.collection,
      snippetsOf: () => [
        ...builtInSnippets,
        ...ref.read(userSnippetsProvider).value ?? const <Snippet>[],
      ],
    );
  }

  String? _sessionId() {
    final session = ref
        .read(connectionSessionProvider(widget.connectionId))
        .session;
    if (session == null ||
        !session.capabilities.contains(completionCapability(widget.context))) {
      return null;
    }
    return session.id;
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompletionScope(
      controller: widget.controller,
      engine: _engine,
      child: widget.child,
    );
  }
}
