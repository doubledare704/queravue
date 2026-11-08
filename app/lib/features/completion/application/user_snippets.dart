import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/data/workspace_repository.dart';
import '../../workspace/domain/workspace_models.dart';
import '../domain/snippets.dart';

const userSnippetsPath = '.queravue/snippets.json';

/// Snippets from `.queravue/snippets.json` in the first workspace root.
/// A missing or unreadable file means no user snippets.
final userSnippetsProvider = FutureProvider<List<Snippet>>((ref) async {
  final repo = ref.watch(workspaceRepositoryProvider);
  try {
    final roots = await repo.roots();
    if (roots.isEmpty) return const [];
    final file = await repo.read(FilePath(roots.first.id, userSnippetsPath));
    return parseUserSnippets(file.content);
  } on Object {
    return const [];
  }
});
