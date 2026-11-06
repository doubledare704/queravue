import 'dart:async';

import 'package:queravue/features/connections/domain/cancellation.dart';
import 'package:queravue/features/documents/data/document_repository.dart';
import 'package:queravue/features/documents/domain/models.dart';

/// Canonical EJSON of document `i`: `{_id: Int32 i, name: "doc-i", big:
/// Int64 i}`.
String fakeDoc(int i) =>
    '{"_id":{"\$numberInt":"$i"},"name":"doc-$i","big":{"\$numberLong":"${9007199254740000 + i}"}}';

/// An in-memory [DocumentRepository] over [docs]. Honors skip and limit.
class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({int count = 120})
    : docs = [for (var i = 0; i < count; i++) fakeDoc(i)];

  List<String> docs;
  final finds = <FindQuery>[];
  final inserted = <String>[];
  final replaced = <({String id, String doc, String? expected})>[];
  final deleted = <List<String>>[];
  var deleteConfirmed = <bool>[];
  var findCancelled = 0;
  var counts = 0;

  /// Next `find` fails with this.
  DocumentError? findError;

  /// Next `replace` fails with this.
  DocumentError? replaceError;

  /// When set, `find` waits for it before emitting.
  Completer<void>? holdFind;

  CountResult countResult = const CountResult(count: 120, exact: false);
  List<FieldStat> sampled = const [
    FieldStat(name: '_id', types: ['int']),
    FieldStat(name: 'name', types: ['string']),
    FieldStat(name: 'big', types: ['long']),
  ];

  @override
  Stream<DocBatch> find(CollectionTarget t, FindQuery q, {int batchSize = 0}) {
    finds.add(q);
    late StreamController<DocBatch> c;
    c = StreamController<DocBatch>(
      onListen: () async {
        final h = holdFind;
        if (h != null) await h.future;
        if (c.isClosed) return;
        final err = findError;
        if (err != null) {
          findError = null;
          c.addError(DocumentFailure(err));
          await c.close();
          return;
        }
        var out = docs.skip(q.skip);
        if (q.limit > 0) out = out.take(q.limit);
        final list = out.toList();
        c.add(DocBatch(offset: 0, documents: list));
        c.add(DocBatch(offset: list.length, documents: const [], done: true));
        await c.close();
      },
      onCancel: () => findCancelled++,
    );
    return c.stream;
  }

  @override
  Future<CountResult> count(
    CollectionTarget t,
    String filter, {
    CancellationToken? cancel,
  }) async {
    counts++;
    return countResult;
  }

  @override
  Future<List<String>> insert(
    CollectionTarget t,
    List<String> documents,
  ) async {
    inserted.addAll(documents);
    return const [];
  }

  @override
  Future<String> replace(
    CollectionTarget t, {
    required String id,
    required String document,
    String? expected,
  }) async {
    replaced.add((id: id, doc: document, expected: expected));
    final e = replaceError;
    if (e != null) {
      replaceError = null;
      throw DocumentFailure(e);
    }
    return document;
  }

  @override
  Future<int> delete(
    CollectionTarget t,
    List<String> ids, {
    bool confirmed = false,
  }) async {
    deleted.add(ids);
    deleteConfirmed.add(confirmed);
    return ids.length;
  }

  @override
  Future<SampleResult> sampleFields(
    CollectionTarget t, {
    int sampleSize = 0,
  }) async => SampleResult(fields: sampled, sampled: 3);
}
