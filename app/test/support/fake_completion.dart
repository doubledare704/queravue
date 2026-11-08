import 'dart:async';

import 'package:queravue/features/completion/data/completion_repository.dart';
import 'package:queravue/features/completion/domain/completion_models.dart';

/// Answers completion requests from a script and records them.
class FakeCompletionRepository implements CompletionRepository {
  FakeCompletionRepository({this.answer});

  /// Builds the answer for a request; the default is an empty one.
  CompletionResult Function(CompletionRequest request)? answer;

  /// Delay before answering, to test slow cores.
  Duration delay = Duration.zero;

  final requests = <CompletionRequest>[];
  int cancelled = 0;

  FormatSqlResult Function(String text)? formatter;
  final formatted = <String>[];

  @override
  Future<CompletionResult> complete(
    CompletionRequest request, {
    required Future<void> cancel,
  }) async {
    requests.add(request);
    var wasCancelled = false;
    unawaited(
      cancel.then((_) {
        wasCancelled = true;
        cancelled++;
      }),
    );
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (wasCancelled) return const CompletionResult(error: 'Cancelled');
    return answer?.call(request) ?? const CompletionResult();
  }

  @override
  Future<FormatSqlResult> formatSql({
    required String sessionId,
    required String text,
    FormatSqlOptions options = const FormatSqlOptions(),
    int? rangeStart,
    int? rangeEnd,
  }) async {
    formatted.add(text);
    return formatter?.call(text) ??
        FormatSqlResult(
          formattedText: text,
          replaceStart: rangeStart ?? 0,
          replaceEnd: rangeEnd ?? text.length,
        );
  }
}
