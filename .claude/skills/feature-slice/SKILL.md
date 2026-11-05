---
name: feature-slice
description: Scaffold and implement a new Flutter UI feature in Queravue (screen, panel, or tool) wired to the Go core. Use when adding any new user-facing feature in app/.
---
# Add a Flutter feature slice

## Structure
```
app/lib/features/<feature>/
  data/        <feature>_repository.dart   (calls core_client only; maps proto ↔ domain)
  domain/      models.dart                 (immutable models, freezed if used)
  application/ <feature>_controller.dart   (Riverpod Notifier/AsyncNotifier; all logic here)
  presentation/<feature>_view.dart + widgets/
app/test/features/<feature>/              (controller unit tests, widget/golden tests)
```

## Steps
1. Find the roadmap item and PRD section, and list the acceptance criteria in the PR.
2. If new core data is needed, run the **proto-change** skill first.
3. Repository: wrap the gRPC calls, map errors to user-friendly failures, and expose streams for streaming RPCs.
4. Controller: state as a sealed class (loading / data / error / empty); cancel in-flight calls on dispose.
5. View: keep widgets dumb, use only virtualized lists/grids for collections, add empty/error/loading states, support light and dark themes.
6. Keyboard: register a shortcut and a command-palette entry for each primary action.
7. Gate by capability: hide or disable the feature when the active connection's engine lacks the required capability.
8. Tests: controller unit tests with a fake repository; widget test for each main state; golden test for the main view.
9. While the app runs: use Dart MCP `analyze_files`, `hot_reload`, `get_runtime_errors`, and `widget_inspector` to verify.

## Done when
- `flutter analyze` is clean and `flutter test` is green.
- The feature works against a real core plus docker DBs, cancel works, and nothing blocks the UI thread.
