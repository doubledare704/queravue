import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

import '../../../core_client/core_connection.dart';
import '../../../core_client/core_providers.dart';
import '../../../core_client/gen/queravue/v1/gridfs.pbgrpc.dart' as pb;
import '../../connections/domain/cancellation.dart';
import '../domain/gridfs_models.dart';

abstract interface class GridFsRepository {
  Future<List<String>> listBuckets(GridFsDatabase scope);

  Stream<GridFsEntry> listFiles(
    GridFsTarget target, {
    required String filter,
    required String sort,
    required int skip,
    required int limit,
  });

  Stream<List<int>> download(
    GridFsTarget target,
    String id, {
    required CancellationToken cancel,
    int offset = 0,
    int? length,
  });

  Future<GridFsEntry> upload(
    GridFsTarget target,
    GridFsUpload upload,
    Stream<List<int>> bytes, {
    required CancellationToken cancel,
    required bool confirmed,
  });

  Future<void> delete(
    GridFsTarget target,
    String id, {
    required bool confirmed,
  });

  Future<void> rename(GridFsTarget target, String id, String filename);
}

final gridFsRepositoryProvider = Provider<GridFsRepository>((ref) {
  final supervisor = ref.watch(coreSupervisorProvider);
  return GrpcGridFsRepository(() => supervisor.connection);
});

class GrpcGridFsRepository implements GridFsRepository {
  GrpcGridFsRepository(this._connection);

  final CoreConnection? Function() _connection;

  CoreConnection get _conn =>
      _connection() ?? (throw StateError('Core is not connected'));

  static final _options = CallOptions(timeout: const Duration(seconds: 60));

  @override
  Future<List<String>> listBuckets(GridFsDatabase scope) async {
    final pb.ListBucketsResponse response;
    try {
      response = await _conn.gridFsService.listBuckets(
        pb.ListBucketsRequest(
          sessionId: scope.sessionId,
          database: scope.database,
        ),
        options: _options,
      );
    } on GrpcError catch (error) {
      throw _grpcFailure(error);
    }
    if (response.hasError()) throw _failure(response.error);
    return [for (final bucket in response.buckets) bucket.name];
  }

  @override
  Stream<GridFsEntry> listFiles(
    GridFsTarget target, {
    required String filter,
    required String sort,
    required int skip,
    required int limit,
  }) async* {
    final call = _conn.gridFsService.listFiles(
      pb.ListFilesRequest(
        sessionId: target.scope.sessionId,
        database: target.scope.database,
        bucket: target.bucket,
        filter: filter,
        sort: sort,
        skip: Int64(skip),
        limit: Int64(limit),
      ),
    );
    // Transform the stream directly so subscription cancellation reaches gRPC.
    yield* call
        .expand((response) {
          if (response.hasError()) throw _failure(response.error);
          return response.batch.files.map(_entry);
        })
        .handleError((Object error, StackTrace stack) {
          if (error is GrpcError) throw _grpcFailure(error);
          Error.throwWithStackTrace(error, stack);
        });
  }

  @override
  Stream<List<int>> download(
    GridFsTarget target,
    String id, {
    required CancellationToken cancel,
    int offset = 0,
    int? length,
  }) async* {
    if (cancel.isCancelled) throw const OperationCancelled();
    final call = _conn.gridFsService.download(
      pb.DownloadRequest(
        sessionId: target.scope.sessionId,
        database: target.scope.database,
        bucket: target.bucket,
        idEjson: id,
        offset: Int64(offset),
        length: length == null ? null : Int64(length),
      ),
    );
    var active = true;
    unawaited(
      cancel.whenCancelled.then((_) async {
        if (active) await call.cancel();
      }),
    );
    int? remaining;
    try {
      await for (final response in call) {
        if (cancel.isCancelled) throw const OperationCancelled();
        if (response.hasError()) throw _failure(response.error);
        if (response.hasFile() && remaining == null) {
          final available = math.max(0, response.file.length.toInt() - offset);
          remaining = length == null ? available : math.min(available, length);
        } else if (response.hasChunk() &&
            remaining != null &&
            response.chunk.length <= math.min(remaining, gridFsChunkBytes)) {
          remaining -= response.chunk.length;
          yield response.chunk;
        } else {
          throw const GridFsFailure(
            GridFsFailureKind.corrupt,
            'Invalid download stream',
          );
        }
      }
      if (cancel.isCancelled) throw const OperationCancelled();
      if (remaining != 0) {
        throw const GridFsFailure(
          GridFsFailureKind.corrupt,
          'Incomplete download',
        );
      }
    } on GrpcError catch (error) {
      if (cancel.isCancelled && error.code == StatusCode.cancelled) {
        throw const OperationCancelled();
      }
      throw _grpcFailure(error);
    } finally {
      active = false;
    }
  }

