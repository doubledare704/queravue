import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/gen/queravue/v1/gridfs.pbgrpc.dart' as pb;
import 'package:queravue/features/connections/domain/cancellation.dart';
import 'package:queravue/features/gridfs/data/gridfs_repository.dart';
import 'package:queravue/features/gridfs/domain/gridfs_models.dart';

const _target = (scope: (sessionId: 's', database: 'db'), bucket: 'bucket');

class _Connection extends Fake implements CoreConnection {
  @override
  _Service get gridFsService => service;
  final service = _Service();
  final uploads = <pb.UploadRequest>[];

  @override
  Future<pb.UploadResponse> uploadGridFsFile(
    Stream<pb.UploadRequest> requests,
    CancellationToken cancel,
  ) async {
    await for (final request in requests) {
      uploads.add(request);
    }
    return pb.UploadResponse(file: pb.GridFsFile(idEjson: '"file"'));
  }
}

class _Service extends Fake implements pb.GridFsServiceClient {
  pb.DownloadRequest? request;
  final responses = <pb.DownloadResponse>[];

  @override
  ResponseStream<pb.DownloadResponse> download(
    pb.DownloadRequest request, {
    CallOptions? options,
  }) {
    this.request = request;
    return _Responses(responses);
  }
}

class _Responses extends Stream<pb.DownloadResponse>
    implements ResponseStream<pb.DownloadResponse> {
  _Responses(this.values);

  final List<pb.DownloadResponse> values;

  @override
  StreamSubscription<pb.DownloadResponse> listen(
    void Function(pb.DownloadResponse event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.fromIterable(values).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  ResponseFuture<pb.DownloadResponse> get single => throw UnimplementedError();

  @override
  Future<void> cancel() async {}

  @override
  Future<Map<String, String>> get headers => Future.value({});

  @override
  Future<Map<String, String>> get trailers => Future.value({});
}

void main() {
  late _Connection connection;
  late GridFsRepository repository;

  setUp(() {
    connection = _Connection();
    repository = GrpcGridFsRepository(() => connection);
  });

  test(
    'download requests a byte range and checks the header before yielding',
    () async {
      final service = connection.service;
      service.responses.addAll([
        pb.DownloadResponse(file: pb.GridFsFile(length: Int64(18))),
        pb.DownloadResponse(chunk: [1]),
        pb.DownloadResponse(chunk: [2, 3]),
      ]);
      final chunks = await repository
          .download(
            _target,
            '{"\$oid":"id"}',
            offset: 12,
            length: 3,
            cancel: CancellationToken(),
          )
          .toList();
      expect(chunks, [
        [1],
        [2, 3],
      ]);
      expect(service.request?.database, 'db');
      expect(service.request?.bucket, 'bucket');
      expect(service.request?.idEjson, '{"\$oid":"id"}');
      expect(service.request?.offset, Int64(12));
      expect(service.request?.length, Int64(3));
    },
  );

  test('download maps in-band errors and rejects incomplete streams', () async {
    final cancel = CancellationToken();
    final responses = connection.service.responses;
    final corrupt = isA<GridFsFailure>().having(
      (e) => e.kind,
      'kind',
      GridFsFailureKind.corrupt,
    );
    responses.add(
      pb.DownloadResponse(
        error: pb.GridFsError(
          kind: pb.GridFsErrorKind.GRID_FS_ERROR_KIND_CORRUPT,
          message: 'Missing chunk',
        ),
      ),
    );
    await expectLater(
      repository.download(_target, 'id', cancel: cancel),
      emitsError(corrupt.having((e) => e.message, 'message', 'Missing chunk')),
    );
    responses
      ..clear()
      ..add(pb.DownloadResponse(file: pb.GridFsFile(length: Int64(2))))
      ..add(pb.DownloadResponse(chunk: [0]));
    await expectLater(
      repository.download(_target, 'id', cancel: cancel),
      emitsInOrder([
        equals([0]),
        emitsError(corrupt),
      ]),
    );
    expect(connection.service.request?.hasLength(), isFalse);
  });

  test(
    'upload forwards the options in one header before the bounded chunks',
    () async {
      final result = await repository.upload(
        _target,
        const GridFsUpload(
          filename: 'picture',
          contentType: 'image/png',
          metadata: '{"project":"demo"}',
          replaceId: '"old"',
        ),
        Stream.fromIterable([
          [1, 2],
          [3],
        ]),
        cancel: CancellationToken(),
        confirmed: true,
      );
      expect(connection.uploads.first.header.filename, 'picture');
      expect(connection.uploads.first.header.contentType, 'image/png');
      expect(
        connection.uploads.first.header.metadataEjson,
        '{"project":"demo"}',
      );
      expect(connection.uploads.first.header.replaceIdEjson, '"old"');
      expect(connection.uploads.first.header.confirmed, isTrue);
      expect(connection.uploads.skip(1).map((request) => request.chunk), [
        [1, 2],
        [3],
      ]);
      expect(result.id, '"file"');
    },
  );
}
