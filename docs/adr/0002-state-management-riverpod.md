# ADR 0002 — State management: Riverpod

**Status:** Accepted · 2026-11-05

## Context
PRD §10 left state management open (Riverpod vs. Bloc). Iteration 0 needs app-wide state for the core sidecar lifecycle, and later iterations add per-connection, per-tab and streaming state. AGENTS.md requires no business logic in widgets: widgets call providers/controllers, which call `core_client`.

## Decision
- Use `flutter_riverpod` 3.x.
- Write plain `Provider` / `Notifier` / `AsyncNotifier` classes **without** `riverpod_generator`, so the project needs no `build_runner` step. We can revisit this if the amount of boilerplate becomes a problem.
- Inject infrastructure through providers (for example `coreLauncherProvider` and `coreConnectorProvider`) and override them in tests.
- Keep long-lived logic in plain Dart classes (for example `CoreSupervisor`) that can be unit-tested without Flutter. Notifiers adapt that logic into UI state.

## Rationale
- Overriding providers gives dependency injection and test fakes without a service locator.
- Far less boilerplate than Bloc for many small, independent pieces of state (tabs, connections, grid windows).
- `ref.onDispose` ties resource cleanup (streams, gRPC calls) to widget lifetimes, which fits the "everything is cancellable" rule.

## Consequences
- Contributors need to know Riverpod 3 APIs (Notifier rather than StateNotifier).
- Without code generation, providers are declared by hand. Keep them next to the feature they serve (`lib/features/<feature>/`).
