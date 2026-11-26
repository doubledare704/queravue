import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/document.pb.dart';
import '../../completion/data/completion_repository.dart';
import '../../completion/domain/completion_models.dart';
import '../../schema/data/schema_repository.dart';
import '../domain/mongo_sql_completion_context.dart';
import '../domain/mongo_sql_translation.dart';

typedef MongoSqlCollectionScope = ({String session, String database});
typedef MongoSqlFieldScope = ({
  String session,
  String database,
  String collection,
});

final mongoSqlCompletionRepositoryProvider = Provider.autoDispose
    .family<CompletionRepository, String>((ref, tabId) {
      final schema = ref.watch(schemaRepositoryProvider);
      final supervisor = ref.watch(coreSupervisorProvider);
      final samples = <ResponseFuture<SampleFieldPathsResponse>>{};
      ref.onDispose(() {
        for (final call in samples) {
          call.cancel().ignore();
        }
      });
      return MongoSqlCompletionRepository(
        listCollections: (scope) async => [
          for (final object in await schema.listObjects(
            scope.session,
            database: scope.database,
            schema: '',
          ))
            object.name,
        ],
        sampleFields: (scope) async {
          final document = supervisor.connection?.documentService;
          if (document == null) return const [];
          final call = document.sampleFieldPaths(
            SampleFieldPathsRequest(
              sessionId: scope.session,
              database: scope.database,
              collection: scope.collection,
            ),
            options: CallOptions(timeout: const Duration(seconds: 5)),
          );
          samples.add(call);
          try {
            final response = await call;
            return [for (final path in response.paths) path.path];
          } finally {
            samples.remove(call);
          }
        },
      );
    });

class MongoSqlCompletionRepository implements CompletionRepository {
  MongoSqlCompletionRepository({
    required this.listCollections,
    required this.sampleFields,
  });

  final Future<List<String>> Function(MongoSqlCollectionScope) listCollections;
  final Future<List<String>> Function(MongoSqlFieldScope) sampleFields;
  final _collections = _CompletionCache<MongoSqlCollectionScope>();
  final _fields = _CompletionCache<MongoSqlFieldScope>();

  @override
  Future<CompletionResult> complete(
    CompletionRequest request, {
    required Future<void> cancel,
  }) async {
    final context = mongoSqlCompletionContext(
      request.text,
      request.cursorOffset,
    );
    if (context == null) return const CompletionResult();
    final database = request.database;
    final session = request.sessionId;
    final collection = context.collection;
    try {
      final names = await Future.any([
        if (context.collections)
          _collections.get((
            session: session,
            database: database,
          ), listCollections)
        else if (collection != null)
          _fields.get((
            session: session,
            database: database,
            collection: collection,
          ), sampleFields)
        else
          Future.value(const <String>[]),
        cancel.then((_) => const <String>[]),
      ]);
      return CompletionResult(
        catalogState: CatalogState.ready,
        items: [
          for (final name in names.take(
            request.maxItems > 0 ? request.maxItems : names.length,
          ))
            CompletionItem(
              label: name,
              kind: context.collections
                  ? CompletionKind.collection
                  : CompletionKind.field,
              detail: context.collections ? 'Collection' : collection ?? '',
              insertText: context.collections
                  ? _identifier(name)
                  : name.split('.').map(_identifier).join('.'),
              replaceStart: context.start,
              replaceEnd: context.end,
              sortKey: '000${name.toLowerCase()}',
            ),
        ],
      );
    } on Object {
      return const CompletionResult();
    }
  }

  static String _identifier(String value) =>
      isBareMongoSqlIdentifier(value) ? value : quoteMongoSqlIdentifier(value);

  @override
  Future<FormatSqlResult> formatSql({
    required String sessionId,
    required String text,
    FormatSqlOptions options = const FormatSqlOptions(),
    int? rangeStart,
    int? rangeEnd,
  }) async =>
      const FormatSqlResult(error: 'Formatting is unavailable in SQL mode.');
}

class _CompletionCache<K> {
  K? _key;
  Future<List<String>>? _pending;

  Future<List<String>> get(K key, Future<List<String>> Function(K) load) async {
    final existing = _pending;
    if (key == _key && existing != null) return existing;
    _key = key;
    final pending = _pending = load(key);
    try {
      return await pending;
    } on Object {
      if (identical(_pending, pending)) _pending = null;
      rethrow;
    }
  }
}