  @override
  Future<GridFsEntry> upload(
    GridFsTarget target,
    GridFsUpload upload,
    Stream<List<int>> bytes, {
    required CancellationToken cancel,
    required bool confirmed,
  }) async {
    Stream<pb.UploadRequest> requests() async* {
      yield pb.UploadRequest(
        header: pb.UploadHeader(
          sessionId: target.scope.sessionId,
          database: target.scope.database,
          bucket: target.bucket,
          filename: upload.filename,
          contentType: upload.contentType,
          metadataEjson: upload.metadata,
          replaceIdEjson: upload.replaceId,
          confirmed: confirmed,
        ),
      );
      yield* bytes.map((chunk) {
        if (chunk.length > gridFsChunkBytes) {
          throw ArgumentError('GridFS upload chunks must be at most 1 MiB');
        }
        return pb.UploadRequest(chunk: chunk);
      });
    }

    final pb.UploadResponse response;
    try {
      response = await _conn.uploadGridFsFile(requests(), cancel);
    } on GrpcError catch (error) {
      if (cancel.isCancelled && error.code == StatusCode.cancelled) {
        throw const OperationCancelled();
      }
      throw _grpcFailure(error);
    }
    if (response.hasError()) throw _failure(response.error);
    if (!response.hasFile()) {
      throw const GridFsFailure(
        GridFsFailureKind.corrupt,
        'Invalid upload response',
      );
    }
    return _entry(response.file);
  }

  @override
  Future<void> delete(
    GridFsTarget target,
    String id, {
    required bool confirmed,
  }) async {
    final pb.DeleteFileResponse response;
    try {
      response = await _conn.gridFsService.deleteFile(
        pb.DeleteFileRequest(
          sessionId: target.scope.sessionId,
          database: target.scope.database,
          bucket: target.bucket,
          idEjson: id,
          confirmed: confirmed,
        ),
        options: _options,
      );
    } on GrpcError catch (error) {
      throw _grpcFailure(error);
    }
    if (response.hasError()) throw _failure(response.error);
  }

  @override
  Future<void> rename(GridFsTarget target, String id, String filename) async {
    final pb.RenameFileResponse response;
    try {
      response = await _conn.gridFsService.renameFile(
        pb.RenameFileRequest(
          sessionId: target.scope.sessionId,
          database: target.scope.database,
          bucket: target.bucket,
          idEjson: id,
          newFilename: filename,
        ),
        options: _options,
      );
    } on GrpcError catch (error) {
      throw _grpcFailure(error);
    }
    if (response.hasError()) throw _failure(response.error);
  }
}

GridFsEntry _entry(pb.GridFsFile file) => GridFsEntry(
  id: file.idEjson,
  filename: file.filename,
  length: file.length.toInt(),
  uploadDate: DateTime.fromMillisecondsSinceEpoch(
    file.uploadDateMs.toInt(),
    isUtc: true,
  ),
  contentType: file.contentType,
  metadata: file.metadataEjson,
);

GridFsFailure _grpcFailure(GrpcError error) {
  final kind = switch (error.code) {
    StatusCode.unauthenticated ||
    StatusCode.permissionDenied => GridFsFailureKind.auth,
    StatusCode.notFound => GridFsFailureKind.notFound,
    StatusCode.invalidArgument => GridFsFailureKind.parse,
    StatusCode.failedPrecondition ||
    StatusCode.unimplemented => GridFsFailureKind.unsupported,
    StatusCode.deadlineExceeded => GridFsFailureKind.timeout,
    StatusCode.unavailable => GridFsFailureKind.network,
    StatusCode.cancelled => GridFsFailureKind.canceled,
    StatusCode.dataLoss => GridFsFailureKind.corrupt,
    _ => GridFsFailureKind.server,
  };
  final message = error.message;
  return GridFsFailure(
    kind,
    message != null && message.isNotEmpty ? message : error.codeName,
  );
}

GridFsFailure _failure(
  pb.GridFsError error,
) => GridFsFailure(switch (error.kind) {
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_PARSE => GridFsFailureKind.parse,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_NOT_FOUND => GridFsFailureKind.notFound,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED =>
    GridFsFailureKind.confirmationRequired,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_AUTH => GridFsFailureKind.auth,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_NETWORK => GridFsFailureKind.network,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_TIMEOUT => GridFsFailureKind.timeout,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_CANCELED => GridFsFailureKind.canceled,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_UNSUPPORTED =>
    GridFsFailureKind.unsupported,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_SERVER => GridFsFailureKind.server,
  pb.GridFsErrorKind.GRID_FS_ERROR_KIND_CORRUPT => GridFsFailureKind.corrupt,
  _ => GridFsFailureKind.unspecified,
}, error.message);
