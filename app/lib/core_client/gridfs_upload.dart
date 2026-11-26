import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:grpc/grpc.dart';
import 'package:http2/transport.dart';
import 'package:protobuf/protobuf.dart';

import '../features/connections/domain/cancellation.dart';
import 'gen/queravue/v1/gridfs.pb.dart';

const int _maxGrpcMessageBytes = 48 << 20;
const Duration _cleanupTimeout = Duration(milliseconds: 100);

class CoreEndpoint {
  const CoreEndpoint._(this.address, this.port);

  factory CoreEndpoint(InternetAddress address, {int port = 0}) {
    switch (address.type) {
      case InternetAddressType.unix:
        if (address.address.isEmpty) {
          throw ArgumentError('Core Unix socket path must not be empty');
        }
        if (port != 0) {
          throw ArgumentError.value(
            port,
            'port',
            'Unix socket endpoints require port 0',
          );
        }
        return CoreEndpoint._(address, 0);
      case InternetAddressType.IPv4:
      case InternetAddressType.IPv6:
        if (!address.isLoopback) {
          throw ArgumentError(
            'Core endpoint must be a loopback address: ${address.address}',
          );
        }
        if (port < 1 || port > 65535) {
          throw RangeError.range(port, 1, 65535, 'port');
        }
        return CoreEndpoint._(address, port);
      default:
        throw ArgumentError(
          'Unsupported core endpoint address type: ${address.type.name}',
        );
    }
  }

  factory CoreEndpoint.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Core endpoint must not be empty');
    }
    if (!trimmed.contains('/') && !trimmed.contains(r'\')) {
      if (trimmed.startsWith('[')) {
        final closeBracket = trimmed.indexOf(']:');
        if (closeBracket <= 1) {
          throw ArgumentError('Invalid bracketed core endpoint: $trimmed');
        }
        final host = trimmed.substring(1, closeBracket);
        final port = int.tryParse(trimmed.substring(closeBracket + 2));
        final address = InternetAddress.tryParse(host);
        if (address == null ||
            address.type != InternetAddressType.IPv6 ||
            port == null) {
          throw ArgumentError('Invalid IPv6 core endpoint: $trimmed');
        }
        return CoreEndpoint(address, port: port);
      }
      final colon = trimmed.lastIndexOf(':');
      if (colon != -1) {
        if (trimmed.indexOf(':') != colon) {
          throw ArgumentError(
            'Core IPv6 endpoint must use [host]:port: $trimmed',
          );
        }
        final host = trimmed.substring(0, colon);
        final port = int.tryParse(trimmed.substring(colon + 1));
        final address = InternetAddress.tryParse(host);
        if (address == null ||
            address.type != InternetAddressType.IPv4 ||
            port == null) {
          throw ArgumentError('Invalid TCP core endpoint: $trimmed');
        }
        return CoreEndpoint(address, port: port);
      }
    }
    if (Platform.isWindows) {
      throw ArgumentError(
        'Windows core endpoint must be a loopback host:port address',
      );
    }
    return CoreEndpoint(
      InternetAddress(trimmed, type: InternetAddressType.unix),
    );
  }

  final InternetAddress address;
  final int port;

  String get authority => switch (address.type) {
    InternetAddressType.unix => 'localhost',
    InternetAddressType.IPv6 => '[${address.address}]:$port',
    _ => '${address.address}:$port',
  };
}

