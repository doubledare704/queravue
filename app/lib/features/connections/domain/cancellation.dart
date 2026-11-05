import 'dart:async';

/// Lets a caller abandon an in-flight operation (for example a connection
/// test). Repositories cancel the underlying RPC when [cancel] is called.
class CancellationToken {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Thrown by an operation that was cancelled through a [CancellationToken].
class OperationCancelled implements Exception {
  const OperationCancelled();

  @override
  String toString() => 'Cancelled';
}
