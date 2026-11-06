import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/document.pbgrpc.dart' as pb;
import '../../connections/domain/cancellation.dart';
import '../domain/models.dart';

/// Where a document operation runs: database and collection of a session.
class CollectionTarget {
  const CollectionTarget(this.sessionId, this.database, this.collection);
  final String sessionId;
  final String database;
  final String collection;

  @override
  bool operator ==(Object other) =>
      other is CollectionTarget &&
      other.sessionId == sessionId &&
      other.database == database &&
      other.collection == collection;

  @override
  int get hashCode => Object.hash(sessionId, database, collection);
}

/// Result of SampleFields.
class SampleResult {
  const SampleResult({
    required this.fields,
    required this.sampled,
    this.usedFallback = false,
  });
  final List<FieldStat> fields;
  final int sampled;
  final bool usedFallback;
}

/// Access to the core's DocumentService. Operations that the core reports as
/// failed throw a [DocumentFailure]; transport errors propagate as they are.
abstract interface class DocumentRepository {
  /// Streams the documents of [q]. Cancelling the subscription cancels the
  /// call and kills the server cursor.
  Stream<DocBatch> find(CollectionTarget t, FindQuery q, {int batchSize});

  Future<CountResult> count(
    CollectionTarget t,
    String filter, {
    CancellationToken? cancel,
  });

  Future<List<String>> insert(CollectionTarget t, List<String> documents);

  /// Replaces the document with `_id` [id]. With [expected], the core rejects
  /// the write with a conflict if the stored document differs.
  Future<String> replace(
    CollectionTarget t, {
    required String id,
    required String document,
    String? expected,
  });

  Future<int> delete(
    CollectionTarget t,
    List<String> ids, {
    bool confirmed = false,
  });

  Future<SampleResult> sampleFields(CollectionTarget t, {int sampleSize});
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcDocumentRepository(() => supervisor.connection);
});

class GrpcDocumentRepository implements DocumentRepository {
  GrpcDocumentRepository(this._connection);

  final CoreConnection? Function() _connection;

  static const _timeout = Duration(seconds: 60);

  CoreConnection get _conn {
    final c = _connection();
    if (c == null) throw StateError('Core is not connected');
    return c;
  }

  @override
  Stream<DocBatch> find(CollectionTarget t, FindQuery q, {int batchSize = 0}) {
    final call = _conn.documentService.find(
      pb.FindRequest(
        sessionId: t.sessionId,
        database: t.database,
        collection: t.collection,
        filter: q.filter,
        sort: q.sort,
        projection: q.projection,
        skip: Int64(q.skip),
        limit: Int64(q.limit),
        batchSize: batchSize,
      ),
    );
    return call.map((r) {
      if (r.hasError()) throw DocumentFailure(_error(r.error));
      final b = r.batch;
      return DocBatch(
        offset: b.offset.toInt(),
        documents: List.of(b.documents),
        done: b.done,
      );
    });
  }

  @override
  Future<CountResult> count(
    CollectionTarget t,
    String filter, {
    CancellationToken? cancel,
  }) async {
    final call = _conn.documentService.count(
      pb.CountRequest(
        sessionId: t.sessionId,
        database: t.database,
        collection: t.collection,
        filter: filter,
      ),
    );
    unawaited(cancel?.whenCancelled.then((_) => call.cancel()));
    try {
      final r = await call;
      if (r.hasError()) throw DocumentFailure(_error(r.error));
      return CountResult(count: r.count.toInt(), exact: r.exact);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.cancelled && (cancel?.isCancelled ?? false)) {
        throw const OperationCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> insert(
    CollectionTarget t,
    List<String> documents,
  ) async {
    final r = await _conn.documentService.insertDocuments(
      pb.InsertDocumentsRequest(
        sessionId: t.sessionId,
        database: t.database,
        collection: t.collection,
        documents: documents,
      ),
      options: CallOptions(timeout: _timeout),
    );
    if (r.hasError()) throw DocumentFailure(_error(r.error));
    return List.of(r.insertedIds);
  }

  @override
  Future<String> replace(
    CollectionTarget t, {
    required String id,
    required String document,
    String? expected,
  }) async {
    final req = pb.ReplaceDocumentRequest(
      sessionId: t.sessionId,
      database: t.database,
      collection: t.collection,
      id: id,
      document: document,
    );
    if (expected != null) req.expectedDocument = expected;
    final r = await _conn.documentService.replaceDocument(
      req,
      options: CallOptions(timeout: _timeout),
    );
    if (r.hasError()) throw DocumentFailure(_error(r.error));
    return r.document;
  }

  @override
  Future<int> delete(
    CollectionTarget t,
    List<String> ids, {
    bool confirmed = false,
  }) async {
    final r = await _conn.documentService.deleteDocuments(
      pb.DeleteDocumentsRequest(
        sessionId: t.sessionId,
        database: t.database,
        collection: t.collection,
        ids: ids,
        confirmed: confirmed,
      ),
      options: CallOptions(timeout: _timeout),
    );
    if (r.hasError()) throw DocumentFailure(_error(r.error));
    return r.deletedCount.toInt();
  }

  @override
  Future<SampleResult> sampleFields(
    CollectionTarget t, {
    int sampleSize = 0,
  }) async {
    final r = await _conn.documentService.sampleFields(
      pb.SampleFieldsRequest(
        sessionId: t.sessionId,
        database: t.database,
        collection: t.collection,
        sampleSize: sampleSize,
      ),
      options: CallOptions(timeout: _timeout),
    );
    if (r.hasError()) throw DocumentFailure(_error(r.error));
    return SampleResult(
      sampled: r.sampled,
      usedFallback: r.usedFallback,
      fields: [
        for (final f in r.fields)
          FieldStat(
            name: f.name,
            frequency: f.frequency,
            types: [for (final x in f.types) x.type],
          ),
      ],
    );
  }

  DocumentError _error(pb.DocumentError e) => DocumentError(
    kind: switch (e.kind) {
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_PARSE => DocErrorKind.parse,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_CONFLICT =>
        DocErrorKind.conflict,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_NOT_FOUND =>
        DocErrorKind.notFound,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED =>
        DocErrorKind.confirmationRequired,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_AUTH => DocErrorKind.auth,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_NETWORK => DocErrorKind.network,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_TIMEOUT => DocErrorKind.timeout,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_CANCELED =>
        DocErrorKind.canceled,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_UNSUPPORTED =>
        DocErrorKind.unsupported,
      pb.DocumentErrorKind.DOCUMENT_ERROR_KIND_SERVER => DocErrorKind.server,
      _ => DocErrorKind.unspecified,
    },
    message: e.message,
    input: switch (e.input) {
      pb.DocumentInput.DOCUMENT_INPUT_FILTER => DocInput.filter,
      pb.DocumentInput.DOCUMENT_INPUT_SORT => DocInput.sort,
      pb.DocumentInput.DOCUMENT_INPUT_PROJECTION => DocInput.projection,
      pb.DocumentInput.DOCUMENT_INPUT_DOCUMENT => DocInput.document,
      _ => DocInput.none,
    },
    position: e.hasPosition() ? e.position : null,
    documentIndex: e.hasDocumentIndex() ? e.documentIndex : null,
    currentDocument: e.hasCurrentDocument() ? e.currentDocument : null,
  );
}