String? decodeGrpcMessage(String? raw, [String token = '']) {
  if (raw == null) return null;
  final input = utf8.encode(raw);
  final out = <int>[];
  for (var i = 0; i < input.length; i++) {
    if (input[i] == 0x25 && i + 2 < input.length) {
      final hi = _hexDigit(input[i + 1]);
      final lo = _hexDigit(input[i + 2]);
      if (hi >= 0 && lo >= 0) {
        out.add((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    out.add(input[i]);
  }
  return _redactToken(utf8.decode(out, allowMalformed: true), token);
}

Future<UploadResponse> uploadGridFs(
  InternetAddress address,
  String token,
  Stream<UploadRequest> requests,
  CancellationToken cancel, {
  int port = 0,
  Duration connectTimeout = const Duration(seconds: 2),
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  final endpoint = CoreEndpoint(address, port: port);
  _validateToken(token);
  if (cancel.isCancelled) throw const OperationCancelled();

  final socket = await _connectSocket(endpoint, token, cancel, connectTimeout);
  ClientTransportConnection? connection;
  ClientTransportStream? stream;
  StreamSubscription<void>? frameSub;
  StreamSubscription<StreamMessage>? incomingSub;
  Timer? watchdog;
  var sendingDone = false;
  var receivingDone = false;
  var timedOut = false;
  int? peerResetCode;
  Object? sourceError;
  Object? sinkError;
  Object? responseError;
  UploadResponse? responseValue;
  final finished = Completer<void>();
  final receiveDone = Completer<void>();

  void wake() {
    if (!finished.isCompleted) finished.complete();
  }

  void finishReceive() {
    if (!receivingDone) {
      receivingDone = true;
      if (!receiveDone.isCompleted) receiveDone.complete();
    }
    wake();
  }

  void resetWatchdog() {
    watchdog?.cancel();
    if (finished.isCompleted || cancel.isCancelled || timedOut) return;
    watchdog = Timer(idleTimeout, () {
      timedOut = true;
      wake();
    });
  }

  try {
    connection = ClientTransportConnection.viaSocket(socket);
    stream = connection.makeRequest([
      Header.ascii(':method', 'POST'),
      Header.ascii(':scheme', 'http'),
      Header.ascii(':authority', endpoint.authority),
      Header.ascii(':path', '/queravue.v1.GridFsService/Upload'),
      Header.ascii('content-type', 'application/grpc'),
      Header.ascii('te', 'trailers'),
      Header(ascii.encode('authorization'), ascii.encode('Bearer $token')),
    ]);
    stream.onTerminated = (code) => peerResetCode = code;

    frameSub = connection.onFrameReceived.listen((_) {
      if (!sendingDone) resetWatchdog();
    });

    final decoder = _ResponseDecoder(token);
    incomingSub = stream.incomingMessages.listen(
      (message) {
        resetWatchdog();
        try {
          decoder.add(message);
        } on Object catch (error) {
          responseError ??= error;
          unawaited(incomingSub?.cancel() ?? Future<void>.value());
          finishReceive();
        }
      },
      onError: (Object error, StackTrace stack) {
        if (decoder.trailersReceived) {
          try {
            responseValue = decoder.finish();
          } on Object catch (finishError) {
            responseError ??= finishError;
          }
        } else {
          responseError ??= _transportGrpcError(error, peerResetCode, token);
        }
        finishReceive();
      },
      onDone: () {
        if (!receivingDone) {
          try {
            responseValue = decoder.finish();
          } on Object catch (error) {
            responseError ??= error;
          }
          finishReceive();
        }
      },
      cancelOnError: true,
    );

    final outgoing = stream.outgoingMessages;
    final encoded = requests.transform(
      StreamTransformer<UploadRequest, StreamMessage>.fromHandlers(
        handleData: (request, sink) {
          resetWatchdog();
          try {
            sink.add(_frameRequest(request));
          } on Object catch (error) {
            sourceError ??= error;
            sink.addError(error);
          }
        },
        handleError: (error, stack, sink) {
          sourceError ??= error;
          sink.addError(error, stack);
        },
      ),
    );

    resetWatchdog();
    final sendTask = () async {
      try {
        await outgoing.addStream(encoded);
        if (!cancel.isCancelled && !timedOut && !receivingDone) {
          resetWatchdog();
          await outgoing.close();
        }
      } on Object catch (error) {
        if (sourceError == null) sinkError = error;
      } finally {
        sendingDone = true;
        if (sourceError != null || sinkError != null) wake();
      }
    }();

    unawaited(cancel.whenCancelled.then((_) => wake()));
    await finished.future;

    // A sink failure without a source error means the peer closed or reset the
    // stream; give incomingMessages a turn to deliver trailers or RST_STREAM.
    if (sourceError == null &&
        sinkError != null &&
        !receivingDone &&
        !cancel.isCancelled &&
        !timedOut) {
      await Future.any([
        receiveDone.future,
        cancel.whenCancelled,
        Future<void>.delayed(_cleanupTimeout),
      ]);
    }

    final aborted =
        cancel.isCancelled ||
        timedOut ||
        sourceError != null ||
        responseError != null ||
        !sendingDone;
    if (aborted) stream.terminate();

    await _terminateConnection(
      connection,
      aborted ? ErrorCode.CANCEL : ErrorCode.NO_ERROR,
    );
    await incomingSub.cancel().timeout(_cleanupTimeout, onTimeout: () {});
    socket.destroy();
    await sendTask.timeout(_cleanupTimeout, onTimeout: () {});

    if (cancel.isCancelled) throw const OperationCancelled();
    if (timedOut) {
      throw const GrpcError.deadlineExceeded('GridFS upload timed out');
    }
    if (responseError != null) throw responseError!;
    if (responseValue != null) return responseValue!;
    if (sourceError != null) throw _sanitizeError(sourceError!, token);
    if (sinkError != null) {
      throw _transportGrpcError(sinkError, peerResetCode, token);
    }
    throw const GrpcError.internal('Missing GridFS upload response');
  } finally {
    watchdog?.cancel();
    await frameSub?.cancel().timeout(_cleanupTimeout, onTimeout: () {});
    await incomingSub?.cancel().timeout(_cleanupTimeout, onTimeout: () {});
    if (connection != null) {
      await _terminateConnection(connection, ErrorCode.CANCEL);
    }
    socket.destroy();
  }
}

Future<void> _terminateConnection(
  ClientTransportConnection connection,
  int errorCode,
) => connection
    .terminate(errorCode)
    .then<void>((_) {}, onError: (Object _) {})
    .timeout(_cleanupTimeout, onTimeout: () {});

void _validateToken(String token) {
  if (token.trim().isEmpty) {
    throw ArgumentError('Core auth token must not be empty');
  }
  for (final unit in token.codeUnits) {
    if (unit < 0x20 || unit > 0x7E) {
      throw ArgumentError('Core auth token must contain printable ASCII');
    }
  }
}

Future<Socket> _connectSocket(
  CoreEndpoint endpoint,
  String token,
  CancellationToken cancel,
  Duration timeout,
) async {
  ConnectionTask<Socket>? task;
  var connecting = true;
  var timedOut = false;
  Timer? timer;

  unawaited(
    cancel.whenCancelled.then((_) {
      if (connecting) task?.cancel();
    }),
  );

  try {
    timer = Timer(timeout, () {
      timedOut = true;
      if (connecting) task?.cancel();
    });
    final started = await Socket.startConnect(endpoint.address, endpoint.port);
    task = started;
    if (cancel.isCancelled || timedOut) started.cancel();
    final socket = await started.socket;
    connecting = false;
    if (cancel.isCancelled) {
      socket.destroy();
      throw const OperationCancelled();
    }
    if (timedOut) {
      socket.destroy();
      throw const GrpcError.deadlineExceeded('Timed out connecting to core');
    }
    if (endpoint.address.type != InternetAddressType.unix) {
      socket.setOption(SocketOption.tcpNoDelay, true);
    }
    return socket;
  } on Object catch (error) {
    connecting = false;
    if (error is OperationCancelled || cancel.isCancelled) {
      throw const OperationCancelled();
    }
    if (error is GrpcError) rethrow;
    if (timedOut) {
      throw const GrpcError.deadlineExceeded('Timed out connecting to core');
    }
    throw GrpcError.unavailable(_redactToken(error.toString(), token));
  } finally {
    connecting = false;
    timer?.cancel();
  }
}

DataStreamMessage _frameRequest(UploadRequest request) {
  final writer = CodedBufferWriter();
  request.writeToCodedBufferWriter(writer);
  final length = writer.lengthInBytes;
  if (length > _maxGrpcMessageBytes) {
    throw const GrpcError.resourceExhausted(
      'GridFS upload chunk exceeds maximum message size',
    );
  }
  final framed = Uint8List(5 + length);
  framed.buffer.asByteData().setUint32(1, length);
  writer.writeTo(framed, 5);
  return DataStreamMessage(framed);
}

class _ResponseDecoder {
  _ResponseDecoder(this.token);

  final String token;
  bool headersReceived = false;
  bool trailersReceived = false;
  int? trailerStatus;
  String? trailerMessage;
  UploadResponse? response;

  final _prefix = Uint8List(5);
  int _prefixOffset = 0;
  Uint8List? _payload;
  int _payloadOffset = 0;

  bool get _inPartialFrame => _prefixOffset != 0 || _payload != null;

  void add(StreamMessage message) {
    if (message is HeadersStreamMessage) {
      _onHeaders(message);
    } else if (message is DataStreamMessage) {
      _onData(message);
    } else {
      throw const GrpcError.internal('Unexpected HTTP/2 frame type');
    }
  }

  void _onHeaders(HeadersStreamMessage message) {
    final headers = <String, String>{};
    for (final header in message.headers) {
      final name = latin1.decode(header.name).toLowerCase();
      final value = utf8.decode(header.value, allowMalformed: true);
      final existing = headers[name];
      headers[name] = existing == null ? value : '$existing, $value';
    }

    if (!headersReceived) {
      headersReceived = true;
      final httpStatus = int.tryParse(headers[':status'] ?? '');
      if (httpStatus == null) {
        throw const GrpcError.unknown('Missing HTTP :status header');
      }
      if (httpStatus != HttpStatus.ok) {
        final rawStatus = _parseGrpcStatus(headers['grpc-status']);
        final detail = decodeGrpcMessage(headers['grpc-message'], token);
        if (rawStatus != null &&
            rawStatus > StatusCode.ok &&
            rawStatus != StatusCode.unknown) {
          throw _statusGrpcError(rawStatus, detail);
        }
        throw _httpStatusGrpcError(httpStatus, detail);
      }
      if (!_isGrpcContentType(headers['content-type']?.toLowerCase())) {
        throw const GrpcError.unknown('Invalid gRPC content-type header');
      }
      if (message.endStream) {
        trailersReceived = true;
        trailerStatus = _parseGrpcStatus(headers['grpc-status']);
        trailerMessage = decodeGrpcMessage(headers['grpc-message'], token);
      }
      return;
    }

    if (trailersReceived) {
      throw const GrpcError.internal('Received multiple gRPC trailers');
    }
    if (_inPartialFrame) {
      throw const GrpcError.internal('Received trailers mid-frame');
    }
    if (!message.endStream) {
      throw const GrpcError.internal('Expected END_STREAM on gRPC trailers');
    }
    trailersReceived = true;
    trailerStatus = _parseGrpcStatus(headers['grpc-status']);
    trailerMessage = decodeGrpcMessage(headers['grpc-message'], token);
  }

  void _onData(DataStreamMessage message) {
    if (!headersReceived) {
      throw const GrpcError.internal('Received gRPC data before headers');
    }
    if (trailersReceived) {
      throw const GrpcError.internal('Received gRPC data after trailers');
    }
    final bytes = message.bytes;
    var offset = 0;
    while (offset < bytes.length) {
      if (_payload == null) {
        final needed = 5 - _prefixOffset;
        final take = math.min(needed, bytes.length - offset);
        _prefix.setRange(_prefixOffset, _prefixOffset + take, bytes, offset);
        _prefixOffset += take;
        offset += take;
        if (_prefixOffset < 5) break;

        if (_prefix[0] != 0) {
          throw const GrpcError.internal(
            'Compressed gRPC response is not supported',
          );
        }
        final length = ByteData.sublistView(_prefix).getUint32(1);
        if (length > _maxGrpcMessageBytes) {
          throw const GrpcError.resourceExhausted(
            'GridFS upload response exceeds maximum message size',
          );
        }
        _payload = Uint8List(length);
        _payloadOffset = 0;
        _prefixOffset = 0;
      }

      final payload = _payload!;
      if (_payloadOffset < payload.length) {
        final needed = payload.length - _payloadOffset;
        final take = math.min(needed, bytes.length - offset);
        payload.setRange(_payloadOffset, _payloadOffset + take, bytes, offset);
        _payloadOffset += take;
        offset += take;
      }
      if (_payloadOffset == payload.length) {
        if (response != null) {
          throw const GrpcError.internal(
            'Multiple GridFS upload responses received',
          );
        }
        try {
          response = UploadResponse.fromBuffer(payload);
        } on InvalidProtocolBufferException {
          throw const GrpcError.internal('Invalid GridFS upload response');
        }
        _payload = null;
        _payloadOffset = 0;
      }
    }
  }

  UploadResponse finish() {
    if (!headersReceived) {
      throw const GrpcError.unavailable('Stream closed without gRPC headers');
    }
    if (_inPartialFrame) {
      throw const GrpcError.unavailable('Truncated gRPC response frame');
    }
    if (!trailersReceived) {
      throw const GrpcError.unavailable('Missing gRPC trailers');
    }
    final status = trailerStatus;
    if (status == null) {
      throw GrpcError.unknown(
        trailerMessage ?? 'Missing or invalid grpc-status',
      );
    }
    if (status != StatusCode.ok) {
      throw _statusGrpcError(status, trailerMessage);
    }
    final parsed = response;
    if (parsed == null || (!parsed.hasFile() && !parsed.hasError())) {
      throw const GrpcError.internal('Missing GridFS upload response');
    }
    return parsed;
  }
}

bool _isGrpcContentType(String? value) =>
    value != null &&
    (value == 'application/grpc' ||
        value.startsWith('application/grpc+') ||
        value.startsWith('application/grpc;'));

int? _parseGrpcStatus(String? raw) {
  if (raw == null) return null;
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

int _hexDigit(int unit) {
  if (unit >= 0x30 && unit <= 0x39) return unit - 0x30;
  if (unit >= 0x41 && unit <= 0x46) return unit - 0x41 + 10;
  if (unit >= 0x61 && unit <= 0x66) return unit - 0x61 + 10;
  return -1;
}

String _redactToken(String text, String token) {
  if (token.isEmpty || !text.contains(token)) return text;
  return text.replaceAll(token, '<redacted>');
}

Object _sanitizeError(Object error, String token) {
  if (error is GrpcError) {
    final msg = error.message;
    if (msg != null && token.isNotEmpty && msg.contains(token)) {
      return GrpcError.custom(error.code, _redactToken(msg, token));
    }
  }
  return error;
}

GrpcError _statusGrpcError(int status, String? message) {
  if (status == StatusCode.unauthenticated) {
    return GrpcError.unauthenticated(message);
  }
  return GrpcError.custom(status, message);
}

GrpcError _httpStatusGrpcError(int httpStatus, String? detail) {
  final message = detail ?? 'HTTP status $httpStatus';
  return switch (httpStatus) {
    HttpStatus.badRequest => GrpcError.internal(message),
    HttpStatus.unauthorized => GrpcError.unauthenticated(message),
    HttpStatus.forbidden => GrpcError.permissionDenied(message),
    HttpStatus.notFound => GrpcError.unimplemented(message),
    HttpStatus.tooManyRequests ||
    HttpStatus.badGateway ||
    HttpStatus.serviceUnavailable ||
    HttpStatus.gatewayTimeout => GrpcError.unavailable(message),
    _ => GrpcError.unknown(message),
  };
}

GrpcError _transportGrpcError(Object? error, int? resetCode, String token) {
  if (error is GrpcError) return _sanitizeError(error, token) as GrpcError;
  if (resetCode != null) {
    final message = error == null
        ? 'HTTP/2 stream reset (code $resetCode)'
        : _redactToken(error.toString(), token);
    return switch (resetCode) {
      ErrorCode.REFUSED_STREAM => GrpcError.unavailable(message),
      ErrorCode.CANCEL => GrpcError.cancelled(message),
      ErrorCode.ENHANCE_YOUR_CALM => GrpcError.resourceExhausted(message),
      ErrorCode.INADEQUATE_SECURITY => GrpcError.permissionDenied(message),
      _ => GrpcError.internal(message),
    };
  }
  return GrpcError.unavailable(
    error == null
        ? 'GridFS upload connection closed'
        : _redactToken(error.toString(), token),
  );
}
