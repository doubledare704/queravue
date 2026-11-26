import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:http2/transport.dart';

import '../features/connections/domain/cancellation.dart';
import 'gen/queravue/v1/gridfs.pb.dart';

Future<UploadResponse> uploadGridFs(
  InternetAddress address,
  String token,
  Stream<UploadRequest> requests,
  CancellationToken cancel,
) async {
  if (cancel.isCancelled) throw const OperationCancelled();
  final socket = await Socket.connect(
    address,
    0,
    timeout: const Duration(seconds: 2),
  );
  try {
    if (cancel.isCancelled) throw const OperationCancelled();
    final connection = ClientTransportConnection.viaSocket(socket);
    final stream = connection.makeRequest([
      Header.ascii(':method', 'POST'),
      Header.ascii(':scheme', 'http'),
      Header.ascii(':authority', 'localhost'),
      Header.ascii(':path', '/queravue.v1.GridFsService/Upload'),
      Header.ascii('content-type', 'application/grpc'),
      Header.ascii('te', 'trailers'),
      Header.ascii('authorization', 'Bearer $token'),
    ]);
    final encoder = GrpcHttpEncoder();
    final outgoing = stream.outgoingMessages;
    final response = _readResponse(stream);
    // addStream propagates HTTP/2 window pauses to the file source.
    final sendFailure = Completer<UploadResponse>();
    unawaited(
      outgoing
          .addStream(
            requests.map(
              (request) => encoder.convert(
                GrpcData(request.writeToBuffer(), isCompressed: false),
              ),
            ),
          )
          .then<void>((_) => outgoing.close())
          .catchError((Object error, StackTrace stack) {
            sendFailure.completeError(error, stack);
          }),
    );
    try {
      return await Future.any([
        response,
        sendFailure.future,
        cancel.whenCancelled.then<UploadResponse>(
          (_) => throw const OperationCancelled(),
        ),
      ]);
    } finally {
      await connection.terminate();
    }
  } finally {
    socket.destroy();
  }
}

Future<UploadResponse> _readResponse(ClientTransportStream stream) async {
  UploadResponse? response;
  int? status;
  String? message;
  await for (final event in stream.incomingMessages.transform(
    GrpcHttpDecoder(forResponse: true),
  )) {
    if (event is GrpcData) {
      response = UploadResponse.fromBuffer(event.data);
    } else if (event is GrpcMetadata) {
      status = int.tryParse(event.metadata['grpc-status'] ?? '') ?? status;
      final detail = event.metadata['grpc-message'];
      if (detail != null) message = Uri.decodeComponent(detail);
    }
  }
  if (status != StatusCode.ok) {
    throw GrpcError.custom(status ?? StatusCode.unknown, message);
  }
  return response ??
      (throw GrpcError.internal('Missing GridFS upload response'));
}
