import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:http2/transport.dart';
import 'package:queravue/core_client/core_connection.dart';
import 'package:queravue/core_client/core_launcher.dart';
import 'package:queravue/core_client/gen/queravue/v1/gridfs.pb.dart';
import 'package:queravue/core_client/gridfs_upload.dart';
import 'package:queravue/features/connections/domain/cancellation.dart';

class _TestH2Server {
  _TestH2Server._(this.socket, this.address, this.port, this._tempDir);

  final ServerSocket socket;
  final InternetAddress address;
  final int port;
  final Directory? _tempDir;
  final List<ServerTransportConnection> _connections = [];
  final List<Socket> _rawSockets = [];
  StreamSubscription<Socket>? _sub;
  int connectionCount = 0;

  static Future<_TestH2Server> start(
    InternetAddress address,
    Future<void> Function(ServerTransportStream stream) onStream, {
    bool rawAcceptOnly = false,
  }) async {
    final socket = await ServerSocket.bind(address, 0);
    final server = _TestH2Server._(socket, address, socket.port, null);
    server._listen(onStream, rawAcceptOnly: rawAcceptOnly);
    return server;
  }

  static Future<_TestH2Server> startUnix(
    Future<void> Function(ServerTransportStream stream) onStream,
  ) async {
    final dir = await Directory.systemTemp.createTemp('queravue-h2-');
    final addr = InternetAddress(
      '${dir.path}/core.sock',
      type: InternetAddressType.unix,
    );
    final socket = await ServerSocket.bind(addr, 0);
    final server = _TestH2Server._(socket, addr, 0, dir);
    server._listen(onStream);
    return server;
  }

  void _listen(
    Future<void> Function(ServerTransportStream stream) onStream, {
    bool rawAcceptOnly = false,
  }) {
    _sub = socket.listen((client) {
      connectionCount++;
      _rawSockets.add(client);
      if (rawAcceptOnly) return;
      final conn = ServerTransportConnection.viaSocket(client);
      _connections.add(conn);
      conn.incomingStreams.listen(
        (stream) => unawaited(onStream(stream)),
        onError: (_) {},
      );
    });
  }

  Future<void> close() async {
    await _sub?.cancel();
    for (final conn in _connections) {
      await conn
          .terminate()
          .then<void>((_) {}, onError: (Object _) {})
          .timeout(const Duration(milliseconds: 100), onTimeout: () {});
    }
    for (final s in _rawSockets) {
      s.destroy();
    }
    await socket.close();
    if (_tempDir != null && _tempDir.existsSync()) {
      await _tempDir.delete(recursive: true);
    }
  }
}

class _FakeHandle implements CoreHandle {
  _FakeHandle(this.socketPath, {this.token = 'secret-token'});

  @override
  final String socketPath;

  @override
  final String token;

  @override
  int get pid => 1;

  @override
  Future<int> get exitCode => Completer<int>().future;

  @override
  Future<void> kill() async {}

  @override
  Future<void> shutdown({Duration timeout = const Duration(seconds: 3)}) async {}
}

Uint8List _frameMessage(List<int> payload, {int compressed = 0}) {
  final out = Uint8List(5 + payload.length);
  out[0] = compressed;
  out.buffer.asByteData().setUint32(1, payload.length);
  out.setRange(5, out.length, payload);
  return out;
}

Future<({Map<String, String> headers, List<UploadRequest> requests})>
_readAllRequests(ServerTransportStream stream) async {
  final headers = <String, String>{};
  final requests = <UploadRequest>[];
  final decoder = GrpcHttpDecoder();
  await for (final msg in stream.incomingMessages.transform(decoder)) {
    if (msg is GrpcMetadata) {
      headers.addAll(msg.metadata);
    } else if (msg is GrpcData) {
      requests.add(UploadRequest.fromBuffer(msg.data));
    }
  }
  return (headers: headers, requests: requests);
}

Stream<UploadRequest> _singleHeaderRequests({List<int>? chunk}) async* {
  yield UploadRequest(
    header: UploadHeader(
      sessionId: 's1',
      database: 'db',
      bucket: 'fs',
      filename: 'file.bin',
    ),
  );
  if (chunk != null) {
    yield UploadRequest(chunk: chunk);
  }
}

