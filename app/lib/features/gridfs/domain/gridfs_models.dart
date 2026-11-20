const gridFsChunkBytes = 1024 * 1024;

typedef GridFsDatabase = ({String sessionId, String database});
typedef GridFsTarget = ({GridFsDatabase scope, String bucket});

class GridFsEntry {
  const GridFsEntry({
    required this.id,
    required this.filename,
    required this.length,
    required this.uploadDate,
    this.contentType = '',
    this.metadata = '',
  });

  final String id;
  final String filename;
  final int length;
  final DateTime uploadDate;
  final String contentType;
  final String metadata;
}

class GridFsUpload {
  const GridFsUpload({
    required this.filename,
    this.contentType = '',
    this.metadata = '',
    this.replaceId,
  });

  final String filename;
  final String contentType;
  final String metadata;
  final String? replaceId;
}

enum GridFsFailureKind {
  unspecified,
  parse,
  notFound,
  confirmationRequired,
  auth,
  network,
  timeout,
  canceled,
  unsupported,
  server,
  corrupt,
}

class GridFsFailure implements Exception {
  const GridFsFailure(this.kind, this.message);

  final GridFsFailureKind kind;
  final String message;

  @override
  String toString() => message;
}