UploadResponse _okResponse([String id = '"1"']) =>
    UploadResponse(file: GridFsFile(idEjson: id, filename: 'file.bin'));

void main() {
  group('CoreEndpoint', () {
    test('accepts Unix paths, IPv4 loopback, and bracketed IPv6 loopback', () {
      if (!Platform.isWindows) {
        final unix = CoreEndpoint.parse('/tmp/queravue/core.sock');
        expect(unix.address.type, InternetAddressType.unix);
        expect(unix.port, 0);
        expect(unix.authority, 'localhost');
      }

      final v4 = CoreEndpoint.parse('127.0.0.1:43210');
      expect(v4.address, InternetAddress.loopbackIPv4);
      expect(v4.port, 43210);
      expect(v4.authority, '127.0.0.1:43210');

      final v6 = CoreEndpoint.parse('[::1]:43211');
      expect(v6.address, InternetAddress.loopbackIPv6);
      expect(v6.port, 43211);
      expect(v6.authority, '[::1]:43211');
    });

    test('rejects non-loopback, hostnames, bad ports, and wrong types', () {
      for (final raw in [
        '',
        '   ',
        '192.168.1.10:5000',
        '0.0.0.0:5000',
        '[2001:db8::1]:5000',
        '[::]:5000',
        'example.com:5000',
        '127.0.0.1:0',
        '127.0.0.1:70000',
        '::1:5000',
        '[::1]:abc',
      ]) {
        expect(
          () => CoreEndpoint.parse(raw),
          throwsArgumentError,
          reason: 'raw=$raw',
        );
      }

      expect(
        () => CoreEndpoint(InternetAddress('192.168.1.10')),
        throwsArgumentError,
      );
      expect(() => CoreEndpoint(InternetAddress.anyIPv4), throwsArgumentError);
      expect(
        () => CoreEndpoint(InternetAddress.anyIPv6, port: 5000),
        throwsArgumentError,
      );
      expect(
        () => CoreEndpoint(InternetAddress.loopbackIPv4, port: 0),
        throwsArgumentError,
      );
      expect(
        () => CoreEndpoint(InternetAddress.loopbackIPv4, port: 70000),
        throwsArgumentError,
      );
      expect(
        () => CoreEndpoint(
          InternetAddress('/tmp/a.sock', type: InternetAddressType.unix),
          port: 123,
        ),
        throwsArgumentError,
      );
      expect(
        () => CoreEndpoint(
          InternetAddress('', type: InternetAddressType.unix),
        ),
        throwsArgumentError,
      );
    });

    test('GrpcCoreConnection.connect supports loopback TCP endpoints', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          stream.sendData(_frameMessage(_okResponse('"tcp"').writeToBuffer()));
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      final conn = await GrpcCoreConnection.connect(
        _FakeHandle('127.0.0.1:${server.port}', token: 'tok-123'),
      );
      addTearDown(conn.close);

      final resp = await conn.uploadGridFsFile(
        _singleHeaderRequests(chunk: [1, 2, 3]),
        CancellationToken(),
      );
      expect(resp.file.idEjson, '"tcp"');
    });
  });

  group('decodeGrpcMessage', () {
    test('decodes valid percent-encoded UTF-8 and survives malformed input', () {
      expect(decodeGrpcMessage(null), isNull);
      expect(decodeGrpcMessage('caf%C3%A9%20100%25+ok'), 'café 100%+ok');
      expect(decodeGrpcMessage('100% full'), '100% full');
      expect(decodeGrpcMessage('bad %zz value'), 'bad %zz value');
      expect(decodeGrpcMessage('truncated %2'), 'truncated %2');
      expect(decodeGrpcMessage('trailing %'), 'trailing %');
      expect(() => decodeGrpcMessage('%FF%FE'), returnsNormally);
      expect(
        decodeGrpcMessage('leaked secret-token here', 'secret-token'),
        'leaked <redacted> here',
      );
    });
  });

  group('uploadGridFs addressing and auth', () {
    test('uploads over Unix socket with expected headers and token', () async {
      late Map<String, String> receivedHeaders;
      late List<UploadRequest> receivedRequests;
      final server = await _TestH2Server.startUnix((stream) async {
        final read = await _readAllRequests(stream);
        receivedHeaders = read.headers;
        receivedRequests = read.requests;
        stream.sendHeaders([
          Header.ascii(':status', '200'),
          Header.ascii('content-type', 'application/grpc'),
        ]);
        stream.sendData(_frameMessage(_okResponse('"unix"').writeToBuffer()));
        stream.sendHeaders([Header.ascii('grpc-status', '0')], endStream: true);
      });
      addTearDown(server.close);

      final resp = await uploadGridFs(
        server.address,
        'my-secret-token',
        _singleHeaderRequests(chunk: [4, 5, 6]),
        CancellationToken(),
      );
      expect(resp.file.idEjson, '"unix"');
      expect(receivedHeaders[':method'], 'POST');
      expect(receivedHeaders[':scheme'], 'http');
      expect(receivedHeaders[':authority'], 'localhost');
      expect(receivedHeaders[':path'], '/queravue.v1.GridFsService/Upload');
      expect(receivedHeaders['content-type'], 'application/grpc');
      expect(receivedHeaders['te'], 'trailers');
      expect(receivedHeaders['authorization'], 'Bearer my-secret-token');
      expect(receivedRequests, hasLength(2));
      expect(receivedRequests[1].chunk, [4, 5, 6]);
    });

    test('uploads over IPv4 and IPv6 loopback with host:port authority', () async {
      for (final addr in [
        InternetAddress.loopbackIPv4,
        InternetAddress.loopbackIPv6,
      ]) {
        late Map<String, String> headers;
        final server = await _TestH2Server.start(addr, (stream) async {
          headers = (await _readAllRequests(stream)).headers;
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          stream.sendData(_frameMessage(_okResponse().writeToBuffer()));
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        });
        addTearDown(server.close);

        final resp = await uploadGridFs(
          addr,
          'loopback-token',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server.port,
        );
        expect(resp.file.idEjson, '"1"');
        final expectedAuthority = addr.type == InternetAddressType.IPv6
            ? '[::1]:${server.port}'
            : '127.0.0.1:${server.port}';
        expect(headers[':authority'], expectedAuthority);
      }
    });

    test('validates token without leaking it in error messages', () async {
      for (final bad in ['', '   ', 'tok\nen', 'tok\u00e9n']) {
        Object? caught;
        try {
          await uploadGridFs(
            InternetAddress.loopbackIPv4,
            bad,
            _singleHeaderRequests(),
            CancellationToken(),
            port: 1234,
          );
        } on Object catch (error) {
          caught = error;
        }
        expect(caught, isA<ArgumentError>());
        if (bad.trim().isNotEmpty) {
          expect(caught.toString(), isNot(contains(bad)));
        }
      }
    });

    test(
      'surfaces trailers-only UNAUTHENTICATED while streaming and redacts token',
      () async {
        const secret = 'super-secret-token-xyz';
        final server = await _TestH2Server.start(
          InternetAddress.loopbackIPv4,
          (stream) async {
            final firstHeader = Completer<void>();
            late StreamSubscription<StreamMessage> sub;
            sub = stream.incomingMessages.listen((msg) {
              if (msg is DataStreamMessage && !firstHeader.isCompleted) {
                firstHeader.complete();
              }
            });
            await firstHeader.future;
            stream.sendHeaders([
              Header.ascii(':status', '200'),
              Header.ascii('content-type', 'application/grpc'),
              Header.ascii('grpc-status', '${StatusCode.unauthenticated}'),
              Header.ascii('grpc-message', 'invalid token $secret'),
            ], endStream: true);
            await stream.outgoingMessages.done;
            stream.terminate();
            await sub.cancel();
          },
        );
        addTearDown(server.close);

        var sourceCancelled = false;
        final controller = StreamController<UploadRequest>(
          onCancel: () => sourceCancelled = true,
        );
        controller.add(
          UploadRequest(header: UploadHeader(filename: 'a.bin')),
        );
        final timer = Timer.periodic(const Duration(milliseconds: 5), (t) {
          if (controller.isClosed) {
            t.cancel();
            return;
          }
          controller.add(UploadRequest(chunk: List<int>.filled(65536, 1)));
        });
        addTearDown(() {
          timer.cancel();
          return controller.close();
        });

        await expectLater(
          uploadGridFs(
            InternetAddress.loopbackIPv4,
            secret,
            controller.stream,
            CancellationToken(),
            port: server.port,
          ),
          throwsA(
            isA<GrpcError>()
                .having((e) => e.code, 'code', StatusCode.unauthenticated)
                .having((e) => e.message, 'message', isNot(contains(secret)))
                .having((e) => e.message, 'message', contains('<redacted>')),
          ),
        );
        expect(sourceCancelled, isTrue);
      },
    );

    test('maps HTTP 401 without grpc-status to UNAUTHENTICATED', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '401'),
            Header.ascii('content-type', 'text/plain'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server.port,
        ),
        throwsA(
          isA<GrpcError>().having(
            (e) => e.code,
            'code',
            StatusCode.unauthenticated,
          ),
        ),
      );
    });
  });

  group('uploadGridFs protocol correctness', () {
    test('handles trailers-only gRPC error and malformed grpc-message', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
            Header.ascii('grpc-status', '${StatusCode.failedPrecondition}'),
            Header.ascii('grpc-message', '100% broken %zz'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server.port,
        ),
        throwsA(
          isA<GrpcError>()
              .having((e) => e.code, 'code', StatusCode.failedPrecondition)
              .having((e) => e.message, 'message', '100% broken %zz'),
        ),
      );
    });

    test('rejects trailers-only OK with no response message', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server.port,
        ),
        throwsA(
          isA<GrpcError>().having((e) => e.code, 'code', StatusCode.internal),
        ),
      );
    });

    test('rejects empty UploadResponse with neither file nor error', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          stream.sendData(_frameMessage(UploadResponse().writeToBuffer()));
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server.port,
        ),
        throwsA(
          isA<GrpcError>().having((e) => e.code, 'code', StatusCode.internal),
        ),
      );
    });

    test('waits for trailers before accepting response and fails if omitted', () async {
      final releaseTrailers = Completer<void>();
      var closeWithoutTrailers = false;
      final dataSent = Completer<void>();
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
            // Spec forbids trusting grpc-status from non-trailers-only headers.
            Header.ascii('grpc-status', '0'),
          ]);
          stream.sendData(_frameMessage(_okResponse('"gated"').writeToBuffer()));
          if (!dataSent.isCompleted) dataSent.complete();
          await releaseTrailers.future;
          if (closeWithoutTrailers) {
            await stream.outgoingMessages.close();
          } else {
            stream.sendHeaders([
              Header.ascii('grpc-status', '0'),
            ], endStream: true);
          }
        },
      );
      addTearDown(server.close);

      var settled = false;
      final pending = uploadGridFs(
        InternetAddress.loopbackIPv4,
        'tok',
        _singleHeaderRequests(),
        CancellationToken(),
        port: server.port,
      ).whenComplete(() => settled = true);

      await dataSent.future;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(settled, isFalse);

      releaseTrailers.complete();
      final response = await pending;
      expect(response.file.idEjson, '"gated"');

      // Now close after DATA without trailers.
      final releaseSecond = Completer<void>();
      closeWithoutTrailers = true;
      final server2 = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
            Header.ascii('grpc-status', '0'),
          ]);
          stream.sendData(_frameMessage(_okResponse().writeToBuffer()));
          await releaseSecond.future;
          await stream.outgoingMessages.close();
        },
      );
      addTearDown(server2.close);

      releaseSecond.complete();
      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: server2.port,
        ),
        throwsA(
          isA<GrpcError>().having((e) => e.code, 'code', StatusCode.unavailable),
        ),
      );
    });

    test('maps non-200 HTTP statuses and invalid content-type', () async {
      final cases = <(String, String, int)>[
        ('400', 'text/plain', StatusCode.internal),
        ('403', 'text/plain', StatusCode.permissionDenied),
        ('404', 'text/plain', StatusCode.unimplemented),
        ('502', 'text/plain', StatusCode.unavailable),
        ('503', 'text/plain', StatusCode.unavailable),
        ('504', 'text/plain', StatusCode.unavailable),
        ('200', 'text/html', StatusCode.unknown),
      ];

      for (final (httpStatus, contentType, expectedCode) in cases) {
        final server = await _TestH2Server.start(
          InternetAddress.loopbackIPv4,
          (stream) async {
            await _readAllRequests(stream);
            stream.sendHeaders([
              Header.ascii(':status', httpStatus),
              Header.ascii('content-type', contentType),
            ], endStream: true);
          },
        );
        addTearDown(server.close);

        await expectLater(
          uploadGridFs(
            InternetAddress.loopbackIPv4,
            'tok',
            _singleHeaderRequests(),
            CancellationToken(),
            port: server.port,
          ),
          throwsA(
            isA<GrpcError>().having((e) => e.code, 'code', expectedCode),
          ),
          reason: 'status=$httpStatus contentType=$contentType',
        );
      }
    });

    test('reassembles 1-byte fragmented response and rejects bad framing', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          final framed = _frameMessage(_okResponse('"frag"').writeToBuffer());
          for (final byte in framed) {
            stream.sendData([byte]);
          }
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(server.close);

      final resp = await uploadGridFs(
        InternetAddress.loopbackIPv4,
        'tok',
        _singleHeaderRequests(),
        CancellationToken(),
        port: server.port,
      );
      expect(resp.file.idEjson, '"frag"');

      // Oversized length prefix (> 48 MiB) must be rejected before allocation.
      final oversized = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          final prefix = Uint8List(5);
          prefix.buffer.asByteData().setUint32(1, (48 << 20) + 1);
          stream.sendData(prefix);
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(oversized.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: oversized.port,
        ),
        throwsA(
          isA<GrpcError>().having(
            (e) => e.code,
            'code',
            StatusCode.resourceExhausted,
          ),
        ),
      );

      // Compressed response flag must be rejected.
      final compressed = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          stream.sendData(
            _frameMessage(_okResponse().writeToBuffer(), compressed: 1),
          );
          stream.sendHeaders([
            Header.ascii('grpc-status', '0'),
          ], endStream: true);
        },
      );
      addTearDown(compressed.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: compressed.port,
        ),
        throwsA(
          isA<GrpcError>().having((e) => e.code, 'code', StatusCode.internal),
        ),
      );
    });

    test(
      'returns early in-band UploadResponse when server replies before EOF',
      () async {
        final server = await _TestH2Server.start(
          InternetAddress.loopbackIPv4,
          (stream) async {
            final gotHeader = Completer<void>();
            late StreamSubscription<StreamMessage> sub;
            sub = stream.incomingMessages.listen((msg) {
              if (msg is DataStreamMessage && !gotHeader.isCompleted) {
                gotHeader.complete();
              }
            });
            await gotHeader.future;
            stream.sendHeaders([
              Header.ascii(':status', '200'),
              Header.ascii('content-type', 'application/grpc'),
            ]);
            stream.sendData(
              _frameMessage(
                UploadResponse(
                  error: GridFsError(
                    kind:
                        GridFsErrorKind.GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED,
                    message: 'confirm replace',
                  ),
                ).writeToBuffer(),
              ),
            );
            stream.sendHeaders([
              Header.ascii('grpc-status', '0'),
            ], endStream: true);
            await stream.outgoingMessages.done;
            stream.terminate();
            await sub.cancel();
          },
        );
        addTearDown(server.close);

        final controller = StreamController<UploadRequest>();
        controller.add(
          UploadRequest(header: UploadHeader(filename: 'a.bin')),
        );
        final timer = Timer.periodic(const Duration(milliseconds: 5), (t) {
          if (controller.isClosed) {
            t.cancel();
            return;
          }
          controller.add(UploadRequest(chunk: List<int>.filled(65536, 2)));
        });
        addTearDown(() {
          timer.cancel();
          return controller.close();
        });

        final response = await uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          controller.stream,
          CancellationToken(),
          port: server.port,
        );
        expect(
          response.error.kind,
          GridFsErrorKind.GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED,
        );
      },
    );
  });

  group('uploadGridFs back-pressure', () {
    test('pauses source stream when HTTP/2 flow control blocks', () async {
      final serverReceivedFirst = Completer<void>();
      late StreamSubscription<GrpcMessage> serverSub;
      var serverBytes = 0;
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          final decoder = GrpcHttpDecoder();
          serverSub = stream.incomingMessages
              .transform(decoder)
              .listen(
                (msg) {
                  if (msg is GrpcData) {
                    serverBytes += msg.data.length;
                    if (!serverReceivedFirst.isCompleted) {
                      serverReceivedFirst.complete();
                      serverSub.pause();
                    }
                  }
                },
                onDone: () {
                  unawaited(serverSub.cancel());
                  stream.sendHeaders([
                    Header.ascii(':status', '200'),
                    Header.ascii('content-type', 'application/grpc'),
                  ]);
                  stream.sendData(
                    _frameMessage(_okResponse('"32m"').writeToBuffer()),
                  );
                  stream.sendHeaders([
                    Header.ascii('grpc-status', '0'),
                  ], endStream: true);
                },
              );
        },
      );
      addTearDown(() async {
        await serverSub.cancel();
        await server.close();
      });

      var yieldedChunks = 0;
      final chunk = Uint8List(1024 * 1024);
      Stream<UploadRequest> source() async* {
        yield UploadRequest(header: UploadHeader(filename: '32m.bin'));
        for (var i = 0; i < 32; i++) {
          yieldedChunks++;
          yield UploadRequest(chunk: chunk);
        }
      }

      final pending = uploadGridFs(
        InternetAddress.loopbackIPv4,
        'tok',
        source(),
        CancellationToken(),
        port: server.port,
      );

      await serverReceivedFirst.future;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(yieldedChunks, lessThanOrEqualTo(2));

      serverSub.resume();
      final response = await pending;
      expect(response.file.idEjson, '"32m"');
      expect(yieldedChunks, 32);
      expect(serverBytes, greaterThan(32 * 1024 * 1024));
    });
  });

  group('uploadGridFs cancellation, timeouts, and errors', () {
    test('cancelling before connect opens zero connections', () async {
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (_) async {},
      );
      addTearDown(server.close);

      final cancel = CancellationToken()..cancel();
      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          cancel,
          port: server.port,
        ),
        throwsA(isA<OperationCancelled>()),
      );
      expect(server.connectionCount, 0);
    });

    test(
      'cancelling during paused send sends RST_STREAM and closes source',
      () async {
        final serverTerminated = Completer<int?>();
        final firstData = Completer<void>();
        late StreamSubscription<StreamMessage> sub;
        final server = await _TestH2Server.start(
          InternetAddress.loopbackIPv4,
          (stream) async {
            stream.onTerminated = (code) {
              if (!serverTerminated.isCompleted) serverTerminated.complete(code);
            };
            sub = stream.incomingMessages.listen((msg) {
              if (msg is DataStreamMessage && !firstData.isCompleted) {
                firstData.complete();
                sub.pause();
              }
            });
          },
        );
        addTearDown(() async {
          await sub.cancel();
          await server.close();
        });

        final sourceClosed = Completer<void>();
        final cancel = CancellationToken();
        final chunk = Uint8List(1024 * 1024);
        Stream<UploadRequest> source() async* {
          try {
            yield UploadRequest(header: UploadHeader(filename: 'big.bin'));
            for (var i = 0; i < 32; i++) {
              yield UploadRequest(chunk: chunk);
            }
          } finally {
            if (!sourceClosed.isCompleted) sourceClosed.complete();
          }
        }

        final pending = uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          source(),
          cancel,
          port: server.port,
        );

        await firstData.future;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        cancel.cancel();

        await expectLater(pending, throwsA(isA<OperationCancelled>()));
        await sourceClosed.future;
        final rstCode = await serverTerminated.future;
        expect(rstCode, ErrorCode.CANCEL);
      },
    );

    test('cancelling while awaiting response sends RST_STREAM(CANCEL)', () async {
      final serverTerminated = Completer<int?>();
      final eofSeen = Completer<void>();
      final server = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          stream.onTerminated = (code) {
            if (!serverTerminated.isCompleted) serverTerminated.complete(code);
          };
          await for (final _ in stream.incomingMessages) {}
          if (!eofSeen.isCompleted) eofSeen.complete();
        },
      );
      addTearDown(server.close);

      final cancel = CancellationToken();
      final pending = uploadGridFs(
        InternetAddress.loopbackIPv4,
        'tok',
        _singleHeaderRequests(chunk: [1, 2, 3]),
        cancel,
        port: server.port,
      );

      await eofSeen.future;
      cancel.cancel();

      await expectLater(pending, throwsA(isA<OperationCancelled>()));
      expect(await serverTerminated.future, ErrorCode.CANCEL);
    });

    test('times out when server never sends SETTINGS or trailers', () async {
      final silentServer = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (_) async {},
        rawAcceptOnly: true,
      );
      addTearDown(silentServer.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: silentServer.port,
          idleTimeout: const Duration(milliseconds: 60),
        ),
        throwsA(
          isA<GrpcError>().having(
            (e) => e.code,
            'code',
            StatusCode.deadlineExceeded,
          ),
        ),
      );

      final stallAfterData = await _TestH2Server.start(
        InternetAddress.loopbackIPv4,
        (stream) async {
          await _readAllRequests(stream);
          stream.sendHeaders([
            Header.ascii(':status', '200'),
            Header.ascii('content-type', 'application/grpc'),
          ]);
          stream.sendData(_frameMessage(_okResponse().writeToBuffer()));
        },
      );
      addTearDown(stallAfterData.close);

      await expectLater(
        uploadGridFs(
          InternetAddress.loopbackIPv4,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
          port: stallAfterData.port,
          idleTimeout: const Duration(milliseconds: 60),
        ),
        throwsA(
          isA<GrpcError>().having(
            (e) => e.code,
            'code',
            StatusCode.deadlineExceeded,
          ),
        ),
      );
    });

    test('fails with UNAVAILABLE on missing Unix socket', () async {
      final dir = await Directory.systemTemp.createTemp('queravue-missing-');
      addTearDown(() => dir.delete(recursive: true));
      final missing = InternetAddress(
        '${dir.path}/missing.sock',
        type: InternetAddressType.unix,
      );
      await expectLater(
        uploadGridFs(
          missing,
          'tok',
          _singleHeaderRequests(),
          CancellationToken(),
        ),
        throwsA(
          isA<GrpcError>().having((e) => e.code, 'code', StatusCode.unavailable),
        ),
      );
    });

    test(
      'leaves zero unhandled zone errors when send and response fail together',
      () async {
        final zoneErrors = <Object>[];
        await runZonedGuarded(
          () async {
            final server = await _TestH2Server.start(
              InternetAddress.loopbackIPv4,
              (stream) async {
                final gotOne = Completer<void>();
                late StreamSubscription<StreamMessage> sub;
                sub = stream.incomingMessages.listen((msg) {
                  if (msg is DataStreamMessage && !gotOne.isCompleted) {
                    gotOne.complete();
                  }
                });
                await gotOne.future;
                stream.sendHeaders([
                  Header.ascii(':status', '200'),
                  Header.ascii('content-type', 'application/grpc'),
                  Header.ascii('grpc-status', '${StatusCode.internal}'),
                  Header.ascii('grpc-message', 'server failed'),
                ], endStream: true);
                await stream.outgoingMessages.done;
                stream.terminate();
                await sub.cancel();
              },
            );
            addTearDown(server.close);

            final controller = StreamController<UploadRequest>();
            addTearDown(controller.close);
            controller.add(
              UploadRequest(header: UploadHeader(filename: 'a.bin')),
            );
            Timer(const Duration(milliseconds: 5), () {
              if (!controller.isClosed) {
                controller.addError(StateError('disk read failed'));
              }
            });

            await expectLater(
              uploadGridFs(
                InternetAddress.loopbackIPv4,
                'tok',
                controller.stream,
                CancellationToken(),
                port: server.port,
              ),
              throwsA(anyOf(isA<StateError>(), isA<GrpcError>())),
            );
            await Future<void>.delayed(const Duration(milliseconds: 30));
          },
          (error, stack) => zoneErrors.add(error),
        );
        expect(zoneErrors, isEmpty);
      },
    );
  });
}
